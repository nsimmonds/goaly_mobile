import 'package:flutter_test/flutter_test.dart';
import 'package:goaly_mobile/models/task.dart';
import 'package:goaly_mobile/models/tag.dart';

void main() {
  group('Task', () {
    test('creates task with required fields', () {
      final task = Task(description: 'Test task');

      expect(task.description, 'Test task');
      expect(task.completed, false);
      expect(task.id, isNull);
      expect(task.createdAt, isNotNull);
      expect(task.completedAt, isNull);
      expect(task.timeEstimate, isNull);
      expect(task.dependencyTaskId, isNull);
      expect(task.totalTimeSpent, 0);
      expect(task.tags, isEmpty);
    });

    test('creates task with all fields', () {
      final createdAt = DateTime(2024, 1, 10);
      final completedAt = DateTime(2024, 1, 11);
      final tags = [
        Tag(id: 1, name: 'Work', colorValue: 0xFF5C6BC0),
      ];

      final task = Task(
        id: 1,
        description: 'Full task',
        completed: true,
        createdAt: createdAt,
        completedAt: completedAt,
        timeEstimate: 30,
        dependencyTaskId: 2,
        totalTimeSpent: 1800,
        tags: tags,
      );

      expect(task.id, 1);
      expect(task.description, 'Full task');
      expect(task.completed, true);
      expect(task.createdAt, createdAt);
      expect(task.completedAt, completedAt);
      expect(task.timeEstimate, 30);
      expect(task.dependencyTaskId, 2);
      expect(task.totalTimeSpent, 1800);
      expect(task.tags.length, 1);
      expect(task.tags.first.name, 'Work');
    });

    test('toMap converts task to map correctly', () {
      final now = DateTime.now();
      final task = Task(
        id: 1,
        description: 'Map test',
        completed: true,
        createdAt: now,
        completedAt: now,
        timeEstimate: 15,
        dependencyTaskId: 3,
        totalTimeSpent: 900,
      );

      final map = task.toMap();

      expect(map['id'], 1);
      expect(map['description'], 'Map test');
      expect(map['completed'], 1);
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['completed_at'], now.millisecondsSinceEpoch);
      expect(map['time_estimate'], 15);
      expect(map['dependency_task_id'], 3);
      expect(map['total_time_spent'], 900);
    });

    test('fromMap creates task from map correctly', () {
      final timestamp = DateTime(2024, 1, 15).millisecondsSinceEpoch;
      final map = {
        'id': 5,
        'description': 'From map',
        'completed': 0,
        'created_at': timestamp,
        'completed_at': null,
        'time_estimate': 45,
        'dependency_task_id': null,
        'total_time_spent': 0,
      };

      final task = Task.fromMap(map);

      expect(task.id, 5);
      expect(task.description, 'From map');
      expect(task.completed, false);
      expect(task.timeEstimate, 45);
      expect(task.tags, isEmpty); // Tags loaded separately
    });

    test('copyWith creates copy with updated fields', () {
      final task = Task(
        id: 1,
        description: 'Original',
        totalTimeSpent: 100,
      );

      final updated = task.copyWith(
        completed: true,
        totalTimeSpent: 500,
      );

      expect(updated.id, 1);
      expect(updated.description, 'Original');
      expect(updated.completed, true);
      expect(updated.totalTimeSpent, 500);
    });

    test('copyWith can add tags', () {
      final task = Task(description: 'No tags');
      final tags = [
        Tag(id: 1, name: 'Tag1', colorValue: 0xFF5C6BC0),
        Tag(id: 2, name: 'Tag2', colorValue: 0xFF26A69A),
      ];

      final updated = task.copyWith(tags: tags);

      expect(updated.tags.length, 2);
      expect(updated.tags[0].name, 'Tag1');
      expect(updated.tags[1].name, 'Tag2');
    });

    test('default tags is empty list', () {
      final task = Task(description: 'Test');
      expect(task.tags, isA<List<Tag>>());
      expect(task.tags, isEmpty);
    });
  });
}
