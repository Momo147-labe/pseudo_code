import 'package:pseudo_code/interpreteur/environnement.dart';
import 'package:pseudo_code/interpreteur/executeur.dart';
import 'package:pseudo_code/interpreteur/mots_cles.dart';
import 'package:pseudo_code/interpreteur/navigateur_blocs.dart';
import 'package:pseudo_code/interpreteur/blocs/fonctions.dart';
import 'package:pseudo_code/interpreteur/blocs/structures.dart';
import 'package:pseudo_code/providers/debug_provider.dart';

class PreAnalyseur {
  static final RegExp _regConstLine = RegExp(
    r'^const\s+(.*)$',
    caseSensitive: false,
  );
  static final RegExp _regAssignConst = RegExp(
    r'^([a-zA-Z_]\w*)\s*(?:<-|←|=)\s*(.*)$',
  );
  static final RegExp _regTypeStruct = RegExp(
    r'^type\s+([a-zA-Z_]\w*)\s*=\s*structure',
    caseSensitive: false,
  );
  static final RegExp _regTypeSimple = RegExp(
    r'^type\s+([a-zA-Z_]\w*)\s*=\s*(.*)$',
    caseSensitive: false,
  );
  static final RegExp _regValidId = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$');
  static final RegExp _regStartsWithNum = RegExp(r'^[0-9]');

  static Future<void> analyser(
    List<String> lignes,
    Environnement env,
    DebugProvider provider,
    Function(String) onOutput,
  ) async {
    await _enregistrerConstantes(lignes, env, provider, onOutput);
    _enregistrerTypesEtStructures(lignes, env);
    _enregistrerSousProgrammes(lignes, env);
  }

  static Future<void> _enregistrerConstantes(
    List<String> lignes,
    Environnement env,
    DebugProvider provider,
    Function(String) onOutput,
  ) async {
    final exec = Executeur(
      env,
      provider: provider,
      onInput: () async => "",
      onOutput: onOutput,
    );

    for (int i = 0; i < lignes.length; i++) {
      final l = lignes[i].trim();
      final matchLine = _regConstLine.firstMatch(l);
      if (matchLine != null) {
        final declarations = matchLine.group(1)!;
        final parts = _splitDeclarations(declarations);
        for (final part in parts) {
          final m = _regAssignConst.firstMatch(part.trim());
          if (m != null) {
            final nom = m.group(1)!;
            validerNomIdentifier(nom);
            final expr = m.group(2)!;
            try {
              final valeur = await exec.evaluer(expr);
              env.declarerConstante(nom, valeur);
            } catch (e) {
              onOutput(
                "Erreur lors de l'évaluation de la constante '$nom': $e",
              );
            }
          }
        }
      }
    }
  }

  static List<String> _splitDeclarations(String s) {
    final result = <String>[];
    String courant = "";
    int parenStack = 0;
    for (int i = 0; i < s.length; i++) {
      if (s[i] == '(') parenStack++;
      if (s[i] == ')') parenStack--;
      if (s[i] == ',' && parenStack == 0) {
        result.add(courant.trim());
        courant = "";
      } else {
        courant += s[i];
      }
    }
    if (courant.isNotEmpty) result.add(courant.trim());
    return result;
  }

