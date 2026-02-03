import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../merise/mcd_models.dart';
import '../merise/sql_engine.dart';
import '../merise/mld_transformer.dart';
import '../merise/mpd_generator.dart';

class MeriseProvider with ChangeNotifier {
  final List<McdEntity> _entities = [];
  final List<McdRelation> _relations = [];
  final List<McdLink> _links = [];
  final List<McdFunctionalDependency> _functionalDependencies = [];

  // Simulation avec moteur SQL
  SqlEngine? _sqlEngine;
  Mld? _currentMld;

  // Sélection
  final Set<String> _selectedIds = {};

  // Historique (Undo/Redo)
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  Timer? _historyDebounce;

  // Interface
  double _zoom = 1.0;
  double _textScaleFactor = 1.1; // Plus grand par défaut
  Offset _panOffset = Offset.zero;
  String _activeView = 'mcd';
  static const double gridStep = 20.0;
  SqlDialect _sqlDialect = SqlDialect.mysql;

  // Mode Lien
  bool _isLinkMode = false;
  String? _linkSourceId; // Entity or Relation ID
  Offset? _tempLinkEnd;
  bool _isDraggingElement = false;

  MeriseProvider() {
    _initDemoData();
  }

  List<McdEntity> get entities => _entities;
  List<McdRelation> get relations => _relations;
  List<McdLink> get links => _links;

  Set<String> get selectedIds => _selectedIds;

  dynamic get selectedItem {
    if (_selectedIds.isEmpty) return null;
    final lastId = _selectedIds.last;
    if (lastId.startsWith('e')) {
      return _entities.firstWhere(
        (e) => e.id == lastId,
        orElse: () => _entities.first,
      );
    } else {
      return _relations.firstWhere(
        (r) => r.id == lastId,
        orElse: () => _relations.first,
      );
    }
  }

  double get zoom => _zoom;
  double get textScaleFactor => _textScaleFactor;
  Offset get panOffset => _panOffset;
  String get activeView => _activeView;
  SqlDialect get sqlDialect => _sqlDialect;
  bool get isLinkMode => _isLinkMode;
  String? get linkSourceId => _linkSourceId;
  Offset? get tempLinkEnd => _tempLinkEnd;
  SqlEngine? get sqlEngine => _sqlEngine;
  Mld? get currentMld => _currentMld;
  bool get isDraggingElement => _isDraggingElement;

  Mcd get mcd => Mcd(
    entities: _entities,
    relations: _relations,
    links: _links,
    functionalDependencies: _functionalDependencies,
  );

  void increaseTextScale() {
    _textScaleFactor = (_textScaleFactor + 0.1).clamp(0.8, 2.0);
    notifyListeners();
  }

  void decreaseTextScale() {
    _textScaleFactor = (_textScaleFactor - 0.1).clamp(0.8, 2.0);
    notifyListeners();
  }

  void setActiveView(String view) {
    if (_activeView != view) {
      _activeView = view;
      _isLinkMode = false; // Désactiver le mode lien si on change de vue
      notifyListeners();
    }
  }

  void setSqlDialect(SqlDialect dialect) {
    if (_sqlDialect != dialect) {
      _sqlDialect = dialect;
      notifyListeners();
    }
  }

  void updatePanOffset(Offset delta) {
    _panOffset += delta;
    notifyListeners();
  }

  void setDraggingElement(bool value) {
    if (_isDraggingElement != value) {
      _isDraggingElement = value;
      notifyListeners();
    }
  }

  void resetPanOffset() {
    _panOffset = Offset.zero;
    notifyListeners();
  }

  void jumpTo(Offset worldPosition, Size viewportSize) {
    // Centrer worldPosition dans le viewportSize
    _panOffset = Offset(
      (viewportSize.width / 2 / _zoom) - worldPosition.dx,
      (viewportSize.height / 2 / _zoom) - worldPosition.dy,
    );
    notifyListeners();
  }

