import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service d'analytics pour tracking des performances AI
class AnalyticsService {
  static const String _keyPrefix = 'ai_analytics_';
  static const String _keyStats = '${_keyPrefix}stats';
  static const String _keyFeedback = '${_keyPrefix}feedback';

  // Stats en mémoire
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  final List<int> _responseTimes = [];
  int _totalTokensUsed = 0;
  final Map<String, int> _feedbackCounts = {'positive': 0, 'negative': 0};

  /// Initialise le service en chargeant les stats persistantes
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_keyStats);

      if (statsJson != null) {
        final stats = jsonDecode(statsJson);
        _totalRequests = stats['totalRequests'] ?? 0;
        _successfulRequests = stats['successfulRequests'] ?? 0;
        _failedRequests = stats['failedRequests'] ?? 0;
        _totalTokensUsed = stats['totalTokensUsed'] ?? 0;
      }

      final feedbackJson = prefs.getString(_keyFeedback);
      if (feedbackJson != null) {
        final feedback = jsonDecode(feedbackJson);
        _feedbackCounts['positive'] = feedback['positive'] ?? 0;
        _feedbackCounts['negative'] = feedback['negative'] ?? 0;
      }
    } catch (e) {
      debugPrint('AnalyticsService: Erreur chargement stats - $e');
    }
  }

  /// Enregistre une requête réussie
  Future<void> recordSuccess({
    required int responseTimeMs,
    int tokensUsed = 0,
  }) async {
    _totalRequests++;
    _successfulRequests++;
    _responseTimes.add(responseTimeMs);
    _totalTokensUsed += tokensUsed;

    // Garder seulement les 100 derniers temps de réponse
    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0);
    }

    await _saveStats();
  }

  /// Enregistre une requête échouée
  Future<void> recordFailure() async {
    _totalRequests++;
    _failedRequests++;
    await _saveStats();
  }

  /// Enregistre un feedback utilisateur
  Future<void> recordFeedback(bool isPositive) async {
    if (isPositive) {
      _feedbackCounts['positive'] = (_feedbackCounts['positive'] ?? 0) + 1;
    } else {
      _feedbackCounts['negative'] = (_feedbackCounts['negative'] ?? 0) + 1;
    }

    await _saveFeedback();
  }

  /// Retourne les statistiques complètes
  Map<String, dynamic> getStats() {
    final successRate = _totalRequests > 0
        ? (_successfulRequests / _totalRequests * 100).toStringAsFixed(1)
        : '0.0';

    final avgResponseTime = _responseTimes.isNotEmpty
        ? (_responseTimes.reduce((a, b) => a + b) / _responseTimes.length)
              .round()
        : 0;

    final totalFeedback =
        (_feedbackCounts['positive'] ?? 0) + (_feedbackCounts['negative'] ?? 0);

    final positiveRate = totalFeedback > 0
        ? ((_feedbackCounts['positive'] ?? 0) / totalFeedback * 100)
              .toStringAsFixed(1)
        : '0.0';

    return {
      'totalRequests': _totalRequests,
      'successfulRequests': _successfulRequests,
      'failedRequests': _failedRequests,
      'successRate': '$successRate%',
      'avgResponseTimeMs': avgResponseTime,
      'totalTokensUsed': _totalTokensUsed,
      'positiveFeedback': _feedbackCounts['positive'] ?? 0,
      'negativeFeedback': _feedbackCounts['negative'] ?? 0,
      'positiveRate': '$positiveRate%',
    };
  }

  /// Estime le coût basé sur les tokens utilisés
  /// Prix approximatifs pour différents modèles
  double estimateCost(String modelName, int tokens) {
    // Prix par 1M tokens (approximatif)
    final prices = {
      'llama-3.1-8b-instant': 0.05, // Groq
      'gpt-4': 30.0, // OpenAI
      'gpt-3.5-turbo': 0.5, // OpenAI
      'claude-3-opus': 15.0, // Anthropic
      'claude-3-sonnet': 3.0, // Anthropic
      'ollama': 0.0, // Local, gratuit
    };

    final pricePerMillion = prices[modelName] ?? 0.05;
    return (tokens / 1000000) * pricePerMillion;
  }

  /// Réinitialise toutes les statistiques
  Future<void> reset() async {
    _totalRequests = 0;
    _successfulRequests = 0;
    _failedRequests = 0;
    _responseTimes.clear();
    _totalTokensUsed = 0;
    _feedbackCounts['positive'] = 0;
    _feedbackCounts['negative'] = 0;

    await _saveStats();
    await _saveFeedback();
  }

  /// Sauvegarde les stats dans SharedPreferences
  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = {
        'totalRequests': _totalRequests,
        'successfulRequests': _successfulRequests,
        'failedRequests': _failedRequests,
        'totalTokensUsed': _totalTokensUsed,
      };
      await prefs.setString(_keyStats, jsonEncode(stats));
    } catch (e) {
      debugPrint('AnalyticsService: Erreur sauvegarde stats - $e');
    }
  }

  /// Sauvegarde les feedbacks dans SharedPreferences
  Future<void> _saveFeedback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFeedback, jsonEncode(_feedbackCounts));
    } catch (e) {
      debugPrint('AnalyticsService: Erreur sauvegarde feedback - $e');
    }
  }
}
