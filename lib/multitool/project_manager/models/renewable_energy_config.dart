/// Konfiguracja OZE (Odnawialne Źródła Energii) i Elektromobilności
/// 
/// Obsługuje:
/// - Instalacje fotowoltaiki (PV)
/// - Magazyny energii (BESS)
/// - Ładowarki samochodów elektrycznych (EV)
/// - System zarządzania mocą (DLM)

library;

enum PhotovoltaicSystemSize {
  micro, // < 6.5 kWp (bez wymogów straży pożarnej)
  standard, // 6.5 - 50 kWp (wymaga zawiadomienia straży pożarnej)
  large, // > 50 kWp (wymaga pełnej dokumentacji ppoż)
}

enum BatteryStorageType {
  liIon, // Litowo-jonowe
  lfp, // LiFePO4
  saltWater, // Wodne azotan sodu
  leadAcid, // Ołowiowo-kwasowe (zalecane tylko dla systemów < 5 kWh)
}

enum ChargingStationType {
  wallbox, // Wallbox (7-22 kW, dom/budynek)
  publichCommonSlupek, // Słupek publiczny (22-350 kW)
  dcFastCharger, // Szybka ładowarka DC (50-350 kW)
}

enum DlmSystemType {
  none, // Bez systemu zarządzania
  passive, // Pasywne limity mocy
  activeRealtime, // Aktywne zarządzanie w czasie rzeczywistym
}

/// Konfiguracja systemu fotowoltaiki
class PhotovoltaicConfiguration {
  final bool isEnabled;
  final double installedPowerKwp; // Moc zainstalowana w kWp
  final PhotovoltaicSystemSize systemSize;
  final int estimatedMonthlyProductionKwh; // Szacunkowa roczna produkcja w kWh
  final String moduleType; // Monokrystaliczne, polikrystaliczne
  final String inverterType; // Typ falownika
  final String? customModuleModel;
  final String? customInverterModel;
  
  // Załączniki dokumentacyjne
  final List<String> attachments; // Nazwy plików załączników
  
  PhotovoltaicConfiguration({
    this.isEnabled = false,
    this.installedPowerKwp = 0.0,
    this.systemSize = PhotovoltaicSystemSize.micro,
    this.estimatedMonthlyProductionKwh = 0,
    this.moduleType = 'Monokrystaliczne',
    this.inverterType = 'Trójfazowy',
    this.customModuleModel,
    this.customInverterModel,
    List<String>? attachments,
  }) : attachments = attachments ?? [];
  
  // Czy wymaga zgłoszenia do straży pożarnej (> 6,5 kWp)
  bool get requiresFireDepartmentNotification => installedPowerKwp > 6.5;
  
  // Czy wymaga pełnej dokumentacji ppoż (> 50 kWp)
  bool get requiresFullFireSafetyDocs => installedPowerKwp > 50.0;
  
  PhotovoltaicConfiguration copyWith({
    bool? isEnabled,
    double? installedPowerKwp,
    PhotovoltaicSystemSize? systemSize,
    int? estimatedMonthlyProductionKwh,
    String? moduleType,
    String? inverterType,
    String? customModuleModel,
    String? customInverterModel,
    List<String>? attachments,
  }) {
    return PhotovoltaicConfiguration(
      isEnabled: isEnabled ?? this.isEnabled,
      installedPowerKwp: installedPowerKwp ?? this.installedPowerKwp,
      systemSize: systemSize ?? this.systemSize,
      estimatedMonthlyProductionKwh: estimatedMonthlyProductionKwh ?? this.estimatedMonthlyProductionKwh,
      moduleType: moduleType ?? this.moduleType,
      inverterType: inverterType ?? this.inverterType,
      customModuleModel: customModuleModel ?? this.customModuleModel,
      customInverterModel: customInverterModel ?? this.customInverterModel,
      attachments: attachments ?? this.attachments,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'installedPowerKwp': installedPowerKwp,
    'systemSize': systemSize.toString(),
    'estimatedMonthlyProductionKwh': estimatedMonthlyProductionKwh,
    'moduleType': moduleType,
    'inverterType': inverterType,
    'customModuleModel': customModuleModel,
    'customInverterModel': customInverterModel,
    'attachments': attachments,
  };
  
  factory PhotovoltaicConfiguration.fromJson(Map<String, dynamic> json) => PhotovoltaicConfiguration(
    isEnabled: json['isEnabled'] as bool? ?? false,
    installedPowerKwp: (json['installedPowerKwp'] as num?)?.toDouble() ?? 0.0,
    systemSize: _parsePhotovoltaicSystemSize(json['systemSize'] as String?),
    estimatedMonthlyProductionKwh: json['estimatedMonthlyProductionKwh'] as int? ?? 0,
    moduleType: json['moduleType'] as String? ?? 'Monokrystaliczne',
    inverterType: json['inverterType'] as String? ?? 'Trójfazowy',
    customModuleModel: json['customModuleModel'] as String?,
    customInverterModel: json['customInverterModel'] as String?,
    attachments: List<String>.from(json['attachments'] as List? ?? []),
  );
}

PhotovoltaicSystemSize _parsePhotovoltaicSystemSize(String? value) {
  switch (value) {
    case 'PhotovoltaicSystemSize.micro':
      return PhotovoltaicSystemSize.micro;
    case 'PhotovoltaicSystemSize.standard':
      return PhotovoltaicSystemSize.standard;
    case 'PhotovoltaicSystemSize.large':
      return PhotovoltaicSystemSize.large;
    default:
      return PhotovoltaicSystemSize.micro;
  }
}

/// Konfiguracja magazynu energii (BESS)
class BatteryStorageConfiguration {
  final bool isEnabled;
  final double storageSizeKwh; // Pojemność w kWh
  final BatteryStorageType batteryType;
  final double usableCapacityPercent; // Procent pojemności dostępny do użytku
  final String? customBatteryModel;
  
