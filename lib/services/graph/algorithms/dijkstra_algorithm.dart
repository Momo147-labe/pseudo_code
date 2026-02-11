import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/services/graph/algorithms/graph_algorithm.dart';
import 'package:pseudo_code/services/graph/dijkstra_service.dart';

class DijkstraAlgorithm implements GraphAlgorithm {
  @override
  List<AlgorithmStep> run(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    String startNodeId,
  ) {
    if (nodes.isEmpty) return [];

    final service = DijkstraService(nodes: nodes, edges: edges);
    // Helper to find target? For animation we usually run until all reachable or specific target.
    // The current UI runs generic Dijkstra.
    final result = service.run(startNodeId);

    return result.steps.map((step) {
      // Find active edge? DijkstraService steps might not have it explicitly in the same way
      // but they have distances.
      // We can infer active edge if we track changes, but DijkstraStep as defined in service
      // doesn't seem to store "activeEdge".
      // Let's look at DijkstraService again ... it has pure data.
      // The old runDijkstraAnimation Logic calculated activeEdgeId during valid neighbors check.
      // The DijkstraStep in service might need enhancement or we just show nodes.
      // Actually, standard Dijkstra visualization highlights the edge being relaxed.

      return AlgorithmStep(
        visitedNodes: step.visited,
        activeNodeId: step.currentNode,
        data: {'distances': step.distances, 'predecessors': step.predecessors},
      );
    }).toList();
  }
}
