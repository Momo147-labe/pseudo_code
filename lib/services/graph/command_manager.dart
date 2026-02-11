import 'package:flutter/foundation.dart';

abstract class GraphCommand {
  void execute();
  void undo();
  void redo() => execute();
}

class CommandManager extends ChangeNotifier {
  final List<GraphCommand> _history = [];
  final List<GraphCommand> _redoStack = [];

  static const int maxHistorySize = 50;

  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void execute(GraphCommand command) {
    command.execute();
    _history.add(command);
    _redoStack.clear();

    if (_history.length > maxHistorySize) {
      _history.removeAt(0);
    }
    notifyListeners();
  }

  void undo() {
    if (canUndo) {
      final command = _history.removeLast();
      command.undo();
      _redoStack.add(command);
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      final command = _redoStack.removeLast();
      command.redo();
      _history.add(command);
      notifyListeners();
    }
  }

  void clear() {
    _history.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
