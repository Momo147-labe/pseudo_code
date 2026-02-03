import 'mpd_generator.dart';

/// Utilities shared by Merise SQL generation/simulation.
///
/// Goals:
/// - Normalize concept types coming from MCD/MLD UI (FR/EN variants)
/// - Quote identifiers consistently per dialect
/// - Keep a single source of truth for reserved words
class SqlUtils {
  static final Set<String> reservedWords = {
    'SELECT',
    'INSERT',
    'UPDATE',
    'DELETE',
    'CREATE',
    'DROP',
    'ALTER',
    'TABLE',
    'INDEX',
    'VIEW',
    'FROM',
    'WHERE',
    'JOIN',
    'ON',
    'AND',
    'OR',
    'NOT',
    'NULL',
    'PRIMARY',
    'KEY',
    'FOREIGN',
    'REFERENCES',
    'CHECK',
    'DEFAULT',
    'UNIQUE',
    'ORDER',
    'BY',
    'GROUP',
    'HAVING',
    'LIMIT',
    'OFFSET',
    'IN',
    'IS',
    'AS',
    'INTO',
    'VALUES',
    'UNION',
    'ALL',
    'ANY',
    'BETWEEN',
    'EXISTS',
    'LIKE',
    'DESC',
    'ASC',
  };

  /// Returns true if [name] is a "simple" SQL identifier (no spaces/special chars).
  static bool isSimpleIdentifier(String name) {
    return RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(name);
  }

  static bool isReserved(String name) => reservedWords.contains(name.toUpperCase());

  /// Quote an identifier for a given [dialect] if necessary.
  static String quote(String name, SqlDialect dialect) {
    final needsQuoting = !isSimpleIdentifier(name) || isReserved(name);
    if (!needsQuoting) return name;

    if (dialect == SqlDialect.mysql) return '`$name`';
    return '"$name"';
  }

  /// Normalize a concept type coming from the MCD (FR/EN variants) to a canonical key.
  ///
  /// Returned values are stable keys used by generators and validators:
  /// - string, int, float, bool, date, text
  static String canonicalType(String raw) {
    final t = raw.trim().toLowerCase();

    // Common UI values: String / Entier / Reel / Date / Booleen
    if (t == 'string' || t == 'chaine' || t == 'chaîne') return 'string';
    if (t == 'texte' || t == 'text') return 'text';
    if (t == 'entier' || t == 'int' || t == 'integer') return 'int';
    if (t == 'reel' || t == 'réel' || t == 'float' || t == 'double' || t == 'real') {
      return 'float';
    }
    if (t == 'booleen' || t == 'bool' || t == 'boolean') return 'bool';
    if (t == 'date' || t == 'datetime') return 'date';

    // MCD default in your models
    if (t == 'chaine') return 'string';
    if (t == 'chaine ') return 'string';

    // Fallback: treat unknown as string-ish
    return 'string';
  }
}

