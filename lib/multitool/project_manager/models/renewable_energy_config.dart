// renewable_energy_config.dart
// Konfiguracja systemów OZE i elektromobilności

import 'package:flutter/foundation.dart';

// === ENUMY ===

/// Rozmiar systemu fotowoltaicznego
enum PhotovoltaicSystemSize {
  none,           // Brak instalacji
  microSmall,     // < 6.5 kWp (mikroinstalacja mała)
  microMedium,    // 6.5-10 kWp (mikroinstalacja średnia)
  microLarge,     // 10-50 kWp (mikroinstalacja duża)
  commercial,     // > 50 kWp (komercyjna)
}

/// Typ magazynu energii
enum BatteryStorageType {
  none,                // Brak magazynu
  lifepo4Residential,  // LiFePO4 mieszkaniowy (5-20 kWh)
  lifepo4Commercial,   // LiFePO4 komercyjny (20-100 kWh)
  liionIndustrial,     // Li-ion przemysłowy (> 100 kWh)
}

/// Typ stacji ładowania EV
enum ChargingStationType {
  none,          // Brak ładowarek
  wallbox,       // Wallbox (AC, 3.7-22 kW)
  standAlone,    // Wolnostojąca (AC/DC, do 50 kW)
  fastCharger,   // Szybka (DC, 50-350 kW)
}

/// System zarządzania mocą (DLM - Dynamic Load Management)
enum DlmSystemType {
  none,     // Brak DLM
  passive,  // Pasywne balansowanie (lokalne sensory)
  active,   // Aktywne balansowanie (centralne zarządzanie)
}

// === KLASY KONFIGURACJI ===

/// Konfiguracja instalacji fotowoltaicznej
@immutable
class PhotovoltaicConfiguration {
  const PhotovoltaicConfiguration({
    this.isInstalled = false,
    this.peakPower = 0.0,
    this.systemSize = PhotovoltaicSystemSize.none,
    this.requiresFireDeptApproval = false,
    this.requiresOsdNotification = true,
  });

  final bool isInstalled;
  final double peakPower;  // Moc szczytowa w kWp
  final PhotovoltaicSystemSize systemSize;
  final bool requiresFireDeptApproval;  // Zgłoszenie do PSP (> 6.5 kWp)
  final bool requiresOsdNotification;    // Zgłoszenie do OSD (≤ 50 kWp)

  PhotovoltaicConfiguration copyWith({
    bool? isInstalled,
    double? peakPower,
    PhotovoltaicSystemSize? systemSize,
    bool? requiresFireDeptApproval,
    bool? requiresOsdNotification,
  }) {
    return PhotovoltaicConfiguration(
      isInstalled: isInstalled ?? this.isInstalled,
      peakPower: peakPower ?? this.peakPower,
      systemSize: systemSize ?? this.systemSize,
      requiresFireDeptApproval:
          requiresFireDeptApproval ?? this.requiresFireDeptApproval,
      requiresOsdNotification:
          requiresOsdNotification ?? this.requiresOsdNotification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isInstalled': isInstalled,
      'peakPower': peakPower,
      'systemSize': systemSize.name,
      'requiresFireDeptApproval': requiresFireDeptApproval,
      'requiresOsdNotification': requiresOsdNotification,
    };
  }

  factory PhotovoltaicConfiguration.fromJson(Map<String, dynamic> json) {
    return PhotovoltaicConfiguration(
      isInstalled: json['isInstalled'] as bool? ?? false,
      peakPower: (json['peakPower'] as num?)?.toDouble() ?? 0.0,
      systemSize: PhotovoltaicSystemSize.values.firstWhere(
        (e) => e.name == json['systemSize'],
        orElse: () => PhotovoltaicSystemSize.none,
      ),
      requiresFireDeptApproval: json['requiresFireDeptApproval'] as bool? ?? false,
      requiresOsdNotification: json['requiresOsdNotification'] as bool? ?? true,
    );
  }

