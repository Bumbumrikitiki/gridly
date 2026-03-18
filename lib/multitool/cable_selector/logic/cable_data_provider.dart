import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:gridly/multitool/cable_selector/models/cable_data.dart';

class CableDataProvider {
  static final Map<CableMaterial, Map<CableType, Map<double, CableData>>>
      _data = _buildData();
  static Map<CableMaterial, Map<CableType, Map<double, CableData>>>
      _runtimeData = _cloneDataMap(_data);
  static Map<CableMaterial, Map<CableType, List<CableData>>> _runtimeVariants =
      _buildVariantData(_runtimeData);
  static bool _localDatabaseInitialized = false;
  static int _localImportedRecords = 0;
  static const List<String> _localDatabaseAssets = [
    'assets/data/cables/local_cable_database.json',
    'assets/data/cables/local_cable_database_verified.json',
  ];

  static Future<void> initializeLocalDatabase() async {
    if (_localDatabaseInitialized) {
      return;
    }

    _runtimeData = _cloneDataMap(_data);
    _runtimeVariants = _buildVariantData(_runtimeData);
    var imported = 0;

    for (final assetPath in _localDatabaseAssets) {
      try {
        final jsonRaw = await rootBundle.loadString(assetPath);
        final decoded = json.decode(jsonRaw);

        if (decoded is List) {
          for (final item in decoded) {
            if (item is! Map<String, dynamic>) {
              continue;
            }

            final record = _parseLocalCableRecord(item);
            if (record == null) {
              continue;
            }

            _upsertCableData(record);
            imported += 1;
          }
        }
      } catch (_) {
        // Preserve built-in data when one of assets is missing or malformed.
      }
    }

    _localImportedRecords = imported;
    _localDatabaseInitialized = true;
  }

  static Map<String, int> getDatabaseStats() {
    var totalRecords = 0;
    for (final materialEntry in _runtimeVariants.values) {
      for (final typeEntry in materialEntry.values) {
        totalRecords += typeEntry.length;
      }
    }

    return {
      'totalRecords': totalRecords,
      'localImportedRecords': _localImportedRecords,
      'materials': _runtimeVariants.length,
    };
  }

  static Map<CableMaterial, Map<CableType, Map<double, CableData>>>
      _cloneDataMap(
    Map<CableMaterial, Map<CableType, Map<double, CableData>>> source,
  ) {
    final clone = <CableMaterial, Map<CableType, Map<double, CableData>>>{};
    for (final materialEntry in source.entries) {
      final typeMap = <CableType, Map<double, CableData>>{};
      for (final typeEntry in materialEntry.value.entries) {
        final normalizedEntry = <double, CableData>{};
        for (final cableEntry in typeEntry.value.entries) {
          normalizedEntry[cableEntry.key] =
              _normalizeCableApplication(cableEntry.value);
        }
        typeMap[typeEntry.key] = normalizedEntry;
      }
      clone[materialEntry.key] = typeMap;
    }
    return clone;
  }

  static Map<CableMaterial, Map<CableType, List<CableData>>> _buildVariantData(
    Map<CableMaterial, Map<CableType, Map<double, CableData>>> source,
  ) {
    final variants = <CableMaterial, Map<CableType, List<CableData>>>{};
    for (final materialEntry in source.entries) {
      final typeMap = <CableType, List<CableData>>{};
      for (final typeEntry in materialEntry.value.entries) {
        typeMap[typeEntry.key] = typeEntry.value.values.toList();
      }
      variants[materialEntry.key] = typeMap;
    }
    return variants;
  }

  static String _cableCompositeKey(CableData cable) {
    return [
      cable.crossSection,
      cable.wireConfiguration.name,
      cable.outerDiameter,
      cable.maxVoltage,
      cable.sourceType ?? '',
      cable.sourceSize ?? '',
      cable.sourceDiameter ?? '',
      cable.manufacturer ?? '',
      cable.cpr ?? '',
      cable.insulation ?? '',
      cable.halogenFree ?? '',
      cable.notes ?? '',
      cable.usage ?? '',
      cable.importedAt ?? '',
    ].join(':');
  }

