import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/model_selector_service.dart';
import 'package:pseudo_code/services/ai/ai_cache_service.dart';
import 'package:pseudo_code/services/ai/retry_service.dart';
import 'package:pseudo_code/services/ai/rate_limiter_service.dart';
import 'package:pseudo_code/services/ai/analytics_service.dart';

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
    String? graphContext,
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
        graphContext,
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
                graphContext: graphContext,
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
          graphContext,
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

      // --- FILTRE JSON (Merise / Graphe) ---
      // Si on est dans un contexte Merise ou Graphe ET que la réponse ne
      // contient pas de commande de modification réelle, on supprime les
      // blocs ```json ... ``` pour ne pas exposer le JSON brut à l'utilisateur.
      if ((mcdContext != null || graphContext != null) &&
          !response.contains('[MODIFIER_MCD]') &&
          !response.contains('[REORGANISER_MCD]')) {
        // Supprimer les blocs ```json ... ``` et ``` ... ```
        String cleaned = response;
        cleaned = cleaned.replaceAllMapped(
          RegExp(r'```(?:json)?\s*[\s\S]*?```', caseSensitive: false),
          (m) {
            final content = m.group(0) ?? '';
            // Garder les blocs qui ne ressemblent pas à du JSON
            if (content.contains('"entities"') ||
                content.contains('"relations"') ||
                content.contains('"nodes"') ||
                content.contains('"edges"') ||
                content.contains('"links"')) {
              return ''; // Supprimer ce bloc JSON
            }
            return content; // Garder les autres blocs (ex: pseudocode)
          },
        );
        // Nettoyer les lignes vides consécutives
        cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
        if (cleaned != response) {
          _messages.last['content'] = cleaned;
          finalResponseText = cleaned;
          notifyListeners();
        }
      }
      // --- FIN FILTRE JSON ---

      // L'agent IA est désormais en lecture seule.
      // Il peut recevoir le contexte (code, MCD, graphe) et l'expliquer,
      // mais il n'a plus le droit de modifier quoi que ce soit.
      // Les balises [REPLACER_CODE], [INSERER_CODE], [MODIFIER_MCD],
      // [REORGANISER_MCD] sont désormais ignorées.

      // Seul le résumé de l'historique est conservé
      if (finalResponseText.contains('[RESUMER_ETAT]')) {
        _summarizeHistory();
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
