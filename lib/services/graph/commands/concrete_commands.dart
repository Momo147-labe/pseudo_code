import 'package:flutter/material.dart';

import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/services/graph/command_manager.dart';

typedef NotifyCallback = void Function();

class AddNodeCommand implements GraphCommand {
  final List<GraphNode> nodes;
  final GraphNode node;
  final NotifyCallback notify;

  AddNodeCommand(this.nodes, this.node, this.notify);

  @override
  void execute() {
    nodes.add(node);
    notify();
  }

  @override
  void undo() {
    nodes.remove(node);
    notify();
  }

  @override
  void redo() => execute();
}

class RemoveNodeCommand implements GraphCommand {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final String nodeId;
  final NotifyCallback notify;

  // State to restore
  late GraphNode _removedNode;
  late List<GraphEdge> _removedEdges;

  RemoveNodeCommand(this.nodes, this.edges, this.nodeId, this.notify);

  @override
  void execute() {
    final nodeIndex = nodes.indexWhere((n) => n.id == nodeId);
    if (nodeIndex == -1) return; // Should not happen

    _removedNode = nodes[nodeIndex];
    _removedEdges = edges
        .where((e) => e.fromId == nodeId || e.toId == nodeId)
        .toList();

    nodes.removeAt(nodeIndex);
    edges.removeWhere((e) => e.fromId == nodeId || e.toId == nodeId);
    notify();
  }

  @override
  void undo() {
    nodes.add(_removedNode);
    edges.addAll(_removedEdges);
    notify();
  }

  @override
  void redo() => execute();
}

class MoveNodesCommand implements GraphCommand {
  final List<GraphNode> nodes;
  final Map<String, Offset> oldPositions;
  final Map<String, Offset> newPositions;
  final NotifyCallback notify;

  MoveNodesCommand(
    this.nodes,
    this.oldPositions,
    this.newPositions,
    this.notify,
  );

  @override
  void execute() {
    newPositions.forEach((id, pos) {
      final index = nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        nodes[index] = nodes[index].copyWith(position: pos);
      }
    });
    notify();
  }

  @override
  void undo() {
    oldPositions.forEach((id, pos) {
      final index = nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        nodes[index] = nodes[index].copyWith(position: pos);
      }
    });
    notify();
  }

  @override
  void redo() => execute();
}

class AddEdgeCommand implements GraphCommand {
  final List<GraphEdge> edges;
  final GraphEdge edge;
  final NotifyCallback notify;

  AddEdgeCommand(this.edges, this.edge, this.notify);

  @override
  void execute() {
    edges.add(edge);
    notify();
  }

  @override
  void undo() {
    edges.remove(edge);
    notify();
  }

  @override
  void redo() => execute();
}

class RemoveEdgeCommand implements GraphCommand {
  final List<GraphEdge> edges;
  final String edgeId;
  final NotifyCallback notify;

  late GraphEdge _removedEdge;

  RemoveEdgeCommand(this.edges, this.edgeId, this.notify);

  @override
  void execute() {
    final index = edges.indexWhere((e) => e.id == edgeId);
    if (index != -1) {
      _removedEdge = edges[index];
      edges.removeAt(index);
      notify();
    }
  }

  @override
  void undo() {
    edges.add(_removedEdge);
    notify();
  }

  @override
  void redo() => execute();
}
