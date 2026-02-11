import 'dart:math' as math;
import 'dart:async'; // For Debouncer later
import 'package:flutter/material.dart';
import 'package:pseudo_code/models/graph/graph_models.dart';
import 'package:pseudo_code/repositories/graph_repository.dart';

import 'package:pseudo_code/services/graph/dijkstra_service.dart';
import 'package:pseudo_code/services/graph/algorithms/graph_algorithm.dart';
import 'package:pseudo_code/services/graph/algorithms/bfs_algorithm.dart';
import 'package:pseudo_code/services/graph/algorithms/dfs_algorithm.dart';
import 'package:pseudo_code/services/graph/algorithms/dijkstra_algorithm.dart';
import 'package:pseudo_code/services/graph/algorithms/cycle_detection_algorithm.dart';
import 'package:pseudo_code/services/graph/command_manager.dart';
import 'package:pseudo_code/services/graph/commands/concrete_commands.dart';

import 'package:uuid/uuid.dart';

class GraphProvider with ChangeNotifier {
  final List<GraphNode> _nodes = [];
  final List<GraphEdge> _edges = [];
  final _uuid = const Uuid();
  final _repository = GraphRepository();
  final _commandManager = CommandManager();

  bool get canUndo => _commandManager.canUndo;
  bool get canRedo => _commandManager.canRedo;

  void undo() => _commandManager.undo();
  void redo() => _commandManager.redo();

  String? _currentFilePath;
  String? get currentFilePath => _currentFilePath;

  bool _isDirected = false;
  bool get isDirected => _isDirected;

  bool _isWeighted = false;
  bool get isWeighted => _isWeighted;

  void setGraphSettings({
    bool? isDirected,
    bool? isWeighted,
    bool? snapToGrid,
  }) {
    if (isDirected != null) _isDirected = isDirected;
    if (isWeighted != null) _isWeighted = isWeighted;
    if (snapToGrid != null) _snapToGrid = snapToGrid;
    _autoSave();
    notifyListeners();
  }

  bool _snapToGrid = false;
  bool get snapToGrid => _snapToGrid;

  Set<String> _selectedNodeIds = {};
  Set<String> get selectedNodeIds => _selectedNodeIds;

  bool _resetViewRequested = false;
  bool get resetViewRequested => _resetViewRequested;

  String? _startNodeId;
  String? get startNodeId => _startNodeId;

  String? _endNodeId;
  String? get endNodeId => _endNodeId;

  DijkstraResult? _dijkstraResult;
  DijkstraResult? get dijkstraResult => _dijkstraResult;

  void setStartNode(String? id) {
    _startNodeId = id;
    notifyListeners();
  }

  void setEndNode(String? id) {
    _endNodeId = id;
    notifyListeners();
  }

  double _zoomRequest = 0;
  double get zoomRequest => _zoomRequest;

  void consumeZoomRequest() {
    _zoomRequest = 0;
  }

  void zoomIn() {
    _zoomRequest = 1.2;
    notifyListeners();
  }

  void zoomOut() {
    _zoomRequest = 0.8;
    notifyListeners();
  }

  void consumeResetView() {
    _resetViewRequested = false;
  }

  void resetView() {
    _resetViewRequested = true;
    notifyListeners();
  }

  bool _isExecuting = false;
  bool get isExecuting => _isExecuting;

  Set<String> _visitedNodes = {};
  Set<String> get visitedNodes => _visitedNodes;

  String? _activeEdgeId;
  String? get activeEdgeId => _activeEdgeId;

  List<GraphNode> get nodes => List.unmodifiable(_nodes);
  List<GraphEdge> get edges => List.unmodifiable(_edges);

  String? get selectedNodeId =>
      _selectedNodeIds.isEmpty ? null : _selectedNodeIds.first;

  void addNode(Offset position) {
    Offset finalPos = position;
    if (_snapToGrid) {
      finalPos = Offset(
        (position.dx / 20).round() * 20.0,
        (position.dy / 20).round() * 20.0,
      );
    }
    final newNode = GraphNode(
      id: _uuid.v4(),
      position: finalPos,
      label: 'S${_nodes.length + 1}',
    );

    _commandManager.execute(
      AddNodeCommand(_nodes, newNode, () {
        _autoSave();
        notifyListeners();
      }),
    );
  }

