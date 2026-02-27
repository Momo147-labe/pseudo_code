import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  static const String _fontKey = 'app_font';
  AppTheme _currentTheme = AppTheme.dark;
  String _fontFamily = 'JetBrainsMono';

  AppTheme get currentTheme => _currentTheme;
  String get fontFamily => _fontFamily;

  bool get isDarkMode =>
      _currentTheme != AppTheme.light && _currentTheme != AppTheme.papier;

  ThemeProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Theme
    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null && themeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[themeIndex];
    }

    // Font
    _fontFamily = prefs.getString(_fontKey) ?? 'JetBrainsMono';

    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  Future<void> setFontFamily(String font) async {
    _fontFamily = font;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, font);
  }

  void toggleTheme() {
    final nextIndex = (_currentTheme.index + 1) % AppTheme.values.length;
    setTheme(AppTheme.values[nextIndex]);
  }
}
