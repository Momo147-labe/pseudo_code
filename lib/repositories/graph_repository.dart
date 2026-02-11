import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pseudo_code/models/graph/graph_models.dart';

class GraphRepository {
  Future<void> saveGraph(String path, String content) async {
    try {
      final file = File(path);
      await file.writeAsString(content);
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde du graphe: $e");
      rethrow;
    }
  }

  String exportGraph({
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
    required bool isDirected,
    required bool isWeighted,
  }) {
    final data = {
      'nodes': nodes.map((n) => n.toJson()).toList(),
      'edges': edges.map((e) => e.toJson()).toList(),
      'isDirected': isDirected,
      'isWeighted': isWeighted,
    };
    return jsonEncode(data);
  }

  Map<String, dynamic> parseGraphContent(String content) {
    try {
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Erreur lors du parsing du graphe: $e");
      return {};
    }
  }

  Future<String> loadGraph(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return '';
    } catch (e) {
      debugPrint("Erreur lors du chargement du graphe: $e");
      rethrow;
    }
  }
}
