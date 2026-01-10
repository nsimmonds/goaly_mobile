import 'dart:convert';
import '../config/constants.dart';
import '../models/task.dart';
import '../models/tag.dart';
import 'database_service.dart';

/// Result of an import operation
class ImportResult {
  final int tasksImported;
  final int tagsImported;
  final int tasksSkipped;
  final int tagsSkipped;
  final String? error;

  ImportResult({
    this.tasksImported = 0,
    this.tagsImported = 0,
    this.tasksSkipped = 0,
    this.tagsSkipped = 0,
    this.error,
  });

  bool get hasError => error != null;

  String get summary {
    if (hasError) return error!;
    final parts = <String>[];
    if (tasksImported > 0) parts.add('$tasksImported tasks');
    if (tagsImported > 0) parts.add('$tagsImported tags');
    if (parts.isEmpty) return 'Nothing to import';
    final imported = 'Imported ${parts.join(', ')}';
    if (tasksSkipped > 0 || tagsSkipped > 0) {
      return '$imported (${tasksSkipped + tagsSkipped} skipped)';
    }
    return imported;
  }
}

/// Service for exporting and importing task data
class BackupService {
  static const int _currentVersion = 1;
  static const int _minTimestamp = 946684800000; // 2000-01-01
  static const int _maxTimestamp = 4102444800000; // 2100-01-01

  final DatabaseService _db = DatabaseService.instance;

  /// Export all tasks and tags to JSON string
  Future<String> exportToJson() async {
    final tasks = await _db.getAllTasks();
    final tags = await _db.getAllTags();
    final taskTagAssociations = await _db.getAllTaskTagAssociations();

    // Build tag IDs map for each task
    final taskTagIds = <int, List<int>>{};
    for (final assoc in taskTagAssociations) {
      final taskId = assoc['task_id']!;
      final tagId = assoc['tag_id']!;
      taskTagIds.putIfAbsent(taskId, () => []).add(tagId);
    }

    final export = {
      'version': _currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tags': tags.map((tag) => {
        'id': tag.id,
        'name': tag.name,
        'color': tag.colorValue,
        'createdAt': tag.createdAt.millisecondsSinceEpoch,
      }).toList(),
      'tasks': tasks.map((task) => {
        'id': task.id,
        'description': task.description,
        'completed': task.completed,
        'createdAt': task.createdAt.millisecondsSinceEpoch,
        'completedAt': task.completedAt?.millisecondsSinceEpoch,
        'timeEstimate': task.timeEstimate,
        'dependencyTaskId': task.dependencyTaskId,
        'totalTimeSpent': task.totalTimeSpent,
        'notes': task.notes,
        'tagIds': taskTagIds[task.id] ?? [],
      }).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Validate import data structure and limits
  /// Returns error message if invalid, null if valid
  String? _validateImportData(Map<String, dynamic> data) {
    // Check required fields
    if (!data.containsKey('version') || !data.containsKey('tasks')) {
      return 'Invalid backup file format';
    }

    // Check version
    final version = data['version'];
    if (version is! int || version > _currentVersion) {
      return 'Backup file is from a newer version';
    }

    // Get arrays
    final tags = data['tags'];
    final tasks = data['tasks'];

    if (tasks is! List) {
      return 'Invalid tasks format';
    }

    // Check array sizes
    if (tasks.length > AppConstants.maxTasks) {
      return 'Too many tasks (max $AppConstants.maxTasks)';
    }
    if (tags is List && tags.length > AppConstants.maxTags) {
      return 'Too many tags (max $AppConstants.maxTags)';
    }

    // Validate each tag
    if (tags is List) {
      for (var i = 0; i < tags.length; i++) {
        final tag = tags[i];
        if (tag is! Map<String, dynamic>) {
          return 'Invalid tag at index $i';
        }
        final tagError = _validateTag(tag, i);
        if (tagError != null) return tagError;
      }
    }

    // Validate each task
    for (var i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      if (task is! Map<String, dynamic>) {
        return 'Invalid task at index $i';
      }
      final taskError = _validateTask(task, i);
      if (taskError != null) return taskError;
    }

    return null;
  }

