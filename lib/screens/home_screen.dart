import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../config/constants.dart';
import '../screens/task_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/stats_screen.dart';
import '../services/notification_service.dart';
import 'package:app_settings/app_settings.dart';

/// Paints text along a subtle arc
class _ArcTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double radius;

  _ArcTextPainter({
    required this.text,
    required this.style,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calculate total width to center the text
    double totalWidth = 0;
    final charWidths = <double>[];
    for (final char in text.characters) {
      textPainter.text = TextSpan(text: char, style: style);
      textPainter.layout();
      charWidths.add(textPainter.width);
      totalWidth += textPainter.width;
    }

    // Calculate the total angle the text will span
    final totalAngle = totalWidth / radius;

    // Start from center, offset by half the total angle
    double currentAngle = -totalAngle / 2;

    // Center point - arc center is below the widget
    final centerX = size.width / 2;
    final centerY = size.height / 2 + radius;

    int i = 0;
    for (final char in text.characters) {
      textPainter.text = TextSpan(text: char, style: style);
      textPainter.layout();

      final charWidth = charWidths[i];
      final charAngle = charWidth / radius;

      // Position at middle of this character's arc segment
      final angle = currentAngle + charAngle / 2;

      final x = centerX + radius * math.sin(angle);
      final y = centerY - radius * math.cos(angle);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      textPainter.paint(
        canvas,
        Offset(-charWidth / 2, -textPainter.height / 2),
      );
      canvas.restore();

      currentAngle += charAngle;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _ArcTextPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.style != style;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String? _currentBreakSuggestion;
  bool _wasInBreak = false;
  bool _feedbackClicked = true; // Default to true (no highlight) until loaded
  bool _notificationPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFeedbackClickedState();
    _checkNotificationPermission();
    // Load tasks on startup and link providers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kDebugMode) {
        debugPrint('Loading tasks...');
      }
      final taskProvider = context.read<TaskProvider>();
      final timerProvider = context.read<TimerProvider>();

      // Link TaskProvider to TimerProvider for auto-cycling
      timerProvider.setTaskProvider(taskProvider);

      taskProvider.loadTasks().then((_) {
        if (kDebugMode) {
          debugPrint('Tasks loaded: ${taskProvider.tasks.length}');
        }
      }).catchError((e) {
        if (kDebugMode) {
          debugPrint('Error loading tasks: $e');
        }
      });
    });
  }

  Future<void> _checkNotificationPermission() async {
    final granted = await NotificationService.instance.checkPermissionStatus();
    if (mounted) {
      setState(() {
        _notificationPermissionDenied = !granted;
      });
    }
  }

  Future<void> _loadFeedbackClickedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _feedbackClicked = prefs.getBool(AppConstants.keyFeedbackClicked) ?? false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (kDebugMode) {
      debugPrint('HomeScreen: App lifecycle state changed to $state');
    }
    if (state == AppLifecycleState.resumed) {
      // Check if timer should have completed while app was backgrounded
      final timer = context.read<TimerProvider>();
      timer.checkForMissedCompletion();

      // Check notification permission status on resume
      _checkNotificationPermission();
    }
  }

  Future<void> _openFeedbackForm() async {
    // Mark as clicked and persist
    if (!_feedbackClicked) {
      setState(() => _feedbackClicked = true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyFeedbackClicked, true);
    }

    final uri = Uri.parse(AppConstants.feedbackFormUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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

  /// Start a work session, optionally showing screen pinning prompt
  Future<void> _startWorkSession(TimerProvider timer, TaskProvider tasks) async {
    final settings = context.read<SettingsProvider>();

    if (settings.focusLockEnabled) {
      final proceed = await _showScreenPinningDialog();
      if (proceed != true) return;
    }

    timer.startWorkSession(tasks);
  }

  /// Show dialog explaining how to enable screen pinning
  Future<bool?> _showScreenPinningDialog() {
    final isAndroid = Platform.isAndroid;
    final isIOS = Platform.isIOS;

    String instructions;
    if (isAndroid) {
      instructions = '1. Open recent apps (square button)\n'
          '2. Tap the app icon at the top of Goaly\'s card\n'
          '3. Select "Pin" or "Screen pin"\n\n'
          'To unpin: Hold Back + Overview buttons';
    } else if (isIOS) {
      instructions = '1. Triple-click the side button to start Guided Access\n'
          '2. Tap "Start" in the top right\n\n'
          'To exit: Triple-click side button and enter passcode\n\n'
          'Note: Enable in Settings → Accessibility → Guided Access first';
    } else {
      // Desktop - not applicable
      instructions = 'Screen pinning is only available on mobile devices.';
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(AppConstants.emojiLock),
            const SizedBox(width: 8),
            const Text('Pin Your Screen'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'For distraction-free focus, pin Goaly to your screen:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(instructions),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
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
          if (AppConstants.feedbackModeEnabled)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: _feedbackClicked
                  ? null
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
              child: IconButton(
                icon: const Icon(Icons.feedback_outlined),
                tooltip: 'Send Feedback',
                onPressed: _openFeedbackForm,
              ),
            ),
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

          return Column(
            children: [
              // Notification permission warning banner
              if (_notificationPermissionDenied)
                _buildNotificationWarningBanner(),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Unified Timer-Button
                        _buildTimerButton(timer, tasks),
                  const SizedBox(height: 24),

                  // Control Buttons (pause/stop when running)
                  if (timer.isRunning || timer.isPaused)
                    _buildControlButtons(timer),
                  if (timer.isRunning || timer.isPaused)
                    const SizedBox(height: 24),

                  // Flow mode toggle (always visible)
                  _buildFlowModeToggle(timer, tasks),
                  const SizedBox(height: 24),

                        // Navigate to Tasks Button
                        if (timer.isIdle)
                          _buildNavigateToTasksButton(context, tasks),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Warning banner for denied notification permissions
  Widget _buildNotificationWarningBanner() {
    return MaterialBanner(
      backgroundColor: Colors.amber.shade100,
      leading: Icon(Icons.notifications_off, color: Colors.amber.shade800),
      content: Text(
        'Notifications are disabled. You won\'t be alerted when timers complete.',
        style: TextStyle(color: Colors.amber.shade900),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() => _notificationPermissionDenied = false);
          },
          child: const Text('Dismiss'),
        ),
        TextButton(
          onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.notification),
          child: const Text('Open Settings'),
        ),
      ],
    );
  }

  /// Unified timer-button widget
  Widget _buildTimerButton(TimerProvider timer, TaskProvider tasks) {
    final remaining = timer.formatTime(timer.remainingSeconds);
    final progress = timer.progress;

    // Determine colors based on state
    Color baseColor;
    Color progressColor;
    Color textColor;

    if (timer.isIdle) {
      baseColor = Colors.green;
      progressColor = Colors.green.shade700;
      textColor = Colors.white;
    } else if (timer.sessionType == SessionType.work) {
      baseColor = Colors.blue;
      progressColor = Colors.blue.shade700;
      textColor = Colors.white;
    } else {
      baseColor = Colors.purple;
      progressColor = Colors.purple.shade700;
      textColor = Colors.white;
    }

    // Determine text content
    String mainText;
    String subscript;

    if (timer.isIdle) {
      mainText = 'Start Work\nSession';
      subscript = tasks.hasIncompleteTasks ? 'tap to start' : 'add a task first';
    } else if (timer.isPaused) {
      mainText = timer.sessionType == SessionType.work
          ? (timer.currentTask?.description ?? 'Work Session')
          : 'Break Time';
      subscript = 'tap to resume';
    } else if (timer.sessionType == SessionType.work) {
      mainText = timer.currentTask?.description ?? 'Work Session';
      subscript = 'tap if complete';
    } else {
      mainText = 'Break Time';
      subscript = _currentBreakSuggestion ?? 'take a break';
    }

    // Handle tap
    void onTap() {
      if (timer.isIdle) {
        if (tasks.hasIncompleteTasks) {
          _startWorkSession(timer, tasks);
        }
      } else if (timer.isPaused) {
        timer.resume();
      } else if (timer.sessionType == SessionType.work) {
        timer.completeCurrentTask(context);
      } else {
        // Break session - skip break
        timer.skipBreak();
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 280,
        height: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Filled background circle
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseColor,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Progress ring (only when not idle)
            if (!timer.isIdle)
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  color: progressColor,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main text (task name or action) - with subtle arc
                  SizedBox(
                    width: 220,
                    height: 60,
                    child: CustomPaint(
                      painter: _ArcTextPainter(
                        text: mainText.replaceAll('\n', ' '),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        radius: 300, // Large radius = subtle curve
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Time display
                  Text(
                    remaining,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subscript
                  if (timer.isPaused)
                    Text(
                      '⏸️ Paused',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade200,
                      ),
                    ),
                  Text(
                    subscript,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Control buttons - icon-only pause/stop (or resume when paused)
  Widget _buildControlButtons(TimerProvider timer) {
    if (timer.isRunning) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pause button (icon only)
          IconButton.filled(
            onPressed: () => timer.pause(),
            icon: const Icon(Icons.pause),
            tooltip: 'Pause',
          ),
          const SizedBox(width: 24),
          // Stop button (icon only)
          IconButton.filled(
            onPressed: () => timer.stop(),
            icon: const Icon(Icons.stop),
            tooltip: 'Stop',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      );
    } else if (timer.isPaused) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Resume button (icon only)
          IconButton.filled(
            onPressed: () => timer.resume(),
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Resume',
          ),
          const SizedBox(width: 24),
          // Stop button (icon only)
          IconButton.filled(
            onPressed: () => timer.stop(),
            icon: const Icon(Icons.stop),
            tooltip: 'Stop',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// Show flow mode explanation dialog
  void _showFlowModeHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sync, color: Colors.blue),
            SizedBox(width: 8),
            Text('Flow Mode'),
          ],
        ),
        content: const Text(
          'Flow mode keeps you focused on a single task across multiple pomodoro cycles.\n\n'
          'When enabled, your chosen task will persist through breaks instead of switching to a random task.\n\n'
          'Great for deep work sessions on complex tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Flow mode toggle
  Widget _buildFlowModeToggle(TimerProvider timer, TaskProvider tasks) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (timer.flowMode)
          const Icon(Icons.sync, size: 18, color: Colors.blue),
        if (timer.flowMode) const SizedBox(width: 8),
        Text(
          'Flow mode',
          style: TextStyle(
            color: timer.flowMode ? Colors.blue : Colors.grey,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.help_outline,
            size: 18,
            color: Colors.grey.shade500,
          ),
          onPressed: () => _showFlowModeHelp(),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'What is flow mode?',
        ),
        const SizedBox(width: 4),
        Switch(
          value: timer.flowMode,
          onChanged: (enabled) async {
            if (enabled) {
              // If idle, show task picker
              if (timer.isIdle && tasks.hasIncompleteTasks) {
                final selectedTask = await _showTaskPicker(tasks);
                if (selectedTask != null) {
                  timer.setFlowMode(true, task: selectedTask);
                }
              } else if (timer.isRunning || timer.isPaused) {
                // Mid-session, lock onto current task
                timer.setFlowMode(true);
              }
            } else {
              timer.setFlowMode(false);
            }
          },
        ),
      ],
    );
  }

  /// Task picker dialog for flow mode
  Future<Task?> _showTaskPicker(TaskProvider tasks) async {
    final incompleteTasks = tasks.incompleteTasks
        .where((t) => !tasks.isTaskBlocked(t))
        .toList();

    if (incompleteTasks.isEmpty) return null;

    return showDialog<Task>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Focus Task'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: incompleteTasks.length,
            itemBuilder: (context, index) {
              final task = incompleteTasks[index];
              return ListTile(
                title: Text(task.description),
                onTap: () => Navigator.pop(context, task),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigateToTasksButton(BuildContext context, TaskProvider tasks) {
    return TextButton.icon(
      onPressed: () {
        if (kDebugMode) {
          debugPrint('Navigate to tasks button pressed');
        }
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
