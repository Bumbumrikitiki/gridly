/// Modele projektu budowlanego z chronologią prac elektrycznych
///
/// System automatycznie generuje harmonogram prac elektrycznych
/// na podstawie typu budowy, zeitów budowy i wybranych systemów.
library;

import 'package:gridly/multitool/project_manager/models/schedule_data_integration.dart';
import 'package:gridly/multitool/project_manager/models/renewable_energy_config.dart';

// ═══════════════════════════════════════════════════════════════════════════
// TYPY I ENUMY PODSTAWOWE
// ═══════════════════════════════════════════════════════════════════════════

enum BuildingType {
  mieszkalny, // Budynek mieszkalny (dom, dupleks, apartamentowiec)
  biurowy, // Budynek biurowy / handlowo-usługowy
}

enum UnitNamingScheme {
  construction,
  target,
}

enum SubcontractorArea {
  elevators,
  garage,
  externalArea,
  stairCases,
  residentialUnits,
  additionalRooms,
  parking,
}

enum SubcontractorTargetType {
  building,
  stairCase,
  floor,
  unit,
  additionalRoom,
  system,
  renewable,
  ev,
}

BuildingType _parseBuildingType(String? value) {
  switch (value) {
    case 'mieszkalny':
      return BuildingType.mieszkalny;
    case 'biurowy':
      return BuildingType.biurowy;
    case 'domek':
    case 'dupleks':
    case 'wielorodzinny':
    case 'wielorodzinnyWysoki':
      return BuildingType.mieszkalny;
    case 'biurowiec':
    case 'handlowy':
    case 'przemyslowy':
    case 'mieszany':
      return BuildingType.biurowy;
    default:
      return BuildingType.mieszkalny;
  }
}

UnitNamingScheme _parseUnitNamingScheme(String? value) {
  switch (value) {
    case 'target':
      return UnitNamingScheme.target;
    case 'construction':
    default:
      return UnitNamingScheme.construction;
  }
}

SubcontractorArea _parseSubcontractorArea(String? value) {
  switch (value) {
    case 'elevators':
      return SubcontractorArea.elevators;
    case 'garage':
      return SubcontractorArea.garage;
    case 'externalArea':
      return SubcontractorArea.externalArea;
    case 'stairCases':
      return SubcontractorArea.stairCases;
    case 'residentialUnits':
      return SubcontractorArea.residentialUnits;
    case 'additionalRooms':
      return SubcontractorArea.additionalRooms;
    case 'parking':
      return SubcontractorArea.parking;
    default:
      return SubcontractorArea.residentialUnits;
  }
}

SubcontractorTargetType _parseSubcontractorTargetType(String? value) {
  switch (value) {
    case 'building':
      return SubcontractorTargetType.building;
    case 'stairCase':
      return SubcontractorTargetType.stairCase;
    case 'floor':
      return SubcontractorTargetType.floor;
    case 'unit':
      return SubcontractorTargetType.unit;
    case 'additionalRoom':
      return SubcontractorTargetType.additionalRoom;
    case 'system':
      return SubcontractorTargetType.system;
    case 'renewable':
      return SubcontractorTargetType.renewable;
    case 'ev':
    default:
      return SubcontractorTargetType.ev;
  }
}

enum FoundationType {
  naPalach, // Pale wbijane/wiercone
  naPaskach, // Pasy fundamentowe
  naBetonie, // Bezpośrednio na terenie
}

enum PowerSupplyType {
  przylaczeNN, // Przyłącze NN (230/400V) bezpośrednio
  przylaczeSNZTrafo, // Przyłącze SN (6-30kV) z transformatorem własnym
  wlasnaGeneracja, // Własna generacja (OZE/agregat)
}

/// Szczegółowa architektura toru zasilania stosowana w praktyce projektowej.
///
/// Model odzwierciedla rzeczywistą topologię zasilania budynku,
/// a nie wyłącznie poziom napięcia lub układ sieciowy TN/TT.
enum PowerSupplyArchitectureType {
  lvDirect, // siec nN -> ZK/ZKP -> WLZ -> RG
  lvWithMainBoard, // siec nN -> RGnN + rozbudowana dystrybucja
  mvTransformerSingle, // SN -> RSn -> T1 -> RGnN
  mvTransformerMulti, // SN -> RSn -> T1+T2 -> RG sekcjonowana
  mvWithSwitchgear, // SN z rozdzielnia SN wielopolowa
  mvDualFeed, // Dwa niezalezne zasilania SN, zwykle z SZR
}

enum BackupSystemType {
  ups,
  generator,
  upsGeneratorCombo,
}

enum BackupCoverage {
  critical,
  full,
}

enum RenewableSystemType {
  pvOnGrid,
  pvWithStorage,
}

enum PowerValidationSeverity {
  warning,
  error,
}

class PowerValidationIssue {
  final PowerValidationSeverity severity;
  final String message;

  const PowerValidationIssue({
    required this.severity,
    required this.message,
  });
}

class PowerValidationResult {
  final List<PowerValidationIssue> issues;

  const PowerValidationResult(this.issues);

  bool get hasErrors =>
      issues.any((issue) => issue.severity == PowerValidationSeverity.error);

  List<String> get errors => issues
      .where((issue) => issue.severity == PowerValidationSeverity.error)
      .map((issue) => issue.message)
      .toList();

  List<String> get warnings => issues
      .where((issue) => issue.severity == PowerValidationSeverity.warning)
      .map((issue) => issue.message)
      .toList();
}

class BackupSystemConfig {
  final BackupSystemType type;
  final int priority;
  final BackupCoverage covers;
  final int? autonomyMinutes;

  const BackupSystemConfig({
    required this.type,
    required this.priority,
    required this.covers,
    this.autonomyMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'priority': priority,
      'covers': covers.name,
      'autonomyMinutes': autonomyMinutes,
    };
  }

  factory BackupSystemConfig.fromJson(Map<String, dynamic> map) {
    return BackupSystemConfig(
      type: _parseBackupSystemType(map['type'] as String?),
      priority: (map['priority'] as num?)?.toInt() ?? 1,
      covers: _parseBackupCoverage(map['covers'] as String?),
      autonomyMinutes: (map['autonomyMinutes'] as num?)?.toInt(),
    );
  }
}

class RenewableSystemConfig {
  final RenewableSystemType type;
  final double? powerKW;
  final bool integratedWithBackup;

  const RenewableSystemConfig({
    required this.type,
    this.powerKW,
    this.integratedWithBackup = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'powerKW': powerKW,
      'integratedWithBackup': integratedWithBackup,
    };
  }

  factory RenewableSystemConfig.fromJson(Map<String, dynamic> map) {
    return RenewableSystemConfig(
      type: _parseRenewableSystemType(map['type'] as String?),
      powerKW: (map['powerKW'] as num?)?.toDouble(),
      integratedWithBackup: map['integratedWithBackup'] as bool? ?? false,
    );
  }
}

PowerSupplyType _parsePowerSupplyType(String? value) {
  switch (value) {
    case 'przylaczeNN':
      return PowerSupplyType.przylaczeNN;
    case 'przylaczeSNZTrafo':
      return PowerSupplyType.przylaczeSNZTrafo;
    case 'wlasnaGeneracja':
      return PowerSupplyType.wlasnaGeneracja;
    case 'siecWysokiegoNapieciaTrafo':
      return PowerSupplyType.przylaczeSNZTrafo;
    case 'siecNiskiegoNapieciaBezposrednio':
      return PowerSupplyType.przylaczeNN;
    default:
      return PowerSupplyType.przylaczeNN;
  }
}

PowerSupplyArchitectureType _parsePowerSupplyArchitectureType(String? value) {
  switch (value) {
    case 'lvDirect':
      return PowerSupplyArchitectureType.lvDirect;
    case 'lvWithMainBoard':
      return PowerSupplyArchitectureType.lvWithMainBoard;
    case 'mvTransformerSingle':
      return PowerSupplyArchitectureType.mvTransformerSingle;
    case 'mvTransformerMulti':
      return PowerSupplyArchitectureType.mvTransformerMulti;
    case 'mvWithSwitchgear':
      return PowerSupplyArchitectureType.mvWithSwitchgear;
    case 'mvDualFeed':
      return PowerSupplyArchitectureType.mvDualFeed;
    case 'przylaczeSNZTrafo':
    case 'siecWysokiegoNapieciaTrafo':
      return PowerSupplyArchitectureType.mvTransformerSingle;
    case 'wlasnaGeneracja':
      return PowerSupplyArchitectureType.lvWithMainBoard;
    case 'przylaczeNN':
    case 'siecNiskiegoNapieciaBezposrednio':
    default:
      return PowerSupplyArchitectureType.lvDirect;
  }
}

ConnectionType _parseConnectionType(String? value) {
  switch (value) {
    case 'zlaczeDynamiczne':
      return ConnectionType.zlaczeDynamiczne;
    case 'rozdzielnicaSN':
      return ConnectionType.rozdzielnicaSN;
    case 'rozdzielnicaNN':
      return ConnectionType.rozdzielnicaNN;
    default:
      return ConnectionType.zlaczeDynamiczne;
  }
}

BackupSystemType _parseBackupSystemType(String? value) {
  switch (value) {
    case 'ups':
    case 'UPS':
      return BackupSystemType.ups;
    case 'generator':
    case 'GENERATOR':
      return BackupSystemType.generator;
    case 'upsGeneratorCombo':
    case 'UPS_GENERATOR_COMBO':
      return BackupSystemType.upsGeneratorCombo;
    default:
      return BackupSystemType.ups;
  }
}

BackupCoverage _parseBackupCoverage(String? value) {
  switch (value) {
    case 'full':
    case 'FULL':
      return BackupCoverage.full;
    case 'critical':
    case 'CRITICAL':
    default:
      return BackupCoverage.critical;
  }
}

RenewableSystemType _parseRenewableSystemType(String? value) {
  switch (value) {
    case 'pvOnGrid':
    case 'PV_ON_GRID':
      return RenewableSystemType.pvOnGrid;
    case 'pvWithStorage':
    case 'PV_WITH_STORAGE':
      return RenewableSystemType.pvWithStorage;
    default:
      return RenewableSystemType.pvOnGrid;
  }
}

