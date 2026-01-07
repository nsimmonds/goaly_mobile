import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../config/constants.dart';
import '../screens/task_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _currentBreakSuggestion;
  bool _wasInBreak = false;

  @override
  void initState() {
    super.initState();
    // Load tasks on startup and link providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('Loading tasks...');
      final taskProvider = context.read<TaskProvider>();
      final timerProvider = context.read<TimerProvider>();

      // Link TaskProvider to TimerProvider for auto-cycling
      timerProvider.setTaskProvider(taskProvider);

      taskProvider.loadTasks().then((_) {
        print('Tasks loaded: ${taskProvider.tasks.length}');
      }).catchError((e) {
        print('Error loading tasks: $e');
      });
    });
  }

  void _updateBreakSuggestion(TimerProvider timer, SettingsProvider settings) {
    final isInBreak = timer.sessionType == SessionType.breakSession &&
        (timer.isRunning || timer.isPaused);

    if (isInBreak && !_wasInBreak) {
      // Just entered break, get new suggestion
      _currentBreakSuggestion = settings.getRandomBreakSuggestion();
    } else if (!isInBreak) {
      // Not in break, clear suggestion
      _currentBreakSuggestion = null;
    }
    _wasInBreak = isInBreak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${AppConstants.emojiGoal} ${AppConstants.appName}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer3<TimerProvider, TaskProvider, SettingsProvider>(
        builder: (context, timer, tasks, settings, _) {
          // Update break suggestion state
          _updateBreakSuggestion(timer, settings);

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Session Type Indicator
                  _buildSessionIndicator(timer),
                  const SizedBox(height: 32),

                  // Circular Timer Display
                  _buildCircularTimer(timer),
                  const SizedBox(height: 32),

                  // Current Task Display (work) or Break Suggestion (break)
                  if (timer.sessionType == SessionType.work)
                    _buildCurrentTask(timer)
                  else if (_currentBreakSuggestion != null)
                    _buildBreakSuggestion(),
                  const SizedBox(height: 48),

                  // Control Buttons
                  _buildControlButtons(timer, tasks),
                  const SizedBox(height: 24),

                  // Navigate to Tasks Button
                  if (!timer.isRunning)
                    _buildNavigateToTasksButton(context, tasks),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionIndicator(TimerProvider timer) {
    final emoji = timer.sessionType == SessionType.work
        ? AppConstants.emojiTimer
        : AppConstants.emojiBreak;
    final text = timer.sessionType == SessionType.work
        ? AppConstants.workSession
        : AppConstants.breakSession;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          '$emoji $text',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildCircularTimer(TimerProvider timer) {
    final progress = timer.progress;
    final remaining = timer.formatTime(timer.remainingSeconds);

    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 280,
            height: 280,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              color: timer.sessionType == SessionType.work
                  ? Colors.blue
                  : Colors.green,
            ),
          ),
          // Time display
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                remaining,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (timer.isPaused)
                const Text(
                  '⏸️ Paused',
                  style: TextStyle(fontSize: 18, color: Colors.orange),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTask(TimerProvider timer) {
    if (timer.currentTask == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${AppConstants.emojiGoal} Current Task',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              timer.currentTask!.description,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakSuggestion() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              '💡 Suggestion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentBreakSuggestion!,
              style: TextStyle(
                fontSize: 20,
                color: Colors.green.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons(TimerProvider timer, TaskProvider tasks) {
    if (timer.isIdle) {
      return Column(
        children: [
          // Start Work Session Button
          ElevatedButton.icon(
            onPressed: tasks.hasIncompleteTasks
                ? () => timer.startWorkSession(tasks)
                : null,
            icon: const Icon(Icons.play_arrow, size: 32),
            label: const Text(
              'Start Work Session',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
          ),
          if (!tasks.hasIncompleteTasks)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Add a task to start working!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
        ],
      );
    } else if (timer.isRunning) {
      // Check if it's a work session with a task
      if (timer.sessionType == SessionType.work && timer.currentTask != null) {
        return Column(
          children: [
            // Task Complete button (prominent)
            ElevatedButton.icon(
              onPressed: () => timer.completeCurrentTask(context),
              icon: const Icon(Icons.check_circle, size: 28),
              label: const Text(
                'Task Complete!',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Pause and Stop buttons (smaller row)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => timer.pause(),
                  icon: const Icon(Icons.pause, size: 20),
                  label: const Text('Pause'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => timer.stop(),
                  icon: Text(AppConstants.emojiStop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        // Break session - only Pause/Stop
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => timer.pause(),
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => timer.stop(),
              icon: Text(AppConstants.emojiStop),
              label: const Text('Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ],
        );
      }
    } else {
      // Paused
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Resume Button
          ElevatedButton.icon(
            onPressed: () => timer.resume(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
          const SizedBox(width: 16),
          // Stop Button
          ElevatedButton.icon(
            onPressed: () => timer.stop(),
            icon: Text(AppConstants.emojiStop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildNavigateToTasksButton(BuildContext context, TaskProvider tasks) {
    return TextButton.icon(
      onPressed: () {
        print('Navigate to tasks button pressed');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskListScreen()),
        );
      },
      icon: Text(AppConstants.emojiTasks),
      label: Text(
        tasks.hasIncompleteTasks
            ? 'Manage Tasks (${tasks.incompleteTasks.length})'
            : 'Add Your First Task',
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}