  void autoCenter(Size viewportSize) {
    if (_entities.isEmpty && _relations.isEmpty) {
      _panOffset = Offset.zero;
      notifyListeners();
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final e in _entities) {
      minX = math.min(minX, e.position.dx);
      minY = math.min(minY, e.position.dy);
      maxX = math.max(maxX, e.position.dx + 150);
      maxY = math.max(maxY, e.position.dy + 100);
    }
    for (final r in _relations) {
      minX = math.min(minX, r.position.dx);
      minY = math.min(minY, r.position.dy);
      maxX = math.max(maxX, r.position.dx + 45);
      maxY = math.max(maxY, r.position.dy + 45);
    }

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    jumpTo(Offset(centerX, centerY), viewportSize);
  }

  // -- Mode Lien Logic --

  void toggleLinkMode() {
    _isLinkMode = !_isLinkMode;
    _linkSourceId = null;
    _tempLinkEnd = null;
    notifyListeners();
  }

  void startLink(String sourceId) {
    if (!_isLinkMode) return;
    _linkSourceId = sourceId;
    _tempLinkEnd = null;
    notifyListeners();
  }

  void updateTempLink(Offset end) {
    _tempLinkEnd = end;
    notifyListeners();
  }

  void autoLayout() {
    if (_entities.isEmpty) return;

    // 1. Organiser les entités en grille
    const double startX = 50.0;
    const double startY = 50.0;
    const double spacingX = 250.0;
    const double spacingY = 200.0;
    const int entitiesPerRow = 3;

    for (int i = 0; i < _entities.length; i++) {
      final row = i ~/ entitiesPerRow;
      final col = i % entitiesPerRow;
      _entities[i] = _entities[i].copyWith(
        position: Offset(startX + col * spacingX, startY + row * spacingY),
      );
    }

    // 2. Placer les relations au barycentre de leurs entités liées
    for (final rel in _relations) {
      final connectedLinks = _links
          .where((l) => l.relationId == rel.id)
          .toList();
      if (connectedLinks.isNotEmpty) {
        double sumX = 0;
        double sumY = 0;
        int count = 0;

        for (final link in connectedLinks) {
          final entityIndex = _entities.indexWhere(
            (e) => e.id == link.entityId,
          );
          if (entityIndex != -1) {
            final entity = _entities[entityIndex];
            sumX += entity.position.dx + 75; // Centre horizontal approximatif
            sumY += entity.position.dy + 50; // Centre vertical approximatif
            count++;
          }
        }

        if (count > 0) {
          final relIndex = _relations.indexWhere((r) => r.id == rel.id);
          if (relIndex != -1) {
            _relations[relIndex] = _relations[relIndex].copyWith(
              position: Offset(sumX / count - 15, sumY / count - 15),
            );
          }
        }
      }
    }

    saveToHistory();
    notifyListeners();
  }

  void forceDirectedLayout() {
    if (_entities.isEmpty) return;

    // Paramètres de l’algorithme
    const int iterations = 50;
    const double repulsionCoeff = 1000000.0;
    const double attractionCoeff = 0.05;

    for (int iter = 0; iter < iterations; iter++) {
      final Map<String, Offset> forces = {};

      // 1. Force de répulsion entre toutes les entités
      for (int i = 0; i < _entities.length; i++) {
        forces[_entities[i].id] = Offset.zero;
        for (int j = 0; j < _entities.length; j++) {
          if (i == j) continue;
          final delta = _entities[i].position - _entities[j].position;
          final dist = delta.distance.clamp(10.0, 1000.0);
          final force = (delta / dist) * (repulsionCoeff / (dist * dist));
          forces[_entities[i].id] = forces[_entities[i].id]! + force;
        }
      }

      // 2. Force d’attraction via les liens
      for (final link in _links) {
        final entityIndex = _entities.indexWhere((e) => e.id == link.entityId);
        final relIndex = _relations.indexWhere((r) => r.id == link.relationId);

        if (entityIndex != -1 && relIndex != -1) {
          final e = _entities[entityIndex];
          final r = _relations[relIndex];
          final delta = r.position - e.position;
          final dist = delta.distance;
          final force = (delta / dist) * (dist * dist * attractionCoeff);

          forces[e.id] = forces[e.id]! + force;
        }
      }

      // 3. Appliquer les forces
      for (int i = 0; i < _entities.length; i++) {
        final f = forces[_entities[i].id]!;
        // Limiter le déplacement par itération
        final limitedF = Offset(f.dx.clamp(-20, 20), f.dy.clamp(-20, 20));
        _entities[i] = _entities[i].copyWith(
          position: _entities[i].position + limitedF,
        );
      }
    }

    saveToHistory();
    notifyListeners();
  }

