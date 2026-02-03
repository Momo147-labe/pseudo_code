import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'app_theme';
  AppTheme _currentTheme = AppTheme.dark;

  AppTheme get currentTheme => _currentTheme;

  bool get isDarkMode =>
      _currentTheme != AppTheme.light && _currentTheme != AppTheme.papier;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey);
    if (index != null && index < AppTheme.values.length) {
      _currentTheme = AppTheme.values[index];
      notifyListeners();
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  void toggleTheme() {
    if (_currentTheme == AppTheme.dark)
      setTheme(AppTheme.light);
    else if (_currentTheme == AppTheme.light)
      setTheme(AppTheme.dracula);
    else if (_currentTheme == AppTheme.dracula)
      setTheme(AppTheme.oneDark);
    else if (_currentTheme == AppTheme.oneDark)
      setTheme(AppTheme.papier);
    else
      setTheme(AppTheme.dark);
  }
}
