import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.1-8b-instant';

  // Note: Dans un environnement réel, cette clé devrait être gérée via --dart-define ou un fichier .env
  final String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  // final String apiKey = const String.fromEnvironment('GROQ_API_KEY');

  Future<String> getChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    String userName = "Momo",
    bool isAgentMode = true,
  }) async {
    try {
      String promptContent =
          "Tu es l'AGENT DE CODE de $userName, un expert en algorithmique et modélisation Merise.\n"
          "Tu as le pouvoir de MODIFIER DIRECTEMENT son code et ses diagrammes MCD.\n\n";

      if (contextCode != null) {
        promptContent +=
            "**Règles de Syntaxe Pseudocode STRICTES :**\n"
            "- CASSE : `Algorithme`, `Variables`, `Début`, `Fin`, `Type`, `Structure`, `FinStructure`, `Fonction`, `FinFonction`, `Procédure`, `FinProcédure` commencent par une MAJUSCULE.\n"
            "- CASSE : TOUS les autres mots-clés sont en MINUSCULE (`lire`, `afficher`, `tantque`, `fintantque`, `si`, `alors`, `sinon`, `finsi`, `pour`, `finpour`, `repeter`, `jusqua`, `faire`, `selon`, `cas`, `finselon`, `retourner`).\n"
            "- TERMINAISON : Un programme se termine TOUJOURS par le mot-clé unique `Fin` seul sur sa ligne.\n"
            "- I/O : `lire(variable)` et `afficher(\"message\", variable)`.\n"
            "- DÉCLARATION : `variables nom1, nom2 : Type` ou `type NomDuType = tableau[1..Taille] de TypeBase`.\n"
            "- MODIFICATION : Utilise `[REPLACER_CODE]` pour remplacer tout le code ou `[INSERER_CODE]` pour ajouter un bloc.\n\n";
      }

      if (mcdContext != null) {
        promptContent +=
            "**Instructions Merise / MCD (FORMAT JSON STRICT) :**\n"
            "- Pour modifier le diagramme, utilise `[MODIFIER_MCD]` suivi du JSON COMPLET.\n"
            "- STRUCTURE JSON :\n"
            "  `entities`: `[{ \"id\": \"e1\", \"name\": \"NOM\", \"position\": {\"dx\": 100, \"dy\": 100}, \"attributes\": [{\"name\": \"id\", \"type\": \"ENTIER\", \"isPrimaryKey\": true, \"description\": \"\", \"length\": \"\", \"constraints\": \"\", \"rules\": \"\"}] }]`\n"
            "  `relations`: `[{ \"id\": \"r1\", \"name\": \"NOM\", \"position\": {\"dx\": 200, \"dy\": 200}, \"attributes\": [] }]`\n"
            "  `links`: `[{ \"entityId\": \"e1\", \"relationId\": \"r1\", \"cardinalities\": \"1,n\" }]`\n"
            "  `functionalDependencies`: `[{ \"id\": \"df1\", \"sourceAttributes\": [\"attr1\"], \"targetAttributes\": [\"attr2\"] }]`\n"
            "- Pour réorganiser visuellement un diagramme désordonné, utilise uniquement la balise `[REORGANISER_MCD]`.\n"
            "- Tu DOIS renvoyer TOUT le diagramme (inclus les éléments inchangés).\n"
            "- Espace les objets (dx/dy) de minimum 150 unités pour éviter les superpositions.\n\n";
      }

      promptContent +=
          "**Intelligence Avancée et Qualité :**\n"
          "- MODE REVIEW : Tes modifications de code passent désormais par une étape de revue. L'utilisateur pourra accepter ou rejeter tes changements.\n"
          "- LINTER : Si des avertissements de linter sont présents (ex: variables inutilisées), ils te seront communiqués à côté du nom de l'utilisateur. Corrige-les si possible.\n"
          "- AUTO-CORRECTION : Si tu envoies un code avec une erreur de structure, l'application te renverra l'erreur pour correction immédiate.\n"
          "- MÉMOIRE : Utilise la balise `[RESUMER_ETAT]` seule si tu penses que la conversation devient trop longue et nécessite un résumé technique pour économiser de la mémoire.\n\n"
          "Sois direct, technique et n'ajoute pas de texte superflu en mode Agent.\n";

      if (contextCode != null) {
        promptContent += "\nCODE ACTUEL :\n```\n$contextCode\n```";
      }
      if (mcdContext != null) {
        promptContent += "\nMCD ACTUEL (JSON) :\n```json\n$mcdContext\n```";
      }

      final List<Map<String, String>> finalMessages = [
        {
          "role": "system",
          "content": isAgentMode
              ? promptContent
              : "Tu es un assistant IA pédagogique pour $userName. "
                    "Ne propose pas de modification automatique sauf si c'est explicitement demandé. "
                    "${contextCode != null ? "\nCODE ACTUEL :\n```\n$contextCode\n```" : ""}"
                    "${mcdContext != null ? "\nMCD ACTUEL (JSON) :\n```json\n$mcdContext\n```" : ""}",
        },
        ...messages,
      ];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": _model,
          "messages": finalMessages,
          "temperature": isAgentMode ? 0.1 : 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception(
          "Erreur Groq (${response.statusCode}): ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Erreur de connexion à l'Assistant IA : $e");
    }
  }
}
