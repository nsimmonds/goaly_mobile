import 'tag.dart';

class Task {
  final int? id;
  final String description;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? timeEstimate;      // Minutes, nullable
  final int? dependencyTaskId;  // Task ID, nullable
  final int totalTimeSpent;     // Seconds, default 0
  final String? notes;          // Optional notes, nullable
  final List<Tag> tags;         // Tags (loaded separately from junction table)

  Task({
    this.id,
    required this.description,
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
    this.timeEstimate,
    this.dependencyTaskId,
    this.totalTimeSpent = 0,
    this.notes,
    List<Tag>? tags,
  })  : createdAt = createdAt ?? DateTime.now(),
        tags = tags ?? const [];

  // Convert Task to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'time_estimate': timeEstimate,
      'dependency_task_id': dependencyTaskId,
      'total_time_spent': totalTimeSpent,
      'notes': notes,
    };
  }

  // Create Task from Map (database row)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as int?,
      description: map['description'] as String,
      completed: (map['completed'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      timeEstimate: map['time_estimate'] as int?,
      dependencyTaskId: map['dependency_task_id'] as int?,
      totalTimeSpent: map['total_time_spent'] as int? ?? 0,
      notes: map['notes'] as String?,
    );
  }

  // Create a copy with some fields updated
  Task copyWith({
    int? id,
    String? description,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    int? timeEstimate,
    int? dependencyTaskId,
    int? totalTimeSpent,
    String? notes,
    List<Tag>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      dependencyTaskId: dependencyTaskId ?? this.dependencyTaskId,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, description: $description, completed: $completed}';
  }
}
