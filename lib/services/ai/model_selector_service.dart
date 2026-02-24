import 'package:flutter/foundation.dart';
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/groq_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de sélection du modèle IA (Groq uniquement)
class ModelSelectorService {
  static const String _prefKeySelectedModel = 'ai_selected_model';

  // Modèles Groq disponibles
  static const String modelFast = 'groq_fast';
  static const String modelSmart = 'groq_smart';

  String _selectedModel = modelFast;

  /// Initialise le service en chargeant les préférences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedModel = prefs.getString(_prefKeySelectedModel) ?? modelFast;
    } catch (e) {
      debugPrint('ModelSelectorService: Erreur init - $e');
    }
  }

  /// Retourne le service IA selon la sélection
  ILlmService getService() {
    switch (_selectedModel) {
      case modelSmart:
        return GroqService(model: GroqService.modelSmart);
      case modelFast:
      default:
        return GroqService(model: GroqService.modelFast);
    }
  }

  /// Pour rester compatible avec l'interface existante
  ILlmService getServiceForTask(int complexity) {
    if (complexity >= 7) {
      // Tâches complexes → modèle expert
      return GroqService(model: GroqService.modelSmart);
    }
    return getService();
  }

  /// Change le modèle sélectionné
  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeySelectedModel, model);
    } catch (e) {
      debugPrint('Erreur sauvegarde modèle sélectionné: $e');
    }
  }

  /// Retourne la liste des modèles Groq disponibles
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    return [
      {
        'id': modelFast,
        'name': 'Llama 3.1 8B (Rapide)',
        'provider': 'Groq',
        'cost': 'Très bas',
        'speed': 'Très rapide',
        'description':
            'Idéal pour les questions simples et corrections rapides.',
        'available': true,
      },
      {
        'id': modelSmart,
        'name': 'Llama 3.3 70B (Expert)',
        'provider': 'Groq',
        'cost': 'Bas',
        'speed': 'Rapide',
        'description': 'Recommandé pour la génération de code et Merise.',
        'available': true,
      },
    ];
  }

  String get selectedModel => _selectedModel;
  bool get isOllamaAvailable => false; // Plus de support Ollama
}
