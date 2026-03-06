import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Pour rootBundle
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
import '../outils/formateur.dart';
import '../interpreteur/mots_cles.dart';

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
  List<Suggestion> _suggestions = [];
  bool _isAideMode = false;
  int _selectedIndex = 0;
  bool _isInsertingSuggestion = false;
  final LayerLink _layerLink = LayerLink();
  final LayerLink _quickFixLink = LayerLink();

  // Code Folding State
  final Map<int, bool> _foldedLines = {}; // Line index -> isFolded
  final Set<int> _foldableLines = {};

  // Search & Replace State
  // Search & Replace State
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  List<int> _searchMatches = [];
  int _currentMatchIndex = -1;

  // minimap
  final ScrollController _minimapScrollController = ScrollController();
  StreamSubscription? _insertSubscription;
  StreamSubscription? _jumpSubscription;
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
      _insertSubscription = _fileProvider?.insertRequests.listen((request) {
        _handleInsertionRequest(request);
      });
      _jumpSubscription = _fileProvider?.jumpRequests.listen((line) {
        _jumpToLine(line);
      });
      _fileProvider?.addListener(_handleFileProviderChange);
    }

    _controller.addListener(_onControllerChanged);
    _controller.addListener(_updateFoldableLines);
    _controller.addListener(_handleCursorChange);

    _editorScrollController.addListener(_onEditorScroll);
    _focusNode.onKeyEvent = _handleKeyEvent;

    // Charger le contenu du fichier initial
    if (!widget.isStandalone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handleFileProviderChange();
      });
    }
  }

  void _onEditorScroll() {
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
    _jumpSubscription?.cancel();
    _fileProvider?.removeListener(_handleFileProviderChange);
    _controller.removeListener(_updateFoldableLines);
    _controller.removeListener(_onControllerChanged);
    _controller.removeListener(_handleCursorChange);
    _editorScrollController.removeListener(_onEditorScroll);
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
                            final suggestion = _suggestions[index];
                            final isSelected = index == _selectedIndex;

                            return InkWell(
                              onTap: () => _insertSuggestion(suggestion.text),
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
                                      suggestion.icon,
                                      size: 16,
                                      color: isSelected
                                          ? Colors.blueAccent
                                          : Colors.white38,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            suggestion.text,
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
                                          Text(
                                            suggestion.category ??
                                                suggestion.type,
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isSelected
                                                  ? Colors.blueAccent
                                                        .withValues(alpha: 0.8)
                                                  : Colors.white24,
                                            ),
                                          ),
                                        ],
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

  Future<void> _insertSuggestion(String s) async {
    _isInsertingSuggestion = true;
    final text = _controller.text;
    final selection = _controller.selection;
    final start = _getWordStart(text, selection.baseOffset);

    String insertionText = s;
    if (_isAideMode) {
      try {
        // Chargement via le bundle d'assets de Flutter
        final assetPath = "lib/interpreteur/blocs/donnerTableau/$s.md";
        insertionText = await rootBundle.loadString(assetPath);
      } catch (e) {
        debugPrint("Erreur lors de la lecture de l'asset algorithme: $e");
      }
    }

    if (!mounted) return;
    final newText = text.replaceRange(
      start,
      selection.baseOffset,
      insertionText,
    );
    _controller.text = newText;
    _controller.selection = TextSelection.collapsed(
      offset: start + insertionText.length,
    );

    _hideOverlay();
    _isAideMode = false; // Reset explicitly après insertion
    _onChanged(newText, context.read<FileProvider>());
    _isInsertingSuggestion = false;
  }

  void _handleInsertionRequest(InsertionRequest request) {
    final selection = _controller.selection;
    final currentText = _controller.text;
    final snippet = request.snippet;
    String newFullCode = currentText;
    int newCursorOffset = -1;

    const pairs = {'(': ')', '[': ']', '{': '}', '"': '"'};

    if (request.direct) {
      if (!selection.isValid) {
        if (pairs.containsKey(snippet)) {
          newFullCode = currentText + snippet + pairs[snippet]!;
          newCursorOffset = currentText.length + snippet.length;
        } else {
          newFullCode = currentText + snippet;
          newCursorOffset = newFullCode.length;
        }
      } else if (!selection.isCollapsed) {
        if (pairs.containsKey(snippet)) {
          String selectedText = currentText.substring(
            selection.start,
            selection.end,
          );
          newFullCode = currentText.replaceRange(
            selection.start,
            selection.end,
            '$snippet$selectedText${pairs[snippet]!}',
          );
          newCursorOffset = selection.start + snippet.length;
        } else {
          newFullCode = currentText.replaceRange(
            selection.start,
            selection.end,
            snippet,
          );
          newCursorOffset = selection.start + snippet.length;
        }
      } else {
        if (pairs.containsKey(snippet)) {
          newFullCode = currentText.replaceRange(
            selection.start,
            selection.end,
            '$snippet${pairs[snippet]!}',
          );
          newCursorOffset = selection.start + snippet.length;
        } else {
          newFullCode = currentText.replaceRange(
            selection.start,
            selection.end,
            snippet,
          );
          newCursorOffset = selection.start + snippet.length;
        }
      }

      _controller.text = newFullCode;
      if (newCursorOffset != -1) {
        _controller.selection = TextSelection.collapsed(
          offset: newCursorOffset,
        );
      }
      _onChanged(newFullCode, context.read<FileProvider>());
    } else {
      // Pour une insertion non directe, on ne change pas le comportement de base
      if (!selection.isValid) {
        newFullCode = currentText + snippet;
      } else {
        newFullCode = currentText.replaceRange(
          selection.start,
          selection.end,
          snippet,
        );
      }
      context.read<FileProvider>().proposeCodeChange(newFullCode);
    }
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

        if (word.toLowerCase() == "aide") {
          _isAideMode = true;
          // Utilisation de AssetManifest pour lister les fichiers dynamiquement
          AssetManifest.loadFromAssetBundle(rootBundle)
              .then((manifest) {
                final algoAssets = manifest.listAssets().where(
                  (path) =>
                      path.startsWith(
                        'lib/interpreteur/blocs/donnerTableau/',
                      ) &&
                      path.endsWith('.md'),
                );

                _suggestions = algoAssets.map((path) {
                  final name = path.split('/').last.replaceAll('.md', '');
                  return Suggestion(
                    text: name,
                    type: 'Aide',
                    icon: Icons.help_outline,
                  );
                }).toList();

                if (_suggestions.isNotEmpty) {
                  _selectedIndex = 0;
                  _showOverlay();
                } else {
                  _hideOverlay();
                }
              })
              .catchError((e) {
                debugPrint("Erreur manifest: $e");
                _hideOverlay();
              });
        } else {
          _isAideMode = false;
          _suggestions = _controller.motsCles
              .where((s) => s.text.toLowerCase().startsWith(word.toLowerCase()))
              .toList();

          if (_suggestions.isNotEmpty) {
            _selectedIndex = 0;
            _showOverlay();
          } else {
            _hideOverlay();
          }
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

  void _jumpToLine(int line1Based) {
    if (line1Based <= 0) return;
    final text = _controller.text;
    final lines = text.split('\n');
    if (line1Based > lines.length) return;

    // Calculate offset
    int offset = 0;
    for (int i = 0; i < line1Based - 1; i++) {
      offset += lines[i].length + 1;
    }

    _controller.selection = TextSelection.collapsed(offset: offset);
    _focusNode.requestFocus();

    // Scroll
    final fontSize = context.read<AppProvider>().fontSize;
    final lineHeight = fontSize * 1.5;
    final scrollOffset = (line1Based - 1) * lineHeight;

    _editorScrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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

  /// Auto-fermeture des délimiteurs : (, [, ", {
  /// Insère le caractère fermant et place le curseur entre les deux.
  KeyEventResult _handleAutoClose(String character) {
    const pairs = {'(': ')', '[': ']', '"': '"', '{': '}'};
    if (!pairs.containsKey(character)) return KeyEventResult.ignored;

    final sel = _controller.selection;
    if (!sel.isValid) return KeyEventResult.ignored;

    final text = _controller.text;
    final closing = pairs[character]!;

    // Si on tape un caractère fermant qui est déjà juste devant le curseur, on saute par-dessus
    // (Over-typing)
    if (sel.isCollapsed &&
        sel.baseOffset < text.length &&
        text[sel.baseOffset] == character &&
        (character == ')' ||
            character == ']' ||
            character == '"' ||
            character == '}')) {
      _controller.selection = TextSelection.collapsed(
        offset: sel.baseOffset + 1,
      );
      return KeyEventResult.handled;
    }

    // Cas spécial si on tape le caractère fermant explicitement
    final closingChars = ")]}\"";
    if (closingChars.contains(character) &&
        sel.isCollapsed &&
        sel.baseOffset < text.length &&
        text[sel.baseOffset] == character) {
      _controller.selection = TextSelection.collapsed(
        offset: sel.baseOffset + 1,
      );
      return KeyEventResult.handled;
    }

    // Si un texte est sélectionné, on l'entoure des délimiteurs
    if (!sel.isCollapsed) {
      final selected = text.substring(sel.start, sel.end);
      final newText = text.replaceRange(
        sel.start,
        sel.end,
        '$character$selected$closing',
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection(
          baseOffset: sel.start + 1,
          extentOffset: sel.start + 1 + selected.length,
        ),
      );
      return KeyEventResult.handled;
    }

    // Insertion standard : caractère + fermant, curseur entre les deux
    final newText = text.replaceRange(sel.start, sel.end, '$character$closing');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + 1),
    );
    // Notifier le provider si disponible (mode non-standalone)
    if (_fileProvider != null) {
      _onChanged(newText, _fileProvider!);
    }
    return KeyEventResult.handled;
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
        _insertSuggestion(_suggestions[_selectedIndex].text);
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _hideOverlay());
        return KeyEventResult.handled;
      }
    }

    final selection = _controller.selection;

    // Handle Backspace to remove auto-closed pairs
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        selection.isCollapsed &&
        selection.baseOffset > 0 &&
        selection.baseOffset < _controller.text.length) {
      final charBefore = _controller.text[selection.baseOffset - 1];
      final charAfter = _controller.text[selection.baseOffset];
      const openers = '([{"';
      const closers = ')]}"';
      int openerIdx = openers.indexOf(charBefore);
      if (openerIdx != -1 && charAfter == closers[openerIdx]) {
        final newText = _controller.text.replaceRange(
          selection.baseOffset - 1,
          selection.baseOffset + 1,
          '',
        );
        _controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: selection.baseOffset - 1),
        );
        if (_fileProvider != null) _onChanged(newText, _fileProvider!);
        return KeyEventResult.handled;
      }
    }

    // New: Handle Multi-line Indentation with Tab/Shift+Tab
    if (event.logicalKey == LogicalKeyboardKey.tab &&
        selection.isValid &&
        !selection.isCollapsed) {
      _handleMultiLineIndentation(HardwareKeyboard.instance.isShiftPressed);
      return KeyEventResult.handled;
    }

    // 2. Auto-fermeture: supprimé de _handleKeyEvent car géré par AutoCloseFormatter pour support mobile

    // 3. Editor shortcuts handling (Auto-indent, Snippets)
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
    final isDark = theme != AppTheme.light && theme != AppTheme.papier;

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
        LogicalKeySet(
          LogicalKeyboardKey.alt,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyF,
        ): const FormatIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          SaveIntent: CallbackAction<SaveIntent>(
            onInvoke: (intent) => fileProvider.saveCurrentFile(),
          ),
          SearchIntent: CallbackAction<SearchIntent>(
            onInvoke: (intent) {
              appProvider.toggleEditorSearch();
              if (appProvider.isEditorSearchVisible) {
                _focusNode.unfocus();
              }
              return null;
            },
          ),
          FormatIntent: CallbackAction<FormatIntent>(
            onInvoke: (intent) {
              final formatted = PseudoCodeFormateur.formater(_controller.text);
              if (formatted != _controller.text) {
                _controller.text = formatted;
                _onChanged(formatted, fileProvider);
              }
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
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: GridPainter(
                              color: ThemeColors.textMain(
                                theme,
                              ).withValues(alpha: isDark ? 0.05 : 0.1),
                            ),
                          ),
                        ),
                        Row(
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
                                    child: GestureDetector(
                                      onLongPressStart: (details) {
                                        _showHoverTooltip(
                                          details.localPosition,
                                          appProvider.fontSize,
                                        );
                                      },
                                      onTapDown: (_) => _hideHoverTooltip(),
                                      child: MouseRegion(
                                        onHover: (event) => _handleMouseHover(
                                          event,
                                          appProvider.fontSize,
                                        ),
                                        onExit: (_) => _hideHoverTooltip(),
                                        child: TextField(
                                          controller: _controller,
                                          focusNode: _focusNode,
                                          scrollController:
                                              _editorScrollController,
                                          maxLines: null,
                                          expands: true,
                                          readOnly:
                                              !widget.isStandalone &&
                                              fileProvider.isReviewMode,
                                          textAlignVertical:
                                              TextAlignVertical.top,
                                          cursorColor: ThemeColors.textBright(
                                            theme,
                                          ),
                                          style: TextStyle(
                                            color: ThemeColors.textBright(
                                              theme,
                                            ),
                                            fontFamily:
                                                themeProvider.fontFamily,
                                            fontSize: appProvider.fontSize,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.only(
                                              top: 12,
                                            ),
                                          ),
                                          inputFormatters: [
                                            AutoCloseFormatter(),
                                          ],
                                          onChanged: (text) =>
                                              _onChanged(text, fileProvider),
                                        ),
                                      ),
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
                                    fontFamily: themeProvider.fontFamily,
                                  ),
                                  withComposing: false,
                                ),
                                theme: theme,
                                lintIssues: activeFile?.lintIssues ?? [],
                                executionErrorLine: debugProvider.errorLine,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (fileProvider.isReviewMode)
                  _buildReviewBanner(theme, fileProvider),
              ],
            ),
            if (appProvider.isEditorSearchVisible)
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
                onClose: () => appProvider.setEditorSearchVisible(false),
              ),
            // Sticky Scroll Header
            if (!isMobile)
              _buildStickyHeader(
                theme,
                appProvider.fontSize,
                themeProvider.fontFamily,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader(
    AppTheme theme,
    double fontSize,
    String fontFamily,
  ) {
    if (!_editorScrollController.hasClients ||
        _editorScrollController.offset < 50) {
      return const SizedBox.shrink();
    }

    final lineHeight = fontSize * 1.5;
    final firstVisibleLineIndex = (_editorScrollController.offset / lineHeight)
        .floor();

    // Find the current enclosing block
    String? currentBlock;
    final lines = _controller.text.split('\n');

    final blockRegex = RegExp(
      r'^\s*(Algorithme|Fonction|Proc[eé]dure|Structure)\s+([a-zA-Z_]\w*)',
      caseSensitive: false,
    );

    for (int i = firstVisibleLineIndex; i >= 0; i--) {
      if (i < lines.length) {
        final match = blockRegex.firstMatch(lines[i]);
        if (match != null) {
          currentBlock = "${match.group(1)} ${match.group(2)}";
          break;
        }
      }
    }

    if (currentBlock == null) return const SizedBox.shrink();

    return Positioned(
      top: widget.isStandalone ? 0 : 40, // Account for TabManager
      left: 50, // Account for Gutter
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: ThemeColors.sidebarBg(theme).withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.segment,
              size: 14,
              color: ThemeColors.syntaxStructure(theme),
            ),
            const SizedBox(width: 8),
            Text(
              currentBlock,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: fontFamily,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentMatchIndex = -1;
        _controller.searchMatches = [];
        _controller.currentMatchIndex = -1;
        _controller.searchQuery = '';
      });
      return;
    }

    final text = _controller.text.toLowerCase();
    final matches = <int>[];
    int index = text.indexOf(query);
    while (index != -1) {
      matches.add(index);
      index = text.indexOf(query, index + query.length);
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isEmpty ? -1 : 0;
      _controller.searchMatches = matches;
      _controller.currentMatchIndex = _currentMatchIndex;
      _controller.searchQuery = _searchController.text;
    });

    if (_currentMatchIndex != -1) {
      _scrollToMatch();
    }
  }

  void _nextMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      _controller.currentMatchIndex = _currentMatchIndex;
    });
    _scrollToMatch();
  }

  void _prevMatch() {
    if (_searchMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _searchMatches.length) %
          _searchMatches.length;
      _controller.currentMatchIndex = _currentMatchIndex;
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
    _controller.value = _controller.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: pos + replace.length),
    );
    _onChanged(newText, context.read<FileProvider>());
    _performSearch();
  }

  void _replaceAll() {
    final query = _searchController.text;
    final replace = _replaceController.text;
    if (query.isEmpty) return;

    // Use a more robust replace that respects our found matches if it was case-insensitive
    // But since we are doing a global replace, we can use a regex with case-insensitive flag if needed
    // For now, let's just use the current text and replace matching our matches array from end to start to keep offsets valid
    String currentText = _controller.text;
    for (int i = _searchMatches.length - 1; i >= 0; i--) {
      final pos = _searchMatches[i];
      currentText = currentText.replaceRange(pos, pos + query.length, replace);
    }

    _controller.text = currentText;
    _onChanged(currentText, context.read<FileProvider>());
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

  OverlayEntry? _hoverOverlay;
  Timer? _hoverTimer;

  void _handleMouseHover(PointerHoverEvent event, double fontSize) {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 500), () {
      _showHoverTooltip(event.localPosition, fontSize);
    });
  }

  void _hideHoverTooltip() {
    _hoverTimer?.cancel();
    _hoverOverlay?.remove();
    _hoverOverlay = null;
  }

  void _showHoverTooltip(Offset localPos, double fontSize) {
    _hideHoverTooltip();

    final lineHeight = fontSize * 1.5;
    final charWidth = fontSize * 0.6; // Approximation for JetBrainsMono

    final lineIndex =
        ((localPos.dy + _editorScrollController.offset - 12) / lineHeight)
            .floor();
    final charIndex = (localPos.dx / charWidth).floor();

    final lines = _controller.text.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return;

    final line = lines[lineIndex];
    if (charIndex < 0 || charIndex >= line.length) return;

    // Find word under cursor
    int start = charIndex;
    while (start > 0 && RegExp(r'\w').hasMatch(line[start - 1])) start--;
    int end = charIndex;
    while (end < line.length && RegExp(r'\w').hasMatch(line[end])) end++;

    final word = line.substring(start, end).toLowerCase();
    if (word.isEmpty) return;

    final meta = MotsCles.getMetadata(word);
    String? docMarkdown = meta?['desc'];
    String? syntax = meta?['syntax'];
    String? category = meta?['label'];
    IconData? icon;

    if (meta != null) {
      final iconName = meta['icon'];
      if (iconName == 'help_outline')
        icon = Icons.help_outline;
      else if (iconName == 'loop')
        icon = Icons.loop;
      else if (iconName == 'sync')
        icon = Icons.sync;
      else if (iconName == 'terminal')
        icon = Icons.terminal;
      else if (iconName == 'analytics')
        icon = Icons.analytics;
      else if (iconName == 'play_circle_outline')
        icon = Icons.play_circle_outline;
      else if (iconName == 'stop_circle')
        icon = Icons.stop_circle;
      else if (iconName == 'functions')
        icon = Icons.functions;
      else if (iconName == 'settings_suggest')
        icon = Icons.settings_suggest;
      else if (iconName == 'output')
        icon = Icons.output;
      else if (iconName == 'input')
        icon = Icons.input;
      else if (iconName == 'grid_on')
        icon = Icons.grid_on;
      else if (iconName == 'bubble_chart')
        icon = Icons.bubble_chart;
      else if (iconName == 'numbers')
        icon = Icons.numbers;
      else if (iconName == 'calculate')
        icon = Icons.calculate;
      else if (iconName == 'text_fields')
        icon = Icons.text_fields;
      else if (iconName == 'toggle_on')
        icon = Icons.toggle_on;
    }

    String? varType;
    String? scopeLabel;

    if (docMarkdown == null) {
      final info = _controller.getInfo(word);
      if (info != null) {
        varType = info.type ?? 'Inconnu';
        docMarkdown = "Identifiant déclaré à la ligne ${info.line}.";
        category = "Variable";
        icon = Icons.data_object;
        scopeLabel = info.line < 10 ? "Global" : "Locale";
      }
    }

    if (docMarkdown == null) return;

    final theme = context.read<ThemeProvider>().currentTheme;

    // Responsive positioning logic
    final screenSize = MediaQuery.of(context).size;
    const double tooltipWidth = 300;
    const double tooltipHeight = 200; // Estimated max height

    // Convert local position to global to check screen edges
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final globalPos = renderBox.localToGlobal(localPos);

    double left = localPos.dx + 40;
    double top = localPos.dy + (widget.isStandalone ? 20 : 60);

    // If the tooltip would go off the right edge of the screen, flip it to the left of the cursor
    if (globalPos.dx + tooltipWidth + 40 > screenSize.width) {
      left = localPos.dx - tooltipWidth - 10;
    }

    // If it would go off the bottom edge, move it above the cursor
    if (globalPos.dy + tooltipHeight > screenSize.height) {
      top = localPos.dy - 100; // Offset upwards
    }

    _hoverOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: tooltipWidth),
                decoration: BoxDecoration(
                  color: ThemeColors.sidebarBg(theme).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (icon != null)
                          Icon(icon, size: 16, color: Colors.blueAccent),
                        Text(
                          word.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                        if (category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 16),
                    if (varType != null) ...[
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Type : ",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ThemeColors.textMain(
                                    theme,
                                  ).withValues(alpha: 0.6),
                                ),
                              ),
                              Text(
                                varType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: ThemeColors.syntaxType(theme),
                                ),
                              ),
                            ],
                          ),
                          if (scopeLabel != null)
                            Wrap(
                              spacing: 4,
                              runSpacing: 2,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Scope : ",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ThemeColors.textMain(
                                      theme,
                                    ).withValues(alpha: 0.6),
                                  ),
                                ),
                                Text(
                                  scopeLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      docMarkdown!,
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeColors.textMain(theme),
                        height: 1.4,
                      ),
                    ),
                    if (syntax != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        "SYNTAXE",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: ThemeColors.textMain(
                            theme,
                          ).withValues(alpha: 0.5),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          syntax,
                          style: const TextStyle(
                            fontFamily: 'JetBrainsMono',
                            fontSize: 11,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_hoverOverlay!);
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class FormatIntent extends Intent {
  const FormatIntent();
}

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    const double spacing = 25.0; // Espacement de la grille

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      (oldDelegate as GridPainter).color != color;
}

class AutoCloseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) return newValue;

    int oldLen = oldValue.text.length;
    int newLen = newValue.text.length;
    int diff = newLen - oldLen;

    const pairs = {'(': ')', '[': ']', '"': '"', '{': '}'};
    const closingChars = ")]}\"";

    // 1. Frappe simple d'un caractère de fermeture (over-typing) et d'ouverture
    if (diff == 1 && oldValue.selection.isCollapsed) {
      int insertIndex = newValue.selection.baseOffset - 1;
      if (insertIndex >= 0 && insertIndex < newValue.text.length) {
        String char = newValue.text[insertIndex];

        // Si on tape un caractère fermant qui est déjà présent juste après le curseur
        if (closingChars.contains(char)) {
          int oldCursor = oldValue.selection.baseOffset;
          if (oldCursor < oldLen && oldValue.text[oldCursor] == char) {
            // Over-typing: on ignore l'insertion et on avance juste le curseur
            return TextEditingValue(
              text: oldValue.text,
              selection: TextSelection.collapsed(offset: oldCursor + 1),
            );
          }
        }

        // Si on tape un caractère d'ouverture, on insère la fermeture auto
        if (pairs.containsKey(char)) {
          String closing = pairs[char]!;
          String newText = newValue.text.replaceRange(
            insertIndex + 1,
            insertIndex + 1,
            closing,
          );
          return TextEditingValue(text: newText, selection: newValue.selection);
        }
      }
    }

    // 2. Wrap de texte existant (ex: l'utilisateur a sélectionné "abc" et a tapé "(")
    if (!oldValue.selection.isCollapsed) {
      int deletedLen = oldValue.selection.end - oldValue.selection.start;
      if (diff == 1 - deletedLen) {
        int insertIndex = newValue.selection.baseOffset - 1;
        if (insertIndex == oldValue.selection.start) {
          String char = newValue.text[insertIndex];
          if (pairs.containsKey(char)) {
            String closing = pairs[char]!;
            String selected = oldValue.text.substring(
              oldValue.selection.start,
              oldValue.selection.end,
            );
            String newText = oldValue.text.replaceRange(
              oldValue.selection.start,
              oldValue.selection.end,
              '$char$selected$closing',
            );
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                offset: oldValue.selection.start + 1,
              ),
            );
          }
        }
      }
    }

    return newValue;
  }
}
