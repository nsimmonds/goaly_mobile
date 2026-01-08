import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _searchQuery = '';
  int? _selectedTagId;

  List<Task> _getFilteredTasks(List<Task> completedTasks) {
    var filtered = completedTasks;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((t) =>
        t.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Filter by tag
    if (_selectedTagId != null) {
      filtered = filtered.where((t) =>
        t.tags.any((tag) => tag.id == _selectedTagId)
      ).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Statistics'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, _) {
          final allCompletedTasks = taskProvider.completedTasks;
          final filteredTasks = _getFilteredTasks(allCompletedTasks);
          final allTags = taskProvider.allTags;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Section
                _buildFilterSection(context, allTags),
                const SizedBox(height: 24),

                // Summary Section
                _buildSectionHeader(context, 'Overall Summary'),
                const SizedBox(height: 12),
                _buildSummaryCards(context, filteredTasks),
                const SizedBox(height: 32),

                // Time Breakdown Section
                _buildSectionHeader(context, 'Time Breakdown'),
                const SizedBox(height: 12),
                _buildTimeBreakdown(context, filteredTasks),
                const SizedBox(height: 32),

                // Estimate Accuracy Section
                _buildSectionHeader(context, 'Estimate Accuracy'),
                const SizedBox(height: 12),
                _buildEstimateAccuracy(context, filteredTasks),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context, List<dynamic> allTags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search box
        TextField(
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 12),

        // Tag filter chips
        if (allTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _selectedTagId == null,
                onSelected: (_) => setState(() => _selectedTagId = null),
              ),
              ...allTags.map((tag) => FilterChip(
                label: Text(tag.name),
                selected: _selectedTagId == tag.id,
                selectedColor: tag.color.withValues(alpha: 0.3),
                checkmarkColor: tag.color,
                onSelected: (selected) {
                  setState(() {
                    _selectedTagId = selected ? tag.id : null;
                  });
                },
              )),
            ],
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, List<Task> completedTasks) {
    final totalTasks = completedTasks.length;
    final totalTimeSeconds = completedTasks.fold<int>(
      0, (sum, task) => sum + task.totalTimeSpent,
    );
    final avgTimeSeconds = totalTasks > 0 ? totalTimeSeconds ~/ totalTasks : 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle,
            iconColor: Colors.green,
            label: 'Completed',
            value: '$totalTasks',
            subtitle: 'tasks',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.timer,
            iconColor: Colors.blue,
            label: 'Total Time',
            value: _formatDuration(totalTimeSeconds),
            subtitle: 'tracked',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.speed,
            iconColor: Colors.orange,
            label: 'Average',
            value: _formatDuration(avgTimeSeconds),
            subtitle: 'per task',
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBreakdown(BuildContext context, List<Task> completedTasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    // Filter tasks by time period
    final todayTasks = completedTasks.where((t) =>
      t.completedAt != null && t.completedAt!.isAfter(today)
    ).toList();

    final weekTasks = completedTasks.where((t) =>
      t.completedAt != null && t.completedAt!.isAfter(weekStart)
    ).toList();

    final monthTasks = completedTasks.where((t) =>
      t.completedAt != null && t.completedAt!.isAfter(monthStart)
    ).toList();

    return Column(
      children: [
        _TimeBreakdownRow(
          label: 'Today',
          tasks: todayTasks,
          icon: Icons.today,
        ),
        const SizedBox(height: 8),
        _TimeBreakdownRow(
          label: 'This Week',
          tasks: weekTasks,
          icon: Icons.date_range,
        ),
        const SizedBox(height: 8),
        _TimeBreakdownRow(
          label: 'This Month',
          tasks: monthTasks,
          icon: Icons.calendar_month,
        ),
        const SizedBox(height: 8),
        _TimeBreakdownRow(
          label: 'All Time',
          tasks: completedTasks,
          icon: Icons.all_inclusive,
        ),
      ],
    );
  }

  Widget _buildEstimateAccuracy(BuildContext context, List<Task> completedTasks) {
    // Only consider tasks with both estimates and tracked time
    final tasksWithEstimates = completedTasks.where((t) =>
      t.timeEstimate != null && t.totalTimeSpent > 0
    ).toList();

    if (tasksWithEstimates.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Complete tasks with time estimates to see accuracy stats',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    int underEstimated = 0;
    int onTarget = 0;
    int overEstimated = 0;
    int beatEstimate = 0;
    int totalEstimatedSeconds = 0;
    int totalActualSeconds = 0;

    for (final task in tasksWithEstimates) {
      final estimatedSeconds = task.timeEstimate! * 60;
      final actualSeconds = task.totalTimeSpent;
      totalEstimatedSeconds += estimatedSeconds;
      totalActualSeconds += actualSeconds;

      // Beat estimate = completed in less time than estimated
      if (actualSeconds < estimatedSeconds) {
        beatEstimate++;
      }

      final ratio = actualSeconds / estimatedSeconds;
      if (ratio > 1.2) {
        underEstimated++; // Took longer than estimated
      } else if (ratio < 0.8) {
        overEstimated++; // Took less time than estimated
      } else {
        onTarget++; // Within 20% of estimate
      }
    }

    final accuracyPercent = totalEstimatedSeconds > 0
        ? ((totalActualSeconds / totalEstimatedSeconds) * 100).round()
        : 100;

    final beatPercent = tasksWithEstimates.isNotEmpty
        ? ((beatEstimate / tasksWithEstimates.length) * 100).round()
        : 0;

    return Column(
      children: [
        // Beat estimate card
        Card(
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  beatPercent >= 50 ? Icons.emoji_events : Icons.trending_up,
                  color: Colors.teal,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$beatPercent% beat their estimate',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$beatEstimate of ${tasksWithEstimates.length} tasks completed under estimate',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Overall accuracy
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  accuracyPercent > 120 ? Icons.trending_up :
                  accuracyPercent < 80 ? Icons.trending_down :
                  Icons.check_circle,
                  color: accuracyPercent > 120 ? Colors.orange :
                         accuracyPercent < 80 ? Colors.blue :
                         Colors.green,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall: $accuracyPercent% of estimates',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        accuracyPercent > 120 ? 'Tasks take longer than estimated' :
                        accuracyPercent < 80 ? 'Tasks finish faster than estimated' :
                        'Estimates are on target!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Breakdown
        Row(
          children: [
            Expanded(
              child: _AccuracyChip(
                label: 'Under',
                count: underEstimated,
                color: Colors.orange,
                icon: Icons.arrow_upward,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AccuracyChip(
                label: 'On Target',
                count: onTarget,
                color: Colors.green,
                icon: Icons.check,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AccuracyChip(
                label: 'Over',
                count: overEstimated,
                color: Colors.blue,
                icon: Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBreakdownRow extends StatelessWidget {
  final String label;
  final List<Task> tasks;
  final IconData icon;

  const _TimeBreakdownRow({
    required this.label,
    required this.tasks,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final taskCount = tasks.length;
    final totalSeconds = tasks.fold<int>(
      0, (sum, task) => sum + task.totalTimeSpent,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$taskCount tasks',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _formatDuration(totalSeconds),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) {
      return '0m';
    } else if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '${minutes}m';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}

class _AccuracyChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _AccuracyChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
