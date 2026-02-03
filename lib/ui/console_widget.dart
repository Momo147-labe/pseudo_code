import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/debug_provider.dart';
import '../theme.dart';
import '../interpreteur/interpreteur.dart';
import 'dart:async';

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget({super.key});

  @override
  State<ConsoleWidget> createState() => ConsoleWidgetState();
}

class ConsoleWidgetState extends State<ConsoleWidget> {
  final List<String> _messages = ['[Compilateur prêt]'];

  final List<String> _inputHistory = [];
  int _historyIndex = -1;

  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  Completer<String>? _inputCompleter;
  bool _waitingForInput = false;
  double _fontSize = 14.0;
  final ScrollController _scrollController = ScrollController();

  Future<void> runCode(String code) async {
    final sw = Stopwatch()..start();
    final startMessage =
        '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Début de l\'exécution...';

    setState(() {
      _messages.clear();
      _messages.add(startMessage);
      _waitingForInput = false;
    });

    try {
      await Interpreteur.executer(
        code,
        provider: context.read<DebugProvider>(),
        onOutput: (text) {
          if (!mounted) return;
          if (text == '__CLEAR__') {
            setState(() {
              _messages.clear();
              _messages.add(startMessage);
            });
            return;
          }
          setState(() {
            _messages.add(text);
          });
          _scrollToBottom();
        },
        onInput: () {
          final completer = Completer<String>();
          setState(() {
            _inputCompleter = completer;
            _waitingForInput = true;
          });
          // Focus automatique
          Future.delayed(const Duration(milliseconds: 100), () {
            _inputFocusNode.requestFocus();
          });
          return completer.future;
        },
      );

      sw.stop();
      if (!mounted) return;
      setState(() {
        _messages.add(
          '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Fin de l\'exécution (${sw.elapsed.inMilliseconds}ms).',
        );
      });
      _scrollToBottom();
    } catch (e) {
      sw.stop();
      if (!mounted) return;
      setState(() {
        _messages.add('Erreur: $e');
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _waitingForInput = false;
          _inputCompleter = null;
        });
      }
    }
  }

  void clear() {
    setState(() {
      _messages.clear();
      _inputHistory.clear();
      _historyIndex = -1;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void printDirect(String message) {
    setState(() {
      _messages.clear();
      _messages.add(message);
    });
  }

  void _submitInput() {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      _inputHistory.add(text);
      _historyIndex = -1;
    }

    if (_inputCompleter != null && !_inputCompleter!.isCompleted) {
      _inputCompleter!.complete(text);
      setState(() {
        if (_messages.isNotEmpty && _waitingForInput) {
          final last = _messages.removeLast();
          _messages.add('$last $text');
        } else {
          _messages.add('> $text');
        }
        _inputController.clear();
        _waitingForInput = false;
      });
      _scrollToBottom();
    }
  }

  void _handleHistory(bool up) {
    if (_inputHistory.isEmpty) return;

    if (up) {
      if (_historyIndex == -1) {
        _historyIndex = _inputHistory.length - 1;
      } else if (_historyIndex > 0) {
        _historyIndex--;
      }
    } else {
      if (_historyIndex != -1) {
        if (_historyIndex < _inputHistory.length - 1) {
          _historyIndex++;
        } else {
          _historyIndex = -1;
        }
      }
    }

    setState(() {
      if (_historyIndex != -1) {
        _inputController.text = _inputHistory[_historyIndex];
        _inputController.selection = TextSelection.collapsed(
          offset: _inputController.text.length,
        );
      } else {
        _inputController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.editorBg(theme),
        border: Border(
          top: BorderSide(
            color:
                provider.consolePosition == ConsolePosition.bottom &&
                    provider.isConsoleVisible
                ? (isDark ? Colors.white10 : Colors.black12)
                : Colors.transparent,
          ),
          left: BorderSide(
            color:
                provider.consolePosition == ConsolePosition.right &&
                    provider.isConsoleVisible
                ? (isDark ? Colors.white10 : Colors.black12)
                : Colors.transparent,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PanelTab(title: 'CONSOLE', theme: theme, isActive: true),
                  _PanelTab(title: 'SORTIE', theme: theme),
                  _PanelTab(title: 'TERMINAL', theme: theme),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.vertical_align_top,
                      size: 16,
                      color: provider.consolePosition == ConsolePosition.top
                          ? Colors.blueAccent
                          : ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () =>
                        provider.setConsolePosition(ConsolePosition.top),
                    tooltip: "Position: Haut",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.vertical_align_bottom,
                      size: 16,
                      color: provider.consolePosition == ConsolePosition.bottom
                          ? Colors.blueAccent
                          : ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () =>
                        provider.setConsolePosition(ConsolePosition.bottom),
                    tooltip: "Position: Bas",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.align_horizontal_right,
                      size: 16,
                      color: provider.consolePosition == ConsolePosition.right
                          ? Colors.blueAccent
                          : ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () =>
                        provider.setConsolePosition(ConsolePosition.right),
                    tooltip: "Position: Droite",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.zoom_in,
                      size: 16,
                      color: ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(8, 30),
                    ),
                    tooltip: "Zoomer",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.zoom_out,
                      size: 16,
                      color: ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(8, 30),
                    ),
                    tooltip: "Dézoomer",
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: 16,
                      color: ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () {
                      final allContent = _messages.join('\n');
                      Clipboard.setData(ClipboardData(text: allContent));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Console copiée dans le presse-papier"),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    tooltip: "Copier tout",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.clear_all,
                      size: 16,
                      color: ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () {
                      setState(() => _messages.clear());
                      _inputHistory.clear();
                      _historyIndex = -1;
                    },
                    tooltip: "Effacer la console",
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: ThemeColors.textMain(theme).withOpacity(0.5),
                    ),
                    onPressed: () => provider.toggleConsole(),
                    tooltip: "Fermer la console",
                  ),
                ],
              ),
            ),
          ),
          // Output + Inline Input
          Expanded(
            child: SelectionArea(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final m = _messages[index];
                  final isLast = index == _messages.length - 1;
                  final lineNum = index + 1;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line number for console
                      Container(
                        width: 40,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 12, top: 2),
                        child: Text(
                          '$lineNum',
                          style: TextStyle(
                            color: ThemeColors.textMain(theme).withOpacity(0.2),
                            fontSize: _fontSize - 2, // Slightly smaller
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(minHeight: 20),
                          alignment: Alignment.centerLeft,
                          child: _waitingForInput && isLast
                              ? Row(
                                  children: [
                                    Text(
                                      m,
                                      style: TextStyle(
                                        color: ThemeColors.textMain(theme),
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: _fontSize,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: RawKeyboardListener(
                                        focusNode:
                                            FocusNode(), // Dummy node for listener
                                        onKey: (event) {
                                          if (event is RawKeyDownEvent) {
                                            if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowUp) {
                                              _handleHistory(true);
                                            } else if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowDown) {
                                              _handleHistory(false);
                                            }
                                          }
                                        },
                                        child: TextField(
                                          controller: _inputController,
                                          focusNode: _inputFocusNode,
                                          autofocus: true,
                                          cursorColor: Colors.blueAccent,
                                          style: TextStyle(
                                            color: ThemeColors.textBright(
                                              theme,
                                            ),
                                            fontFamily: 'JetBrainsMono',
                                            fontSize: _fontSize,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onSubmitted: (_) => _submitInput(),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  m,
                                  style: TextStyle(
                                    color: _getMessageColor(m, theme),
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: _fontSize,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getMessageColor(String m, AppTheme theme) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    if (m.startsWith('Erreur') || m.contains('Exception'))
      return Colors.redAccent;
    if (m.startsWith('[')) return isDark ? Colors.white38 : Colors.black38;
    if (m.startsWith('>')) return Colors.blueAccent;
    return ThemeColors.textMain(theme);
  }
}

class _PanelTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final AppTheme theme;

  const _PanelTab({
    required this.title,
    this.isActive = false,
    this.theme = AppTheme.dark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        border: isActive
            ? const Border(
                bottom: BorderSide(color: Colors.blueAccent, width: 1),
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: TextStyle(
          color: isActive
              ? ThemeColors.textBright(theme)
              : ThemeColors.textMain(theme).withOpacity(0.5),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
