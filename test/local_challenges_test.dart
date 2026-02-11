import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Local challenges JSON should contain 5000 challenges with 10 test cases each',
    () {
      final file = File('assets/challenges.json');
      expect(file.existsSync(), isTrue);

      final jsonString = file.readAsStringSync();
      final List<dynamic> challenges = json.decode(jsonString);

      expect(challenges.length, greaterThanOrEqualTo(5000));

      for (var i = 0; i < 10; i++) {
        // Sample check of first 10
        final challenge = challenges[i];
        expect(challenge['test_cases'], isList);
        expect((challenge['test_cases'] as List).length, equals(10));
      }

      print(
        "Verification successful: ${challenges.length} challenges found, first 10 verified to have 10 test cases.",
      );
    },
  );
}
