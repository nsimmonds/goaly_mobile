import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';

enum TimerState {
  idle,
  workActive,
  workPaused,
  breakActive,
  breakPaused,
}

enum SessionType {
  work,
  breakSession,
}

class TimerProvider with ChangeNotifier {
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  TimerState _state = TimerState.idle;
  SessionType _sessionType = SessionType.work;
  Task? _currentTask;

  DateTime? _sessionEndTime;
  DateTime? _pausedAt;
  int _totalPausedSeconds = 0;

  int _workMinutes = 25;
  int _breakMinutes = 5;
  bool _soundEnabled = true;

  TaskProvider? _taskProvider;

  // Getters
  TimerState get state => _state;
  SessionType get sessionType => _sessionType;
  Task? get currentTask => _currentTask;
  bool get isRunning => _state == TimerState.workActive || _state == TimerState.breakActive;
  bool get isPaused => _state == TimerState.workPaused || _state == TimerState.breakPaused;
  bool get isIdle => _state == TimerState.idle;
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;

  /// Get remaining seconds in current session
  int get remainingSeconds {
    if (_sessionEndTime == null) {
      // When idle, show the full duration for the current session type
      return totalSeconds;
    }

    if (isPaused && _pausedAt != null) {
      // Calculate remaining at pause time
      final remainingAtPause = _sessionEndTime!.difference(_pausedAt!).inSeconds;
      return remainingAtPause > 0 ? remainingAtPause : 0;
    }

    final now = DateTime.now();
    final remaining = _sessionEndTime!.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Get total seconds for current session
  int get totalSeconds {
    return _sessionType == SessionType.work
        ? _workMinutes * 60
        : _breakMinutes * 60;
  }

  /// Get elapsed seconds in current session (excluding pause time)
  int get elapsedSeconds {
    if (_sessionEndTime == null) return 0;

    final totalDuration = totalSeconds;
    final remaining = remainingSeconds;
    final elapsed = totalDuration - remaining;

    // Subtract paused time
    return (elapsed - _totalPausedSeconds).clamp(0, totalDuration);
  }

  /// Get progress (0.0 to 1.0)
  double get progress {
    final total = totalSeconds;
    if (total == 0) return 0.0;
    final remaining = remainingSeconds;
    return 1.0 - (remaining / total);
  }

  /// Update settings from SettingsProvider
  void updateSettings(SettingsProvider settings) {
    bool changed = false;
    if (_workMinutes != settings.workMinutes ||
        _breakMinutes != settings.breakMinutes ||
        _soundEnabled != settings.soundEnabled) {
      changed = true;
    }

    _workMinutes = settings.workMinutes;
    _breakMinutes = settings.breakMinutes;
    _soundEnabled = settings.soundEnabled;

    // Schedule notification for after build phase if values changed and we're idle
    if (changed && isIdle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Set TaskProvider dependency for auto-cycling
  void setTaskProvider(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
  }

  /// Start a new work session with a random task
  Future<void> startWorkSession(TaskProvider taskProvider) async {
    if (isRunning) return;

    // Get a random task
    _currentTask = await taskProvider.getRandomTask();

    _sessionType = SessionType.work;
    _sessionEndTime = DateTime.now().add(Duration(minutes: _workMinutes));
    _state = TimerState.workActive;
    _totalPausedSeconds = 0;
    _pausedAt = null;

    _startTimer();
    notifyListeners();
  }

  /// Start a break session
  void startBreakSession() {
    if (isRunning) return;

    _sessionType = SessionType.breakSession;
    _currentTask = null; // No task during break
    _sessionEndTime = DateTime.now().add(Duration(minutes: _breakMinutes));
    _state = TimerState.breakActive;
    _totalPausedSeconds = 0;
    _pausedAt = null;

    _startTimer();
    notifyListeners();
  }

  /// Pause the current session
  void pause() {
    if (!isRunning) return;

    _pausedAt = DateTime.now();
    _state = _sessionType == SessionType.work
        ? TimerState.workPaused
        : TimerState.breakPaused;
    _timer?.cancel();

    notifyListeners();
  }

  /// Resume the paused session
  void resume() {
    if (!isPaused) return;

    if (_pausedAt != null) {
      final pauseDuration = DateTime.now().difference(_pausedAt!).inSeconds;
      _totalPausedSeconds += pauseDuration;
      // Extend end time by pause duration
      _sessionEndTime = _sessionEndTime!.add(Duration(seconds: pauseDuration));
    }

    _state = _sessionType == SessionType.work
        ? TimerState.workActive
        : TimerState.breakActive;
    _pausedAt = null;

    _startTimer();
    notifyListeners();
  }

  /// Stop the current session and return to idle
  void stop() {
    _timer?.cancel();
    _state = TimerState.idle;
    _sessionType = SessionType.work;
    _currentTask = null;
    _sessionEndTime = null;
    _pausedAt = null;
    _totalPausedSeconds = 0;

    notifyListeners();
  }

  /// Complete the current task and ask user what to do next
  Future<void> completeCurrentTask(BuildContext context) async {
    if (_currentTask == null || !isRunning) return;

    // Calculate time spent (excluding pauses)
    final timeSpent = elapsedSeconds;

    // Stop the timer
    _timer?.cancel();
    _state = TimerState.idle;

    // Mark task complete with accumulated time
    if (_taskProvider != null && _currentTask!.id != null) {
      await _taskProvider!.completeTaskWithTime(
        _currentTask!.id!,
        timeSpent,
      );
    }

    final completedTask = _currentTask;
    _currentTask = null;
    _sessionEndTime = null;
    _sessionType = SessionType.work;
    _totalPausedSeconds = 0;
    _pausedAt = null;
    notifyListeners();

    // Show dialog asking user what to do next
    if (context.mounted) {
      await _showCompletionDialog(context, completedTask!);
    }
  }

  Future<void> _showCompletionDialog(BuildContext context, Task completedTask) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Task Complete!'),
        content: Text('Great job finishing "${completedTask.description}"!\n\nWhat would you like to do next?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'celebrate'),
            child: const Text('Celebrate 🎊'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, 'keep_working'),
            child: const Text('Keep Working'),
          ),
        ],
      ),
    );

