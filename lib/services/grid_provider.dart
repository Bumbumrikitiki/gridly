import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/models/circuit_line.dart';

class GridProvider extends ChangeNotifier {
  final List<GridNode> _nodes = [];
  final Map<GridNode, GridNode?> _parentByNode = {};
  final Map<GridNode, List<GridNode>> _childrenByNode = {};
  final Map<GridNode, double> _aggregatePowerKw = {};
  final Map<GridNode, double> _aggregateVoltageDrop = {};
  String _buildingName = '';

  List<GridNode> get nodes => List.unmodifiable(_nodes);

  Map<GridNode, double> get aggregatePowerKw =>
      Map.unmodifiable(_aggregatePowerKw);

  Map<GridNode, double> get aggregateVoltageDrop =>
      Map.unmodifiable(_aggregateVoltageDrop);

  String get buildingName => _buildingName;

  void setBuildingName(String value, {bool shouldNotify = true}) {
    final normalized = value.trim();
    if (_buildingName == normalized) {
      return;
    }

    _buildingName = normalized;
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void addNode(GridNode node, {GridNode? parent, bool shouldNotify = true}) {
    if (!_nodes.contains(node)) {
      _nodes.add(node);
    }

    _parentByNode[node] = parent;
    node.parentId = parent?.id;
    _childrenByNode.putIfAbsent(node, () => []);

    if (parent != null) {
      _childrenByNode.putIfAbsent(parent, () => []);
      if (!_childrenByNode[parent]!.contains(node)) {
        _childrenByNode[parent]!.add(node);
      }
    }

    if (shouldNotify) {
      recalculateHierarchy();
    }
  }

  void removeNode(GridNode node, {bool shouldNotify = true}) {
    if (!_nodes.contains(node)) {
      return;
    }

    final nodesToRemove = _collectSubtree(node);
    for (final entry in nodesToRemove) {
      _nodes.remove(entry);
      final parent = _parentByNode.remove(entry);
      if (parent != null) {
        _childrenByNode[parent]?.remove(entry);
      }
      _childrenByNode.remove(entry);
      _aggregatePowerKw.remove(entry);
      _aggregateVoltageDrop.remove(entry);
    }

    if (shouldNotify) {
      recalculateHierarchy();
    }
  }

  void updateNodeParent(
    GridNode node,
    GridNode? newParent, {
    bool shouldNotify = true,
  }) {
    if (!_nodes.contains(node)) {
      return;
    }

    final previousParent = _parentByNode[node];
    if (previousParent == newParent) {
      return;
    }

    if (newParent == node || _isDescendant(newParent, node)) {
      return;
    }

    if (previousParent != null) {
      _childrenByNode[previousParent]?.remove(node);
    }

    _parentByNode[node] = newParent;
    node.parentId = newParent?.id;
    if (newParent != null) {
      _childrenByNode.putIfAbsent(newParent, () => []);
      if (!_childrenByNode[newParent]!.contains(node)) {
        _childrenByNode[newParent]!.add(node);
      }
    }

    if (shouldNotify) {
      recalculateHierarchy();
    }
  }

  void recalculateHierarchy() {
    _aggregatePowerKw.clear();
    _aggregateVoltageDrop.clear();

    final roots = _nodes.where((node) => _parentByNode[node] == null);
    final visiting = <GridNode>{};

    for (final root in roots) {
      _computeAggregate(root, visiting);
    }

    // Opóźnij notifyListeners aby uniknąć "markNeedsBuild during build"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  double _computeAggregate(GridNode node, Set<GridNode> visiting) {
    if (_aggregatePowerKw.containsKey(node)) {
      return _aggregatePowerKw[node]!;
    }

    if (visiting.contains(node)) {
      throw StateError('Cycle detected in grid hierarchy.');
    }

    visiting.add(node);

    final children = _childrenByNode[node] ?? const [];
    var totalChildrenPower = 0.0;
    var maxChildDrop = 0.0;

    for (final child in children) {
      final childAggregate = _computeAggregate(child, visiting);
      totalChildrenPower += childAggregate;
      maxChildDrop = max(maxChildDrop, _aggregateVoltageDrop[child] ?? 0.0);
    }

    final diversity = GridNode.getDiversityFactor(children.length);
    final totalPower = node.powerKw + (totalChildrenPower * diversity);

    final nodeDrop = _calculateVoltageDropForPower(node, totalPower);
    final totalDrop = nodeDrop + maxChildDrop;

    _aggregatePowerKw[node] = totalPower;
    _aggregateVoltageDrop[node] = totalDrop;

    visiting.remove(node);

    return totalPower;
  }

  double _calculateVoltageDropForPower(GridNode node, double powerKw) {
    final conductivity = node.material == ConductorMaterial.cu ? 56.0 : 34.0;
    final current = _calculateIbForPower(node, powerKw);

    if (node.isThreePhase) {
      return (sqrt(3) * node.lengthM * current) /
          (conductivity * node.crossSectionMm2);
    }

    return (2 * node.lengthM * current) / (conductivity * node.crossSectionMm2);
  }

  double _calculateIbForPower(GridNode node, double powerKw) {
    if (node.isThreePhase) {
      return (powerKw * 1000) / (sqrt(3) * 400);
    }

    return (powerKw * 1000) / 230;
  }

  List<GridNode> _collectSubtree(GridNode node) {
    final result = <GridNode>[];
    final stack = <GridNode>[node];

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      result.add(current);
      stack.addAll(_childrenByNode[current] ?? const []);
    }

    return result;
  }