  void completeLink(String targetId) {
    if (_linkSourceId != null && _linkSourceId != targetId) {
      // Vérifier si c'est Entity -> Relation ou Relation -> Entity
      String? eId;
      String? rId;

      if (_entities.any((e) => e.id == _linkSourceId)) {
        eId = _linkSourceId;
        if (_relations.any((r) => r.id == targetId)) rId = targetId;
      } else if (_relations.any((r) => r.id == _linkSourceId)) {
        rId = _linkSourceId;
        if (_entities.any((e) => e.id == targetId)) eId = targetId;
      }

      if (eId != null && rId != null) {
        createLink(eId, rId);
      }
    }
    _linkSourceId = null;
    _tempLinkEnd = null;
    notifyListeners();
  }

  void cancelLink() {
    _linkSourceId = null;
    _tempLinkEnd = null;
    notifyListeners();
  }

  // -- Functional Dependencies Logic --

  List<McdFunctionalDependency> get functionalDependencies =>
      _functionalDependencies;

  void addFunctionalDependency(List<String> sources, List<String> targets) {
    _functionalDependencies.add(
      McdFunctionalDependency(
        id: 'df${DateTime.now().millisecondsSinceEpoch}',
        sourceAttributes: sources,
        targetAttributes: targets,
      ),
    );
    saveToHistory();
    notifyListeners();
  }

  void updateFunctionalDependency(
    String id,
    List<String> sources,
    List<String> targets,
  ) {
    final index = _functionalDependencies.indexWhere((df) => df.id == id);
    if (index != -1) {
      _functionalDependencies[index] = _functionalDependencies[index].copyWith(
        sourceAttributes: sources,
        targetAttributes: targets,
      );
      saveToHistory();
      notifyListeners();
    }
  }

  void deleteFunctionalDependency(String id) {
    _functionalDependencies.removeWhere((df) => df.id == id);
    saveToHistory();
    notifyListeners();
  }

  // -- Historique Logic --

  void _resetHistory() {
    _undoStack.clear();
    _redoStack.clear();
    _undoStack.add(serialize());
  }

  void _scheduleHistorySave() {
    _historyDebounce?.cancel();
    _historyDebounce = Timer(const Duration(milliseconds: 350), () {
      saveToHistory();
      notifyListeners();
    });
  }

  void saveToHistory() {
    final state = serialize();
    if (_undoStack.isEmpty || _undoStack.last != state) {
      _undoStack.add(state);
      _redoStack.clear();
      // Limiter la taille de l'historique
      if (_undoStack.length > 50) _undoStack.removeAt(0);
    }
  }

  void undo() {
    _historyDebounce?.cancel();
    if (_undoStack.length > 1) {
      final currentState = _undoStack.removeLast();
      _redoStack.add(currentState);
      deserialize(_undoStack.last, clearHistory: false);
      notifyListeners();
    }
  }

  void redo() {
    _historyDebounce?.cancel();
    if (_redoStack.isNotEmpty) {
      final nextState = _redoStack.removeLast();
      _undoStack.add(nextState);
      deserialize(nextState, clearHistory: false);
      notifyListeners();
    }
  }

  void _initDemoData() {
    // Les données sont maintenant chargées uniquement depuis les fichiers .csi
    _resetHistory();
  }