  String? _validateTag(Map<String, dynamic> tag, int index) {
    if (!tag.containsKey('id') || tag['id'] is! int) {
      return 'Tag $index: missing or invalid id';
    }
    if (!tag.containsKey('name') || tag['name'] is! String) {
      return 'Tag $index: missing or invalid name';
    }
    final name = tag['name'] as String;
    if (name.isEmpty || name.length > AppConstants.maxTagName) {
      return 'Tag $index: name must be 1-$AppConstants.maxTagName characters';
    }
    if (!tag.containsKey('color') || tag['color'] is! int) {
      return 'Tag $index: missing or invalid color';
    }
    if (!tag.containsKey('createdAt') || tag['createdAt'] is! int) {
      return 'Tag $index: missing or invalid createdAt';
    }
    final createdAt = tag['createdAt'] as int;
    if (createdAt < _minTimestamp || createdAt > _maxTimestamp) {
      return 'Tag $index: createdAt out of valid range';
    }
    return null;
  }

  String? _validateTask(Map<String, dynamic> task, int index) {
    if (!task.containsKey('id') || task['id'] is! int) {
      return 'Task $index: missing or invalid id';
    }
    if (!task.containsKey('description') || task['description'] is! String) {
      return 'Task $index: missing or invalid description';
    }
    final description = task['description'] as String;
    if (description.isEmpty || description.length > AppConstants.maxTaskDescription) {
      return 'Task $index: description must be 1-$AppConstants.maxTaskDescription characters';
    }
    if (!task.containsKey('completed') || task['completed'] is! bool) {
      return 'Task $index: missing or invalid completed';
    }
    if (!task.containsKey('createdAt') || task['createdAt'] is! int) {
      return 'Task $index: missing or invalid createdAt';
    }
    final createdAt = task['createdAt'] as int;
    if (createdAt < _minTimestamp || createdAt > _maxTimestamp) {
      return 'Task $index: createdAt out of valid range';
    }
    // Optional fields
    if (task['completedAt'] != null) {
      if (task['completedAt'] is! int) {
        return 'Task $index: invalid completedAt';
      }
      final completedAt = task['completedAt'] as int;
      if (completedAt < _minTimestamp || completedAt > _maxTimestamp) {
        return 'Task $index: completedAt out of valid range';
      }
    }
    if (task['timeEstimate'] != null && task['timeEstimate'] is! int) {
      return 'Task $index: invalid timeEstimate';
    }
    if (task['totalTimeSpent'] != null && task['totalTimeSpent'] is! int) {
      return 'Task $index: invalid totalTimeSpent';
    }
    if (task['dependencyTaskId'] != null && task['dependencyTaskId'] is! int) {
      return 'Task $index: invalid dependencyTaskId';
    }
    if (task['tagIds'] != null && task['tagIds'] is! List) {
      return 'Task $index: invalid tagIds';
    }
    if (task['notes'] != null) {
      if (task['notes'] is! String) {
        return 'Task $index: invalid notes';
      }
      if ((task['notes'] as String).length > AppConstants.maxTaskNotes) {
        return 'Task $index: notes too long (max ${AppConstants.maxTaskNotes} characters)';
      }
    }
    return null;
  }

  /// Import tasks and tags from JSON string
  /// If [replace] is true, deletes all existing data first
  Future<ImportResult> importFromJson(String jsonString, {bool replace = false}) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate structure and data
      final validationError = _validateImportData(data);
      if (validationError != null) {
        return ImportResult(error: validationError);
      }

      final tagsData = (data['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final tasksData = (data['tasks'] as List).cast<Map<String, dynamic>>();

      if (replace) {
        return await _importReplace(tagsData, tasksData);
      } else {
        return await _importMerge(tagsData, tasksData);
      }
    } catch (e) {
      return ImportResult(error: 'Failed to parse backup: $e');
    }
  }

