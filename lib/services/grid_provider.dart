import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/models/circuit_line.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GridStructureSummary {
  final String id;
  final String name;
  final DateTime updatedAt;

  const GridStructureSummary({
    required this.id,
    required this.name,
    required this.updatedAt,
  });
}

class TemporarySupplyConfig {
  final String networkSystem;
  final double? osdConnectionPowerKw;
  final double? osdMainProtectionA;
  final double? assumedShortCircuitCurrentKa;
  final double? assumedLoopImpedanceOhm;
  final bool rcdRequired;
  final bool siteEarthingRequired;

  const TemporarySupplyConfig({
    this.networkSystem = 'TN-C-S',
    this.osdConnectionPowerKw,
    this.osdMainProtectionA,
    this.assumedShortCircuitCurrentKa,
    this.assumedLoopImpedanceOhm,
    this.rcdRequired = true,
    this.siteEarthingRequired = true,
  });

  TemporarySupplyConfig copyWith({
    String? networkSystem,
    double? osdConnectionPowerKw,
    bool keepOsdConnectionPowerKw = true,
    double? osdMainProtectionA,
    bool keepOsdMainProtectionA = true,
    double? assumedShortCircuitCurrentKa,
    bool keepAssumedShortCircuitCurrentKa = true,
    double? assumedLoopImpedanceOhm,
    bool keepAssumedLoopImpedanceOhm = true,
    bool? rcdRequired,
    bool? siteEarthingRequired,
  }) {
    return TemporarySupplyConfig(
      networkSystem: networkSystem ?? this.networkSystem,
      osdConnectionPowerKw: keepOsdConnectionPowerKw
          ? (osdConnectionPowerKw ?? this.osdConnectionPowerKw)
          : osdConnectionPowerKw,
      osdMainProtectionA: keepOsdMainProtectionA
          ? (osdMainProtectionA ?? this.osdMainProtectionA)
          : osdMainProtectionA,
      assumedShortCircuitCurrentKa: keepAssumedShortCircuitCurrentKa
          ? (assumedShortCircuitCurrentKa ?? this.assumedShortCircuitCurrentKa)
          : assumedShortCircuitCurrentKa,
      assumedLoopImpedanceOhm: keepAssumedLoopImpedanceOhm
          ? (assumedLoopImpedanceOhm ?? this.assumedLoopImpedanceOhm)
          : assumedLoopImpedanceOhm,
      rcdRequired: rcdRequired ?? this.rcdRequired,
      siteEarthingRequired: siteEarthingRequired ?? this.siteEarthingRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'networkSystem': networkSystem,
      'osdConnectionPowerKw': osdConnectionPowerKw,
      'osdMainProtectionA': osdMainProtectionA,
      'assumedShortCircuitCurrentKa': assumedShortCircuitCurrentKa,
      'assumedLoopImpedanceOhm': assumedLoopImpedanceOhm,
      'rcdRequired': rcdRequired,
      'siteEarthingRequired': siteEarthingRequired,
    };
  }

  factory TemporarySupplyConfig.fromMap(Map<String, dynamic> map) {
    return TemporarySupplyConfig(
      networkSystem:
          (map['networkSystem'] as String?)?.trim().isNotEmpty == true
              ? (map['networkSystem'] as String)
              : 'TN-C-S',
      osdConnectionPowerKw: (map['osdConnectionPowerKw'] as num?)?.toDouble(),
      osdMainProtectionA: (map['osdMainProtectionA'] as num?)?.toDouble(),
      assumedShortCircuitCurrentKa:
          (map['assumedShortCircuitCurrentKa'] as num?)?.toDouble(),
      assumedLoopImpedanceOhm:
          (map['assumedLoopImpedanceOhm'] as num?)?.toDouble(),
      rcdRequired: (map['rcdRequired'] as bool?) ?? true,
      siteEarthingRequired: (map['siteEarthingRequired'] as bool?) ?? true,
    );
  }
}

class GridProvider extends ChangeNotifier {
  static const _structuresStorageKey = 'grid_structures_v1';
  static const _currentStructureStorageKey = 'grid_current_structure_id_v1';

  final List<GridNode> _nodes = [];
  final Map<GridNode, GridNode?> _parentByNode = {};
  final Map<GridNode, List<GridNode>> _childrenByNode = {};
  final Map<GridNode, double> _aggregatePowerKw = {};
  final Map<GridNode, double> _aggregateVoltageDrop = {};
  final Map<String, Map<String, dynamic>> _structureDataById = {};
  final List<GridStructureSummary> _structures = [];

  String _buildingName = '';
  TemporarySupplyConfig _temporarySupplyConfig = const TemporarySupplyConfig();
  String? _currentStructureId;
  bool _structuresLoaded = false;
  bool _isStructuresLoading = false;
  Timer? _snapshotPersistTimer;
  bool _isSnapshotSaving = false;
  bool _hasPendingSnapshotSave = false;
  bool _hasSnapshotChanges = false;
  int _topologyRevision = 0;

