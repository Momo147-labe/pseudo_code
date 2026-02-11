import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/prompt_manager.dart';

class GroqService implements ILlmService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  // Clé API (idéalement injectée, mais ici récupérée comme avant)
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

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
          "Erreur Groq (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Erreur connection IA: $e");
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
        throw Exception("Erreur Stream Groq (${response.statusCode})");
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
      throw Exception("Erreur Stream IA: $e");
    }
  }

  @override
  Map<String, dynamic> getModelInfo() {
    return {
      'name': 'Llama 3.1 8B',
      'provider': 'Groq',
      'model': _model,
      'costPer1MTokens': 0.05, // USD
      'maxTokens': 8192,
      'supportsStreaming': true,
    };
  }

  @override
  int estimateTokens(String text) {
    // Estimation approximative : ~4 caractères par token
    return (text.length / 4).ceil();
  }
}
