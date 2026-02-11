import 'package:pseudo_code/models/graph/graph_models.dart';

class AlgorithmStep {
  final Set<String> visitedNodes;
  final String? activeNodeId;
  final String? activeEdgeId;
  // Generic map for algorithm specific data (distances, parent pointers, etc.)
  final Map<String, dynamic> data;

  AlgorithmStep({
    required this.visitedNodes,
    this.activeNodeId,
    this.activeEdgeId,
    this.data = const {},
  });
}

abstract class GraphAlgorithm {
  List<AlgorithmStep> run(
    List<GraphNode> nodes,
    List<GraphEdge> edges,
    String startNodeId,
  );
}