enum ConnectionType {
  zlaczeDynamiczne, // Złącze dynamiczne
  rozdzielnicaSN, // Rozdzielnica SN
  rozdzielnicaNN, // Rozdzielnica NN
}

enum ElectricalSystemType {
  oswietlenie, // Oświetlenie (LED/żarówki)
  zasilanie, // Zasilanie gniazdek
  oswietlenieAwaryjneEwakuacyjne,
  gniazdaDedykowane,
  trasyKablowe,
  wlz,
  rozdzielniceRgRnnRsn,
  uziemieniePolaczeniaWyrownawcze,
  klimatyzacja, // Klimatyzacja/ogrzewanie
  wentylacja,
  automatykaHvac,
  windaAscensor, // Winda/ascensor
  domofonowa, // Domofon (analogowy/cyfrowy)
  telewizja, // Antena telewizyjna/kablówka
  internet, // Internet/lan
  lan,
  swiatlowod,
  wifi,
  voip,
  dataRoom,
  av,
  digitalSignage,
  odgromowa, // Ochrona odgromowa
  panelePV, // Panele słoneczne
  magazynEnergii,
  ladownarki, // Ładowarki samochodowe
  agregat, // Agregat prądotwórczy
  ups,
  szr,
  dualFeedSn,
  ukladyPomiarowe,
  podlicznikiEnergii,
  analizatorySieci,
  ems,
  ppoz, // Systemy ppoż (fire alarm)
  dso, // DSO (detektory dymu)
  kd,
  czujnikiRuchu, // Czujniki ruchu/alarm
  podgrzewanePodjazdy, // Grzejniki podjazdów
  ogrzewanieRur, // Grzejniki rur
  floorboxy,
  zasilanieStanowiskPracy,
  rezerwacjaSal,
  cctv, // Monitoring (CCTV)
  sswim, // SSWIM (system sygnalizacji)
  gaszeniGazem, // Gaszenie gazem (FM200, CO2)
  ewakuacyjne, // Oprawy ewakuacyjne
  smartHome, // Automatyka (smart home)
  oddymianieKlatek, // Oddymianie klatek
  bms, // BMS (zarządzanie budynkiem)
  integracjaSystemow,
  psimSms,
  wykrywaniWyciekow, // Detektory wycieków
  itp, // Inne
}

ElectricalSystemType _parseElectricalSystemType(String? value) {
  switch (value) {
    case 'oswietlenie':
      return ElectricalSystemType.oswietlenie;
    case 'zasilanie':
      return ElectricalSystemType.zasilanie;
    case 'oswietlenieAwaryjneEwakuacyjne':
    case 'ewakuacyjne':
      return ElectricalSystemType.oswietlenieAwaryjneEwakuacyjne;
    case 'gniazdaDedykowane':
      return ElectricalSystemType.gniazdaDedykowane;
    case 'trasyKablowe':
      return ElectricalSystemType.trasyKablowe;
    case 'wlz':
      return ElectricalSystemType.wlz;
    case 'rozdzielniceRgRnnRsn':
      return ElectricalSystemType.rozdzielniceRgRnnRsn;
    case 'uziemieniePolaczeniaWyrownawcze':
      return ElectricalSystemType.uziemieniePolaczeniaWyrownawcze;
    case 'klimatyzacja':
      return ElectricalSystemType.klimatyzacja;
    case 'wentylacja':
      return ElectricalSystemType.wentylacja;
    case 'automatykaHvac':
      return ElectricalSystemType.automatykaHvac;
    case 'windaAscensor':
      return ElectricalSystemType.windaAscensor;
    case 'domofonowa':
      return ElectricalSystemType.domofonowa;
    case 'telewizja':
      return ElectricalSystemType.telewizja;
    case 'internet':
      return ElectricalSystemType.internet;
    case 'lan':
      return ElectricalSystemType.lan;
    case 'swiatlowod':
      return ElectricalSystemType.swiatlowod;
    case 'wifi':
      return ElectricalSystemType.wifi;
    case 'voip':
      return ElectricalSystemType.voip;
    case 'dataRoom':
      return ElectricalSystemType.dataRoom;
    case 'av':
      return ElectricalSystemType.av;
    case 'digitalSignage':
      return ElectricalSystemType.digitalSignage;
    case 'odgromowa':
      return ElectricalSystemType.odgromowa;
    case 'panelePV':
      return ElectricalSystemType.panelePV;
    case 'magazynEnergii':
      return ElectricalSystemType.magazynEnergii;
    case 'ladownarki':
      return ElectricalSystemType.ladownarki;
    case 'agregat':
      return ElectricalSystemType.agregat;
    case 'ups':
      return ElectricalSystemType.ups;
    case 'szr':
      return ElectricalSystemType.szr;
    case 'dualFeedSn':
      return ElectricalSystemType.dualFeedSn;
    case 'ukladyPomiarowe':
      return ElectricalSystemType.ukladyPomiarowe;
    case 'podlicznikiEnergii':
      return ElectricalSystemType.podlicznikiEnergii;
    case 'analizatorySieci':
      return ElectricalSystemType.analizatorySieci;
    case 'ems':
      return ElectricalSystemType.ems;
    case 'ppoz':
      return ElectricalSystemType.ppoz;
    case 'dso':
      return ElectricalSystemType.dso;
    case 'kd':
      return ElectricalSystemType.kd;
    case 'czujnikiRuchu':
      return ElectricalSystemType.czujnikiRuchu;
    case 'podgrzewanePodjazdy':
      return ElectricalSystemType.podgrzewanePodjazdy;
    case 'ogrzewanieRur':
      return ElectricalSystemType.ogrzewanieRur;
    case 'floorboxy':
      return ElectricalSystemType.floorboxy;
    case 'zasilanieStanowiskPracy':
      return ElectricalSystemType.zasilanieStanowiskPracy;
    case 'rezerwacjaSal':
      return ElectricalSystemType.rezerwacjaSal;
    case 'cctv':
      return ElectricalSystemType.cctv;
    case 'sswim':
      return ElectricalSystemType.sswim;
    case 'gaszeniGazem':
      return ElectricalSystemType.gaszeniGazem;
    case 'smartHome':
      return ElectricalSystemType.smartHome;
    case 'oddymianieKlatek':
      return ElectricalSystemType.oddymianieKlatek;
    case 'bms':
      return ElectricalSystemType.bms;
    case 'integracjaSystemow':
      return ElectricalSystemType.integracjaSystemow;
    case 'psimSms':
      return ElectricalSystemType.psimSms;
    case 'wykrywaniWyciekow':
      return ElectricalSystemType.wykrywaniWyciekow;
    case 'itp':
    default:
      return ElectricalSystemType.itp;
  }
}

extension ElectricalSystemTypePresentation on ElectricalSystemType {
  String get displayName {
    switch (this) {
      case ElectricalSystemType.oswietlenie:
        return 'Oświetlenie podstawowe';
      case ElectricalSystemType.zasilanie:
        return 'Gniazda ogólne';
      case ElectricalSystemType.oswietlenieAwaryjneEwakuacyjne:
        return 'Oświetlenie awaryjne i ewakuacyjne';
      case ElectricalSystemType.gniazdaDedykowane:
        return 'Gniazda dedykowane';
      case ElectricalSystemType.trasyKablowe:
        return 'Trasy kablowe';
      case ElectricalSystemType.wlz:
        return 'WLZ';
      case ElectricalSystemType.rozdzielniceRgRnnRsn:
        return 'Rozdzielnice RG / RNN / RSN';
      case ElectricalSystemType.uziemieniePolaczeniaWyrownawcze:
        return 'Uziemienie i połączenia wyrównawcze';
      case ElectricalSystemType.klimatyzacja:
        return 'Klimatyzacja';
      case ElectricalSystemType.wentylacja:
        return 'Wentylacja';
      case ElectricalSystemType.automatykaHvac:
        return 'Automatyka HVAC';
      case ElectricalSystemType.windaAscensor:
        return 'Windy / ascensory';
      case ElectricalSystemType.domofonowa:
        return 'Domofon / wideodomofon';
      case ElectricalSystemType.telewizja:
        return 'Telewizja / RTV-SAT';
      case ElectricalSystemType.internet:
      case ElectricalSystemType.lan:
        return 'LAN';
      case ElectricalSystemType.swiatlowod:
        return 'Światłowód';
      case ElectricalSystemType.wifi:
        return 'Wi-Fi';
      case ElectricalSystemType.voip:
        return 'VoIP';
      case ElectricalSystemType.dataRoom:
        return 'Data Room';
      case ElectricalSystemType.av:
        return 'AV';
      case ElectricalSystemType.digitalSignage:
        return 'Digital Signage';
      case ElectricalSystemType.odgromowa:
        return 'Instalacja odgromowa';
      case ElectricalSystemType.panelePV:
        return 'Fotowoltaika (PV)';
      case ElectricalSystemType.magazynEnergii:
        return 'Magazyn energii (BESS)';
      case ElectricalSystemType.ladownarki:
        return 'Ładowarki EV';
      case ElectricalSystemType.agregat:
        return 'Agregat prądotwórczy';
      case ElectricalSystemType.ups:
        return 'UPS';
      case ElectricalSystemType.szr:
        return 'SZR';
      case ElectricalSystemType.dualFeedSn:
        return 'Dual feed SN';
      case ElectricalSystemType.ukladyPomiarowe:
        return 'Układy pomiarowe';
      case ElectricalSystemType.podlicznikiEnergii:
        return 'Podliczniki energii';
      case ElectricalSystemType.analizatorySieci:
        return 'Analizatory sieci';
      case ElectricalSystemType.ems:
        return 'EMS';
      case ElectricalSystemType.ppoz:
        return 'SSP';
      case ElectricalSystemType.dso:
        return 'DSO';
      case ElectricalSystemType.kd:
        return 'KD';
      case ElectricalSystemType.czujnikiRuchu:
        return 'Czujniki ruchu';
      case ElectricalSystemType.podgrzewanePodjazdy:
        return 'Podgrzewane podjazdy';
      case ElectricalSystemType.ogrzewanieRur:
        return 'Ogrzewanie rur';
      case ElectricalSystemType.floorboxy:
        return 'Floorboxy';
      case ElectricalSystemType.zasilanieStanowiskPracy:
        return 'Zasilanie stanowisk pracy';
      case ElectricalSystemType.rezerwacjaSal:
        return 'Rezerwacja sal';
      case ElectricalSystemType.cctv:
        return 'CCTV';
      case ElectricalSystemType.sswim:
        return 'SSWiM';
      case ElectricalSystemType.gaszeniGazem:
        return 'Gaszenie gazem';
      case ElectricalSystemType.ewakuacyjne:
        return 'Oprawy ewakuacyjne';
      case ElectricalSystemType.smartHome:
        return 'Smart Home';
      case ElectricalSystemType.oddymianieKlatek:
        return 'Oddymianie';
      case ElectricalSystemType.bms:
        return 'BMS';
      case ElectricalSystemType.integracjaSystemow:
        return 'Integracja systemów';
      case ElectricalSystemType.psimSms:
        return 'PSIM / SMS';
      case ElectricalSystemType.wykrywaniWyciekow:
        return 'Detekcja wycieków';
      case ElectricalSystemType.itp:
        return 'Inne';
    }
  }
}

