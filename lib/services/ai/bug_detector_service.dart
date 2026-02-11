import 'package:pseudo_code/interpreteur/validateur.dart';

/// Service de détection proactive de bugs
class BugDetectorService {
  /// Détecte les bugs potentiels dans le code
  List<DetectedBug> detectBugs(String code) {
    final bugs = <DetectedBug>[];
    final lines = code.split('\n');

    // Utiliser le validateur existant
    final structuralErrors = ValidateurStructure.valider(lines);
    for (final error in structuralErrors) {
      bugs.add(
        DetectedBug(
          line: error.line ?? 0,
          type: BugType.syntaxError,
          severity: BugSeverity.high,
          message: error.message,
          suggestion: 'Corriger la syntaxe selon les règles du pseudocode',
        ),
      );
    }

    // Détection de patterns problématiques
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineNumber = i + 1;

      // Détection de boucles infinies potentielles
      if (_isPotentialInfiniteLoop(lines, i)) {
        bugs.add(
          DetectedBug(
            line: lineNumber,
            type: BugType.infiniteLoop,
            severity: BugSeverity.critical,
            message: 'Boucle potentiellement infinie détectée',
            suggestion:
                'Vérifier que la condition de sortie peut être atteinte',
          ),
        );
      }

      // Détection de division par zéro
      if (_hasPotentialDivisionByZero(line)) {
        bugs.add(
          DetectedBug(
            line: lineNumber,
            type: BugType.divisionByZero,
            severity: BugSeverity.high,
            message: 'Division par zéro potentielle',
            suggestion: 'Ajouter une vérification avant la division',
          ),
        );
      }

      // Détection de variables non initialisées
      if (_hasUninitializedVariable(lines, i)) {
        bugs.add(
          DetectedBug(
            line: lineNumber,
            type: BugType.uninitializedVariable,
            severity: BugSeverity.medium,
            message: 'Variable potentiellement non initialisée',
            suggestion: 'Initialiser la variable avant utilisation',
          ),
        );
      }

      // Détection d'accès hors limites
      if (_hasOutOfBoundsAccess(line)) {
        bugs.add(
          DetectedBug(
            line: lineNumber,
            type: BugType.outOfBounds,
            severity: BugSeverity.high,
            message: 'Accès hors limites potentiel',
            suggestion: 'Vérifier les indices avant l\'accès au tableau',
          ),
        );
      }

      // Détection de conditions toujours vraies/fausses
      if (_hasAlwaysTrueCondition(line)) {
        bugs.add(
          DetectedBug(
            line: lineNumber,
            type: BugType.alwaysTrueCondition,
            severity: BugSeverity.low,
            message: 'Condition toujours vraie',
            suggestion: 'Vérifier la logique de la condition',
          ),
        );
      }
    }

    return bugs;
  }

  bool _isPotentialInfiniteLoop(List<String> lines, int startIndex) {
    final line = lines[startIndex].trim().toLowerCase();

    // Détecter les boucles tantque/repeter
    if (!line.startsWith('tantque') && !line.startsWith('repeter')) {
      return false;
    }

    // Chercher la fin de la boucle
    int depth = 1;
    bool hasModification = false;

    for (int i = startIndex + 1; i < lines.length && depth > 0; i++) {
      final currentLine = lines[i].trim().toLowerCase();

      if (currentLine.startsWith('tantque') ||
          currentLine.startsWith('repeter')) {
        depth++;
      } else if (currentLine.startsWith('fintantque') ||
          currentLine.startsWith('jusqua')) {
        depth--;
      }

      // Vérifier s'il y a une modification de variable
      if (currentLine.contains('<-') || currentLine.contains('lire(')) {
        hasModification = true;
      }
    }

    // Si pas de modification dans la boucle, c'est suspect
    return !hasModification;
  }

  bool _hasPotentialDivisionByZero(String line) {
    // Chercher des divisions
    if (!line.contains('/')) return false;

    // Patterns suspects : division par 0, par (x-x), etc.
    final suspectPatterns = [
      RegExp(r'/\s*0\s*[^\d]'),
      RegExp(r'/\s*\(\s*\w+\s*-\s*\w+\s*\)'),
    ];

    return suspectPatterns.any((pattern) => pattern.hasMatch(line));
  }

  bool _hasUninitializedVariable(List<String> lines, int currentIndex) {
    final line = lines[currentIndex].trim().toLowerCase();

    // Chercher une utilisation de variable
    final useMatch = RegExp(r'(\w+)\s*(<-|=)').firstMatch(line);
    if (useMatch == null) return false;

    final varName = useMatch.group(1);
    if (varName == null) return false;

    // Vérifier si la variable a été déclarée/initialisée avant
    for (int i = 0; i < currentIndex; i++) {
      final prevLine = lines[i].trim().toLowerCase();
      if (prevLine.contains('variables') && prevLine.contains(varName)) {
        return false; // Déclarée
      }
      if (prevLine.contains('$varName <-') ||
          prevLine.contains('lire($varName')) {
        return false; // Initialisée
      }
    }

    return true;
  }

  bool _hasOutOfBoundsAccess(String line) {
    // Chercher des accès à des tableaux avec indices fixes
    final arrayAccess = RegExp(r'\w+\[(\d+)\]');
    final matches = arrayAccess.allMatches(line);

    for (final match in matches) {
      final index = int.tryParse(match.group(1) ?? '');
      // Si l'indice est 0 ou très grand, c'est suspect
      if (index != null && (index == 0 || index > 1000)) {
        return true;
      }
    }

    return false;
  }

  bool _hasAlwaysTrueCondition(String line) {
    final lower = line.toLowerCase();

    // Conditions évidentes
    if (lower.contains('si vrai') ||
        lower.contains('si 1 = 1') ||
        lower.contains('tantque vrai')) {
      return true;
    }

    return false;
  }
}

/// Bug détecté
class DetectedBug {
  final int line;
  final BugType type;
  final BugSeverity severity;
  final String message;
  final String suggestion;

  DetectedBug({
    required this.line,
    required this.type,
    required this.severity,
    required this.message,
    required this.suggestion,
  });
}

/// Types de bugs
enum BugType {
  syntaxError,
  infiniteLoop,
  divisionByZero,
  uninitializedVariable,
  outOfBounds,
  alwaysTrueCondition,
  logicError,
}

/// Sévérité des bugs
enum BugSeverity { critical, high, medium, low }