  List<GridNode> get nodes => List.unmodifiable(_nodes);

  Map<GridNode, double> get aggregatePowerKw =>
      Map.unmodifiable(_aggregatePowerKw);

  Map<GridNode, double> get aggregateVoltageDrop =>
      Map.unmodifiable(_aggregateVoltageDrop);

  String get buildingName => _buildingName;
  TemporarySupplyConfig get temporarySupplyConfig => _temporarySupplyConfig;
  List<GridStructureSummary> get structures => List.unmodifiable(_structures);
  String? get currentStructureId => _currentStructureId;
  bool get structuresLoaded => _structuresLoaded;
  bool get isStructuresLoading => _isStructuresLoading;
  int get topologyRevision => _topologyRevision;

  void _bumpTopologyRevision() {
    _topologyRevision++;
  }

  String get currentStructureName {
    if (_currentStructureId == null) {
      return 'Brak struktury';
    }

    for (final structure in _structures) {
      if (structure.id == _currentStructureId) {
        return structure.name;
      }
    }

    return 'Brak struktury';
  }

  Future<void> loadSavedStructures({bool forceReload = false}) async {
    if (_structuresLoaded && !forceReload) {
      return;
    }

    _isStructuresLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_structuresStorageKey);
      final savedCurrentId = prefs.getString(_currentStructureStorageKey);

      _structures.clear();
      _structureDataById.clear();

      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;