  // Załączniki
  final List<String> attachments;
  
  BatteryStorageConfiguration({
    this.isEnabled = false,
    this.storageSizeKwh = 0.0,
    this.batteryType = BatteryStorageType.liIon,
    this.usableCapacityPercent = 90.0,
    this.customBatteryModel,
    List<String>? attachments,
  }) : attachments = attachments ?? [];
  
  BatteryStorageConfiguration copyWith({
    bool? isEnabled,
    double? storageSizeKwh,
    BatteryStorageType? batteryType,
    double? usableCapacityPercent,
    String? customBatteryModel,
    List<String>? attachments,
  }) {
    return BatteryStorageConfiguration(
      isEnabled: isEnabled ?? this.isEnabled,
      storageSizeKwh: storageSizeKwh ?? this.storageSizeKwh,
      batteryType: batteryType ?? this.batteryType,
      usableCapacityPercent: usableCapacityPercent ?? this.usableCapacityPercent,
      customBatteryModel: customBatteryModel ?? this.customBatteryModel,
      attachments: attachments ?? this.attachments,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'storageSizeKwh': storageSizeKwh,
    'batteryType': batteryType.toString(),
    'usableCapacityPercent': usableCapacityPercent,
    'customBatteryModel': customBatteryModel,
    'attachments': attachments,
  };
  
  factory BatteryStorageConfiguration.fromJson(Map<String, dynamic> json) => BatteryStorageConfiguration(
    isEnabled: json['isEnabled'] as bool? ?? false,
    storageSizeKwh: (json['storageSizeKwh'] as num?)?.toDouble() ?? 0.0,
    batteryType: _parseBatteryStorageType(json['batteryType'] as String?),
    usableCapacityPercent: (json['usableCapacityPercent'] as num?)?.toDouble() ?? 90.0,
    customBatteryModel: json['customBatteryModel'] as String?,
    attachments: List<String>.from(json['attachments'] as List? ?? []),
  );
}

BatteryStorageType _parseBatteryStorageType(String? value) {
  switch (value) {
    case 'BatteryStorageType.lfp':
      return BatteryStorageType.lfp;
    case 'BatteryStorageType.saltWater':
      return BatteryStorageType.saltWater;
    case 'BatteryStorageType.leadAcid':
      return BatteryStorageType.leadAcid;
    case 'BatteryStorageType.liIon':
    default:
      return BatteryStorageType.liIon;
  }
}

/// Pojedyncza stacja ładowania
class ChargingStation {
  final String stationId; // Unikatowy identyfikator
  final String stationName; // Nazwa/lokalizacja
  final ChargingStationType stationType;
  final double chargingPowerKw; // Moc ładowania w kW
  final int numberOfConnectors; // Liczba złączy
  final bool isFastCharging; // Czy szybka ładowarka
  String? customModel;
  
  // Załączniki
  final List<String> attachments;
  
  ChargingStation({
    required this.stationId,
    required this.stationName,
    required this.stationType,
    this.chargingPowerKw = 7.0,
    this.numberOfConnectors = 1,
    this.isFastCharging = false,
    this.customModel,
    List<String>? attachments,
  }) : attachments = attachments ?? [];
  
