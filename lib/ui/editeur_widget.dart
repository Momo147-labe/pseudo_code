import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/debug_provider.dart';
import '../providers/file_provider.dart';
import '../theme.dart';
import 'package:pseudo_code/l10n/app_localizations.dart';
import 'editor_controller.dart';
import 'tab_manager.dart';
import 'package:pseudo_code/interpreteur/linter.dart';
import 'editor/editor_gutter.dart';
import 'editor/editor_search_panel.dart';
import 'editor/editor_minimap.dart';

class EditeurWidget extends StatefulWidget {
  final CodeEditorController? controller;
  final bool isStandalone;
  final String? initialCode;
  final Function(String)? onChanged;

  const EditeurWidget({
    super.key,
    this.controller,
    this.isStandalone = false,
    this.initialCode,
    this.onChanged,
  });

  @override
  State<EditeurWidget> createState() => _EditeurWidgetState();
}

class _EditeurWidgetState extends State<EditeurWidget> {
  late CodeEditorController _controller;
  bool _ownsController = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _gutterScrollController = ScrollController();
  String? _lastPath;
  Timer? _lintTimer;

  OverlayEntry? _overlay;
  OverlayEntry? _quickFixOverlay;
  List<String> _suggestions = [];
  int _selectedIndex = 0;
  bool _isInsertingSuggestion = false;
  final LayerLink _layerLink = LayerLink();
  final LayerLink _quickFixLink = LayerLink();

  // Code Folding State
  final Map<int, bool> _foldedLines = {}; // Line index -> isFolded
  final Set<int> _foldableLines = {};