        for (final item in decoded) {
          if (item is! Map<String, dynamic>) {
            continue;
          }

          final id = (item['id'] as String?)?.trim();
          if (id == null || id.isEmpty) {
            continue;
          }

          final name = (item['name'] as String?)?.trim();
          final updatedAtRaw = item['updatedAt'] as String?;
          final parsedUpdatedAt = DateTime.tryParse(updatedAtRaw ?? '');

          _structures.add(
            GridStructureSummary(
              id: id,
              name: (name == null || name.isEmpty) ? 'Struktura' : name,
              updatedAt: parsedUpdatedAt ?? DateTime.now(),
            ),
          );
          _structureDataById[id] = item;
        }
      }

      if (_structures.isEmpty) {
        final initialName = _buildingName.trim().isEmpty
            ? 'Nowa struktura'
            : _buildingName.trim();
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        final structure = GridStructureSummary(
          id: id,
          name: initialName,
          updatedAt: DateTime.now(),
        );
        _structures.add(structure);
        _currentStructureId = id;
        _structureDataById[id] = _buildCurrentStructureMap(
          id: id,
          name: initialName,
        );
        await _saveStructuresToStorage();
      } else {
        _currentStructureId = _structureDataById.containsKey(savedCurrentId)
            ? savedCurrentId
            : _structures.first.id;
        final currentData = _structureDataById[_currentStructureId];
        if (currentData != null) {
          _applyStructureData(currentData, shouldNotify: false);
          recalculateHierarchy();
        }
      }
    } finally {
      _structuresLoaded = true;
      _isStructuresLoading = false;
      notifyListeners();
    }
  }

  Future<void> createNewStructure(String name) async {
    await loadSavedStructures();

    final normalizedName = name.trim().isEmpty ? 'Nowa struktura' : name.trim();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final summary = GridStructureSummary(
      id: id,
      name: normalizedName,
      updatedAt: DateTime.now(),
    );

    _structures.add(summary);
    _currentStructureId = id;
    _nodes.clear();
    _parentByNode.clear();
    _childrenByNode.clear();
    _aggregatePowerKw.clear();
    _aggregateVoltageDrop.clear();
    _buildingName = normalizedName;
    _temporarySupplyConfig = const TemporarySupplyConfig();

    _structureDataById[id] = _buildCurrentStructureMap(
      id: id,
      name: normalizedName,
    );

    _bumpTopologyRevision();
    await _saveStructuresToStorage();
    notifyListeners();
  }

  Future<void> switchStructure(String structureId) async {
    await loadSavedStructures();
    final target = _structureDataById[structureId];
    if (target == null) {
      return;
    }

    _currentStructureId = structureId;
    _applyStructureData(target);
    await _saveStructuresToStorage();
  }

  Future<void> deleteStructure(String structureId) async {
    await loadSavedStructures();

    _structures.removeWhere((structure) => structure.id == structureId);
    _structureDataById.remove(structureId);

    if (_structures.isEmpty) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      const name = 'Nowa struktura';
      _currentStructureId = id;
      _structures.add(
        GridStructureSummary(
          id: id,
          name: name,
          updatedAt: DateTime.now(),
        ),
      );

      _nodes.clear();
      _parentByNode.clear();
      _childrenByNode.clear();
      _aggregatePowerKw.clear();
      _aggregateVoltageDrop.clear();
      _buildingName = name;
      _temporarySupplyConfig = const TemporarySupplyConfig();

      _structureDataById[id] = _buildCurrentStructureMap(
        id: id,
        name: name,
      );
      _bumpTopologyRevision();
    } else {
      if (_currentStructureId == structureId) {
        _currentStructureId = _structures.first.id;
      }

      final currentData = _structureDataById[_currentStructureId];
      if (currentData != null) {
        _applyStructureData(currentData);
      }
    }

    await _saveStructuresToStorage();
    notifyListeners();
  }

  void setBuildingName(String value, {bool shouldNotify = true}) {
    final normalized = value.trim();
    if (_buildingName == normalized) {
      return;
    }

    _buildingName = normalized;
    unawaited(_persistCurrentStructureSnapshot());
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void updateTemporarySupplyConfig(
    TemporarySupplyConfig config, {
    bool shouldNotify = true,
  }) {
    _temporarySupplyConfig = config;
    unawaited(_persistCurrentStructureSnapshot());
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

    _bumpTopologyRevision();

    // Opóźnij notifyListeners aby uniknąć "markNeedsBuild during build"
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
    unawaited(_persistCurrentStructureSnapshot());
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

  void updateNodeConfiguration(
    GridNode node, {
    required String name,
    String? location,
    required double powerKw,
    required double lengthM,
    required double crossSectionMm2,
    required int cableCores,
    required double ratedCurrentA,
    required ConductorMaterial material,
    bool? isPenSplitPoint,
    int? socketCount230V,
    int? socketCount400V,
    bool? isThreePhaseReceiver,
    bool shouldNotify = true,
  }) {
    if (!_nodes.contains(node)) {
      return;
    }

    node.name = name.trim();
    if (location != null) {
      node.location = location.trim();
    }
    node.powerKw = powerKw;
    node.lengthM = lengthM;
    node.crossSectionMm2 = crossSectionMm2;
    node.cableCores = cableCores;
    node.ratedCurrentA = ratedCurrentA;
    node.material = material;

    if (node is DistributionBoard) {
      if (isPenSplitPoint != null) {
        node.isPenSplitPoint = isPenSplitPoint;
      }
      node.socketCount230V = socketCount230V;
      node.socketCount400V = socketCount400V;
    } else if (node is PowerReceiver && isThreePhaseReceiver != null) {
      node.isThreePhaseReceiver = isThreePhaseReceiver;
    }

    if (shouldNotify) {
      recalculateHierarchy();
    }
  }

  void addProtectionSlot(DistributionBoard board, BoardProtectionSlot slot) {
    if (_nodes.contains(board)) {
      board.protectionSlots.add(slot);
      _bumpTopologyRevision();
      unawaited(_persistCurrentStructureSnapshot());
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
        _bumpTopologyRevision();
        unawaited(_persistCurrentStructureSnapshot());
        notifyListeners();
      }
    }
  }

  void removeProtectionSlot(DistributionBoard board, String slotId) {
    if (_nodes.contains(board)) {
      board.protectionSlots.removeWhere((e) => e.id == slotId);
      _bumpTopologyRevision();
      unawaited(_persistCurrentStructureSnapshot());
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
      _bumpTopologyRevision();
      unawaited(_persistCurrentStructureSnapshot());
      notifyListeners();
    }
  }

  // ============ Circuit Line Management ============

  /// Add a circuit line to a node
  void addCircuitLine(GridNode node, CircuitLine line) {
    if (_nodes.contains(node)) {
      node.circuitLines.add(line);
      _bumpTopologyRevision();
      unawaited(_persistCurrentStructureSnapshot());
      notifyListeners();
    }
  }

  /// Update a circuit line in a node
  void updateCircuitLine(GridNode node, CircuitLine updatedLine) {
    if (_nodes.contains(node)) {
      final index = node.circuitLines.indexWhere((e) => e.id == updatedLine.id);
      if (index >= 0) {
        node.circuitLines[index] = updatedLine;
        _bumpTopologyRevision();
        unawaited(_persistCurrentStructureSnapshot());
        notifyListeners();
      }
    }
  }

  /// Remove a circuit line from a node
  void removeCircuitLine(GridNode node, String lineId) {
    if (_nodes.contains(node)) {
      node.circuitLines.removeWhere((e) => e.id == lineId);
      _bumpTopologyRevision();
      unawaited(_persistCurrentStructureSnapshot());
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

  Future<void> _persistCurrentStructureSnapshot() async {
    if (!_structuresLoaded || _currentStructureId == null) {
      return;
    }

    var currentSummaryIndex = -1;
    for (var i = 0; i < _structures.length; i++) {
      if (_structures[i].id == _currentStructureId) {
        currentSummaryIndex = i;
        break;
      }
    }

    if (currentSummaryIndex < 0) {
      return;
    }

    final currentSummary = _structures[currentSummaryIndex];
    final snapshot = _buildCurrentStructureMap(
      id: currentSummary.id,
      name: currentSummary.name,
    );
    _structureDataById[currentSummary.id] = snapshot;
    _structures[currentSummaryIndex] = GridStructureSummary(
      id: currentSummary.id,
      name: currentSummary.name,
      updatedAt: DateTime.now(),
    );

    _hasSnapshotChanges = true;
    _scheduleSnapshotSave();
  }

  void _scheduleSnapshotSave() {
    _snapshotPersistTimer?.cancel();
    _snapshotPersistTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(_flushSnapshotSave());
    });
  }

  Future<void> _flushSnapshotSave() async {
    if (!_hasSnapshotChanges && !_isSnapshotSaving) {
      return;
    }

    if (_isSnapshotSaving) {
      _hasPendingSnapshotSave = true;
      return;
    }

    _isSnapshotSaving = true;
    try {
      do {
        _hasPendingSnapshotSave = false;
        await _saveStructuresToStorage();
        _hasSnapshotChanges = false;
      } while (_hasPendingSnapshotSave);
    } finally {
      _isSnapshotSaving = false;
    }
  }

  Future<void> flushPendingSnapshotSave() async {
    _snapshotPersistTimer?.cancel();
    _snapshotPersistTimer = null;
    await _flushSnapshotSave();
  }

  Map<String, dynamic> _buildCurrentStructureMap({
    required String id,
    required String name,
  }) {
    return {
      'id': id,
      'name': name,
      'buildingName': _buildingName,
      'updatedAt': DateTime.now().toIso8601String(),
      'temporarySupplyConfig': _temporarySupplyConfig.toMap(),
      'nodes': _nodes.map((node) => node.toMap()).toList(),
    };
  }

  void _applyStructureData(
    Map<String, dynamic> structureData, {
    bool shouldNotify = true,
  }) {
    final parsedNodes = <GridNode>[];
    final rawNodes = structureData['nodes'];
    if (rawNodes is List) {
      for (final item in rawNodes) {
        if (item is Map<String, dynamic>) {
          parsedNodes.add(GridNode.fromMap(item));
        } else if (item is Map) {
          parsedNodes.add(
            GridNode.fromMap(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          );
        }
      }
    }

    _nodes
      ..clear()
      ..addAll(parsedNodes);
    _buildingName = (structureData['buildingName'] as String?)?.trim() ?? '';
    final rawSupplyConfig = structureData['temporarySupplyConfig'];
    if (rawSupplyConfig is Map<String, dynamic>) {
      _temporarySupplyConfig = TemporarySupplyConfig.fromMap(rawSupplyConfig);
    } else if (rawSupplyConfig is Map) {
      _temporarySupplyConfig = TemporarySupplyConfig.fromMap(
        Map<String, dynamic>.from(rawSupplyConfig as Map<dynamic, dynamic>),
      );
    } else {
      _temporarySupplyConfig = const TemporarySupplyConfig();
    }

    _rebuildHierarchyMaps();
    _aggregatePowerKw.clear();
    _aggregateVoltageDrop.clear();
    if (shouldNotify) {
      recalculateHierarchy();
    }
  }

  void _rebuildHierarchyMaps() {
    _parentByNode.clear();
    _childrenByNode.clear();

    final nodeById = <String, GridNode>{
      for (final node in _nodes) node.id: node,
    };

    for (final node in _nodes) {
      _childrenByNode.putIfAbsent(node, () => []);
    }

    for (final node in _nodes) {
      final parent = node.parentId == null ? null : nodeById[node.parentId!];
      _parentByNode[node] = parent;
      if (parent != null) {
        _childrenByNode.putIfAbsent(parent, () => []);
        _childrenByNode[parent]!.add(node);
      }
    }
  }

  Future<void> _saveStructuresToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final structuresPayload = _structures.map((summary) {
      final current = _structureDataById[summary.id] ??
          {
            'id': summary.id,
            'name': summary.name,
            'buildingName': '',
            'updatedAt': summary.updatedAt.toIso8601String(),
            'nodes': <Map<String, dynamic>>[],
          };

      return {
        ...current,
        'id': summary.id,
        'name': summary.name,
        'updatedAt': summary.updatedAt.toIso8601String(),
      };
    }).toList();

    await prefs.setString(_structuresStorageKey, jsonEncode(structuresPayload));
    if (_currentStructureId != null) {
      await prefs.setString(_currentStructureStorageKey, _currentStructureId!);
    }
  }

  @override
  void dispose() {
    _snapshotPersistTimer?.cancel();
    unawaited(flushPendingSnapshotSave());
    super.dispose();
  }
}
