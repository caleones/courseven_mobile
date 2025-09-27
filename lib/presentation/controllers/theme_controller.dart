import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';

  
  final RxBool _isDarkMode = true.obs; 

  
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark =
          prefs.getBool(_themeKey) ?? true; 
      _isDarkMode.value = isDark;
      _updateSystemTheme();
    } catch (e) {
      debugPrint('[THEME] Error cargando preferencia de tema: $e');
      
      _isDarkMode.value = true;
      _updateSystemTheme();
    }
  }

  
  Future<void> _saveThemeToPrefs(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      debugPrint('[THEME] Error guardando preferencia de tema: $e');
    }
  }

  
  void setLightTheme() {
    _isDarkMode.value = false;
    _updateSystemTheme();
    _saveThemeToPrefs(false);
    update();
  }

  
  void setDarkTheme() {
    _isDarkMode.value = true;
    _updateSystemTheme();
    _saveThemeToPrefs(true);
    update();
  }

  
  void toggleTheme() {
    if (_isDarkMode.value) {
      setLightTheme();
    } else {
      setDarkTheme();
    }
  }

  
  void _updateSystemTheme() {
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