enum BuildingStage {
  przygotowanie, // Faza 0: Projekty, harmonogram, zamówienia
  fundamenty, // Faza 1: Fundamenty, dreny
  konstrukcja, // Faza 2: Szkielety, stropy, słupy
  przegrody, // Faza 3: Ścianki działowe, przechody
  tynki, // Faza 4: Tynki (zewnętrzne + wewnętrzne)
  posadzki, // Faza 5: Posadzki, wylewki
  osprzet, // Faza 6: Osprzęt elektryczny, oprawy
  malowanie, // Faza 7: Malowanie, lakierowanie
  finalizacja, // Faza 8: Drzwi finalne, meblościany
  oddawanie, // Faza 9: Pomiary, dokumentacja, odbiór
  ozeInstalacje, // Faza 10: Instalacje OZE (PV, BESS, magazyny energii)
  evInfrastruktura, // Faza 11: Infrastruktura elektromobilności (ładowarki EV)
}

enum TaskStatus {
  pending, // Oczekujące
  inProgress, // W trakcie
  blocked, // Zablokowane (czeka na inne zadania)
  completed, // Ukończone
  attention, // Wymaga uwagi
  delayed, // Opóźnione
}

enum AlertSeverity {
  info, // Informacja
  warning, // Ostrzeżenie
  critical, // Krytyczne
  urgent, // Pilne
}

enum AdditionalRoomLevelType {
  nadziemna, // Kondygnacja nadziemna
  podziemna, // Kondygnacja podziemna
}

enum AdditionalRoomInstallation {
  zasilanie,
  oswietlenie,
  teletechnika,
  cctv,
  ppoz,
  ssp,
  wentylacja,
  klimatyzacja,
  oddymianie,
}

enum AdditionalRoomTask {
  projekt,
  okablowanie,
  montazOsprzetu,
  pomiary,
  uruchomienie,
  odbior,
}

class FloorUnitNumberingConfig {
  final String constructionStartLabel;
  final String targetStartLabel;

  const FloorUnitNumberingConfig({
    required this.constructionStartLabel,
    required this.targetStartLabel,
  });

  factory FloorUnitNumberingConfig.defaultForFloor({
    required String stairCaseName,
    required int floor,
  }) {
    final defaultStart =
        '$stairCaseName.${(floor * 100 + 1).toString().padLeft(3, '0')}';
    return FloorUnitNumberingConfig(
      constructionStartLabel: defaultStart,
      targetStartLabel: defaultStart,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'constructionStartLabel': constructionStartLabel,
      'targetStartLabel': targetStartLabel,
    };
  }

  factory FloorUnitNumberingConfig.fromJson(Map<String, dynamic> json) {
    final fallback = json['startLabel'] as String? ?? '';
    return FloorUnitNumberingConfig(
      constructionStartLabel:
          json['constructionStartLabel'] as String? ?? fallback,
      targetStartLabel: json['targetStartLabel'] as String? ?? fallback,
    );
  }

  String rangeLabel(int count, UnitNamingScheme scheme) {
    final labels = labelsForCount(count, scheme);
    if (labels.isEmpty) {
      return '-';
    }
    if (labels.length == 1) {
      return labels.first;
    }
    return '${labels.first}-${labels.last}';
  }

  List<String> labelsForCount(int count, UnitNamingScheme scheme) {
    final startLabel = scheme == UnitNamingScheme.target
        ? targetStartLabel
        : constructionStartLabel;
    return _buildSequence(startLabel, count);
  }

  static List<String> _buildSequence(String startLabel, int count) {
    if (count <= 0) {
      return const [];
    }

    final normalized = startLabel.trim();
    if (normalized.isEmpty) {
      return List<String>.generate(count, (index) => '${index + 1}');
    }

    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(normalized);
    if (match == null) {
      return List<String>.generate(
        count,
        (index) => index == 0 ? normalized : '$normalized-${index + 1}',
      );
    }

    final prefix = match.group(1) ?? '';
    final numericPart = match.group(2)!;
    final start = int.tryParse(numericPart) ?? 1;
    final width = numericPart.length;

    return List<String>.generate(
      count,
      (index) => '$prefix${(start + index).toString().padLeft(width, '0')}',
    );
  }
}

const String kAlternateProjectTaskId = 'unit-01-alt-project';

// ═══════════════════════════════════════════════════════════════════════════
// GŁÓWNE MODELE DANYCH
// ═══════════════════════════════════════════════════════════════════════════

/// Szczegóły klatki schodowej z informacją o piętrach i mieszkaniach
class StairCaseDetails {
  final String stairCaseName; // A, B, C, D
  final int numberOfLevels; // Ile pięter ma ta konkretna klatka
  final Map<int, int> unitsPerFloor; // Piętro -> ilość mieszkań na piętrze
  final int numberOfElevators; // Liczba dźwigów w tej klatce
  final Map<int, String>
      floorNames; // Piętro -> customowa nazwa (np. "Parter", "I piętro")
  final Map<int, FloorUnitNumberingConfig> floorUnitNumbering;

  StairCaseDetails({
    required this.stairCaseName,
    required this.numberOfLevels,
    Map<int, int>? unitsPerFloor,
    this.numberOfElevators = 0,
    Map<int, String>? floorNames,
    Map<int, FloorUnitNumberingConfig>? floorUnitNumbering,
  })  : unitsPerFloor = unitsPerFloor ?? {},
        floorNames = floorNames ?? {},
        floorUnitNumbering = floorUnitNumbering ?? {};

  // Całkowita liczba jednostek w tej klatce
  int get totalUnits {
    return unitsPerFloor.values.fold(0, (sum, count) => sum + count);
  }

  // Pobierz nazwę piętra (customowa lub domyślna "P. X")
  String getFloorName(int floor) {
    return floorNames[floor] ?? 'P. $floor';
  }

  FloorUnitNumberingConfig getFloorUnitNumbering(int floor) {
    return floorUnitNumbering[floor] ??
        FloorUnitNumberingConfig.defaultForFloor(
          stairCaseName: stairCaseName,
          floor: floor,
        );
  }

  List<String> getFloorUnitLabels(
    int floor,
    UnitNamingScheme scheme,
  ) {
    final count = unitsPerFloor[floor] ?? 0;
    return getFloorUnitNumbering(floor).labelsForCount(count, scheme);
  }

  String getFloorUnitRangeLabel(
    int floor,
    UnitNamingScheme scheme,
  ) {
    final count = unitsPerFloor[floor] ?? 0;
    return getFloorUnitNumbering(floor).rangeLabel(count, scheme);
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'stairCaseName': stairCaseName,
      'numberOfLevels': numberOfLevels,
      'unitsPerFloor': unitsPerFloor.map((k, v) => MapEntry(k.toString(), v)),
      'numberOfElevators': numberOfElevators,
      'floorNames': floorNames.map((k, v) => MapEntry(k.toString(), v)),
      'floorUnitNumbering': floorUnitNumbering.map(
        (k, v) => MapEntry(k.toString(), v.toJson()),
      ),
    };
  }

  factory StairCaseDetails.fromJson(Map<String, dynamic> json) {
    return StairCaseDetails(
      stairCaseName: json['stairCaseName'] as String,
      numberOfLevels: json['numberOfLevels'] as int,
      unitsPerFloor: (json['unitsPerFloor'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as int),
          ) ??
          {},
      numberOfElevators: json['numberOfElevators'] as int? ?? 0,
      floorNames: (json['floorNames'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), v as String),
          ) ??
          {},
      floorUnitNumbering:
          (json['floorUnitNumbering'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                  int.parse(k),
                  FloorUnitNumberingConfig.fromJson(v as Map<String, dynamic>),
                ),
              ) ??
              {},
    );
  }
}

/// Budynek z informacją o klatkach, piętrach podziemnych itp.
class BuildingDetails {
  final String buildingName; // "Budynek 1", "A", "B"
  final List<StairCaseDetails> stairCases; // Klatki schodowe
  final int basementLevels; // Piętra podziemne (jeśli ma garaż)

  BuildingDetails({
    required this.buildingName,
    required this.stairCases,
    this.basementLevels = 0,
  });

  // Całkowita liczba pięter nadziemnych (max ze wszystkich klatek)
  int get totalLevels {
    if (stairCases.isEmpty) return 0;
    return stairCases
        .map((sc) => sc.numberOfLevels)
        .reduce((a, b) => a > b ? a : b);
  }

  // Całkowita liczba mieszkań w budynku
  int get totalUnits {
    return stairCases.fold<int>(0, (sum, sc) => sum + sc.totalUnits);
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'buildingName': buildingName,
      'stairCases': stairCases.map((sc) => sc.toJson()).toList(),
      'basementLevels': basementLevels,
    };
  }

  factory BuildingDetails.fromJson(Map<String, dynamic> json) {
    return BuildingDetails(
      buildingName: json['buildingName'] as String,
      stairCases: (json['stairCases'] as List)
          .map((sc) => StairCaseDetails.fromJson(sc as Map<String, dynamic>))
          .toList(),
      basementLevels: json['basementLevels'] as int? ?? 0,
    );
  }
}

/// Szczegóły klatki schodowej z informacją o piętrach i mieszkaniach
class BuildingConfiguration {
  final String projectName;
  final BuildingType buildingType;
  final String address;
  final DateTime projectStartDate;
  final DateTime projectEndDate;

