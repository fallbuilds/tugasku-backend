import 'package:tugasku_backend/repositories/task_repository.dart';

class TaskService {
  final TaskRepository _taskRepository;

  TaskService(this._taskRepository);

  List<Map<String, dynamic>> getTasks(int userId) {
    return _taskRepository.getTasksByUserId(userId);
  }

  Map<String, dynamic> getTask(int id, int userId) {
    final task = _taskRepository.getTaskById(id);
    if (task == null || task['user_id'] != userId) {
      throw Exception('Task not found');
    }
    return task;
  }

  Map<String, dynamic> createTask(int userId, Map<String, dynamic> data) {
    if (data['title'] == null || data['title'].toString().trim().isEmpty) {
      throw Exception('title is required and cannot be empty');
    }
    if (data['subject'] == null || data['subject'].toString().trim().isEmpty) {
      throw Exception('subject is required and cannot be empty');
    }
    if (data['deadline'] == null) {
      throw Exception('deadline is required');
    }
    try {
      DateTime.parse(data['deadline']);
    } catch (_) {
      throw Exception('deadline must be a valid ISO 8601 string');
    }
    
    final priority = data['priority'];
    if (priority != null && priority != 'high' && priority != 'medium' && priority != 'low') {
      throw Exception('priority must be high, medium, or low');
    }

    return _taskRepository.createTask(userId, data);
  }

  Map<String, dynamic> updateTask(int id, int userId, Map<String, dynamic> data) {
    // Check existence and ownership
    getTask(id, userId);

    if (data.containsKey('title') && data['title'].toString().trim().isEmpty) {
      throw Exception('title cannot be empty');
    }
    if (data.containsKey('subject') && data['subject'].toString().trim().isEmpty) {
      throw Exception('subject cannot be empty');
    }
    if (data.containsKey('deadline')) {
      try {
        DateTime.parse(data['deadline']);
      } catch (_) {
        throw Exception('deadline must be a valid ISO 8601 string');
      }
    }
    if (data.containsKey('priority')) {
      final priority = data['priority'];
      if (priority != 'high' && priority != 'medium' && priority != 'low') {
        throw Exception('priority must be high, medium, or low');
      }
    }
    if (data.containsKey('status')) {
      final status = data['status'];
      if (status != 'pending' && status != 'completed') {
        throw Exception('status must be pending or completed');
      }
    }

    final updatedTask = _taskRepository.updateTask(id, userId, data);
    if (updatedTask == null) {
      throw Exception('Failed to update task');
    }
    return updatedTask;
  }

  void deleteTask(int id, int userId) {
    // Check existence and ownership
    getTask(id, userId);
    final success = _taskRepository.deleteTask(id, userId);
    if (!success) {
      throw Exception('Failed to delete task');
    }
  }

  Map<String, dynamic> updateStatus(int id, int userId, String status) {
    getTask(id, userId);
    if (status != 'pending' && status != 'completed') {
      throw Exception('status must be pending or completed');
    }
    final updatedTask = _taskRepository.updateStatus(id, userId, status);
    if (updatedTask == null) {
      throw Exception('Failed to update status');
    }
    return updatedTask;
  }
}
