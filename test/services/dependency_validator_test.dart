import 'package:flutter_test/flutter_test.dart';
import 'package:goaly_mobile/models/task.dart';
import 'package:goaly_mobile/services/dependency_validator.dart';

void main() {
  group('DependencyValidator', () {
    group('isTaskBlocked', () {
      test('returns false for task with no dependency', () {
        final task = Task(id: 1, description: 'Independent');
        final tasks = [task];

        expect(DependencyValidator.isTaskBlocked(task, tasks), false);
      });

      test('returns true when dependency is incomplete', () {
        final dependency = Task(id: 1, description: 'Dependency', completed: false);
        final task = Task(id: 2, description: 'Blocked', dependencyTaskId: 1);
        final tasks = [dependency, task];

        expect(DependencyValidator.isTaskBlocked(task, tasks), true);
      });

      test('returns false when dependency is complete', () {
        final dependency = Task(id: 1, description: 'Dependency', completed: true);
        final task = Task(id: 2, description: 'Unblocked', dependencyTaskId: 1);
        final tasks = [dependency, task];

        expect(DependencyValidator.isTaskBlocked(task, tasks), false);
      });

      test('returns false when dependency does not exist', () {
        final task = Task(id: 1, description: 'Orphan', dependencyTaskId: 999);
        final tasks = [task];

        expect(DependencyValidator.isTaskBlocked(task, tasks), false);
      });
    });

    group('hasCircularDependency', () {
      test('returns false for no dependency', () {
        final tasks = [
          Task(id: 1, description: 'Task 1'),
          Task(id: 2, description: 'Task 2'),
        ];

        expect(DependencyValidator.hasCircularDependency(tasks, 1, null), false);
      });

      test('returns false for valid dependency chain', () {
        final tasks = [
          Task(id: 1, description: 'Task 1'),
          Task(id: 2, description: 'Task 2', dependencyTaskId: 1),
          Task(id: 3, description: 'Task 3', dependencyTaskId: 2),
        ];

        // Task 4 depending on Task 3 is valid
        expect(DependencyValidator.hasCircularDependency(tasks, 4, 3), false);
      });

      test('returns true for direct circular dependency', () {
        final tasks = [
          Task(id: 1, description: 'Task 1', dependencyTaskId: 2),
          Task(id: 2, description: 'Task 2'),
        ];

        // Task 2 depending on Task 1 would create a circle
        expect(DependencyValidator.hasCircularDependency(tasks, 2, 1), true);
      });

      test('returns true for indirect circular dependency', () {
        final tasks = [
          Task(id: 1, description: 'Task 1'),
          Task(id: 2, description: 'Task 2', dependencyTaskId: 1),
          Task(id: 3, description: 'Task 3', dependencyTaskId: 2),
        ];

        // Task 1 depending on Task 3 would create a circle: 1 -> 3 -> 2 -> 1
        expect(DependencyValidator.hasCircularDependency(tasks, 1, 3), true);
      });

      test('returns true for self-dependency', () {
        final tasks = [
          Task(id: 1, description: 'Task 1'),
        ];

        expect(DependencyValidator.hasCircularDependency(tasks, 1, 1), true);
      });
    });

    group('getBlockedTaskIds', () {
      test('returns empty set when no tasks are blocked', () {
        final tasks = [
          Task(id: 1, description: 'Task 1', completed: true),
          Task(id: 2, description: 'Task 2'),
        ];

        expect(DependencyValidator.getBlockedTaskIds(tasks), isEmpty);
      });

      test('returns blocked task ids', () {
        final tasks = [
          Task(id: 1, description: 'Incomplete', completed: false),
          Task(id: 2, description: 'Blocked', dependencyTaskId: 1),
          Task(id: 3, description: 'Also blocked', dependencyTaskId: 1),
          Task(id: 4, description: 'Not blocked'),
        ];

        final blocked = DependencyValidator.getBlockedTaskIds(tasks);

        expect(blocked, contains(2));
        expect(blocked, contains(3));
        expect(blocked, isNot(contains(1)));
        expect(blocked, isNot(contains(4)));
      });
    });
  });
}
