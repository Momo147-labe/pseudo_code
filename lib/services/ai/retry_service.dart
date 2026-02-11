import 'package:flutter/foundation.dart';

/// Service de retry avec backoff exponentiel
class RetryService {
  // Configuration
  static const int maxRetries = 3;
  static const Duration initialDelay = Duration(seconds: 1);

  /// Exécute une fonction avec retry automatique
  ///
  /// [operation] : La fonction à exécuter
  /// [maxAttempts] : Nombre maximum de tentatives (défaut: 3)
  /// [onRetry] : Callback appelé avant chaque retry
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    int attempt = 0;
    Exception? lastError;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;

        // Si c'est la dernière tentative, on lance l'erreur
        if (attempt >= maxAttempts) {
          debugPrint('RetryService: Échec après $maxAttempts tentatives');
          rethrow;
        }

        // Vérifier si l'erreur est temporaire ou permanente
        if (_isPermanentError(lastError)) {
          debugPrint('RetryService: Erreur permanente détectée, abandon');
          rethrow;
        }

        // Calculer le délai avec backoff exponentiel
        final delay = _calculateDelay(attempt);

        debugPrint(
          'RetryService: Tentative $attempt/$maxAttempts échouée, '
          'retry dans ${delay.inSeconds}s',
        );

        // Notifier avant le retry
        onRetry?.call(attempt, lastError);

        // Attendre avant de réessayer
        await Future.delayed(delay);
      }
    }

    // Ne devrait jamais arriver ici
    throw lastError ?? Exception('Erreur inconnue');
  }

  /// Calcule le délai avec backoff exponentiel
  /// Tentative 1: 1s, Tentative 2: 2s, Tentative 3: 4s
  static Duration _calculateDelay(int attempt) {
    final multiplier = 1 << (attempt - 1); // 2^(attempt-1)
    return initialDelay * multiplier;
  }

  /// Détermine si une erreur est permanente (pas de retry)
  static bool _isPermanentError(Exception error) {
    final errorMsg = error.toString().toLowerCase();

    // Erreurs permanentes (ne pas retry)
    final permanentErrors = [
      'unauthorized',
      'forbidden',
      'invalid api key',
      'authentication failed',
      'bad request',
      '400',
      '401',
      '403',
      '404',
    ];

    for (final pattern in permanentErrors) {
      if (errorMsg.contains(pattern)) {
        return true;
      }
    }

    // Erreurs temporaires (retry possible)
    final temporaryErrors = [
      'timeout',
      'connection',
      'network',
      'rate limit',
      '429',
      '500',
      '502',
      '503',
      '504',
    ];

    for (final pattern in temporaryErrors) {
      if (errorMsg.contains(pattern)) {
        return false;
      }
    }

    // Par défaut, considérer comme temporaire
    return false;
  }

  /// Exécute une opération avec retry et retourne un résultat ou null en cas d'échec
  static Future<T?> tryExecute<T>(
    Future<T> Function() operation, {
    int maxAttempts = maxRetries,
    void Function(int attempt, Exception error)? onRetry,
  }) async {
    try {
      return await execute(
        operation,
        maxAttempts: maxAttempts,
        onRetry: onRetry,
      );
    } catch (e) {
      debugPrint('RetryService: Échec définitif - $e');
      return null;
    }
  }
}