  Map<String, Offset> _dragInitialPositions = {};

  void startNodeDrag(String id) {
    _dragInitialPositions.clear();
    if (_selectedNodeIds.contains(id)) {
      for (final selectedId in _selectedNodeIds) {
        final index = _nodes.indexWhere((n) => n.id == selectedId);
        if (index != -1) {
          _dragInitialPositions[selectedId] = _nodes[index].position;
        }
      }
    } else {
      final index = _nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        _dragInitialPositions[id] = _nodes[index].position;
      }
    }
  }

  void updateNodePosition(String id, Offset newPosition) {
    Offset finalPos = newPosition;
    if (_snapToGrid) {
      finalPos = Offset(
        (newPosition.dx / 20).round() * 20.0,
        (newPosition.dy / 20).round() * 20.0,
      );
    }
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(position: finalPos);
      notifyListeners();
    }
  }

  void updateSelectionPosition(Offset delta) {
    if (_selectedNodeIds.isEmpty) return;

    for (int i = 0; i < _nodes.length; i++) {
      if (_selectedNodeIds.contains(_nodes[i].id)) {
        Offset newPos = _nodes[i].position + delta;
        if (_snapToGrid) {
          newPos = Offset(
            (newPos.dx / 20).round() * 20.0,
            (newPos.dy / 20).round() * 20.0,
          );
        }
        _nodes[i] = _nodes[i].copyWith(position: newPos);
      }
    }
    notifyListeners();
  }

  void endNodeDrag() {
    if (_dragInitialPositions.isEmpty) return;

    final newPositions = <String, Offset>{};
    _dragInitialPositions.forEach((id, _) {
      final index = _nodes.indexWhere((n) => n.id == id);
      if (index != -1) {
        newPositions[id] = _nodes[index].position;
      }
    });

    bool moved = false;
    newPositions.forEach((id, pos) {
      if (_dragInitialPositions[id] != pos) moved = true;
    });

    if (moved) {
      _commandManager.execute(
        MoveNodesCommand(
          _nodes,
          Map.from(_dragInitialPositions),
          newPositions,
          () {
            _autoSave();
            notifyListeners();
          },
        ),
      );
    }
    _dragInitialPositions.clear();
  }

  void addEdge(
    String fromId,
    String toId, {
    double weight = 1.0,
    bool directed = false,
  }) {
    // Éviter les doublons simples (on pourrait complexifier pour les graphes multiples)
    if (_edges.any((e) => e.fromId == fromId && e.toId == toId)) return;

    final newEdge = GraphEdge(
      id: _uuid.v4(),
      fromId: fromId,
      toId: toId,
      weight: weight,
      directed: directed,
    );

    _commandManager.execute(
      AddEdgeCommand(_edges, newEdge, () {
        _autoSave();
        notifyListeners();
      }),
    );
  }

  void selectNode(String? id, {bool multi = false}) {
    if (id == null) {
      _selectedNodeIds.clear();
    } else {
      if (multi) {
        if (_selectedNodeIds.contains(id)) {
          _selectedNodeIds.remove(id);
        } else {
          _selectedNodeIds.add(id);
        }
      } else {
        _selectedNodeIds = {id};
      }
    }
    notifyListeners();
  }

  void selectNodesInRect(Rect rect) {
    _selectedNodeIds.clear();
    for (final node in _nodes) {
      if (rect.contains(node.position)) {
        _selectedNodeIds.add(node.id);
      }
    }
    notifyListeners();
  }

  void updateNodeLabel(String id, String label) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index != -1) {
      _nodes[index] = _nodes[index].copyWith(label: label);
      _autoSave();
      notifyListeners();
    }
  }

  void updateEdgeWeight(String id, double weight) {
    final index = _edges.indexWhere((edge) => edge.id == id);
    if (index != -1) {
      _edges[index] = _edges[index].copyWith(weight: weight);
      _autoSave();
      notifyListeners();
    }
  }

  void toggleEdgeDirection(String id) {
    final index = _edges.indexWhere((edge) => edge.id == id);
    if (index != -1) {
      _edges[index] = _edges[index].copyWith(directed: !_edges[index].directed);
      _autoSave();
      notifyListeners();
    }
  }

  void clear() {
    _nodes.clear();
    _edges.clear();
    _selectedNodeIds.clear();
    _currentFilePath = null;
    notifyListeners();
  }

  void loadFromContent(String content, String path) {
    try {
      _nodes.clear();
      _edges.clear();
      _selectedNodeIds.clear();
      _currentFilePath = path;

      final data = _repository.parseGraphContent(content);
      if (data.isNotEmpty) {
        if (data.containsKey('nodes')) {
          for (var n in data['nodes']) {
            _nodes.add(GraphNode.fromJson(n));
          }
        }
        if (data.containsKey('edges')) {
          for (var e in data['edges']) {
            _edges.add(GraphEdge.fromJson(e));
          }
        }
        _isDirected = data['isDirected'] ?? false;
        _isWeighted = data['isWeighted'] ?? false;
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement du graphe: $e");
    }
    notifyListeners();
  }

  String exportContent() {
    return _repository.exportGraph(
      nodes: _nodes,
      edges: _edges,
      isDirected: _isDirected,
      isWeighted: _isWeighted,
    );
  }

  Timer? _saveDebouncer;

  Future<void> _autoSave() async {
    if (_currentFilePath == null) return;

    if (_saveDebouncer?.isActive ?? false) _saveDebouncer!.cancel();
    _saveDebouncer = Timer(const Duration(milliseconds: 1000), () async {
      try {
        await _repository.saveGraph(_currentFilePath!, exportContent());
      } catch (e) {
        debugPrint("Erreur lors de l'auto-sauvegarde du graphe: $e");
      }
    });
  }

  @override
  void dispose() {
    _saveDebouncer?.cancel();
    super.dispose();
  }

  void removeNode(String id) {
    // For removeNode, we need to handle edges removal too.
    // The RemoveNodeCommand handles it.
    _commandManager.execute(
      RemoveNodeCommand(_nodes, _edges, id, () {
        _selectedNodeIds.remove(id);
        if (_startNodeId == id) _startNodeId = null;
        if (_endNodeId == id) _endNodeId = null;
        _autoSave();
        notifyListeners();
      }),
    );
  }

  void removeEdge(String id) {
    _commandManager.execute(
      RemoveEdgeCommand(_edges, id, () {
        _autoSave();
        notifyListeners();
      }),
    );
  }

  // --- ALGORITHMS ---

  int _animationSpeedMs = 500;
  int get animationSpeedMs => _animationSpeedMs;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  bool _stepMode = false;
  bool get stepMode => _stepMode;

  void setAnimationSpeed(int speedMs) {
    _animationSpeedMs = speedMs;
    notifyListeners();
  }

  void togglePause() {
    _isPaused = !_isPaused;
    notifyListeners();
  }

  void setStepMode(bool enabled) {
    _stepMode = enabled;
    notifyListeners();
  }

  Future<void> _awaitAnimation() async {
    while (_isPaused && _isExecuting) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(Duration(milliseconds: _animationSpeedMs));
  }

  // --- ALGORITHMS ---

  // --- ALGORITHMS ---

  Future<void> runBFS(String startNodeId) async {
    final algo = BFSAlgorithm();
    final steps = algo.run(_nodes, _edges, startNodeId);
    await _runSteps(steps);
  }

  Future<void> runDFS(String startNodeId) async {
    final algo = DFSAlgorithm();
    final steps = algo.run(_nodes, _edges, startNodeId);
    await _runSteps(steps);
  }

  Future<bool> detectCycle() async {
    if (_nodes.isEmpty) return false;
    final algo = CycleDetectionAlgorithm();
    final steps = algo.run(_nodes, _edges, _nodes.first.id);
    await _runSteps(steps);

    final hasCycle = steps.isNotEmpty && steps.last.data['hasCycle'] == true;
    debugPrint("Cycle détecté: $hasCycle");
    return hasCycle;
  }

  Future<void> runDijkstraAnimation(String startNodeId) async {
    final algo = DijkstraAlgorithm(); // Using our new wrapper
    // The wrapper uses DijkstraService internally but we need to pass nodes/edges
    // Note: The wrapper might not yield detailed activeEdgeId as the service doesn't provide it
    // If strict visual parity is needed, we might need to enhance the service or wrapper.
    // For now, this restores functionality.
    final steps = algo.run(_nodes, _edges, startNodeId);
    await _runSteps(steps);
  }

  Future<void> _runSteps(List<AlgorithmStep> steps) async {
    _isExecuting = true;
    _visitedNodes.clear();
    _activeEdgeId = null;
    notifyListeners();

    for (final step in steps) {
      if (!_isExecuting) break;

      _visitedNodes = step.visitedNodes;
      _activeEdgeId = step.activeEdgeId;
      notifyListeners();
      await _awaitAnimation();
    }
    _finalizeExecution();
  }

  void generateRandomGraph({int nodeCount = 6, int edgeCount = 8}) {
    clear();
    final math.Random random = math.Random();

    for (int i = 0; i < nodeCount; i++) {
      addNode(
        Offset(random.nextDouble() * 500 + 50, random.nextDouble() * 500 + 50),
      );
    }

    for (int i = 0; i < edgeCount; i++) {
      final from = _nodes[random.nextInt(_nodes.length)].id;
      final to = _nodes[random.nextInt(_nodes.length)].id;
      if (from != to)
        addEdge(
          from,
          to,
          directed: _isDirected,
          weight: _isWeighted ? (random.nextInt(10) + 1).toDouble() : 1.0,
        );
    }
  }

  void _finalizeExecution() {
    _isExecuting = false;
    _activeEdgeId = null;
    notifyListeners();
  }

  void stopExecution() {
    _isExecuting = false;
    notifyListeners();
  }

  // --- AUTO LAYOUT (Force-Directed) ---
  Future<void> runAutoLayout() async {
    if (_nodes.isEmpty) return;

    const double k = 100.0; // Ideal distance
    const double repulsion = 5000.0;
    const double spring = 0.05;
    const int iterations = 50;

    for (int i = 0; i < iterations; i++) {
      final Map<String, Offset> displacements = {
        for (var n in _nodes) n.id: Offset.zero,
      };

      // Repulsion between nodes
      for (int i = 0; i < _nodes.length; i++) {
        for (int j = 0; j < _nodes.length; j++) {
          if (i == j) continue;
          final delta = _nodes[i].position - _nodes[j].position;
          final distance = delta.distance;
          if (distance > 0) {
            final force = (delta / distance) * (repulsion / distance);
            displacements[_nodes[i].id] = displacements[_nodes[i].id]! + force;
          }
        }
      }

      // Attraction between connected nodes
      for (final edge in _edges) {
        final fromNode = _nodes.firstWhere((n) => n.id == edge.fromId);
        final toNode = _nodes.firstWhere((n) => n.id == edge.toId);
        final delta = fromNode.position - toNode.position;
        final distance = delta.distance;
        if (distance > 0) {
          final force = (delta / distance) * (spring * (distance - k));
          displacements[fromNode.id] = displacements[fromNode.id]! - force;
          displacements[toNode.id] = displacements[toNode.id]! + force;
        }
      }

      // Apply displacements
      for (int j = 0; j < _nodes.length; j++) {
        final id = _nodes[j].id;
        _nodes[j] = _nodes[j].copyWith(
          position: _nodes[j].position + displacements[id]!,
        );
      }

      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 20));
    }
    _autoSave();
  }

  // ==================== Dijkstra ====================

  /// Exécute l'algorithme de Dijkstra
  /// Si targetId est fourni : cherche uniquement le chemin source→target
  /// Sinon : calcule les distances vers tous les nœuds
  void runDijkstra(String sourceId, {String? targetId}) {
    try {
      final service = DijkstraService(nodes: _nodes, edges: _edges);
      _dijkstraResult = service.run(sourceId, targetId: targetId);
      notifyListeners();
    } catch (e) {
      print('Error running Dijkstra: $e');
      _dijkstraResult = null;
      notifyListeners();
      rethrow;
    }
  }

  /// Efface les résultats de Dijkstra
  void clearDijkstra() {
    _dijkstraResult = null;
    notifyListeners();
  }
}
