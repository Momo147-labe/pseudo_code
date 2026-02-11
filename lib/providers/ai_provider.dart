import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/model_selector_service.dart';
import 'package:pseudo_code/services/ai/ai_cache_service.dart';
import 'package:pseudo_code/services/ai/retry_service.dart';
import 'package:pseudo_code/services/ai/rate_limiter_service.dart';
import 'package:pseudo_code/services/ai/analytics_service.dart';
import '../interpreteur/validateur.dart';

class AiProvider with ChangeNotifier {
  // Services
  final ModelSelectorService _modelSelector = ModelSelectorService();
  final AiCacheService _cache = AiCacheService();
  final RateLimiterService _rateLimiter = RateLimiterService();
  final AnalyticsService _analytics = AnalyticsService();

  ILlmService? _aiService;
  bool _isInitialized = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider avec votre pseudo-code aujourd\'hui ?',
    },
  ];

  bool _isLoading = false;
  bool _isAgentMode = true;
  bool _isExplainMode = false;
  int _lastTokensUsed = 0;
  double _lastCost = 0.0;

  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isAgentMode => _isAgentMode;
  bool get isExplainMode => _isExplainMode;
  int get lastTokensUsed => _lastTokensUsed;
  double get lastCost => _lastCost;

  /// Initialise le provider
  Future<void> init() async {
    if (_isInitialized) return;

    await _modelSelector.init();
    await _analytics.init();
    _aiService = _modelSelector.getService();
    _isInitialized = true;
  }

  void setAgentMode(bool val) {
    _isAgentMode = val;
    notifyListeners();
  }

  void setExplainMode(bool val) {
    _isExplainMode = val;
    notifyListeners();
  }

  /// Change le modèle AI utilisé
  Future<void> setModel(String modelId) async {
    await _modelSelector.setSelectedModel(modelId);
    _aiService = _modelSelector.getService();
    notifyListeners();
  }

  /// Enregistre un feedback utilisateur
  Future<void> recordFeedback(bool isPositive) async {
    await _analytics.recordFeedback(isPositive);
    notifyListeners();
  }

  /// Récupère les statistiques
  Map<String, dynamic> getStats() {
    return {
      'analytics': _analytics.getStats(),
      'cache': _cache.getCacheStats(),
      'rateLimiter': _rateLimiter.getStats(),
    };
  }

  Future<void> sendMessage(
    String text,
    String? contextCode, {
    String? mcdContext,
    List<String>? currentLints,
    bool? isAgentMode,
    Function(String)? onCodeUpdate,
    Function(String)? onCodeInsert,
    Function(String)? onMeriseUpdate,
    Function()? onMeriseLayout,
    Function(String)? onReviewRequest,
  }) async {
    if (!_isInitialized) {
      await init();
    }

    final bool agentMode = isAgentMode ?? _isAgentMode;
    if (text.trim().isEmpty) return;

    // Vérifier le rate limit
    if (!_rateLimiter.canMakeRequest()) {
      final remaining = _rateLimiter.getTimeUntilReset();
      _messages.add({
        'role': 'assistant',
        'content':
            'Limite de requêtes atteinte. Veuillez patienter ${remaining.inSeconds} secondes.',
      });
      notifyListeners();
      return;
    }

    // Ajouter le message utilisateur
    _messages.add({'role': 'user', 'content': text.trim()});
    _isLoading = true;
    notifyListeners();

    final startTime = DateTime.now();

    try {
      // Préparer les messages pour l'historique
      final int start = _messages.length > 6 ? _messages.length - 6 : 0;
      final historyToSend = _messages
          .sublist(start)
          .map((m) => {"role": m['role']!, "content": m['content']!})
          .toList();

      // Vérifier le cache
      final cachedResponse = await _cache.get(
        historyToSend,
        contextCode,
        mcdContext,
        agentMode,
      );

      String fullResponse;

      if (cachedResponse != null) {
        // Utiliser la réponse en cache
        fullResponse = cachedResponse;
        _messages.add({'role': 'assistant', 'content': fullResponse});
        notifyListeners();
      } else {
        // Faire une nouvelle requête avec retry et rate limiting
        fullResponse = "";
        _messages.add({'role': 'assistant', 'content': ''});
        notifyListeners();

        await _rateLimiter.execute(() async {
          await RetryService.execute(
            () async {
              final stream = _aiService!.streamChatCompletion(
                historyToSend,
                contextCode: contextCode,
                mcdContext: mcdContext,
                isAgentMode: agentMode,
                userName: currentLints != null && currentLints.isNotEmpty
                    ? "Momo (Lints actifs: ${currentLints.join(', ')})"
                    : "Momo",
              );

              await for (final chunk in stream) {
                fullResponse += chunk;
                _messages.last['content'] = fullResponse;
                notifyListeners();
              }
            },
            onRetry: (attempt, error) {
              debugPrint('Retry tentative $attempt: $error');
            },
          );
        });

        // Mettre en cache
        await _cache.set(
          historyToSend,
          contextCode,
          mcdContext,
          agentMode,
          fullResponse,
        );
      }

      final response = fullResponse;
      String finalResponseText = response;

      // Calculer les tokens et le coût
      _lastTokensUsed = _aiService!.estimateTokens(response);
      final modelInfo = _aiService!.getModelInfo();
      _lastCost = _analytics.estimateCost(modelInfo['model'], _lastTokensUsed);

      // Détection et application du code UNIQUEMENT en mode agent
      if (agentMode) {
        if (response.contains('[REPLACER_CODE]')) {
          final patterns = [
            RegExp(
              r"\[REPLACER_CODE\][\s\S]*?```[a-z]*\s*([\s\S]*?)```",
              caseSensitive: false,
            ),
            RegExp(
              r"```[a-z]*\s*\[REPLACER_CODE\]\s*([\s\S]*?)```",
              caseSensitive: false,
            ),
            RegExp(
              r"\[REPLACER_CODE\]\s*([\s\S]+?)(?:\s*\[(?:INSERER|MODIFIER|REORGANISER)|$)",
              caseSensitive: false,
            ),
          ];

          String? newCode;
          for (final p in patterns) {
            final m = p.firstMatch(response);
            if (m != null) {
              newCode = m.group(1)?.trim();
              if (newCode != null && newCode.isNotEmpty) break;
            }
          }

          if (newCode != null && newCode.isNotEmpty) {
            // Validation structurelle
            final validationErrors = ValidateurStructure.valider(
              newCode.split('\n'),
            );
            if (validationErrors.isEmpty) {
              // Utiliser le mode REVIEW si disponible, sinon update direct
              if (onReviewRequest != null) {
                onReviewRequest(newCode);
              } else if (onCodeUpdate != null) {
                onCodeUpdate(newCode);
              }
            } else {
              // Auto-correction
              debugPrint("Échec de validation, tentative d'auto-correction...");
              final errorMsg = validationErrors
                  .map((e) => "- ${e.message} (Ligne ${e.line})")
                  .join('\n');

              final correctionResponse = await _aiService!.getChatCompletion(
                [
                  ...historyToSend,
                  {"role": "assistant", "content": response},
                  {
                    "role": "user",
                    "content":
                        "ERREUR DE SYNTAXE :\n$errorMsg\nCorrige le code et renvoie-le UNIQUEMENT via [REPLACER_CODE].",
                  },
                ],
                contextCode: contextCode,
                isAgentMode: true,
              );

              finalResponseText = correctionResponse;

              for (final p in patterns) {
                final m = p.firstMatch(correctionResponse);
                if (m != null) {
                  final finalCode = m.group(1)?.trim();
                  if (finalCode != null) {
                    if (onReviewRequest != null) {
                      onReviewRequest(finalCode);
                    } else if (onCodeUpdate != null) {
                      onCodeUpdate(finalCode);
                    }
                    break;
                  }
                }
              }
            }
          }
        }

        if (response.contains('[INSERER_CODE]')) {
          final patterns = [
            RegExp(
              r"\[INSERER_CODE\][\s\S]*?```[a-z]*\s*([\s\S]*?)```",
              caseSensitive: false,
            ),
            RegExp(
              r"```[a-z]*\s*\[INSERER_CODE\]\s*([\s\S]*?)```",
              caseSensitive: false,
            ),
            RegExp(
              r"\[INSERER_CODE\]\s*([\s\S]+?)(?:\s*\[(?:REPLACER|MODIFIER|REORGANISER)|$)",
              caseSensitive: false,
            ),
          ];

          String? snippet;
          for (final p in patterns) {
            final m = p.firstMatch(response);
            if (m != null) {
              snippet = m.group(1)?.trim();
              if (snippet != null && snippet.isNotEmpty) break;
            }
          }

          if (snippet != null && snippet.isNotEmpty && onCodeInsert != null) {
            onCodeInsert(snippet);
          }
        }

        // Détection et application du MCD si présent [MODIFIER_MCD]
        if (response.contains('[MODIFIER_MCD]')) {
          final patterns = [
            RegExp(
              r"\[MODIFIER_MCD\][\s\S]*?```(?:json)?\s*([\s\S]*?)```",
              caseSensitive: false,
            ),
            RegExp(
              r"```(?:json)?\s*\[MODIFIER_MCD\]\s*([\s\S]*?)```",
              caseSensitive: false,
            ),
            RegExp(
              r"\[MODIFIER_MCD\]\s*(\{[\s\S]+\})",
              multiLine: true,
              caseSensitive: false,
            ),
          ];

          String? mcdJson;
          for (final p in patterns) {
            final m = p.firstMatch(response);
            if (m != null) {
              mcdJson = m.group(1)?.trim();
              if (mcdJson != null && mcdJson.isNotEmpty) break;
            }
          }

          // Fallback : chercher le premier { et dernier } après la balise
          if (mcdJson == null) {
            final tagIndex = response.toUpperCase().indexOf('[MODIFIER_MCD]');
            final firstBrace = response.indexOf('{', tagIndex);
            final lastBrace = response.lastIndexOf('}');
            if (firstBrace != -1 && lastBrace > firstBrace) {
              mcdJson = response.substring(firstBrace, lastBrace + 1);
            }
          }

          if (mcdJson != null && mcdJson.isNotEmpty && onMeriseUpdate != null) {
            try {
              // Validation JSON basique
              jsonDecode(mcdJson);
              onMeriseUpdate(mcdJson);
            } catch (e) {
              debugPrint("Erreur de parsing MCD JSON: $e");
            }
          }
        }

        // Détection de la demande de réorganisation [REORGANISER_MCD]
        if (finalResponseText.contains('[REORGANISER_MCD]') &&
            onMeriseLayout != null) {
          onMeriseLayout();
        }

        // Détection de demande de résumé d'état [RESUMER_ETAT]
        if (finalResponseText.contains('[RESUMER_ETAT]')) {
          _summarizeHistory();
        }
      }

      // Enregistrer les analytics
      final duration = DateTime.now().difference(startTime);
      await _analytics.recordSuccess(
        responseTimeMs: duration.inMilliseconds,
        tokensUsed: _lastTokensUsed,
      );
    } catch (e) {
      // Enregistrer l'échec
      await _analytics.recordFailure();

      // Si on était en train de streamer, on a peut-être un message incomplet
      if (_messages.last['role'] == 'assistant' &&
          _messages.last['content']!.isEmpty) {
        _messages.removeLast();
      }
      _messages.add({
        'role': 'assistant',
        'content': 'Désolé, j\'ai rencontré une erreur : ${e.toString()}',
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHistory() {
    _messages.clear();
    _messages.add({
      'role': 'assistant',
      'content':
          'Bonjour ! Je suis votre assistant IA. Comment puis-je vous aider avec votre pseudo-code aujourd\'hui ?',
    });
    notifyListeners();
  }

  /// Efface le cache
  Future<void> clearCache() async {
    await _cache.clear();
    notifyListeners();
  }

  void _summarizeHistory() {
    if (_messages.length < 6) return;

    final summary = _messages
        .skip(1)
        .take(_messages.length - 3)
        .map(
          (m) =>
              "${m['role']}: ${m['content']?.substring(0, math.min(m['content']!.length, 80))}...",
        )
        .join("\n");

    _messages.removeRange(1, _messages.length - 3);
    _messages.insert(1, {
      'role': 'system',
      'content': 'RÉSUMÉ DES ÉCHANGES PRÉCÉDENTS :\n$summary',
    });
    debugPrint("Historique résumé pour économiser les tokens.");
  }

  ModelSelectorService get modelSelector => _modelSelector;
  RateLimiterService get rateLimiter => _rateLimiter;
  AiCacheService get cache => _cache;
  AnalyticsService get analytics => _analytics;
}
