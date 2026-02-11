import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pseudo_code/providers/graph_provider.dart';
import 'package:pseudo_code/providers/theme_provider.dart';
import 'package:pseudo_code/theme.dart';
import 'package:pseudo_code/services/graph/graph_analysis.dart';

class GraphAnalysisView extends StatelessWidget {
  final VoidCallback onClose;
  final double width;

  const GraphAnalysisView({super.key, required this.onClose, this.width = 420});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GraphProvider>();
    final theme = context.watch<ThemeProvider>().currentTheme;
    final isDark = theme == AppTheme.dark;

    final analysis = GraphAnalysisService(
      nodes: provider.nodes,
      edges: provider.edges,
      isDirected: provider.isDirected,
      selectedNodeIds: provider.selectedNodeIds,
    );

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: ThemeColors.sidebarBg(theme),
        border: Border(
          left: BorderSide(
            color: isDark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: DefaultTabController(
        length: 6,
        child: Column(
          children: [
            _buildHeader(context, theme, onClose),
            TabBar(
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              labelColor: ThemeColors.vscodeBlue,
              unselectedLabelColor: ThemeColors.textMain(
                theme,
              ).withValues(alpha: 0.5),
              indicatorColor: ThemeColors.vscodeBlue,
              tabs: const [
                Tab(text: "Résumé"),
                Tab(text: "Sommets"),
                Tab(text: "Matrices"),
                Tab(text: "Distances"),
                Tab(text: "Cycles"),
                Tab(text: "Listes"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(analysis: analysis, theme: theme),
                  _NodesTab(analysis: analysis, theme: theme),
                  _MatricesTab(analysis: analysis, theme: theme),
                  _DistancesTab(analysis: analysis, theme: theme),
                  _CyclesTab(analysis: analysis, theme: theme),
                  _ListsTab(analysis: analysis, theme: theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppTheme theme,
    VoidCallback onClose,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme == AppTheme.dark
                ? Colors.white12
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 20,
                color: ThemeColors.vscodeBlue,
              ),
              const SizedBox(width: 12),
              Text(
                "Analyse du Graphe",
                style: TextStyle(
                  color: ThemeColors.textBright(theme),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final GraphAnalysisService analysis;
  final AppTheme theme;

  const _OverviewTab({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard("Propriétés Globales", [
          _buildRow("Ordre (n)", "${analysis.order}"),
          _buildRow("Taille (m)", "${analysis.size}"),
          _buildRow("Densité", analysis.density.toStringAsFixed(3)),
          _buildRow("Type", analysis.isDirected ? "Orienté" : "Non-orienté"),
          _buildRow("Structure", analysis.isSimple ? "Simple" : "Multiple"),
          _buildRow("Biparti", analysis.isBipartite() ? "Oui" : "Non"),
          _buildRow("Nombre Cyclomatique", "${analysis.cyclomaticNumber}"),
        ]),
        const SizedBox(height: 16),
        if (analysis.hasSelection) ...[
          _buildInfoCard("Sous-graphe Induit (Sélection)", [
            _buildRow("Ordre (n')", "${analysis.subgraphOrder}"),
            _buildRow("Taille (m')", "${analysis.subgraphSize}"),
          ]),
          const SizedBox(height: 16),
        ],
        _buildInfoCard("Connectivité", [
          _buildRow("Connexe", analysis.isConnected() ? "Oui" : "Non"),
          if (analysis.isDirected)
            _buildRow(
              "Fortement Connexe",
              analysis.isStronglyConnected() ? "Oui" : "Non",
            ),
          _buildRow(
            "Nombre de Composantes",
            "${analysis.getConnectedComponents().length}",
          ),
          const SizedBox(height: 8),
          Text(
            "Détail des composantes :",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
            ),
          ),
          ...analysis.getConnectedComponents().asMap().entries.map((entry) {
            final nodes = entry.value
                .map((id) => analysis.nodes.firstWhere((n) => n.id == id).label)
                .join(', ');
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "• G${entry.key + 1}: { $nodes }",
                style: TextStyle(
                  fontSize: 11,
                  color: ThemeColors.textMain(theme),
                ),
              ),
            );
          }),
        ]),
        const SizedBox(height: 16),
        _buildInfoCard("Sommets Spéciaux", [
          _buildRow("Isolés", "${analysis.isolatedNodes.length}"),
          if (analysis.isolatedNodes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Sommets sans liens: ${analysis.isolatedNodes.map((n) => n.label).join(', ')}",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orangeAccent.withValues(alpha: 0.8),
                ),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.blueAccent,
          ),
        ),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: ThemeColors.textMain(theme)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: ThemeColors.textBright(theme),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodesTab extends StatelessWidget {
  final GraphAnalysisService analysis;
  final AppTheme theme;

  const _NodesTab({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    final inDegrees = analysis.getInDegrees();
    final outDegrees = analysis.getOutDegrees();
    final ecc = analysis.getEccentricities();
    final adj = analysis.getAdjacencyList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: analysis.nodes.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        final node = analysis.nodes[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sommet ${node.label} ${analysis.selectedNodeIds?.contains(node.id) == true ? '★' : ''}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildBadge("d⁻: ${inDegrees[node.id]}", Colors.green),
                const SizedBox(width: 8),
                _buildBadge("d⁺: ${outDegrees[node.id]}", Colors.orange),
                const SizedBox(width: 8),
                _buildBadge(
                  "Ecc: ${ecc[node.id]?.toStringAsFixed(0)}",
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Voisinage sortant: { ${adj[node.id]?.map((id) => analysis.nodes.firstWhere((n) => n.id == id).label).join(', ') ?? ''} }",
              style: TextStyle(
                fontSize: 11,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MatricesTab extends StatelessWidget {
  final GraphAnalysisService analysis;
  final AppTheme theme;

  const _MatricesTab({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMatrixView(
          "Matrice d'Adjacence (A)",
          analysis.getAdjacencyMatrix(),
        ),
        const SizedBox(height: 24),
        _buildMatrixView(
          "Matrice d'Incidence (M)",
          analysis.getIncidenceMatrix(),
        ),
        const SizedBox(height: 24),
        _buildMatrixView("Matrice de Degré (D)", analysis.getDegreeMatrix()),
      ],
    );
  }

  Widget _buildMatrixView(String title, List<List<int>> matrix) {
    if (matrix.isEmpty) {
      return Text(
        title + ": [ ]",
        style: TextStyle(
          color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: ThemeColors.textBright(theme),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeColors.textMain(theme).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: matrix.map((row) {
                return Row(
                  children: row.map((val) {
                    return Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Text(
                        "$val",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: ThemeColors.syntaxNumber(theme),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CyclesTab extends StatelessWidget {
  final GraphAnalysisService analysis;
  final AppTheme theme;

  const _CyclesTab({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    final cycles = analysis.getCycleBasis();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Base des Cycles Fondamentaux (${cycles.length})",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: ThemeColors.syntaxKeyword(theme),
          ),
        ),
        Divider(color: ThemeColors.textMain(theme).withValues(alpha: 0.1)),
        if (cycles.isEmpty)
          Text(
            "Aucun cycle détecté.",
            style: TextStyle(
              fontSize: 12,
              color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
            ),
          )
        else
          ...List.generate(cycles.length, (i) {
            final cycle = cycles[i];
            final labels = cycle
                .map((id) => analysis.nodes.firstWhere((n) => n.id == id).label)
                .join(' - ');
            final vector = analysis.getCycleVector(cycle);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Cycle $i: [ $labels - ${analysis.nodes.firstWhere((n) => n.id == cycle.first).label} ]",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.textBright(theme),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Vecteur associé (arêtes):",
                    style: TextStyle(
                      fontSize: 10,
                      color: ThemeColors.textMain(theme).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ThemeColors.textMain(
                        theme,
                      ).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      vector.toString(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: ThemeColors.syntaxIO(theme),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _DistancesTab extends StatelessWidget {
  final GraphAnalysisService analysis;
  final AppTheme theme;

  const _DistancesTab({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    final distMatrix = analysis.getDistanceMatrix();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Matrice des Distances",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: ThemeColors.textBright(theme),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ThemeColors.textMain(theme).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 32),
                    ...analysis.nodes.map(
                      (n) => Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Text(
                          n.label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.syntaxKeyword(theme),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                ...List.generate(analysis.nodes.length, (i) {
                  return Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        child: Text(
                          analysis.nodes[i].label,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.syntaxKeyword(theme),
                            fontSize: 10,
                          ),
                        ),
                      ),
                      ...List.generate(analysis.nodes.length, (j) {
                        final d = distMatrix[i][j];
                        return Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: Text(
                            d == double.infinity ? "∞" : d.toInt().toString(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: d == 0
                                  ? ThemeColors.textMain(
                                      theme,
                                    ).withValues(alpha: 0.3)
                                  : ThemeColors.syntaxNumber(theme),
                            ),
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ListsTab extends StatelessWidget {
  final GraphAnalysisService analysis;
  final AppTheme theme;

  const _ListsTab({required this.analysis, required this.theme});

  @override
  Widget build(BuildContext context) {
    final adj = analysis.getAdjacencyList();
    final dict = analysis.getDictionary();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          "Liste d'Adjacence",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: ThemeColors.syntaxKeyword(theme),
          ),
        ),
        Divider(color: ThemeColors.textMain(theme).withValues(alpha: 0.1)),
        ...analysis.nodes.map((node) {
          final neighbors =
              adj[node.id]
                  ?.map(
                    (id) => analysis.nodes.firstWhere((n) => n.id == id).label,
                  )
                  .join(', ') ??
              '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
                ),
                children: [
                  TextSpan(
                    text: "${node.label} : ",
                    style: TextStyle(color: ThemeColors.syntaxString(theme)),
                  ),
                  TextSpan(text: "{ $neighbors }"),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        Text(
          "Dictionnaire des Arêtes",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: ThemeColors.syntaxKeyword(theme),
          ),
        ),
        Divider(color: ThemeColors.textMain(theme).withValues(alpha: 0.1)),
        ...(dict['aretes'] as List).map((edgeStr) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              edgeStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: ThemeColors.textMain(theme).withValues(alpha: 0.8),
              ),
            ),
          );
        }),
      ],
    );
  }
}
