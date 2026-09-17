import 'package:tugasku_backend/database/database.dart';
import 'package:tugasku_backend/models/user_model.dart';

class AuthRepository {
  final DatabaseHelper _dbHelper;

  AuthRepository(this._dbHelper);

  User? findByEmail(String email) {
    final result = _dbHelper.db.select('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
    if (result.isEmpty) return null;
    return User.fromRow(result.first);
  }

  User? findById(int id) {
    final result = _dbHelper.db.select('SELECT * FROM users WHERE id = ? LIMIT 1', [id]);
    if (result.isEmpty) return null;
    return User.fromRow(result.first);
  }

  User createUser(String name, String email, String passwordHash) {
    final now = DateTime.now().toIso8601String();
    _dbHelper.db.execute(
      'INSERT INTO users (name, email, password_hash, created_at, updated_at) VALUES (?, ?, ?, ?, ?)',
      [name, email, passwordHash, now, now],
    );
    final id = _dbHelper.db.lastInsertRowId;
    return findById(id)!;
  }

  void updateUser(int userId, String name, String email) {
    final now = DateTime.now().toIso8601String();
    _dbHelper.db.execute(
      'UPDATE users SET name = ?, email = ?, updated_at = ? WHERE id = ?',
      [name, email, now, userId],
    );
  }

  void updatePassword(int userId, String passwordHash) {
    final now = DateTime.now().toIso8601String();
    _dbHelper.db.execute(
      'UPDATE users SET password_hash = ?, updated_at = ? WHERE id = ?',
      [passwordHash, now, userId],
    );
  }
}