  // Parametry budynku
  final int numberOfBuildings; // Ile budynków w projekcie
  final bool hasGarage; // Czy jest garaż (dotyczy wszystkich budynków)
  final bool hasParking; // Czy jest parking

  // Szczegóły budynków z klatkami
  final List<BuildingDetails> buildings; // Informacja o każdym budynku

  // Zasilanie
  final PowerSupplyType powerSupplyType;
  final ConnectionType connectionType;
  final PowerSupplyArchitectureType powerSupplyArchitecture;
  final List<BackupSystemConfig> backupSystems;
  final List<RenewableSystemConfig> renewableSystems;
  final bool offGridMode;
  final String energySupplier;
  final double estimatedPowerDemand; // kW

  // Systemy elektryczne
  final Set<ElectricalSystemType> selectedSystems;

  // Konfiguracja odnawialnych źródeł energii (OZE) i elektromobilności (EV)
  final RenewableEnergyConfiguration? renewableEnergyConfig;

  // Pomieszczenia dodatkowe
  final List<AdditionalRoom> additionalRooms;
  final List<SubcontractorAssignment> subcontractors;
  final List<SubcontractorLink> subcontractorLinks;
  final UnitNamingScheme defaultUnitNamingScheme;

  // Mieszkańcy/szacunkowa liczba lokali
  final int estimatedUnits; // Liczba mieszkań/biur

  // Całkowity czas budowy (w tygodniach) - użytkownik podaje całkowity czas
  final int totalBuildingWeeks;

  // Aktualny etap budowy - dla celów śledzenia które prace już wykonano
  final BuildingStage currentBuildingStage;

  // Dodatkowe info
  final String notes;
  final DateTime? createdAt;

  BuildingConfiguration({
    required this.projectName,
    required this.buildingType,
    required this.address,
    required this.projectStartDate,
    required this.projectEndDate,
    required this.numberOfBuildings,
    required this.hasGarage,
    required this.hasParking,
    required this.buildings,
    required this.powerSupplyType,
    required this.connectionType,
    PowerSupplyArchitectureType? powerSupplyArchitecture,
    List<BackupSystemConfig>? backupSystems,
    List<RenewableSystemConfig>? renewableSystems,
    this.offGridMode = false,
    required this.energySupplier,
    required this.estimatedPowerDemand,
    required this.selectedSystems,
    required this.additionalRooms,
    List<SubcontractorAssignment>? subcontractors,
    List<SubcontractorLink>? subcontractorLinks,
    this.defaultUnitNamingScheme = UnitNamingScheme.construction,
    required this.estimatedUnits,
    required this.totalBuildingWeeks,
    required this.currentBuildingStage,
    this.renewableEnergyConfig,
    this.notes = '',
    DateTime? createdAt,
  })  : powerSupplyArchitecture = powerSupplyArchitecture ??
            _deriveArchitectureFromLegacy(powerSupplyType, connectionType),
        backupSystems = backupSystems ?? const [],
        renewableSystems = renewableSystems ?? const [],
        subcontractors = subcontractors ?? const [],
        subcontractorLinks = subcontractorLinks ?? const [],
        createdAt = createdAt ?? DateTime.now();

  static PowerSupplyArchitectureType recommendPowerSupplyArchitecture({
    required BuildingType buildingType,
    required int estimatedUnits,
    required int totalLevels,
    required double estimatedPowerDemand,
  }) {
    if (buildingType == BuildingType.mieszkalny) {
      if (estimatedUnits <= 20 &&
          totalLevels <= 4 &&
          estimatedPowerDemand <= 160) {
        return PowerSupplyArchitectureType.lvDirect;
      }
      if (estimatedUnits <= 80 && estimatedPowerDemand <= 500) {
        return PowerSupplyArchitectureType.lvWithMainBoard;
      }
      return PowerSupplyArchitectureType.mvTransformerSingle;
    }

    if (estimatedPowerDemand >= 900 ||
        totalLevels >= 10 ||
        estimatedUnits >= 120) {
      return PowerSupplyArchitectureType.mvDualFeed;
    }
    if (estimatedPowerDemand >= 450) {
      return PowerSupplyArchitectureType.mvWithSwitchgear;
    }
    if (estimatedPowerDemand >= 220) {
      return PowerSupplyArchitectureType.mvTransformerSingle;
    }
    return PowerSupplyArchitectureType.lvWithMainBoard;
  }

  static PowerSupplyArchitectureType _deriveArchitectureFromLegacy(
    PowerSupplyType powerSupplyType,
    ConnectionType connectionType,
  ) {
    if (powerSupplyType == PowerSupplyType.przylaczeSNZTrafo) {
      if (connectionType == ConnectionType.rozdzielnicaSN) {
        return PowerSupplyArchitectureType.mvWithSwitchgear;
      }
      return PowerSupplyArchitectureType.mvTransformerSingle;
    }
    if (powerSupplyType == PowerSupplyType.wlasnaGeneracja) {
      return PowerSupplyArchitectureType.lvWithMainBoard;
    }
    if (connectionType == ConnectionType.rozdzielnicaNN) {
      return PowerSupplyArchitectureType.lvWithMainBoard;
    }
    return PowerSupplyArchitectureType.lvDirect;
  }

  bool get usesMediumVoltage {
    return powerSupplyArchitecture ==
            PowerSupplyArchitectureType.mvTransformerSingle ||
        powerSupplyArchitecture ==
            PowerSupplyArchitectureType.mvTransformerMulti ||
        powerSupplyArchitecture ==
            PowerSupplyArchitectureType.mvWithSwitchgear ||
        powerSupplyArchitecture == PowerSupplyArchitectureType.mvDualFeed;
  }

  PowerValidationResult validatePowerModel() {
    final issues = <PowerValidationIssue>[];

    final hasGridConnection =
        powerSupplyType != PowerSupplyType.wlasnaGeneracja;
    final hasPv = renewableSystems.any(
      (system) =>
          system.type == RenewableSystemType.pvOnGrid ||
          system.type == RenewableSystemType.pvWithStorage,
    );

    if (powerSupplyArchitecture == PowerSupplyArchitectureType.mvDualFeed &&
        connectionType != ConnectionType.rozdzielnicaSN) {
      issues.add(
        const PowerValidationIssue(
          severity: PowerValidationSeverity.error,
          message:
              'Zasilanie dwustronne wymaga infrastruktury SN i rozdzielnicy SN.',
        ),
      );
    }

    if (backupSystems.any((backup) => backup.type == BackupSystemType.ups) &&
        backupSystems.any((backup) => backup.covers == BackupCoverage.full)) {
      issues.add(
        const PowerValidationIssue(
          severity: PowerValidationSeverity.warning,
          message:
              'UPS ustawiony na zasilanie calosci obiektu. Zweryfikuj, czy wymagane sa dedykowane odbiory krytyczne.',
        ),
      );
    }

    if (hasPv && !hasGridConnection && !offGridMode) {
      issues.add(
        const PowerValidationIssue(
          severity: PowerValidationSeverity.error,
          message:
              'PV bez polaczenia z siecia wymaga trybu off-grid albo zapewnienia przylacza sieciowego.',
        ),
      );
    }

    if (renewableSystems
            .any((system) => system.type == RenewableSystemType.pvOnGrid) &&
        offGridMode) {
      issues.add(
        const PowerValidationIssue(
          severity: PowerValidationSeverity.error,
          message: 'System PV_ON_GRID nie jest zgodny z trybem off-grid.',
        ),
      );
    }

    return PowerValidationResult(issues);
  }

  // Oblicz całkowity czas budowy (z danych użytkownika)
  Duration get buildingDuration {
    return projectEndDate.difference(projectStartDate);
  }

  // Całkowita liczba pięter nadziemnych (max ze wszystkich budynków)
  int get totalLevels {
    if (buildings.isEmpty) return 0;
    return buildings.map((b) => b.totalLevels).reduce((a, b) => a > b ? a : b);
  }

  // Całkowita liczba pięter podziemnych
  int get basementLevels {
    if (!hasGarage) return 0;
    if (buildings.isEmpty) return 0;
    return buildings.first.basementLevels;
  }

  // Liczba klatek schodowych (ze wszystkich budynków)
  int get estimatedStairCases {
    return buildings.fold<int>(0, (sum, b) => sum + b.stairCases.length);
  }

  // Całkowita liczba dźwigów (ze wszystkich klatek)
  int get numberOfElevators {
    int total = 0;
    for (final building in buildings) {
      for (final stairCase in building.stairCases) {
        total += stairCase.numberOfElevators;
      }
    }
    return total;
  }

  // Oblicz przewidywaną datę zakończenia
  DateTime get estimatedEndDate {
    return projectEndDate;
  }

