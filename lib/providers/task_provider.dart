import 'dart:math';
import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/task.dart';
import '../models/tag.dart';
import '../services/database_service.dart';
import '../services/dependency_validator.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Task> _tasks = [];
  List<Tag> _tags = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Task> get tasks => _tasks;
  List<Tag> get allTags => _tags;
  List<Task> get incompleteTasks => _tasks.where((task) => !task.completed).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.completed).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasIncompleteTasks => incompleteTasks.isNotEmpty;

  /// Load all tasks from database
  Future<void> loadTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tasks = await _db.getAllTasks();
      _tags = await _db.getAllTags();

      // Load tags for each task
      for (int i = 0; i < _tasks.length; i++) {
        final taskTags = await _db.getTagsForTask(_tasks[i].id!);
        _tasks[i] = _tasks[i].copyWith(tags: taskTags);
      }
    } catch (e) {
      _errorMessage = 'Failed to load tasks: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new task
  Future<void> addTask(String description) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Task name cannot be empty';
      notifyListeners();
      return;
    }
    if (trimmed.length > AppConstants.maxTaskDescription) {
      _errorMessage = 'Task name too long (max ${AppConstants.maxTaskDescription} characters)';
      notifyListeners();
      return;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final task = Task(description: description.trim());
      final createdTask = await _db.createTask(task);
      _tasks.insert(0, createdTask); // Add to beginning
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to add task: $e';
      notifyListeners();
    }
  }

  /// Add a new task with time estimate, dependency, and notes
  /// Returns the created task, or null if creation failed
  Future<Task?> addTaskWithDetails(
    String description,
    int? timeEstimate,
    int? dependencyTaskId, {
    String? notes,
  }) async {
    final trimmed = description.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Task name cannot be empty';
      notifyListeners();
      return null;
    }
    if (trimmed.length > AppConstants.maxTaskDescription) {
      _errorMessage = 'Task name too long (max ${AppConstants.maxTaskDescription} characters)';
      notifyListeners();
      return null;
    }
    if (notes != null && notes.length > AppConstants.maxTaskNotes) {
      _errorMessage = 'Notes too long (max ${AppConstants.maxTaskNotes} characters)';
      notifyListeners();
      return null;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final task = Task(
        description: description.trim(),
        timeEstimate: timeEstimate,
        dependencyTaskId: dependencyTaskId,
        notes: notes?.trim(),
      );
      final createdTask = await _db.createTask(task);
      _tasks.insert(0, createdTask);
      notifyListeners();
      return createdTask;
    } catch (e) {
      _errorMessage = 'Failed to add task: $e';
      notifyListeners();
      return null;
    }
  }

  /// Update an existing task
  Future<void> updateTask(Task task) async {
    if (task.description.trim().isEmpty) {
      _errorMessage = 'Task name cannot be empty';
      notifyListeners();
      return;
    }
    if (task.description.length > AppConstants.maxTaskDescription) {
      _errorMessage = 'Task name too long (max ${AppConstants.maxTaskDescription} characters)';
      notifyListeners();
      return;
    }
    if (task.notes != null && task.notes!.length > AppConstants.maxTaskNotes) {
      _errorMessage = 'Notes too long (max ${AppConstants.maxTaskNotes} characters)';
      notifyListeners();
      return;
    }

    _errorMessage = null;

    try {
      await _db.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to update task: $e';
      notifyListeners();
    }
  }

  /// Mark a task as completed
  Future<void> completeTask(int taskId) async {
    _errorMessage = null;

    try {
      await _db.completeTask(taskId);

      // Update local list
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          completed: true,
          completedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to complete task: $e';
      notifyListeners();
    }
  }

  /// Reopen a completed task (preserves time spent)
  Future<void> reopenTask(int taskId) async {
    _errorMessage = null;

    try {
      await _db.reopenTask(taskId);

      // Update local list
      final index = _tasks.indexWhere((task) => task.id == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          completed: false,
          completedAt: null,
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to reopen task: $e';
      notifyListeners();
    }
  }

  /// Complete a task and add accumulated time
  Future<void> completeTaskWithTime(int taskId, int additionalSeconds) async {
    _errorMessage = null;

    try {
      // Get current task to add to its time
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final newTotalTime = task.totalTimeSpent + additionalSeconds;

      // Update task with completion and accumulated time
      final updatedTask = task.copyWith(
        completed: true,
        completedAt: DateTime.now(),
        totalTimeSpent: newTotalTime,
      );

      await _db.updateTask(updatedTask);
      _tasks[taskIndex] = updatedTask;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to complete task: $e';
      notifyListeners();
    }
  }

  /// Accumulate time on a task without marking it complete
  Future<void> accumulateTaskTime(int taskId, int additionalSeconds) async {
    try {
      final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
      if (taskIndex == -1) return;

      final task = _tasks[taskIndex];
      final newTotalTime = task.totalTimeSpent + additionalSeconds;

      final updatedTask = task.copyWith(totalTimeSpent: newTotalTime);
      await _db.updateTask(updatedTask);
      _tasks[taskIndex] = updatedTask;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to accumulate task time: $e');
      }
    }
  }

  /// Delete a task
  Future<void> deleteTask(int taskId) async {
    _errorMessage = null;

    try {
      // Clear this task as a dependency from other tasks
      final dependents = _tasks.where((t) => t.dependencyTaskId == taskId);
      for (var task in dependents) {
        await _db.updateTask(task.copyWith(dependencyTaskId: null));
      }

      // Delete the task
      await _db.deleteTask(taskId);
      await loadTasks(); // Reload to ensure consistency
    } catch (e) {
      _errorMessage = 'Failed to delete task: $e';
      notifyListeners();
    }
  }

  /// Get a random incomplete task (excluding blocked tasks)
  Future<Task?> getRandomTask() async {
    try {
      // Get all incomplete tasks that aren't blocked
      final available = _tasks
          .where((t) => !t.completed && !isTaskBlocked(t))
          .toList();

      if (available.isEmpty) return null;

      final random = Random();
      return available[random.nextInt(available.length)];
    } catch (e) {
      _errorMessage = 'Failed to get random task: $e';
      notifyListeners();
      return null;
    }
  }

  /// Check if a task is blocked by an incomplete dependency
  bool isTaskBlocked(Task task) {
    return DependencyValidator.isTaskBlocked(task, _tasks);
  }

  /// Get list of tasks available to be selected as dependencies
  /// Excludes the task being edited and completed tasks
  List<Task> getAvailableTasksForDependency(int? excludeTaskId) {
    return _tasks
        .where((t) => !t.completed && t.id != excludeTaskId)
        .toList();
  }

  /// Get task by ID
  Task? getTaskById(int taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Tag Management

  /// Create a new tag
  Future<Tag?> createTag(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Tag name cannot be empty';
      notifyListeners();
      return null;
    }
    if (trimmed.length > AppConstants.maxTagName) {
      _errorMessage = 'Tag name too long (max ${AppConstants.maxTagName} characters)';
      notifyListeners();
      return null;
    }

    try {
      final tag = await _db.createTag(trimmed);
      _tags.add(tag);
      _tags.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return tag;
    } catch (e) {
      _errorMessage = 'Failed to create tag: $e';
      notifyListeners();
      return null;
    }
  }

  /// Add a tag to a task
  Future<void> addTagToTask(int taskId, int tagId) async {
    await _db.addTagToTask(taskId, tagId);

    // Update local task
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final tag = _tags.firstWhere((t) => t.id == tagId);
      final currentTags = List<Tag>.from(_tasks[taskIndex].tags);
      if (!currentTags.any((t) => t.id == tagId)) {
        currentTags.add(tag);
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(tags: currentTags);
        notifyListeners();
      }
    }
  }

  /// Remove a tag from a task
  Future<void> removeTagFromTask(int taskId, int tagId) async {
    await _db.removeTagFromTask(taskId, tagId);

    // Update local task
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final currentTags = List<Tag>.from(_tasks[taskIndex].tags);
      currentTags.removeWhere((t) => t.id == tagId);
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(tags: currentTags);
      notifyListeners();
    }
  }

  /// Get tasks filtered by tag
  List<Task> getTasksByTag(int tagId) {
    return _tasks.where((t) => t.tags.any((tag) => tag.id == tagId)).toList();
  }

  /// Get completed tasks filtered by tag
  List<Task> getCompletedTasksByTag(int tagId) {
    return completedTasks.where((t) => t.tags.any((tag) => tag.id == tagId)).toList();
  }
}
