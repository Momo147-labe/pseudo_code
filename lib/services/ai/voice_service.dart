import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  String _currentLocale = "fr_FR"; // Langue par défaut

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get currentLocale => _currentLocale;

  Future<bool> init() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Voice Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (errorNotification) {
          debugPrint('Voice Error: $errorNotification');
          _isListening = false;
        },
      );
      return _isAvailable;
    } catch (e) {
      debugPrint("Erreur init VoiceService: $e");
      return false;
    }
  }

  /// Récupère les locales disponibles
  Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isAvailable) {
      await init();
    }

    try {
      return await _speech.locales();
    } catch (e) {
      debugPrint("Erreur récupération locales: $e");
      return [];
    }
  }

  /// Change la langue de reconnaissance
  Future<void> setLocale(String locale) async {
    _currentLocale = locale;
  }

  /// Détecte automatiquement la langue (basé sur les locales système)
  Future<String> detectLanguage() async {
    final locales = await getAvailableLocales();

    // Chercher français en priorité
    final frLocale = locales.firstWhere(
      (l) => l.localeId.startsWith('fr'),
      orElse: () => locales.isNotEmpty
          ? locales.first
          : stt.LocaleName('en_US', 'English'),
    );

    return frLocale.localeId;
  }

  Future<void> startListening({
    required Function(String) onResult,
    required VoidCallback onDone,
    String? locale,
  }) async {
    if (!_isAvailable) {
      bool success = await init();
      if (!success) {
        debugPrint("Voice recognition not available");
        return;
      }
    }

    if (_isListening) {
      await stopListening();
      return; // Toggle logic if already listening
    }

    // Utiliser la locale spécifiée ou celle par défaut
    final useLocale = locale ?? _currentLocale;

    _isListening = true;
    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          _isListening = false;
          onDone();
        }
        onResult(result.recognizedWords);
      },
      localeId: useLocale,
      cancelOnError: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await stopListening();
  }
}
