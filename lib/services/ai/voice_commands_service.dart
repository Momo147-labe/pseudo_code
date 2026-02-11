/// Service de commandes vocales pour l'assistant AI
class VoiceCommandsService {
  /// Détecte l'intention d'une commande vocale
  VoiceCommand? detectCommand(String text) {
    final lowerText = text.toLowerCase().trim();

    // Commande : Expliquer le code
    if (_matchesKeywords(lowerText, [
      'expliquer',
      'explique',
      'qu\'est-ce que',
      'c\'est quoi',
      'comment ça marche',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.explain,
        originalText: text,
        confidence: 0.9,
      );
    }

    // Commande : Trouver les erreurs
    if (_matchesKeywords(lowerText, [
      'erreur',
      'bug',
      'problème',
      'trouve',
      'cherche',
      'vérifie',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.findBugs,
        originalText: text,
        confidence: 0.9,
      );
    }

    // Commande : Optimiser
    if (_matchesKeywords(lowerText, [
      'optimise',
      'optimiser',
      'améliore',
      'améliorer',
      'plus rapide',
      'performance',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.optimize,
        originalText: text,
        confidence: 0.9,
      );
    }

    // Commande : Traduire
    if (_matchesKeywords(lowerText, [
      'traduis',
      'traduire',
      'convertir',
      'transformer',
    ])) {
      // Détecter le langage cible
      String? targetLanguage;
      if (lowerText.contains('python'))
        targetLanguage = 'Python';
      else if (lowerText.contains('java'))
        targetLanguage = 'Java';
      else if (lowerText.contains('c++') || lowerText.contains('cpp')) {
        targetLanguage = 'C++';
      } else if (lowerText.contains('javascript') || lowerText.contains('js')) {
        targetLanguage = 'JavaScript';
      } else if (lowerText.contains('c '))
        targetLanguage = 'C';

      return VoiceCommand(
        type: VoiceCommandType.translate,
        originalText: text,
        confidence: 0.8,
        parameters: {'language': targetLanguage ?? 'Python'},
      );
    }

    // Commande : Code Review
    if (_matchesKeywords(lowerText, [
      'review',
      'revue',
      'analyse',
      'évalue',
      'qualité',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.codeReview,
        originalText: text,
        confidence: 0.85,
      );
    }

    // Commande : Générer des tests
    if (_matchesKeywords(lowerText, [
      'test',
      'tests',
      'cas de test',
      'vérification',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.generateTests,
        originalText: text,
        confidence: 0.85,
      );
    }

    // Commande : Nettoyer le code
    if (_matchesKeywords(lowerText, [
      'nettoie',
      'nettoyer',
      'clean',
      'lisibilité',
      'reformate',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.clean,
        originalText: text,
        confidence: 0.8,
      );
    }

    // Commande : Effacer l'historique
    if (_matchesKeywords(lowerText, [
      'efface',
      'effacer',
      'supprimer',
      'clear',
      'nouveau',
      'recommence',
    ])) {
      return VoiceCommand(
        type: VoiceCommandType.clearHistory,
        originalText: text,
        confidence: 0.9,
      );
    }

    // Aucune commande détectée, c'est une question libre
    return VoiceCommand(
      type: VoiceCommandType.freeQuestion,
      originalText: text,
      confidence: 0.5,
    );
  }

  /// Vérifie si le texte contient au moins un des mots-clés
  bool _matchesKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Convertit une commande vocale en prompt textuel
  String commandToPrompt(VoiceCommand command) {
    switch (command.type) {
      case VoiceCommandType.explain:
        return "Expliquer mon code";
      case VoiceCommandType.findBugs:
        return "Trouver les erreurs dans mon code";
      case VoiceCommandType.optimize:
        return "Optimiser mon code";
      case VoiceCommandType.translate:
        final lang = command.parameters?['language'] ?? 'Python';
        return "Traduire mon code en $lang";
      case VoiceCommandType.codeReview:
        return "Faire une revue de code complète";
      case VoiceCommandType.generateTests:
        return "Générer des cas de test pour mon code";
      case VoiceCommandType.clean:
        return "Améliorer la lisibilité de mon code";
      case VoiceCommandType.clearHistory:
        return ""; // Géré différemment (action directe)
      case VoiceCommandType.freeQuestion:
        return command.originalText;
    }
  }
}

/// Types de commandes vocales
enum VoiceCommandType {
  explain,
  findBugs,
  optimize,
  translate,
  codeReview,
  generateTests,
  clean,
  clearHistory,
  freeQuestion,
}

/// Représente une commande vocale détectée
class VoiceCommand {
  final VoiceCommandType type;
  final String originalText;
  final double confidence;
  final Map<String, dynamic>? parameters;

  VoiceCommand({
    required this.type,
    required this.originalText,
    required this.confidence,
    this.parameters,
  });

  bool get isAction => type == VoiceCommandType.clearHistory;
}
