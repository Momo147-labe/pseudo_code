import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';

class MobileDebugScreen extends StatefulWidget {
  final String code;
  final String filename;

  const MobileDebugScreen({
    super.key,
    required this.code,
    required this.filename,
  });

  @override
  State<MobileDebugScreen> createState() => _MobileDebugScreenState();
}

class _MobileDebugScreenState extends State<MobileDebugScreen> {
  final ScrollController _codeScrollController = ScrollController();
  final ScrollController _consoleScrollController = ScrollController();

  int currentLine = 0;
  Map<String, dynamic> variables = {};
  List<String> consoleOutput = [];
  bool isPaused = true;
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    // Initialiser avec quelques données de test
    consoleOutput.add('> Debug démarré');
    _scrollToCurrentLine();
  }

  @override
  void dispose() {
    _codeScrollController.dispose();
    _consoleScrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_codeScrollController.hasClients) {
        final lineHeight = 28.0;
        final targetOffset = currentLine * lineHeight;
        final screenHeight = MediaQuery.of(context).size.height * 0.4;

        _codeScrollController.animateTo(
          (targetOffset - screenHeight / 2).clamp(
            0.0,
            _codeScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _onNextStep() async {
    final lines = widget.code.split('\n');
    if (currentLine >= lines.length - 1) return;

    final currentLineText = lines[currentLine].trim();

    // Vérifier si c'est une instruction Lire
    if (currentLineText.toLowerCase().contains('lire(')) {
      // Extraire le nom de la variable
      final match = RegExp(
        r'lire\s*\(\s*([^)]+)\s*\)',
        caseSensitive: false,
      ).firstMatch(currentLineText);

      if (match != null) {
        final varName = match.group(1)?.trim() ?? 'valeur';

        // Afficher dialog pour saisie
        final value = await _showInputDialog(varName);

        if (value != null) {
          setState(() {
            variables[varName] = value;
            consoleOutput.add('> Lire($varName)');
            consoleOutput.add('→ $value');
            currentLine++;
            _scrollToCurrentLine();
            _scrollConsoleToBottom();
          });
        }
        return;
      }
    }

    // Exécution normale
    setState(() {
      currentLine++;
      consoleOutput.add('> Ligne ${currentLine + 1}: $currentLineText');
      _scrollToCurrentLine();
      _scrollConsoleToBottom();

      // Simuler changement de variable
      if (currentLine % 3 == 0) {
        variables['x'] = currentLine * 2;
        variables['total'] = currentLine * 5;
      }
    });
  }

  Future<String?> _showInputDialog(String varName) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = context.read<ThemeProvider>().currentTheme;

        return AlertDialog(
          backgroundColor: ThemeColors.sidebarBg(theme),
          title: Row(
            children: [
              Icon(Icons.input, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lire($varName)',
                style: TextStyle(
                  color: ThemeColors.textBright(theme),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: ThemeColors.textBright(theme),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Entrez la valeur...',
              hintStyle: TextStyle(
                color: ThemeColors.textMain(theme).withOpacity(0.5),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: ThemeColors.textMain(theme)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _onPrevStep() {
    setState(() {
      if (currentLine > 0) {
        currentLine--;
        consoleOutput.add('← Retour ligne ${currentLine + 1}');
        _scrollToCurrentLine();
        _scrollConsoleToBottom();
      }
    });
  }

  void _scrollConsoleToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consoleScrollController.hasClients) {
        _consoleScrollController.animateTo(
          _consoleScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onStop() {
    Navigator.pop(context);
  }

  void _onRun() {
    setState(() {
      isRunning = !isRunning;
      isPaused = !isRunning;
    });

    if (isRunning) {
      consoleOutput.add('▶ Exécution...');
    } else {
      consoleOutput.add('⏸ Pause');
    }
    _scrollConsoleToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

    return Scaffold(
      backgroundColor: ThemeColors.editorBg(theme),
      appBar: _buildAppBar(theme, isDark),
      body: Column(
        children: [
          _buildCodeViewer(theme, isDark),
          _buildVariablesHeader(theme, isDark),
          Expanded(child: _buildConsoleOutput(theme, isDark)),
          _buildControlsBar(theme, isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(AppTheme theme, bool isDark) {
    return AppBar(
      backgroundColor: ThemeColors.topbarBg(theme),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: ThemeColors.textMain(theme)),
        onPressed: _onStop,
        tooltip: 'Retour',
      ),
      title: Row(
        children: [
          Icon(Icons.bug_report, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Debug - ${widget.filename}',
              style: TextStyle(
                color: ThemeColors.textMain(theme),
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.stop, color: Colors.redAccent, size: 20),
          onPressed: _onStop,
          tooltip: 'Stop',
        ),
        IconButton(
          icon: Icon(
            isRunning ? Icons.pause : Icons.play_arrow,
            color: Colors.greenAccent,
            size: 20,
          ),
          onPressed: _onRun,
          tooltip: isRunning ? 'Pause' : 'Run',
        ),
      ],
    );
  }

  Widget _buildCodeViewer(AppTheme theme, bool isDark) {
    final lines = widget.code.split('\n');

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: ThemeColors.editorBg(theme),
        border: Border(
          bottom: BorderSide(
            color: ThemeColors.textMain(theme).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        controller: _codeScrollController,
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final isCurrentLine = index == currentLine;

          return Container(
            color: isCurrentLine
                ? (isDark
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.yellow.withOpacity(0.3))
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line number
                SizedBox(
                  width: 40,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: ThemeColors.textMain(theme).withOpacity(0.5),
                      fontSize: 12,
                      fontFamily: 'JetBrainsMono',
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12),
                // Current line indicator
                SizedBox(
                  width: 20,
                  child: isCurrentLine
                      ? Icon(
                          Icons.arrow_right,
                          color: Colors.blueAccent,
                          size: 20,
                        )
                      : null,
                ),
                // Code line
                Expanded(
                  child: Text(
                    lines[index],
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: ThemeColors.textBright(theme),
                      fontSize: 14,
                      fontWeight: isCurrentLine
                          ? FontWeight.bold
                          : FontWeight.normal,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVariablesHeader(AppTheme theme, bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          bottom: BorderSide(
            color: ThemeColors.textMain(theme).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.data_object, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text(
            'Variables:',
            style: TextStyle(
              color: ThemeColors.textMain(theme),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                variables.isEmpty
                    ? 'Aucune variable'
                    : variables.entries
                          .map((e) => '${e.key}=${e.value}')
                          .join(', '),
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsoleOutput(AppTheme theme, bool isDark) {
    return Container(
      color: ThemeColors.editorBg(theme),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal, size: 18, color: Colors.greenAccent),
              const SizedBox(width: 8),
              Text(
                'Console',
                style: TextStyle(
                  color: ThemeColors.textMain(theme),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _consoleScrollController,
              itemCount: consoleOutput.length,
              itemBuilder: (context, index) {
                final line = consoleOutput[index];
                Color textColor = ThemeColors.textMain(theme);

                // Colorier selon le type de message
                if (line.startsWith('>')) {
                  textColor = ThemeColors.textMain(theme).withOpacity(0.7);
                } else if (line.startsWith('▶')) {
                  textColor = Colors.greenAccent;
                } else if (line.startsWith('⏸')) {
                  textColor = Colors.orangeAccent;
                } else if (line.startsWith('←')) {
                  textColor = Colors.blueAccent;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'JetBrainsMono',
                      color: textColor,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsBar(AppTheme theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          top: BorderSide(
            color: ThemeColors.textMain(theme).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: _buildControlButton(
              icon: Icons.chevron_left,
              label: 'Prev',
              onPressed: currentLine > 0 ? _onPrevStep : null,
              theme: theme,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: _buildControlButton(
              icon: Icons.skip_next,
              label: 'Step',
              onPressed: _onNextStep,
              theme: theme,
              isDark: isDark,
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: _buildControlButton(
              icon: Icons.chevron_right,
              label: 'Next',
              onPressed: _onNextStep,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required AppTheme theme,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? Colors.blueAccent
              : ThemeColors.editorBg(theme),
          foregroundColor: isPrimary
              ? Colors.white
              : ThemeColors.textMain(theme),
          elevation: isPrimary ? 4 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