  ChargingStation copyWith({
    String? stationId,
    String? stationName,
    ChargingStationType? stationType,
    double? chargingPowerKw,
    int? numberOfConnectors,
    bool? isFastCharging,
    String? customModel,
    List<String>? attachments,
  }) {
    return ChargingStation(
      stationId: stationId ?? this.stationId,
      stationName: stationName ?? this.stationName,
      stationType: stationType ?? this.stationType,
      chargingPowerKw: chargingPowerKw ?? this.chargingPowerKw,
      numberOfConnectors: numberOfConnectors ?? this.numberOfConnectors,
      isFastCharging: isFastCharging ?? this.isFastCharging,
      customModel: customModel ?? this.customModel,
      attachments: attachments ?? this.attachments,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'stationId': stationId,
    'stationName': stationName,
    'stationType': stationType.toString(),
    'chargingPowerKw': chargingPowerKw,
    'numberOfConnectors': numberOfConnectors,
    'isFastCharging': isFastCharging,
    'customModel': customModel,
    'attachments': attachments,
  };
  
  factory ChargingStation.fromJson(Map<String, dynamic> json) => ChargingStation(
    stationId: json['stationId'] as String? ?? '',
    stationName: json['stationName'] as String? ?? '',
    stationType: _parseChargingStationType(json['stationType'] as String?),
    chargingPowerKw: (json['chargingPowerKw'] as num?)?.toDouble() ?? 7.0,
    numberOfConnectors: json['numberOfConnectors'] as int? ?? 1,
    isFastCharging: json['isFastCharging'] as bool? ?? false,
    customModel: json['customModel'] as String?,
    attachments: List<String>.from(json['attachments'] as List? ?? []),
  );
}

ChargingStationType _parseChargingStationType(String? value) {
  switch (value) {
    case 'ChargingStationType.publichCommonSlupek':
      return ChargingStationType.publichCommonSlupek;
    case 'ChargingStationType.dcFastCharger':
      return ChargingStationType.dcFastCharger;
    case 'ChargingStationType.wallbox':
    default:
      return ChargingStationType.wallbox;
  }
}

/// Konfiguracja elektromobilności (ładowarki EV)
class ElectricMobilityConfiguration {
  final bool isEnabled;
  final List<ChargingStation> chargingStations;
  final DlmSystemType dlmSystem; // System zarządzania mocą
  final double maxAllowedDrawKw; // Maksymalny pobór mocy (ograniczenie)
  
  // Załączniki
  final List<String> attachments;
  
  ElectricMobilityConfiguration({
    this.isEnabled = false,
    List<ChargingStation>? chargingStations,
    this.dlmSystem = DlmSystemType.none,
    this.maxAllowedDrawKw = 0.0,
    List<String>? attachments,
  })  : chargingStations = chargingStations ?? [],
        attachments = attachments ?? [];
  
  // Czy wymaga systemu DLM (> 5 stanowisk)
  bool get requiresDlmSystem => chargingStations.length > 5;
  
  // Całkowita moc ładowania wszystkich stacji
  double get totalChargingPowerKw {
    return chargingStations.fold(0.0, (sum, station) => sum + station.chargingPowerKw);
  }
  
