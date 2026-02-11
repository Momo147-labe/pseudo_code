import 'dart:math' as math;
import 'package:pseudo_code/models/graph/graph_models.dart';

class GraphAnalysisService {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool isDirected;
  final Set<String>? selectedNodeIds; // [NEW]

  GraphAnalysisService({
    required this.nodes,
    required this.edges,
    required this.isDirected,
    this.selectedNodeIds,
  });

  /// 1. Propriétés de base
  int get order => nodes.length;
  int get size => edges.length;

  double get density {
    int n = nodes.length;
    if (n <= 1) return 0;
    int m = edges.length;
    if (isDirected) {
      return m / (n * (n - 1));
    } else {
      return (2 * m) / (n * (n - 1));
    }
  }

  List<GraphNode> get isolatedNodes {
    return nodes.where((node) {
      return !edges.any((e) => e.fromId == node.id || e.toId == node.id);
    }).toList();
  }

  bool get isSimple {
    if (edges.any((e) => e.fromId == e.toId)) return false;
    for (int i = 0; i < edges.length; i++) {
      for (int j = i + 1; j < edges.length; j++) {
        final e1 = edges[i];
        final e2 = edges[j];
        if (isDirected) {
          if (e1.fromId == e2.fromId && e1.toId == e2.toId) return false;
        } else {
          if ((e1.fromId == e2.fromId && e1.toId == e2.toId) ||
              (e1.fromId == e2.toId && e1.toId == e2.fromId))
            return false;
        }
      }
    }
    return true;
  }

  /// 2. Degrés et Voisinages
  Map<String, int> getOutDegrees() {
    Map<String, int> degrees = {for (var n in nodes) n.id: 0};
    for (var e in edges) {
      degrees[e.fromId] = (degrees[e.fromId] ?? 0) + 1;
      if (!isDirected && e.fromId != e.toId) {
        degrees[e.toId] = (degrees[e.toId] ?? 0) + 1;
      }
    }
    return degrees;
  }

  Map<String, int> getInDegrees() {
    if (!isDirected) return getOutDegrees();
    Map<String, int> degrees = {for (var n in nodes) n.id: 0};
    for (var e in edges) {
      degrees[e.toId] = (degrees[e.toId] ?? 0) + 1;
    }
    return degrees;
  }

  Map<String, List<String>> getAdjacencyList() {
    Map<String, List<String>> list = {for (var n in nodes) n.id: []};
    for (var e in edges) {
      list[e.fromId]!.add(e.toId);
      if (!isDirected && e.fromId != e.toId) {
        list[e.toId]!.add(e.fromId);
      }
    }
    return list;
  }

  /// 3. Matrices
  List<List<int>> getAdjacencyMatrix() {
    int n = nodes.length;
    List<List<int>> matrix = List.generate(n, (_) => List.filled(n, 0));
    final nodeToIndex = {for (int i = 0; i < n; i++) nodes[i].id: i};

    for (var e in edges) {
      int i = nodeToIndex[e.fromId]!;
      int j = nodeToIndex[e.toId]!;
      matrix[i][j]++;
      if (!isDirected && i != j) {
        matrix[j][i]++;
      }
    }
    return matrix;
  }

  List<List<int>> getIncidenceMatrix() {
    int n = nodes.length;
    int m = edges.length;
    if (m == 0) return [];
    List<List<int>> matrix = List.generate(n, (_) => List.filled(m, 0));
    final nodeToIndex = {for (int i = 0; i < n; i++) nodes[i].id: i};

    for (int k = 0; k < m; k++) {
      final e = edges[k];
      int i = nodeToIndex[e.fromId]!;
      int j = nodeToIndex[e.toId]!;
      if (isDirected) {
        matrix[i][k] = -1; // Sortant
        matrix[j][k] = 1; // Entrant
        if (i == j) matrix[i][k] = 2; // Boucle
      } else {
        matrix[i][k] = 1;
        matrix[j][k] = 1;
      }
    }
    return matrix;
  }

  List<List<int>> getDegreeMatrix() {
    int n = nodes.length;
    List<List<int>> matrix = List.generate(n, (_) => List.filled(n, 0));
    final outDegrees = getOutDegrees();
    final inDegrees = getInDegrees();

    for (int i = 0; i < n; i++) {
      String id = nodes[i].id;
      if (isDirected) {
        matrix[i][i] = (outDegrees[id] ?? 0) + (inDegrees[id] ?? 0);
      } else {
        matrix[i][i] = outDegrees[id] ?? 0;
      }
    }
    return matrix;
  }

