import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ConsolePosition { bottom, right, top }

enum ActiveMainView { algorithm, merise }

class AppProvider with ChangeNotifier {
  // --- UI STATE ---
  String _activeSidebarTab = 'explorer'; // 'explorer', 'debug', 'merise', 'ai'
  ActiveMainView _activeMainView = ActiveMainView.algorithm;

  // Console
  ConsolePosition _consolePosition = ConsolePosition.bottom;
  double _consoleHeight = 250.0;
  double _consoleWidth = 300.0;
  bool _isConsoleVisible = true;

  // Editor Settings
  double _fontSize = 14.0;
  bool _showMinimap = true;

  // Getters
  String get activeSidebarTab => _activeSidebarTab;
  ConsolePosition get consolePosition => _consolePosition;
  double get consoleHeight => _consoleHeight;
  double get consoleWidth => _consoleWidth;
  bool get isConsoleVisible => _isConsoleVisible;
  double get fontSize => _fontSize;
  bool get showMinimap => _showMinimap;
  ActiveMainView get activeMainView => _activeMainView;

  // Setters
  void setShowMinimap(bool show) {
    if (_showMinimap != show) {
      _showMinimap = show;
      notifyListeners();
    }
  }

  void toggleMinimap() {
    _showMinimap = !_showMinimap;
    notifyListeners();
  }

  // Setters
  void setActiveSidebarTab(String tab) {
    _activeSidebarTab = tab;
    // Side effect: if 'merise', hide console and switch main view
    if (tab == 'merise') {
      _isConsoleVisible = false;
      _activeMainView = ActiveMainView.merise;
    } else if (tab == 'explorer' || tab == 'debug') {
      _activeMainView = ActiveMainView.algorithm;
    }
    // Note: switching to 'ai' does NOT change _activeMainView automatically
    notifyListeners();
  }

  void setActiveMainView(ActiveMainView view) {
    _activeMainView = view;
    notifyListeners();
  }

  void setConsolePosition(ConsolePosition pos) {
    _consolePosition = pos;
    notifyListeners();
  }

  void setConsoleHeight(double h) {
    _consoleHeight = h.clamp(50.0, 800.0);
    notifyListeners();
  }

  void setConsoleWidth(double w) {
    _consoleWidth = w.clamp(100.0, 800.0);
    notifyListeners();
  }

  void setConsoleVisible(bool visible) {
    if (_isConsoleVisible != visible) {
      _isConsoleVisible = visible;
      notifyListeners();
    }
  }

  void toggleConsole() {
    _isConsoleVisible = !_isConsoleVisible;
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  Future<void> testLoadImage() async {
    try {
      final data = await rootBundle.load('assets/icone.png');
      debugPrint(
        "TEST: icone.png chargé avec succès (${data.lengthInBytes} octets)",
      );
    } catch (e) {
      debugPrint("TEST: Échec chargement icone.png: $e");
    }
  }
}
