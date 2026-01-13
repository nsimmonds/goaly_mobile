import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  final Random _random = Random();

  // Settings
  // null = use system theme (default), true = dark, false = light
  bool? _isDarkMode;
  int _workMinutes = AppConstants.defaultWorkMinutes;
  int _breakMinutes = AppConstants.defaultBreakMinutes;
  bool _soundEnabled = true;
  bool _suggestionsEnabled = true;
  bool _advancedTaskOptions = false;
  bool _focusLockEnabled = false;
  List<String> _breakSuggestions = List.from(AppConstants.defaultBreakSuggestions);
  List<String> _celebrationSuggestions = List.from(AppConstants.defaultCelebrationSuggestions);

  // Getters
  bool get useSystemTheme => _isDarkMode == null;
  bool get isDarkMode => _isDarkMode ?? _getSystemDarkMode();
  ThemeMode get themeMode {
    if (_isDarkMode == null) return ThemeMode.system;
    return _isDarkMode! ? ThemeMode.dark : ThemeMode.light;
  }

  /// Get current system dark mode setting
  bool _getSystemDarkMode() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get isInitialized => _isInitialized;
  bool get suggestionsEnabled => _suggestionsEnabled;
  bool get advancedTaskOptions => _advancedTaskOptions;
  bool get focusLockEnabled => _focusLockEnabled;
  List<String> get breakSuggestions => List.unmodifiable(_breakSuggestions);
  List<String> get celebrationSuggestions => List.unmodifiable(_celebrationSuggestions);

  /// Initialize settings from SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    _isDarkMode = _prefs.getBool(AppConstants.keyDarkMode); // null = system theme
    _workMinutes = _prefs.getInt(AppConstants.keyWorkMinutes) ?? AppConstants.defaultWorkMinutes;
    _breakMinutes = _prefs.getInt(AppConstants.keyBreakMinutes) ?? AppConstants.defaultBreakMinutes;
    _soundEnabled = _prefs.getBool(AppConstants.keySoundEnabled) ?? true;
    _suggestionsEnabled = _prefs.getBool(AppConstants.keySuggestionsEnabled) ?? true;
    _advancedTaskOptions = _prefs.getBool(AppConstants.keyAdvancedTaskOptions) ?? false;
    _focusLockEnabled = _prefs.getBool(AppConstants.keyFocusLockEnabled) ?? false;

    final breakJson = _prefs.getString(AppConstants.keyBreakSuggestions);
    if (breakJson != null) {
      try {
        _breakSuggestions = List<String>.from(jsonDecode(breakJson));
      } catch (_) {
        _breakSuggestions = List.from(AppConstants.defaultBreakSuggestions);
      }
    }

    final celebrationJson = _prefs.getString(AppConstants.keyCelebrationSuggestions);
    if (celebrationJson != null) {
      try {
        _celebrationSuggestions = List<String>.from(jsonDecode(celebrationJson));
      } catch (_) {
        _celebrationSuggestions = List.from(AppConstants.defaultCelebrationSuggestions);
      }
    }
  }

  /// Set whether to use system theme
  Future<void> setUseSystemTheme(bool value) async {
    if (value) {
      // Switch to system theme
      _isDarkMode = null;
      await _prefs.remove(AppConstants.keyDarkMode);
    } else {
      // Switch to explicit theme, inherit from current system setting
      _isDarkMode = _getSystemDarkMode();
      await _prefs.setBool(AppConstants.keyDarkMode, _isDarkMode!);
    }
    notifyListeners();
  }

  /// Toggle dark mode (only works when not using system theme)
  Future<void> toggleDarkMode() async {
    if (_isDarkMode == null) return; // Don't toggle if using system theme
    _isDarkMode = !_isDarkMode!;
    await _prefs.setBool(AppConstants.keyDarkMode, _isDarkMode!);
    notifyListeners();
  }

  /// Set work duration in minutes
  Future<void> setWorkMinutes(int minutes) async {
    _workMinutes = minutes;
    await _prefs.setInt(AppConstants.keyWorkMinutes, minutes);
    notifyListeners();
  }

  /// Set break duration in minutes
  Future<void> setBreakMinutes(int minutes) async {
    _breakMinutes = minutes;
    await _prefs.setInt(AppConstants.keyBreakMinutes, minutes);
    notifyListeners();
  }

  /// Toggle sound alerts
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _prefs.setBool(AppConstants.keySoundEnabled, _soundEnabled);
    notifyListeners();
  }

  /// Toggle suggestions
  Future<void> toggleSuggestions() async {
    _suggestionsEnabled = !_suggestionsEnabled;
    await _prefs.setBool(AppConstants.keySuggestionsEnabled, _suggestionsEnabled);
    notifyListeners();
  }

  /// Set advanced task options visibility
  Future<void> setAdvancedTaskOptions(bool value) async {
    _advancedTaskOptions = value;
    await _prefs.setBool(AppConstants.keyAdvancedTaskOptions, value);
    notifyListeners();
  }

  /// Toggle focus lock (screen pinning prompt)
  Future<void> toggleFocusLock() async {
    _focusLockEnabled = !_focusLockEnabled;
    await _prefs.setBool(AppConstants.keyFocusLockEnabled, _focusLockEnabled);
    notifyListeners();
  }

  /// Get a random break suggestion
  String? getRandomBreakSuggestion() {
    if (!_suggestionsEnabled || _breakSuggestions.isEmpty) return null;
    return _breakSuggestions[_random.nextInt(_breakSuggestions.length)];
  }

  /// Get a random celebration suggestion
  String? getRandomCelebrationSuggestion() {
    if (!_suggestionsEnabled || _celebrationSuggestions.isEmpty) return null;
    return _celebrationSuggestions[_random.nextInt(_celebrationSuggestions.length)];
  }

  /// Add a break suggestion
  Future<void> addBreakSuggestion(String suggestion) async {
    _breakSuggestions.add(suggestion);
    await _prefs.setString(AppConstants.keyBreakSuggestions, jsonEncode(_breakSuggestions));
    notifyListeners();
  }

  /// Remove a break suggestion
  Future<void> removeBreakSuggestion(int index) async {
    if (index >= 0 && index < _breakSuggestions.length) {
      _breakSuggestions.removeAt(index);
      await _prefs.setString(AppConstants.keyBreakSuggestions, jsonEncode(_breakSuggestions));
      notifyListeners();
    }
  }

  /// Add a celebration suggestion
  Future<void> addCelebrationSuggestion(String suggestion) async {
    _celebrationSuggestions.add(suggestion);
    await _prefs.setString(AppConstants.keyCelebrationSuggestions, jsonEncode(_celebrationSuggestions));
    notifyListeners();
  }

  /// Remove a celebration suggestion
  Future<void> removeCelebrationSuggestion(int index) async {
    if (index >= 0 && index < _celebrationSuggestions.length) {
      _celebrationSuggestions.removeAt(index);
      await _prefs.setString(AppConstants.keyCelebrationSuggestions, jsonEncode(_celebrationSuggestions));
      notifyListeners();
    }
  }

  /// Reset suggestions to defaults
  Future<void> resetSuggestionsToDefaults() async {
    _breakSuggestions = List.from(AppConstants.defaultBreakSuggestions);
    _celebrationSuggestions = List.from(AppConstants.defaultCelebrationSuggestions);
    await _prefs.setString(AppConstants.keyBreakSuggestions, jsonEncode(_breakSuggestions));
    await _prefs.setString(AppConstants.keyCelebrationSuggestions, jsonEncode(_celebrationSuggestions));
    notifyListeners();
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = null; // System theme
    _workMinutes = AppConstants.defaultWorkMinutes;
    _breakMinutes = AppConstants.defaultBreakMinutes;
    _soundEnabled = true;
    _suggestionsEnabled = true;
    _focusLockEnabled = false;
    _breakSuggestions = List.from(AppConstants.defaultBreakSuggestions);
    _celebrationSuggestions = List.from(AppConstants.defaultCelebrationSuggestions);

    await _prefs.remove(AppConstants.keyDarkMode); // Remove to restore system default
    await _prefs.setInt(AppConstants.keyWorkMinutes, _workMinutes);
    await _prefs.setInt(AppConstants.keyBreakMinutes, _breakMinutes);
    await _prefs.setBool(AppConstants.keySoundEnabled, _soundEnabled);
    await _prefs.setBool(AppConstants.keySuggestionsEnabled, _suggestionsEnabled);
    await _prefs.setBool(AppConstants.keyFocusLockEnabled, _focusLockEnabled);
    await _prefs.setString(AppConstants.keyBreakSuggestions, jsonEncode(_breakSuggestions));
    await _prefs.setString(AppConstants.keyCelebrationSuggestions, jsonEncode(_celebrationSuggestions));

    notifyListeners();
  }
}