  // Search & Replace State
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  // minimap
  final ScrollController _minimapScrollController = ScrollController();
  StreamSubscription? _insertSubscription;
  FileProvider? _fileProvider;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = CodeEditorController();
      _ownsController = true;
    }

    if (widget.initialCode != null) {
      _controller.text = widget.initialCode!;
    }

    if (!widget.isStandalone) {
      _fileProvider = context.read<FileProvider>();
      _insertSubscription = _fileProvider?.insertRequests.listen((text) {
        _handleInsertionRequest(text);
      });
    }

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (widget.onChanged != null) {
      widget.onChanged!(_controller.text);
    }
  }

  void _toggleFold(int lineNum) {
    setState(() {
      _foldedLines[lineNum] = !(_foldedLines[lineNum] ?? false);
      _syncHiddenLines();
    });
    _focusNode.onKeyEvent = _handleKeyEvent;
    _editorScrollController.addListener(() {
      if (_gutterScrollController.hasClients) {
        _gutterScrollController.jumpTo(_editorScrollController.offset);
      }
      if (_minimapScrollController.hasClients) {
        _minimapScrollController.jumpTo(_editorScrollController.offset / 5);
      }
      if (_quickFixOverlay != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _quickFixOverlay?.markNeedsBuild();
        });
      }
    });
    if (!widget.isStandalone) {
      context.read<FileProvider>().addListener(_handleFileProviderChange);
    }
    _controller.addListener(_updateFoldableLines);
    _controller.addListener(_handleCursorChange);
  }

  void _handleCursorChange() {
    if (_isInsertingSuggestion) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkQuickFix();
    });
  }

  void _checkQuickFix() {
    final selection = _controller.selection;
    if (!selection.isValid || !selection.isCollapsed) {
      _hideQuickFix();
      return;
    }

    final fileProvider = context.read<FileProvider>();
    final activeFile = fileProvider.activeFile;
    if (activeFile == null) return;

    // Get current line index (1-based because LintIssue.line is 1-based)
    final textBefore = _controller.text.substring(0, selection.baseOffset);
    final currentLine = textBefore.split('\n').length;

    // Find if there's an issue on this line with fixes
    final issuesOnLine = activeFile.lintIssues
        .where(
          (iss) =>
              iss.line == currentLine &&
              iss.fixes != null &&
              iss.fixes!.isNotEmpty,
        )
        .toList();

    if (issuesOnLine.isNotEmpty) {
      _showQuickFix(issuesOnLine.first, currentLine);
    } else {
      _hideQuickFix();
    }
  }

  void _showQuickFix(LintIssue issue, int lineIndex1Based) {
    if (_quickFixOverlay != null) _hideQuickFix();
    final theme = context.read<ThemeProvider>().currentTheme;
    final fontSize = context.read<AppProvider>().fontSize;
    final lineHeight = fontSize * 1.5;

    // Calculate offset relative to the top of the TextField, accounting for scroll
    final initialVerticalOffset =
        (lineIndex1Based - 1) * lineHeight +
        12.0 -
        _editorScrollController.offset;

    // If the line is scrolled out of view, don't show the initial overlay
    if (initialVerticalOffset < -lineHeight ||
        initialVerticalOffset > MediaQuery.of(context).size.height) {
      return;
    }

    _quickFixOverlay = OverlayEntry(
      builder: (context) {
        // Recalculate offset inside builder to stay in sync with scroll
        final currentVerticalOffset =
            (lineIndex1Based - 1) * lineHeight +
            12.0 -
            _editorScrollController.offset;

        return Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _quickFixLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            offset: Offset(20, currentVerticalOffset + lineHeight),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              color: ThemeColors.sidebarBg(theme),
              child: Container(
                width: 280,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "Suggestion d'apprentissage",
                          style: TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: _hideQuickFix,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (issue.documentation != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          issue.documentation!,
                          style: TextStyle(
                            color: ThemeColors.textMain(
                              theme,
                            ).withValues(alpha: 0.9),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    const Divider(color: Colors.white12),
                    const Text(
                      "Actions proposées :",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...?issue.fixes?.map(
                      (fix) => InkWell(
                        onTap: () {
                          _applyFix(issue.line, fix);
                          _hideQuickFix();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_fix_high,
                                size: 14,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  fix.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_quickFixOverlay!);
  }

  void _hideQuickFix() {
    _quickFixOverlay?.remove();
    _quickFixOverlay = null;
  }

  void _applyFix(int line1Based, LintFix fix) {
    final lines = _controller.text.split('\n');
    if (line1Based > 0 && line1Based <= lines.length) {
      lines[line1Based - 1] = fix.replacement;
      _controller.text = lines.join('\n');
      _onChanged(_controller.text, context.read<FileProvider>());
    }
  }

  void _handleFileProviderChange() {
    final fileProvider = context.read<FileProvider>();
    final activeFile = fileProvider.activeFile;

    if (activeFile == null) {
      _lastPath = null;
      _controller.text = "";
      return;
    }

    // Si on est en mode review, le listener gère la mise à jour via _handleDiffVisualization
    if (fileProvider.isReviewMode) {
      _handleDiffVisualization(fileProvider);
    } else {
      // Mode normal : synchroniser avec activeFile.content
      if (_lastPath != activeFile.path) {
        _lastPath = activeFile.path;
        _controller.text = activeFile.content;
        fileProvider.lancerAnalyseStatique(_controller.text);
      } else if (_controller.text != activeFile.content) {
        // Changement externe ou acceptation de modification IA
        _controller.text = activeFile.content;
      }

      // On s'assure que les lignes de diff sont vidées hors review
      if (_controller.addedLines.isNotEmpty ||
          _controller.deletedLines.isNotEmpty) {
        _controller.addedLines = {};
        _controller.deletedLines = {};
      }
    }
  }

  @override
  void dispose() {
    _insertSubscription?.cancel();
    _fileProvider?.removeListener(_handleFileProviderChange);
    _controller.removeListener(_updateFoldableLines);
    _controller.removeListener(_onControllerChanged);
    _controller.removeListener(_handleCursorChange);
    if (_ownsController) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _editorScrollController.dispose();
    _gutterScrollController.dispose();
    _minimapScrollController.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showOverlay() {
    _hideOverlay();
    if (_suggestions.isEmpty) return;
    final theme = context.read<ThemeProvider>().currentTheme;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final overlayWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.9
        : 250.0;

    _overlay = OverlayEntry(
      builder: (context) => Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.topLeft,
          offset: const Offset(0, 24),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(4),
            color: ThemeColors.sidebarBg(theme),
            child: Container(
              width: overlayWidth,
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: ThemeColors.textMain(
                          theme,
                        ).withValues(alpha: 0.6),
                      ),
                      onPressed: _hideOverlay,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(_suggestions.length, (index) {
                            final s = _suggestions[index];
                            final isSelected = index == _selectedIndex;

                            return InkWell(
                              onTap: () => _insertSuggestion(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.blueAccent.withValues(alpha: 0.2)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.code,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.blueAccent
                                          : Colors.white38,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      s,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : ThemeColors.textMain(theme),
                                        fontFamily: 'JetBrainsMono',
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  void _insertSuggestion(String s) {
    _isInsertingSuggestion = true;
    final text = _controller.text;
    final selection = _controller.selection;
    final start = _getWordStart(text, selection.baseOffset);

    final newText = text.replaceRange(start, selection.baseOffset, s);
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(offset: start + s.length);

    _hideOverlay();
    _onChanged(newText, context.read<FileProvider>());
    _isInsertingSuggestion = false;
  }

  void _handleInsertionRequest(String snippet) {
    final selection = _controller.selection;
    final currentText = _controller.text;
    String newFullCode;

    if (!selection.isValid) {
      newFullCode = currentText + snippet;
    } else {
      newFullCode = currentText.replaceRange(
        selection.start,
        selection.end,
        snippet,
      );
    }

    // Au lieu d'appliquer, on propose
    context.read<FileProvider>().proposeCodeChange(newFullCode);
  }

  void _onChanged(String text, FileProvider provider) {
    provider.updateContent(text);

    // Linting avec debounce
    _lintTimer?.cancel();
    _lintTimer = Timer(const Duration(milliseconds: 500), () {
      provider.lancerAnalyseStatique(text);
    });

    if (_isInsertingSuggestion) return;

    final selection = _controller.selection;
    if (selection.baseOffset > 0) {
      final lastChar = text[selection.baseOffset - 1];
      if (RegExp(r'\w').hasMatch(lastChar)) {
        final word = text.substring(
          _getWordStart(text, selection.baseOffset),
          selection.baseOffset,
        );
        _suggestions = _controller.motsCles
            .where((m) => m.toLowerCase().startsWith(word.toLowerCase()))
            .toList();

        if (_suggestions.isNotEmpty) {
          _selectedIndex = 0;
          _showOverlay();
        } else {
          _hideOverlay();
        }
      } else {
        _hideOverlay();
      }
    } else {
      _hideOverlay();
    }
  }

  int _getWordStart(String text, int offset) {
    int start = offset;
    while (start > 0 && RegExp(r'\w').hasMatch(text[start - 1])) {
      start--;
    }
    return start;
  }

  void _updateFoldableLines() {
    final text = _controller.text;
    final lines = text.split('\n');
    final newFoldable = <int>{};

    // Detect blocks: Si, Pour, TantQue, Fonction, Procédure, Structure, Algorithme, Variables
    final blockOn = RegExp(
      r'^\s*(Si|Pour|TantQue|Fonction|Proc[eé]dure|Structure|Algorithme|Variables)\b',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length; i++) {
      if (blockOn.hasMatch(lines[i])) {
        newFoldable.add(i + 1);
      }
    }

    if (newFoldable.length != _foldableLines.length ||
        !newFoldable.containsAll(_foldableLines)) {
      setState(() {
        _foldableLines.clear();
        _foldableLines.addAll(newFoldable);
      });
    }
  }

  // Helper to sync hidden lines with controller
  void _syncHiddenLines() {
    final hidden = <int>{};
    for (var entry in _foldedLines.entries) {
      if (entry.value) {
        final foldStart = entry.key;
        final foldEnd = _findBlockEnd(foldStart);
        for (int i = foldStart + 1; i <= foldEnd; i++) {
          hidden.add(i);
        }
      }
    }
    _controller.hiddenLines = hidden;
  }

  // Helper to check if a line is currently folded
  bool _isLineVisible(int lineIndex) {
    for (var entry in _foldedLines.entries) {
      if (entry.value) {
        final foldStart = entry.key;
        final foldEnd = _findBlockEnd(foldStart);
        if (lineIndex > foldStart && lineIndex <= foldEnd) {
          return false;
        }
      }
    }
    return true;
  }

  int _findBlockEnd(int startLine) {
    final text = _controller.text;
    final lines = text.split('\n');
    if (startLine <= 0 || startLine > lines.length) return startLine;

    final lineText = lines[startLine - 1].trim().toLowerCase();

    String? startKey;
    String? endKey;

    if (RegExp(r'^si\b', caseSensitive: false).hasMatch(lineText)) {
      startKey = 'si';
      endKey = 'finsi';
    } else if (RegExp(r'^pour\b', caseSensitive: false).hasMatch(lineText)) {
      startKey = 'pour';
      endKey = 'finpour';
    } else if (RegExp(r'^tantque\b', caseSensitive: false).hasMatch(lineText)) {
      startKey = 'tantque';
      endKey = 'fintantque';
    } else if (RegExp(
      r'^fonction\b',
      caseSensitive: false,
    ).hasMatch(lineText)) {
      startKey = 'fonction';
      endKey = 'finfonction';
    } else if (RegExp(
      r'^proc[eé]dure\b',
      caseSensitive: false,
    ).hasMatch(lineText)) {
      startKey = 'proc[eé]dure';
      endKey = 'finproc[eé]dure';
    } else if (RegExp(
      r'^structure\b',
      caseSensitive: false,
    ).hasMatch(lineText)) {
      startKey = 'structure';
      endKey = 'finstructure';
    } else if (RegExp(
      r'^algorithme\b',
      caseSensitive: false,
    ).hasMatch(lineText)) {
      startKey = 'algorithme';
      endKey = 'fin';
    } else if (RegExp(
      r'^variables\b',
      caseSensitive: false,
    ).hasMatch(lineText)) {
      startKey = 'variables';
      endKey = 'début';
    }

    if (startKey == null || endKey == null) return startLine;

    int depth = 1;
    final startRegex = RegExp('\\b$startKey\\b', caseSensitive: false);
    final endRegex = RegExp('\\b$endKey\\b', caseSensitive: false);

    for (int i = startLine; i < lines.length; i++) {
      final currentLine = lines[i];
      if (startRegex.hasMatch(currentLine)) depth++;
      if (endRegex.hasMatch(currentLine)) {
        depth--;
        if (depth == 0) return i + 1;
      }
    }
    return lines.length;
  }

  void _handleAutoIndent() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;

    // Get current line to determine indentation
    final beforeCaret = text.substring(0, selection.start);
    final lines = beforeCaret.split('\n');
    final currentLine = lines.last;

    // Calculate current indentation
    final match = RegExp(r'^(\s*)').firstMatch(currentLine);
    String indent = match?.group(1) ?? '';

    // Increase indentation if line ends with certain keywords
    final trimmedLine = currentLine.trim().toLowerCase();
    if (trimmedLine.endsWith('faire') ||
        trimmedLine.endsWith('alors') ||
        trimmedLine.endsWith('début') ||
        trimmedLine.endsWith('structure')) {
      indent += '  ';
    }

    final newText = text.replaceRange(
      selection.start,
      selection.end,
      '\n$indent',
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + 1 + indent.length,
      ),
    );
  }

  void _handleSnippetOrTab() {
    final text = _controller.text;
    final selection = _controller.selection;
    if (!selection.isValid) return;

    final beforeCaret = text.substring(0, selection.start);
    final words = beforeCaret.split(RegExp(r'\s+'));
    final lastWord = words.last.toLowerCase();

    final snippets = {
      'si': 'Si <condition> Alors\n  \nFinSi',
      'pour': 'Pour <var> de <min> à <max> Faire\n  \nFinPour',
      'tantque': 'TantQue <condition> Faire\n  \nFinTantQue',
      'f': 'Fonction <nom>(<params>) : <type>\nDébut\n  \nFinFonction',
      'p': 'Procédure <nom>(<params>)\nDébut\n  \nFinProcédure',
    };

    if (snippets.containsKey(lastWord)) {
      final snippet = snippets[lastWord]!;
      final start = selection.start - lastWord.length;
      final newText = text.replaceRange(start, selection.end, snippet);

      // Position cursor at a logical place (e.g., inside the condition/name)
      int newOffset = start + snippet.indexOf('<');
      if (newOffset < start) newOffset = start + snippet.length;

      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    } else {
      // Just insert two spaces for tab
      final newText = text.replaceRange(selection.start, selection.end, '  ');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + 2),
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // 1. Suggestions Overlay handling
    if (_overlay != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _suggestions.length;
          _showOverlay();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex =
              (_selectedIndex - 1 + _suggestions.length) % _suggestions.length;
          _showOverlay();
        });
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        _insertSuggestion(_suggestions[_selectedIndex]);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _hideOverlay());
        return KeyEventResult.handled;
      }
    }

    // New: Handle Multi-line Indentation with Tab/Shift+Tab
    final selection = _controller.selection;
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        selection.isValid &&
        !selection.isCollapsed) {
      _handleMultiLineIndentation(HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }

    // 2. Editor shortcuts handling (Auto-indent, Snippets)
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _handleAutoIndent();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.tab) {
      _handleSnippetOrTab();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleMultiLineIndentation(bool isShiftPressed) {
    final text = _controller.text;
    final selection = _controller.selection;

    // Expand selection to full lines
    int start = selection.start;
    int end = selection.end;

    // Find the start of the first line
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }
    // Find the end of the last line
    while (end < text.length && text[end] != '\n') {
      end++;
    }

    String selectedText = text.substring(start, end);
    List<String> lines = selectedText.split('\n');
    List<String> modifiedLines = [];

    for (String line in lines) {
      if (isShiftPressed) {
        if (line.startsWith('  ')) {
          modifiedLines.add(line.substring(2));
        } else if (line.startsWith(' ')) {
          modifiedLines.add(line.substring(1));
        } else {
          modifiedLines.add(line);
        }
      } else {
        modifiedLines.add('  $line');
      }
    }

    String newSelectedText = modifiedLines.join('\n');
    _controller.value = TextEditingValue(
      text: text.replaceRange(start, end, newSelectedText),
      selection: TextSelection(
        baseOffset: start,
        extentOffset: start + newSelectedText.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final debugProvider = context.watch<DebugProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final fileProvider = context.watch<FileProvider>();

    final activeFile = fileProvider.activeFile;
    final theme = themeProvider.currentTheme;

    // Detect mobile mode
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (activeFile == null && !widget.isStandalone) {
      return Container(
        decoration: BoxDecoration(
          color: ThemeColors.editorBg(theme),
          image: const DecorationImage(
            image: AssetImage('assets/univ_labe.jpg'),
            fit: BoxFit.cover,
            opacity: 0.3,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.code,
                size: 64,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.openFileToStart,
                style: TextStyle(
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Content is now synchronized via initState listener or _handleDiffVisualization

    // Sync error and highlight state to controller to force repaint
    _controller.errorLine = debugProvider.errorLine;
    _controller.highlightLine = debugProvider.currentHighlightLine;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const SaveIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const SearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) => fileProvider.saveCurrentFile(),
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (_isSearchVisible) {
                  _focusNode.unfocus();
                }
              });
              return null;
            },
          ),
        },
        child: Stack(
          children: [
            Column(
              children: [
                if (!widget.isStandalone) const TabManager(),
                Expanded(
                  child: Container(
                    color: ThemeColors.editorBg(theme),
                    child: Row(
                      children: [
                        // Numéros de ligne
                        EditorGutter(
                          lineCount: _controller.text.split('\n').length,
                          scrollController: _gutterScrollController,
                          isMobile: isMobile,
                          theme: theme,
                          breakpoints: debugProvider.breakpoints,
                          currentHighlightLine:
                              debugProvider.currentHighlightLine,
                          errorLine: debugProvider.errorLine,
                          addedLines: _controller.addedLines,
                          deletedLines: _controller.deletedLines,
                          fontSize: appProvider.fontSize,
                          onToggleBreakpoint: (line) =>
                              debugProvider.toggleBreakpoint(line),
                          onToggleFold: _toggleFold,
                          isLineVisible: _isLineVisible,
                          foldableLines: _foldableLines,
                          foldedLines: _foldedLines,
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CompositedTransformTarget(
                              link: _layerLink,
                              child: CompositedTransformTarget(
                                link: _quickFixLink,
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  scrollController: _editorScrollController,
                                  maxLines: null,
                                  expands: true,
                                  readOnly:
                                      !widget.isStandalone &&
                                      fileProvider.isReviewMode,
                                  textAlignVertical: TextAlignVertical.top,
                                  cursorColor: ThemeColors.textBright(theme),
                                  style: TextStyle(
                                    color: ThemeColors.textBright(theme),
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: appProvider.fontSize,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.only(top: 12),
                                  ),
                                  onChanged: (text) =>
                                      _onChanged(text, fileProvider),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Minimap
                        if (appProvider.showMinimap && !isMobile)
                          EditorMinimap(
                            scrollController: _minimapScrollController,
                            textSpan: _controller.buildTextSpan(
                              context: context,
                              style: TextStyle(
                                color: ThemeColors.textMain(
                                  theme,
                                ).withValues(alpha: 0.2),
                                fontSize: 3,
                                height: 1.5,
                                fontFamily: 'JetBrainsMono',
                              ),
                              withComposing: false,
                            ),
                            theme: theme,
                          ),
                      ],
                    ),
                  ),
                ),
                if (fileProvider.isReviewMode)
                  _buildReviewBanner(theme, fileProvider),
              ],
            ),
            if (_isSearchVisible)
              EditorSearchPanel(
                searchController: _searchController,
                replaceController: _replaceController,
                searchMatches: _searchMatches,
                currentMatchIndex: _currentMatchIndex,
                isMobile: isMobile,
                theme: theme,
                onSearchChanged: _performSearch,
                onNextMatch: _nextMatch,
                onPrevMatch: _prevMatch,
                onReplaceCurrent: _replaceCurrent,
                onReplaceAll: _replaceAll,
                onClose: () => setState(() => _isSearchVisible = false),
              ),
          ],
        ),
      ),
    );
  }

  void _performSearch() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentMatchIndex = -1;
      });
      return;
    }

    final text = _controller.text;
    final matches = <int>[];
    int index = text.indexOf(query);
    while (index != -1) {
      matches.add(index);
      index = text.indexOf(query, index + query.length);
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isEmpty ? -1 : 0;
    });

    if (_currentMatchIndex != -1) {
      _scrollToMatch();
    }
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
    });
    _scrollToMatch();
  }

  void _prevMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _searchMatches.length) %
          _searchMatches.length;
    });
    _scrollToMatch();
  }

  void _scrollToMatch() {
    final pos = _searchMatches[_currentMatchIndex];
    _controller.selection = TextSelection(
      baseOffset: pos,
      extentOffset: pos + _searchController.text.length,
    );

    // Calculate line index
    final textBefore = _controller.text.substring(0, pos);
    final lineIndex = textBefore.split('\n').length - 1;

    // Scroll both editor and gutter
    final fontSize = context.read<AppProvider>().fontSize;
    final lineHeight = fontSize * 1.5;
    final offset = lineIndex * lineHeight;

    _editorScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
    _gutterScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _replaceCurrent() {
    if (_currentMatchIndex == -1) return;
    final pos = _searchMatches[_currentMatchIndex];
    final query = _searchController.text;
    final replace = _replaceController.text;

    final newText = _controller.text.replaceRange(
      pos,
      pos + query.length,
      replace,
    );
    _controller.text = newText;
    _performSearch();
  }

  void _replaceAll() {
    final query = _searchController.text;
    final replace = _replaceController.text;
    if (query.isEmpty) return;

    final newText = _controller.text.replaceAll(query, replace);
    _controller.text = newText;
    _performSearch();
  }

  void _handleDiffVisualization(FileProvider fileProvider) {
    if (fileProvider.proposedCode == null) return;
    if (fileProvider.activeFile == null) return;

    final oldLines = fileProvider.activeFile!.content.split('\n');
    final newLines = fileProvider.proposedCode!.split('\n');

    // On va construire une vue de révision qui contient les lignes ajoutées et supprimées.
    // Pour chaque ligne, on décide si elle est 'conservée', 'ajoutée' ou 'supprimée'.
    // Ceci est une implémentation simplifiée d'un diff.

    final List<String> reviewLines = [];
    final Set<int> added = {};
    final Set<int> deleted = {};

    int i = 0;
    int j = 0;

    // Algorithme de comparaison simple par ligne
    while (i < oldLines.length || j < newLines.length) {
      if (i < oldLines.length &&
          j < newLines.length &&
          oldLines[i].trim() == newLines[j].trim()) {
        reviewLines.add(oldLines[i]);
        i++;
        j++;
      } else {
        bool foundInOld = false;
        bool foundInNew = false;
        for (int k = 1; k <= 10; k++) {
          if (i + k < oldLines.length &&
              j < newLines.length &&
              oldLines[i + k].trim() == newLines[j].trim()) {
            foundInOld = true;
            break;
          }
          if (j + k < newLines.length &&
              i < oldLines.length &&
              newLines[j + k].trim() == oldLines[i].trim()) {
            foundInNew = true;
            break;
          }
        }

        if (foundInOld && !foundInNew) {
          reviewLines.add(oldLines[i]);
          deleted.add(reviewLines.length);
          i++;
        } else if (foundInNew && !foundInOld) {
          reviewLines.add(newLines[j]);
          added.add(reviewLines.length);
          j++;
        } else if (i < oldLines.length && j < newLines.length) {
          reviewLines.add(oldLines[i]);
          deleted.add(reviewLines.length);
          i++;
        } else if (i < oldLines.length) {
          reviewLines.add(oldLines[i]);
          deleted.add(reviewLines.length);
          i++;
        } else if (j < newLines.length) {
          reviewLines.add(newLines[j]);
          added.add(reviewLines.length);
          j++;
        }
      }
    }

    final reviewText = reviewLines.join('\n');
    if (_controller.text != reviewText) {
      _controller.text = reviewText;
    }

    _controller.addedLines = added;
    _controller.deletedLines = deleted;
  }

  Widget _buildReviewBanner(AppTheme theme, FileProvider fileProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: const Border(
          top: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.rate_review, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Révision des modifications de l'IA",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: () => fileProvider.discardChange(),
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            label: const Text(
              "Refuser",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => fileProvider.acceptChange(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            icon: const Icon(Icons.check, color: Colors.white, size: 18),
            label: const Text(
              "Accepter",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}
