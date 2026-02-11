import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de cache intelligent pour les réponses AI
class AiCacheService {
  // Cache en mémoire avec expiration
  final Map<String, _CacheEntry> _memoryCache = {};

  // Durée d'expiration par défaut : 30 minutes
  static const Duration _defaultExpiration = Duration(minutes: 30);

  // Préfixe pour les clés SharedPreferences
  static const String _prefixKey = 'ai_cache_';

  // Stats
  int _hits = 0;
  int _misses = 0;

  /// Génère une clé de cache basée sur le hash du prompt + contexte
  String _generateKey(
    List<Map<String, String>> messages,
    String? contextCode,
    String? mcdContext,
    bool isAgentMode,
  ) {
    final content = jsonEncode({
      'messages': messages,
      'contextCode': contextCode,
      'mcdContext': mcdContext,
      'isAgentMode': isAgentMode,
    });

    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Récupère une réponse du cache (mémoire puis persistant)
  Future<String?> get(
    List<Map<String, String>> messages,
    String? contextCode,
    String? mcdContext,
    bool isAgentMode,
  ) async {
    final key = _generateKey(messages, contextCode, mcdContext, isAgentMode);

    // Vérifier le cache mémoire d'abord
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        _hits++;
        return entry.response;
      } else {
        _memoryCache.remove(key);
      }
    }

    // Vérifier le cache persistant
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('$_prefixKey$key');

      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        final expiration = DateTime.parse(data['expiration']);

        if (DateTime.now().isBefore(expiration)) {
          _hits++;
          // Remettre en cache mémoire
          _memoryCache[key] = _CacheEntry(
            response: data['response'],
            expiration: expiration,
          );
          return data['response'];
        } else {
          // Supprimer l'entrée expirée
          await prefs.remove('$_prefixKey$key');
        }
      }
    } catch (e) {
      // Ignorer les erreurs de cache persistant
    }

    _misses++;
    return null;
  }

  /// Stocke une réponse dans le cache
  Future<void> set(
    List<Map<String, String>> messages,
    String? contextCode,
    String? mcdContext,
    bool isAgentMode,
    String response, {
    Duration? expiration,
  }) async {
    final key = _generateKey(messages, contextCode, mcdContext, isAgentMode);
    final exp = expiration ?? _defaultExpiration;
    final expirationDate = DateTime.now().add(exp);

    // Stocker en mémoire
    _memoryCache[key] = _CacheEntry(
      response: response,
      expiration: expirationDate,
    );

    // Stocker de manière persistante pour les réponses fréquentes
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode({
        'response': response,
        'expiration': expirationDate.toIso8601String(),
      });
      await prefs.setString('$_prefixKey$key', data);
    } catch (e) {
      // Ignorer les erreurs de cache persistant
    }
  }

  /// Efface tout le cache
  Future<void> clear() async {
    _memoryCache.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefixKey));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      // Ignorer les erreurs
    }

    _hits = 0;
    _misses = 0;
  }

  /// Retourne les statistiques du cache
  Map<String, dynamic> getCacheStats() {
    final total = _hits + _misses;
    final hitRate = total > 0
        ? (_hits / total * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'hits': _hits,
      'misses': _misses,
      'total': total,
      'hitRate': '$hitRate%',
      'memoryCacheSize': _memoryCache.length,
    };
  }

  /// Nettoie les entrées expirées du cache mémoire
  void cleanExpired() {
    _memoryCache.removeWhere((key, entry) => entry.isExpired);
  }
}

/// Entrée de cache avec expiration
class _CacheEntry {
  final String response;
  final DateTime expiration;

  _CacheEntry({required this.response, required this.expiration});

  bool get isExpired => DateTime.now().isAfter(expiration);
}
