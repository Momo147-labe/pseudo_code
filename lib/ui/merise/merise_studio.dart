import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/merise_provider.dart';
import '../../providers/file_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';
import 'widgets/sidebar.dart';
import 'widgets/canvas_view.dart';
import 'widgets/properties_panel.dart';
import 'widgets/status_footer.dart';
import 'widgets/dictionary_view.dart';
import 'widgets/normalization_view.dart';
import 'widgets/sql_view.dart';
import 'widgets/query_view.dart';
import 'widgets/simulation_view.dart';
import 'widgets/regles_view.dart';
import 'widgets/gdf_view.dart';
import 'widgets/action_fab.dart';

class MeriseStudio extends StatefulWidget {
  const MeriseStudio({super.key});

  @override
  State<MeriseStudio> createState() => _MeriseStudioState();
}

class _MeriseStudioState extends State<MeriseStudio> {
  String? _lastPath;
  MeriseProvider? _meriseProvider;
  String? _lastSelectedId;
  bool _isSheetOpen = false;
  bool _isFabOpen = false;
  String? _lastSyncedContent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_meriseProvider == null) {
      _meriseProvider = context.read<MeriseProvider>();
      _meriseProvider?.addListener(_handleSelectionChange);
    }
  }

  @override
  void dispose() {
    // Nettoyer le listener et le callback de sauvegarde
    _meriseProvider?.removeListener(_syncToFileProvider);
    _meriseProvider?.removeListener(_handleSelectionChange);
    _meriseProvider?.setOnSaveRequested(null);
    super.dispose();
  }

  void _handleSelectionChange() {
    if (!mounted) return;
    final provider = _meriseProvider;
    if (provider == null) return;

    final selectedId = provider.selectedIds.isNotEmpty
        ? provider.selectedIds.last
        : null;

    if (selectedId != null && selectedId != _lastSelectedId) {
      _lastSelectedId = selectedId;

      // Auto-ouvrir si mobile (Vérification simple de la largeur)
      final isMobile = MediaQuery.of(context).size.width < 960;
      if (isMobile && !_isSheetOpen && provider.activeView == 'mcd') {
        _showPropertiesSheet();
      }
    } else if (selectedId == null) {
      _lastSelectedId = null;
    }
  }

  void _showPropertiesSheet() {
    if (_isSheetOpen) return;
    _isSheetOpen = true;

    final theme = context.read<ThemeProvider>().currentTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: ThemeColors.sidebarBg(theme),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: MerisePropertiesPanel(theme: theme, isMobile: true),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      _isSheetOpen = false;
    });
  }

  void _syncToFileProvider() {
    if (!mounted) return;
    final meriseProvider = context.read<MeriseProvider>();
    // Utilisation de try/catch ou vérification de l'existence du provider si nécessaire
    // Mais ici on suppose que FileProvider est dispo.
    final fileProvider = context.read<FileProvider>();

    if (fileProvider.activeFile?.path == _lastPath) {
      final newContent = meriseProvider.serialize();
      if (fileProvider.activeFile!.content != newContent) {
        _lastSyncedContent = newContent;
        fileProvider.updateContent(newContent);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // On n'écoute que les changements nécessaires
    final activeFile = context.select<FileProvider, AppFile?>(
      (p) => p.activeFile,
    );
    final theme = context.select<ThemeProvider, AppTheme>(
      (p) => p.currentTheme,
    );
    final meriseProvider = context.watch<MeriseProvider>();

    if (activeFile != null && activeFile.extension == 'csi') {
      final String currentContent = activeFile.content;
      bool needsReload = _lastPath != activeFile.path;

      // Si le chemin est le même, on vérifie si le contenu a changé par rapport au provider
      // ET si ce n'est pas le contenu que nous avons nous-mêmes synchronisé
      if (!needsReload && currentContent != _lastSyncedContent) {
        // On vérifie si c'est réellement différent du provider actuel
        // (cas des modifs via l'IA en mode "code replace" ou édition manuelle)
        if (currentContent != meriseProvider.serialize()) {
          needsReload = true;
        } else {
          // C'est le même contenu sémantique, on met à jour notre tag de synchro
          _lastSyncedContent = currentContent;
        }
      }

      if (needsReload) {
        final bool isNewPath = _lastPath != activeFile.path;
        _lastPath = activeFile.path;
        _lastSyncedContent = currentContent;

        // Charger le contenu dans MeriseProvider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Obtenir FileProvider sans écouter
          final fileProvider = context.read<FileProvider>();

          meriseProvider.removeListener(_syncToFileProvider);
          meriseProvider.deserialize(currentContent, clearHistory: isNewPath);
          meriseProvider.addListener(_syncToFileProvider);

          // Connecter la demande de sauvegarde du bouton UI vers FileProvider
          meriseProvider.setOnSaveRequested(() {
            fileProvider.saveCurrentFile();
          });
        });
      }
    }

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
            const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): const DeleteIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): const MoveSelectionIntent(
          Offset(-10, 0),
        ),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): const MoveSelectionIntent(
          Offset(10, 0),
        ),
        LogicalKeySet(LogicalKeyboardKey.arrowUp): const MoveSelectionIntent(
          Offset(0, -10),
        ),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): const MoveSelectionIntent(
          Offset(0, 10),
        ),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          UndoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) => meriseProvider.undo(),
          ),
          RedoIntent: CallbackAction<UndoIntent>(
            onInvoke: (_) => meriseProvider.redo(),
          ),
          DeleteIntent: CallbackAction<DeleteIntent>(
            onInvoke: (_) => meriseProvider.deleteSelectedItems(),
          ),
          SelectAllIntent: CallbackAction<SelectAllIntent>(
            onInvoke: (_) => meriseProvider.selectAll(),
          ),
          MoveSelectionIntent: CallbackAction<MoveSelectionIntent>(
            onInvoke: (intent) => meriseProvider.moveSelection(intent.delta),
          ),
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return Scaffold(
              backgroundColor: ThemeColors.editorBg(theme),
              endDrawer: isMobile
                  ? Drawer(
                      width: 250,
                      child: MeriseSidebar(theme: theme, isMobile: true),
                    )
                  : null,
              body: Row(
                children: [
                  // Sidebar handled by BarreLaterale
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: NotificationListener<Notification>(
                                  onNotification: (_) => false,
                                  child: _buildActiveView(
                                    meriseProvider,
                                    theme,
                                    isMobile,
                                  ),
                                ),
                              ),
                              if (meriseProvider.activeView == 'mcd' &&
                                  !isMobile)
                                MerisePropertiesPanel(theme: theme),
                            ],
                          ),
                        ),
                        MeriseStatusFooter(theme: theme, isMobile: isMobile),
                      ],
                    ),
                  ),
                ],
              ),
              floatingActionButton: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (meriseProvider.activeView == 'mcd') ...[
                          // Undo/Redo side by side or vertical? Let's keep them vertical but separate from main FAB
                          FloatingActionButton(
                            heroTag: 'merise_undo',
                            mini: true,
                            onPressed: () => meriseProvider.undo(),
                            backgroundColor: Colors.orangeAccent,
                            child: const Icon(Icons.undo, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          FloatingActionButton(
                            heroTag: 'merise_redo',
                            mini: true,
                            onPressed: () => meriseProvider.redo(),
                            backgroundColor: Colors.orangeAccent,
                            child: const Icon(Icons.redo, color: Colors.white),
                          ),

                          // Espace dynamique pour l'expansion du FAB circulaire
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: _isFabOpen ? 110 : 12,
                          ),

                          // New Circular Action FAB for Entity/Relation/Link
                          MeriseActionFab(
                            onToggle: (isOpen) =>
                                setState(() => _isFabOpen = isOpen),
                            onAddEntity: () => meriseProvider.createEntity(
                              Offset(
                                constraints.maxWidth / 2,
                                constraints.maxHeight / 2,
                              ),
                            ),
                            onAddRelation: () => meriseProvider.createRelation(
                              Offset(
                                constraints.maxWidth / 2,
                                constraints.maxHeight / 2,
                              ),
                            ),
                            onToggleLink: () => meriseProvider.toggleLinkMode(),
                            isLinkMode: meriseProvider.isLinkMode,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (meriseProvider.selectedItem != null &&
                            meriseProvider.activeView == 'mcd')
                          FloatingActionButton(
                            heroTag: 'merise_props',
                            mini: true,
                            onPressed: _showPropertiesSheet,
                            backgroundColor: Colors.orange,
                            child: const Icon(Icons.tune, color: Colors.white),
                          ),
                      ],
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveView(
    MeriseProvider provider,
    AppTheme theme,
    bool isMobile,
  ) {
    switch (provider.activeView) {
      case 'mcd':
        return MeriseCanvasView(theme: theme, isMobile: isMobile);
      case 'regles':
        return ReglesView(theme: theme);
      case 'dictionnaire':
        return DictionnaireView(theme: theme, isMobile: isMobile);
      case 'normalisation':
        return NormalizationView(theme: theme, isMobile: isMobile);
      case 'mld':
        return SqlView(theme: theme, isMld: true, isMobile: isMobile);
      case 'mpd':
        return SqlView(theme: theme, isMld: false, isMobile: isMobile);
      case 'requetes':
        return QueryView(theme: theme, isMobile: isMobile);
      case 'simulation':
        return SimulationView(theme: theme, isMobile: isMobile);
      case 'gdf':
        return GdfView(theme: theme);
      default:
        return Center(
          child: Text(
            "Vue '${provider.activeView}' en construction",
            style: const TextStyle(color: Colors.grey),
          ),
        );
    }
  }
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class MoveSelectionIntent extends Intent {
  final Offset delta;
  const MoveSelectionIntent(this.delta);
}
