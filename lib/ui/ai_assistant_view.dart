import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/merise_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import '../../services/ai/voice_service.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _voiceService.init().then((avail) {
      if (mounted && avail) {
        setState(() {}); // Update UI if voice available
      }
    });
  }

  void _sendMessage(
    AiProvider aiProvider,
    FileProvider fileProvider,
    MeriseProvider meriseProvider,
    AppProvider appProvider,
  ) {
    if (_controller.text.trim().isEmpty) return;

    final message = _controller.text.trim();
    _controller.clear();

    // On filtre le contexte selon la vue principale active
    final bool isMerise = appProvider.activeMainView == ActiveMainView.merise;

    final contextCode = !isMerise ? fileProvider.activeFile?.content : null;
    final mcdContext = isMerise ? meriseProvider.serialize() : null;

    aiProvider.sendMessage(
      message,
      contextCode,
      currentLints: fileProvider.anomalies.map((a) => a.message).toList(),
      mcdContext: mcdContext,
      isAgentMode: aiProvider.isAgentMode,
      onCodeUpdate: (newCode) => fileProvider.proposeCodeChange(newCode),
      onCodeInsert: (snippet) => fileProvider.insertText(snippet),
      onMeriseUpdate: (mcdJson) =>
          meriseProvider.deserialize(mcdJson, clearHistory: false),
    );

    _scrollToBottom();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _voiceService.startListening(
        onResult: (text) {
          if (mounted) {
            _controller.text = text;
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      // On vérifie si le provider est disponible
      Provider.of<AiProvider>(context, listen: false);
      return _buildContent(context);
    } catch (e) {
      // Si non trouvé, on l'injecte localement (fix pour les problèmes de contexte/hot-reload)
      return ChangeNotifierProvider(
        create: (_) => AiProvider(),
        child: Builder(builder: (context) => _buildContent(context)),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final aiProvider = context.watch<AiProvider>();
    final fileProvider = context.read<FileProvider>();
    final meriseProvider = context.read<MeriseProvider>();
    final appProvider = context.watch<AppProvider>();
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    // Scroll automatique quand un nouveau message arrive
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Récupérer le padding du clavier
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "ASSISTANT IA",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 18),
                onPressed: () {
                  // TODO: Ouvrir les settings AI
                },
                tooltip: "Paramètres IA",
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                onPressed: () => aiProvider.clearHistory(),
                tooltip: "Effacer l'historique",
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: aiProvider.messages.length,
            itemBuilder: (context, index) {
              final msg = aiProvider.messages[index];
              final isUser = msg['role'] == 'user';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.blueAccent.withValues(alpha: 0.2)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.05)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUser
                              ? Colors.blueAccent.withValues(alpha: 0.3)
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            msg['content']!,
                            style: TextStyle(
                              color: ThemeColors.textMain(theme),
                              fontSize: 13,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Boutons feedback pour les réponses IA
                              if (!isUser && index > 0) ...[
                                InkWell(
                                  onTap: () => aiProvider.recordFeedback(true),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      right: 8,
                                    ),
                                    child: Icon(
                                      Icons.thumb_up_outlined,
                                      size: 14,
                                      color: ThemeColors.textMain(
                                        theme,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => aiProvider.recordFeedback(false),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      right: 8,
                                    ),
                                    child: Icon(
                                      Icons.thumb_down_outlined,
                                      size: 14,
                                      color: ThemeColors.textMain(
                                        theme,
                                      ).withValues(alpha: 0.3),
                                    ),
                                  ),
                                ),
                              ],
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(
                                    ClipboardData(text: msg['content']!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Copié dans le presse-papiers",
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: ThemeColors.textMain(
                                      theme,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isUser ? "Vous" : "IA",
                          style: TextStyle(
                            fontSize: 10,
                            color: ThemeColors.textMain(
                              theme,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        // Afficher tokens et coût pour la dernière réponse IA
                        if (!isUser &&
                            index == aiProvider.messages.length - 1 &&
                            aiProvider.lastTokensUsed > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            "${aiProvider.lastTokensUsed} tokens • \$${aiProvider.lastCost.toStringAsFixed(4)}",
                            style: TextStyle(
                              fontSize: 9,
                              color: ThemeColors.textMain(
                                theme,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (aiProvider.isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
        _buildQuickSuggestions(
          theme,
          aiProvider,
          fileProvider,
          meriseProvider,
          appProvider,
        ),
        // Afficher le rate limit si proche de la limite
        if (aiProvider.rateLimiter.getRemainingRequests() <= 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: Text(
              "⚠️ ${aiProvider.rateLimiter.getRemainingRequests()} requêtes restantes",
              style: TextStyle(fontSize: 10, color: Colors.orange),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Icon(
                aiProvider.isAgentMode
                    ? Icons.support_agent
                    : Icons.chat_bubble_outline,
                size: 14,
                color: aiProvider.isAgentMode ? Colors.blueAccent : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                aiProvider.isAgentMode ? "Mode Agent" : "Demande Simple",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: aiProvider.isAgentMode
                      ? Colors.blueAccent
                      : Colors.grey,
                ),
              ),
              const Spacer(),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: aiProvider.isAgentMode,
                  onChanged: (val) => aiProvider.setAgentMode(val),
                  activeColor: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),
        // FIX MOBILE: Ajouter padding dynamique pour le clavier
        Padding(
          padding: EdgeInsets.only(
            left: 12.0,
            right: 12.0,
            bottom: 12.0 + keyboardPadding,
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.multiline,
            maxLines: 5,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            onSubmitted: (_) {
              // Sur mobile ou avec multiline, onSubmitted n'est pas toujours appelé comme on veut avec Enter
              // On garde le bouton d'envoi pour le mobile
            },
            enabled: !aiProvider.isLoading,
            style: TextStyle(
              color: ThemeColors.textBright(theme),
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: aiProvider.isLoading
                  ? "L'IA réfléchit..."
                  : "Poser une question...",
              hintStyle: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.4),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      size: 20,
                      color: _isListening
                          ? Colors.redAccent
                          : ThemeColors.textMain(theme).withValues(alpha: 0.5),
                    ),
                    onPressed: _toggleListening,
                    tooltip: "Dicter",
                  ),
                  IconButton(
                    icon: Icon(
                      aiProvider.isLoading ? Icons.hourglass_empty : Icons.send,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                    onPressed: aiProvider.isLoading
                        ? null
                        : () => _sendMessage(
                            aiProvider,
                            fileProvider,
                            meriseProvider,
                            appProvider,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSuggestions(
    AppTheme theme,
    AiProvider aiProvider,
    FileProvider fileProvider,
    MeriseProvider meriseProvider,
    AppProvider appProvider,
  ) {
    if (aiProvider.isLoading) return const SizedBox();

    final suggestions = [
      "Expliquer mon code",
      "Trouver une erreur",
      "Optimiser",
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: suggestions.map((s) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                final bool isMerise =
                    appProvider.activeMainView == ActiveMainView.merise;
                aiProvider.sendMessage(
                  s,
                  !isMerise ? fileProvider.activeFile?.content : null,
                  currentLints: !isMerise
                      ? fileProvider.anomalies.map((a) => a.message).toList()
                      : null,
                  mcdContext: isMerise ? meriseProvider.serialize() : null,
                  isAgentMode: aiProvider.isAgentMode,
                  onCodeUpdate: (newCode) =>
                      fileProvider.proposeCodeChange(newCode),
                  onCodeInsert: (snippet) => fileProvider.insertText(snippet),
                  onMeriseUpdate: (mcdJson) =>
                      meriseProvider.deserialize(mcdJson, clearHistory: false),
                );
                _scrollToBottom();
              },
              backgroundColor: Colors.transparent,
              side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
