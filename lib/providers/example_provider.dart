import 'package:flutter/material.dart';
import '../repositories/example_repository.dart';

class ExampleProvider with ChangeNotifier {
  final ExampleRepository _repository;
  List<dynamic> _exercices = [];
  bool _isLoading = false;

  ExampleProvider(this._repository) {
    loadExercices();
  }

  List<dynamic> get exercices => _exercices;
  bool get isLoading => _isLoading;

  List<Map<String, String>> get builtInExamples => _repository.builtInExamples;

  Future<void> loadExercices() async {
    _isLoading = true;
    notifyListeners();

    _exercices = await _repository.loadExercices();

    _isLoading = false;
    notifyListeners();
  }
}