  void selectItem(dynamic item, {bool additive = false}) {
    if (item == null) {
      _selectedIds.clear();
    } else {
      final String id = (item is McdEntity)
          ? item.id
          : (item as McdRelation).id;
      if (!additive) {
        _selectedIds.clear();
      }
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedIds.clear();
    for (final e in _entities) {
      _selectedIds.add(e.id);
    }
    for (final r in _relations) {
      _selectedIds.add(r.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedIds.isNotEmpty) {
      _selectedIds.clear();
      notifyListeners();
    }
  }

  bool isSelected(String id) => _selectedIds.contains(id);

  void updateEntityPosition(
    String id,
    Offset newPos, {
    bool isFinal = false,
    bool snap = true,
  }) {
    final index = _entities.indexWhere((e) => e.id == id);
    if (index != -1) {
      final delta = newPos - _entities[index].position;

      // Si l'entité déplacée est sélectionnée, on déplace tout le groupe
      if (_selectedIds.contains(id)) {
        for (final selId in _selectedIds) {
          if (selId.startsWith('e')) {
            final eIdx = _entities.indexWhere((e) => e.id == selId);
            if (eIdx != -1) {
              _moveEntity(eIdx, _entities[eIdx].position + delta, snap: snap);
            }
          } else {
            final rIdx = _relations.indexWhere((r) => r.id == selId);
            if (rIdx != -1) {
              _moveRelation(
                rIdx,
                _relations[rIdx].position + delta,
                snap: snap,
              );
            }
          }
        }
      } else {
        _moveEntity(index, newPos, snap: snap);
      }

      if (isFinal) saveToHistory();
      notifyListeners();
    }
  }

  void _moveEntity(int index, Offset newPos, {bool snap = true}) {
    Offset posToApply = newPos;
    if (snap) {
      posToApply = Offset(
        (newPos.dx / gridStep).round() * gridStep,
        (newPos.dy / gridStep).round() * gridStep,
      );
    }
    _entities[index] = _entities[index].copyWith(position: posToApply);
  }

  void updateRelationPosition(
    String id,
    Offset newPos, {
    bool isFinal = false,
    bool snap = true,
  }) {
    final index = _relations.indexWhere((r) => r.id == id);
    if (index != -1) {
      final delta = newPos - _relations[index].position;

      if (_selectedIds.contains(id)) {
        for (final selId in _selectedIds) {
          if (selId.startsWith('e')) {
            final eIdx = _entities.indexWhere((e) => e.id == selId);
            if (eIdx != -1) {
              _moveEntity(eIdx, _entities[eIdx].position + delta, snap: snap);
            }
          } else {
            final rIdx = _relations.indexWhere((r) => r.id == selId);
            if (rIdx != -1) {
              _moveRelation(
                rIdx,
                _relations[rIdx].position + delta,
                snap: snap,
              );
            }
          }
        }
      } else {
        _moveRelation(index, newPos, snap: snap);
      }

      if (isFinal) saveToHistory();
      notifyListeners();
    }
  }

  void _moveRelation(int index, Offset newPos, {bool snap = true}) {
    Offset posToApply = newPos;
    if (snap) {
      posToApply = Offset(
        (newPos.dx / gridStep).round() * gridStep,
        (newPos.dy / gridStep).round() * gridStep,
      );
    }
    _relations[index] = _relations[index].copyWith(position: posToApply);
  }

  void moveSelection(Offset delta) {
    if (_selectedIds.isEmpty) return;

    for (final id in _selectedIds) {
      if (id.startsWith('e')) {
        final idx = _entities.indexWhere((e) => e.id == id);
        if (idx != -1) {
          _moveEntity(idx, _entities[idx].position + delta, snap: true);
        }
      } else {
        final idx = _relations.indexWhere((r) => r.id == id);
        if (idx != -1) {
          _moveRelation(idx, _relations[idx].position + delta, snap: true);
        }
      }
    }
    saveToHistory();
    notifyListeners();
  }

  void alignSelection(String direction) {
    if (_selectedIds.length < 2) return;

    double? targetCoord;

    // 1. Trouver la coordonnée cible
    for (final id in _selectedIds) {
      Offset pos;
      if (id.startsWith('e')) {
        pos = _entities.firstWhere((e) => e.id == id).position;
      } else {
        pos = _relations.firstWhere((r) => r.id == id).position;
      }

      switch (direction) {
        case 'left':
          targetCoord = (targetCoord == null)
              ? pos.dx
              : math.min(targetCoord, pos.dx);
          break;
        case 'top':
          targetCoord = (targetCoord == null)
              ? pos.dy
              : math.min(targetCoord, pos.dy);
          break;
        case 'right':
          targetCoord = (targetCoord == null)
              ? pos.dx
              : math.max(targetCoord, pos.dx);
          break;
        case 'bottom':
          targetCoord = (targetCoord == null)
              ? pos.dy
              : math.max(targetCoord, pos.dy);
          break;
      }
    }

    if (targetCoord == null) return;

    // 2. Appliquer l'alignement
    for (final id in _selectedIds) {
      if (id.startsWith('e')) {
        final idx = _entities.indexWhere((e) => e.id == id);
        final current = _entities[idx].position;
        Offset newPos = (direction == 'left' || direction == 'right')
            ? Offset(targetCoord, current.dy)
            : Offset(current.dx, targetCoord);
        _moveEntity(idx, newPos, snap: true);
      } else {
        final idx = _relations.indexWhere((r) => r.id == id);
        final current = _relations[idx].position;
        Offset newPos = (direction == 'left' || direction == 'right')
            ? Offset(targetCoord, current.dy)
            : Offset(current.dx, targetCoord);
        _moveRelation(idx, newPos, snap: true);
      }
    }

    saveToHistory();
    notifyListeners();
  }

  // -- Property Panel Methods --

  void updateEntityName(String id, String newName) {
    // Validation
    if (newName.trim().isEmpty) return;

    final index = _entities.indexWhere((e) => e.id == id);
    if (index != -1) {
      _entities[index] = _entities[index].copyWith(name: newName);
      _scheduleHistorySave();
    }
  }

  void updateRelationName(String id, String newName) {
    // Validation
    if (newName.trim().isEmpty) return;

    final index = _relations.indexWhere((r) => r.id == id);
    if (index != -1) {
      _relations[index] = _relations[index].copyWith(name: newName);
      _scheduleHistorySave();
    }
  }

  void addAttribute(String itemId) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes)
        ..add(const McdAttribute(name: 'new_attr'));
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes)
          ..add(const McdAttribute(name: 'new_attr'));
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
      } else {
        return;
      }
    }
    saveToHistory();
    notifyListeners();
  }

  void setZoom(double value) {
    _zoom = value.clamp(0.5, 2.0);
    notifyListeners();
  }

  void autoFixMissingPK(String entityId) {
    final index = _entities.indexWhere((e) => e.id == entityId);
    if (index != -1) {
      final entity = _entities[index];
      // Vérifier si elle n'a vraiment pas de PK
      if (!entity.attributes.any((a) => a.isPrimaryKey)) {
        final newAttrs = List<McdAttribute>.from(entity.attributes)
          ..insert(0, const McdAttribute(name: 'id', isPrimaryKey: true));
        _entities[index] = entity.copyWith(attributes: newAttrs);
        saveToHistory();
        notifyListeners();
      }
    }
  }

  // Permet de forcer une sauvegarde physique via AppProvider
  VoidCallback? _onSaveRequested;
  void setOnSaveRequested(VoidCallback? callback) =>
      _onSaveRequested = callback;
  void requestSave() => _onSaveRequested?.call();

  // -- CRUD Operations --

  void createEntity(Offset position) {
    final newId = 'e${DateTime.now().millisecondsSinceEpoch}';
    // Ajuster la position en fonction du panOffset et du zoom
    final adjustedPos = (position / _zoom) - _panOffset;

    _entities.add(
      McdEntity(
        id: newId,
        name: 'NOUVELLE_ENTITE',
        position: adjustedPos,
        attributes: [McdAttribute(name: 'id', isPrimaryKey: true)],
      ),
    );
    saveToHistory();
    notifyListeners();
  }

  void createRelation(Offset position) {
    final newId = 'r${DateTime.now().millisecondsSinceEpoch}';
    // Ajuster la position en fonction du panOffset et du zoom
    final adjustedPos = (position / _zoom) - _panOffset;

    _relations.add(
      McdRelation(
        id: newId,
        name: 'Relation',
        position: adjustedPos,
        attributes: const [],
      ),
    );
    saveToHistory();
    notifyListeners();
  }

  void deleteEntity(String id) {
    _entities.removeWhere((e) => e.id == id);
    // Supprimer aussi les liens associés
    _links.removeWhere((link) => link.entityId == id);
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    }
    saveToHistory();
    notifyListeners();
  }

  void deleteRelation(String id) {
    _relations.removeWhere((r) => r.id == id);
    // Supprimer aussi les liens associés
    _links.removeWhere((link) => link.relationId == id);
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    }
    saveToHistory();
    notifyListeners();
  }

  void deleteSelectedItems() {
    if (_selectedIds.isEmpty) return;

    final idsToRemove = List<String>.from(_selectedIds);
    for (final id in idsToRemove) {
      if (id.startsWith('e')) {
        deleteEntity(id);
      } else {
        deleteRelation(id);
      }
    }
    _selectedIds.clear();
    saveToHistory();
    notifyListeners();
  }

  void updateAttributeName(String itemId, int attrIndex, String newName) {
    if (newName.trim().isEmpty) return;

    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(name: newName);
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(name: newName);
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void updateAttributeType(String itemId, int attrIndex, String newType) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(type: newType);
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(type: newType);
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void updateAttributeDescription(
    String itemId,
    int attrIndex,
    String description,
  ) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
        description: description,
      );
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
          description: description,
        );
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void updateAttributeLength(String itemId, int attrIndex, String length) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(length: length);
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(length: length);
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void updateAttributeConstraints(
    String itemId,
    int attrIndex,
    String constraints,
  ) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
        constraints: constraints,
      );
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
          constraints: constraints,
        );
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void updateAttributeRules(String itemId, int attrIndex, String rules) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(rules: rules);
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(rules: rules);
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void updateAttributeCustomField(
    String itemId,
    int attrIndex,
    String key,
    String value,
  ) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      final newCustom = Map<String, String>.from(
        newAttrs[attrIndex].customFields,
      );
      newCustom[key] = value;
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
        customFields: newCustom,
      );
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      _scheduleHistorySave();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        final newCustom = Map<String, String>.from(
          newAttrs[attrIndex].customFields,
        );
        newCustom[key] = value;
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
          customFields: newCustom,
        );
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        _scheduleHistorySave();
      }
    }
  }

  void addAttributeToEntityByName(String entityName, String attrName) {
    int index = _entities.indexWhere((e) => e.name == entityName);
    if (index != -1) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes)
        ..add(McdAttribute(name: attrName));
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      saveToHistory();
      notifyListeners();
    } else {
      index = _relations.indexWhere((r) => r.name == entityName);
      if (index != -1) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes)
          ..add(McdAttribute(name: attrName));
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        saveToHistory();
        notifyListeners();
      }
    }
  }

  void toggleAttributePrimaryKey(String itemId, int attrIndex) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes);
      newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
        isPrimaryKey: !newAttrs[attrIndex].isPrimaryKey,
      );
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      saveToHistory();
      notifyListeners();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes);
        newAttrs[attrIndex] = newAttrs[attrIndex].copyWith(
          isPrimaryKey: !newAttrs[attrIndex].isPrimaryKey,
        );
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        saveToHistory();
        notifyListeners();
      }
    }
  }

  void deleteAttribute(String itemId, int attrIndex) {
    int index = _entities.indexWhere((e) => e.id == itemId);
    if (index != -1 && attrIndex < _entities[index].attributes.length) {
      final newAttrs = List<McdAttribute>.from(_entities[index].attributes)
        ..removeAt(attrIndex);
      _entities[index] = _entities[index].copyWith(attributes: newAttrs);
      saveToHistory();
      notifyListeners();
    } else {
      index = _relations.indexWhere((r) => r.id == itemId);
      if (index != -1 && attrIndex < _relations[index].attributes.length) {
        final newAttrs = List<McdAttribute>.from(_relations[index].attributes)
          ..removeAt(attrIndex);
        _relations[index] = _relations[index].copyWith(attributes: newAttrs);
        saveToHistory();
        notifyListeners();
      }
    }
  }

  void createLink(String entityId, String relationId) {
    // Vérifier que le lien n'existe pas déjà
    final exists = _links.any(
      (link) => link.entityId == entityId && link.relationId == relationId,
    );
    if (!exists) {
      _links.add(
        McdLink(
          entityId: entityId,
          relationId: relationId,
          cardinalities: '1,n',
        ),
      );
      saveToHistory();
      notifyListeners();
    }
  }

  void updateLinkCardinality(
    String entityId,
    String relationId,
    String newCardinality,
  ) {
    final index = _links.indexWhere(
      (link) => link.entityId == entityId && link.relationId == relationId,
    );
    if (index != -1) {
      _links[index] = _links[index].copyWith(cardinalities: newCardinality);
      saveToHistory();
      notifyListeners();
    }
  }

  void deleteLink(String entityId, String relationId) {
    _links.removeWhere(
      (link) => link.entityId == entityId && link.relationId == relationId,
    );
    saveToHistory();
    notifyListeners();
  }

  List<McdLink> getLinksForRelation(String relationId) {
    return _links.where((l) => l.relationId == relationId).toList();
  }

  List<McdEntity> getAvailableEntitiesForRelation(String relationId) {
    final linkedEntityIds = getLinksForRelation(
      relationId,
    ).map((l) => l.entityId).toSet();
    return _entities.where((e) => !linkedEntityIds.contains(e.id)).toList();
  }

  // -- Simulation SQL Methods --

  /// Initialiser le moteur SQL avec le MLD actuel
  Future<void> initializeSimulation() async {
    // Transformer le MCD en MLD
    _currentMld = MldTransformer.transform(mcd);

    // Créer et initialiser le moteur SQL
    _sqlEngine = SqlEngine();
    await _sqlEngine!.initialize(_currentMld!);

    notifyListeners();
  }

  /// Ajouter un enregistrement dans une table MLD
  Future<void> addRecordToTable(
    String tableName,
    Map<String, dynamic> data,
  ) async {
    if (_sqlEngine == null) {
      throw StateError('Le moteur SQL n\'est pas initialisé');
    }

    await _sqlEngine!.insertData(tableName, data);
    notifyListeners();
  }

  /// Exécuter une requête SQL
  Future<QueryResult> executeQuery(String sql) async {
    if (_sqlEngine == null) {
      return QueryResult(
        rows: [],
        columns: [],
        rowCount: 0,
        executionTime: Duration.zero,
        error: 'Le moteur SQL n\'est pas initialisé',
      );
    }

    return await _sqlEngine!.executeQuery(sql);
  }

  /// Obtenir les données d'une table
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    if (_sqlEngine == null) return [];
    return await _sqlEngine!.getTableData(tableName);
  }

  /// Vider une table
  Future<void> clearTableData(String tableName) async {
    if (_sqlEngine == null) return;
    await _sqlEngine!.clearTable(tableName);
    notifyListeners();
  }

  /// Vider toutes les tables
  Future<void> clearAllTables() async {
    if (_sqlEngine == null) return;
    await _sqlEngine!.clearAllTables();
    notifyListeners();
  }

  /// Fermer le moteur SQL
  Future<void> closeSimulation() async {
    await _sqlEngine?.close();
    _sqlEngine = null;
    _currentMld = null;
    notifyListeners();
  }

  // -- Persistance (JSON) --

  String serialize() {
    return jsonEncode(mcd.toJson());
  }

  void deserialize(String jsonStr, {bool clearHistory = true}) {
    if (jsonStr.trim().isEmpty) {
      _entities.clear();
      _relations.clear();
      _links.clear();
      _selectedIds.clear();
      if (clearHistory) _resetHistory();
      notifyListeners();
      return;
    }

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final loadedMcd = Mcd.fromJson(data);

      // On ne vide que si le parsing a réussi
      _entities.clear();
      _relations.clear();
      _links.clear();
      _selectedIds.clear();

      _entities.addAll(loadedMcd.entities);
      _relations.addAll(loadedMcd.relations);
      _links.addAll(loadedMcd.links);
      _functionalDependencies.clear();
      _functionalDependencies.addAll(loadedMcd.functionalDependencies);

      if (clearHistory) {
        _resetHistory();
      } else {
        saveToHistory();
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error deserializing Merise data: $e");
      // On ne touche à rien en cas d'erreur pour éviter de tout perdre
      notifyListeners();
    }
  }
}
