import 'dart:math';
import 'package:pseudo_code/interpreteur/blocs/tableaux.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';

/// Gère les fonctions natives du langage pseudo-code
class FonctionsNatives {
  static final List<String> _noms = [
    'long',
    'maj',
    'minus',
    'car',
    'racine',
    'abs',
    'hasard',
    'arrondi',
    'tronque',
    'en_entier',
    'en_reel',
    'en_chaine',
    'typevar',
    'est_numerique',
  ];

  /// Vérifie si une fonction est native
  static bool estNative(String nom) => _noms.contains(nom.toLowerCase());

  /// Liste tous les noms de fonctions natives
  static List<String> get noms => List.unmodifiable(_noms);

  /// Exécute une fonction native avec ses arguments déjà évalués
  static dynamic executer(String nom, List<dynamic> args) {
    switch (nom.toLowerCase()) {
      // 1. Chaînes
      case 'long':
        _verifierArgs(nom, args, 1);
        return args[0].toString().length;
      case 'maj':
        _verifierArgs(nom, args, 1);
        return args[0].toString().toUpperCase();
      case 'minus':
        _verifierArgs(nom, args, 1);
        return args[0].toString().toLowerCase();
      case 'car':
        _verifierArgs(nom, args, 2);
        final s = args[0].toString();
        final pos = _toInt(args[1]);
        if (pos < 1 || pos > s.length) {
          throw Exception(
            "Indice $pos hors des bornes [1..${s.length}] pour la chaîne.",
          );
        }
        return s[pos - 1];

      // 2. Maths
      case 'racine':
        _verifierArgs(nom, args, 1);
        return sqrt(_toDouble(args[0]));
      case 'abs':
        _verifierArgs(nom, args, 1);
        final val = args[0];
        if (val is num) return val.abs();
        if (val is BigInt) return val.abs();
        throw Exception("abs() attend un nombre.");
      case 'hasard':
        _verifierArgs(nom, args, 2);
        final min = _toInt(args[0]);
        final max = _toInt(args[1]);
        if (max < min) throw Exception("hasard(min, max): max < min");
        return Random().nextInt(max - min + 1) + min;
      case 'arrondi':
        _verifierArgs(nom, args, 1);
        return _toDouble(args[0]).round();
      case 'tronque':
        _verifierArgs(nom, args, 1);
        return _toDouble(args[0]).truncate();

      // 3. Conversion
      case 'en_entier':
        _verifierArgs(nom, args, 1);
        return int.tryParse(args[0].toString()) ??
            (throw Exception(
              "'${args[0]}' ne peut pas être converti en entier.",
            ));
      case 'en_reel':
        _verifierArgs(nom, args, 1);
        return double.tryParse(args[0].toString()) ?? 0.0;
      case 'en_chaine':
        _verifierArgs(nom, args, 1);
        return args[0].toString();

      // 4. Analyse
      case 'typevar':
        _verifierArgs(nom, args, 1);
        final val = args[0];
        if (val is int || val is BigInt) return "entier";
        if (val is double) return "reel";
        if (val is String) return "chaine";
        if (val is bool) return "booleen";
        if (val is PseudoTableau) return "tableau";
        if (val is PseudoStructureInstance) return "structure";
        return "inconnu";
      case 'est_numerique':
        _verifierArgs(nom, args, 1);
        final valStr = args[0].toString();
        return num.tryParse(valStr) != null || BigInt.tryParse(valStr) != null;

      default:
        throw Exception("Fonction native '$nom' non implémentée.");
    }
  }

  static void _verifierArgs(String nom, List<dynamic> args, int attendus) {
    if (args.length != attendus) {
      throw Exception("$nom() attend $attendus argument(s).");
    }
  }

  static double _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    final parsed = double.tryParse(val.toString());
    if (parsed != null) return parsed;
    throw Exception("Valeur numérique attendue, reçu: $val");
  }

  static int _toInt(dynamic val) {
    if (val is int) return val;
    if (val is BigInt) return val.toInt();
    if (val is double) return val.toInt();
    final s = val.toString();
    final parsed = int.tryParse(s) ?? BigInt.tryParse(s)?.toInt();
    if (parsed != null) return parsed;
    throw Exception("Valeur entière attendue, reçu: $val");
  }
}
