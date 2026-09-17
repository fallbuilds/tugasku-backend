import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:tugasku_backend/database/database.dart';

class TaskRepository {
  final DatabaseHelper _dbHelper;

  TaskRepository(this._dbHelper);

  Map<String, dynamic> _rowToMap(sqlite3.Row row) {
    return {
      'id': row['id'],
      'user_id': row['user_id'],
      'title': row['title'],
      'subject': row['subject'],
      'class_name': row['class_name'],
      'deadline': row['deadline'],
      'priority': row['priority'],
      'description': row['description'],
      'status': row['status'],
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
      'completed_at': row['completed_at'],
    };
  }

  List<Map<String, dynamic>> getTasksByUserId(int userId) {
    final results = _dbHelper.db.select('SELECT * FROM tasks WHERE user_id = ? ORDER BY deadline ASC', [userId]);
    return results.map(_rowToMap).toList();
  }

  Map<String, dynamic>? getTaskById(int id) {
    final results = _dbHelper.db.select('SELECT * FROM tasks WHERE id = ?', [id]);
    if (results.isEmpty) return null;
    return _rowToMap(results.first);
  }

  Map<String, dynamic> createTask(int userId, Map<String, dynamic> data) {
    final now = DateTime.now().toIso8601String();
    _dbHelper.db.execute('''
      INSERT INTO tasks (
        user_id, title, subject, class_name, deadline, priority, description, status, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      userId,
      data['title'],
      data['subject'],
      data['class_name'] ?? '',
      data['deadline'],
      data['priority'] ?? 'medium',
      data['description'] ?? '',
      'pending',
      now,
      now
    ]);
    final id = _dbHelper.db.lastInsertRowId;
    return getTaskById(id)!;
  }

  Map<String, dynamic>? updateTask(int id, int userId, Map<String, dynamic> data) {
    final now = DateTime.now().toIso8601String();
    
    // Build update query dynamically based on provided fields
    final fields = <String>[];
    final values = <dynamic>[];
    
    if (data.containsKey('title')) { fields.add('title = ?'); values.add(data['title']); }
    if (data.containsKey('subject')) { fields.add('subject = ?'); values.add(data['subject']); }
    if (data.containsKey('class_name')) { fields.add('class_name = ?'); values.add(data['class_name']); }
    if (data.containsKey('deadline')) { fields.add('deadline = ?'); values.add(data['deadline']); }
    if (data.containsKey('priority')) { fields.add('priority = ?'); values.add(data['priority']); }
    if (data.containsKey('description')) { fields.add('description = ?'); values.add(data['description']); }
    if (data.containsKey('status')) { fields.add('status = ?'); values.add(data['status']); }
    
    fields.add('updated_at = ?');
    values.add(now);
    
    if (fields.isEmpty) return getTaskById(id);
    
    values.add(id);
    values.add(userId);
    
    final query = 'UPDATE tasks SET ${fields.join(', ')} WHERE id = ? AND user_id = ?';
    _dbHelper.db.execute(query, values);
    
    return getTaskById(id);
  }

  bool deleteTask(int id, int userId) {
    _dbHelper.db.execute('DELETE FROM tasks WHERE id = ? AND user_id = ?', [id, userId]);
    return _dbHelper.db.updatedRows > 0;
  }

  Map<String, dynamic>? updateStatus(int id, int userId, String status) {
    final now = DateTime.now().toIso8601String();
    String? completedAt = status == 'completed' ? now : null;
    
    _dbHelper.db.execute('''
      UPDATE tasks 
      SET status = ?, updated_at = ?, completed_at = ?
      WHERE id = ? AND user_id = ?
    ''', [status, now, completedAt, id, userId]);
    
    return getTaskById(id);
  }

  Map<String, dynamic> getDashboardStats(int userId) {
    final now = DateTime.now();
    final nowStr = now.toIso8601String();
    final plus3Days = now.add(Duration(days: 3)).toIso8601String();
    final plus24Hours = now.add(Duration(hours: 24)).toIso8601String();
    
    // Month bounds for calendar
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    final totalTasks = _dbHelper.db.select('SELECT COUNT(*) as c FROM tasks WHERE user_id = ?', [userId]).first['c'];
    final upcomingTasksCount = _dbHelper.db.select('''
      SELECT COUNT(*) as c FROM tasks 
      WHERE user_id = ? AND status = 'pending' AND deadline > ? AND deadline <= ?
    ''', [userId, nowStr, plus3Days]).first['c'];
    final overdueTasks = _dbHelper.db.select('''
      SELECT COUNT(*) as c FROM tasks 
      WHERE user_id = ? AND status = 'pending' AND deadline < ?
    ''', [userId, nowStr]).first['c'];
    final completedTasks = _dbHelper.db.select('''
      SELECT COUNT(*) as c FROM tasks 
      WHERE user_id = ? AND status = 'completed'
    ''', [userId]).first['c'];
    
    final priorities = _dbHelper.db.select('''
      SELECT priority, COUNT(*) as count 
      FROM tasks 
      WHERE user_id = ? AND status = 'pending'
      GROUP BY priority
    ''', [userId]);
    
    final priorityBreakdown = {
      'high': 0,
      'medium': 0,
      'low': 0,
    };
    for (final row in priorities) {
      final p = row['priority'] as String;
      priorityBreakdown[p] = row['count'];
    }

    final upcoming = _dbHelper.db.select('''
      SELECT * FROM tasks 
      WHERE user_id = ? AND status = 'pending' AND deadline > ? 
      ORDER BY deadline ASC LIMIT 5
    ''', [userId, nowStr]).map(_rowToMap).toList();

    final reminders = _dbHelper.db.select('''
      SELECT * FROM tasks 
      WHERE user_id = ? AND status = 'pending' AND deadline > ? AND deadline <= ?
      ORDER BY deadline ASC
    ''', [userId, nowStr, plus24Hours]).map(_rowToMap).toList();

    final calendar = _dbHelper.db.select('''
      SELECT * FROM tasks 
      WHERE user_id = ? AND deadline >= ? AND deadline < ?
    ''', [userId, startOfMonth, startOfNextMonth]).map(_rowToMap).toList();

    return {
      'total_tasks': totalTasks,
      'upcoming_tasks': upcomingTasksCount,
      'overdue_tasks': overdueTasks,
      'completed_tasks': completedTasks,
      'priority_breakdown': priorityBreakdown,
      'upcoming': upcoming,
      'reminders': reminders,
      'calendar': calendar,
    };
  }

  List<Map<String, dynamic>> getTasksByMonth(int userId, int month, int year) {
    final startOfMonth = DateTime(year, month, 1).toIso8601String();
    final startOfNextMonth = month == 12 
        ? DateTime(year + 1, 1, 1).toIso8601String() 
        : DateTime(year, month + 1, 1).toIso8601String();
        
    final results = _dbHelper.db.select('''
      SELECT * FROM tasks 
      WHERE user_id = ? AND deadline >= ? AND deadline < ?
      ORDER BY deadline ASC
    ''', [userId, startOfMonth, startOfNextMonth]);
    
    return results.map(_rowToMap).toList();
  }
}
