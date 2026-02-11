import 'dart:async';
import 'dart:isolate';
import 'package:pseudo_code/interpreteur/interpreteur.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

/// Communication protocol for Isolated Interpreter
abstract class InterpreterMessage {}

class RunRequest extends InterpreterMessage {
  final String code;
  final Set<int> breakpoints;
  RunRequest(this.code, this.breakpoints);
}

class InputResponse extends InterpreterMessage {
  final String value;
  InputResponse(this.value);
}

class ControlMessage extends InterpreterMessage {
  final String action; // 'step', 'continue', 'stop'
  ControlMessage(this.action);
}

class OutputEvent extends InterpreterMessage {
  final String text;
  OutputEvent(this.text);
}

class DebugEvent extends InterpreterMessage {
  final int? highlightLine;
  final int? errorLine;
  final Map<String, dynamic> variables;
  final bool isPaused;
  DebugEvent({
    this.highlightLine,
    this.errorLine,
    this.variables = const {},
    this.isPaused = false,
  });
}

class InputRequestEvent extends InterpreterMessage {}

class FinishedEvent extends InterpreterMessage {}

/// A Proxy for DebugProvider that can be sent to and used within an Isolate
/// Actually, we'll implement a custom "RemoteDebugProvider" that sends messages back.
class IsolateDebugProvider extends DebugProvider {
  final SendPort sendPort;
  Set<int> _initialBreakpoints;

  IsolateDebugProvider(this.sendPort, this._initialBreakpoints) {
    // Populate initial breakpoints
    for (var b in _initialBreakpoints) {
      toggleBreakpoint(b);
    }
  }

  @override
  void setHighlightLine(int? line) {
    sendPort.send(DebugEvent(highlightLine: line, isPaused: isPaused));
  }

  @override
  void setErrorLine(int? line) {
    sendPort.send(DebugEvent(errorLine: line, isPaused: isPaused));
  }

  @override
  void updateDebugVariables(Map<String, dynamic> vars) {
    sendPort.send(DebugEvent(variables: vars, isPaused: isPaused));
  }

  @override
  void setPaused(bool paused) {
    super.setPaused(paused);
    sendPort.send(DebugEvent(isPaused: paused));
  }

  // We need to override waitForNextStep to wait for a message from the main thread
  Completer<void>? _stepCompleter;

  @override
  Future<void> waitForNextStep() async {
    if (!isPaused) return;
    _stepCompleter = Completer<void>();
    await _stepCompleter!.future;
  }

  void resolveStep() {
    _stepCompleter?.complete();
    _stepCompleter = null;
  }
}

class IsolatedInterpreter {
  static void entryPoint(SendPort mainSendPort) {
    final childReceivePort = ReceivePort();
    mainSendPort.send(childReceivePort.sendPort);

    IsolateDebugProvider? debugProxy;
    Completer<String>? inputCompleter;

    childReceivePort.listen((message) async {
      if (message is RunRequest) {
        debugProxy = IsolateDebugProvider(mainSendPort, message.breakpoints);

        try {
          await Interpreteur.executer(
            message.code,
            provider: debugProxy!,
            onInput: () async {
              mainSendPort.send(InputRequestEvent());
              inputCompleter = Completer<String>();
              return await inputCompleter!.future;
            },
            onOutput: (text) {
              mainSendPort.send(OutputEvent(text));
            },
          );
        } catch (e) {
          mainSendPort.send(OutputEvent("ERREUR CRITIQUE ISOLATE: $e"));
        } finally {
          mainSendPort.send(FinishedEvent());
        }
      } else if (message is InputResponse) {
        inputCompleter?.complete(message.value);
      } else if (message is ControlMessage) {
        if (message.action == 'step' || message.action == 'continue') {
          debugProxy?.setPaused(message.action == 'step');
          debugProxy?.resolveStep();
        } else if (message.action == 'stop') {
          Isolate.current.kill();
        }
      }
    });
  }
}
