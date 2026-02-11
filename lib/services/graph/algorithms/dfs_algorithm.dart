import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/services/graph/algorithms/graph_algorithm.dart';

class DFSAlgorithm implements GraphAlgorithm {
  @override
  List<AlgorithmStep> run(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    String startNodeId,
  ) {
    if (nodes.isEmpty) return [];

    final steps = <AlgorithmStep>[];
    final visited = <String>{};

    _dfsRecursive(startNodeId, nodes, edges, visited, steps);

    // Final clear step
    steps.add(
      AlgorithmStep(
        visitedNodes: Set.from(visited),
        activeNodeId: null,
        activeEdgeId: null,
      ),
    );

    return steps;
  }

  void _dfsRecursive(
    String nodeId,
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    Set<String> visited,
    List<AlgorithmStep> steps,
  ) {
    visited.add(nodeId);

    // Step: Visited node
    steps.add(
      AlgorithmStep(visitedNodes: Set.from(visited), activeNodeId: nodeId),
    );

    final neighbors = edges
        .where((e) => e.fromId == nodeId || (!e.directed && e.toId == nodeId))
        .map((e) => e.fromId == nodeId ? e.toId : e.fromId);

    for (final neighbor in neighbors) {
      if (!visited.contains(neighbor)) {
        // Find edge
        String? edgeId;
        try {
          final edge = edges.firstWhere(
            (e) =>
                (e.fromId == nodeId && e.toId == neighbor) ||
                (!e.directed && e.fromId == neighbor && e.toId == nodeId),
          );
          edgeId = edge.id;
        } catch (_) {}

        // Step: Traversing edge
        if (edgeId != null) {
          steps.add(
            AlgorithmStep(
              visitedNodes: Set.from(visited),
              activeNodeId: nodeId,
              activeEdgeId: edgeId,
            ),
          );
        }

        _dfsRecursive(neighbor, nodes, edges, visited, steps);

        // Step: Backtracking to current node (optional, but good for visualization)
        steps.add(
          AlgorithmStep(
            visitedNodes: Set.from(visited),
            activeNodeId: nodeId,
            activeEdgeId: edgeId, // Briefly highlight edge on return too?
          ),
        );
      }
    }
  }
}