  bool _isDescendant(GridNode? candidate, GridNode root) {
    if (candidate == null) {
      return false;
    }

    final stack = <GridNode>[root];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final children = _childrenByNode[current] ?? const [];
      if (children.contains(candidate)) {
        return true;
      }
      stack.addAll(children);
    }

    return false;
  }

  void updateConnectionCable(
    GridNode node, {
    required double lengthM,
    required double crossSectionMm2,
    required int cableCores,
    required ConductorMaterial material,
    bool shouldNotify = true,
  }) {
    if (!_nodes.contains(node)) {
      return;
    }

    node.lengthM = lengthM;
    node.crossSectionMm2 = crossSectionMm2;
    node.cableCores = cableCores;
    node.material = material;

    if (shouldNotify) {
      recalculateHierarchy();
    }
  }

  void addProtectionSlot(DistributionBoard board, BoardProtectionSlot slot) {
    if (_nodes.contains(board)) {
      board.protectionSlots.add(slot);
      notifyListeners();
    }
  }

  void updateProtectionSlot(
    DistributionBoard board,
    BoardProtectionSlot updatedSlot,
  ) {
    if (_nodes.contains(board)) {
      final index =
          board.protectionSlots.indexWhere((e) => e.id == updatedSlot.id);
      if (index >= 0) {
        board.protectionSlots[index] = updatedSlot;
        notifyListeners();
      }
    }
  }

  void removeProtectionSlot(DistributionBoard board, String slotId) {
    if (_nodes.contains(board)) {
      board.protectionSlots.removeWhere((e) => e.id == slotId);
      notifyListeners();
    }
  }

  void updateBoardAdditionalEquipment(
    DistributionBoard board,
    List<BoardAdditionalEquipment> equipment,
  ) {
    if (_nodes.contains(board)) {
      board.additionalEquipment
        ..clear()
        ..addAll(equipment.toSet());
      notifyListeners();
    }
  }

  // ============ Circuit Line Management ============

  /// Add a circuit line to a node
  void addCircuitLine(GridNode node, CircuitLine line) {
    if (_nodes.contains(node)) {
      node.circuitLines.add(line);
      notifyListeners();
    }
  }

  /// Update a circuit line in a node
  void updateCircuitLine(GridNode node, CircuitLine updatedLine) {
    if (_nodes.contains(node)) {
      final index = node.circuitLines.indexWhere((e) => e.id == updatedLine.id);
      if (index >= 0) {
        node.circuitLines[index] = updatedLine;
        notifyListeners();
      }
    }
  }

  /// Remove a circuit line from a node
  void removeCircuitLine(GridNode node, String lineId) {
    if (_nodes.contains(node)) {
      node.circuitLines.removeWhere((e) => e.id == lineId);
      notifyListeners();
    }
  }

  /// Get all circuit lines for a node
  List<CircuitLine> getCircuitLines(GridNode node) {
    if (_nodes.contains(node)) {
      return List.unmodifiable(node.circuitLines);
    }
    return const [];
  }
}