  static PhotovoltaicSystemSize determineSizeFromPower(double peakPower) {
    if (peakPower <= 0) return PhotovoltaicSystemSize.none;
    if (peakPower < 6.5) return PhotovoltaicSystemSize.microSmall;
    if (peakPower <= 10) return PhotovoltaicSystemSize.microMedium;
    if (peakPower <= 50) return PhotovoltaicSystemSize.microLarge;
    return PhotovoltaicSystemSize.commercial;
  }
}

/// Konfiguracja magazynu energii (BESS)
@immutable
class BatteryStorageConfiguration {
  const BatteryStorageConfiguration({
    this.isInstalled = false,
    this.capacity = 0.0,
    this.storageType = BatteryStorageType.none,
    this.requiresCertification = false,
  });

  final bool isInstalled;
  final double capacity;  // Pojemność w kWh
  final BatteryStorageType storageType;
  final bool requiresCertification;  // Certyfikat NC RfG

  BatteryStorageConfiguration copyWith({
    bool? isInstalled,
    double? capacity,
    BatteryStorageType? storageType,
    bool? requiresCertification,
  }) {
    return BatteryStorageConfiguration(
      isInstalled: isInstalled ?? this.isInstalled,
      capacity: capacity ?? this.capacity,
      storageType: storageType ?? this.storageType,
      requiresCertification:
          requiresCertification ?? this.requiresCertification,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isInstalled': isInstalled,
      'capacity': capacity,
      'storageType': storageType.name,
      'requiresCertification': requiresCertification,
    };
  }

  factory BatteryStorageConfiguration.fromJson(Map<String, dynamic> json) {
    return BatteryStorageConfiguration(
      isInstalled: json['isInstalled'] as bool? ?? false,
      capacity: (json['capacity'] as num?)?.toDouble() ?? 0.0,
      storageType: BatteryStorageType.values.firstWhere(
        (e) => e.name == json['storageType'],
        orElse: () => BatteryStorageType.none,
      ),
      requiresCertification: json['requiresCertification'] as bool? ?? false,
    );
  }

  static BatteryStorageType determineTypeFromCapacity(double capacity) {
    if (capacity <= 0) return BatteryStorageType.none;
    if (capacity <= 20) return BatteryStorageType.lifepo4Residential;
    if (capacity <= 100) return BatteryStorageType.lifepo4Commercial;
    return BatteryStorageType.liionIndustrial;
  }
}

/// Konfiguracja elektromobilności (ładowarki EV)
@immutable
class ElectricMobilityConfiguration {
  const ElectricMobilityConfiguration({
    this.isInstalled = false,
    this.numberOfChargingPoints = 0,
    this.stationType = ChargingStationType.none,
    this.dlmSystem = DlmSystemType.none,
    this.requiresUdtInspection = false,
    this.requiresDlm = false,
  });

  final bool isInstalled;
  final int numberOfChargingPoints;
  final ChargingStationType stationType;
  final DlmSystemType dlmSystem;
  final bool requiresUdtInspection;  // Dla stacji ogólnodostępnych
  final bool requiresDlm;             // Obowiązkowe dla > 5 stanowisk

  ElectricMobilityConfiguration copyWith({
    bool? isInstalled,
    int? numberOfChargingPoints,
    ChargingStationType? stationType,
    DlmSystemType? dlmSystem,
    bool? requiresUdtInspection,
    bool? requiresDlm,
  }) {
    return ElectricMobilityConfiguration(
      isInstalled: isInstalled ?? this.isInstalled,
      numberOfChargingPoints:
          numberOfChargingPoints ?? this.numberOfChargingPoints,
      stationType: stationType ?? this.stationType,
      dlmSystem: dlmSystem ?? this.dlmSystem,
      requiresUdtInspection:
          requiresUdtInspection ?? this.requiresUdtInspection,
      requiresDlm: requiresDlm ?? this.requiresDlm,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isInstalled': isInstalled,
      'numberOfChargingPoints': numberOfChargingPoints,
      'stationType': stationType.name,
      'dlmSystem': dlmSystem.name,
      'requiresUdtInspection': requiresUdtInspection,
      'requiresDlm': requiresDlm,
    };
  }