  // Oblicz datę startu do prefabrykacji (4 tygodnie przed połową budowy)
  DateTime get prefabrication4WeeksBefore {
    int halfWeeks = totalBuildingWeeks ~/ 2;
    return projectStartDate.add(Duration(days: (halfWeeks - 4) * 7));
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'projectName': projectName,
      'buildingType': buildingType.name,
      'address': address,
      'projectStartDate': projectStartDate.toIso8601String(),
      'projectEndDate': projectEndDate.toIso8601String(),
      'numberOfBuildings': numberOfBuildings,
      'hasGarage': hasGarage,
      'hasParking': hasParking,
      'buildings': buildings.map((b) => b.toJson()).toList(),
      'powerSupplyType': powerSupplyType.name,
      'connectionType': connectionType.name,
      'powerSupplyArchitecture': powerSupplyArchitecture.name,
      'backupSystems': backupSystems.map((s) => s.toJson()).toList(),
      'renewableSystems': renewableSystems.map((s) => s.toJson()).toList(),
      'offGridMode': offGridMode,
      'energySupplier': energySupplier,
      'estimatedPowerDemand': estimatedPowerDemand,
      'selectedSystems': selectedSystems.map((s) => s.name).toList(),
      'renewableEnergyConfig': renewableEnergyConfig?.toJson(),
      'additionalRooms': additionalRooms.map((r) => r.toJson()).toList(),
      'subcontractors': subcontractors.map((s) => s.toJson()).toList(),
      'subcontractorLinks':
          subcontractorLinks.map((link) => link.toJson()).toList(),
      'defaultUnitNamingScheme': defaultUnitNamingScheme.name,
      'estimatedUnits': estimatedUnits,
      'totalBuildingWeeks': totalBuildingWeeks,
      'currentBuildingStage': currentBuildingStage.name,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory BuildingConfiguration.fromJson(Map<String, dynamic> json) {
    final legacyPowerSupplyType = _parsePowerSupplyType(
      json['powerSupplyType'] as String?,
    );
    final legacyConnectionType = _parseConnectionType(
      json['connectionType'] as String?,
    );

    final architecture = json['powerSupplyArchitecture'] != null
        ? _parsePowerSupplyArchitectureType(
            json['powerSupplyArchitecture'] as String?)
        : _deriveArchitectureFromLegacy(
            legacyPowerSupplyType, legacyConnectionType);

    final backupSystems = (json['backupSystems'] as List?)
            ?.map((item) =>
                BackupSystemConfig.fromJson(item as Map<String, dynamic>))
            .toList() ??
        _migrateLegacyBackupSystems(
          selectedSystemsRaw:
              (json['selectedSystems'] as List?)?.cast<String>() ?? const [],
        );

    final renewableSystems = (json['renewableSystems'] as List?)
            ?.map((item) =>
                RenewableSystemConfig.fromJson(item as Map<String, dynamic>))
            .toList() ??
        _migrateLegacyRenewableSystems(
          renewableEnergyConfigRaw:
              json['renewableEnergyConfig'] as Map<String, dynamic>?,
        );

    return BuildingConfiguration(
      projectName: json['projectName'] as String,
      buildingType: _parseBuildingType(json['buildingType'] as String?),
      address: json['address'] as String,
      projectStartDate: DateTime.parse(json['projectStartDate'] as String),
      projectEndDate: DateTime.parse(json['projectEndDate'] as String),
      numberOfBuildings: json['numberOfBuildings'] as int,
      hasGarage: json['hasGarage'] as bool,
      hasParking: json['hasParking'] as bool,
      buildings: (json['buildings'] as List)
          .map((b) => BuildingDetails.fromJson(b as Map<String, dynamic>))
          .toList(),
      powerSupplyType: legacyPowerSupplyType,
      connectionType: legacyConnectionType,
      powerSupplyArchitecture: architecture,
      backupSystems: backupSystems,
      renewableSystems: renewableSystems,
      offGridMode: json['offGridMode'] as bool? ?? false,
      energySupplier: json['energySupplier'] as String? ?? 'Nie wybrano',
      estimatedPowerDemand: (json['estimatedPowerDemand'] as num).toDouble(),
      selectedSystems: (json['selectedSystems'] as List)
          .map((s) => _parseElectricalSystemType(s as String?))
          .toSet(),
      additionalRooms: (json['additionalRooms'] as List?)
              ?.map((r) => AdditionalRoom.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      subcontractors: (json['subcontractors'] as List?)
              ?.map((s) =>
                  SubcontractorAssignment.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      subcontractorLinks: (json['subcontractorLinks'] as List?)
              ?.map((link) =>
                  SubcontractorLink.fromJson(link as Map<String, dynamic>))
              .toList() ??
          [],
      defaultUnitNamingScheme:
          _parseUnitNamingScheme(json['defaultUnitNamingScheme'] as String?),
      estimatedUnits: json['estimatedUnits'] as int,
      totalBuildingWeeks: json['totalBuildingWeeks'] as int,
      currentBuildingStage: BuildingStage.values.firstWhere(
        (e) => e.name == json['currentBuildingStage'],
      ),
      renewableEnergyConfig: json['renewableEnergyConfig'] != null
          ? RenewableEnergyConfiguration.fromJson(
              json['renewableEnergyConfig'] as Map<String, dynamic>)
          : null,
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  static List<BackupSystemConfig> _migrateLegacyBackupSystems({
    required List<String> selectedSystemsRaw,
  }) {
    final hasGenerator =
        selectedSystemsRaw.contains(ElectricalSystemType.agregat.name);
    if (!hasGenerator) {
      return const [];
    }
    return const [
      BackupSystemConfig(
        type: BackupSystemType.generator,
        priority: 1,
        covers: BackupCoverage.critical,
        autonomyMinutes: 480,
      ),
    ];
  }

  static List<RenewableSystemConfig> _migrateLegacyRenewableSystems({
    required Map<String, dynamic>? renewableEnergyConfigRaw,
  }) {
    if (renewableEnergyConfigRaw == null) {
      return const [];
    }

    final photovoltaic =
        renewableEnergyConfigRaw['photovoltaic'] as Map<String, dynamic>?;
    final batteryStorage =
        renewableEnergyConfigRaw['batteryStorage'] as Map<String, dynamic>?;
    final hasPv = photovoltaic?['isEnabled'] as bool? ?? false;
    if (!hasPv) {
      return const [];
    }

    final hasStorage = batteryStorage?['isEnabled'] as bool? ?? false;
    final powerKW = (photovoltaic?['installedPowerKwp'] as num?)?.toDouble();
    return [
      RenewableSystemConfig(
        type: hasStorage
            ? RenewableSystemType.pvWithStorage
            : RenewableSystemType.pvOnGrid,
        powerKW: powerKW,
        integratedWithBackup: hasStorage,
      ),
    ];
  }
}

class SubcontractorAssignment {
  final String id;
  final String companyName;
  final Set<SubcontractorArea> areas;
  final String responsibilities;
  final String details;

  SubcontractorAssignment({
    required this.id,
    required this.companyName,
    this.areas = const {},
    this.responsibilities = '',
    this.details = '',
  });

  SubcontractorAssignment copyWith({
    String? id,
    String? companyName,
    Set<SubcontractorArea>? areas,
    String? responsibilities,
    String? details,
  }) {
    return SubcontractorAssignment(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      areas: areas ?? this.areas,
      responsibilities: responsibilities ?? this.responsibilities,
      details: details ?? this.details,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'areas': areas.map((area) => area.name).toList(),
      'responsibilities': responsibilities,
      'details': details,
    };
  }

  factory SubcontractorAssignment.fromJson(Map<String, dynamic> json) {
    return SubcontractorAssignment(
      id: json['id'] as String,
      companyName: json['companyName'] as String? ?? '',
      areas: (json['areas'] as List?)
              ?.map((area) => _parseSubcontractorArea(area as String?))
              .toSet() ??
          {},
      responsibilities: json['responsibilities'] as String? ?? '',
      details: json['details'] as String? ?? '',
    );
  }
}

class SubcontractorLink {
  final String subcontractorId;
  final SubcontractorTargetType targetType;
  final String targetId;
  final bool blockInheritance;

  const SubcontractorLink({
    required this.subcontractorId,
    required this.targetType,
    required this.targetId,
    this.blockInheritance = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'subcontractorId': subcontractorId,
      'targetType': targetType.name,
      'targetId': targetId,
      'blockInheritance': blockInheritance,
    };
  }

  factory SubcontractorLink.fromJson(Map<String, dynamic> json) {
    return SubcontractorLink(
      subcontractorId: json['subcontractorId'] as String? ?? '',
      targetType: _parseSubcontractorTargetType(
        json['targetType'] as String?,
      ),
      targetId: json['targetId'] as String? ?? '',
      blockInheritance: json['blockInheritance'] as bool? ?? false,
    );
  }
}

/// Pomieszczenie dodatkowe (techniczne, pomocnicze)
class AdditionalRoom {
  final String id;
  final String name;
  final String roomNumber;
  final int buildingIndex;
  final String? stairCaseName;
  final AdditionalRoomLevelType levelType;
  final int floorNumber;
  final Set<AdditionalRoomInstallation> installations;
  final Set<ElectricalSystemType> specificSystems;
  final Set<AdditionalRoomTask> tasks;
  final Set<AdditionalRoomTask> completedTasks;

  AdditionalRoom({
    required this.id,
    required this.name,
    this.roomNumber = '',
    required this.buildingIndex,
    required this.levelType,
    required this.floorNumber,
    this.stairCaseName,
    this.installations = const {},
    this.specificSystems = const {},
    this.tasks = const {},
    this.completedTasks = const {},
  });

  AdditionalRoom copyWith({
    String? id,
    String? name,
    String? roomNumber,
    int? buildingIndex,
    String? stairCaseName,
    AdditionalRoomLevelType? levelType,
    int? floorNumber,
    Set<AdditionalRoomInstallation>? installations,
    Set<ElectricalSystemType>? specificSystems,
    Set<AdditionalRoomTask>? tasks,
    Set<AdditionalRoomTask>? completedTasks,
  }) {
    return AdditionalRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      roomNumber: roomNumber ?? this.roomNumber,
      buildingIndex: buildingIndex ?? this.buildingIndex,
      stairCaseName: stairCaseName ?? this.stairCaseName,
      levelType: levelType ?? this.levelType,
      floorNumber: floorNumber ?? this.floorNumber,
      installations: installations ?? this.installations,
      specificSystems: specificSystems ?? this.specificSystems,
      tasks: tasks ?? this.tasks,
      completedTasks: completedTasks ?? this.completedTasks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roomNumber': roomNumber,
      'buildingIndex': buildingIndex,
      'stairCaseName': stairCaseName,
      'levelType': levelType.name,
      'floorNumber': floorNumber,
      'installations': installations.map((i) => i.name).toList(),
      'specificSystems': specificSystems.map((s) => s.name).toList(),
      'tasks': tasks.map((t) => t.name).toList(),
      'completedTasks': completedTasks.map((t) => t.name).toList(),
    };
  }

  factory AdditionalRoom.fromJson(Map<String, dynamic> json) {
    return AdditionalRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      roomNumber: json['roomNumber'] as String? ?? '',
      buildingIndex: json['buildingIndex'] as int,
      stairCaseName: json['stairCaseName'] as String?,
      levelType: AdditionalRoomLevelType.values.firstWhere(
        (e) => e.name == json['levelType'],
      ),
      floorNumber: json['floorNumber'] as int,
      installations: (json['installations'] as List?)
              ?.map((i) => AdditionalRoomInstallation.values
                  .firstWhere((e) => e.name == i))
              .toSet() ??
          {},
      specificSystems: (json['specificSystems'] as List?)
          ?.map((s) => _parseElectricalSystemType(s as String?))
          .toSet() ??
        _legacyAdditionalRoomSystemsFromInstallations(
        (json['installations'] as List?)
            ?.map((i) => i as String)
            .toSet() ??
          const <String>{},
        ),
      tasks: (json['tasks'] as List?)
              ?.map((t) =>
                  AdditionalRoomTask.values.firstWhere((e) => e.name == t))
              .toSet() ??
          {},
      completedTasks: (json['completedTasks'] as List?)
              ?.map((t) =>
                  AdditionalRoomTask.values.firstWhere((e) => e.name == t))
              .toSet() ??
          {},
    );
  }
}

Set<ElectricalSystemType> _legacyAdditionalRoomSystemsFromInstallations(
  Set<String> installationNames,
) {
  final systems = <ElectricalSystemType>{};

  for (final name in installationNames) {
    switch (name) {
      case 'zasilanie':
        systems.add(ElectricalSystemType.zasilanie);
        break;
      case 'oswietlenie':
        systems.add(ElectricalSystemType.oswietlenie);
        break;
      case 'teletechnika':
        systems.add(ElectricalSystemType.internet);
        break;
      case 'cctv':
        systems.add(ElectricalSystemType.cctv);
        break;
      case 'ppoz':
      case 'ssp':
        systems.add(ElectricalSystemType.ppoz);
        break;
      case 'wentylacja':
        systems.add(ElectricalSystemType.wentylacja);
        break;
      case 'klimatyzacja':
        systems.add(ElectricalSystemType.klimatyzacja);
        break;
      case 'oddymianie':
        systems.add(ElectricalSystemType.oddymianieKlatek);
        break;
      default:
        break;
    }
  }

  return systems;
}

/// Etap budowy z datami
class ProjectPhase {
  final BuildingStage stage;
  final DateTime startDate;
  final DateTime endDate;
  final Duration duration;
  final String description;
  final List<String> criticalTasks; // Zadania krytyczne dla tej fazy

  ProjectPhase({
    required this.stage,
    required this.startDate,
    required this.endDate,
    required this.description,
    this.criticalTasks = const [],
  }) : duration = endDate.difference(startDate);

  // Czy jest w trakcie?
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  // Postęp (0.0 - 1.0)
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;
    final elapsed = now.difference(startDate);
    return elapsed.inHours / duration.inHours;
  }

  // Nazwa fazy
  String get name => description;

  // Numer tygodnia (obliczany na podstawie dat)
  int get weekNumber => (duration.inDays / 7).ceil();

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'stage': stage.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'description': description,
      'criticalTasks': criticalTasks,
    };
  }

