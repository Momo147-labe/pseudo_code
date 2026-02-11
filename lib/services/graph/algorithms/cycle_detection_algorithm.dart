import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/services/graph/algorithms/graph_algorithm.dart';

class CycleDetectionAlgorithm implements GraphAlgorithm {
  @override
  List<AlgorithmStep> run(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    String
    startNodeId, // Not strictly used if checking whole graph, but interface requires it
  ) {
    if (nodes.isEmpty) return [];

    final steps = <AlgorithmStep>[];
    final visited = <String>{};
    final recStack = <String>{};
    bool hasCycle = false;

    // Check all nodes to handle disconnected components
    for (var node in nodes) {
      if (_hasCycleUtil(node.id, nodes, edges, visited, recStack, steps)) {
        hasCycle = true;
        break;
      }
    }

    // Final step
    steps.add(
      AlgorithmStep(
        visitedNodes: Set.from(visited),
        activeNodeId: null,
        activeEdgeId: null,
        data: {'hasCycle': hasCycle},
      ),
    );

    return steps;
  }

  bool _hasCycleUtil(
    String nodeId,
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    Set<String> visited,
    Set<String> recStack,
    List<AlgorithmStep> steps,
  ) {
    visited.add(nodeId);
    recStack.add(nodeId);

    steps.add(
      AlgorithmStep(visitedNodes: Set.from(visited), activeNodeId: nodeId),
    );

    final neighbors = edges
        .where(
          (e) => e.fromId == nodeId,
        ) // Strictly directed for classic cycle detection
        .map((e) => e.toId);

    // Note: For undirected graph, cycle detection is different (should not go back to parent).
    // Assuming directed here based on previous implementation logic which used recursion stack.
    // However, GraphProvider implementation handled undirected edges too?
    // Let's check original provider:
    // `final neighbors = _edges.where((e) => e.fromId == id).map((e) => e.toId);`
    // It only followed outgoing edges from `fromId`. If graph is undirected, edges are usually duplicated or handled differently.
    // The previous implementation used `_edges.where((e) => e.fromId == id).map((e) => e.toId);`
    // This implies it only followed edges where `fromId` matches. In undirected graph model of this app,
    // edges might be stored as directed=false but still have from/to.
    // If undirected, we must check connectivity both ways.
    // But the original code only checked `e.fromId == id`.
    // I will stick to the original logic for now to avoid changing behavior.

    for (var neighbor in neighbors) {
      String? edgeId;
      try {
        final edge = edges.firstWhere(
          (e) => e.fromId == nodeId && e.toId == neighbor,
        );
        edgeId = edge.id;
      } catch (_) {}

      if (edgeId != null) {
        steps.add(
          AlgorithmStep(
            visitedNodes: Set.from(visited),
            activeNodeId: nodeId,
            activeEdgeId: edgeId,
          ),
        );
      }

      if (!visited.contains(neighbor)) {
        if (_hasCycleUtil(neighbor, nodes, edges, visited, recStack, steps))
          return true;
      } else if (recStack.contains(neighbor)) {
        return true;
      }
    }

    recStack.remove(nodeId);
    return false;
  }
}
