import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudo_code/providers/graph_provider.dart';
import 'package:pseudo_code/providers/theme_provider.dart';
import 'package:pseudo_code/theme.dart';
import 'package:pseudo_code/services/graph/dijkstra_service.dart';

class DijkstraPanel extends StatefulWidget {
  final VoidCallback onClose;
  final double width;

  const DijkstraPanel({super.key, required this.onClose, this.width = 450});

  @override
  State<DijkstraPanel> createState() => _DijkstraPanelState();
}

class _DijkstraPanelState extends State<DijkstraPanel> {
  String? _sourceId;
  String? _targetId;
  bool _calculateAllDistances = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GraphProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final result = provider.dijkstraResult;

    // Validation des IDs sélectionnés pour éviter le crash du DropdownButton
    // si un nœud a été supprimé
    if (_sourceId != null && !provider.nodes.any((n) => n.id == _sourceId)) {
      _sourceId = null;
    }
    if (_targetId != null && !provider.nodes.any((n) => n.id == _targetId)) {
      _targetId = null;
    }

    return Container(
      width: widget.width,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          left: BorderSide(
            color: ThemeColors.textMain(theme).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSelector(
                  'Sommet de départ',
                  _sourceId,
                  provider.nodes,
                  (id) => setState(() => _sourceId = id),
                  theme,
                ),
                const SizedBox(height: 16),
                _buildCalculateAllCheckbox(theme),
                if (!_calculateAllDistances) ...[
                  const SizedBox(height: 16),
                  _buildSelector(
                    'Sommet d\'arrivée',
                    _targetId,
                    provider.nodes,
                    (id) => setState(() => _targetId = id),
                    theme,
                  ),
                ],
                const SizedBox(height: 20),
                _buildRunButton(provider, theme),
                if (result != null) ...[
                  const SizedBox(height: 20),
                  _buildResults(result, provider, theme),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ThemeColors.textMain(theme).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.route, size: 20, color: ThemeColors.vscodeBlue),
              const SizedBox(width: 12),
              Text(
                'Dijkstra',
                style: TextStyle(
                  color: ThemeColors.textBright(theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(
    String label,
    String? selectedId,
    List nodes,
    Function(String?) onChanged,
    AppTheme theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ThemeColors.textMain(theme),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: ThemeColors.editorBg(theme),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
            ),
          ),
          child: DropdownButton<String>(
            value: selectedId,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              'Sélectionner un sommet',
              style: TextStyle(
                color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
              ),
            ),
            dropdownColor: ThemeColors.sidebarBg(theme),
            style: TextStyle(color: ThemeColors.textBright(theme)),
            items: nodes.map((node) {
              return DropdownMenuItem<String>(
                value: node.id,
                child: Text(node.label),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateAllCheckbox(AppTheme theme) {
    return Row(
      children: [
        Checkbox(
          value: _calculateAllDistances,
          onChanged: (value) {
            setState(() {
              _calculateAllDistances = value ?? false;
              if (_calculateAllDistances) {
                _targetId = null;
              }
            });
          },
          activeColor: ThemeColors.vscodeBlue,
        ),
        Expanded(
          child: Text(
            'Calculer vers tous les sommets',
            style: TextStyle(fontSize: 13, color: ThemeColors.textMain(theme)),
          ),
        ),
      ],
    );
  }

  Widget _buildRunButton(GraphProvider provider, AppTheme theme) {
    final canRun =
        _sourceId != null && (_calculateAllDistances || _targetId != null);

    return ElevatedButton.icon(
      onPressed: canRun
          ? () {
              try {
                provider.runDijkstra(
                  _sourceId!,
                  targetId: _calculateAllDistances ? null : _targetId,
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
              }
            }
          : null,
      icon: const Icon(Icons.play_arrow, size: 18),
      label: const Text('Exécuter'),
      style: ElevatedButton.styleFrom(
        backgroundColor: ThemeColors.vscodeBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 40),
      ),
    );
  }

  Widget _buildResults(
    DijkstraResult result,
    GraphProvider provider,
    AppTheme theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultHeader(result, theme),
        const SizedBox(height: 16),
        if (result.hasTarget) _buildPathInfo(result, provider, theme),
        const SizedBox(height: 16),
        _buildStepsTable(result, provider, theme),
      ],
    );
  }

  Widget _buildResultHeader(DijkstraResult result, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors.vscodeBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ThemeColors.vscodeBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: ThemeColors.vscodeBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.hasTarget
                  ? 'Chemin optimal trouvé'
                  : 'Distances calculées (${result.distances.length} sommets)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeColors.textBright(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathInfo(
    DijkstraResult result,
    GraphProvider provider,
    AppTheme theme,
  ) {
    final path = result.shortestPath ?? [];
    final pathLabels = path
        .map((id) => provider.nodes.firstWhere((n) => n.id == id).label)
        .join(' → ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors.textMain(theme).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chemin :',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            path.isEmpty ? 'Aucun chemin trouvé' : pathLabels,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: ThemeColors.syntaxNumber(theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coût total : ${result.pathCost?.toInt() ?? '∞'}',
            style: TextStyle(fontSize: 12, color: ThemeColors.textMain(theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsTable(
    DijkstraResult result,
    GraphProvider provider,
    AppTheme theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tableau des étapes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: ThemeColors.textBright(theme),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ThemeColors.editorBg(theme),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ThemeColors.textMain(theme).withValues(alpha: 0.2),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(
                ThemeColors.textMain(theme).withValues(alpha: 0.05),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Itér.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.textBright(theme),
                      fontSize: 11,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Actuel',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.textBright(theme),
                      fontSize: 11,
                    ),
                  ),
                ),
                ...provider.nodes.map((node) {
                  return DataColumn(
                    label: Text(
                      node.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ThemeColors.syntaxKeyword(theme),
                        fontSize: 11,
                      ),
                    ),
                  );
                }),
                DataColumn(
                  label: Text(
                    'Visités',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.textBright(theme),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
              rows: result.steps.map((step) {
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${step.iteration}',
                        style: TextStyle(
                          color: ThemeColors.textMain(theme),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        provider.nodes
                            .firstWhere((n) => n.id == step.currentNode)
                            .label,
                        style: TextStyle(
                          color: ThemeColors.syntaxNumber(theme),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    ...provider.nodes.map((node) {
                      final dist = step.distances[node.id] ?? double.infinity;
                      final pred = step.predecessors[node.id];
                      final isVisited = step.visited.contains(node.id);

                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isVisited
                                ? ThemeColors.syntaxIO(
                                    theme,
                                  ).withValues(alpha: 0.1)
                                : null,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            dist == double.infinity
                                ? '∞'
                                : pred != null
                                ? '${dist.toInt()} (${provider.nodes.firstWhere((n) => n.id == pred).label})'
                                : '${dist.toInt()}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: ThemeColors.textMain(theme),
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        '{${step.visited.map((id) => provider.nodes.firstWhere((n) => n.id == id).label).join(',')}}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: ThemeColors.textMain(
                            theme,
                          ).withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