  factory ElectricMobilityConfiguration.fromJson(Map<String, dynamic> json) {
    return ElectricMobilityConfiguration(
      isInstalled: json['isInstalled'] as bool? ?? false,
      numberOfChargingPoints: json['numberOfChargingPoints'] as int? ?? 0,
      stationType: ChargingStationType.values.firstWhere(
        (e) => e.name == json['stationType'],
        orElse: () => ChargingStationType.none,
      ),
      dlmSystem: DlmSystemType.values.firstWhere(
        (e) => e.name == json['dlmSystem'],
        orElse: () => DlmSystemType.none,
      ),
      requiresUdtInspection: json['requiresUdtInspection'] as bool? ?? false,
      requiresDlm: json['requiresDlm'] as bool? ?? false,
    );
  }
}

/// Główna klasa konfiguracji OZE i elektromobilności
@immutable
class RenewableEnergyConfig {
  const RenewableEnergyConfig({
    this.photovoltaic = const PhotovoltaicConfiguration(),
    this.batteryStorage = const BatteryStorageConfiguration(),
    this.electricMobility = const ElectricMobilityConfiguration(),
  });

  final PhotovoltaicConfiguration photovoltaic;
  final BatteryStorageConfiguration batteryStorage;
  final ElectricMobilityConfiguration electricMobility;

  bool get hasAnyRenewableEnergy =>
      photovoltaic.isInstalled ||
      batteryStorage.isInstalled ||
      electricMobility.isInstalled;

  RenewableEnergyConfig copyWith({
    PhotovoltaicConfiguration? photovoltaic,
    BatteryStorageConfiguration? batteryStorage,
    ElectricMobilityConfiguration? electricMobility,
  }) {
    return RenewableEnergyConfig(
      photovoltaic: photovoltaic ?? this.photovoltaic,
      batteryStorage: batteryStorage ?? this.batteryStorage,
      electricMobility: electricMobility ?? this.electricMobility,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photovoltaic': photovoltaic.toJson(),
      'batteryStorage': batteryStorage.toJson(),
      'electricMobility': electricMobility.toJson(),
    };
  }

  factory RenewableEnergyConfig.fromJson(Map<String, dynamic> json) {
    return RenewableEnergyConfig(
      photovoltaic: json['photovoltaic'] != null
          ? PhotovoltaicConfiguration.fromJson(
              json['photovoltaic'] as Map<String, dynamic>)
          : const PhotovoltaicConfiguration(),
      batteryStorage: json['batteryStorage'] != null
          ? BatteryStorageConfiguration.fromJson(
              json['batteryStorage'] as Map<String, dynamic>)
          : const BatteryStorageConfiguration(),
      electricMobility: json['electricMobility'] != null
          ? ElectricMobilityConfiguration.fromJson(
              json['electricMobility'] as Map<String, dynamic>)
          : const ElectricMobilityConfiguration(),
    );
  }
}

// === VALIDATOR ===

/// Walidator reguł biznesowych dla konfiguracji OZE/EV
class RenewableEnergyValidator {
  /// Sprawdza czy wymagane jest zgłoszenie do straży pożarnej
  /// Reguła: PV > 6.5 kWp wymaga zgłoszenia do PSP
  static bool requiresFireDepartmentNotification(
      PhotovoltaicConfiguration pv) {
    return pv.isInstalled && pv.peakPower > 6.5;
  }

  /// Sprawdza czy wymagane jest zgłoszenie mikroinstalacji do OSD
  /// Reguła: PV ≤ 50 kWp wymaga zgłoszenia do operatora sieci
  static bool requiresOsdMicroinstallationNotification(
      PhotovoltaicConfiguration pv) {
    return pv.isInstalled && pv.peakPower > 0 && pv.peakPower <= 50;
  }

