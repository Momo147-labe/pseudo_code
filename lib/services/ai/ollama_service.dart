import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/prompt_manager.dart';

class OllamaService implements ILlmService {
  final String _baseUrl;
  final String _model;
  bool _isAvailable = false;

  OllamaService({String? baseUrl, String model = 'llama3.1'})
    : _baseUrl =
          baseUrl ?? dotenv.env['OLLAMA_BASE_URL'] ?? 'http://localhost:11434',
      _model = model;

  /// Vérifie si Ollama est disponible
  Future<bool> checkAvailability() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/api/tags'))
          .timeout(const Duration(seconds: 2));

      _isAvailable = response.statusCode == 200;
      return _isAvailable;
    } catch (e) {
      debugPrint('Ollama non disponible: $e');
      _isAvailable = false;
      return false;
    }
  }

  /// Récupère la liste des modèles disponibles
  Future<List<String>> getAvailableModels() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/tags'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models = data['models'] as List;
        return models.map((m) => m['name'] as String).toList();
      }
    } catch (e) {
      debugPrint('Erreur récupération modèles Ollama: $e');
    }
    return [];
  }

  List<Map<String, String>> _prepareMessages(
    List<Map<String, String>> messages,
    String? contextCode,
    String? mcdContext,
    bool isAgentMode,
    String userName,
  ) {
    final systemPrompt = PromptManager.getSystemPrompt(
      userName,
      isAgentMode,
      contextCode: contextCode,
      mcdContext: mcdContext,
    );

    return [
      {"role": "system", "content": systemPrompt},
      ...messages,
    ];
  }

  @override
  Future<String> getChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    bool isAgentMode = true,
    String userName = "Momo",
  }) async {
    // Vérifier la disponibilité
    if (!_isAvailable) {
      final available = await checkAvailability();
      if (!available) {
        throw Exception(
          'Ollama non disponible. Assurez-vous qu\'Ollama est démarré.',
        );
      }
    }

    try {
      final finalMessages = _prepareMessages(
        messages,
        contextCode,
        mcdContext,
        isAgentMode,
        userName,
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": _model,
          "messages": finalMessages,
          "stream": false,
          "options": {"temperature": isAgentMode ? 0.1 : 0.7},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['message']['content'];
      } else {
        throw Exception(
          "Erreur Ollama (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      _isAvailable = false; // Marquer comme non disponible en cas d'erreur
      throw Exception("Erreur connection Ollama: $e");
    }
  }

  @override
  Stream<String> streamChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    bool isAgentMode = true,
    String userName = "Momo",
  }) async* {
    // Vérifier la disponibilité
    if (!_isAvailable) {
      final available = await checkAvailability();
      if (!available) {
        throw Exception(
          'Ollama non disponible. Assurez-vous qu\'Ollama est démarré.',
        );
      }
    }

    final finalMessages = _prepareMessages(
      messages,
      contextCode,
      mcdContext,
      isAgentMode,
      userName,
    );

    final request = http.Request('POST', Uri.parse('$_baseUrl/api/chat'));
    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode({
      "model": _model,
      "messages": finalMessages,
      "stream": true,
      "options": {"temperature": isAgentMode ? 0.1 : 0.7},
    });

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        _isAvailable = false;
        throw Exception("Erreur Stream Ollama (${response.statusCode})");
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.trim().isEmpty) continue;

        try {
          final data = jsonDecode(line);
          if (data['message'] != null && data['message']['content'] != null) {
            yield data['message']['content'];
          }

          // Vérifier si c'est le dernier message
          if (data['done'] == true) {
            break;
          }
        } catch (e) {
          // Ignore parsing errors for partial chunks
        }
      }
      client.close();
    } catch (e) {
      _isAvailable = false;
      throw Exception("Erreur Stream Ollama: $e");
    }
  }

  @override
  Map<String, dynamic> getModelInfo() {
    return {
      'name': _model,
      'provider': 'Ollama (Local)',
      'model': _model,
      'costPer1MTokens': 0.0, // Gratuit (local)
      'maxTokens': 8192,
      'supportsStreaming': true,
      'isLocal': true,
      'isAvailable': _isAvailable,
    };
  }

  @override
  int estimateTokens(String text) {
    // Estimation approximative : ~4 caractères par token
    return (text.length / 4).ceil();
  }

  bool get isAvailable => _isAvailable;
}
