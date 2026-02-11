import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/services/graph/algorithms/graph_algorithm.dart';

class BFSAlgorithm implements GraphAlgorithm {
  @override
  List<AlgorithmStep> run(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    String startNodeId,
  ) {
    if (nodes.isEmpty) return [];

    final steps = <AlgorithmStep>[];
    final visited = <String>{};
    final queue = [startNodeId];

    visited.add(startNodeId);

    steps.add(
      AlgorithmStep(visitedNodes: Set.from(visited), activeNodeId: startNodeId),
    );

    while (queue.isNotEmpty) {
      final nodeId = queue.removeAt(0);

      // Step: Processing current node
      steps.add(
        AlgorithmStep(visitedNodes: Set.from(visited), activeNodeId: nodeId),
      );

      final neighbors = edges
          .where((e) => e.fromId == nodeId || (!e.directed && e.toId == nodeId))
          .map((e) => e.fromId == nodeId ? e.toId : e.fromId);

      for (final neighbor in neighbors) {
        if (!visited.contains(neighbor)) {
          // Find the edge connecting to this neighbor for visualization
          String? edgeId;
          try {
            final edge = edges.firstWhere(
              (e) =>
                  (e.fromId == nodeId && e.toId == neighbor) ||
                  (!e.directed && e.fromId == neighbor && e.toId == nodeId),
            );
            edgeId = edge.id;
          } catch (_) {}

          // Step: Traversing edge to neighbor
          if (edgeId != null) {
            steps.add(
              AlgorithmStep(
                visitedNodes: Set.from(visited),
                activeNodeId: nodeId, // Still at source while traversing edge
                activeEdgeId: edgeId,
              ),
            );
          }

          visited.add(neighbor);
          queue.add(neighbor);

          // Step: Arrived at neighbor
          steps.add(
            AlgorithmStep(
              visitedNodes: Set.from(visited),
              activeNodeId: neighbor,
              activeEdgeId: edgeId, // Keep edge highlighted briefly
            ),
          );
        }
      }
    }

    // Final step clear active items
    steps.add(
      AlgorithmStep(
        visitedNodes: Set.from(visited),
        activeNodeId: null,
        activeEdgeId: null,
      ),
    );

    return steps;
  }
}
