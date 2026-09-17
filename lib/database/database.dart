import 'package:sqlite3/sqlite3.dart' as sqlite3;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  sqlite3.Database? _db;

  void initialize() {
    _db = sqlite3.sqlite3.open('tugasku.db');
    _db!.execute('PRAGMA foreign_keys = ON;');
    
    _db!.execute('''
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'student',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''');

    _db!.execute('''
CREATE TABLE IF NOT EXISTS tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  title TEXT NOT NULL,
  subject TEXT NOT NULL,
  class_name TEXT NOT NULL DEFAULT '',
  deadline TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'medium',
  description TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  completed_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
''');

    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_deadline ON tasks(deadline);');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_status ON tasks(status);');
    _db!.execute('CREATE INDEX IF NOT EXISTS idx_tasks_priority ON tasks(priority);');
  }

  sqlite3.Database get db {
    if (_db == null) {
      throw Exception('Database not initialized');
    }
    return _db!;
  }

  void close() {
    _db?.dispose();
    _db = null;
  }
}