  factory ProjectPhase.fromJson(Map<String, dynamic> json) {
    return ProjectPhase(
      stage: BuildingStage.values.firstWhere(
        (e) => e.name == json['stage'],
      ),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      description: json['description'] as String,
      criticalTasks: (json['criticalTasks'] as List?)?.cast<String>() ?? [],
    );
  }
}

/// Zadanie w checklist'cie
class ChecklistTask {
  final String id;
  final String title;
  final String description;
  final ElectricalSystemType system;
  final BuildingStage stage; // W której fazie to powinno być zrobione?
  final int daysBeforeStageEnd; // Ile dni przed końcem fazy (dla alertów)

  // Status i daty
  TaskStatus status;
  DateTime? completedDate;
  DateTime? dueDate;

  // Zależności
  final List<String> dependsOnTaskIds; // ID zadań, które muszą być najpierw

  // Notatki
  String notes;
  final List<String> attachmentPaths; // Zdjęcia, dokumenty

  // Powiązanie z jednostkami (mieszkania A1-A250)
  final List<String>? unitIds; // null = globalne dla budynku

  ChecklistTask({
    required this.id,
    required this.title,
    required this.description,
    required this.system,
    required this.stage,
    required this.daysBeforeStageEnd,
    this.status = TaskStatus.pending,
    this.completedDate,
    this.dueDate,
    List<String>? dependsOnTaskIds,
    this.notes = '',
    List<String>? attachmentPaths,
    this.unitIds,
  })  : dependsOnTaskIds = List<String>.from(dependsOnTaskIds ?? const []),
        attachmentPaths = List<String>.from(attachmentPaths ?? const []);

  // Czy zadanie jest dostępne do wykonania?
  bool get isAvailable {
    // Dostępne gdy wszystkie zależności są ukończone
    return dependsOnTaskIds.isEmpty;
  }

  // Czy jest opóźnione?
  bool get isDelayed {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.completed;
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'system': system.name,
      'stage': stage.name,
      'daysBeforeStageEnd': daysBeforeStageEnd,
      'status': status.name,
      'completedDate': completedDate?.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'dependsOnTaskIds': dependsOnTaskIds,
      'notes': notes,
      'attachmentPaths': attachmentPaths,
      'unitIds': unitIds,
    };
  }

  factory ChecklistTask.fromJson(Map<String, dynamic> json) {
    return ChecklistTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      system: _parseElectricalSystemType(json['system'] as String?),
      stage: BuildingStage.values.firstWhere(
        (e) => e.name == json['stage'],
      ),
      daysBeforeStageEnd: json['daysBeforeStageEnd'] as int,
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending'),
      ),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dependsOnTaskIds: List<String>.from(
        (json['dependsOnTaskIds'] as List?)?.cast<String>() ?? const [],
      ),
      notes: json['notes'] as String? ?? '',
      attachmentPaths: List<String>.from(
        (json['attachmentPaths'] as List?)?.cast<String>() ?? const [],
      ),
      unitIds: (json['unitIds'] as List?)?.cast<String>(),
    );
  }
}

/// Alert/sugestia dla użytkownika
class ProjectAlert {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? relatedTaskId;
  final String actionSuggestion; // Co powinien zrobić użytkownik?

  bool isRead;
  DateTime? readAt;

  ProjectAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.actionSuggestion,
    this.relatedTaskId,
    DateTime? createdAt,
    this.isRead = false,
    this.readAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity.name,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'relatedTaskId': relatedTaskId,
      'actionSuggestion': actionSuggestion,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory ProjectAlert.fromJson(Map<String, dynamic> json) {
    return ProjectAlert(
      id: json['id'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      title: json['title'] as String,
      message: json['message'] as String,
      actionSuggestion: json['actionSuggestion'] as String,
      relatedTaskId: json['relatedTaskId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }
}

class RecurringProjectAlert {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String actionSuggestion;
  final int intervalDays;
  final DateTime nextOccurrenceAt;
  final int remindBeforeMinutes;
  final int? preferredWeekday;
  final bool isActive;

  const RecurringProjectAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    required this.actionSuggestion,
    required this.intervalDays,
    required this.nextOccurrenceAt,
    this.remindBeforeMinutes = 0,
    this.preferredWeekday,
    this.isActive = true,
  });

  DateTime get nextTriggerAt =>
      nextOccurrenceAt.subtract(Duration(minutes: remindBeforeMinutes));

  RecurringProjectAlert copyWith({
    String? id,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? actionSuggestion,
    int? intervalDays,
    DateTime? nextOccurrenceAt,
    int? remindBeforeMinutes,
    int? preferredWeekday,
    bool? isActive,
  }) {
    return RecurringProjectAlert(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      actionSuggestion: actionSuggestion ?? this.actionSuggestion,
      intervalDays: intervalDays ?? this.intervalDays,
      nextOccurrenceAt: nextOccurrenceAt ?? this.nextOccurrenceAt,
      remindBeforeMinutes: remindBeforeMinutes ?? this.remindBeforeMinutes,
      preferredWeekday: preferredWeekday ?? this.preferredWeekday,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity.name,
      'title': title,
      'message': message,
      'actionSuggestion': actionSuggestion,
      'intervalDays': intervalDays,
      'nextOccurrenceAt': nextOccurrenceAt.toIso8601String(),
      'nextTriggerAt': nextTriggerAt.toIso8601String(),
      'remindBeforeMinutes': remindBeforeMinutes,
      'preferredWeekday': preferredWeekday,
      'isActive': isActive,
    };
  }

  factory RecurringProjectAlert.fromJson(Map<String, dynamic> json) {
    final remindBeforeMinutes = (json['remindBeforeMinutes'] as int?) ?? 0;
    final nextOccurrenceRaw = json['nextOccurrenceAt'] as String?;
    final nextTriggerRaw = json['nextTriggerAt'] as String?;
    final fallbackOccurrence = nextTriggerRaw != null
        ? DateTime.parse(nextTriggerRaw)
            .add(Duration(minutes: remindBeforeMinutes))
        : DateTime.now();

    return RecurringProjectAlert(
      id: json['id'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == (json['severity'] as String? ?? 'warning'),
      ),
      title: json['title'] as String,
      message: json['message'] as String? ?? '',
      actionSuggestion: json['actionSuggestion'] as String? ?? '',
      intervalDays: (json['intervalDays'] as int?) ?? 7,
      nextOccurrenceAt: nextOccurrenceRaw != null
          ? DateTime.parse(nextOccurrenceRaw)
          : fallbackOccurrence,
      remindBeforeMinutes: remindBeforeMinutes,
      preferredWeekday: (json['preferredWeekday'] as int?)?.clamp(1, 7),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Jednostka (mieszkanie, biuro, itp.)
class ProjectUnit {
  final String unitId; // A1, A2, ... B301
  final String constructionUnitId;
  final String targetUnitId;
  final String unitName; // "Mieszkanie A1", "Biuro 2.5"
  final int floor;
  final String stairCase; // Klatka schodowa
  final bool isAlternateUnit; // Lokal zamienny

  // Instalacje specyficzne dla jednostki
  final Set<ElectricalSystemType> specificSystems;

  // Status prac
  final Map<String, TaskStatus> taskStatuses; // taskId -> status
  final Map<String, DateTime?> taskCompletionDates;

  // Dokumentacja
  final List<String> photoPaths;
  final String defectsNotes;

  ProjectUnit({
    required this.unitId,
    String? constructionUnitId,
    String? targetUnitId,
    required this.unitName,
    required this.floor,
    required this.stairCase,
    this.isAlternateUnit = false,
    this.specificSystems = const {},
    this.taskStatuses = const {},
    this.taskCompletionDates = const {},
    this.photoPaths = const [],
    this.defectsNotes = '',
  })  : constructionUnitId = constructionUnitId ?? unitId,
        targetUnitId = targetUnitId ?? constructionUnitId ?? unitId;

  String getDisplayId(UnitNamingScheme scheme) {
    return scheme == UnitNamingScheme.target
        ? targetUnitId
        : constructionUnitId;
  }

  bool matchesSearchQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return unitName.toLowerCase().contains(normalized) ||
        unitId.toLowerCase().contains(normalized) ||
        constructionUnitId.toLowerCase().contains(normalized) ||
        targetUnitId.toLowerCase().contains(normalized);
  }

  // Procent ukończenia dla tej jednostki
  double get completionPercentage {
    if (taskStatuses.isEmpty) return 0.0;
    final completed = taskStatuses.values
        .where((status) => status == TaskStatus.completed)
        .length;
    return (completed / taskStatuses.length) * 100;
  }

  ProjectUnit copyWith({
    String? unitId,
    String? constructionUnitId,
    String? targetUnitId,
    String? unitName,
    int? floor,
    String? stairCase,
    bool? isAlternateUnit,
    Set<ElectricalSystemType>? specificSystems,
    Map<String, TaskStatus>? taskStatuses,
    Map<String, DateTime?>? taskCompletionDates,
    List<String>? photoPaths,
    String? defectsNotes,
  }) {
    return ProjectUnit(
      unitId: unitId ?? this.unitId,
      constructionUnitId: constructionUnitId ?? this.constructionUnitId,
      targetUnitId: targetUnitId ?? this.targetUnitId,
      unitName: unitName ?? this.unitName,
      floor: floor ?? this.floor,
      stairCase: stairCase ?? this.stairCase,
      isAlternateUnit: isAlternateUnit ?? this.isAlternateUnit,
      specificSystems: specificSystems ?? this.specificSystems,
      taskStatuses: taskStatuses ?? this.taskStatuses,
      taskCompletionDates: taskCompletionDates ?? this.taskCompletionDates,
      photoPaths: photoPaths ?? this.photoPaths,
      defectsNotes: defectsNotes ?? this.defectsNotes,
    );
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'unitId': unitId,
      'constructionUnitId': constructionUnitId,
      'targetUnitId': targetUnitId,
      'unitName': unitName,
      'floor': floor,
      'stairCase': stairCase,
      'isAlternateUnit': isAlternateUnit,
      'specificSystems': specificSystems.map((s) => s.name).toList(),
      'taskStatuses': taskStatuses.map((k, v) => MapEntry(k, v.name)),
      'taskCompletionDates': taskCompletionDates.map(
        (k, v) => MapEntry(k, v?.toIso8601String()),
      ),
      'photoPaths': photoPaths,
      'defectsNotes': defectsNotes,
    };
  }

  factory ProjectUnit.fromJson(Map<String, dynamic> json) {
    return ProjectUnit(
      unitId: json['unitId'] as String,
      constructionUnitId:
          json['constructionUnitId'] as String? ?? json['unitId'] as String,
      targetUnitId: json['targetUnitId'] as String? ??
          json['constructionUnitId'] as String? ??
          json['unitId'] as String,
      unitName: json['unitName'] as String,
      floor: json['floor'] as int,
      stairCase: json['stairCase'] as String,
      isAlternateUnit: json['isAlternateUnit'] as bool? ?? false,
      specificSystems: (json['specificSystems'] as List?)
              ?.map((s) => _parseElectricalSystemType(s as String?))
              .toSet() ??
          {},
      taskStatuses: (json['taskStatuses'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              TaskStatus.values.firstWhere((e) => e.name == v),
            ),
          ) ??
          {},
      taskCompletionDates:
          (json['taskCompletionDates'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                  k,
                  v != null ? DateTime.parse(v as String) : null,
                ),
              ) ??
              {},
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
      defectsNotes: json['defectsNotes'] as String? ?? '',
    );
  }
}

enum ProjectAreaType {
  room,
  stairCase,
  elevator,
  garage,
  roof,
  externalArea,
}

ProjectAreaType _parseProjectAreaType(String? value) {
  switch (value) {
    case 'room':
      return ProjectAreaType.room;
    case 'stairCase':
      return ProjectAreaType.stairCase;
    case 'elevator':
      return ProjectAreaType.elevator;
    case 'garage':
      return ProjectAreaType.garage;
    case 'roof':
      return ProjectAreaType.roof;
    case 'externalArea':
    default:
      return ProjectAreaType.externalArea;
  }
}

class ProjectAreaProgress {
  final String areaId;
  final ProjectAreaType areaType;
  final Map<String, TaskStatus> taskStatuses;
  final Map<String, DateTime?> taskCompletionDates;
  final List<String> photoPaths;
  final String notes;

  const ProjectAreaProgress({
    required this.areaId,
    required this.areaType,
    this.taskStatuses = const {},
    this.taskCompletionDates = const {},
    this.photoPaths = const [],
    this.notes = '',
  });

  double get completionPercentage {
    if (taskStatuses.isEmpty) return 0.0;
    final completed = taskStatuses.values
        .where((status) => status == TaskStatus.completed)
        .length;
    return (completed / taskStatuses.length) * 100;
  }

  ProjectAreaProgress copyWith({
    String? areaId,
    ProjectAreaType? areaType,
    Map<String, TaskStatus>? taskStatuses,
    Map<String, DateTime?>? taskCompletionDates,
    List<String>? photoPaths,
    String? notes,
  }) {
    return ProjectAreaProgress(
      areaId: areaId ?? this.areaId,
      areaType: areaType ?? this.areaType,
      taskStatuses: taskStatuses ?? this.taskStatuses,
      taskCompletionDates: taskCompletionDates ?? this.taskCompletionDates,
      photoPaths: photoPaths ?? this.photoPaths,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaId': areaId,
      'areaType': areaType.name,
      'taskStatuses': taskStatuses.map((k, v) => MapEntry(k, v.name)),
      'taskCompletionDates': taskCompletionDates.map(
        (k, v) => MapEntry(k, v?.toIso8601String()),
      ),
      'photoPaths': photoPaths,
      'notes': notes,
    };
  }

  factory ProjectAreaProgress.fromJson(Map<String, dynamic> json) {
    return ProjectAreaProgress(
      areaId: json['areaId'] as String,
      areaType: _parseProjectAreaType(json['areaType'] as String?),
      taskStatuses: (json['taskStatuses'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(
              k,
              TaskStatus.values.firstWhere((e) => e.name == v),
            ),
          ) ??
          {},
      taskCompletionDates:
          (json['taskCompletionDates'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(
                  k,
                  v != null ? DateTime.parse(v as String) : null,
                ),
              ) ??
              {},
      photoPaths: (json['photoPaths'] as List?)?.cast<String>() ?? [],
      notes: json['notes'] as String? ?? '',
    );
  }
}

/// Pełny projekt budowy
class ConstructionProject {
  final String projectId;
  final BuildingConfiguration config;
  final List<ProjectPhase> phases;
  final List<ChecklistTask> allTasks;
  final List<ProjectAlert> alerts;
  final List<RecurringProjectAlert> recurringAlerts;
  final List<ProjectUnit> units; // Dla projektów wielolokalowych
  final List<ProjectAreaProgress> areaProgress;

  // Metadata
  final DateTime createdAt;
  DateTime? lastModifiedAt;

  ConstructionProject({
    required this.projectId,
    required this.config,
    required this.phases,
    required this.allTasks,
    this.alerts = const [],
    this.recurringAlerts = const [],
    this.units = const [],
    this.areaProgress = const [],
    DateTime? createdAt,
    this.lastModifiedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Oblicz ogólny postęp projektu
  double get overallProgress {
    if (allTasks.isEmpty) return 0.0;
    final completed =
        allTasks.where((task) => task.status == TaskStatus.completed).length;
    return (completed / allTasks.length) * 100;
  }

  // Aktywna faza
  ProjectPhase? get activePhase {
    try {
      return phases.firstWhere((phase) => phase.isActive);
    } catch (e) {
      return null;
    }
  }

  // Liczba alertów do uwagi
  int get unreadAlertCount {
    return alerts.where((a) => !a.isRead).length;
  }

  // Liczba zadań opóźnionych
  int get delayedTaskCount {
    return allTasks.where((t) => t.isDelayed).length;
  }

  // Postęp projektu (0.0 - 1.0)
  double getProgress() {
    if (allTasks.isEmpty) return 0.0;
    final completed =
        allTasks.where((task) => task.status == TaskStatus.completed).length;
    return completed / allTasks.length;
  }

  // Szybki dostęp do nazwy projektu
  String get name => config.projectName;

  // Szybki dostęp do adresu projektu
  String get address => config.address;

  String displayUnitId(ProjectUnit unit) {
    return unit.getDisplayId(config.defaultUnitNamingScheme);
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'config': config.toJson(),
      'phases': phases.map((p) => p.toJson()).toList(),
      'allTasks': allTasks.map((t) => t.toJson()).toList(),
      'alerts': alerts.map((a) => a.toJson()).toList(),
      'recurringAlerts': recurringAlerts.map((a) => a.toJson()).toList(),
      'units': units.map((u) => u.toJson()).toList(),
      'areaProgress': areaProgress.map((a) => a.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModifiedAt': lastModifiedAt?.toIso8601String(),
    };
  }

  factory ConstructionProject.fromJson(Map<String, dynamic> json) {
    return ConstructionProject(
      projectId: json['projectId'] as String,
      config: BuildingConfiguration.fromJson(
          json['config'] as Map<String, dynamic>),
      phases: (json['phases'] as List)
          .map((p) => ProjectPhase.fromJson(p as Map<String, dynamic>))
          .toList(),
      allTasks: (json['allTasks'] as List)
          .map((t) => ChecklistTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      alerts: (json['alerts'] as List?)
              ?.map(
                (a) => ProjectAlert.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
      recurringAlerts: (json['recurringAlerts'] as List?)
              ?.map(
                (a) =>
                    RecurringProjectAlert.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
      units: (json['units'] as List?)
              ?.map(
                (u) => ProjectUnit.fromJson(u as Map<String, dynamic>),
              )
              .toList() ??
          [],
      areaProgress: (json['areaProgress'] as List?)
              ?.map(
                (a) => ProjectAreaProgress.fromJson(a as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// KALKULATOR HARMONOGRAMU I WARUNKI KLIMATYCZNE
// ═══════════════════════════════════════════════════════════════════════════

/// Warunki klimatyczne dla Polski - wpływają na prace na zewnątrz
class PolishClimateAnalyzer {
  /// Czy dany miesiąc jest sprzyjający dla prac na zewnątrz?
  /// - maj-wrzesień: idealne (100% wydajności)
  /// - kwiecień, październik: dobre (80% wydajności)
  /// - marzec, listopad: trudne (50% wydajności)
  /// - grudzień-luty: bardzo trudne do niemożliwe (0-20% wydajności)
  static double getOutdoorWorkEfficiency(DateTime date) {
    final month = date.month;

    switch (month) {
      case 5:
      case 6:
      case 7:
      case 8:
      case 9: // maj-wrzesień
        return 1.0; // 100% wydajności
      case 4:
      case 10: // kwiecień, październik
        return 0.8; // 80% wydajności
      case 3:
      case 11: // marzec, listopad
        return 0.5; // 50% wydajności
      default: // grudzień, styczeń, luty
        return 0.1; // 10% wydajności - prace możliwe tylko w warunkach osłoniętych
    }
  }

  /// Oblicz rzeczywisty czas na prace na zewnątrz uwzględniając warunki
  static int calculateOutdoorWorkDays(
    DateTime startDate,
    int estimatedDays,
  ) {
    int actualDays = 0;
    DateTime currentDate = startDate;
    int targetWorkDays = estimatedDays;

    while (actualDays < targetWorkDays) {
      double efficiency = getOutdoorWorkEfficiency(currentDate);
      if (efficiency > 0.3) {
        // Jeśli możliwe prace na zewnątrz
        actualDays += (efficiency * 1.0).toInt(); // Każdy dzień to mniej pracy
      }
      currentDate = currentDate.add(const Duration(days: 1));
      if (actualDays > estimatedDays * 3) break; // Prevent infinite loop
    }

    return (currentDate.difference(startDate).inDays).toInt();
  }
}

/// Ocena złożoności instalacji na podstawie wybranych systemów
class ComplexityCalculator {
  static const Map<ElectricalSystemType, double> systemComplexityWeights = {
    ElectricalSystemType.oswietlenie: 0.5,
    ElectricalSystemType.zasilanie: 0.5,
    ElectricalSystemType.oswietlenieAwaryjneEwakuacyjne: 1.0,
    ElectricalSystemType.gniazdaDedykowane: 0.8,
    ElectricalSystemType.trasyKablowe: 0.9,
    ElectricalSystemType.wlz: 1.1,
    ElectricalSystemType.rozdzielniceRgRnnRsn: 1.4,
    ElectricalSystemType.uziemieniePolaczeniaWyrownawcze: 1.0,
    ElectricalSystemType.klimatyzacja: 1.5,
    ElectricalSystemType.wentylacja: 1.3,
    ElectricalSystemType.automatykaHvac: 1.7,
    ElectricalSystemType.windaAscensor: 2.0,
    ElectricalSystemType.domofonowa: 1.0,
    ElectricalSystemType.telewizja: 0.8,
    ElectricalSystemType.internet: 0.7,
    ElectricalSystemType.lan: 0.9,
    ElectricalSystemType.swiatlowod: 1.2,
    ElectricalSystemType.wifi: 0.8,
    ElectricalSystemType.voip: 0.9,
    ElectricalSystemType.dataRoom: 1.3,
    ElectricalSystemType.av: 1.1,
    ElectricalSystemType.digitalSignage: 1.0,
    ElectricalSystemType.odgromowa: 1.2,
    ElectricalSystemType.panelePV: 2.0,
    ElectricalSystemType.magazynEnergii: 2.1,
    ElectricalSystemType.ladownarki: 1.5,
    ElectricalSystemType.agregat: 1.5,
    ElectricalSystemType.ups: 1.6,
    ElectricalSystemType.szr: 1.4,
    ElectricalSystemType.dualFeedSn: 2.3,
    ElectricalSystemType.ukladyPomiarowe: 0.9,
    ElectricalSystemType.podlicznikiEnergii: 0.8,
    ElectricalSystemType.analizatorySieci: 1.0,
    ElectricalSystemType.ems: 1.8,
    ElectricalSystemType.ppoz: 1.5,
    ElectricalSystemType.dso: 1.0,
    ElectricalSystemType.kd: 1.0,
    ElectricalSystemType.czujnikiRuchu: 0.8,
    ElectricalSystemType.podgrzewanePodjazdy: 1.0,
    ElectricalSystemType.ogrzewanieRur: 0.8,
    ElectricalSystemType.floorboxy: 0.9,
    ElectricalSystemType.zasilanieStanowiskPracy: 0.9,
    ElectricalSystemType.rezerwacjaSal: 1.1,
    ElectricalSystemType.cctv: 1.0,
    ElectricalSystemType.sswim: 1.2,
    ElectricalSystemType.gaszeniGazem: 2.0,
    ElectricalSystemType.ewakuacyjne: 0.8,
    ElectricalSystemType.smartHome: 2.0,
    ElectricalSystemType.oddymianieKlatek: 1.5,
    ElectricalSystemType.bms: 2.5,
    ElectricalSystemType.integracjaSystemow: 2.0,
    ElectricalSystemType.psimSms: 2.1,
    ElectricalSystemType.wykrywaniWyciekow: 0.8,
    ElectricalSystemType.itp: 1.0,
  };

  /// Oblicz wskaźnik złożoności (0.5 - 3.0)
  /// Gdzie 1.0 to średnia złożoność
  static double calculateComplexityFactor(Set<ElectricalSystemType> systems) {
    if (systems.isEmpty) return 0.5; // Bardzo proste - tylko podstawowe

    double totalWeight = 0;
    for (final system in systems) {
      totalWeight += systemComplexityWeights[system] ?? 1.0;
    }

    double averageWeight = totalWeight / systems.length;
    // Normalizuj do zakresu 0.5 - 3.0
    return (0.5 + (averageWeight * 0.5)).clamp(0.5, 3.0);
  }
}

/// Główny kalkulator harmonogramu budowy
class ScheduleCalculator {
  /// Oblicz harmonogram etapów na podstawie całkowitego czasu budowy
  /// i parametrów budynku
  static Map<BuildingStage, int> calculateSchedule(
    BuildingConfiguration config,
  ) {
    // NOWE: Użyj bazy danych harmonogramu opartą na dokumencie
    // o etapach budowy budynków mieszkalnych i biurowych
    final baseProportions = config.buildingType == BuildingType.mieszkalny
        ? _getResidentialProportions()
        : _getCommercialProportions();

    // Mnożnik na podstawie złożoności systemów
    final complexityFactor = ComplexityCalculator.calculateComplexityFactor(
      config.selectedSystems,
    );

    // Mnożnik na podstawie liczby pięter
    final floorFactor = 1.0 + (config.totalLevels - 3) * 0.1;

    // Mnożnik na podstawie liczby klatek schodowych
    final stairCaseFactor = 1.0 + (config.estimatedStairCases - 1) * 0.05;

    // Całkowity mnożnik
    double totalMultiplier = complexityFactor * floorFactor * stairCaseFactor;

    // Normalizuj mnożnik aby harmonogram ukończył się w totalBuildingWeeks
    final baseTotal = baseProportions.values.fold<int>(0, (sum, v) => sum + v);
    final calculatedTotal = (baseTotal * totalMultiplier).toInt();
    final normalizedMultiplier = config.totalBuildingWeeks / calculatedTotal;

    // Zastosuj mnożnik do każdego etapu
    final schedule = <BuildingStage, int>{};
    for (final entry in baseProportions.entries) {
      int weeks = ((entry.value * normalizedMultiplier).round()).clamp(1, 52);
      schedule[entry.key] = weeks;
    }

    return schedule;
  }

  /// Bazowe proporcje dla budynków mieszkalnych
  /// Oparte na elemencie z dokumentu: "Budynek 5–8 kondygnacyjny"
  /// Czas: 18–24 miesiące (78-104 tygodnie)
  static Map<BuildingStage, int> _getResidentialProportions() {
    return {
      BuildingStage.przygotowanie: 2, // 10-15% (2-4 miesiące)
      BuildingStage.fundamenty: 3, // 15-20% (3-5 miesięcy)
      BuildingStage.konstrukcja:
          7, // 25-35% (5-8 miesięcy) - RDZEŃ HARMONOGRAMU
      BuildingStage.przegrody: 4, // 15-20% (3-5 miesięcy)
      BuildingStage.tynki: 5, // 15-20% (3-4 miesiące)
      BuildingStage.posadzki: 2, // Część nakładana z innymi etapami
      BuildingStage.osprzet: 3, // 25-30% nakładane na inne etapy
      BuildingStage.malowanie: 4, // 15-20%
      BuildingStage.finalizacja: 2, // Ostatnia faza
      BuildingStage.oddawanie: 1, // 5-8% (1-2 miesiące)
    };
  }

  /// Bazowe proporcje dla budynków biurowych
  /// Zmodyfikowane ze względu na większe powierzchnie i większe obciążenia
  static Map<BuildingStage, int> _getCommercialProportions() {
    return {
      BuildingStage.przygotowanie: 2, // 5%
      BuildingStage.fundamenty: 3, // 7%
      BuildingStage.konstrukcja: 8, // 19%
      BuildingStage.przegrody: 5, // 12%
      BuildingStage.tynki: 6, // 14%
      BuildingStage.posadzki: 2, // 5%
      BuildingStage.osprzet: 4, // 9%
      BuildingStage.malowanie: 5, // 12%
      BuildingStage.finalizacja: 2, // 5%
      BuildingStage.oddawanie: 2, // 5%
    };
  }

  /// Wygeneruj fazy projektu z datami - NOWE: użyj ScheduleDataIntegration
  static List<ProjectPhase> generatePhases(
    BuildingConfiguration config,
    Map<BuildingStage, int> schedule,
  ) {
    // NOWE: Użyj integracji, która dynamicznie oblicza fazy na podstawie
    // liczby pięter, garaży i typu budynku
    return ScheduleDataIntegration.generateSchedulePhases(config);
  }
}