  /// 4. Distances (Floyd-Warshall)
  List<List<double>> getDistanceMatrix() {
    int n = nodes.length;
    List<List<double>> dist = List.generate(
      n,
      (_) => List.filled(n, double.infinity),
    );
    final nodeToIndex = {for (int i = 0; i < n; i++) nodes[i].id: i};

    for (int i = 0; i < n; i++) dist[i][i] = 0;

    for (var e in edges) {
      int u = nodeToIndex[e.fromId]!;
      int v = nodeToIndex[e.toId]!;
      dist[u][v] = math.min(dist[u][v], 1.0); // Simple distance hop
      if (!isDirected) {
        dist[v][u] = math.min(dist[v][u], 1.0);
      }
    }

    for (int k = 0; k < n; k++) {
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
          if (dist[i][k] != double.infinity && dist[k][j] != double.infinity) {
            dist[i][j] = math.min(dist[i][j], dist[i][k] + dist[k][j]);
          }
        }
      }
    }
    return dist;
  }

  Map<String, double> getEccentricities() {
    int n = nodes.length;
    final distMatrix = getDistanceMatrix();
    Map<String, double> ecc = {};

    for (int i = 0; i < n; i++) {
      double maxDist = 0;
      for (int j = 0; j < n; j++) {
        if (distMatrix[i][j] > maxDist) maxDist = distMatrix[i][j];
      }
      ecc[nodes[i].id] = maxDist;
    }
    return ecc;
  }

  double get diameter {
    final ecc = getEccentricities().values;
    if (ecc.isEmpty) return 0;
    double max = 0;
    for (var e in ecc) if (e > max) max = e;
    return max;
  }

  double get radius {
    final ecc = getEccentricities().values;
    if (ecc.isEmpty) return 0;
    double min = double.infinity;
    for (var e in ecc) if (e < min) min = e;
    return min == double.infinity ? 0 : min;
  }

  List<String> get center {
    final ecc = getEccentricities();
    double r = radius;
    return ecc.entries
        .where((entry) => entry.value == r)
        .map((entry) => entry.key)
        .toList();
  }

  /// 5. Connectivité
  List<List<String>> getStronglyConnectedComponents() {
    int n = nodes.length;
    if (n == 0) return [];

    int index = 0;
    List<int> dfn = List.filled(n, -1);
    List<int> low = List.filled(n, -1);
    List<int> stack = [];
    List<bool> onStack = List.filled(n, false);
    List<List<String>> components = [];

    final nodeToIndex = {for (int i = 0; i < n; i++) nodes[i].id: i};
    final adj = getAdjacencyList();

    void tarjan(int u) {
      dfn[u] = low[u] = index++;
      stack.add(u);
      onStack[u] = true;

      final neighbors = adj[nodes[u].id] ?? [];
      for (var vId in neighbors) {
        int v = nodeToIndex[vId]!;
        if (dfn[v] == -1) {
          tarjan(v);
          low[u] = math.min(low[u], low[v]);
        } else if (onStack[v]) {
          low[u] = math.min(low[u], dfn[v]);
        }
      }

      if (low[u] == dfn[u]) {
        List<String> component = [];
        int v;
        do {
          v = stack.removeLast();
          onStack[v] = false;
          component.add(nodes[v].id);
        } while (u != v);
        components.add(component);
      }
    }

    for (int i = 0; i < n; i++) {
      if (dfn[i] == -1) tarjan(i);
    }
    return components;
  }

  bool isStronglyConnected() {
    if (nodes.isEmpty) return true;
    return getStronglyConnectedComponents().length == 1 && isConnected();
  }

  bool isConnected() {
    if (nodes.isEmpty) return true;
    Set<String> visited = {};
    List<String> queue = [nodes.first.id];
    visited.add(nodes.first.id);

    final allAdj = <String, Set<String>>{};
    for (var e in edges) {
      allAdj.putIfAbsent(e.fromId, () => {}).add(e.toId);
      allAdj.putIfAbsent(e.toId, () => {}).add(e.fromId);
    }

    while (queue.isNotEmpty) {
      String u = queue.removeAt(0);
      for (var v in (allAdj[u] ?? {})) {
        if (!visited.contains(v)) {
          visited.add(v);
          queue.add(v);
        }
      }
    }
    return visited.length == nodes.length;
  }

  List<List<String>> getConnectedComponents() {
    if (nodes.isEmpty) return [];

    List<List<String>> components = [];
    Set<String> visited = {};

    final allAdj = <String, Set<String>>{};
    for (var e in edges) {
      allAdj.putIfAbsent(e.fromId, () => {}).add(e.toId);
      allAdj.putIfAbsent(e.toId, () => {}).add(e.fromId);
    }

    for (var node in nodes) {
      if (!visited.contains(node.id)) {
        List<String> component = [];
        List<String> queue = [node.id];
        visited.add(node.id);

        while (queue.isNotEmpty) {
          String u = queue.removeAt(0);
          component.add(u);
          for (var v in (allAdj[u] ?? {})) {
            if (!visited.contains(v)) {
              visited.add(v);
              queue.add(v);
            }
          }
        }
        components.add(component);
      }
    }
    return components;
  }

  /// 6. Cycles et Topologie
  int get cyclomaticNumber {
    int n = nodes.length;
    int m = edges.length;
    if (n == 0) return 0;

    int p = 0;
    Set<String> visited = {};
    final allAdj = <String, Set<String>>{};
    for (var e in edges) {
      allAdj.putIfAbsent(e.fromId, () => {}).add(e.toId);
      allAdj.putIfAbsent(e.toId, () => {}).add(e.fromId);
    }

    for (var node in nodes) {
      if (!visited.contains(node.id)) {
        p++;
        List<String> q = [node.id];
        visited.add(node.id);
        while (q.isNotEmpty) {
          String u = q.removeAt(0);
          for (var v in (allAdj[u] ?? {})) {
            if (!visited.contains(v)) {
              visited.add(v);
              q.add(v);
            }
          }
        }
      }
    }
    return m - n + p;
  }

  bool isBipartite() {
    if (nodes.isEmpty) return true;
    Map<String, int> colors = {};
    final adj = getAdjacencyList();

    for (var node in nodes) {
      if (!colors.containsKey(node.id)) {
        List<String> q = [node.id];
        colors[node.id] = 0;
        while (q.isNotEmpty) {
          String u = q.removeAt(0);
          for (var v in (adj[u] ?? [])) {
            if (!colors.containsKey(v)) {
              colors[v] = 1 - colors[u]!;
              q.add(v);
            } else if (colors[v] == colors[u]) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  /// 7. Représentation formelle (Dictionnaire)
  Map<String, dynamic> getDictionary() {
    return {
      "ordre": order,
      "taille": size,
      "sommets": nodes.map((n) => n.label).toList(),
      "aretes": edges.map((e) {
        final from = nodes.firstWhere((n) => n.id == e.fromId).label;
        final to = nodes.firstWhere((n) => n.id == e.toId).label;
        return "$from${isDirected ? '->' : '-'}$to (w:${e.weight})";
      }).toList(),
    };
  }

  /// 8. Sous-graphe induit (basé sur la sélection)
  bool get hasSelection =>
      selectedNodeIds != null && selectedNodeIds!.isNotEmpty;

  int get subgraphOrder => selectedNodeIds?.length ?? 0;

  int get subgraphSize {
    if (!hasSelection) return 0;
    return edges
        .where(
          (e) =>
              selectedNodeIds!.contains(e.fromId) &&
              selectedNodeIds!.contains(e.toId),
        )
        .length;
  }

  /// 9. Cycles - Recherche de base de cycles fondamentaux
  List<List<String>> getCycleBasis() {
    if (nodes.isEmpty) return [];

    // Pour simplifier, on traite ça comme un graphe non-orienté pour trouver le cycle basis
    Set<String> visited = {};
    Map<String, String?> parent = {};
    List<List<String>> cycles = [];

    void dfs(String u, String? p) {
      visited.add(u);
      parent[u] = p;
      final adj = getAdjacencyList();
      for (var v in (adj[u] ?? [])) {
        if (v == p) continue;
        if (visited.contains(v)) {
          // Cycle trouvé (back-edge)
          List<String> cycle = [v];
          String? curr = u;
          while (curr != null && curr != v) {
            cycle.add(curr);
            curr = parent[curr];
          }
          if (curr == v) {
            // Vérifier si ce cycle n'est pas déjà dans la base (naïf)
            cycles.add(cycle);
          }
        } else {
          dfs(v, u);
        }
      }
    }

    for (var node in nodes) {
      if (!visited.contains(node.id)) dfs(node.id, null);
    }

    return cycles;
  }

  /// Vecteur binaire associé à un cycle
  List<int> getCycleVector(List<String> cycleNodeIds) {
    List<int> vector = List.filled(edges.length, 0);
    for (int i = 0; i < edges.length; i++) {
      final e = edges[i];
      // On vérifie si l'arête (ou sa reverse si non-orienté) est dans le cycle
      for (int j = 0; j < cycleNodeIds.length; j++) {
        String u = cycleNodeIds[j];
        String v = cycleNodeIds[(j + 1) % cycleNodeIds.length];
        if (isDirected) {
          if (e.fromId == u && e.toId == v) vector[i] = 1;
        } else {
          if ((e.fromId == u && e.toId == v) ||
              (e.fromId == v && e.toId == u)) {
            vector[i] = 1;
          }
        }
      }
    }
    return vector;
  }
}