  ElectricMobilityConfiguration copyWith({
    bool? isEnabled,
    List<ChargingStation>? chargingStations,
    DlmSystemType? dlmSystem,
    double? maxAllowedDrawKw,
    List<String>? attachments,
  }) {
    return ElectricMobilityConfiguration(
      isEnabled: isEnabled ?? this.isEnabled,
      chargingStations: chargingStations ?? this.chargingStations,
      dlmSystem: dlmSystem ?? this.dlmSystem,
      maxAllowedDrawKw: maxAllowedDrawKw ?? this.maxAllowedDrawKw,
      attachments: attachments ?? this.attachments,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'isEnabled': isEnabled,
    'chargingStations': chargingStations.map((s) => s.toJson()).toList(),
    'dlmSystem': dlmSystem.toString(),
    'maxAllowedDrawKw': maxAllowedDrawKw,
    'attachments': attachments,
  };
  
  factory ElectricMobilityConfiguration.fromJson(Map<String, dynamic> json) => ElectricMobilityConfiguration(
    isEnabled: json['isEnabled'] as bool? ?? false,
    chargingStations: (json['chargingStations'] as List?)
        ?.map((s) => ChargingStation.fromJson(s as Map<String, dynamic>))
        .toList(),
    dlmSystem: _parseDlmSystemType(json['dlmSystem'] as String?),
    maxAllowedDrawKw: (json['maxAllowedDrawKw'] as num?)?.toDouble() ?? 0.0,
    attachments: List<String>.from(json['attachments'] as List? ?? []),
  );
}

DlmSystemType _parseDlmSystemType(String? value) {
  switch (value) {
    case 'DlmSystemType.passive':
      return DlmSystemType.passive;
    case 'DlmSystemType.activeRealtime':
      return DlmSystemType.activeRealtime;
    case 'DlmSystemType.none':
    default:
      return DlmSystemType.none;
  }
}

/// Pełna konfiguracja systemów odnawialnych i elektromobilności
class RenewableEnergyConfiguration {
  final PhotovoltaicConfiguration photovoltaic;
  final BatteryStorageConfiguration batteryStorage;
  final ElectricMobilityConfiguration electricMobility;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  RenewableEnergyConfiguration({
    PhotovoltaicConfiguration? photovoltaic,
    BatteryStorageConfiguration? batteryStorage,
    ElectricMobilityConfiguration? electricMobility,
    this.createdAt,
    this.updatedAt,
  })  : photovoltaic = photovoltaic ?? PhotovoltaicConfiguration(),
        batteryStorage = batteryStorage ?? BatteryStorageConfiguration(),
        electricMobility = electricMobility ?? ElectricMobilityConfiguration();
  
  bool get isOptimalConfiguration {
    // Optymalna konfiguracja: PV + BESS + DLM (jeśli jest EV)
    if (!photovoltaic.isEnabled) return false;
    if (electricMobility.isEnabled && electricMobility.dlmSystem == DlmSystemType.none) return false;
    return true;
  }
  
  RenewableEnergyConfiguration copyWith({
    PhotovoltaicConfiguration? photovoltaic,
    BatteryStorageConfiguration? batteryStorage,
    ElectricMobilityConfiguration? electricMobility,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RenewableEnergyConfiguration(
      photovoltaic: photovoltaic ?? this.photovoltaic,
      batteryStorage: batteryStorage ?? this.batteryStorage,
      electricMobility: electricMobility ?? this.electricMobility,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'photovoltaic': photovoltaic.toJson(),
    'batteryStorage': batteryStorage.toJson(),
    'electricMobility': electricMobility.toJson(),
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
  
  factory RenewableEnergyConfiguration.fromJson(Map<String, dynamic> json) => RenewableEnergyConfiguration(
    photovoltaic: json['photovoltaic'] != null
        ? PhotovoltaicConfiguration.fromJson(json['photovoltaic'] as Map<String, dynamic>)
        : null,
    batteryStorage: json['batteryStorage'] != null
        ? BatteryStorageConfiguration.fromJson(json['batteryStorage'] as Map<String, dynamic>)
        : null,
    electricMobility: json['electricMobility'] != null
        ? ElectricMobilityConfiguration.fromJson(json['electricMobility'] as Map<String, dynamic>)
        : null,
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
  );
}

/// Walidacja i reguły
class RenewableEnergyValidator {
  static List<String> validateConfiguration(RenewableEnergyConfiguration config) {
    final issues = <String>[];
    
    // Reguła: PV > 6,5 kWp wymaga zgłoszenia do straży pożarnej
    if (config.photovoltaic.isEnabled && config.photovoltaic.requiresFireDepartmentNotification) {
      if (!config.photovoltaic.attachments.contains('Zgłoszenie Straż Pożarna')) {
        issues.add('⚠️ PV powyżej 6,5 kWp wymaga Zgłoszenia do Straży Pożarnej');
      }
    }
    
    // Reguła: PV wymaga zgłoszenia do OSD (mikroinstalacja)
    if (config.photovoltaic.isEnabled && config.photovoltaic.installedPowerKwp <= 50.0) {
      if (!config.photovoltaic.attachments.contains('Zgłoszenie OSD')) {
        issues.add('⚠️ PV wymaga Zgłoszenia mikroinstalacji do Operatora (OSD)');
      }
    }
    
    // Reguła: EV > 5 stanowisk wymaga DLM
    if (config.electricMobility.isEnabled && config.electricMobility.requiresDlmSystem) {
      if (config.electricMobility.dlmSystem == DlmSystemType.none) {
        issues.add('🚨 Więcej niż 5 stanowisk ładowania wymaga systemu DLM!');
      }
    }
    
    return issues;
  }
}
