import 'dart:math';
import 'package:gridly/models/circuit_line.dart';

enum ConductorMaterial { cu, al }

enum ProtectionDeviceType {
  overcurrentBreaker,
  residualCurrentDevice,
  fuseHolder
}

enum BoardAdditionalEquipment {
  subMeter,
  pwpSwitch,
  surgeProtection,
}

class BoardProtectionSlot {
  final String id;
  ProtectionDeviceType type;
  int quantity;
  int poleCount;
  double? ratedCurrentA;
  double? residualCurrentmA;
  String? fuseLinkSize;
  bool isReserve;
  String? assignedNodeId;

  BoardProtectionSlot({
    required this.id,
    required this.type,
    required this.quantity,
    this.poleCount = 1,
    this.ratedCurrentA,
    this.residualCurrentmA,
    this.fuseLinkSize,
    this.isReserve = false,
    this.assignedNodeId,
  });

  bool get hasCompleteDefinition {
    if (quantity <= 0 || poleCount <= 0) {
      return false;
    }

    switch (type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return (ratedCurrentA ?? 0) > 0;
      case ProtectionDeviceType.residualCurrentDevice:
        return (ratedCurrentA ?? 0) > 0 && (residualCurrentmA ?? 0) > 0;
      case ProtectionDeviceType.fuseHolder:
        return (fuseLinkSize?.trim().isNotEmpty ?? false);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': _typeToString(type),
      'quantity': quantity,
      'poleCount': poleCount,
      'ratedCurrentA': ratedCurrentA,
      'residualCurrentmA': residualCurrentmA,
      'fuseLinkSize': fuseLinkSize,
      'isReserve': isReserve,
      'assignedNodeId': assignedNodeId,
    };
  }

  factory BoardProtectionSlot.fromMap(Map<String, dynamic> map) {
    return BoardProtectionSlot(
      id: map['id'] as String,
      type: _typeFromString(map['type'] as String? ?? 'overcurrent_breaker'),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      poleCount: (map['poleCount'] as num?)?.toInt() ?? 1,
      ratedCurrentA: (map['ratedCurrentA'] as num?)?.toDouble(),
      residualCurrentmA: (map['residualCurrentmA'] as num?)?.toDouble(),
      fuseLinkSize: map['fuseLinkSize'] as String?,
      isReserve: (map['isReserve'] as bool?) ?? false,
      assignedNodeId: map['assignedNodeId'] as String?,
    );
  }

  static String _typeToString(ProtectionDeviceType type) {
    switch (type) {
      case ProtectionDeviceType.overcurrentBreaker:
        return 'overcurrent_breaker';
      case ProtectionDeviceType.residualCurrentDevice:
        return 'residual_current_device';
      case ProtectionDeviceType.fuseHolder:
        return 'fuse_holder';
    }
  }

  static ProtectionDeviceType _typeFromString(String type) {
    switch (type) {
      case 'overcurrent_breaker':
        return ProtectionDeviceType.overcurrentBreaker;
      case 'residual_current_device':
        return ProtectionDeviceType.residualCurrentDevice;
      case 'fuse_holder':
        return ProtectionDeviceType.fuseHolder;
      default:
        return ProtectionDeviceType.overcurrentBreaker;
    }
  }
}

abstract class GridNode {
  final String id;
  final String name;
  String? parentId;
  final double powerKw;
  double lengthM;
  double crossSectionMm2;
  int cableCores;
  final double ratedCurrentA;
  ConductorMaterial material;
  final List<CircuitLine> circuitLines;

  GridNode({
    required this.id,
    required this.name,
    this.parentId,
    required this.powerKw,
    required this.lengthM,
    required this.crossSectionMm2,
    required this.cableCores,
    required this.ratedCurrentA,
    required this.material,
    List<CircuitLine>? circuitLines,
  }) : circuitLines = circuitLines ?? [];

  bool get isThreePhase;

  double calculateIb() {
    if (isThreePhase) {
      return (powerKw * 1000) / (sqrt(3) * 400);
    }

    return (powerKw * 1000) / 230;
  }

  double calculateVoltageDrop() {
    final conductivity = material == ConductorMaterial.cu ? 56.0 : 34.0;
    final current = calculateIb();

    if (isThreePhase) {
      return (sqrt(3) * lengthM * current) / (conductivity * crossSectionMm2);
    }

    return (2 * lengthM * current) / (conductivity * crossSectionMm2);
  }

  Map<String, dynamic> toMap();

  static GridNode fromMap(Map<String, dynamic> map) {
    final type = map['type'] as String?;
    switch (type) {
      case 'distribution_board':
        return DistributionBoard.fromMap(map);
      case 'power_receiver':
        return PowerReceiver.fromMap(map);
      default:
        throw ArgumentError('Unknown GridNode type: $type');
    }
  }

  static double getDiversityFactor(int count) {
    if (count <= 2) {
      return 1.0;
    }

    if (count <= 5) {
      return 0.8;
    }

    return 0.7;
  }

  static ConductorMaterial materialFromString(String value) {
    switch (value.toLowerCase()) {
      case 'cu':
        return ConductorMaterial.cu;
      case 'al':
        return ConductorMaterial.al;
      default:
        throw ArgumentError('Unknown material: $value');
    }
  }

