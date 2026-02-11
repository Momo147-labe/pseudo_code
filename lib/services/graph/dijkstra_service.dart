import 'package:pseudo_code/models/graph/graph_models.dart';

/// Représente une étape de l'algorithme pour le tableau
class DijkstraStep {
  final int iteration;
  final String currentNode;
  final Map<String, double> distances;
  final Map<String, String?> predecessors;
  final Set<String> visited;
  final Set<String> unvisited;

  DijkstraStep({
    required this.iteration,
    required this.currentNode,
    required this.distances,
    required this.predecessors,
    required this.visited,
    required this.unvisited,
  });

  DijkstraStep copyWith({
    int? iteration,
    String? currentNode,
    Map<String, double>? distances,
    Map<String, String?>? predecessors,
    Set<String>? visited,
    Set<String>? unvisited,
  }) {
    return DijkstraStep(
      iteration: iteration ?? this.iteration,
      currentNode: currentNode ?? this.currentNode,
      distances: distances ?? this.distances,
      predecessors: predecessors ?? this.predecessors,
      visited: visited ?? this.visited,
      unvisited: unvisited ?? this.unvisited,
    );
  }
}

/// Résultat final de l'algorithme
class DijkstraResult {
  final String sourceId;
  final String? targetId;
  final Map<String, double> distances;
  final Map<String, String?> predecessors;
  final List<DijkstraStep> steps;
  final List<String>? shortestPath; // null si pas de cible
  final double? pathCost; // null si pas de cible

  DijkstraResult({
    required this.sourceId,
    this.targetId,
    required this.distances,
    required this.predecessors,
    required this.steps,
    this.shortestPath,
    this.pathCost,
  });

  bool get hasTarget => targetId != null;

  DijkstraResult copyWith({
    String? sourceId,
    String? targetId,
    Map<String, double>? distances,
    Map<String, String?>? predecessors,
    List<DijkstraStep>? steps,
    List<String>? shortestPath,
    double? pathCost,
  }) {
    return DijkstraResult(
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      distances: distances ?? this.distances,
      predecessors: predecessors ?? this.predecessors,
      steps: steps ?? this.steps,
      shortestPath: shortestPath ?? this.shortestPath,
      pathCost: pathCost ?? this.pathCost,
    );
  }
}

/// Service pour exécuter l'algorithme de Dijkstra
class DijkstraService {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  DijkstraService({required this.nodes, required this.edges});

  /// Lance Dijkstra depuis [sourceId]
  /// Si [targetId] est fourni : cherche le plus court chemin source→target
  /// Sinon : calcule les distances vers TOUS les nœuds
  DijkstraResult run(String sourceId, {String? targetId}) {
    // Validation
    if (!nodes.any((n) => n.id == sourceId)) {
      throw Exception('Source node not found: $sourceId');
    }
    if (targetId != null && !nodes.any((n) => n.id == targetId)) {
      throw Exception('Target node not found: $targetId');
    }
    if (targetId == sourceId) {
      throw Exception('Source and target cannot be the same node');
    }

    // Initialisation
    final distances = <String, double>{};
    final predecessors = <String, String?>{};
    final visited = <String>{};
    final unvisited = <String>{};
    final steps = <DijkstraStep>[];

    for (final node in nodes) {
      distances[node.id] = double.infinity;
      predecessors[node.id] = null;
      unvisited.add(node.id);
    }
    distances[sourceId] = 0;

    // Étape initiale
    steps.add(
      DijkstraStep(
        iteration: 0,
        currentNode: sourceId,
        distances: Map.from(distances),
        predecessors: Map.from(predecessors),
        visited: Set.from(visited),
        unvisited: Set.from(unvisited),
      ),
    );

    int iteration = 1;

    // Boucle principale
    while (unvisited.isNotEmpty) {
      // Trouver le nœud non visité avec la plus petite distance
      String? current;
      double minDist = double.infinity;
      for (final nodeId in unvisited) {
        if (distances[nodeId]! < minDist) {
          minDist = distances[nodeId]!;
          current = nodeId;
        }
      }

      if (current == null || distances[current] == double.infinity) {
        break; // Graphe non connexe
      }

      // Marquer comme visité
      visited.add(current);
      unvisited.remove(current);

      // Si on cherche une cible et qu'on l'a atteinte : arrêt
      if (targetId != null && current == targetId) {
        steps.add(
          DijkstraStep(
            iteration: iteration++,
            currentNode: current,
            distances: Map.from(distances),
            predecessors: Map.from(predecessors),
            visited: Set.from(visited),
            unvisited: Set.from(unvisited),
          ),
        );
        break;
      }

      // Relâcher les arêtes sortantes
      final outgoingEdges = edges.where((e) => e.fromId == current);
      for (final edge in outgoingEdges) {
        if (visited.contains(edge.toId)) continue;

        final alt = distances[current]! + edge.weight;
        if (alt < distances[edge.toId]!) {
          distances[edge.toId] = alt;
          predecessors[edge.toId] = current;
        }
      }

      // Enregistrer l'étape
      steps.add(
        DijkstraStep(
          iteration: iteration++,
          currentNode: current,
          distances: Map.from(distances),
          predecessors: Map.from(predecessors),
          visited: Set.from(visited),
          unvisited: Set.from(unvisited),
        ),
      );
    }

    // Construire le chemin si cible fournie
    List<String>? path;
    double? cost;
    if (targetId != null) {
      path = _buildPath(predecessors, sourceId, targetId);
      cost = distances[targetId] == double.infinity
          ? null
          : distances[targetId];
    }

    return DijkstraResult(
      sourceId: sourceId,
      targetId: targetId,
      distances: distances,
      predecessors: predecessors,
      steps: steps,
      shortestPath: path,
      pathCost: cost,
    );
  }

  /// Reconstruit le chemin depuis les prédécesseurs
  List<String> _buildPath(
    Map<String, String?> predecessors,
    String source,
    String target,
  ) {
    final path = <String>[];
    String? current = target;

    while (current != null) {
      path.insert(0, current);
      if (current == source) break;
      current = predecessors[current];
    }

    return path.isEmpty || path.first != source ? [] : path;
  }
}