  static void _upsertCableData(CableData cable) {
    final normalizedCable = _normalizeCableApplication(cable);
    final materialMap = _runtimeData.putIfAbsent(
      normalizedCable.material,
      () => <CableType, Map<double, CableData>>{},
    );
    final typeMap = materialMap.putIfAbsent(
      normalizedCable.type,
      () => <double, CableData>{},
    );
    typeMap[normalizedCable.crossSection] = normalizedCable;

    final variantMaterialMap = _runtimeVariants.putIfAbsent(
      normalizedCable.material,
      () => <CableType, List<CableData>>{},
    );
    final variants = variantMaterialMap.putIfAbsent(
      normalizedCable.type,
      () => <CableData>[],
    );
    final newKey = _cableCompositeKey(normalizedCable);
    final existingIndex = variants.indexWhere(
      (item) => _cableCompositeKey(item) == newKey,
    );
    if (existingIndex >= 0) {
      variants[existingIndex] = normalizedCable;
    } else {
      variants.add(normalizedCable);
    }
  }

  static CableData? _parseLocalCableRecord(Map<String, dynamic> jsonMap) {
    final material =
        _parseEnumByName(CableMaterial.values, jsonMap['material']);
    final parsedType = _parseEnumByName(CableType.values, jsonMap['type']);
    final coreType = _parseEnumByName(CoreType.values, jsonMap['coreType']);
    final application =
        _parseEnumByName(CableApplication.values, jsonMap['application']);
    final sourceCategory = _parseString(jsonMap['sourceCategory']);
    final sourceType = _parseString(jsonMap['sourceType']);
    var type = parsedType;
    var resolvedMaterial = material;

    if (type == CableType.hdgs && _isHdhpSource(sourceCategory, sourceType)) {
      type = CableType.hdhp;
    }

    if (type == CableType.n2xh && _isN2axsySource(sourceCategory, sourceType)) {
      type = CableType.na2xsy;
      resolvedMaterial = CableMaterial.al;
    }

    if (resolvedMaterial == null || type == null || coreType == null) {
      return null;
    }

    final resolvedApplication = _expectedApplicationForType(type);

    final crossSection = _parseNum(jsonMap['crossSection']);
    final outerDiameter = _parseNum(jsonMap['outerDiameter']);
    final maxVoltage = _parseString(jsonMap['maxVoltage']);
    final temperatureRange = _parseString(jsonMap['temperatureRange']);

    if (crossSection == null ||
        outerDiameter == null ||
        maxVoltage == null ||
        temperatureRange == null) {
      return null;
    }

    final wireConfiguration = _parseEnumByName(
          WireConfiguration.values,
          jsonMap['wireConfiguration'],
        ) ??
        WireConfiguration.single;

    final recommendedTubeStandard = _parseEnumByName(
          HeatShrinkStandard.values,
          jsonMap['recommendedTubeStandard'],
        ) ??
        HeatShrinkStandard.rck;

    var groupNumber = CableData.typeGroupNumber(type);
    final groupRaw = jsonMap['groupNumber'];
    if (groupRaw is int) {
      groupNumber = groupRaw;
    } else if (groupRaw is String) {
      final parsedGroup = int.tryParse(groupRaw.trim());
      if (parsedGroup != null) {
        groupNumber = parsedGroup;
      }
    }

    final resolvedMaxVoltage =
        type == CableType.xztkmxpwz ? '300V' : maxVoltage;

    final heatShrinkSleeve = _parseString(jsonMap['heatShrinkSleeve']) ??
        getRecommendedHeatShrink3to1(outerDiameter);
    final heatShrinkLabel = _parseString(jsonMap['heatShrinkLabel']) ??
        getRecommendedHeatShrink2to1(outerDiameter);

    return CableData(
      material: resolvedMaterial,
      type: type,
      crossSection: crossSection,
      coreType: coreType,
      outerDiameter: outerDiameter,
      heatShrinkSleeve: heatShrinkSleeve,
      heatShrinkLabel: heatShrinkLabel,
      application: resolvedApplication,
      maxVoltage: resolvedMaxVoltage,
      temperatureRange: temperatureRange,
      wireConfiguration: wireConfiguration,
      groupNumber: groupNumber,
      recommendedTubeStandard: recommendedTubeStandard,
      source: _parseString(jsonMap['source']),
      sourceCategory: sourceCategory,
      sourceType: sourceType,
      sourceSize: _parseString(jsonMap['sourceSize']),
      sourceDiameter: _parseString(jsonMap['sourceDiameter']),
      manufacturer: _parseString(jsonMap['manufacturer']),
      cpr: _parseString(jsonMap['cpr']),
      insulation: _parseString(jsonMap['insulation']),
      halogenFree: _parseString(jsonMap['halogenFree']),
      notes: _parseString(jsonMap['notes']),
      usage: _parseString(jsonMap['usage']),
      importedAt: _parseString(jsonMap['importedAt']),
    );
  }

