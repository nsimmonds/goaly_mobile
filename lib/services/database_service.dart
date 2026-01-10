import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/tag.dart';
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
        total_time_spent INTEGER DEFAULT 0,
        notes TEXT
      )
    ''');

    // Create index on completed column for faster queries
    await db.execute('''
      CREATE INDEX idx_tasks_completed ON tasks(completed)
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Junction table for many-to-many relationship
    await db.execute('''
      CREATE TABLE task_tags (
        task_id INTEGER NOT NULL,
        tag_id INTEGER NOT NULL,
        PRIMARY KEY (task_id, tag_id),
        FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_task_tags_task_id ON task_tags(task_id)');
    await db.execute('CREATE INDEX idx_task_tags_tag_id ON task_tags(tag_id)');
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
    if (oldVersion < 4) {
      // Add tags tables for version 4
      await db.execute('''
        CREATE TABLE tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          color INTEGER NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE task_tags (
          task_id INTEGER NOT NULL,
          tag_id INTEGER NOT NULL,
          PRIMARY KEY (task_id, tag_id),
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
          FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
        )
      ''');

      await db.execute('CREATE INDEX idx_task_tags_task_id ON task_tags(task_id)');
      await db.execute('CREATE INDEX idx_task_tags_tag_id ON task_tags(tag_id)');
    }
    if (oldVersion < 5) {
      // Add notes column for version 5
      await db.execute('ALTER TABLE tasks ADD COLUMN notes TEXT');
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

  // CRUD Operations for Tags

  /// Create a new tag with auto-assigned color
  Future<Tag> createTag(String name) async {
    final db = await database;

    // Get count of existing tags to pick color from palette
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM tags');
    final count = countResult.first['count'] as int;
    final colorIndex = count % AppConstants.tagColorPalette.length;

    final tag = Tag(
      name: name.trim(),
      colorValue: AppConstants.tagColorPalette[colorIndex],
    );

    final id = await db.insert('tags', tag.toMap());
    return tag.copyWith(id: id);
  }

  /// Get all tags
  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final result = await db.query('tags', orderBy: 'name ASC');
    return result.map((json) => Tag.fromMap(json)).toList();
  }

  /// Get tags for a specific task
  Future<List<Tag>> getTagsForTask(int taskId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT t.* FROM tags t
      INNER JOIN task_tags tt ON t.id = tt.tag_id
      WHERE tt.task_id = ?
      ORDER BY t.name ASC
    ''', [taskId]);
    return result.map((json) => Tag.fromMap(json)).toList();
  }

  /// Add a tag to a task
  Future<void> addTagToTask(int taskId, int tagId) async {
    final db = await database;
    await db.insert(
      'task_tags',
      {'task_id': taskId, 'tag_id': tagId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Remove a tag from a task
  Future<void> removeTagFromTask(int taskId, int tagId) async {
    final db = await database;
    await db.delete(
      'task_tags',
      where: 'task_id = ? AND tag_id = ?',
      whereArgs: [taskId, tagId],
    );
  }

  /// Delete a tag (cascade deletes task_tags entries)
  Future<int> deleteTag(int id) async {
    final db = await database;
    // First delete from junction table
    await db.delete('task_tags', where: 'tag_id = ?', whereArgs: [id]);
    // Then delete the tag
    return db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  /// Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Bulk Operations for Backup/Restore

  /// Delete all tasks
  Future<void> deleteAllTasks() async {
    final db = await database;
    await db.delete('task_tags'); // Clear junction table first
    await db.delete('tasks');
  }

  /// Delete all tags
  Future<void> deleteAllTags() async {
    final db = await database;
    await db.delete('task_tags'); // Clear junction table first
    await db.delete('tags');
  }

  /// Insert a task with a specific ID (for restore)
  Future<Task> insertTaskWithId(Task task) async {
    final db = await database;
    final map = task.toMap();
    map['id'] = task.id; // Include ID in insert
    await db.insert('tasks', map, conflictAlgorithm: ConflictAlgorithm.replace);
    return task;
  }

  /// Insert a tag with a specific ID (for restore)
  Future<Tag> insertTagWithId(Tag tag) async {
    final db = await database;
    final map = tag.toMap();
    map['id'] = tag.id; // Include ID in insert
    await db.insert('tags', map, conflictAlgorithm: ConflictAlgorithm.replace);
    return tag;
  }

  /// Get all task-tag associations
  Future<List<Map<String, int>>> getAllTaskTagAssociations() async {
    final db = await database;
    final result = await db.query('task_tags');
    return result.map((row) => {
      'task_id': row['task_id'] as int,
      'tag_id': row['tag_id'] as int,
    }).toList();
  }

  /// Check if a task with matching description and createdAt exists
  Future<bool> taskExists(String description, int createdAtMs) async {
    final db = await database;
    final result = await db.query(
      'tasks',
      where: 'description = ? AND created_at = ?',
      whereArgs: [description, createdAtMs],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Check if a tag with matching name exists
  Future<Tag?> getTagByName(String name) async {
    final db = await database;
    final result = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Tag.fromMap(result.first);
  }
}
