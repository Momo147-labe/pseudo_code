import 'dart:async';
import 'dart:isolate';
import '../models/challenge_model.dart';
import '../interpreteur/isolated_interpreter.dart';

class TestCaseResult {
  final TestCase testCase;
  final String actualOutput;
  final bool success;
  final String? error;

  TestCaseResult({
    required this.testCase,
    required this.actualOutput,
    required this.success,
    this.error,
  });
}

class ChallengeValidationResult {
  final List<TestCaseResult> results;
  final bool allPassed;
  final int passedCount;
  final int totalCount;

  ChallengeValidationResult({required this.results})
    : allPassed = results.every((r) => r.success),
      passedCount = results.where((r) => r.success).length,
      totalCount = results.length;
}

class ChallengeValidator {
  Future<ChallengeValidationResult> validate({
    required Challenge challenge,
    required String code,
  }) async {
    final results = <TestCaseResult>[];

    for (final testCase in challenge.testCases) {
      final result = await _runTestCase(code, testCase);
      results.add(result);
    }

    return ChallengeValidationResult(results: results);
  }

  Future<TestCaseResult> _runTestCase(String code, TestCase testCase) async {
    final receivePort = ReceivePort();
    Isolate? isolate;
    StreamSubscription? subscription;

    try {
      isolate = await Isolate.spawn(
        IsolatedInterpreter.entryPoint,
        receivePort.sendPort,
      );

      final stream = receivePort.asBroadcastStream();
      final sendPort = await stream.first as SendPort;

      final outputs = <String>[];
      final completer = Completer<TestCaseResult>();

      // Handle multiple inputs if needed (split testCase.input by newline)
      final inputs = testCase.input.split('\n');
      int inputIndex = 0;

      subscription = stream.listen((message) {
        if (message is OutputEvent) {
          if (message.text != '__CLEAR__') {
            outputs.add(message.text.trim());
          }
        } else if (message is InputRequestEvent) {
          if (inputIndex < inputs.length) {
            sendPort.send(InputResponse(inputs[inputIndex]));
            inputIndex++;
          } else {
            sendPort.send(InputResponse("")); // Or error
          }
        } else if (message is FinishedEvent) {
          final actual = outputs.join('\n').trim();
          final expected = testCase.expectedOutput.trim();

          bool success = actual == expected;
          if (!success) {
            // Try numeric comparison
            final actualNum = num.tryParse(actual);
            final expectedNum = num.tryParse(expected);
            if (actualNum != null && expectedNum != null) {
              success = actualNum == expectedNum;
            }
          }

          completer.complete(
            TestCaseResult(
              testCase: testCase,
              actualOutput: actual,
              success: success,
            ),
          );
        }
      });

      sendPort.send(RunRequest(code, {}));

      // Timeout for infinite loops
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return TestCaseResult(
            testCase: testCase,
            actualOutput: outputs.join('\n'),
            success: false,
            error: "Temps d'exécution dépassé (Timeout)",
          );
        },
      );
    } catch (e) {
      return TestCaseResult(
        testCase: testCase,
        actualOutput: "",
        success: false,
        error: "Erreur d'exécution: $e",
      );
    } finally {
      subscription?.cancel();
      isolate?.kill(priority: Isolate.immediate);
      receivePort.close();
    }
  }
}
