/// Represents a single circuit line (kieszeni/gniazdo) in a distribution board
class CircuitLine {
  final String id;
  String name;
  
  // Protection (Zabezpieczenie)
  String protectionType; // 'B', 'C', 'D', etc.
  double protectionCurrentA;
  
  // Cable parameters (Kabel)
  double cableLength;
  double cableCrossSectionMm2;
  String cableMaterial; // 'Cu', 'Al'
  
  // Device parameters
  String ipRating; // 'IP65', 'IP54', etc.
  
  // Dates and status
  DateTime? installationDate;
  DateTime? lastFailureDate;
  DateTime? lastMeasurementDate;
  String? notes;
  bool isActive;

  CircuitLine({
    required this.id,
    required this.name,
    this.protectionType = 'B',
    this.protectionCurrentA = 16,
    this.cableLength = 10,
    this.cableCrossSectionMm2 = 2.5,
    this.cableMaterial = 'Cu',
    this.ipRating = 'IP20',
    this.installationDate,
    this.lastFailureDate,
    this.lastMeasurementDate,
    this.notes,
    this.isActive = true,
  });

  /// Convert to JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'protectionType': protectionType,
      'protectionCurrentA': protectionCurrentA,
      'cableLength': cableLength,
      'cableCrossSectionMm2': cableCrossSectionMm2,
      'cableMaterial': cableMaterial,
      'ipRating': ipRating,
      'installationDate': installationDate?.toIso8601String(),
      'lastFailureDate': lastFailureDate?.toIso8601String(),
      'lastMeasurementDate': lastMeasurementDate?.toIso8601String(),
      'notes': notes,
      'isActive': isActive,
    };
  }

  /// Create from JSON
  factory CircuitLine.fromMap(Map<String, dynamic> map) {
    return CircuitLine(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Line',
      protectionType: map['protectionType'] as String? ?? 'B',
      protectionCurrentA: (map['protectionCurrentA'] as num?)?.toDouble() ?? 16,
      cableLength: (map['cableLength'] as num?)?.toDouble() ?? 10,
      cableCrossSectionMm2:
          (map['cableCrossSectionMm2'] as num?)?.toDouble() ?? 2.5,
      cableMaterial: map['cableMaterial'] as String? ?? 'Cu',
      ipRating: map['ipRating'] as String? ?? 'IP20',
      installationDate: map['installationDate'] != null
          ? DateTime.parse(map['installationDate'] as String)
          : null,
      lastFailureDate: map['lastFailureDate'] != null
          ? DateTime.parse(map['lastFailureDate'] as String)
          : null,
      lastMeasurementDate: map['lastMeasurementDate'] != null
          ? DateTime.parse(map['lastMeasurementDate'] as String)
          : null,
      notes: map['notes'] as String?,
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  /// Create a copy with updated fields
  CircuitLine copyWith({
    String? id,
    String? name,
    String? protectionType,
    double? protectionCurrentA,
    double? cableLength,
    double? cableCrossSectionMm2,
    String? cableMaterial,
    String? ipRating,
    DateTime? installationDate,
    DateTime? lastFailureDate,
    DateTime? lastMeasurementDate,
    String? notes,
    bool? isActive,
  }) {
    return CircuitLine(
      id: id ?? this.id,
      name: name ?? this.name,
      protectionType: protectionType ?? this.protectionType,
      protectionCurrentA: protectionCurrentA ?? this.protectionCurrentA,
      cableLength: cableLength ?? this.cableLength,
      cableCrossSectionMm2: cableCrossSectionMm2 ?? this.cableCrossSectionMm2,
      cableMaterial: cableMaterial ?? this.cableMaterial,
      ipRating: ipRating ?? this.ipRating,
      installationDate: installationDate ?? this.installationDate,
      lastFailureDate: lastFailureDate ?? this.lastFailureDate,
      lastMeasurementDate: lastMeasurementDate ?? this.lastMeasurementDate,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}
