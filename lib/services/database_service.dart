import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../config/constants.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        completed_at INTEGER,
        time_estimate INTEGER,
        dependency_task_id INTEGER,
        total_time_spent INTEGER DEFAULT 0
      )
    ''');

    // Create index on completed column for faster queries
    await db.execute('''
      CREATE INDEX idx_tasks_completed ON tasks(completed)
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE tasks ADD COLUMN time_estimate INTEGER');
      await db.execute('ALTER TABLE tasks ADD COLUMN dependency_task_id INTEGER');
    }
    if (oldVersion < 3) {
      // Add time tracking column for version 3
      await db.execute('ALTER TABLE tasks ADD COLUMN total_time_spent INTEGER DEFAULT 0');
    }
  }

  // CRUD Operations for Tasks

  /// Create a new task
  Future<Task> createTask(Task task) async {
    final db = await database;
    final id = await db.insert('tasks', task.toMap());
    return task.copyWith(id: id);
  }

  /// Get all tasks
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  /// Get incomplete tasks only
  Future<List<Task>> getIncompleteTasks() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Task.fromMap(json)).toList();
  }

  /// Get a random incomplete task
  Future<Task?> getRandomTask() async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'completed = ?',
      whereArgs: [0],
      orderBy: 'RANDOM()',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Task.fromMap(result.first);
  }

  /// Update a task
  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  /// Mark a task as completed
  Future<int> completeTask(int id) async {
    final db = await database;
    return db.update(
      'tasks',
      {
        'completed': 1,
        'completed_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a task
  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