  static CableData _normalizeCableApplication(CableData cable) {
    final expectedApplication = _expectedApplicationForType(cable.type);
    final expectedGroup = CableData.typeGroupNumber(cable.type);
    final expectedMaxVoltage =
        cable.type == CableType.xztkmxpwz ? '300V' : cable.maxVoltage;

    if (cable.application == expectedApplication &&
        cable.groupNumber == expectedGroup &&
        cable.maxVoltage == expectedMaxVoltage) {
      return cable;
    }

    return CableData(
      material: cable.material,
      type: cable.type,
      crossSection: cable.crossSection,
      coreType: cable.coreType,
      outerDiameter: cable.outerDiameter,
      heatShrinkSleeve: cable.heatShrinkSleeve,
      heatShrinkLabel: cable.heatShrinkLabel,
      application: expectedApplication,
      maxVoltage: expectedMaxVoltage,
      temperatureRange: cable.temperatureRange,
      wireConfiguration: cable.wireConfiguration,
      groupNumber: expectedGroup,
      recommendedTubeStandard: cable.recommendedTubeStandard,
      source: cable.source,
      sourceCategory: cable.sourceCategory,
      sourceType: cable.sourceType,
      sourceSize: cable.sourceSize,
      sourceDiameter: cable.sourceDiameter,
      manufacturer: cable.manufacturer,
      cpr: cable.cpr,
      insulation: cable.insulation,
      halogenFree: cable.halogenFree,
      notes: cable.notes,
      usage: cable.usage,
      importedAt: cable.importedAt,
    );
  }

  static CableApplication _expectedApplicationForType(CableType type) {
    switch (type) {
      case CableType.ydy:
      case CableType.ydyp:
      case CableType.omy:
      case CableType.hdhp:
      case CableType.yky:
      case CableType.yaky:
      case CableType.n2xh:
        return CableApplication.electrical;
      case CableType.hdgs:
      case CableType.hlgs:
      case CableType.nhxh:
      case CableType.htksh:
        return CableApplication.fireproof;
      case CableType.utp5e:
      case CableType.utp6:
      case CableType.futp6:
      case CableType.sftp7:
      case CableType.rg6:
      case CableType.rg11:
      case CableType.ytnksy:
      case CableType.xztkmxpwz:
        return CableApplication.telecom;
      case CableType.liyy:
      case CableType.liycyekaprn:
      case CableType.ysly:
      case CableType.bit500cy:
      case CableType.h07rnf:
        return CableApplication.control;
      case CableType.yhakxs:
      case CableType.xhakxs:
      case CableType.xruhakxs:
      case CableType.a2xsy:
      case CableType.na2xsy:
        return CableApplication.mediumVoltage;
    }
  }

  static T? _parseEnumByName<T extends Enum>(
    List<T> values,
    dynamic raw,
  ) {
    if (raw is! String) {
      return null;
    }

    final normalized = raw.trim().toLowerCase();
    for (final item in values) {
      if (item.name.toLowerCase() == normalized) {
        return item;
      }
    }
    return null;
  }

