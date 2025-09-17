import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Theme Controller
class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';

  // Observable for theme mode
  final RxBool _isDarkMode = true.obs; // Default to dark theme

  // Getter for dark mode status
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  // Load theme preference from storage
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? true; // Default to dark theme
      _isDarkMode.value = isDark;
      _updateSystemTheme();
    } catch (e) {
      print('Error loading theme preference: $e');
      // Default to dark theme on error
      _isDarkMode.value = true;
      _updateSystemTheme();
    }
  }

  // Save theme preference to storage
  Future<void> _saveThemeToPrefs(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  // Set light theme
  void setLightTheme() {
    _isDarkMode.value = false;
    _updateSystemTheme();
    _saveThemeToPrefs(false);
    update();
  }

  // Set dark theme
  void setDarkTheme() {
    _isDarkMode.value = true;
    _updateSystemTheme();
    _saveThemeToPrefs(true);
    update();
  }

  // Toggle between themes
  void toggleTheme() {
    if (_isDarkMode.value) {
      setLightTheme();
    } else {
      setDarkTheme();
    }
  }

  // Update system theme
  void _updateSystemTheme() {
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Get current theme mode
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
