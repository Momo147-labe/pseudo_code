import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/merise_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ai_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State local supprimé car déplacé dans AiProvider

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
                "ASSISTANT IA (GROQ)",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: ThemeColors.textMain(theme).withOpacity(0.5),
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
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
                            ? Colors.blueAccent.withOpacity(0.2)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withOpacity(0.05)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isUser
                              ? Colors.blueAccent.withOpacity(0.3)
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
                          Align(
                            alignment: Alignment.bottomRight,
                            child: InkWell(
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
                                  ).withOpacity(0.3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUser ? "Vous" : "IA (Llama 3.1)",
                      style: TextStyle(
                        fontSize: 10,
                        color: ThemeColors.textMain(theme).withOpacity(0.4),
                      ),
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
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _controller,
            onSubmitted: (_) => _sendMessage(
              aiProvider,
              fileProvider,
              meriseProvider,
              appProvider,
            ),
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
                color: ThemeColors.textMain(theme).withOpacity(0.4),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white10
                  : Colors.black.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              suffixIcon: IconButton(
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
              side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