  static double? _parseNum(dynamic raw) {
    if (raw is num) {
      return raw.toDouble();
    }
    if (raw is String) {
      final normalized = raw.replaceAll(',', '.').trim();
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _parseString(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim();
    }
    return null;
  }

  static bool _isHdhpSource(String? sourceCategory, String? sourceType) {
    final category = sourceCategory?.toLowerCase() ?? '';
    final type = sourceType?.toLowerCase() ?? '';
    return category.contains('hdhp') || type.contains('hdhp');
  }

  static bool _isN2axsySource(String? sourceCategory, String? sourceType) {
    final category = sourceCategory?.toLowerCase() ?? '';
    final type = sourceType?.toLowerCase() ?? '';
    return category.contains('n2axsy') ||
        category.contains('na2xsy') ||
        type.contains('n2axsy') ||
        type.contains('na2xsy');
  }

  static Map<CableMaterial, Map<CableType, Map<double, CableData>>>
      _buildData() {
    final data = <CableMaterial, Map<CableType, Map<double, CableData>>>{
      CableMaterial.cu: _buildCopperCables(),
      CableMaterial.al: _buildAluminumCables(),
    };
    return data;
  }

  static Map<CableType, Map<double, CableData>> _buildCopperCables() {
    return {
      ..._buildYDY(),
      ..._buildYDYP(),
      ..._buildOMY(),
      ..._buildYKY(),
      ..._buildN2XH(),
      ..._buildHDGS(),
      ..._buildHLGS(),
      ..._buildNHXH(),
      ..._buildHTKSH(),
      ..._buildUTP5E(),
      ..._buildUTP6(),
      ..._buildFUTP6(),
      ..._buildSFTP7(),
      ..._buildRG6(),
      ..._buildRG11(),
      ..._buildYTNKSY(),
      ..._buildLIYY(),
      ..._buildLIYCYEK(),
      ..._buildYSLY(),
      ..._buildBIT500CY(),
      ..._buildH07RNF(),
      ..._buildYHAKXS(),
      ..._buildXHAKXS(),
      ..._buildXRUHAKXS(),
      ..._buildA2XSY(),
    };
  }

  static Map<CableType, Map<double, CableData>> _buildAluminumCables() {
    return {
      ..._buildYAKY(),
      ..._buildNA2XSY(),
    };
  }

  // YDY - Przewód instalacyjny miedziany
  static Map<CableType, Map<double, CableData>> _buildYDY() {
    return {
      CableType.ydy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.mediumVoltage,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 9.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.mediumVoltage,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        4.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 4.0,
          coreType: CoreType.re,
          outerDiameter: 11.0,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.mediumVoltage,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        6.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 6.0,
          coreType: CoreType.re,
          outerDiameter: 12.5,
          heatShrinkSleeve: '20/7',
          heatShrinkLabel: '10/3',
          application: CableApplication.mediumVoltage,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        10.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 10.0,
          coreType: CoreType.re,
          outerDiameter: 15.0,
          heatShrinkSleeve: '25/8',
          heatShrinkLabel: '12/4',
          application: CableApplication.mediumVoltage,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        16.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 16.0,
          coreType: CoreType.re,
          outerDiameter: 18.0,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        25.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ydy,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 22.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +70°C',
        ),
      }
    };
  }

  // YDYp - Przewód płaski
  static Map<CableType, Map<double, CableData>> _buildYDYP() {
    return {
      CableType.ydyp: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydyp,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 7.5,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '0.45/0.75 kV',
          temperatureRange: '-30°C do +70°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ydyp,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 8.5,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.electrical,
          maxVoltage: '0.45/0.75 kV',
          temperatureRange: '-30°C do +70°C',
        ),
      }
    };
  }

  // YKY - Kabel ziemny
  static Map<CableType, Map<double, CableData>> _buildYKY() {
    return {
      CableType.yky: {
        10.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yky,
          crossSection: 10.0,
          coreType: CoreType.re,
          outerDiameter: 16.0,
          heatShrinkSleeve: '25/8',
          heatShrinkLabel: '12/4',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        16.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yky,
          crossSection: 16.0,
          coreType: CoreType.re,
          outerDiameter: 19.0,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        25.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yky,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 23.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
      }
    };
  }

  // N2XH - Kabel bezhalogenowy (elektryczny, nie pożarowy!)
  static Map<CableType, Map<double, CableData>> _buildN2XH() {
    return {
      CableType.n2xh: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xh,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 9.0,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
        2.5: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xh,
          crossSection: 2.5,
          coreType: CoreType.re,
          outerDiameter: 10.0,
          heatShrinkSleeve: '15/5',
          heatShrinkLabel: '6/2',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
        4.0: CableData(
          material: CableMaterial.cu,
          type: CableType.n2xh,
          crossSection: 4.0,
          coreType: CoreType.re,
          outerDiameter: 11.5,
          heatShrinkSleeve: '18/6',
          heatShrinkLabel: '8/2.5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-30°C do +90°C',
        ),
      }
    };
  }

  // YAKY - Kabel aluminiowy
  static Map<CableType, Map<double, CableData>> _buildYAKY() {
    return {
      CableType.yaky: {
        16.0: CableData(
          material: CableMaterial.al,
          type: CableType.yaky,
          crossSection: 16.0,
          coreType: CoreType.sm,
          outerDiameter: 19.0,
          heatShrinkSleeve: '30/10',
          heatShrinkLabel: '15/5',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        25.0: CableData(
          material: CableMaterial.al,
          type: CableType.yaky,
          crossSection: 25.0,
          coreType: CoreType.sm,
          outerDiameter: 23.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '20/6',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
        35.0: CableData(
          material: CableMaterial.al,
          type: CableType.yaky,
          crossSection: 35.0,
          coreType: CoreType.sm,
          outerDiameter: 26.0,
          heatShrinkSleeve: '45/15',
          heatShrinkLabel: '25/8',
          application: CableApplication.electrical,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +70°C',
        ),
      }
    };
  }

  // NA2XSY - Kabel aluminiowy XLPE średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildNA2XSY() {
    return {
      CableType.na2xsy: {
        120.0: CableData(
          material: CableMaterial.al,
          type: CableType.na2xsy,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 48.0,
          heatShrinkSleeve: '70/25',
          heatShrinkLabel: '40/13',
          application: CableApplication.electrical,
          maxVoltage: '18/30 kV',
          temperatureRange: '-40°C do +90°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      }
    };
  }

  // OMY / OWY - Przewód warsztatowy
  static Map<CableType, Map<double, CableData>> _buildOMY() {
    return {
      CableType.omy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.omy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.4,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.electrical,
          maxVoltage: '450/750V',
          temperatureRange: '-30°C do +70°C',
          groupNumber: 1,
        ),
      },
    };
  }

  // HDGS - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildHDGS() {
    return {
      CableType.hdgs: {
        1.0: CableData(
          material: CableMaterial.cu,
          type: CableType.hdgs,
          crossSection: 1.0,
          coreType: CoreType.re,
          outerDiameter: 7.8,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.hdgs,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.4,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // HLGS - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildHLGS() {
    return {
      CableType.hlgs: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.hlgs,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 8.9,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // NHXH E90 - Kabel pożarowy
  static Map<CableType, Map<double, CableData>> _buildNHXH() {
    return {
      CableType.nhxh: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.nhxh,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 15.5,
          heatShrinkSleeve: '24/8',
          heatShrinkLabel: '8/3',
          application: CableApplication.fireproof,
          maxVoltage: '0.6/1 kV',
          temperatureRange: '-40°C do +90°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // HTKSH - Kabel pożarowy ekranowany
  static Map<CableType, Map<double, CableData>> _buildHTKSH() {
    return {
      CableType.htksh: {
        0.8: CableData(
          material: CableMaterial.cu,
          type: CableType.htksh,
          crossSection: 0.8,
          coreType: CoreType.re,
          outerDiameter: 6.2,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.fireproof,
          maxVoltage: '300V',
          temperatureRange: '-40°C do +250°C',
          groupNumber: 3,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // U/UTP 5e - Kabel sieciowy
  static Map<CableType, Map<double, CableData>> _buildUTP5E() {
    return {
      CableType.utp5e: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.utp5e,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 5.2,
          heatShrinkSleeve: '6/2',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // U/UTP 6 - Kabel sieciowy
  static Map<CableType, Map<double, CableData>> _buildUTP6() {
    return {
      CableType.utp6: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.utp6,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 6.3,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // F/UTP 6 - Kabel sieciowy ekranowany
  static Map<CableType, Map<double, CableData>> _buildFUTP6() {
    return {
      CableType.futp6: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.futp6,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 7.2,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // S/FTP 7 - Kabel sieciowy ekranowany podwójnie
  static Map<CableType, Map<double, CableData>> _buildSFTP7() {
    return {
      CableType.sftp7: {
        24.0: CableData(
          material: CableMaterial.cu,
          type: CableType.sftp7,
          crossSection: 24.0,
          coreType: CoreType.re,
          outerDiameter: 7.8,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-10°C do +60°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // RG6 - Kabel koaksjalny SAT
  static Map<CableType, Map<double, CableData>> _buildRG6() {
    return {
      CableType.rg6: {
        75.0: CableData(
          material: CableMaterial.cu,
          type: CableType.rg6,
          crossSection: 75.0,
          coreType: CoreType.sm,
          outerDiameter: 6.8,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-40°C do +70°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // RG11 - Kabel koaksjalny SAT
  static Map<CableType, Map<double, CableData>> _buildRG11() {
    return {
      CableType.rg11: {
        75.0: CableData(
          material: CableMaterial.cu,
          type: CableType.rg11,
          crossSection: 75.0,
          coreType: CoreType.sm,
          outerDiameter: 10.3,
          heatShrinkSleeve: '19.1/9.5',
          heatShrinkLabel: '9.5/4.8',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-40°C do +70°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // YnTKSY - Kabel teletechniczny
  static Map<CableType, Map<double, CableData>> _buildYTNKSY() {
    return {
      CableType.ytnksy: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.ytnksy,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 4.2,
          heatShrinkSleeve: '6/2',
          heatShrinkLabel: '3/1',
          application: CableApplication.telecom,
          maxVoltage: '300V',
          temperatureRange: '-20°C do +70°C',
          groupNumber: 4,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // LiYY - Kabel sterowniczy
  static Map<CableType, Map<double, CableData>> _buildLIYY() {
    return {
      CableType.liyy: {
        0.5: CableData(
          material: CableMaterial.cu,
          type: CableType.liyy,
          crossSection: 0.5,
          coreType: CoreType.re,
          outerDiameter: 4.8,
          heatShrinkSleeve: '6/2',
          heatShrinkLabel: '3/1',
          application: CableApplication.control,
          maxVoltage: '300/500V',
          temperatureRange: '-20°C do +70°C',
          wireConfiguration: WireConfiguration.twoWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rc,
        ),
      },
    };
  }

  // LiYCY ekranowany - Kabel sterowniczy ekranowany
  static Map<CableType, Map<double, CableData>> _buildLIYCYEK() {
    return {
      CableType.liycyekaprn: {
        0.75: CableData(
          material: CableMaterial.cu,
          type: CableType.liycyekaprn,
          crossSection: 0.75,
          coreType: CoreType.re,
          outerDiameter: 6.2,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '300/500V',
          temperatureRange: '-20°C do +70°C',
          wireConfiguration: WireConfiguration.twoWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // YSLY / JZ-500 - Kabel sterowniczy
  static Map<CableType, Map<double, CableData>> _buildYSLY() {
    return {
      CableType.ysly: {
        1.0: CableData(
          material: CableMaterial.cu,
          type: CableType.ysly,
          crossSection: 1.0,
          coreType: CoreType.re,
          outerDiameter: 6.5,
          heatShrinkSleeve: '9.5/4.8',
          heatShrinkLabel: '4/1.5',
          application: CableApplication.control,
          maxVoltage: '300V',
          temperatureRange: '-30°C do +70°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // BiT 500 CY - Kabel sterowniczy ekranowany
  static Map<CableType, Map<double, CableData>> _buildBIT500CY() {
    return {
      CableType.bit500cy: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.bit500cy,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 9.2,
          heatShrinkSleeve: '12/4',
          heatShrinkLabel: '6/2',
          application: CableApplication.control,
          maxVoltage: '300V',
          temperatureRange: '-20°C do +70°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // H07RN-F - Kabel gumowy OnPD
  static Map<CableType, Map<double, CableData>> _buildH07RNF() {
    return {
      CableType.h07rnf: {
        1.5: CableData(
          material: CableMaterial.cu,
          type: CableType.h07rnf,
          crossSection: 1.5,
          coreType: CoreType.re,
          outerDiameter: 10.5,
          heatShrinkSleeve: '19.1/9.5',
          heatShrinkLabel: '9.5/4.8',
          application: CableApplication.industrial,
          maxVoltage: '450/750V',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.threeWire,
          groupNumber: 5,
          recommendedTubeStandard: HeatShrinkStandard.rck,
        ),
      },
    };
  }

  // YHAKXS - Kabel średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildYHAKXS() {
    return {
      CableType.yhakxs: {
        35.0: CableData(
          material: CableMaterial.cu,
          type: CableType.yhakxs,
          crossSection: 35.0,
          coreType: CoreType.sm,
          outerDiameter: 26.0,
          heatShrinkSleeve: '40/13',
          heatShrinkLabel: '19.1/9.5',
          application: CableApplication.electrical,
          maxVoltage: '12/20 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // XHAKXS - Kabel średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildXHAKXS() {
    return {
      CableType.xhakxs: {
        120.0: CableData(
          material: CableMaterial.cu,
          type: CableType.xhakxs,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 34.0,
          heatShrinkSleeve: '55/15',
          heatShrinkLabel: '24.0/8',
          application: CableApplication.electrical,
          maxVoltage: '12/20 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // XRUHAKXS - Kabel średnie napięcie pancerz
  static Map<CableType, Map<double, CableData>> _buildXRUHAKXS() {
    return {
      CableType.xruhakxs: {
        120.0: CableData(
          material: CableMaterial.cu,
          type: CableType.xruhakxs,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 38.0,
          heatShrinkSleeve: '55/15',
          heatShrinkLabel: '24.0/8',
          application: CableApplication.electrical,
          maxVoltage: '12/20 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // A2XSY - Kabel średnie napięcie
  static Map<CableType, Map<double, CableData>> _buildA2XSY() {
    return {
      CableType.a2xsy: {
        120.0: CableData(
          material: CableMaterial.cu,
          type: CableType.a2xsy,
          crossSection: 120.0,
          coreType: CoreType.sm,
          outerDiameter: 43.0,
          heatShrinkSleeve: '55/15',
          heatShrinkLabel: '24.0/8',
          application: CableApplication.electrical,
          maxVoltage: '18/30 kV',
          temperatureRange: '-40°C do +70°C',
          wireConfiguration: WireConfiguration.single,
          groupNumber: 6,
          recommendedTubeStandard: HeatShrinkStandard.rgk,
        ),
      },
    };
  }

  // === Metody zapytań ===

  static CableData? getCableData(
    CableMaterial material,
    CableType type,
    double crossSection,
  ) {
    final variants = _runtimeVariants[material]?[type];
    if (variants == null) {
      return null;
    }
    for (final cable in variants) {
      if (cable.crossSection == crossSection) {
        return cable;
      }
    }
    return null;
  }

  static CableData? getCableDataByConfiguration(
    CableMaterial material,
    CableType type,
    double crossSection,
    WireConfiguration wireConfiguration,
  ) {
    final variants = _runtimeVariants[material]?[type];
    if (variants == null) {
      return null;
    }
    for (final cable in variants) {
      if (cable.crossSection == crossSection &&
          cable.wireConfiguration == wireConfiguration) {
        return cable;
      }
    }
    return null;
  }

  static List<CableData> getCableVariants(
    CableMaterial material,
    CableType type,
  ) {
    return List<CableData>.from(
      _runtimeVariants[material]?[type] ?? const <CableData>[],
    );
  }

  static List<CableData> getCableVariantsByConfiguration(
    CableMaterial material,
    CableType type,
    double crossSection,
    WireConfiguration wireConfiguration,
  ) {
    final variants = _runtimeVariants[material]?[type] ?? const <CableData>[];
    return variants
        .where(
          (cable) =>
              cable.crossSection == crossSection &&
              cable.wireConfiguration == wireConfiguration,
        )
        .toList();
  }

  static List<CableType> getAvailableTypes(CableMaterial material) {
    return _runtimeVariants[material]?.keys.toList() ?? [];
  }

  static List<double> getAvailableCrossSections(
    CableMaterial material,
    CableType type, {
    WireConfiguration? wireConfiguration,
  }) {
    final variants = _runtimeVariants[material]?[type] ?? const <CableData>[];
    final crossSections = variants
        .where(
          (cable) =>
              wireConfiguration == null ||
              cable.wireConfiguration == wireConfiguration,
        )
        .map((cable) => cable.crossSection)
        .toSet()
        .toList();
    crossSections.sort();
    return crossSections;
  }

  static List<WireConfiguration> getAvailableWireConfigurations(
    CableMaterial material,
    CableType type,
  ) {
    final variants = _runtimeVariants[material]?[type] ?? const <CableData>[];
    final configs =
        variants.map((cable) => cable.wireConfiguration).toSet().toList();
    configs.sort((a, b) => a.index.compareTo(b.index));
    return configs;
  }

  // Nowa metoda: pobierz dostępne zastosowania
  static List<CableApplication> getAvailableApplications() {
    final apps = <CableApplication>{};
    for (final materialEntry in _runtimeVariants.entries) {
      for (final typeEntry in materialEntry.value.entries) {
        for (final cable in typeEntry.value) {
          apps.add(cable.application);
        }
      }
    }

    final result = apps.toList();
    result.sort((a, b) => a.index.compareTo(b.index));
    return result;
  }

  // Nowa metoda: filtrowanie po zastosowaniu
  static List<CableType> getTypesByApplication(CableApplication app) {
    final types = <CableType>[];
    for (final materialEntry in _runtimeVariants.entries) {
      for (final typeEntry in materialEntry.value.entries) {
        if (typeEntry.value.any((cable) => cable.application == app)) {
          types.add(typeEntry.key);
        }
      }
    }
    return types.toSet().toList();
  }

  // Nowa metoda: filtrowanie po zastosowaniu i materiale
  static List<CableType> getTypesByApplicationAndMaterial(
    CableApplication app,
    CableMaterial material,
  ) {
    final types = <CableType>[];
    final materialData = _runtimeVariants[material];
    if (materialData != null) {
      for (final typeEntry in materialData.entries) {
        if (typeEntry.value.any((cable) => cable.application == app)) {
          types.add(typeEntry.key);
        }
      }
    }
    return types;
  }

  // Sugestia standardu rury na podstawie warunków pracy
  static HeatShrinkStandard suggestTubeStandardForCondition(
    WorkingCondition condition,
  ) {
    return CableData.suggestTubeStandard(condition);
  }

  // Pobierz sugerowane rury na podstawie średnicy kabla i warunku
  static List<HeatShrinkTube> suggestTubesForCable(
    double cableDiameter,
    WorkingCondition condition,
  ) {
    final standard = CableData.suggestTubeStandard(condition);
    return CableData.suggestTubesForCableDiameter(cableDiameter, standard);
  }

  // Sugerowane srednice rur sztywnych (orientacyjnie) dla pojedynczego kabla.
  // Przyjeto zapas montazowy ok. 30% srednicy zewnetrznej kabla.
  static List<int> suggestRigidConduitDiameters(double outerDiameter) {
    const standardDiameters = <int>[16, 20, 25, 32, 40, 50, 63, 75, 90, 110];
    final minimum = outerDiameter * 1.3;
    final fits = standardDiameters.where((d) => d >= minimum).toList();
    return fits.take(3).toList();
  }

  // Pobierz dostępne warianty warunków pracy
  static List<WorkingCondition> getAvailableWorkingConditions() {
    return WorkingCondition.values;
  }

  // Oblicz rekomendowaną rurę 3:1 na podstawie średnicy kabla
  static String getRecommendedHeatShrink3to1(double outerDiameter) {
    if (outerDiameter <= 6.0) return '9/3';
    if (outerDiameter <= 9.0) return '12/4';
    if (outerDiameter <= 12.0) return '15/5';
    if (outerDiameter <= 15.0) return '18/6';
    if (outerDiameter <= 18.0) return '25/8';
    if (outerDiameter <= 24.0) return '30/10';
    if (outerDiameter <= 32.0) return '40/13';
    if (outerDiameter <= 42.0) return '50/17';
    return '60/20';
  }

  // Oblicz rekomendowaną rurę 2:1 na podstawie średnicy kabla
  static String getRecommendedHeatShrink2to1(double outerDiameter) {
    if (outerDiameter <= 3.0) return '3/1';
    if (outerDiameter <= 4.0) return '4/1.5';
    if (outerDiameter <= 5.0) return '6/2';
    if (outerDiameter <= 7.0) return '8/2.5';
    if (outerDiameter <= 9.0) return '10/3';
    if (outerDiameter <= 11.0) return '12/4';
    if (outerDiameter <= 14.0) return '15/5';
    if (outerDiameter <= 18.0) return '20/6';
    if (outerDiameter <= 23.0) return '25/8';
    return '30/10';
  }
}
