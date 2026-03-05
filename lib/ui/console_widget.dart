import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/debug_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import '../interpreteur/isolated_interpreter.dart';
import 'dart:async';
import 'dart:isolate';

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget({super.key});

  @override
  State<ConsoleWidget> createState() => ConsoleWidgetState();
}

class ConsoleWidgetState extends State<ConsoleWidget> {
  List<String> _messages = ['[Compilateur prêt]'];

  final List<String> _inputHistory = [];
  int _historyIndex = -1;

  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  Completer<String>? _inputCompleter;
  bool _waitingForInput = false;
  double _fontSize = 14.0;
  final ScrollController _scrollController = ScrollController();
  Isolate? _interpreterIsolate;
  SendPort? _interpreterSendPort;
  ReceivePort? _receivePort;
  StreamSubscription? _controlSub;

  String _activeTab = 'CONSOLE';
  List<dynamic> _guideData = [];
  bool _isConsoleSearchVisible = false;
  final TextEditingController _consoleSearchController =
      TextEditingController();
  String _consoleSearchQuery = '';
  String _logFilter = 'all'; // all, output, system

  @override
  void initState() {
    super.initState();
    _loadGuideData();
  }

  Future<void> _loadGuideData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/guide.json');
      setState(() {
        _guideData = json.decode(jsonString);
      });
    } catch (e) {
      debugPrint("Erreur chargement guide: $e");
    }
  }

  Future<void> runCode(String code) async {
    if (_interpreterIsolate != null) {
      _interpreterIsolate!.kill(priority: Isolate.immediate);
      _interpreterIsolate = null;
    }

    final sw = Stopwatch()..start();
    final startMessage =
        '[${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}] Début de l\'exécution...';

    setState(() {
      _messages.clear();
      _messages.add(startMessage);
      _waitingForInput = false;
      _activeTab = 'CONSOLE';
    });

    final debugProvider = context.read<DebugProvider>();
    debugProvider.setErrorLine(null);
    debugProvider.setHighlightLine(null);
    debugProvider.updateDebugVariables({});

    _receivePort = ReceivePort();

    try {
      _interpreterIsolate = await Isolate.spawn(
        IsolatedInterpreter.entryPoint,
        _receivePort!.sendPort,
      );

      final stream = _receivePort!.asBroadcastStream();

      // First message from isolate is its SendPort
      _interpreterSendPort = await stream.first as SendPort;

      // Start execution
      _interpreterSendPort!.send(RunRequest(code, debugProvider.breakpoints));

      // Listen to control actions from UI (Step, Continue, Stop)
      _controlSub = debugProvider.controlActionStream.listen((action) {
        _interpreterSendPort?.send(ControlMessage(action));
      });

      await for (final message in stream) {
        if (message is OutputEvent) {
          if (!mounted) break;
          if (message.text == '__CLEAR__') {
            setState(() {
              _messages.clear();
              _messages.add(startMessage);
            });
          } else {
            setState(() {
              _messages.add(message.text);
            });
            _scrollToBottom();
          }
        } else if (message is InputRequestEvent) {
          final completer = Completer<String>();
          setState(() {
            _inputCompleter = completer;
            _waitingForInput = true;
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            _inputFocusNode.requestFocus();
          });
          final input = await completer.future;
          _interpreterSendPort!.send(InputResponse(input));
        } else if (message is DebugEvent) {
          if (message.highlightLine != null) {
            debugProvider.setHighlightLine(message.highlightLine);
          }
          if (message.errorLine != null) {
            debugProvider.setErrorLine(message.errorLine);
          }
          if (message.variables.isNotEmpty) {
            debugProvider.updateDebugVariables(message.variables);
          }
          debugProvider.setPaused(message.isPaused);
        } else if (message is FinishedEvent) {
          break;
        }
      }

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
      _stopInterpreter();
    }
  }

  void _stopInterpreter() {
    if (mounted) {
      final debugProvider = context.read<DebugProvider>();
      debugProvider.setHighlightLine(null);
    }
    _controlSub?.cancel();
    _controlSub = null;
    _interpreterIsolate?.kill(priority: Isolate.immediate);
    _interpreterIsolate = null;
    _interpreterSendPort = null;
    _receivePort?.close();
    _receivePort = null;
    if (mounted) {
      setState(() {
        _waitingForInput = false;
        _inputCompleter = null;
      });
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

  Future<void> _exportLogs() async {
    try {
      final content = _messages.join('\n');
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File(p.join(directory.path, "log_console_$timestamp.txt"));
      await file.writeAsString(content);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Log exporté : ${file.path}"),
            backgroundColor: Colors.blueAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur d'exportation : $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _submitInput() {
    final text = _inputController.text;
    if (text.isNotEmpty) {
      _inputHistory.add(text);
      _historyIndex = -1;
    }

    // Gestion du Terminal / Guide
    if (_activeTab == 'TERMINAL') {
      setState(() {
        if (_messages.isNotEmpty && _messages.last == '> ') {
          _messages.removeLast(); // Retirer le prompt actif
        }
        _messages.add('> $text'); // Ajouter l'historique
        _inputController.clear();
      });
      _processTerminalCommand(text);
      _scrollToBottom();
      return;
    }

    // Gestion standard (Console / Input program)
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

  Future<void> _processTerminalCommand(String input) async {
    final args = input.trim().split(' ');
    final cleanInput = input.trim().toLowerCase();

    if (cleanInput == 'clear' ||
        cleanInput == 'cls' ||
        cleanInput == 'effacer') {
      setState(() {
        _messages = ['> ']; // Reset avec prompt
      });
      _scrollToBottom();
      return;
    }

    // Tentative de chargement si vide
    if (_guideData.isEmpty) {
      await _loadGuideData();
      if (_guideData.isEmpty) {
        _bufferTerminal("Erreur : Impossible de charger les données du guide.");
        _flushTerminal();
        return;
      }
    }

    if (cleanInput == 'guide' || cleanInput == 'aide') {
      _bufferTerminal("=== GUIDE ALGORITHMIQUE ===");
      _bufferTerminal("Sujets disponibles :");
      final sujets = _guideData.map((e) => "- ${e['commande']}").join('\n');
      _bufferTerminal(sujets);
      _bufferTerminal(
        "\nTapez le nom d'un sujet pour voir les détails (ex: 'variable')",
      );
      _flushTerminal();
      return;
    }

    String query = cleanInput;
    if (args.isNotEmpty &&
        (args[0].toLowerCase() == 'guide' || args[0].toLowerCase() == 'aide')) {
      if (args.length > 1) {
        query = args.sublist(1).join(' ').toLowerCase();
      } else {
        _flushTerminal();
        return;
      }
    }

    final match = _guideData.firstWhere(
      (e) =>
          e['commande'].toString().toLowerCase() == query ||
          e['commande'].toString().toLowerCase().contains(query),
      orElse: () => null,
    );

    if (match != null) {
      _afficherDetailsGuide(match);
    } else {
      _bufferTerminal(
        "Commande ou sujet inconnu : '$input'.\nTapez 'guide' pour voir la liste des sujets.",
      );
    }
    _flushTerminal();
  }

  void _afficherDetailsGuide(dynamic entry) {
    _bufferTerminal(
      "» ${entry['commande'].toString().toUpperCase()} «",
      system: true,
    );
    _bufferTerminal("————————————————————————————————————————", system: true);
    _bufferTerminal("• DESCR : ${entry['contenu']}", system: true);

    if (entry['caracteristique'] != null) {
      _bufferTerminal("\n• CARACTÉRISTIQUES :", system: true);
      for (var c in entry['caracteristique']) {
        _bufferTerminal("  - $c", system: true);
      }
    }

    if (entry['exemple'] != null) {
      _bufferTerminal("\n• EXEMPLE :", system: true);
      if (entry['exemple']['probleme'] != null) {
        _bufferTerminal(
          "  Problème : ${entry['exemple']['probleme']}",
          system: true,
        );
      }
      if (entry['exemple']['etapes'] != null) {
        _bufferTerminal("  Étapes :", system: true);
        for (var etape in entry['exemple']['etapes']) {
          _bufferTerminal("    $etape", system: true);
        }
      }
    }
    _bufferTerminal("————————————————————————————————————————", system: true);
  }

  // Helpers pour accumuler les messages
  void _bufferTerminal(String text, {bool system = false}) {
    if (_messages.isNotEmpty && _messages.last == '> ') {
      _messages.removeLast();
    }
    _messages.add(
      system && !text.startsWith('[') && !text.startsWith('>')
          ? "[SYST] $text"
          : text,
    );
  }

  void _flushTerminal() {
    setState(() {
      _messages.add('> '); // Nouveau prompt
    });
    _scrollToBottom();
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
    final fileProvider = context
        .watch<FileProvider>(); // Listen to file changes for badge
    final theme = themeProvider.currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    final anomaliesCount = fileProvider.anomalies.length;

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme).withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
          ),
          left: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 0.5,
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
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PanelTab(
                          title: 'CONSOLE',
                          theme: theme,
                          isActive: _activeTab == 'CONSOLE',
                          onTap: () => setState(() => _activeTab = 'CONSOLE'),
                        ),
                        _PanelTab(
                          title: 'AVERTISSEMENTS',
                          theme: theme,
                          isActive: _activeTab == 'WARNINGS',
                          onTap: () => setState(() => _activeTab = 'WARNINGS'),
                          badgeCount: anomaliesCount,
                        ),
                        _PanelTab(
                          title: 'GUIDE',
                          theme: theme,
                          isActive: _activeTab == 'TERMINAL',
                          onTap: () => setState(() => _activeTab = 'TERMINAL'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.vertical_align_top,
                            size: 16,
                            color:
                                provider.consolePosition == ConsolePosition.top
                                ? Colors.blueAccent
                                : ThemeColors.textMain(
                                    theme,
                                  ).withValues(alpha: 0.5),
                          ),
                          onPressed: () =>
                              provider.setConsolePosition(ConsolePosition.top),
                          tooltip: "Position: Haut",
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.vertical_align_bottom,
                            size: 16,
                            color:
                                provider.consolePosition ==
                                    ConsolePosition.bottom
                                ? Colors.blueAccent
                                : ThemeColors.textMain(
                                    theme,
                                  ).withValues(alpha: 0.5),
                          ),
                          onPressed: () => provider.setConsolePosition(
                            ConsolePosition.bottom,
                          ),
                          tooltip: "Position: Bas",
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.align_horizontal_right,
                            size: 16,
                            color:
                                provider.consolePosition ==
                                    ConsolePosition.right
                                ? Colors.blueAccent
                                : ThemeColors.textMain(
                                    theme,
                                  ).withValues(alpha: 0.5),
                          ),
                          onPressed: () => provider.setConsolePosition(
                            ConsolePosition.right,
                          ),
                          tooltip: "Position: Droite",
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.zoom_in,
                            size: 16,
                            color: ThemeColors.textMain(
                              theme,
                            ).withValues(alpha: 0.5),
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
                            color: ThemeColors.textMain(
                              theme,
                            ).withValues(alpha: 0.5),
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
                            color: ThemeColors.textMain(
                              theme,
                            ).withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            if (_activeTab == 'WARNINGS') {
                              // Copier les avertissements
                              final fileProvider = context.read<FileProvider>();
                              final text = fileProvider.anomalies
                                  .map((a) => "Ligne ${a.line}: ${a.message}")
                                  .join('\n');
                              Clipboard.setData(ClipboardData(text: text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Avertissements copiés dans le presse-papier",
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            } else {
                              // Copier la console/guide
                              final allContent = _messages.join('\n');
                              Clipboard.setData(
                                ClipboardData(text: allContent),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Contenu copié dans le presse-papier",
                                  ),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          tooltip: "Copier tout",
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.clear_all,
                            size: 16,
                            color: ThemeColors.textMain(
                              theme,
                            ).withValues(alpha: 0.5),
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
                            Icons.search,
                            size: 16,
                            color: _isConsoleSearchVisible
                                ? Colors.blueAccent
                                : ThemeColors.textMain(
                                    theme,
                                  ).withValues(alpha: 0.5),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConsoleSearchVisible =
                                  !_isConsoleSearchVisible;
                              if (!_isConsoleSearchVisible) {
                                _consoleSearchQuery = '';
                                _consoleSearchController.clear();
                              }
                            });
                          },
                          tooltip: "Rechercher dans la console",
                        ),
                        const VerticalDivider(
                          width: 1,
                          indent: 8,
                          endIndent: 8,
                        ),
                        // Filtres
                        if (_activeTab == 'CONSOLE') ...[
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: "Tout",
                            isActive: _logFilter == 'all',
                            onTap: () => setState(() => _logFilter = 'all'),
                            theme: theme,
                          ),
                          _FilterChip(
                            label: "Sortie",
                            isActive: _logFilter == 'output',
                            onTap: () => setState(() => _logFilter = 'output'),
                            theme: theme,
                          ),
                          _FilterChip(
                            label: "Syst",
                            isActive: _logFilter == 'system',
                            onTap: () => setState(() => _logFilter = 'system'),
                            theme: theme,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Actions fixes
                IconButton(
                  icon: Icon(
                    Icons.file_download_outlined,
                    size: 16,
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                  ),
                  onPressed: _exportLogs,
                  tooltip: "Exporter le log (.txt)",
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 16,
                    color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                  ),
                  onPressed: () => provider.toggleConsole(),
                  tooltip: "Fermer la console",
                ),
              ],
            ),
          ),
          // Barre de recherche (si visible)
          if (_isConsoleSearchVisible)
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 14,
                    color: Colors.blueAccent.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _consoleSearchController,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.textMain(theme),
                      ),
                      decoration: const InputDecoration(
                        hintText: "Rechercher...",
                        hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _consoleSearchQuery = value.trim().toLowerCase();
                        });
                      },
                    ),
                  ),
                  if (_consoleSearchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () {
                        setState(() {
                          _consoleSearchController.clear();
                          _consoleSearchQuery = '';
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          // Output + Inline Input
          Expanded(
            child: _activeTab == 'WARNINGS'
                ? SelectionArea(child: _buildWarningsView(context, theme))
                : SelectionArea(
                    child: Builder(
                      builder: (context) {
                        final filteredMessages = _messages.where((m) {
                          // Filter by search query
                          if (_consoleSearchQuery.isNotEmpty &&
                              !m.toLowerCase().contains(_consoleSearchQuery)) {
                            return false;
                          }
                          // Filter by category
                          final isSystem =
                              m.startsWith('[') || m.startsWith('>');
                          if (_logFilter == 'output' && isSystem) return false;
                          if (_logFilter == 'system' && !isSystem) return false;
                          return true;
                        }).toList();

                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount: filteredMessages.length,
                          itemBuilder: (context, index) {
                            final m = filteredMessages[index];
                            final isLastOriginal =
                                _messages.isNotEmpty && m == _messages.last;
                            final lineNum = _messages.indexOf(m) + 1;

                            // Allow input if waiting for input OR if we are in Terminal/Guide mode (and it's the last line of ALL messages)
                            final canInput =
                                isLastOriginal &&
                                (_waitingForInput || _activeTab == 'TERMINAL');

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Line number for console
                                Container(
                                  width: 40,
                                  alignment: Alignment.topRight,
                                  padding: const EdgeInsets.only(
                                    right: 12,
                                    top: 2,
                                  ),
                                  child: Text(
                                    '$lineNum',
                                    style: TextStyle(
                                      color: ThemeColors.textMain(
                                        theme,
                                      ).withValues(alpha: 0.2),
                                      fontSize:
                                          _fontSize - 2, // Slightly smaller
                                      fontFamily: 'JetBrainsMono',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 20,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: canInput
                                        ? Row(
                                            children: [
                                              Text(
                                                m,
                                                style: TextStyle(
                                                  color: ThemeColors.textMain(
                                                    theme,
                                                  ),
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
                                                    if (event
                                                        is RawKeyDownEvent) {
                                                      if (event.logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowUp) {
                                                        _handleHistory(true);
                                                      } else if (event
                                                              .logicalKey ==
                                                          LogicalKeyboardKey
                                                              .arrowDown) {
                                                        _handleHistory(false);
                                                      }
                                                    }
                                                  },
                                                  child: TextField(
                                                    controller:
                                                        _inputController,
                                                    focusNode: _inputFocusNode,
                                                    autofocus: true,
                                                    cursorColor:
                                                        Colors.blueAccent,
                                                    style: TextStyle(
                                                      color:
                                                          ThemeColors.textBright(
                                                            theme,
                                                          ),
                                                      fontFamily:
                                                          'JetBrainsMono',
                                                      fontSize: _fontSize,
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                        ),
                                                    onSubmitted: (_) =>
                                                        _submitInput(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : _buildStyledMessage(
                                            m,
                                            theme,
                                            _fontSize,
                                          ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningsView(BuildContext context, AppTheme theme) {
    // Access FileProvider safely
    final fileProvider = context
        .read<
          FileProvider
        >(); // Use read here as we have already watched in build
    final anomalies = fileProvider.anomalies;

    if (anomalies.isEmpty) {
      return Center(
        child: Text(
          "Aucun avertissement.",
          style: TextStyle(
            color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
            fontFamily: 'JetBrainsMono',
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: anomalies.length,
      itemBuilder: (context, index) {
        final issue = anomalies[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 20,
          ),
          title: Text(
            issue.message,
            style: TextStyle(
              color: ThemeColors.textBright(theme),
              fontFamily: 'JetBrainsMono',
              fontSize: _fontSize - 1,
            ),
          ),
          subtitle: Text(
            "Ligne ${issue.line}",
            style: TextStyle(
              color: ThemeColors.textMain(theme).withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 16,
            color: Colors.white12,
          ),
          onTap: () {
            context.read<FileProvider>().jumpToLine(issue.line);
          },
        );
      },
    );
  }

  Color _getMessageColor(String m, AppTheme theme) {
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;
    if (m.startsWith('Erreur') || m.contains('Exception')) {
      return Colors.redAccent;
    }
    if (m.startsWith('[')) return isDark ? Colors.white38 : Colors.black38;
    if (m.startsWith('>')) return Colors.blueAccent;
    return ThemeColors.textMain(theme);
  }

  Widget _buildStyledMessage(String m, AppTheme theme, double fontSize) {
    final Color baseColor = _getMessageColor(m, theme);
    final TextStyle baseStyle = TextStyle(
      color: baseColor,
      fontFamily: 'JetBrainsMono',
      fontSize: fontSize,
    );

    // Expression régulière pour les nombres (entiers et décimaux)
    final RegExp numberRegex = RegExp(r'\b\d+(\.\d+)?\b');
    final List<TextSpan> spans = [];
    int lastIndex = 0;

    for (final match in numberRegex.allMatches(m)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: m.substring(lastIndex, match.start)));
      }

      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: ThemeColors.syntaxNumber(theme),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < m.length) {
      spans.add(TextSpan(text: m.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: spans.isEmpty ? [TextSpan(text: m)] : spans,
      ),
    );
  }
}

class _PanelTab extends StatelessWidget {
  final String title;
  final bool isActive;
  final AppTheme theme;
  final VoidCallback? onTap;
  final int badgeCount;

  const _PanelTab({
    required this.title,
    this.isActive = false,
    this.theme = AppTheme.dark,
    this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          border: isActive
              ? Border(
                  bottom: BorderSide(
                    color: Colors.blueAccent.withValues(alpha: 0.8),
                    width: 2,
                  ),
                )
              : null,
          color: isActive
              ? Colors.blueAccent.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTabIcon(title),
              size: 13,
              color: isActive
                  ? Colors.blueAccent
                  : ThemeColors.textMain(theme).withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive
                    ? ThemeColors.textBright(theme)
                    : ThemeColors.textMain(theme).withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 0.5,
              ),
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16),
                alignment: Alignment.center,
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTabIcon(String title) {
    switch (title.toUpperCase()) {
      case 'CONSOLE':
        return Icons.terminal_rounded;
      case 'TERMINAL':
        return Icons.keyboard_command_key_rounded;
      case 'WARNINGS':
      case 'AVERTISSEMENTS':
        return Icons.warning_amber_rounded;
      default:
        return Icons.tab_rounded;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AppTheme theme;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.blueAccent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? Colors.blueAccent.withValues(alpha: 0.5)
                : ThemeColors.textMain(theme).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? Colors.blueAccent
                : ThemeColors.textMain(theme).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