  static String materialToString(ConductorMaterial material) {
    return material == ConductorMaterial.cu ? 'Cu' : 'Al';
  }
}

class DistributionBoard extends GridNode {
  bool isPenSplitPoint;
  final List<BoardProtectionSlot> protectionSlots;
  final List<BoardAdditionalEquipment> additionalEquipment;

  DistributionBoard({
    required super.id,
    required super.name,
    super.parentId,
    required super.powerKw,
    required super.lengthM,
    required super.crossSectionMm2,
    super.cableCores = 5,
    required super.ratedCurrentA,
    required super.material,
    super.circuitLines,
    this.isPenSplitPoint = false,
    List<BoardProtectionSlot>? protectionSlots,
    List<BoardAdditionalEquipment>? additionalEquipment,
  })  : protectionSlots = protectionSlots ?? [],
        additionalEquipment = additionalEquipment ?? [];

  @override
  bool get isThreePhase => true;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'distribution_board',
      'id': id,
      'name': name,
      'parentId': parentId,
      'P': powerKw,
      'L': lengthM,
      'S': crossSectionMm2,
      'cores': cableCores,
      'In': ratedCurrentA,
      'material': GridNode.materialToString(material),
      'isThreePhase': isThreePhase,
      'isPenSplitPoint': isPenSplitPoint,
      'circuitLines': circuitLines.map((e) => e.toMap()).toList(),
      'protectionSlots': protectionSlots.map((e) => e.toMap()).toList(),
      'additionalEquipment':
          additionalEquipment.map(_additionalEquipmentToString).toList(),
    };
  }

  factory DistributionBoard.fromMap(Map<String, dynamic> map) {
    final linesList =
        (map['circuitLines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final slotsList =
        (map['protectionSlots'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final equipmentList =
        (map['additionalEquipment'] as List?)?.cast<String>() ?? [];
    return DistributionBoard(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parentId'] as String?,
      powerKw: (map['P'] as num).toDouble(),
      lengthM: (map['L'] as num).toDouble(),
      crossSectionMm2: (map['S'] as num).toDouble(),
      cableCores: (map['cores'] as num?)?.toInt() ?? 5,
      ratedCurrentA: (map['In'] as num).toDouble(),
      material: GridNode.materialFromString(map['material'] as String),
      circuitLines: linesList.map((e) => CircuitLine.fromMap(e)).toList(),
      isPenSplitPoint: (map['isPenSplitPoint'] as bool?) ?? false,
      protectionSlots:
          slotsList.map((e) => BoardProtectionSlot.fromMap(e)).toList(),
      additionalEquipment:
          equipmentList.map(_additionalEquipmentFromString).toList(),
    );
  }

  static String _additionalEquipmentToString(BoardAdditionalEquipment item) {
    switch (item) {
      case BoardAdditionalEquipment.subMeter:
        return 'sub_meter';
      case BoardAdditionalEquipment.pwpSwitch:
        return 'pwp_switch';
      case BoardAdditionalEquipment.surgeProtection:
        return 'surge_protection';
    }
  }

  static BoardAdditionalEquipment _additionalEquipmentFromString(String item) {
    switch (item) {
      case 'sub_meter':
        return BoardAdditionalEquipment.subMeter;
      case 'pwp_switch':
        return BoardAdditionalEquipment.pwpSwitch;
      case 'surge_protection':
        return BoardAdditionalEquipment.surgeProtection;
      default:
        return BoardAdditionalEquipment.subMeter;
    }
  }
}

class PowerReceiver extends GridNode {
  bool isThreePhaseReceiver;

  PowerReceiver({
    required super.id,
    required super.name,
    super.parentId,
    required super.powerKw,
    required super.lengthM,
    required super.crossSectionMm2,
    super.cableCores = 3,
    required super.ratedCurrentA,
    required super.material,
    super.circuitLines,
    this.isThreePhaseReceiver = false,
  });

  @override
  bool get isThreePhase => isThreePhaseReceiver;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'power_receiver',
      'id': id,
      'name': name,
      'parentId': parentId,
      'P': powerKw,
      'L': lengthM,
      'S': crossSectionMm2,
      'cores': cableCores,
      'In': ratedCurrentA,
      'material': GridNode.materialToString(material),
      'isThreePhase': isThreePhase,
      'circuitLines': circuitLines.map((e) => e.toMap()).toList(),
    };
  }

  factory PowerReceiver.fromMap(Map<String, dynamic> map) {
    final linesList =
        (map['circuitLines'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    return PowerReceiver(
      id: map['id'] as String,
      name: map['name'] as String,
      parentId: map['parentId'] as String?,
      powerKw: (map['P'] as num).toDouble(),
      lengthM: (map['L'] as num).toDouble(),
      crossSectionMm2: (map['S'] as num).toDouble(),
      cableCores: (map['cores'] as num?)?.toInt() ?? 3,
      ratedCurrentA: (map['In'] as num).toDouble(),
      material: GridNode.materialFromString(map['material'] as String),
      circuitLines: linesList.map((e) => CircuitLine.fromMap(e)).toList(),
      isThreePhaseReceiver: (map['isThreePhase'] as bool?) ?? false,
    );
  }
}