    if (result == 'keep_working' && _taskProvider != null) {
      // Start new work session immediately
      await startWorkSession(_taskProvider!);
    }
    // If 'celebrate', stay in idle state
  }

  /// Internal method to start the countdown timer
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        _onSessionComplete();
        timer.cancel();
      } else {
        notifyListeners(); // Update UI every second
      }
    });
  }

  /// Handle session completion
  Future<void> _onSessionComplete() async {
    _timer?.cancel();

    // Play sound
    if (_soundEnabled) {
      await _playCompletionSound();
    }

    if (_sessionType == SessionType.work) {
      // Work completed - accumulate time before transitioning
      if (_currentTask != null && _taskProvider != null && _currentTask!.id != null) {
        final timeSpent = totalSeconds - _totalPausedSeconds; // Full session minus pauses
        await _taskProvider!.accumulateTaskTime(
          _currentTask!.id!,
          timeSpent,
        );
      }

      // Auto-start break
      _sessionType = SessionType.breakSession;
      _currentTask = null;
      _sessionEndTime = DateTime.now().add(Duration(minutes: _breakMinutes));
      _state = TimerState.breakActive;
      _totalPausedSeconds = 0;
      _pausedAt = null;

      _startTimer();
      notifyListeners();
    } else {
      // Break completed - auto-start next work session
      if (_taskProvider != null && _taskProvider!.hasIncompleteTasks) {
        _currentTask = await _taskProvider!.getRandomTask();

        if (_currentTask != null) {
          _sessionType = SessionType.work;
          _sessionEndTime = DateTime.now().add(Duration(minutes: _workMinutes));
          _state = TimerState.workActive;
          _totalPausedSeconds = 0;
          _pausedAt = null;

          _startTimer();
          notifyListeners();
        } else {
          // No task available - return to idle
          _state = TimerState.idle;
          _sessionType = SessionType.work;
          notifyListeners();
        }
      } else {
        // No incomplete tasks - return to idle
        _state = TimerState.idle;
        _sessionType = SessionType.work;
        notifyListeners();
      }
    }
  }

  /// Play completion sound
  Future<void> _playCompletionSound() async {
    try {
      // Play the notification sound (WAV format)
      // Download a free sound from freesound.org or pixabay.com
      // and save it as assets/sounds/notification.wav
      await _audioPlayer.play(AssetSource('sounds/notification.wav'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
      // Fail silently - sound is optional
    }
  }

  /// Format seconds as MM:SS
  String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
