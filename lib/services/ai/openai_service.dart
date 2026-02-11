import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/prompt_manager.dart';

class OpenAiService implements ILlmService {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  // Modèles disponibles
  static const String modelGpt4 = 'gpt-4';
  static const String modelGpt35Turbo = 'gpt-3.5-turbo';

  final String _model;
  final String _apiKey;

  OpenAiService({String model = modelGpt35Turbo})
    : _model = model,
      _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

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
    if (_apiKey.isEmpty) {
      throw Exception('Clé API OpenAI non configurée');
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
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _model,
          "messages": finalMessages,
          "temperature": isAgentMode ? 0.1 : 0.7,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception(
          "Erreur OpenAI (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Erreur connection OpenAI: $e");
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
      throw Exception('Clé API OpenAI non configurée');
    }

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
      'Authorization': 'Bearer $_apiKey',
    });
    request.body = jsonEncode({
      "model": _model,
      "messages": finalMessages,
      "temperature": isAgentMode ? 0.1 : 0.7,
      "stream": true,
    });

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception("Erreur Stream OpenAI (${response.statusCode})");
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final dataStr = line.substring(6).trim();
          if (dataStr == '[DONE]') break;

          try {
            final data = jsonDecode(dataStr);
            if (data['choices'] != null && data['choices'].isNotEmpty) {
              final delta = data['choices'][0]['delta'];
              if (delta != null && delta['content'] != null) {
                yield delta['content'];
              }
            }
          } catch (e) {
            // Ignore parsing errors for partial chunks
          }
        }
      }
      client.close();
    } catch (e) {
      throw Exception("Erreur Stream OpenAI: $e");
    }
  }

  @override
  Map<String, dynamic> getModelInfo() {
    final costs = {modelGpt4: 30.0, modelGpt35Turbo: 0.5};

    return {
      'name': _model == modelGpt4 ? 'GPT-4' : 'GPT-3.5 Turbo',
      'provider': 'OpenAI',
      'model': _model,
      'costPer1MTokens': costs[_model] ?? 0.5,
      'maxTokens': _model == modelGpt4 ? 8192 : 4096,
      'supportsStreaming': true,
    };
  }

  @override
  int estimateTokens(String text) {
    // Estimation approximative : ~4 caractères par token
    return (text.length / 4).ceil();
  }
}
