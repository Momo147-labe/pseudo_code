import 'package:flutter/foundation.dart';
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/groq_service.dart';
import 'package:pseudo_code/services/ai/openai_service.dart';
import 'package:pseudo_code/services/ai/anthropic_service.dart';
import 'package:pseudo_code/services/ai/ollama_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de sélection intelligente du modèle AI
class ModelSelectorService {
  static const String _prefKeySelectedModel = 'ai_selected_model';
  static const String _prefKeyPreferLocal = 'ai_prefer_local';

  // Types de modèles disponibles
  static const String modelGroq = 'groq';
  static const String modelOpenAiGpt4 = 'openai_gpt4';
  static const String modelOpenAiGpt35 = 'openai_gpt35';
  static const String modelClaudeOpus = 'claude_opus';
  static const String modelClaudeSonnet = 'claude_sonnet';
  static const String modelClaudeHaiku = 'claude_haiku';
  static const String modelOllama = 'ollama';

  String _selectedModel = modelGroq;
  bool _preferLocal = false;
  OllamaService? _ollamaService;

  /// Initialise le service en chargeant les préférences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedModel = prefs.getString(_prefKeySelectedModel) ?? modelGroq;
      _preferLocal = prefs.getBool(_prefKeyPreferLocal) ?? false;

      // Vérifier la disponibilité d'Ollama
      _ollamaService = OllamaService();
      await _ollamaService!.checkAvailability();
    } catch (e) {
      debugPrint('ModelSelectorService: Erreur init - $e');
    }
  }

  /// Retourne le service AI approprié selon la sélection
  ILlmService getService() {
    switch (_selectedModel) {
      case modelOpenAiGpt4:
        return OpenAiService(model: OpenAiService.modelGpt4);
      case modelOpenAiGpt35:
        return OpenAiService(model: OpenAiService.modelGpt35Turbo);
      case modelClaudeOpus:
        return AnthropicService(model: AnthropicService.modelClaude3Opus);
      case modelClaudeSonnet:
        return AnthropicService(model: AnthropicService.modelClaude3Sonnet);
      case modelClaudeHaiku:
        return AnthropicService(model: AnthropicService.modelClaude3Haiku);
      case modelOllama:
        if (_ollamaService != null && _ollamaService!.isAvailable) {
          return _ollamaService!;
        } else {
          debugPrint('Ollama non disponible, fallback vers Groq');
          return GroqService();
        }
      case modelGroq:
      default:
        return GroqService();
    }
  }

  /// Sélection intelligente basée sur la complexité de la tâche
  ///
  /// [complexity] : 0-10, où 0 = très simple, 10 = très complexe
  ILlmService getServiceForTask(int complexity) {
    // Si préférence pour local et Ollama disponible, l'utiliser pour tâches simples
    if (_preferLocal &&
        _ollamaService != null &&
        _ollamaService!.isAvailable &&
        complexity <= 5) {
      debugPrint('Utilisation Ollama (local) pour tâche simple');
      return _ollamaService!;
    }

    // Pour tâches complexes, utiliser le modèle sélectionné
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

  /// Active/désactive la préférence pour les modèles locaux
  Future<void> setPreferLocal(bool prefer) async {
    _preferLocal = prefer;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyPreferLocal, prefer);
    } catch (e) {
      debugPrint('Erreur sauvegarde préférence local: $e');
    }
  }

  /// Retourne la liste des modèles disponibles
  Future<List<Map<String, dynamic>>> getAvailableModels() async {
    final models = [
      {
        'id': modelGroq,
        'name': 'Llama 3.1 8B (Groq)',
        'provider': 'Groq',
        'cost': 'Très bas',
        'speed': 'Très rapide',
        'available': true,
      },
      {
        'id': modelOpenAiGpt35,
        'name': 'GPT-3.5 Turbo',
        'provider': 'OpenAI',
        'cost': 'Bas',
        'speed': 'Rapide',
        'available': true,
      },
      {
        'id': modelOpenAiGpt4,
        'name': 'GPT-4',
        'provider': 'OpenAI',
        'cost': 'Élevé',
        'speed': 'Moyen',
        'available': true,
      },
      {
        'id': modelClaudeHaiku,
        'name': 'Claude 3 Haiku',
        'provider': 'Anthropic',
        'cost': 'Très bas',
        'speed': 'Très rapide',
        'available': true,
      },
      {
        'id': modelClaudeSonnet,
        'name': 'Claude 3 Sonnet',
        'provider': 'Anthropic',
        'cost': 'Moyen',
        'speed': 'Rapide',
        'available': true,
      },
      {
        'id': modelClaudeOpus,
        'name': 'Claude 3 Opus',
        'provider': 'Anthropic',
        'cost': 'Élevé',
        'speed': 'Moyen',
        'available': true,
      },
    ];

    // Ajouter Ollama si disponible
    if (_ollamaService != null) {
      final available = await _ollamaService!.checkAvailability();
      models.add({
        'id': modelOllama,
        'name': 'Ollama (Local)',
        'provider': 'Ollama',
        'cost': 'Gratuit',
        'speed': 'Variable',
        'available': available,
      });
    }

    return models;
  }

  String get selectedModel => _selectedModel;
  bool get preferLocal => _preferLocal;
  bool get isOllamaAvailable => _ollamaService?.isAvailable ?? false;
}
