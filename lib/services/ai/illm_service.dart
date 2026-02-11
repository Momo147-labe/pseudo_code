import 'dart:async';

/// Interface abstraite pour les services de LLM (Large Language Model)
/// Permet de supporter plusieurs fournisseurs (Groq, OpenAI, Ollama, etc.)
abstract class ILlmService {
  /// Envoie une requête de complétion et attend la réponse complète.
  Future<String> getChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    bool isAgentMode = true,
    String userName = "Momo",
  });

  /// Envoie une requête de complétion et retourne un Stream de fragments de texte.
  Stream<String> streamChatCompletion(
    List<Map<String, String>> messages, {
    String? contextCode,
    String? mcdContext,
    bool isAgentMode = true,
    String userName = "Momo",
  });

  /// Retourne les informations sur le modèle
  Map<String, dynamic> getModelInfo();

  /// Estime le nombre de tokens pour un texte donné
  int estimateTokens(String text);
}
