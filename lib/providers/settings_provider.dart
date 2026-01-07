import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class SettingsProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Settings
  bool _isDarkMode = false;
  int _workMinutes = AppConstants.defaultWorkMinutes;
  int _breakMinutes = AppConstants.defaultBreakMinutes;
  bool _soundEnabled = true;

  // Getters
  bool get isDarkMode => _isDarkMode;
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  bool get soundEnabled => _soundEnabled;
  bool get isInitialized => _isInitialized;

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

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _workMinutes = AppConstants.defaultWorkMinutes;
    _breakMinutes = AppConstants.defaultBreakMinutes;
    _soundEnabled = true;

    await _prefs.setBool(AppConstants.keyDarkMode, _isDarkMode);
    await _prefs.setInt(AppConstants.keyWorkMinutes, _workMinutes);
    await _prefs.setInt(AppConstants.keyBreakMinutes, _breakMinutes);
    await _prefs.setBool(AppConstants.keySoundEnabled, _soundEnabled);

    notifyListeners();
  }
}
