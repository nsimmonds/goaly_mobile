import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../config/constants.dart';
import '../models/task.dart';
import '../services/dependency_validator.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _estimateController = TextEditingController();
  int? _selectedDependencyId;

  @override
  void dispose() {
    _textController.dispose();
    _estimateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppConstants.emojiTasks} Tasks'),
          ],
        ),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          if (taskProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (taskProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    taskProvider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      taskProvider.clearError();
                      taskProvider.loadTasks();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final tasks = taskProvider.tasks;

          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConstants.emojiGoal,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.noTasksMessage,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _buildTaskCard(context, task, taskProvider);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task, TaskProvider provider) {
    final isBlocked = provider.isTaskBlocked(task);

    return Opacity(
      opacity: isBlocked ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: isBlocked
              ? Icon(Icons.lock, color: Colors.orange, size: 28)
              : Checkbox(
                  value: task.completed,
                  onChanged: task.completed
                      ? null
                      : (value) {
                          if (value == true && task.id != null) {
                            provider.completeTask(task.id!);
                          }
                        },
                ),
          title: Text(
            task.description,
            style: TextStyle(
              fontSize: 16,
              decoration: task.completed ? TextDecoration.lineThrough : null,
              color: task.completed ? Colors.grey : null,
            ),
          ),
          subtitle: _buildTaskSubtitle(task, provider),
          trailing: IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _confirmDelete(context, task, provider),
          ),
        ),
      ),
    );
  }

  Widget? _buildTaskSubtitle(Task task, TaskProvider provider) {
    List<String> parts = [];

    // For completed tasks: show actual time vs estimate
    if (task.completed) {
      if (task.totalTimeSpent > 0) {
        final actualMinutes = (task.totalTimeSpent / 60).round();
        if (task.timeEstimate != null) {
          // Show comparison
          parts.add('${AppConstants.emojiEstimate} $actualMinutes min / ${task.timeEstimate} min est');
        } else {
          // No estimate, just show actual
          parts.add('${AppConstants.emojiEstimate} Time spent: $actualMinutes min');
        }
      } else if (task.timeEstimate != null) {
        // Had estimate but no time tracked
        parts.add('${AppConstants.emojiEstimate} Est: ${task.timeEstimate} min');
      }
      parts.add('${AppConstants.emojiSuccess} Completed');
    } else {
      // Incomplete task: show estimate and dependency
      if (task.timeEstimate != null) {
        parts.add('${AppConstants.emojiEstimate} Est: ${task.timeEstimate} min');
      }

      if (task.dependencyTaskId != null) {
        final blockingTask = provider.getTaskById(task.dependencyTaskId!);
        if (blockingTask != null && !blockingTask.completed) {
          parts.add('${AppConstants.emojiLock} Blocked by: ${blockingTask.description}');
        }
      }
    }

    if (parts.isEmpty) return null;

    return Text(
      parts.join(' | '),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    _textController.clear();
    _estimateController.clear();
    _selectedDependencyId = null;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final taskProvider = context.read<TaskProvider>();
            final availableTasks = taskProvider.getAvailableTasksForDependency(null);

            return AlertDialog(
              title: const Text('Add New Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description field
                    TextField(
                      controller: _textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Task Description',
                        hintText: AppConstants.addTaskHint,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Time estimate field
                    TextField(
                      controller: _estimateController,
                      decoration: const InputDecoration(
                        labelText: 'Time Estimate (minutes)',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),

                    // Dependency dropdown
                    DropdownButtonFormField<int?>(
                      value: _selectedDependencyId,
                      decoration: const InputDecoration(
                        labelText: 'Depends On',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('None'),
                        ),
                        ...availableTasks.map((task) => DropdownMenuItem(
                              value: task.id,
                              child: Text(
                                task.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedDependencyId = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _saveTask(context),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveTask(BuildContext context) {
    final description = _textController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task description cannot be empty')),
      );
      return;
    }

    int? estimate;
    if (_estimateController.text.isNotEmpty) {
      estimate = int.tryParse(_estimateController.text);
      if (estimate == null || estimate < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid time estimate')),
        );
        return;
      }
    }

    // Check for circular dependency
    if (_selectedDependencyId != null) {
      final taskProvider = context.read<TaskProvider>();
      if (DependencyValidator.hasCircularDependency(
        taskProvider.tasks,
        0, // 0 for new task
        _selectedDependencyId,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This would create a circular dependency!')),
        );
        return;
      }
    }

    // Save task
    context.read<TaskProvider>().addTaskWithDetails(
          description,
          estimate,
          _selectedDependencyId,
        );

    Navigator.pop(context);
  }

  Future<void> _confirmDelete(BuildContext context, Task task, TaskProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${AppConstants.emojiDelete} Delete Task'),
          content: Text('Are you sure you want to delete "${task.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && task.id != null) {
      provider.deleteTask(task.id!);
    }
  }
}