  /// Sprawdza czy system DLM jest krytyczny (obowiązkowy)
  /// Reguła: > 5 stanowisk ładowania wymaga DLM
  static bool requiresMandatoryDlm(ElectricMobilityConfiguration ev) {
    return ev.isInstalled && ev.numberOfChargingPoints > 5;
  }

  /// Sprawdza czy wymagana jest inspekcja UDT
  /// Reguła: Stacje ogólnodostępne wymagają UDT
  static bool requiresUdtInspection(ElectricMobilityConfiguration ev) {
    return ev.isInstalled &&
        ev.requiresUdtInspection &&
        ev.stationType != ChargingStationType.none;
  }

  /// Zwraca listę ostrzeżeń dla danej konfiguracji
  static List<String> getWarnings(RenewableEnergyConfig config) {
    final warnings = <String>[];

    // Ostrzeżenia PV
    if (requiresFireDepartmentNotification(config.photovoltaic)) {
      warnings.add(
          '⚠️ PV > 6.5 kWp: wymagane zgłoszenie do Państwowej Straży Pożarnej');
    }
    if (requiresOsdMicroinstallationNotification(config.photovoltaic)) {
      warnings.add('📋 Wymagane zgłoszenie mikroinstalacji do OSD');
    }

    // Ostrzeżenia BESS
    if (config.batteryStorage.isInstalled &&
        config.batteryStorage.capacity > 20) {
      warnings.add('🔋 BESS > 20 kWh: wymagany certyfikat NC RfG');
    }

    // Ostrzeżenia EV
    if (requiresMandatoryDlm(config.electricMobility)) {
      warnings.add(
          '🚨 > 5 stanowisk EV: system DLM jest OBOWIĄZKOWY (zapobieganie awariom zasilania)');
    }
    if (config.electricMobility.isInstalled &&
        config.electricMobility.numberOfChargingPoints > 0 &&
        config.electricMobility.dlmSystem == DlmSystemType.none &&
        config.electricMobility.numberOfChargingPoints > 3) {
      warnings.add('💡 Zalecany system DLM dla optymalizacji obciążenia');
    }
    if (requiresUdtInspection(config.electricMobility)) {
      warnings.add(
          '🔍 Stacja ogólnodostępna: wymagana decyzja UDT przed eksploatacją');
    }

    return warnings;
  }

  /// Zwraca listę wymaganych dokumentów/załączników
  static List<String> getRequiredDocuments(RenewableEnergyConfig config) {
    final docs = <String>[];

    if (config.photovoltaic.isInstalled) {
      docs.add('Schemat jednokreskowy instalacji PV');
      docs.add('Protokół pomiarów parametrów instalacji fotowoltaicznej');
      
      if (requiresFireDepartmentNotification(config.photovoltaic)) {
        docs.add('Zgłoszenie do Państwowej Straży Pożarnej');
        docs.add('Uzgodnienie projektu z rzeczoznawcą ppoż.');
      }
      
      if (requiresOsdMicroinstallationNotification(config.photovoltaic)) {
        docs.add('Zgłoszenie mikroinstalacji do Operatora (OSD)');
      }
    }

    if (config.batteryStorage.isInstalled) {
      docs.add('Karta gwarancyjna magazynu energii');
      
      if (config.batteryStorage.requiresCertification) {
        docs.add('Certyfikat NC RfG');
      }
    }

    if (config.electricMobility.isInstalled) {
      docs.add('Deklaracja zgodności producenta stacji ładowania');
      
      if (config.electricMobility.numberOfChargingPoints > 1) {
        docs.add('Atest na kable ognioodporne (jeśli wymagane)');
      }
      
      if (config.electricMobility.dlmSystem != DlmSystemType.none) {
        docs.add('Raport z konfiguracji systemu balansu obciążenia (DLM)');
      }
      
      if (requiresUdtInspection(config.electricMobility)) {
        docs.add('Decyzja UDT dopuszczająca do eksploatacji');
      }
    }

    return docs;
  }
}
