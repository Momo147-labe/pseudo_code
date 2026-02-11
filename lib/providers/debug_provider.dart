import 'dart:async';
import 'package:flutter/material.dart';

class DebugProvider with ChangeNotifier {
  final Set<int> _breakpoints = {};
  bool _isPaused = false;
  Completer<void>? _nextStepCompleter;
  int? _currentHighlightLine;
  Map<String, dynamic> _debugVariables = {};
  int? _errorLine;

  // Stream to notify external systems (like Isolate) of control actions
  final _controlActionController = StreamController<String>.broadcast();
  Stream<String> get controlActionStream => _controlActionController.stream;

  Set<int> get breakpoints => _breakpoints;
  bool get isPaused => _isPaused;
  int? get currentHighlightLine => _currentHighlightLine;
  Map<String, dynamic> get debugVariables => _debugVariables;
  int? get errorLine => _errorLine;

  void toggleBreakpoint(int line) {
    if (_breakpoints.contains(line)) {
      _breakpoints.remove(line);
    } else {
      _breakpoints.add(line);
    }
    notifyListeners();
  }

  void setPaused(bool paused) {
    _isPaused = paused;
    notifyListeners();
  }

  void setHighlightLine(int? line) {
    _currentHighlightLine = line;
    notifyListeners();
  }

  void updateDebugVariables(Map<String, dynamic> vars) {
    _debugVariables = Map.from(vars);
    notifyListeners();
  }

  void setErrorLine(int? line) {
    if (_errorLine != line) {
      _errorLine = line;
      notifyListeners();
    }
  }

  Future<void> waitForNextStep() async {
    _nextStepCompleter = Completer<void>();
    await _nextStepCompleter!.future;
    _nextStepCompleter = null;
  }

  void triggerNextStep() {
    _controlActionController.add('step');
    if (_nextStepCompleter != null && !_nextStepCompleter!.isCompleted) {
      _nextStepCompleter!.complete();
    }
  }

  void triggerContinue() {
    _controlActionController.add('continue');
    setPaused(false);
    triggerNextStep();
  }

  void triggerStop() {
    _controlActionController.add('stop');
    setPaused(false);
  }

  @override
  void dispose() {
    _controlActionController.close();
    super.dispose();
  }
}
