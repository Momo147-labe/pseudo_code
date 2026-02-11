import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/prompt_manager.dart';

class AnthropicService implements ILlmService {
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const String _anthropicVersion = '2023-06-01';

  // Modèles disponibles
  static const String modelClaude3Opus = 'claude-3-opus-20240229';
  static const String modelClaude3Sonnet = 'claude-3-sonnet-20240229';
  static const String modelClaude3Haiku = 'claude-3-haiku-20240307';

  final String _model;
  final String _apiKey;

  AnthropicService({String model = modelClaude3Sonnet})
    : _model = model,
      _apiKey = dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  List<Map<String, dynamic>> _prepareMessages(
    List<Map<String, String>> messages,
    String? contextCode,
    String? mcdContext,
    bool isAgentMode,
    String userName,
  ) {
    // Anthropic utilise un format légèrement différent
    return messages.map((m) {
      return {
        "role": m['role'] == 'assistant' ? 'assistant' : 'user',
        "content": m['content'],
      };
    }).toList();
  }

  @override
  Future<String> getChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    bool isAgentMode = true,
    String userName = "Momo",
  }) async {
    if (_apiKey.isEmpty) {
      throw Exception('Clé API Anthropic non configurée');
    }

    try {
      final systemPrompt = PromptManager.getSystemPrompt(
        userName,
        isAgentMode,
        contextCode: contextCode,
        mcdContext: mcdContext,
      );

      final finalMessages = _prepareMessages(
        messages,
        contextCode,
        mcdContext,
        isAgentMode,
        userName,
      );

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': _anthropicVersion,
        },
        body: jsonEncode({
          "model": _model,
          "messages": finalMessages,
          "system": systemPrompt,
          "max_tokens": 4096,
          "temperature": isAgentMode ? 0.1 : 0.7,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['content'][0]['text'];
      } else {
        throw Exception(
          "Erreur Anthropic (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Erreur connection Anthropic: $e");
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
    if (_apiKey.isEmpty) {
      throw Exception('Clé API Anthropic non configurée');
    }

    final systemPrompt = PromptManager.getSystemPrompt(
      userName,
      isAgentMode,
      contextCode: contextCode,
      mcdContext: mcdContext,
    );

    final finalMessages = _prepareMessages(
      messages,
      contextCode,
      mcdContext,
      isAgentMode,
      userName,
    );

    final request = http.Request('POST', Uri.parse(_baseUrl));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': _apiKey,
      'anthropic-version': _anthropicVersion,
    });
    request.body = jsonEncode({
      "model": _model,
      "messages": finalMessages,
      "system": systemPrompt,
      "max_tokens": 4096,
      "temperature": isAgentMode ? 0.1 : 0.7,
      "stream": true,
    });

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception("Erreur Stream Anthropic (${response.statusCode})");
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();

          try {
            final data = jsonDecode(dataStr);
            if (data['type'] == 'content_block_delta') {
              final delta = data['delta'];
              if (delta != null && delta['text'] != null) {
                yield delta['text'];
              }
            }
          } catch (e) {
            // Ignore parsing errors for partial chunks
          }
        }
      }
      client.close();
    } catch (e) {
      throw Exception("Erreur Stream Anthropic: $e");
    }
  }

  @override
  Map<String, dynamic> getModelInfo() {
    final costs = {
      modelClaude3Opus: 15.0,
      modelClaude3Sonnet: 3.0,
      modelClaude3Haiku: 0.25,
    };

    final names = {
      modelClaude3Opus: 'Claude 3 Opus',
      modelClaude3Sonnet: 'Claude 3 Sonnet',
      modelClaude3Haiku: 'Claude 3 Haiku',
    };

    return {
      'name': names[_model] ?? 'Claude 3',
      'provider': 'Anthropic',
      'model': _model,
      'costPer1MTokens': costs[_model] ?? 3.0,
      'maxTokens': 200000,
      'supportsStreaming': true,
    };
  }

  @override
  int estimateTokens(String text) {
    // Estimation approximative : ~4 caractères par token
    return (text.length / 4).ceil();
  }
}
