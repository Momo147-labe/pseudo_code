import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class FileOpenService {
  /// Récupère la liste des fichiers .alg valides à partir des arguments CLI.
  static List<String> getFilesFromArgs(List<String> args) {
    if (args.isEmpty) return [];

    final List<String> filesToOpen = [];

    for (var arg in args) {
      // Nettoyage des guillemets potentiels ajoutés par l'OS
      String path = arg.trim();
      if (path.startsWith('"') && path.endsWith('"')) {
        path = path.substring(1, path.length - 1);
      }

      final file = File(path);

      // Validation du fichier
      if (file.existsSync()) {
        final extension = p.extension(path).toLowerCase();
        if (extension == '.alg') {
          filesToOpen.add(path);
        } else {
          debugPrint("Fichier ignoré Car extension non supportée : $path");
        }
      } else {
        // Optionnel : si on passe juste un nom sans dossier,
        // on pourrait chercher dans le dossier courant,
        // mais restons sur des chemins absolus pour la robustesse CLI Windows.
        debugPrint("Fichier introuvable : $path");
      }
    }

    return filesToOpen;
  }
}
