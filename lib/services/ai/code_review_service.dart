import 'package:flutter/foundation.dart';
import 'package:pseudo_code/services/ai/illm_service.dart';
import 'package:pseudo_code/services/ai/prompt_templates.dart';

/// Service de revue de code automatique
class CodeReviewService {
  final ILlmService _aiService;

  CodeReviewService(this._aiService);

  /// Effectue une revue complète du code
  Future<CodeReviewResult> reviewCode(String code) async {
    try {
      final prompt = PromptTemplates.codeReview(code);

      final response = await _aiService.getChatCompletion([
        {"role": "user", "content": prompt},
      ], isAgentMode: false);

      return _parseReviewResponse(response);
    } catch (e) {
      debugPrint('CodeReviewService: Erreur - $e');
      return CodeReviewResult(
        score: 0,
        strengths: [],
        improvements: [],
        bugs: [],
        suggestions: [],
        rawResponse: e.toString(),
      );
    }
  }

  /// Parse la réponse de l'IA pour extraire les informations structurées
  CodeReviewResult _parseReviewResponse(String response) {
    int score = 50; // Score par défaut
    final strengths = <String>[];
    final improvements = <String>[];
    final bugs = <CodeBug>[];
    final suggestions = <String>[];

    // Extraire le score
    final scoreMatch = RegExp(r'Score.*?(\d+)/100').firstMatch(response);
    if (scoreMatch != null) {
      score = int.tryParse(scoreMatch.group(1) ?? '50') ?? 50;
    }

    // Extraire les points forts
    final strengthsSection = _extractSection(response, 'Points forts');
    if (strengthsSection != null) {
      strengths.addAll(_extractListItems(strengthsSection));
    }

    // Extraire les points à améliorer
    final improvementsSection = _extractSection(response, 'Points à améliorer');
    if (improvementsSection != null) {
      improvements.addAll(_extractListItems(improvementsSection));
    }

    // Extraire les bugs
    final bugsSection = _extractSection(response, 'Bugs détectés');
    if (bugsSection != null) {
      bugs.addAll(_extractBugs(bugsSection));
    }

    // Extraire les suggestions
    final suggestionsSection = _extractSection(response, 'Suggestions');
    if (suggestionsSection != null) {
      suggestions.addAll(_extractListItems(suggestionsSection));
    }

    return CodeReviewResult(
      score: score,
      strengths: strengths,
      improvements: improvements,
      bugs: bugs,
      suggestions: suggestions,
      rawResponse: response,
    );
  }

  String? _extractSection(String text, String sectionName) {
    final pattern = RegExp(
      '$sectionName.*?:(.*?)(?=\\n\\n|\\*\\*|\\Z)',
      dotAll: true,
      caseSensitive: false,
    );
    final match = pattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  List<String> _extractListItems(String text) {
    final items = <String>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('-') ||
          trimmed.startsWith('•') ||
          RegExp(r'^\d+\.').hasMatch(trimmed)) {
        items.add(trimmed.replaceFirst(RegExp(r'^[-•\d.]+\s*'), ''));
      }
    }

    return items;
  }

  List<CodeBug> _extractBugs(String text) {
    final bugs = <CodeBug>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final lineMatch = RegExp(
        r'Ligne\s+(\d+)',
        caseSensitive: false,
      ).firstMatch(line);

      if (lineMatch != null) {
        final lineNumber = int.tryParse(lineMatch.group(1) ?? '0') ?? 0;
        final description = line.replaceFirst(lineMatch.group(0)!, '').trim();

        bugs.add(
          CodeBug(
            line: lineNumber,
            description: description,
            severity: _detectSeverity(description),
          ),
        );
      }
    }

    return bugs;
  }

  BugSeverity _detectSeverity(String description) {
    final lower = description.toLowerCase();

    if (lower.contains('critique') ||
        lower.contains('grave') ||
        lower.contains('bloquant')) {
      return BugSeverity.critical;
    } else if (lower.contains('important') || lower.contains('majeur')) {
      return BugSeverity.major;
    } else if (lower.contains('mineur') || lower.contains('cosmétique')) {
      return BugSeverity.minor;
    }

    return BugSeverity.moderate;
  }
}

/// Résultat d'une revue de code
class CodeReviewResult {
  final int score; // 0-100
  final List<String> strengths;
  final List<String> improvements;
  final List<CodeBug> bugs;
  final List<String> suggestions;
  final String rawResponse;

  CodeReviewResult({
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.bugs,
    required this.suggestions,
    required this.rawResponse,
  });

  String get scoreLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Très bon';
    if (score >= 60) return 'Bon';
    if (score >= 40) return 'Moyen';
    return 'À améliorer';
  }
}

/// Représente un bug détecté
class CodeBug {
  final int line;
  final String description;
  final BugSeverity severity;

  CodeBug({
    required this.line,
    required this.description,
    required this.severity,
  });
}

/// Sévérité d'un bug
enum BugSeverity { critical, major, moderate, minor }