  static void _enregistrerTypesEtStructures(
    List<String> lignes,
    Environnement env,
  ) {
    int i = 0;
    while (i < lignes.length) {
      String l = lignes[i].trim();
      final matchStruct = _regTypeStruct.firstMatch(l);
      if (matchStruct != null) {
        String nomStruct = matchStruct.group(1)!;
        validerNomIdentifier(nomStruct);
        nomStruct = nomStruct.toLowerCase();
        List<ChampStructure> champs = [];
        i++;
        while (i < lignes.length) {
          String ligneChamp = lignes[i].trim();
          if (ligneChamp.toLowerCase() == 'finstructure') break;
          if (ligneChamp.contains(':')) {
            final p = ligneChamp.split(':');
            final noms = p[0].split(',').map((e) => e.trim());
            final type = p[1].trim();
            for (final n in noms) {
              if (n.isNotEmpty) {
                validerNomIdentifier(n);
                champs.add(ChampStructure(nom: n, type: type));
              }
            }
          }
          i++;
        }
        env.declarerStructure(
          PseudoStructureDefinition(nom: nomStruct, champs: champs),
        );
      } else {
        final matchSimple = _regTypeSimple.firstMatch(l);
        if (matchSimple != null) {
          final nom = matchSimple.group(1)!;
          validerNomIdentifier(nom);
          final def = matchSimple.group(2)!;
          env.declarerType(nom, def);
        }
      }
      i++;
    }
  }

  static void _enregistrerSousProgrammes(
    List<String> lignes,
    Environnement env,
  ) {
    int i = 0;
    while (i < lignes.length) {
      String l = lignes[i].trim();
      if (l.toLowerCase().startsWith('fonction')) {
        final match = GestionnaireFonctions.regFonction.firstMatch(l);
        if (match != null) {
          final nom = match.group(1)!;
          validerNomIdentifier(nom);
          final params = GestionnaireFonctions.extraireParametres(
            match.group(2)!,
          );
          for (final p in params) {
            validerNomIdentifier(p.nom);
          }
          final typeRetour = match.group(3)!;
          final debutIdx = i + 1;
          final finIdx = NavigateurBlocs.trouverFinBlocCorrespondant(
            lignes,
            debutIdx,
            'fonction',
            ['finfonction'],
          );
          env.declarerFonction(
            PseudoFonction(
              nom: nom,
              parametres: params,
              typeRetour: typeRetour,
              lignes: lignes.sublist(debutIdx, finIdx - 1),
              offset: debutIdx,
            ),
          );
          i = finIdx;
          continue;
        }
      } else if (l.toLowerCase().startsWith('procedure')) {
        final match = GestionnaireFonctions.regProcedure.firstMatch(l);
        if (match != null) {
          final nom = match.group(1)!;
          validerNomIdentifier(nom);
          final params = GestionnaireFonctions.extraireParametres(
            match.group(2)!,
          );
          for (final p in params) {
            validerNomIdentifier(p.nom);
          }
          final debutIdx = i + 1;
          final finIdx = NavigateurBlocs.trouverFinBlocCorrespondant(
            lignes,
            debutIdx,
            'procedure',
            ['finprocedure'],
          );
          env.declarerProcedure(
            PseudoProcedure(
              nom: nom,
              parametres: params,
              lignes: lignes.sublist(debutIdx, finIdx - 1),
              offset: debutIdx,
            ),
          );
          i = finIdx;
          continue;
        }
      }
      i++;
    }
  }

  static void validerNomIdentifier(String nom) {
    if (nom.isEmpty) return;
    final lower = nom.toLowerCase();
    // On autorise certains petits mots qui servent de séparateurs (a, à, de)
    // à être aussi utilisés comme noms de variables si l'utilisateur le souhaite.
    if (MotsCles.estUnMotCle(nom) &&
        lower != 'a' &&
        lower != 'à' &&
        lower != 'de') {
      throw Exception("Erreur: '$nom' est un mot-clé réservé du langage.");
    }
    if (!_regValidId.hasMatch(nom)) {
      if (_regStartsWithNum.hasMatch(nom)) {
        throw Exception(
          "Erreur: Le nom '$nom' ne peut pas commencer par un chiffre.",
        );
      }
      if (nom.contains(' ')) {
        throw Exception(
          "Erreur: Le nom '$nom' ne peut pas contenir d'espaces.",
        );
      }
      throw Exception(
        "Erreur: Le nom '$nom' contient des caractères spéciaux non autorisés.",
      );
    }
  }
}