  /// Replace all data with imported data
  Future<ImportResult> _importReplace(
    List<Map<String, dynamic>> tagsData,
    List<Map<String, dynamic>> tasksData,
  ) async {
    // Clear existing data
    await _db.deleteAllTasks();
    await _db.deleteAllTags();

    int tagsImported = 0;
    int tagsSkipped = 0;
    int tasksImported = 0;
    int tasksSkipped = 0;

    // Import tags with original IDs
    for (final tagData in tagsData) {
      try {
        final tag = Tag(
          id: tagData['id'] as int,
          name: tagData['name'] as String,
          colorValue: tagData['color'] as int,
          createdAt: DateTime.fromMillisecondsSinceEpoch(tagData['createdAt'] as int),
        );
        await _db.insertTagWithId(tag);
        tagsImported++;
      } catch (_) {
        tagsSkipped++;
      }
    }

    // Import tasks with original IDs
    for (final taskData in tasksData) {
      try {
        final task = Task(
          id: taskData['id'] as int,
          description: taskData['description'] as String,
          completed: taskData['completed'] as bool,
          createdAt: DateTime.fromMillisecondsSinceEpoch(taskData['createdAt'] as int),
          completedAt: taskData['completedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(taskData['completedAt'] as int)
              : null,
          timeEstimate: taskData['timeEstimate'] as int?,
          dependencyTaskId: taskData['dependencyTaskId'] as int?,
          totalTimeSpent: taskData['totalTimeSpent'] as int? ?? 0,
          notes: taskData['notes'] as String?,
        );
        await _db.insertTaskWithId(task);

        // Restore tag associations
        final tagIds = (taskData['tagIds'] as List?)?.cast<int>() ?? [];
        for (final tagId in tagIds) {
          await _db.addTagToTask(task.id!, tagId);
        }

        tasksImported++;
      } catch (_) {
        tasksSkipped++;
      }
    }

    return ImportResult(
      tasksImported: tasksImported,
      tagsImported: tagsImported,
      tasksSkipped: tasksSkipped,
      tagsSkipped: tagsSkipped,
    );
  }

  /// Merge imported data with existing data (skip duplicates)
  Future<ImportResult> _importMerge(
    List<Map<String, dynamic>> tagsData,
    List<Map<String, dynamic>> tasksData,
  ) async {
    int tagsImported = 0;
    int tagsSkipped = 0;
    int tasksImported = 0;
    int tasksSkipped = 0;

    // Map old tag IDs to new tag IDs
    final tagIdMap = <int, int>{};

    // Import tags (skip if name exists)
    for (final tagData in tagsData) {
      try {
        final oldId = tagData['id'] as int;
        final name = tagData['name'] as String;

        final existingTag = await _db.getTagByName(name);
        if (existingTag != null) {
          // Map to existing tag
          tagIdMap[oldId] = existingTag.id!;
          tagsSkipped++;
        } else {
          // Create new tag
          final newTag = await _db.createTag(name);
          tagIdMap[oldId] = newTag.id!;
          tagsImported++;
        }
      } catch (_) {
        tagsSkipped++;
      }
    }

    // Map old task IDs to new task IDs (for dependency remapping)
    final taskIdMap = <int, int>{};

    // First pass: import tasks without dependencies
    for (final taskData in tasksData) {
      try {
        final oldId = taskData['id'] as int;
        final description = taskData['description'] as String;
        final createdAtMs = taskData['createdAt'] as int;

        // Check if task already exists
        final exists = await _db.taskExists(description, createdAtMs);
        if (exists) {
          tasksSkipped++;
          continue;
        }

        // Create task without dependency first
        final task = Task(
          description: description,
          completed: taskData['completed'] as bool,
          createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs),
          completedAt: taskData['completedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(taskData['completedAt'] as int)
              : null,
          timeEstimate: taskData['timeEstimate'] as int?,
          dependencyTaskId: null, // Set in second pass
          totalTimeSpent: taskData['totalTimeSpent'] as int? ?? 0,
          notes: taskData['notes'] as String?,
        );

        final newTask = await _db.createTask(task);
        taskIdMap[oldId] = newTask.id!;

        // Add tag associations with remapped IDs
        final tagIds = (taskData['tagIds'] as List?)?.cast<int>() ?? [];
        for (final oldTagId in tagIds) {
          final newTagId = tagIdMap[oldTagId];
          if (newTagId != null) {
            await _db.addTagToTask(newTask.id!, newTagId);
          }
        }

        tasksImported++;
      } catch (_) {
        tasksSkipped++;
      }
    }

    // Second pass: update dependencies with remapped IDs
    for (final taskData in tasksData) {
      try {
        final oldId = taskData['id'] as int;
        final oldDepId = taskData['dependencyTaskId'] as int?;

        if (oldDepId != null && taskIdMap.containsKey(oldId)) {
          final newTaskId = taskIdMap[oldId]!;
          final newDepId = taskIdMap[oldDepId];

          if (newDepId != null) {
            // Get the task and update its dependency
            final tasks = await _db.getAllTasks();
            final task = tasks.firstWhere((t) => t.id == newTaskId);
            await _db.updateTask(task.copyWith(dependencyTaskId: newDepId));
          }
        }
      } catch (_) {
        // Dependency update failed, task was already imported without it
      }
    }

    return ImportResult(
      tasksImported: tasksImported,
      tagsImported: tagsImported,
      tasksSkipped: tasksSkipped,
      tagsSkipped: tagsSkipped,
    );
  }
}
