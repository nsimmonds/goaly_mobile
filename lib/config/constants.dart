// App Constants
class AppConstants {
  // Timer Durations (in minutes)
  static const int defaultWorkMinutes = 25;
  static const int defaultBreakMinutes = 5;

  // Database
  static const String dbName = 'goaly.db';
  static const int dbVersion = 3;

  // Emojis (matching Python version)
  static const String emojiGoal = '🥅';
  static const String emojiTimer = '⏰';
  static const String emojiSuccess = '🌠';
  static const String emojiBreak = '☕';
  static const String emojiCelebrate = '🎉';
  static const String emojiStop = '🛑';
  static const String emojiTasks = '📝';
  static const String emojiDelete = '🗑️';
  static const String emojiSettings = '⚙️';
  static const String emojiDarkMode = '🌙';
  static const String emojiLightMode = '☀️';
  static const String emojiLock = '🔒';
  static const String emojiEstimate = '⏱️';

  // App Strings
  static const String appName = 'Goaly';
  static const String workSession = 'Work Session';
  static const String breakSession = 'Break Session';
  static const String noTasksMessage = 'No tasks yet. Add one to get started!';
  static const String addTaskHint = 'What do you need to work on?';

  // Settings Keys (SharedPreferences)
  static const String keyDarkMode = 'dark_mode';
  static const String keyWorkMinutes = 'work_minutes';
  static const String keyBreakMinutes = 'break_minutes';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keySuggestionsEnabled = 'suggestions_enabled';
  static const String keyBreakSuggestions = 'break_suggestions';
  static const String keyCelebrationSuggestions = 'celebration_suggestions';
  static const String keyAdvancedTaskOptions = 'advanced_task_options';

  // Default Suggestions
  static const List<String> defaultBreakSuggestions = [
    'Dance in place!',
    'Touch grass!',
    'Do some stretches!',
    'Get a glass of water!',
    'Look out the window!',
    'Take some deep breaths!',
    'Do 10 jumping jacks!',
    'Pet your pet!',
  ];

  static const List<String> defaultCelebrationSuggestions = [
    'Buy yourself something nice!',
    'You can have that treat!',
    'Take a victory lap!',
    'Tell someone about your accomplishment!',
    'Do a happy dance!',
    'Treat yourself to a snack!',
    'You earned a longer break!',
    'Pat yourself on the back!',
  ];
}
