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
  bool _isDarkMode = false;
  int _workMinutes = AppConstants.defaultWorkMinutes;
  int _breakMinutes = AppConstants.defaultBreakMinutes;
  bool _soundEnabled = true;
  bool _suggestionsEnabled = true;
  bool _advancedTaskOptions = false;
  List<String> _breakSuggestions = List.from(AppConstants.defaultBreakSuggestions);
  List<String> _celebrationSuggestions = List.from(AppConstants.defaultCelebrationSuggestions);

  // Getters
  bool get isDarkMode => _isDarkMode;
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get isInitialized => _isInitialized;
  bool get suggestionsEnabled => _suggestionsEnabled;
  bool get advancedTaskOptions => _advancedTaskOptions;
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
    _isDarkMode = _prefs.getBool(AppConstants.keyDarkMode) ?? false;
    _workMinutes = _prefs.getInt(AppConstants.keyWorkMinutes) ?? AppConstants.defaultWorkMinutes;
    _breakMinutes = _prefs.getInt(AppConstants.keyBreakMinutes) ?? AppConstants.defaultBreakMinutes;
    _soundEnabled = _prefs.getBool(AppConstants.keySoundEnabled) ?? true;
    _suggestionsEnabled = _prefs.getBool(AppConstants.keySuggestionsEnabled) ?? true;
    _advancedTaskOptions = _prefs.getBool(AppConstants.keyAdvancedTaskOptions) ?? false;

    final breakJson = _prefs.getString(AppConstants.keyBreakSuggestions);
    if (breakJson != null) {
      _breakSuggestions = List<String>.from(jsonDecode(breakJson));
    }

    final celebrationJson = _prefs.getString(AppConstants.keyCelebrationSuggestions);
    if (celebrationJson != null) {
      _celebrationSuggestions = List<String>.from(jsonDecode(celebrationJson));
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool(AppConstants.keyDarkMode, _isDarkMode);
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
    _isDarkMode = false;
    _workMinutes = AppConstants.defaultWorkMinutes;
    _breakMinutes = AppConstants.defaultBreakMinutes;
    _soundEnabled = true;
    _suggestionsEnabled = true;
    _breakSuggestions = List.from(AppConstants.defaultBreakSuggestions);
    _celebrationSuggestions = List.from(AppConstants.defaultCelebrationSuggestions);

    await _prefs.setBool(AppConstants.keyDarkMode, _isDarkMode);
    await _prefs.setInt(AppConstants.keyWorkMinutes, _workMinutes);
    await _prefs.setInt(AppConstants.keyBreakMinutes, _breakMinutes);
    await _prefs.setBool(AppConstants.keySoundEnabled, _soundEnabled);
    await _prefs.setBool(AppConstants.keySuggestionsEnabled, _suggestionsEnabled);
    await _prefs.setString(AppConstants.keyBreakSuggestions, jsonEncode(_breakSuggestions));
    await _prefs.setString(AppConstants.keyCelebrationSuggestions, jsonEncode(_celebrationSuggestions));

    notifyListeners();
  }
}
