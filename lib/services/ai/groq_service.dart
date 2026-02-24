import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/prompt_manager.dart';

class GroqService implements ILlmService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // Modèles Groq disponibles
  static const String modelFast = 'llama-3.1-8b-instant';
  static const String modelSmart = 'llama-3.3-70b-versatile';
  static const String modelDefault = modelFast;

  final String _model;
  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

  GroqService({String? model}) : _model = model ?? modelDefault;

  List<Map<String, String>> _prepareMessages(
    List<Map<String, String>> messages,
    String? contextCode,
    String? mcdContext,
    String? graphContext,
    bool isAgentMode,
    String userName,
  ) {
    final systemPrompt = PromptManager.getSystemPrompt(
      userName,
      isAgentMode,
      contextCode: contextCode,
      mcdContext: mcdContext,
      graphContext: graphContext,
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
    String? graphContext,
    bool isAgentMode = true,
    String userName = "Momo",
  }) async {
    try {
      final finalMessages = _prepareMessages(
        messages,
        contextCode,
        mcdContext,
        graphContext,
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
          "max_tokens": 4096,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        final msg = error['error']?['message'] ?? response.body;
        throw Exception("Erreur Groq (${response.statusCode}): $msg");
      }
    } catch (e) {
      throw Exception("Erreur connexion IA Groq: $e");
    }
  }

  @override
  Stream<String> streamChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    String? graphContext,
    bool isAgentMode = true,
    String userName = "Momo",
  }) async* {
    final finalMessages = _prepareMessages(
      messages,
      contextCode,
      mcdContext,
      graphContext,
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
      "max_tokens": 4096,
      "stream": true,
    });

    try {
      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception("Erreur Stream Groq (${response.statusCode}): $body");
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
            // Ignore errors for partial chunks
          }
        }
      }
      client.close();
    } catch (e) {
      throw Exception("Erreur Stream IA Groq: $e");
    }
  }

  @override
  Map<String, dynamic> getModelInfo() {
    if (_model == modelSmart) {
      return {
        'name': 'Llama 3.3 70B (Expert)',
        'provider': 'Groq',
        'model': _model,
        'costPer1MTokens': 0.59,
        'maxTokens': 32768,
        'supportsStreaming': true,
      };
    }
    return {
      'name': 'Llama 3.1 8B (Rapide)',
      'provider': 'Groq',
      'model': _model,
      'costPer1MTokens': 0.05,
      'maxTokens': 8192,
      'supportsStreaming': true,
    };
  }

  @override
  int estimateTokens(String text) {
    // Approx: 1 token ≈ 4 chars in English, ~3 in French
    return (text.length / 3.5).ceil();
  }
}
