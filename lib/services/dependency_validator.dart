import 'dart:collection';
import '../models/task.dart';

/// Utility class for validating task dependencies and preventing circular references
class DependencyValidator {
  /// Check if adding a dependency would create a circular dependency
  /// Uses breadth-first search to traverse dependency chain
  ///
  /// Returns true if circular dependency detected
  static bool hasCircularDependency(
    List<Task> allTasks,
    int taskId,
    int? newDependencyId,
  ) {
    if (newDependencyId == null) return false;
    if (taskId == newDependencyId) return true; // Direct self-reference

    // BFS to detect cycle
    Set<int> visited = {};
    Queue<int> queue = Queue();
    queue.add(newDependencyId);

    while (queue.isNotEmpty) {
      final currentId = queue.removeFirst();

      if (visited.contains(currentId)) continue;
      visited.add(currentId);

      // If we reach the original task, there's a cycle
      if (currentId == taskId) return true;

      // Find the task and check its dependency
      final task = allTasks.firstWhere(
        (t) => t.id == currentId,
        orElse: () => Task(description: '', id: -1),
      );

      if (task.id != null && task.id != -1 && task.dependencyTaskId != null) {
        queue.add(task.dependencyTaskId!);
      }
    }

    return false;
  }

  /// Get list of task IDs that are blocked (have incomplete dependencies)
  static List<int> getBlockedTaskIds(List<Task> allTasks) {
    List<int> blockedIds = [];

    for (var task in allTasks) {
      if (!task.completed && isTaskBlocked(task, allTasks)) {
        if (task.id != null) {
          blockedIds.add(task.id!);
        }
      }
    }

    return blockedIds;
  }

  /// Check if a specific task is blocked by an incomplete dependency
  static bool isTaskBlocked(Task task, List<Task> allTasks) {
    if (task.dependencyTaskId == null) return false;

    final blockingTask = allTasks.firstWhere(
      (t) => t.id == task.dependencyTaskId,
      orElse: () => Task(description: '', id: -1),
    );

    // Task is blocked if dependency exists and is not completed
    return blockingTask.id != -1 && !blockingTask.completed;
  }
}
