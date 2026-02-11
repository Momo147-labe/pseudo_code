import 'package:flutter/material.dart';

class GraphNode {
  final String id;
  Offset position;
  String label;
  Color color;

  GraphNode({
    required this.id,
    required this.position,
    this.label = '',
    this.color = Colors.blue,
  });

  factory GraphNode.fromJson(Map<String, dynamic> json) {
    return GraphNode(
      id: json['id'],
      position: Offset(json['dx'], json['dy']),
      label: json['label'] ?? '',
      color: Color(json['color'] ?? Colors.blue.value),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dx': position.dx,
      'dy': position.dy,
      'label': label,
      'color': color.value,
    };
  }

  GraphNode copyWith({
    String? id,
    Offset? position,
    String? label,
    Color? color,
  }) {
    return GraphNode(
      id: id ?? this.id,
      position: position ?? this.position,
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }
}

class GraphEdge {
  final String id;
  final String fromId;
  final String toId;
  final double weight;
  final bool directed;
  Color color;

  GraphEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    this.weight = 1.0,
    this.directed = false,
    this.color = Colors.grey,
  });

  factory GraphEdge.fromJson(Map<String, dynamic> json) {
    return GraphEdge(
      id: json['id'],
      fromId: json['fromId'],
      toId: json['toId'],
      weight: (json['weight'] ?? 1.0).toDouble(),
      directed: json['directed'] ?? false,
      color: Color(json['color'] ?? Colors.grey.value),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromId': fromId,
      'toId': toId,
      'weight': weight,
      'directed': directed,
      'color': color.value,
    };
  }

  GraphEdge copyWith({
    String? id,
    String? fromId,
    String? toId,
    double? weight,
    bool? directed,
    Color? color,
  }) {
    return GraphEdge(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      weight: weight ?? this.weight,
      directed: directed ?? this.directed,
      color: color ?? this.color,
    );
  }
}
