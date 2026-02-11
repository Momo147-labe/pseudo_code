import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service de rate limiting côté client
class RateLimiterService {
  // Configuration
  static const int maxRequestsPerMinute = 10;
  static const Duration windowDuration = Duration(minutes: 1);

  // État
  final List<DateTime> _requestTimestamps = [];
  final List<_QueuedRequest> _queue = [];
  bool _isProcessingQueue = false;

  /// Vérifie si une nouvelle requête peut être effectuée
  bool canMakeRequest() {
    _cleanOldTimestamps();
    return _requestTimestamps.length < maxRequestsPerMinute;
  }

  /// Retourne le nombre de requêtes restantes dans la fenêtre actuelle
  int getRemainingRequests() {
    _cleanOldTimestamps();
    return maxRequestsPerMinute - _requestTimestamps.length;
  }

  /// Retourne le temps restant avant le prochain reset
  Duration getTimeUntilReset() {
    _cleanOldTimestamps();

    if (_requestTimestamps.isEmpty) {
      return Duration.zero;
    }

    final oldestTimestamp = _requestTimestamps.first;
    final resetTime = oldestTimestamp.add(windowDuration);
    final now = DateTime.now();

    if (now.isAfter(resetTime)) {
      return Duration.zero;
    }

    return resetTime.difference(now);
  }

  /// Exécute une requête avec rate limiting
  ///
  /// Si la limite est atteinte, la requête est mise en queue
  /// et sera exécutée dès qu'un slot se libère
  Future<T> execute<T>(
    Future<T> Function() operation, {
    int priority = 0,
  }) async {
    if (canMakeRequest()) {
      _recordRequest();
      return await operation();
    }

    // Mettre en queue
    final completer = Completer<T>();
    _queue.add(
      _QueuedRequest(
        operation: () async {
          try {
            final result = await operation();
            completer.complete(result);
          } catch (e) {
            completer.completeError(e);
          }
        },
        priority: priority,
      ),
    );

    // Trier la queue par priorité (plus haute d'abord)
    _queue.sort((a, b) => b.priority.compareTo(a.priority));

    // Démarrer le traitement de la queue si pas déjà en cours
    _processQueue();

    return completer.future;
  }

  /// Enregistre une requête
  void _recordRequest() {
    _requestTimestamps.add(DateTime.now());
  }

  /// Nettoie les timestamps trop anciens
  void _cleanOldTimestamps() {
    final cutoff = DateTime.now().subtract(windowDuration);
    _requestTimestamps.removeWhere((timestamp) => timestamp.isBefore(cutoff));
  }

  /// Traite la queue de requêtes en attente
  Future<void> _processQueue() async {
    if (_isProcessingQueue || _queue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;

    while (_queue.isNotEmpty) {
      // Attendre qu'un slot se libère
      while (!canMakeRequest()) {
        final waitTime = getTimeUntilReset();
        debugPrint(
          'RateLimiter: Limite atteinte, attente de ${waitTime.inSeconds}s',
        );
        await Future.delayed(const Duration(seconds: 1));
      }

      // Exécuter la prochaine requête en queue
      final request = _queue.removeAt(0);
      _recordRequest();
      await request.operation();
    }

    _isProcessingQueue = false;
  }

  /// Retourne les statistiques du rate limiter
  Map<String, dynamic> getStats() {
    _cleanOldTimestamps();

    return {
      'requestsInWindow': _requestTimestamps.length,
      'remainingRequests': getRemainingRequests(),
      'queuedRequests': _queue.length,
      'timeUntilReset': getTimeUntilReset().inSeconds,
      'isLimited': !canMakeRequest(),
    };
  }

  /// Réinitialise le rate limiter
  void reset() {
    _requestTimestamps.clear();
    _queue.clear();
    _isProcessingQueue = false;
  }
}

/// Requête en queue avec priorité
class _QueuedRequest {
  final Future<void> Function() operation;
  final int priority;

  _QueuedRequest({required this.operation, required this.priority});
}
