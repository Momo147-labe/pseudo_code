import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudo_code/providers/graph_provider.dart';
import 'package:pseudo_code/providers/theme_provider.dart';
import 'package:pseudo_code/theme.dart';
import 'widgets/graph_canvas.dart';
import 'widgets/graph_analysis_view.dart';
import 'widgets/dijkstra_panel.dart';

class GraphStudio extends StatefulWidget {
  const GraphStudio({super.key});

  @override
  State<GraphStudio> createState() => _GraphStudioState();
}

class _GraphStudioState extends State<GraphStudio> {
  bool _showAnalysis = false;
  bool _showDijkstra = false;
  final GlobalKey<GraphCanvasState> _canvasKey = GlobalKey<GraphCanvasState>();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = theme == AppTheme.dark;

    return Scaffold(
      backgroundColor: ThemeColors.editorBg(theme),
      body: Column(
        children: [
          _buildToolbar(context, theme, isDark),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 850;
                final double panelWidth = math.min(
                  420.0,
                  constraints.maxWidth * 0.85,
                );

                return Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(child: GraphCanvas(key: _canvasKey)),
                        if (_showAnalysis && isWide)
                          GraphAnalysisView(
                            onClose: () =>
                                setState(() => _showAnalysis = false),
                            width: panelWidth,
                          ),
                        if (_showDijkstra && isWide)
                          DijkstraPanel(
                            onClose: () {
                              setState(() => _showDijkstra = false);
                              context.read<GraphProvider>().clearDijkstra();
                            },
                            width: panelWidth,
                          ),
                      ],
                    ),
                    if (_showAnalysis && !isWide)
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: Material(
                          elevation: 16,
                          child: GraphAnalysisView(
                            onClose: () =>
                                setState(() => _showAnalysis = false),
                            width: panelWidth,
                          ),
                        ),
                      ),
                    if (_showDijkstra && !isWide)
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: Material(
                          elevation: 16,
                          child: DijkstraPanel(
                            onClose: () {
                              setState(() => _showDijkstra = false);
                              context.read<GraphProvider>().clearDijkstra();
                            },
                            width: panelWidth,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, AppTheme theme, bool isDark) {
    final provider = context.read<GraphProvider>();

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              Icons.auto_graph_outlined,
              size: 18,
              color: ThemeColors.textBright(theme),
            ),
            const SizedBox(width: 8),
            Text(
              "Studio",
              style: TextStyle(
                color: ThemeColors.textBright(theme),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            // --- HISTORIQUE ---
            _ToolbarButton(
              icon: Icons.undo,
              tooltip: "Annuler",
              onPressed: provider.canUndo ? provider.undo : null,
              theme: theme,
            ),
            _ToolbarButton(
              icon: Icons.redo,
              tooltip: "Rétablir",
              onPressed: provider.canRedo ? provider.redo : null,
              theme: theme,
            ),
            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            // --- HISTORIQUE ---
            _ToolbarButton(
              icon: Icons.undo,
              tooltip: "Annuler",
              onPressed: provider.canUndo ? provider.undo : null,
              theme: theme,
              color: provider.canUndo
                  ? null
                  : ThemeColors.textMain(theme).withValues(alpha: 0.3),
            ),
            _ToolbarButton(
              icon: Icons.redo,
              tooltip: "Rétablir",
              onPressed: provider.canRedo ? provider.redo : null,
              theme: theme,
              color: provider.canRedo
                  ? null
                  : ThemeColors.textMain(theme).withValues(alpha: 0.3),
            ),
            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            // --- CRÉATION ---
            Draggable<String>(
              data: 'new_node',
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
              child: _ToolbarButton(
                icon: Icons.add_circle_outline,
                tooltip: "Sommet (Glisser)",
                onPressed: () => _showAddVertexDialog(context, provider),
                theme: theme,
              ),
            ),
            _ToolbarButton(
              icon: Icons.add_link_outlined,
              tooltip: "Arête",
              onPressed: () => _showAddEdgeDialog(context, provider),
              theme: theme,
            ),

            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            // --- ALGORITHMES ---
            PopupMenuButton<String>(
              tooltip: "Algorithmes",
              icon: Icon(
                Icons.psychology_outlined,
                size: 20,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
              ),
              onSelected: (val) => _handleAlgorithm(context, provider, val),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'bfs', child: Text("BFS (Largeur)")),
                const PopupMenuItem(
                  value: 'dfs',
                  child: Text("DFS (Profondeur)"),
                ),
                const PopupMenuItem(
                  value: 'dijkstra',
                  child: Text("Dijkstra (Chemin)"),
                ),
                const PopupMenuItem(
                  value: 'cycle',
                  child: Text("Détection Cycles"),
                ),
              ],
            ),

            // --- OUTILS ---
            PopupMenuButton<String>(
              tooltip: "Outils",
              icon: Icon(
                Icons.construction_outlined,
                size: 20,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.7),
              ),
              onSelected: (val) {
                if (val == 'random') provider.generateRandomGraph();
                if (val == 'reset') provider.clear();
                if (val == 'config') _showGraphConfigDialog(context, provider);
                if (val == 'auto') provider.runAutoLayout();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'random',
                  child: Text("Graphe Aléatoire"),
                ),
                const PopupMenuItem(
                  value: 'auto',
                  child: Text("Organisation Automatique"),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: Text("Tout Effacer"),
                ),
                const PopupMenuItem(
                  value: 'config',
                  child: Text("Configuration"),
                ),
              ],
            ),

            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            _ToolbarButton(
              icon: Icons.route_outlined,
              tooltip: "Dijkstra",
              onPressed: () {
                setState(() {
                  _showDijkstra = !_showDijkstra;
                  if (_showDijkstra) _showAnalysis = false;
                });
              },
              theme: theme,
              color: _showDijkstra ? ThemeColors.vscodeBlue : null,
            ),

            _ToolbarButton(
              icon: Icons.analytics_outlined,
              tooltip: "Analyse théorique",
              onPressed: () {
                setState(() {
                  _showAnalysis = !_showAnalysis;
                  if (_showAnalysis) _showDijkstra = false;
                });
              },
              theme: theme,
              color: _showAnalysis ? ThemeColors.vscodeBlue : null,
            ),

            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            _ToolbarButton(
              icon: Icons.zoom_in_outlined,
              tooltip: "Zoom +",
              onPressed: () => provider.zoomIn(),
              theme: theme,
            ),
            _ToolbarButton(
              icon: Icons.zoom_out_outlined,
              tooltip: "Zoom -",
              onPressed: () => provider.zoomOut(),
              theme: theme,
            ),
            _ToolbarButton(
              icon: Icons.center_focus_strong_outlined,
              tooltip: "Recentrer",
              onPressed: () => provider.resetView(),
              theme: theme,
            ),

            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            // --- LECTURE / ANIMATION ---
            if (provider.isExecuting) ...[
              _ToolbarButton(
                icon: provider.isPaused ? Icons.play_arrow : Icons.pause,
                tooltip: provider.isPaused ? "Reprendre" : "Pause",
                onPressed: () => provider.togglePause(),
                theme: theme,
                color: Colors.orange,
              ),
              _ToolbarButton(
                icon: Icons.stop,
                tooltip: "Arrêter",
                onPressed: () => provider.stopExecution(),
                theme: theme,
                color: Colors.red,
              ),
            ] else
              _ToolbarButton(
                icon: Icons.play_arrow,
                tooltip: "Exécuter BFS",
                onPressed: () {
                  if (provider.nodes.isNotEmpty) {
                    provider.runBFS(provider.nodes.first.id);
                  }
                },
                theme: theme,
                color: Colors.green,
              ),

            const VerticalDivider(indent: 12, endIndent: 12, width: 24),

            _ToolbarButton(
              icon: Icons.save_outlined,
              tooltip: "Sauvegarder (JSON)",
              onPressed: () {
                provider.exportContent();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Graphe sauvegardé")),
                );
              },
              theme: theme,
            ),
            _ToolbarButton(
              icon: Icons.image_outlined,
              tooltip: "Exporter PNG",
              onPressed: () => _canvasKey.currentState?.exportToPNG(),
              theme: theme,
            ),

            _ToolbarButton(
              icon: Icons.help_outline,
              tooltip: "Aide",
              onPressed: () => _showHelpDialog(context),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAlgorithm(
    BuildContext context,
    GraphProvider provider,
    String algo,
  ) async {
    if (provider.nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ajoutez au moins un sommet.")),
      );
      return;
    }
    final startId = provider.nodes.first.id;
    if (algo == 'bfs') provider.runBFS(startId);
    if (algo == 'dfs') provider.runDFS(startId);
    if (algo == 'dijkstra') provider.runDijkstraAnimation(startId);
    if (algo == 'cycle') {
      final hasCycle = await provider.detectCycle();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasCycle ? "Cycle détecté !" : "Aucun cycle détecté."),
          backgroundColor: hasCycle ? Colors.orange : null,
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aide Graph Studio"),
        content: const Text(
          "• Double-clic vide : Nouveau sommet\n"
          "• Glisser sommet : Déplacer\n"
          "• Appui long + Glisser : Nouvelle arête\n"
          "• Clic droit : Menu options (Renommer, Supprimer, etc.)",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  void _showAddVertexDialog(BuildContext context, GraphProvider provider) {
    final labelController = TextEditingController();
    final xController = TextEditingController(text: "100");
    final yController = TextEditingController(text: "100");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouveau Sommet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: "Label (ex: A)"),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: xController,
                    decoration: const InputDecoration(labelText: "X"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: yController,
                    decoration: const InputDecoration(labelText: "Y"),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              final x = double.tryParse(xController.text) ?? 100;
              final y = double.tryParse(yController.text) ?? 100;
              provider.addNode(Offset(x, y));
              if (labelController.text.isNotEmpty) {
                // Modifie le dernier noeud ajouté
                provider.updateNodeLabel(
                  provider.nodes.last.id,
                  labelController.text,
                );
              }
              Navigator.pop(context);
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  void _showAddEdgeDialog(BuildContext context, GraphProvider provider) {
    if (provider.nodes.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Il faut au moins 2 sommets pour créer une arête."),
        ),
      );
      return;
    }

    String? fromId = provider.nodes.first.id;
    String? toId = provider.nodes.last.id;
    final weightController = TextEditingController(
      text: provider.isWeighted ? "1.0" : "",
    );

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Nouvelle Arête"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fromId,
                decoration: const InputDecoration(labelText: "Source"),
                items: provider.nodes
                    .map(
                      (n) =>
                          DropdownMenuItem(value: n.id, child: Text(n.label)),
                    )
                    .toList(),
                onChanged: (val) => setStateDialog(() => fromId = val),
              ),
              DropdownButtonFormField<String>(
                value: toId,
                decoration: const InputDecoration(labelText: "Cible"),
                items: provider.nodes
                    .map(
                      (n) =>
                          DropdownMenuItem(value: n.id, child: Text(n.label)),
                    )
                    .toList(),
                onChanged: (val) => setStateDialog(() => toId = val),
              ),
              if (provider.isWeighted)
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(labelText: "Poids"),
                  keyboardType: TextInputType.number,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                if (fromId != null && toId != null) {
                  provider.addEdge(
                    fromId!,
                    toId!,
                    directed: provider.isDirected,
                  );
                  if (provider.isWeighted) {
                    final weight =
                        double.tryParse(weightController.text) ?? 1.0;
                    provider.updateEdgeWeight(provider.edges.last.id, weight);
                  }
                }
                Navigator.pop(context);
              },
              child: const Text("Créer"),
            ),
          ],
        ),
      ),
    );
  }

  void _showGraphConfigDialog(BuildContext context, GraphProvider provider) {
    bool isDirected = provider.isDirected;
    bool isWeighted = provider.isWeighted;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Configuration du Graphe"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text("Aligner sur la grille"),
                subtitle: const Text("Magnétisme des sommets"),
                value: provider.snapToGrid,
                onChanged: (val) {
                  provider.setGraphSettings(snapToGrid: val);
                  setStateDialog(() {});
                },
              ),
              SwitchListTile(
                title: const Text("Graphe Orienté"),
                subtitle: const Text("Par défaut pour les nouvelles arêtes"),
                value: isDirected,
                onChanged: (val) => setStateDialog(() => isDirected = val),
              ),
              SwitchListTile(
                title: const Text("Graphe Pondéré"),
                subtitle: const Text("Affiche et permet de modifier les poids"),
                value: isWeighted,
                onChanged: (val) => setStateDialog(() => isWeighted = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () {
                provider.setGraphSettings(
                  isDirected: isDirected,
                  isWeighted: isWeighted,
                );
                Navigator.pop(context);
              },
              child: const Text("Valider"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppTheme theme;
  final Color? color;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,

    required this.theme,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color ?? ThemeColors.textMain(theme).withValues(alpha: 0.7),
        onPressed: onPressed,
      ),
    );
  }
}
