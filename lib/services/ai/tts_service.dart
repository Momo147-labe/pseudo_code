import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Service Text-to-Speech pour lire les réponses de l'IA
class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isEnabled = false;
  bool _isSpeaking = false;

  // Configuration
  String _language = 'fr-FR';
  double _speechRate = 0.5; // 0.0 à 1.0
  double _pitch = 1.0; // 0.5 à 2.0
  double _volume = 1.0; // 0.0 à 1.0

  bool get isEnabled => _isEnabled;
  bool get isSpeaking => _isSpeaking;
  String get language => _language;

  /// Initialise le service TTS
  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      // Configuration de base
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);

      // Callbacks
      _tts.setStartHandler(() {
        _isSpeaking = true;
        debugPrint('TTS: Démarrage de la lecture');
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
        debugPrint('TTS: Lecture terminée');
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('TTS: Erreur - $msg');
      });

      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('TTS: Erreur initialisation - $e');
      return false;
    }
  }

  /// Active ou désactive le TTS
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled && _isSpeaking) {
      await stop();
    }
  }

  /// Lit un texte
  Future<void> speak(String text) async {
    if (!_isEnabled) return;

    if (!_isInitialized) {
      final success = await init();
      if (!success) {
        debugPrint('TTS: Impossible d\'initialiser');
        return;
      }
    }

    try {
      // Arrêter la lecture en cours si nécessaire
      if (_isSpeaking) {
        await stop();
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS: Erreur lecture - $e');
    }
  }

  /// Arrête la lecture en cours
  Future<void> stop() async {
    if (_isSpeaking) {
      try {
        await _tts.stop();
        _isSpeaking = false;
      } catch (e) {
        debugPrint('TTS: Erreur arrêt - $e');
      }
    }
  }

  /// Pause la lecture
  Future<void> pause() async {
    if (_isSpeaking) {
      try {
        await _tts.pause();
      } catch (e) {
        debugPrint('TTS: Erreur pause - $e');
      }
    }
  }

  /// Change la langue
  Future<void> setLanguage(String language) async {
    _language = language;
    if (_isInitialized) {
      try {
        await _tts.setLanguage(language);
      } catch (e) {
        debugPrint('TTS: Erreur changement langue - $e');
      }
    }
  }

  /// Change la vitesse de lecture
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    if (_isInitialized) {
      try {
        await _tts.setSpeechRate(_speechRate);
      } catch (e) {
        debugPrint('TTS: Erreur changement vitesse - $e');
      }
    }
  }

  /// Change le pitch
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    if (_isInitialized) {
      try {
        await _tts.setPitch(_pitch);
      } catch (e) {
        debugPrint('TTS: Erreur changement pitch - $e');
      }
    }
  }

  /// Change le volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_isInitialized) {
      try {
        await _tts.setVolume(_volume);
      } catch (e) {
        debugPrint('TTS: Erreur changement volume - $e');
      }
    }
  }

  /// Récupère les langues disponibles
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('TTS: Erreur récupération langues - $e');
      return [];
    }
  }

  /// Récupère les voix disponibles pour une langue
  Future<List<Map<String, String>>> getVoices() async {
    try {
      final voices = await _tts.getVoices;
      return List<Map<String, String>>.from(voices);
    } catch (e) {
      debugPrint('TTS: Erreur récupération voix - $e');
      return [];
    }
  }

  /// Nettoie les ressources
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}
