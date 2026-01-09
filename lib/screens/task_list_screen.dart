import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
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
  final TextEditingController _newTagController = TextEditingController();
  int? _selectedDependencyId;
  Set<int> _selectedTagIds = {};

  @override
  void dispose() {
    _textController.dispose();
    _estimateController.dispose();
    _newTagController.dispose();
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: isBlocked
                    ? const Icon(Icons.lock, color: Colors.orange, size: 28)
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!task.completed)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditTaskDialog(context, task),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _confirmDelete(context, task, provider),
                    ),
                  ],
                ),
              ),
              // Tags row
              if (task.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: task.tags.map((tag) => Chip(
                      label: Text(
                        tag.name,
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      backgroundColor: tag.color,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    )).toList(),
                  ),
                ),
            ],
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
    _newTagController.clear();
    _selectedDependencyId = null;
    _selectedTagIds = {};

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final taskProvider = context.watch<TaskProvider>();
            final settingsProvider = context.watch<SettingsProvider>();
            final availableTasks = taskProvider.getAvailableTasksForDependency(null);
            final allTags = taskProvider.allTags;
            final showAdvanced = settingsProvider.advancedTaskOptions;

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
                        counterText: '',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),

                    // Advanced options toggle
                    Row(
                      children: [
                        Text(
                          'Advanced Options',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: showAdvanced,
                          onChanged: (value) => settingsProvider.setAdvancedTaskOptions(value),
                        ),
                      ],
                    ),

                    // Advanced fields (conditional)
                    if (showAdvanced) ...[
                      const SizedBox(height: 8),
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
                        initialValue: _selectedDependencyId,
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
                      const SizedBox(height: 16),

                      // Tags section
                      Text(
                        'Tags',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...allTags.map((tag) => FilterChip(
                            label: Text(tag.name),
                            selected: _selectedTagIds.contains(tag.id),
                            selectedColor: tag.color.withValues(alpha: 0.3),
                            checkmarkColor: tag.color,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTagIds.add(tag.id!);
                                } else {
                                  _selectedTagIds.remove(tag.id);
                                }
                              });
                            },
                          )),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('New'),
                            onPressed: () => _showNewTagDialog(context, setState),
                          ),
                        ],
                      ),
                    ],
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

  Future<void> _showNewTagDialog(BuildContext context, StateSetter parentSetState) async {
    _newTagController.clear();

    final tagName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Tag'),
          content: TextField(
            controller: _newTagController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tag Name',
              hintText: 'e.g., Work, Personal, Urgent',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _newTagController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (tagName != null && tagName.isNotEmpty && context.mounted) {
      final taskProvider = context.read<TaskProvider>();
      final newTag = await taskProvider.createTag(tagName);
      parentSetState(() {
        _selectedTagIds.add(newTag.id!);
      });
    }
  }

  Future<void> _saveTask(BuildContext context) async {
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
    final taskProvider = context.read<TaskProvider>();
    if (_selectedDependencyId != null) {
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
    final createdTask = await taskProvider.addTaskWithDetails(
      description,
      estimate,
      _selectedDependencyId,
    );

    // Add selected tags to the task
    if (createdTask != null && _selectedTagIds.isNotEmpty) {
      for (final tagId in _selectedTagIds) {
        await taskProvider.addTagToTask(createdTask.id!, tagId);
      }
    }

    if (context.mounted) {
      Navigator.pop(context);
    }
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

  Future<void> _showEditTaskDialog(BuildContext context, Task task) async {
    _textController.text = task.description;
    _estimateController.text = task.timeEstimate?.toString() ?? '';
    _selectedTagIds = task.tags.map((t) => t.id!).toSet();

    // Get available tasks first to validate dependency
    final taskProvider = context.read<TaskProvider>();
    final availableTasks = taskProvider.getAvailableTasksForDependency(task.id);

    // Only set dependency if it still exists in available tasks
    final dependencyExists = task.dependencyTaskId == null ||
        availableTasks.any((t) => t.id == task.dependencyTaskId);
    _selectedDependencyId = dependencyExists ? task.dependencyTaskId : null;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final taskProvider = context.watch<TaskProvider>();
            final settingsProvider = context.watch<SettingsProvider>();
            final availableTasks = taskProvider.getAvailableTasksForDependency(task.id);
            final allTags = taskProvider.allTags;
            final showAdvanced = settingsProvider.advancedTaskOptions;

            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _textController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Task Description',
                        hintText: AppConstants.addTaskHint,
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Text(
                          'Advanced Options',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: showAdvanced,
                          onChanged: (value) => settingsProvider.setAdvancedTaskOptions(value),
                        ),
                      ],
                    ),

                    if (showAdvanced) ...[
                      const SizedBox(height: 8),
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

                      DropdownButtonFormField<int?>(
                        initialValue: _selectedDependencyId,
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
                          ...availableTasks.map((t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(
                                  t.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedDependencyId = value);
                        },
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Tags',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...allTags.map((tag) => FilterChip(
                            label: Text(tag.name),
                            selected: _selectedTagIds.contains(tag.id),
                            selectedColor: tag.color.withValues(alpha: 0.3),
                            checkmarkColor: tag.color,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTagIds.add(tag.id!);
                                } else {
                                  _selectedTagIds.remove(tag.id);
                                }
                              });
                            },
                          )),
                          ActionChip(
                            avatar: const Icon(Icons.add, size: 18),
                            label: const Text('New'),
                            onPressed: () => _showNewTagDialog(context, setState),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => _updateTask(context, task),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateTask(BuildContext context, Task originalTask) async {
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

    final taskProvider = context.read<TaskProvider>();

    // Check for circular dependency
    if (_selectedDependencyId != null) {
      if (DependencyValidator.hasCircularDependency(
        taskProvider.tasks,
        originalTask.id!,
        _selectedDependencyId,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This would create a circular dependency!')),
        );
        return;
      }
    }

    // Update the task
    final updatedTask = originalTask.copyWith(
      description: description,
      timeEstimate: estimate,
      dependencyTaskId: _selectedDependencyId,
    );
    await taskProvider.updateTask(updatedTask);

    // Update tags - remove old, add new
    final currentTagIds = originalTask.tags.map((t) => t.id!).toSet();

    // Remove tags that are no longer selected
    for (final tagId in currentTagIds) {
      if (!_selectedTagIds.contains(tagId)) {
        await taskProvider.removeTagFromTask(originalTask.id!, tagId);
      }
    }

    // Add newly selected tags
    for (final tagId in _selectedTagIds) {
      if (!currentTagIds.contains(tagId)) {
        await taskProvider.addTagToTask(originalTask.id!, tagId);
      }
    }

    // Reload to get updated tags
    await taskProvider.loadTasks();

    if (context.mounted) {
      Navigator.pop(context);
    }
  }
}
