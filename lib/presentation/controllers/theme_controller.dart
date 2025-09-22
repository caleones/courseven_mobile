import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Controlador que gestiona el estado del tema (claro/oscuro) de la aplicación
class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';

  // Observable para el modo de tema
  final RxBool _isDarkMode = true.obs; // Por defecto tema oscuro

  // Getter para el estado del modo oscuro
  bool get isDarkMode => _isDarkMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadThemeFromPrefs();
  }

  // Carga la preferencia de tema desde el almacenamiento local
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark =
          prefs.getBool(_themeKey) ?? true; // Por defecto tema oscuro
      _isDarkMode.value = isDark;
      _updateSystemTheme();
    } catch (e) {
      debugPrint('[THEME] Error cargando preferencia de tema: $e');
      // Por defecto tema oscuro en caso de error
      _isDarkMode.value = true;
      _updateSystemTheme();
    }
  }

  // Guarda la preferencia de tema en el almacenamiento local
  Future<void> _saveThemeToPrefs(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      debugPrint('[THEME] Error guardando preferencia de tema: $e');
    }
  }

  // Establece el tema claro
  void setLightTheme() {
    _isDarkMode.value = false;
    _updateSystemTheme();
    _saveThemeToPrefs(false);
    update();
  }

  // Establece el tema oscuro
  void setDarkTheme() {
    _isDarkMode.value = true;
    _updateSystemTheme();
    _saveThemeToPrefs(true);
    update();
  }

  // Alterna entre los temas claro y oscuro
  void toggleTheme() {
    if (_isDarkMode.value) {
      setLightTheme();
    } else {
      setDarkTheme();
    }
  }

  // Actualiza el tema del sistema
  void _updateSystemTheme() {
    Get.changeThemeMode(_isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // Obtiene el modo de tema actual
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
