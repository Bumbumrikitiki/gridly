import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gridly/multitool/cable_selector/logic/cable_data_provider.dart';
import 'package:gridly/multitool/cable_selector/models/cable_data.dart';

enum _MaterialProfile {
  interior,
  outdoorUv,
  underground,
  highTemp,
  chemical,
}

enum _MountingSubstrate {
  concrete,
  steel,
  masonry,
}

class _RecommendationSnapshot {
  const _RecommendationSnapshot({
    required this.condition,
    required this.reservePercent,
    required this.standard,
    required this.sleeve,
    required this.label,
    required this.topTube,
    required this.topRigidConduit,
  });

  final WorkingCondition condition;
  final double reservePercent;
  final String standard;
  final String sleeve;
  final String label;
  final String topTube;
  final String topRigidConduit;
}

class _CableTrayPreset {
  const _CableTrayPreset({
    required this.heightMm,
    required this.widthMm,
  });

  final double heightMm;
  final double widthMm;

  String get label => '${widthMm.toInt()}x${heightMm.toInt()}';
}

class _TrayCapacityResult {
  const _TrayCapacityResult({
    required this.maxByFill,
    required this.maxByLoad,
    required this.maxByThermal,
    required this.finalCount,
    required this.cableMassKgPerM,
    required this.cableAreaMm2,
    required this.thermalFactor,
    required this.isPowerCable,
    required this.massFromDatabase,
    required this.tempCorrection,
    required this.groupingCorrection,
    required this.ventilationCorrection,
  });

  final int maxByFill;
  final int maxByLoad;
  final int maxByThermal;
  final int finalCount;
  final double cableMassKgPerM;
  final double cableAreaMm2;
  final double thermalFactor;
  final bool isPowerCable;
  final bool massFromDatabase;
  final double tempCorrection;
  final double groupingCorrection;
  final double ventilationCorrection;
}

class _OfferRecommendationGroup {
  const _OfferRecommendationGroup({
    required this.title,
    required this.icon,
    required this.items,
    this.note,
  });

  final String title;
  final IconData icon;
  final List<String> items;
  final String? note;
}

class CableSelectorScreen extends StatefulWidget {
  const CableSelectorScreen({super.key});

  @override
  State<CableSelectorScreen> createState() => _CableSelectorScreenState();
}

class _CableSelectorScreenState extends State<CableSelectorScreen>
    with SingleTickerProviderStateMixin {
  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _electricBlue = Color(0xFF1E90FF);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  CableApplication? _selectedApplication;
  CableMaterial? _selectedMaterial;
  // Removed group and voltage filters
  String _typeSearchQuery = '';
  CableType? _selectedType;
  WireConfiguration? _selectedWireConfiguration;
  double? _selectedCrossSection;
  WorkingCondition _selectedWorkingCondition = WorkingCondition.interior;
  _MaterialProfile _selectedMaterialProfile = _MaterialProfile.interior;
  double _materialReservePercent = 20;
  _RecommendationSnapshot? _previousRecommendation;
  String? _recommendationChangeReason;
  _MountingSubstrate _mountingSubstrate = _MountingSubstrate.concrete;
  double _trayHeightMm = 50;
  double _trayWidthMm = 200;
  double _trayMaxFillPercent = 40;
  double _trayMaxLoadKgPerM = 25;
  double _trayAmbientTempC = 30;
  int _trayGroupedPowerCircuits = 1;
  bool _trayVentilated = true;
  CableData? _result;
  final Set<CableType> _favoriteTypes = <CableType>{};
  final List<CableType> _recentTypes = <CableType>[];
  bool _databaseInitialized = false;
  Map<String, int> _databaseStats = const {
    'totalRecords': 0,
    'localImportedRecords': 0,
    'materials': 0,
  };
  final TextEditingController _typeSearchController = TextEditingController();

  static const List<_CableTrayPreset> _trayPresets = [
    _CableTrayPreset(heightMm: 50, widthMm: 50),
    _CableTrayPreset(heightMm: 50, widthMm: 100),
    _CableTrayPreset(heightMm: 50, widthMm: 150),
    _CableTrayPreset(heightMm: 50, widthMm: 200),
    _CableTrayPreset(heightMm: 50, widthMm: 300),
    _CableTrayPreset(heightMm: 50, widthMm: 400),
    _CableTrayPreset(heightMm: 50, widthMm: 600),
  ];

  static const String _trayNormReference =
      'Model referencyjny: IEC 60364/PN-HD (zajetosc, grupowanie, temperatura)';

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _initializeLocalDatabase();
  }

  Future<void> _initializeLocalDatabase() async {
    await CableDataProvider.initializeLocalDatabase();
    if (!mounted) {
      return;
    }

    setState(() {
      _databaseStats = CableDataProvider.getDatabaseStats();
      _databaseInitialized = true;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _typeSearchController.dispose();
    super.dispose();
  }

  void _onApplicationSelected(CableApplication app) {
    final availableMaterials = _getAvailableMaterialsForApplication(app);
    setState(() {
      _selectedApplication = app;
      _selectedMaterial =
          availableMaterials.length == 1 ? availableMaterials.first : null;
      _typeSearchQuery = '';
      _selectedType = null;
      _selectedWireConfiguration = null;
      _selectedCrossSection = null;
      _result = null;
      _typeSearchController.clear();
    });
    _animationController.forward(from: 0);
  }

  List<CableMaterial> _getAvailableMaterialsForApplication(
    CableApplication app,
  ) {
    final materials = CableMaterial.values.where((material) {
      return CableDataProvider.getTypesByApplicationAndMaterial(app, material)
          .isNotEmpty;
    }).toList();
    materials.sort((a, b) => a.index.compareTo(b.index));
    return materials;
  }

  void _onMaterialSelected(CableMaterial material) {
    setState(() {
      _selectedMaterial = material;
      _typeSearchQuery = '';
      _selectedType = null;
      _selectedWireConfiguration = null;
      _selectedCrossSection = null;
      _result = null;
      _typeSearchController.clear();
    });
    _animationController.forward(from: 0);
  }

  void _onTypeSelected(CableType type) {
    setState(() {
      _selectedType = type;
      _selectedWireConfiguration = null;
      _selectedCrossSection = null;
      _result = null;
      _recentTypes.remove(type);
      _recentTypes.insert(0, type);
      if (_recentTypes.length > 10) {
        _recentTypes.removeRange(10, _recentTypes.length);
      }
    });
    _animationController.forward(from: 0);
  }

  void _toggleFavorite(CableType type) {
    setState(() {
      if (_favoriteTypes.contains(type)) {
        _favoriteTypes.remove(type);
      } else {
        _favoriteTypes.add(type);
      }
    });
  }

  List<CableType> _getBaseTypesForCurrentSelection() {
    if (_selectedApplication == null || _selectedMaterial == null) {
      return const [];
    }
    return CableDataProvider.getTypesByApplicationAndMaterial(
      _selectedApplication!,
      _selectedMaterial!,
    );
  }

  List<int> _getAvailableGroupNumbersForCurrentSelection() {
    final groups = _getBaseTypesForCurrentSelection()
        .map(CableData.typeGroupNumber)
        .toSet()
        .toList();
    groups.sort();
    return groups;
  }

  List<CableType> _getFilteredTypes() {
    final query = _normalizeToken(_typeSearchQuery);
    final tokens = _extractSearchTokens(query);
    final filtered = _getBaseTypesForCurrentSelection().where((type) {
      if (query.isEmpty) {
        return true;
      }
      final haystack = _buildTypeSearchIndex(type);
      if (haystack.contains(query)) {
        return true;
      }
      return tokens.every(haystack.contains);
    }).toList();

    if (query.isEmpty) {
      filtered.sort((a, b) =>
          CableData.typeToString(a).compareTo(CableData.typeToString(b)));
      return filtered;
    }

    filtered.sort(
      (a, b) =>
          _scoreTypeForQuery(b, query).compareTo(_scoreTypeForQuery(a, query)),
    );
    return filtered;
  }

  String _buildTypeSearchIndex(CableType type) {
    final tokens = <String>[
      CableData.typeToString(type).toLowerCase(),
      CableData.typeGroupLabel(type).toLowerCase(),
      type.name.toLowerCase(),
    ];

    tokens.addAll(_getTypeAliases(type));

    if (_selectedMaterial != null) {
      final variants = CableDataProvider.getCableVariants(
        _selectedMaterial!,
        type,
      );
      for (final data in variants) {
        final wireCount = _wireCountForConfig(data.wireConfiguration);
        final csLabel = data.crossSection.toString().replaceAll('.0', '');
        if (wireCount != null) {
          tokens.add('${wireCount}x$csLabel');
          tokens.add('${wireCount}x${csLabel.replaceAll('.', ',')}');
          tokens.add('$wireCount x $csLabel');
          tokens.add('$wireCount x ${csLabel.replaceAll('.', ',')}');
        }
        tokens.add(data.maxVoltage.toLowerCase());
        tokens.add(_normalizeToken(data.maxVoltage));
      }
    }

    return tokens.map(_normalizeToken).join(' ');
  }

  int _scoreTypeForQuery(CableType type, String query) {
    final normalized = _normalizeToken(query);
    final typeName = CableData.typeToString(type).toLowerCase();
    final shortName = type.name.toLowerCase();
    final searchIndex = _buildTypeSearchIndex(type);
    var score = 0;

    if (shortName == normalized || typeName == normalized) {
      score += 120;
    }
    if (shortName.startsWith(normalized) || typeName.startsWith(normalized)) {
      score += 80;
    }
    if (searchIndex.contains(normalized)) {
      score += 40;
    }

    final parts = _extractSearchTokens(normalized);
    for (final part in parts) {
      if (shortName.startsWith(part)) {
        score += 20;
      }
      if (searchIndex.contains(part)) {
        score += 12;
      }
    }

    return score;
  }

  List<String> _getTypeAliases(CableType type) {
    switch (type) {
      case CableType.yky:
        return ['yky', 'ziemny', 'power'];
      case CableType.n2xh:
        return ['n2xh', 'bezhalogen', 'halogenfree', 'b2ca'];
      case CableType.utp5e:
        return ['utp5e', 'uutp', 'u/utp', 'kat5e', 'cat5e'];
      case CableType.utp6:
        return ['utp6', 'uutp', 'u/utp', 'kat6', 'cat6'];
      case CableType.futp6:
        return ['futp6', 'f/utp', 'kat6', 'cat6'];
      case CableType.sftp7:
        return ['sftp7', 's/ftp', 'kat7', 'cat7'];
      default:
        return [type.name.toLowerCase()];
    }
  }

  String _normalizeToken(String value) {
    return value
        .toLowerCase()
        .replaceAll(',', '.')
        .replaceAll(' ', '')
        .replaceAll('kv', 'kv')
        .trim();
  }

  List<String> _extractSearchTokens(String query) {
    final expanded = query
        .toLowerCase()
        .replaceAll(',', '.')
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .replaceAll('x', ' x ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (expanded.isEmpty) {
      return const [];
    }

    final parts = expanded
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(_normalizeToken)
        .toSet()
        .toList();

    final compact = _normalizeToken(expanded);
    if (compact.isNotEmpty) {
      parts.add(compact);
    }
    return parts;
  }

  int? _wireCountForConfig(WireConfiguration config) {
    switch (config) {
      case WireConfiguration.single:
        return 1;
      case WireConfiguration.pair:
        return 2;
      case WireConfiguration.twoWire:
        return 2;
      case WireConfiguration.threeWire:
        return 3;
      case WireConfiguration.fourWire:
        return 4;
      case WireConfiguration.fiveWire:
        return 5;
      case WireConfiguration.sevenWire:
        return 7;
      case WireConfiguration.twelvWire:
        return 12;
      case WireConfiguration.twentyFiveWire:
        return 25;
    }
  }

  // Removed _activeFilterCount (no filters)

  void _applyQuickSearchChip(String value) {
    setState(() {
      _typeSearchQuery = value;
      _typeSearchController.text = value;
      _typeSearchController.selection =
          TextSelection.collapsed(offset: value.length);
    });
  }

  void _clearTypeSearch() {
    setState(() {
      _typeSearchQuery = '';
      _typeSearchController.clear();
    });
  }

  // Removed filter modal

  List<String> _getAvailableVoltagesForCurrentSelection() {
    final values = <String>{};
    for (final type in _getBaseTypesForCurrentSelection()) {
      if (_selectedMaterial == null) {
        continue;
      }
      final variants = CableDataProvider.getCableVariants(
        _selectedMaterial!,
        type,
      );
      if (variants.isEmpty) {
        continue;
      }
      for (final data in variants) {
        values.add(data.maxVoltage);
      }
    }
    final list = values.toList();
    list.sort();
    return list;
  }

  bool _typeMatchesVoltage(CableType type, String voltage) {
    if (_selectedMaterial == null) {
      return false;
    }
    final variants = CableDataProvider.getCableVariants(
      _selectedMaterial!,
      type,
    );
    return variants.any((data) => data.maxVoltage == voltage);
  }

  String _qualityLabel(CableData data) {
    if ((data.source ?? '').isNotEmpty) {
      return 'Katalogowe';
    }
    if (data.groupNumber >= 6) {
      return 'Do weryfikacji';
    }
    return 'Przyblizone';
  }

  bool _hasValue(String? value) {
    if (value == null) {
      return false;
    }
    final normalized = value.trim();
    return normalized.isNotEmpty && normalized != '---';
  }

  String _variantTitle(CableData data) {
    final parts = <String>[];
    if (_hasValue(data.sourceType)) {
      parts.add(data.sourceType!.trim());
    }
    if (_hasValue(data.sourceSize)) {
      parts.add(data.sourceSize!.trim());
    } else {
      parts.add('${data.crossSection} mm²');
    }
    if (_hasValue(data.manufacturer)) {
      parts.add(data.manufacturer!.trim());
    }
    return parts.join(' • ');
  }

  bool _isFlatCable(CableData data) {
    if (data.type == CableType.ydyp) {
      return true;
    }
    final sourceType = (data.sourceType ?? '').toLowerCase();
    return sourceType.contains('plaski') || sourceType.contains('płaski');
  }

  String _externalDimensionLabel(CableData data) {
    return _isFlatCable(data) ? 'Wymiary zewnętrzne' : 'Średnica zewnętrzna';
  }

  String _externalDimensionValue(CableData data) {
    if (_isFlatCable(data) && _hasValue(data.sourceDiameter)) {
      final raw =
          data.sourceDiameter!.replaceAll('×', 'x').replaceAll('X', 'x').trim();
      if (raw.contains('x')) {
        return '$raw mm';
      }
    }

    // Wymiar zewnętrzny pobieramy z kolumny d zaimportowanej do outerDiameter.
    return '${data.outerDiameter} mm';
  }

  Color _qualityColor(String quality) {
    switch (quality) {
      case 'Do weryfikacji':
        return const Color(0xFFFF6B6B);
      case 'Katalogowe':
        return const Color(0xFF2ECC71);
      default:
        return const Color(0xFFF7B500);
    }
  }

  String _profileTitle(_MaterialProfile profile) {
    switch (profile) {
      case _MaterialProfile.interior:
        return 'Wnetrze';
      case _MaterialProfile.outdoorUv:
        return 'Zewnatrz UV';
      case _MaterialProfile.underground:
        return 'Ziemia';
      case _MaterialProfile.highTemp:
        return 'Wysoka temp.';
      case _MaterialProfile.chemical:
        return 'Chemia';
    }
  }

  String _profileHint(_MaterialProfile profile) {
    switch (profile) {
      case _MaterialProfile.interior:
        return 'Szafa/puszka, standardowe warunki';
      case _MaterialProfile.outdoorUv:
        return 'Ekspozycja UV i wilgoc';
      case _MaterialProfile.underground:
        return 'Trasa w ziemi i ochrona mechaniczna';
      case _MaterialProfile.highTemp:
        return 'Podwyzszona temperatura pracy';
      case _MaterialProfile.chemical:
        return 'Agresywne srodowisko przemyslowe';
    }
  }

  WorkingCondition _profileCondition(_MaterialProfile profile) {
    switch (profile) {
      case _MaterialProfile.interior:
        return WorkingCondition.interior;
      case _MaterialProfile.outdoorUv:
      case _MaterialProfile.highTemp:
      case _MaterialProfile.chemical:
        return WorkingCondition.humid;
      case _MaterialProfile.underground:
        return WorkingCondition.ground;
    }
  }

  double _profileReservePercent(_MaterialProfile profile) {
    switch (profile) {
      case _MaterialProfile.interior:
        return 15;
      case _MaterialProfile.outdoorUv:
        return 25;
      case _MaterialProfile.underground:
        return 30;
      case _MaterialProfile.highTemp:
        return 25;
      case _MaterialProfile.chemical:
        return 30;
    }
  }

  double _reserveAdjustedDiameter(double outerDiameter, double reservePercent) {
    final delta = (reservePercent - 20) / 100;
    return outerDiameter * (1 + delta);
  }

  List<HeatShrinkTube> _tubeRecommendationsForReserve(CableData data) {
    final adjustedDiameter = _reserveAdjustedDiameter(
      data.outerDiameter,
      _materialReservePercent,
    );
    final options = CableDataProvider.suggestTubesForCable(
      adjustedDiameter,
      _selectedWorkingCondition,
    );
    return options.take(4).toList();
  }

  List<int> _rigidConduitsForReserve(CableData data) {
    final adjustedDiameter = _reserveAdjustedDiameter(
      data.outerDiameter,
      _materialReservePercent,
    );
    return CableDataProvider.suggestRigidConduitDiameters(adjustedDiameter);
  }

  String _confidenceLabel(
    CableData data,
    List<HeatShrinkTube> tubes,
    List<int> conduits,
  ) {
    if (_qualityLabel(data) == 'Do weryfikacji' ||
        data.groupNumber >= 6 ||
        tubes.isEmpty) {
      return 'Do weryfikacji';
    }
    if (_qualityLabel(data) == 'Katalogowe' && conduits.isNotEmpty) {
      return 'Wysoka';
    }
    return 'Srednia';
  }

  Color _confidenceColor(String confidence) {
    switch (confidence) {
      case 'Wysoka':
        return const Color(0xFF2ECC71);
      case 'Srednia':
        return const Color(0xFFF7B500);
      default:
        return const Color(0xFFFF6B6B);
    }
  }

  String _recommendationReason(
    CableData data,
    HeatShrinkStandard standard,
    List<HeatShrinkTube> tubes,
  ) {
    final baseReason =
        'Srednica kabla ${data.outerDiameter} mm, zapas ${_materialReservePercent.toStringAsFixed(0)}%, warunki ${CableData.workingConditionToString(_selectedWorkingCondition).toLowerCase()}.';

    if (tubes.isEmpty) {
      return '$baseReason Brak jednoznacznego dopasowania rur - wymagana reczna weryfikacja.';
    }

    return '$baseReason Standard ${HeatShrinkTube.standardToString(standard)} dobrany do profilu pracy.';
  }

  List<String> _buildRecommendationWarnings(
    CableData data,
    List<HeatShrinkTube> tubes,
    List<int> conduits,
    HeatShrinkStandard standard,
  ) {
    final warnings = <String>[];
    final halogen = (data.halogenFree ?? '').toLowerCase();

    if (tubes.isEmpty) {
      warnings.add(
          'Brak sugerowanej rury termokurczliwej dla aktualnych parametrow.');
    }
    if (conduits.isEmpty) {
      warnings.add(
          'Brak sugerowanej rury sztywnej - sprawdz trase i srednice recznie.');
    }
    if ((halogen.contains('tak') || halogen.contains('yes')) &&
        standard == HeatShrinkStandard.rc) {
      warnings.add(
          'Kabel oznaczony jako halogen free: preferowany standard RCK/RGK.');
    }
    if (_materialReservePercent >= 30 && tubes.length < 2) {
      warnings
          .add('Duzy zapas montazowy: rozważ alternatywe o wiekszej srednicy.');
    }
    if (data.groupNumber >= 6) {
      warnings.add('Dla grupy SN zalecana akceptacja przez osobe uprawniona.');
    }

    return warnings;
  }

  _RecommendationSnapshot _buildRecommendationSnapshot(
    CableData data,
    WorkingCondition condition,
    double reservePercent,
  ) {
    final adjustedDiameter =
        data.outerDiameter * (1 + ((reservePercent - 20) / 100));
    final standard =
        CableDataProvider.suggestTubeStandardForCondition(condition);
    final tubes =
        CableDataProvider.suggestTubesForCable(adjustedDiameter, condition);
    final conduits =
        CableDataProvider.suggestRigidConduitDiameters(adjustedDiameter);

    return _RecommendationSnapshot(
      condition: condition,
      reservePercent: reservePercent,
      standard: HeatShrinkTube.standardToString(standard),
      sleeve: data.heatShrinkSleeve,
      label: data.heatShrinkLabel,
      topTube: tubes.isNotEmpty ? tubes.first.description : '-',
      topRigidConduit: conduits.isNotEmpty ? 'DN ${conduits.first} mm' : '-',
    );
  }

  String? _buildRecommendationDeltaMessage(
    _RecommendationSnapshot before,
    _RecommendationSnapshot after,
  ) {
    final changes = <String>[];
    if (before.condition != after.condition) {
      changes.add(
        'warunki ${CableData.workingConditionToString(before.condition)} -> ${CableData.workingConditionToString(after.condition)}',
      );
    }
    if (before.reservePercent != after.reservePercent) {
      changes.add(
        'zapas ${before.reservePercent.toStringAsFixed(0)}% -> ${after.reservePercent.toStringAsFixed(0)}%',
      );
    }
    if (before.standard != after.standard) {
      changes.add('standard ${before.standard} -> ${after.standard}');
    }
    if (before.topTube != after.topTube) {
      changes.add('rura termokurczliwa ${before.topTube} -> ${after.topTube}');
    }
    if (before.topRigidConduit != after.topRigidConduit) {
      changes.add(
        'rura sztywna ${before.topRigidConduit} -> ${after.topRigidConduit}',
      );
    }

    if (changes.isEmpty) {
      return null;
    }

    return 'Dlaczego zmiana: ${changes.join('; ')}.';
  }

  void _applyMaterialProfile(_MaterialProfile profile) {
    final data = _result;
    final before = data == null
        ? null
        : _buildRecommendationSnapshot(
            data,
            _selectedWorkingCondition,
            _materialReservePercent,
          );

    final nextCondition = _profileCondition(profile);
    final nextReserve = _profileReservePercent(profile);
    final nextReason = data == null || before == null
        ? null
        : _buildRecommendationDeltaMessage(
            before,
            _buildRecommendationSnapshot(data, nextCondition, nextReserve),
          );

    setState(() {
      _selectedMaterialProfile = profile;
      _selectedWorkingCondition = nextCondition;
      _materialReservePercent = nextReserve;
      _previousRecommendation = before;
      _recommendationChangeReason = nextReason;
    });
    _animationController.forward(from: 0);
  }

  void _onReserveChanged(double value) {
    final data = _result;
    final before = data == null
        ? null
        : _buildRecommendationSnapshot(
            data,
            _selectedWorkingCondition,
            _materialReservePercent,
          );
    final rounded = (value / 5).round() * 5.0;
    final nextReason = data == null || before == null
        ? null
        : _buildRecommendationDeltaMessage(
            before,
            _buildRecommendationSnapshot(
              data,
              _selectedWorkingCondition,
              rounded,
            ),
          );

    setState(() {
      _materialReservePercent = rounded;
      _previousRecommendation = before;
      _recommendationChangeReason = nextReason;
    });
  }

  bool _isPowerCable(CableData data) {
    return data.application == CableApplication.electrical ||
        data.application == CableApplication.power ||
        data.application == CableApplication.mediumVoltage;
  }

  ({double a, double b})? _flatDimensions(CableData data) {
    if (!_isFlatCable(data) || !_hasValue(data.sourceDiameter)) {
      return null;
    }
    final raw = data.sourceDiameter!
        .toLowerCase()
        .replaceAll('×', 'x')
        .replaceAll(' ', '');
    final parts = raw.split('x');
    if (parts.length != 2) {
      return null;
    }
    final a = double.tryParse(parts[0].replaceAll(',', '.'));
    final b = double.tryParse(parts[1].replaceAll(',', '.'));
    if (a == null || b == null || a <= 0 || b <= 0) {
      return null;
    }
    return (a: a, b: b);
  }

  double _projectedCableAreaMm2(CableData data) {
    final flat = _flatDimensions(data);
    if (flat != null) {
      return flat.a * flat.b;
    }
    final radius = data.outerDiameter / 2;
    return math.pi * radius * radius;
  }

  double _estimatedCableMassKgPerM(CableData data) {
    final wireCount = _wireCountForConfig(data.wireConfiguration) ?? 1;
    final conductorAreaMm2 = data.crossSection * wireCount;
    final conductorDensity =
        data.material == CableMaterial.cu ? 8960.0 : 2700.0;
    final conductorMass = conductorAreaMm2 * 1e-6 * conductorDensity;

    final outerAreaMm2 = math.pi * math.pow(data.outerDiameter / 2, 2);
    final polymerAreaMm2 = math.max(
        (outerAreaMm2 - (conductorAreaMm2 * 1.15)).toDouble(),
        outerAreaMm2 * 0.35);
    final polymerMass = polymerAreaMm2 * 1e-6 * 1200;

    return conductorMass + polymerMass;
  }

  double? _massFromDatabaseKgPerM(CableData data) {
    final candidates = [
      data.notes,
      data.usage,
      data.sourceSize,
      data.sourceType,
    ];
    final regex =
        RegExp(r'(\d+(?:[\.,]\d+)?)\s*kg\s*/\s*m', caseSensitive: false);

    for (final entry in candidates) {
      if (entry == null || entry.trim().isEmpty) {
        continue;
      }
      final match = regex.firstMatch(entry);
      if (match == null) {
        continue;
      }
      final parsed = double.tryParse(match.group(1)!.replaceAll(',', '.'));
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    return null;
  }

  bool _isXlpeInsulation(CableData data) {
    final text =
        '${data.insulation ?? ''} ${data.sourceType ?? ''}'.toLowerCase();
    return text.contains('xlpe') ||
        text.contains('xlh') ||
        text.contains('xhak');
  }

  double _temperatureCorrection(CableData data) {
    final xlpe = _isXlpeInsulation(data);
    final temp = _trayAmbientTempC;

    if (xlpe) {
      if (temp <= 25) return 1.03;
      if (temp <= 30) return 1.00;
      if (temp <= 35) return 0.96;
      if (temp <= 40) return 0.91;
      if (temp <= 45) return 0.87;
      return 0.82;
    }

    if (temp <= 25) return 1.02;
    if (temp <= 30) return 1.00;
    if (temp <= 35) return 0.94;
    if (temp <= 40) return 0.87;
    if (temp <= 45) return 0.79;
    return 0.71;
  }

  double _groupingCorrection() {
    const factors = {
      1: 1.00,
      2: 0.85,
      3: 0.79,
      4: 0.75,
      5: 0.73,
      6: 0.72,
    };

    if (_trayGroupedPowerCircuits <= 1) {
      return 1.0;
    }
    if (_trayGroupedPowerCircuits >= 6) {
      return 0.72;
    }
    return factors[_trayGroupedPowerCircuits] ?? 0.72;
  }

  double _ventilationCorrection() {
    return _trayVentilated ? 1.0 : 0.9;
  }

  double _thermalFactorForTray(CableData data) {
    if (!_isPowerCable(data)) {
      return 1.0;
    }
    var factor = _temperatureCorrection(data) *
        _groupingCorrection() *
        _ventilationCorrection();

    if (_trayMaxFillPercent > 40) {
      factor *= 0.93;
    }
    if (_trayHeightMm <= 50) {
      factor *= 0.96;
    }
    if (_selectedWorkingCondition == WorkingCondition.humid) {
      factor *= 0.97;
    }
    if (_selectedWorkingCondition == WorkingCondition.ground) {
      factor *= 0.95;
    }
    if (data.groupNumber >= 6) {
      factor *= 0.94;
    }

    return factor.clamp(0.5, 1.05);
  }

  _TrayCapacityResult _calculateTrayCapacity(CableData data) {
    final trayArea = _trayHeightMm * _trayWidthMm;
    final allowedArea = trayArea * (_trayMaxFillPercent / 100);
    final cableArea =
        _projectedCableAreaMm2(data).clamp(1, double.infinity).toDouble();
    final dbMass = _massFromDatabaseKgPerM(data);
    final cableMass = (dbMass ?? _estimatedCableMassKgPerM(data))
        .clamp(0.01, double.infinity);

    final spacingFactor = _isPowerCable(data) ? 1.15 : 1.05;
    final maxByFill = (allowedArea / (cableArea * spacingFactor)).floor();
    final maxByLoad = (_trayMaxLoadKgPerM / cableMass).floor();
    final thermalFactor = _thermalFactorForTray(data);

    final preThermal = math.max(0, math.min(maxByFill, maxByLoad));
    final maxByThermal = (preThermal * thermalFactor).floor();
    final finalCount = _isPowerCable(data)
        ? math.max(0, math.min(preThermal, maxByThermal))
        : preThermal;

    return _TrayCapacityResult(
      maxByFill: math.max(0, maxByFill),
      maxByLoad: math.max(0, maxByLoad),
      maxByThermal: math.max(0, maxByThermal),
      finalCount: finalCount,
      cableMassKgPerM: cableMass,
      cableAreaMm2: cableArea,
      thermalFactor: thermalFactor,
      isPowerCable: _isPowerCable(data),
      massFromDatabase: dbMass != null,
      tempCorrection: _temperatureCorrection(data),
      groupingCorrection: _groupingCorrection(),
      ventilationCorrection: _ventilationCorrection(),
    );
  }

  String _trayLimitingFactor(_TrayCapacityResult result) {
    if (result.finalCount <= 0) {
      return 'Brak miejsca lub za duze obciazenie';
    }
    if (result.maxByFill <= result.maxByLoad &&
        (!result.isPowerCable || result.maxByFill <= result.maxByThermal)) {
      return 'Limit zajetosci koryta';
    }
    if (result.maxByLoad <= result.maxByFill &&
        (!result.isPowerCable || result.maxByLoad <= result.maxByThermal)) {
      return 'Limit obciazenia kg/m';
    }
    if (result.isPowerCable) {
      return 'Limit termiczny (grzanie kabli)';
    }
    return 'Warunki mieszane';
  }

  String _substrateLabel(_MountingSubstrate substrate) {
    switch (substrate) {
      case _MountingSubstrate.concrete:
        return 'Beton';
      case _MountingSubstrate.steel:
        return 'Stal';
      case _MountingSubstrate.masonry:
        return 'Mur/cegla';
    }
  }

  int _nearestClipSize(double cableDiameterMm, List<int> sizes) {
    // Prefer tight fit: minimal functional clearance for assembly.
    final target = cableDiameterMm + 0.2;
    for (final size in sizes) {
      if (target <= size) {
        return size;
      }
    }
    return sizes.last;
  }

  String _celoPinRecommendation(_MountingSubstrate substrate) {
    switch (substrate) {
      case _MountingSubstrate.concrete:
        return 'Gwozdzie do betonu (dobor dlugosci wg podloza i osadzaka).';
      case _MountingSubstrate.steel:
        return 'Gwozdzie do stali (dobor typu wg grubosci blachy).';
      case _MountingSubstrate.masonry:
        return 'Mur/cegla: mocowanie strzelane tylko warunkowo; zwykle lepiej kotwa/mechaniczne.';
    }
  }

  String _celoShotFiredSelection(double cableDiameterMm) {
    const celoClipSeries = [8, 10, 12, 14, 16, 20, 25, 30];
    final size = _nearestClipSize(cableDiameterMm, celoClipSeries);
    final clearance = size - cableDiameterMm;
    final fitNote = clearance <= 0.8
        ? 'wariant ciasny (minimalny luz montazowy)'
        : 'przy wiekszym luzie dodaj przekladke/wkladke dociskowa';
    final looseCableWarning = clearance > 1.2
        ? 'Uwaga: przy blaszce wiekszej od srednicy zewnetrznej kabla moze pojawic sie luz; zalecana jest weryfikacja srednicy kabla i doboru elementu mocujacego.'
        : null;
    return 'PFT $size (pojedyncza) / DFT $size (podwojna), $fitNote${looseCableWarning != null ? '. $looseCableWarning' : ''}';
  }

  String _hiltiPinRecommendation(_MountingSubstrate substrate) {
    switch (substrate) {
      case _MountingSubstrate.concrete:
        return 'Gwozdzie X-U (dlugosc dobierz wg podloza i geometrii uchwytu).';
      case _MountingSubstrate.steel:
        return 'Gwozdzie X-P do stali (dobor wg grubosci blachy).';
      case _MountingSubstrate.masonry:
        return 'Mur/cegla: mocowanie strzelane tylko po probie; przewaznie mocowanie kotwione.';
    }
  }

  String _hiltiShotFiredSelection(double cableDiameterMm) {
    if (cableDiameterMm <= 10) {
      return 'X-EKSC M8 (pojedynczy kabel)';
    }
    if (cableDiameterMm <= 14) {
      return 'X-EKSC M10 (pojedynczy kabel)';
    }
    if (cableDiameterMm <= 22) {
      return 'X-ECT-M M16 (mocowanie trasy/przewiazki)';
    }
    return 'X-ECT-M M20 (mocowanie trasy/przewiazki)';
  }

  String _shotFiredSubstrateNote(_MountingSubstrate substrate) {
    switch (substrate) {
      case _MountingSubstrate.concrete:
        return 'Podloze beton: dobieraj systemowe gwozdzie producenta pod osadzak i klase betonu.';
      case _MountingSubstrate.steel:
        return 'Podloze stal: stosowac gwozdzie dedykowane do stali i kontrolowac grubosc blachy.';
      case _MountingSubstrate.masonry:
        return 'Podloze murowe: osprzet strzelany tylko po weryfikacji podloza; czesto lepszy montaz kotwiony.';
    }
  }

  double _largestCableDimensionMm(CableData data) {
    final flat = _flatDimensions(data);
    if (flat == null) {
      return data.outerDiameter;
    }
    return math.max(flat.a, flat.b);
  }

  int _selectNominalSize(double requiredMm, List<int> series) {
    for (final value in series) {
      if (value >= requiredMm) {
        return value;
      }
    }
    return series.isNotEmpty ? series.last : requiredMm.ceil();
  }

  /// Zakresy wg typowych katalogów (można doprecyzować pod producenta):
  /// PG7: 3–6.5 mm
  /// PG9: 4–8 mm
  /// PG11: 5–10 mm
  /// PG13.5: 6–12 mm
  /// PG16: 10–14 mm
  /// PG21: 13–18 mm
  /// PG29: 18–25 mm
  /// PG36: 25–33 mm
  /// PG42: 32–38 mm
  String _selectPgGland(double cableDiameterMm) {
    if (cableDiameterMm <= 6.5) return 'PG7';
    if (cableDiameterMm <= 8) return 'PG9';
    if (cableDiameterMm <= 10) return 'PG11';
    if (cableDiameterMm <= 12) return 'PG13.5';
    if (cableDiameterMm <= 14) return 'PG16';
    if (cableDiameterMm <= 18) return 'PG21';
    if (cableDiameterMm <= 25) return 'PG29';
    if (cableDiameterMm <= 33) return 'PG36';
    if (cableDiameterMm <= 38) return 'PG42';
    return 'PG48';
  }

  bool _requiresShotFiredMounting(CableData data) {
    return data.application == CableApplication.fireproof ||
        data.application == CableApplication.control ||
        data.type == CableType.h07rnf ||
        data.type == CableType.htksh;
  }

  bool _supportsUnderPlasterFlatClips(CableData data) {
    return _isFlatCable(data) &&
        data.application == CableApplication.electrical &&
        data.groupNumber == 1;
  }

  bool _needsArotForGroundPower(CableData data) {
    final isGround = _selectedWorkingCondition == WorkingCondition.ground;
    final isPower = data.application == CableApplication.electrical ||
        data.application == CableApplication.mediumVoltage;
    final largeCrossSection = data.crossSection >= 16;
    final typeName = data.type.name.toLowerCase();
    final preferredType = typeName.contains('yky') ||
        typeName.contains('yaky') ||
        typeName.contains('hakxs') ||
        typeName.contains('a2xsy') ||
        typeName.contains('na2xsy');

    return isGround && isPower && (largeCrossSection || preferredType);
  }

  List<_OfferRecommendationGroup> _buildOfferRecommendationGroups(
    CableData data,
    List<HeatShrinkTube> suggestedTubes,
    List<int> rigidConduits,
  ) {
    final groups = <_OfferRecommendationGroup>[];
    final largestDim = _largestCableDimensionMm(data);
    final corrugatedSeries = [16, 20, 25, 32, 40, 50, 63, 75, 90];
    final arotSeries = [50, 63, 75, 90, 110, 125, 160];
    final corrugatedNominal = _selectNominalSize(largestDim * 1.4, corrugatedSeries);
    final arotNominal = _selectNominalSize(largestDim * 1.7, arotSeries);
    final shotFiredRequired = _requiresShotFiredMounting(data);
    final flatCable = _isFlatCable(data);
    final flatUnderPlasterAllowed = _supportsUnderPlasterFlatClips(data);

    // FLAT CABLES: Only under-plaster clips, no glands/dławiki
    if (flatCable) {
      // Determine single/double cable for USMP model
      final isDouble = (data.notes?.contains('2x') ?? false) || (data.usage?.contains('2x') ?? false);
      final singleModel = 'USMP-3';
      final doubleModel = 'USMP-3 BIS';
      groups.add(
        _OfferRecommendationGroup(
          title: 'Uchwyty podtynkowe do kabli płaskich',
          icon: Icons.push_pin,
          items: [
            'Pojedynczy kabel: $singleModel (Elektro-Plast Opatówek)',
            'Podwójny kabel: $doubleModel (Elektro-Plast Opatówek)',
            'Dobierz model wg szerokości kabla i liczby żył; patrz katalog producenta.',
            'Mocowanie co 30-40 cm, gęściej przy załamaniach trasy.',
          ],
          note: 'Dla kabli płaskich YDYp, YDYt, itp. – stosuj wyłącznie uchwyty podtynkowe USMP serii Elektro-Plast Opatówek. Nie stosować dławików.',
        ),
      );
      return groups;
    }

    // NON-FLAT: Standard logic (including glands/dławiki)
    final pgSize = _selectPgGland(largestDim);
    if (shotFiredRequired) {
      groups.add(
        _OfferRecommendationGroup(
          title: 'Mocowanie strzelane',
          icon: Icons.construction,
          items: [
            'Uchwyty szybkiego montażu płaskie: USMP-1, USMP-2, USMP-3 BIS, USMP-4, USMP-5, USMP-6, USMP-7, USMP-8, USMP-9, USMP-10 (dobierz rozmiar do szerokości kabla; np. USMP-3 BIS do 2x YDYp 3x1,5/3x2,5)',
            'Podloze montazowe: ${_substrateLabel(_mountingSubstrate)}',
            'Rozstaw montazu: zgodnie z dokumentacja producenta systemu mocujacego oraz projektem trasy',
          ],
          note:
              'Dla pojedynczych przewodów na blaszkach/obejmach w praktyce często stosuje się rozstaw 25–30 cm, ale ostateczny dobór należy potwierdzić w projekcie i dokumentacji systemu mocującego.',
        ),
      );
    }

    groups.add(
      _OfferRecommendationGroup(
        title: 'Dławiki skręcane typu PG',
        icon: Icons.settings_input_component,
        items: [
          'Zalecany rozmiar: $pgSize',
          'Alternatywa: ${_selectPgGland(largestDim * 1.1)} (wiekszy zakres zacisku)',
          'Wersja IP68 dla stref wilgotnych i zewnetrznych',
        ],
      ),
    );

    // Pokazuj tylko jedną najbardziej odpowiednią opcję rury termokurczliwej
    String? bestTube;
    if (suggestedTubes.isNotEmpty) {
      bestTube = 'Katalogowe dopasowanie: ${suggestedTubes.first.description}';
    } else if ((data.heatShrinkSleeve ?? '').isNotEmpty) {
      bestTube = 'Podstawowa: ${data.heatShrinkSleeve}';
    } else if ((data.heatShrinkLabel ?? '').isNotEmpty) {
      bestTube = 'Alternatywa/znacznik: ${data.heatShrinkLabel}';
    }
    if (bestTube != null) {
      groups.add(
        _OfferRecommendationGroup(
          title: 'Rury termokurczliwe',
          icon: Icons.bolt,
          items: [bestTube],
        ),
      );
    }

    if (!shotFiredRequired) {
      groups.add(
        _OfferRecommendationGroup(
          title: 'Rury oslonowe sztywne',
          icon: Icons.straighten,
          items: [
            if (rigidConduits.isNotEmpty)
              'Podstawowa: DN ${rigidConduits.first} mm',
            if (rigidConduits.length > 1)
              'Alternatywa: DN ${rigidConduits[1]} mm',
            if (rigidConduits.isEmpty)
              'Brak jednoznacznej pozycji - sprawdz trase recznie',
          ],
        ),
      );

      groups.add(
        _OfferRecommendationGroup(
          title: 'Rury oslonowe karbowane',
          icon: Icons.waves,
          items: [
            'Peszel/karbowana: fi $corrugatedNominal mm',
            'Alternatywa: fi ${_selectNominalSize(corrugatedNominal * 1.2, corrugatedSeries).toInt()} mm',
            'Wersja UV lub HF dla tras zewnetrznych / halogen free',
          ],
        ),
      );
    }

    if (_needsArotForGroundPower(data)) {
      groups.add(
        _OfferRecommendationGroup(
          title: 'Rury dwuwarstwowe AROT (ziemia)',
          icon: Icons.route,
          items: [
            'Podstawowa: AROT DN $arotNominal',
            'Alternatywa: AROT DN ${_selectNominalSize(arotNominal * 1.2, arotSeries).toInt()}',
            'Stosowac z uszczelnieniem koncow i tasma ostrzegawcza',
          ],
          note:
              'Dodatkowo rekomendowane dla duzych przekrojow kabli ziemnych (np. YKY/YAKY/YHAKXS).',
        ),
      );
    }

    if (flatUnderPlasterAllowed && !shotFiredRequired) {
      groups.add(
        _OfferRecommendationGroup(
          title: 'Uchwyty podtynkowe dla kabli plaskich',
          icon: Icons.push_pin,
          items: [
            'Uchwyt pojedynczy: pod ${_externalDimensionValue(data)}',
            'Uchwyt podwojny: dla prowadzenia rownoleglego 2x kabel',
            'Mocowanie co 30-40 cm, gestsze przy zalamaniach trasy',
          ],
        ),
      );
    }

    return groups;
  }

  Future<void> _copyResultToClipboard(CableData data) async {
    final dimensionLabel =
        _isFlatCable(data) ? 'Wymiary zewnetrzne' : 'Srednica zewnetrzna';
    final tubeStandard = CableDataProvider.suggestTubeStandardForCondition(
      _selectedWorkingCondition,
    );
    final suggestedTubes = _tubeRecommendationsForReserve(data);
    final rigidConduits = _rigidConduitsForReserve(data);
    final confidence = _confidenceLabel(data, suggestedTubes, rigidConduits);
    final reason = _recommendationReason(data, tubeStandard, suggestedTubes);
    final warnings = _buildRecommendationWarnings(
      data,
      suggestedTubes,
      rigidConduits,
      tubeStandard,
    );
    final rigidStandard = rigidConduits.isNotEmpty
        ? 'DN ${rigidConduits.first} mm'
        : 'Brak standardu';
    final offerGroups = _buildOfferRecommendationGroups(
      data,
      suggestedTubes,
      rigidConduits,
    );
    final trayCapacity = _calculateTrayCapacity(data);


    final textParts = <String>[];
    textParts.add('Zalecane materiały');
    textParts.add('Profil pracy: ${_profileTitle(_selectedMaterialProfile)}');
    textParts.add('Warunki pracy: ${CableData.workingConditionToString(_selectedWorkingCondition)}');
    textParts.add('Zapas montażowy: ${_materialReservePercent.toStringAsFixed(0)}%');
    if (confidence == 'Do weryfikacji') {
      textParts.add('⚠️ Dobór materiałów wymaga weryfikacji!');
    }
    if (suggestedTubes.isNotEmpty) {
      textParts.add('Rura termokurczliwa: ${suggestedTubes.first.description}');
    } else {
      textParts.add('⚠️ Brak dopasowania rury termokurczliwej – sprawdź ręcznie!');
    }
    if (rigidConduits.isNotEmpty) {
      textParts.add('Rura sztywna: DN ${rigidConduits.first} mm');
    } else {
      textParts.add('⚠️ Brak dopasowania rury sztywnej – sprawdź trasę!');
    }
    if (offerGroups.isNotEmpty) {
      for (final group in offerGroups) {
        textParts.add('- ${group.title}: ${group.items.join(' | ')}');
        if (group.note != null && group.note!.trim().isNotEmpty) {
          textParts.add('  Uwaga: ${group.note!}');
        }
      }
    }
    if (warnings.isNotEmpty) {
      textParts.add('Ostrzeżenia: ${warnings.join(' | ')}');
    }
    if (_recommendationChangeReason != null) {
      textParts.add(_recommendationChangeReason!);
    }
    final text = textParts.join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parametry kabla skopiowane do schowka.')),
    );
  }

  Future<void> _copyRecommendedMaterialsSet(CableData data) async {
    final tubeStandard = CableDataProvider.suggestTubeStandardForCondition(
      _selectedWorkingCondition,
    );
    final suggestedTubes = _tubeRecommendationsForReserve(data);
    final rigidConduits = _rigidConduitsForReserve(data);
    final rigidStandard =
        rigidConduits.isNotEmpty ? 'DN ${rigidConduits.first} mm' : '-';
    final offerGroups = _buildOfferRecommendationGroups(
      data,
      suggestedTubes,
      rigidConduits,
    );
    final trayCapacity = _calculateTrayCapacity(data);

    final kitLines = <String>[
      'Zestaw materialow',
      'Profil: ${_profileTitle(_selectedMaterialProfile)}',
      'Warunki pracy: ${CableData.workingConditionToString(_selectedWorkingCondition)}',
      'Zapas montazowy: ${_materialReservePercent.toStringAsFixed(0)}%',
      'Standard rury: ${HeatShrinkTube.standardToString(tubeStandard)}',
      'Rura termokurczliwa: ${data.heatShrinkSleeve} / ${data.heatShrinkLabel}',
      'Standard rury sztywnej: $rigidStandard',
      'Rura termokurczliwa: ${suggestedTubes.isNotEmpty ? suggestedTubes.first.description : '-'}',
      'Rura termokurczliwa lub: ${suggestedTubes.length > 1 ? suggestedTubes[1].description : '-'}',
      'Rura sztywna: ${rigidConduits.isNotEmpty ? 'DN ${rigidConduits.first} mm' : '-'}',
      'Rura sztywna lub: ${rigidConduits.length > 1 ? 'DN ${rigidConduits[1]} mm' : '-'}',
      if (offerGroups.isNotEmpty) ...[
        '',
        'Akcesoria i osprzet montazowy:',
        'Podloze montazowe: ${_substrateLabel(_mountingSubstrate)}',
        ...offerGroups.map((group) =>
            '- ${group.title}: ${group.items.join(' | ')}${group.note != null ? ' [${group.note}]' : ''}'),
      ],
      '',
      'Koryto kablowe: ${_trayWidthMm.toInt()}x${_trayHeightMm.toInt()} mm',
      _trayNormReference,
      'Maks. zajetosc: ${_trayMaxFillPercent.toStringAsFixed(0)}%',
      'Maks. obciazenie: ${_trayMaxLoadKgPerM.toStringAsFixed(1)} kg/m',
      'Temp. otoczenia: ${_trayAmbientTempC.toStringAsFixed(0)} C',
      'Liczba obwodow zasilajacych: $_trayGroupedPowerCircuits',
      'Koryto wentylowane: ${_trayVentilated ? 'tak' : 'nie'}',
      'Mozliwa liczba kabli: ${trayCapacity.finalCount} szt.',
      if (trayCapacity.isPowerCable)
        'Korekty: kt=${trayCapacity.tempCorrection.toStringAsFixed(2)}, kg=${trayCapacity.groupingCorrection.toStringAsFixed(2)}, kv=${trayCapacity.ventilationCorrection.toStringAsFixed(2)}',
      'Masa kabla: ${trayCapacity.cableMassKgPerM.toStringAsFixed(2)} kg/m (${trayCapacity.massFromDatabase ? 'z bazy' : 'szacowana'})',
      'Czynnik ograniczajacy: ${_trayLimitingFactor(trayCapacity)}',
    ];

    await Clipboard.setData(ClipboardData(text: kitLines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zestaw materialow skopiowany do schowka.')),
    );
  }

  void _onWireConfigurationSelected(WireConfiguration configuration) {
    setState(() {
      _selectedWireConfiguration = configuration;
      _selectedCrossSection = null;
      _result = null;
    });
    _animationController.forward(from: 0);
  }

  void _onCrossSectionSelected(double crossSection) {
    if (_selectedWireConfiguration == null) {
      return;
    }

    setState(() {
      _selectedCrossSection = crossSection;
      if (_selectedMaterial != null && _selectedType != null) {
        final data = CableDataProvider.getCableDataByConfiguration(
          _selectedMaterial!,
          _selectedType!,
          crossSection,
          _selectedWireConfiguration!,
        );
        _result = data;
      }
    });
    _animationController.forward(from: 0);
  }

  List<WireConfiguration> _getAvailableWireConfigurations(CableType type) {
    if (_selectedMaterial == null) {
      return const [];
    }

    return CableDataProvider.getAvailableWireConfigurations(
      _selectedMaterial!,
      type,
    );
  }

  List<double> _getFilteredCrossSections() {
    if (_selectedMaterial == null || _selectedType == null) {
      return const [];
    }

    final crossSections = CableDataProvider.getAvailableCrossSections(
      _selectedMaterial!,
      _selectedType!,
      wireConfiguration: _selectedWireConfiguration,
    );
    return crossSections;
  }

  List<CableData> _getMatchingVariants() {
    if (_selectedMaterial == null ||
        _selectedType == null ||
        _selectedWireConfiguration == null ||
        _selectedCrossSection == null) {
      return const [];
    }

    return CableDataProvider.getCableVariantsByConfiguration(
      _selectedMaterial!,
      _selectedType!,
      _selectedCrossSection!,
      _selectedWireConfiguration!,
    );
  }

  void _onWorkingConditionSelected(WorkingCondition condition) {
    final data = _result;
    final before = data == null
        ? null
        : _buildRecommendationSnapshot(
            data,
            _selectedWorkingCondition,
            _materialReservePercent,
          );
    final nextReason = data == null || before == null
        ? null
        : _buildRecommendationDeltaMessage(
            before,
            _buildRecommendationSnapshot(
              data,
              condition,
              _materialReservePercent,
            ),
          );

    setState(() {
      _selectedWorkingCondition = condition;
      if (condition == WorkingCondition.interior) {
        _selectedMaterialProfile = _MaterialProfile.interior;
      } else if (condition == WorkingCondition.ground) {
        _selectedMaterialProfile = _MaterialProfile.underground;
      } else if (_selectedMaterialProfile == _MaterialProfile.interior ||
          _selectedMaterialProfile == _MaterialProfile.underground) {
        _selectedMaterialProfile = _MaterialProfile.outdoorUv;
      }
      _previousRecommendation = before;
      _recommendationChangeReason = nextReason;
    });
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baza Kabli i Przewodów'),
        backgroundColor: _deepNavy,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_deepNavy, const Color(0xFF1A2F42)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildApplicationSelection(),
                if (_selectedApplication != null) ...[
                  const SizedBox(height: 24),
                  _buildMaterialSelection(),
                ],
                if (_selectedMaterial != null) ...[
                  const SizedBox(height: 16),
                  _buildQuickAccessSection(),
                ],
                if (_selectedMaterial != null) ...[
                  const SizedBox(height: 24),
                  _buildTypeSelection(),
                ],
                if (_selectedType != null) ...[
                  const SizedBox(height: 24),
                  _buildWireConfigurationSelection(),
                ],
                if (_selectedType != null &&
                    _selectedWireConfiguration != null) ...[
                  const SizedBox(height: 24),
                  _buildCrossSectionSelection(),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 32),
                  _buildResult(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationSelection() {
    final applications = CableDataProvider.getAvailableApplications();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: applications.map((app) {
        final isSelected = _selectedApplication == app;
        return ScaleTransition(
          scale:
              isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
          child: InkWell(
            onTap: () => _onApplicationSelected(app),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? _electricBlue : _cardNavy,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _amber : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _electricBlue.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getApplicationIcon(app),
                    color: isSelected ? Colors.white : Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CableData.applicationToString(app),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaterialSelection() {
    if (_selectedApplication == null) {
      return const SizedBox.shrink();
    }

    final availableMaterials =
        _getAvailableMaterialsForApplication(_selectedApplication!);

    if (availableMaterials.isEmpty) {
      return Card(
        color: _cardNavy,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Brak dostepnych materialow dla wybranego zastosowania.',
            style: TextStyle(color: Colors.grey[300]),
          ),
        ),
      );
    }

    if (availableMaterials.length == 1) {
      final onlyMaterial = availableMaterials.first;
      final label =
          onlyMaterial == CableMaterial.cu ? 'Miedz (Cu)' : 'Aluminium (Al)';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Material zyly',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _amber,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _cardNavy,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: Row(
              children: [
                Icon(
                  onlyMaterial == CableMaterial.cu ? Icons.eco : Icons.hardware,
                  color: _amber,
                ),
                const SizedBox(width: 10),
                Text(
                  '$label (jedyny dostepny)',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wybierz materiał żyły',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _amber,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: availableMaterials.map((material) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: material == availableMaterials.first ? 6 : 0,
                  left: material == availableMaterials.last ? 6 : 0,
                ),
                child: _buildMaterialCard(material),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMaterialCard(CableMaterial material) {
    final isSelected = _selectedMaterial == material;
    final label =
        material == CableMaterial.cu ? 'Miedź (Cu)' : 'Aluminium (Al)';
    final icon = material == CableMaterial.cu ? Icons.eco : Icons.hardware;

    return ScaleTransition(
      scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
      child: InkWell(
        onTap: () => _onMaterialSelected(material),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? _electricBlue : _cardNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _amber : Colors.grey[700]!,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _electricBlue.withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[400],
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[300],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    final available = _getBaseTypesForCurrentSelection().toSet();
    final favorites = _favoriteTypes.where(available.contains).toList();
    final recent = _recentTypes.where(available.contains).toList();

    if (favorites.isEmpty && recent.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (favorites.isNotEmpty) ...[
          Text(
            'Ulubione typy',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _amber,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: favorites
                .map((type) => _buildQuickTypeChip(type, icon: Icons.star))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        if (recent.isNotEmpty) ...[
          Text(
            'Ostatnio uzywane',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[300],
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recent
                .map((type) => _buildQuickTypeChip(type, icon: Icons.history))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickTypeChip(CableType type, {required IconData icon}) {
    final isSelected = _selectedType == type;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: isSelected ? Colors.white : _amber),
      backgroundColor: isSelected ? _electricBlue : _cardNavy,
      side: BorderSide(color: isSelected ? _amber : Colors.grey[700]!),
      label: Text(
        CableData.typeToString(type),
        style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300]),
      ),
      onPressed: () => _onTypeSelected(type),
    );
  }

  Widget _buildTypeSelection() {
    final types = _getFilteredTypes();
    final quickSearches = const <String>[
      'yky',
      'n2xh',
      'utp6',
      'futp6',
      'kat6',
      '0.6/1kv',
      'b2ca',
    ];

    if (types.isEmpty) {
      return Card(
        color: _cardNavy,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Brak dostępnych typów kabli dla wybranego zastosowania i materiału',
            style: TextStyle(color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wyszukiwanie',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[300],
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _typeSearchController,
          onChanged: (value) {
            setState(() {
              _typeSearchQuery = value;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Szukaj (np. yky 3x2.5, n2xh b2ca, utp6)',
            labelStyle: TextStyle(color: Colors.grey[300]),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _typeSearchQuery.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Wyczysc wyszukiwanie',
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: _clearTypeSearch,
                  ),
            filled: true,
            fillColor: _cardNavy,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: quickSearches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final value = quickSearches[index];
              final selected =
                  _normalizeToken(_typeSearchQuery) == _normalizeToken(value);
              return ChoiceChip(
                label: Text(value),
                selected: selected,
                onSelected: (_) => _applyQuickSearchChip(value),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Wybierz typ kabla (${types.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _amber,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: types.map((type) {
            final isSelected = _selectedType == type;
            return ScaleTransition(
              scale: isSelected
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: InkWell(
                onTap: () => _onTypeSelected(type),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 280),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? _electricBlue : _cardNavy,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _amber : Colors.grey[700]!,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _electricBlue.withOpacity(0.4),
                              blurRadius: 8,
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              CableData.typeToString(type),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[300],
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CableData.typeGroupLabel(type),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _favoriteTypes.contains(type)
                            ? 'Usun z ulubionych'
                            : 'Dodaj do ulubionych',
                        onPressed: () => _toggleFavorite(type),
                        icon: Icon(
                          _favoriteTypes.contains(type)
                              ? Icons.star
                              : Icons.star_border,
                          color: _favoriteTypes.contains(type)
                              ? _amber
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWireConfigurationSelection() {
    final configurations = _getAvailableWireConfigurations(_selectedType!);

    if (configurations.isEmpty) {
      return Card(
        color: _cardNavy,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Brak wariantow ilosci zyl dla wybranego typu kabla.',
            style: TextStyle(color: Colors.grey[300]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wybierz ilość żył',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _amber,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: configurations.map((configuration) {
            final isSelected = _selectedWireConfiguration == configuration;
            return ScaleTransition(
              scale: isSelected
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: InkWell(
                onTap: () => _onWireConfigurationSelected(configuration),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _electricBlue : _cardNavy,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _amber : Colors.grey[700]!,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _electricBlue.withOpacity(0.4),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    CableData.wireConfigToString(configuration),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCrossSectionSelection() {
    final crossSections = _getFilteredCrossSections();

    if (crossSections.isEmpty) {
      return Card(
        color: _cardNavy,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Brak przekrojow dla wybranego typu i ilosci zyl.',
            style: TextStyle(color: Colors.grey[300]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wybierz przekrój [mm²]',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _amber,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: crossSections.map((cs) {
            final isSelected = _selectedCrossSection == cs;
            return ScaleTransition(
              scale: isSelected
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: InkWell(
                onTap: () => _onCrossSectionSelected(cs),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? _electricBlue : _cardNavy,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? _amber : Colors.grey[700]!,
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: _electricBlue.withOpacity(0.4),
                              blurRadius: 6,
                            )
                          ]
                        : null,
                  ),
                  child: Text(
                    cs.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();

    final selectedData = _result!;
    final matchingVariants = _getMatchingVariants();

    final tubeStandard = CableDataProvider.suggestTubeStandardForCondition(
      _selectedWorkingCondition,
    );
    final suggestedTubes = _tubeRecommendationsForReserve(selectedData);
    final rigidConduits = _rigidConduitsForReserve(selectedData);
    final confidence =
        _confidenceLabel(selectedData, suggestedTubes, rigidConduits);
    final recommendationReason =
        _recommendationReason(selectedData, tubeStandard, suggestedTubes);
    final recommendationWarnings = _buildRecommendationWarnings(
      selectedData,
      suggestedTubes,
      rigidConduits,
      tubeStandard,
    );
    final offerGroups = _buildOfferRecommendationGroups(
      selectedData,
      suggestedTubes,
      rigidConduits,
    );
    final shotFiredRequired = _requiresShotFiredMounting(selectedData);
    final trayCapacity = _calculateTrayCapacity(selectedData);
    final quality = _qualityLabel(selectedData);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_animationController),
      child: FadeTransition(
        opacity: _animationController,
        child: Card(
          color: _cardNavy,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _amber, width: 2),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _amber.withOpacity(0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: _amber, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Parametry techniczne',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _amber,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _qualityColor(quality).withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _qualityColor(quality)),
                      ),
                      child: Text(
                        quality,
                        style: TextStyle(
                          color: _qualityColor(quality),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kopiuj parametry',
                      onPressed: () => _copyResultToClipboard(_result!),
                      icon: const Icon(Icons.copy_all, color: Colors.white),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.grey),
                _buildResultRow(
                  'Grupa',
                  CableData.typeGroupLabel(_result!.type),
                  Icons.folder_open,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Typ kabla',
                  CableData.typeToString(_result!.type),
                  Icons.cable,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Zastosowanie',
                  CableData.applicationToString(_result!.application),
                  _getApplicationIcon(_result!.application),
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Materiał żyły',
                  CableData.materialToString(_result!.material),
                  Icons.eco,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Przekrój',
                  '${_result!.crossSection} mm²',
                  Icons.straighten,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Ilość żył',
                  CableData.wireConfigToString(_result!.wireConfiguration),
                  Icons.linear_scale,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Typ żyły',
                  CableData.coreTypeToString(_result!.coreType),
                  Icons.account_tree,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  _externalDimensionLabel(_result!),
                  _externalDimensionValue(_result!),
                  Icons.circle_outlined,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Napięcie max',
                  _result!.maxVoltage,
                  Icons.bolt,
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Zakres temperatur',
                  _result!.temperatureRange,
                  Icons.thermostat,
                ),
                if (matchingVariants.length > 1) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Wariant z bazy danych',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _amber,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: matchingVariants.map((variant) {
                      final selected = identical(variant, _result!);
                      return ChoiceChip(
                        label: Text(_variantTitle(variant)),
                        selected: selected,
                        onSelected: (_) {
                          setState(() {
                            _result = variant;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                if (_hasValue(_result!.cpr) ||
                    _hasValue(_result!.insulation) ||
                    _hasValue(_result!.halogenFree) ||
                    _hasValue(_result!.notes) ||
                    _hasValue(_result!.usage)) ...[
                  const SizedBox(height: 20),
                  if (_hasValue(_result!.cpr)) ...[
                    _buildResultRow(
                      'CPR/Ognioodpornosc',
                      _result!.cpr!.trim(),
                      Icons.local_fire_department,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasValue(_result!.insulation)) ...[
                    _buildResultRow(
                      'Izolacja/plaszcz',
                      _result!.insulation!.trim(),
                      Icons.layers,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasValue(_result!.halogenFree)) ...[
                    _buildResultRow(
                      'Halogen free',
                      _result!.halogenFree!.trim(),
                      Icons.shield,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasValue(_result!.usage)) ...[
                    _buildResultRow(
                      'Zastosowanie (zrodlo)',
                      _result!.usage!.trim(),
                      Icons.build,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hasValue(_result!.notes)) ...[
                    _buildResultRow(
                      'Uwagi',
                      _result!.notes!.trim(),
                      Icons.notes,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                const Divider(height: 32, color: Colors.grey),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Zalecane materiały',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: _amber,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _copyRecommendedMaterialsSet(selectedData),
                      icon: const Icon(Icons.inventory_2_outlined, size: 18),
                      label: const Text('Kopiuj zestaw'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Profile środowiska',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _MaterialProfile.values.map((profile) {
                    final isSelected = _selectedMaterialProfile == profile;
                    return ChoiceChip(
                      label: Text(_profileTitle(profile)),
                      selected: isSelected,
                      onSelected: (_) => _applyMaterialProfile(profile),
                      selectedColor: _electricBlue,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      avatar: Icon(
                        Icons.tune,
                        size: 14,
                        color: isSelected ? _amber : Colors.white54,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(
                  _profileHint(_selectedMaterialProfile),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CableDataProvider.getAvailableWorkingConditions()
                      .map(
                        (condition) => _buildWorkingConditionChip(condition),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Zapas montazowy: ${_materialReservePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Slider(
                  value: _materialReservePercent,
                  min: 10,
                  max: 35,
                  divisions: 5,
                  activeColor: _amber,
                  inactiveColor: Colors.grey[700],
                  label: '${_materialReservePercent.toStringAsFixed(0)}%',
                  onChanged: _onReserveChanged,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildConfidenceBadge(confidence),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendationReason,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_recommendationChangeReason != null) ...[
                  const SizedBox(height: 10),
                  _buildInfoBanner(
                    _previousRecommendation == null
                        ? _recommendationChangeReason!
                        : '${_recommendationChangeReason!} Poprzednio: ${_previousRecommendation!.standard}, ${_previousRecommendation!.topTube}.',
                    icon: Icons.compare_arrows,
                    borderColor: _electricBlue,
                  ),
                ],
                if (recommendationWarnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildInfoBanner(
                    recommendationWarnings.join(' '),
                    icon: Icons.warning_amber_rounded,
                    borderColor: const Color(0xFFFF6B6B),
                  ),
                ],
                if (offerGroups.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Akcesoria i osprzet montazowy',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (shotFiredRequired) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Podloze dla mocowania strzelanego',
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _MountingSubstrate.values.map((substrate) {
                        final selected = _mountingSubstrate == substrate;
                        return ChoiceChip(
                          label: Text(_substrateLabel(substrate)),
                          selected: selected,
                          onSelected: (_) {
                            setState(() {
                              _mountingSubstrate = substrate;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ...offerGroups.map(_buildOfferRecommendationGroupCard),
                ],
                const SizedBox(height: 18),
                _buildCableTraySection(selectedData, trayCapacity),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _electricBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(String confidence) {
    final color = _confidenceColor(confidence);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        'Pewność: $confidence',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoBanner(
    String text, {
    required IconData icon,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _deepNavy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withOpacity(0.75)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[200], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferRecommendationGroupCard(_OfferRecommendationGroup group) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _deepNavy,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(group.icon, color: _electricBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title,
                  style: TextStyle(
                    color: Colors.grey[200],
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...group.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '- $item',
                style: TextStyle(color: Colors.grey[300], fontSize: 12),
              ),
            ),
          ),
          if (group.note != null && group.note!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Uwaga: ${group.note!}',
              style: TextStyle(
                color: Colors.orange[200],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCableTraySection(CableData data, _TrayCapacityResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _deepNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _electricBlue.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Koryto kablowe',
            style: TextStyle(
              color: _amber,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _trayNormReference,
            style: TextStyle(color: Colors.grey[400], fontSize: 11),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trayPresets.map((preset) {
              final selected = _trayHeightMm == preset.heightMm &&
                  _trayWidthMm == preset.widthMm;
              return ChoiceChip(
                label: Text(preset.label),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    _trayHeightMm = preset.heightMm;
                    _trayWidthMm = preset.widthMm;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            'Rozmiar koryta',
            '${_trayWidthMm.toInt()}x${_trayHeightMm.toInt()} mm',
            Icons.view_week,
          ),
          const SizedBox(height: 10),
          Text(
            'Maks. zajetosc: ${_trayMaxFillPercent.toStringAsFixed(0)}%',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          if (_trayMaxFillPercent > 50)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                'Ostrzeżenie: Zajętość koryta przekracza 50%. Zalecane maksimum wg PN-EN 61537:2007 i praktyki branżowej to 40–50%. Przekroczenie może prowadzić do przegrzewania kabli i problemów z montażem.',
                style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Slider(
            value: _trayMaxFillPercent,
            min: 25,
            max: 60,
            divisions: 7,
            activeColor: _amber,
            inactiveColor: Colors.grey[700],
            label: '${_trayMaxFillPercent.toStringAsFixed(0)}%',
            onChanged: (value) {
              setState(() {
                _trayMaxFillPercent = value;
              });
            },
          ),
          Text(
            'Maks. obciazenie: ${_trayMaxLoadKgPerM.toStringAsFixed(1)} kg/m',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          Slider(
            value: _trayMaxLoadKgPerM,
            min: 5,
            max: 120,
            divisions: 23,
            activeColor: _amber,
            inactiveColor: Colors.grey[700],
            label: '${_trayMaxLoadKgPerM.toStringAsFixed(1)} kg/m',
            onChanged: (value) {
              setState(() {
                _trayMaxLoadKgPerM = value;
              });
            },
          ),
          Text(
            'Temp. otoczenia: ${_trayAmbientTempC.toStringAsFixed(0)} C',
            style: TextStyle(color: Colors.grey[300], fontSize: 12),
          ),
          Slider(
            value: _trayAmbientTempC,
            min: 20,
            max: 55,
            divisions: 7,
            activeColor: _amber,
            inactiveColor: Colors.grey[700],
            label: '${_trayAmbientTempC.toStringAsFixed(0)} C',
            onChanged: (value) {
              setState(() {
                _trayAmbientTempC = value;
              });
            },
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liczba obwodow zasilajacych: $_trayGroupedPowerCircuits',
                      style: TextStyle(color: Colors.grey[300], fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Adnotacja: Liczba obwodów zasilających oznacza ilość niezależnych obwodów energetycznych prowadzonych wspólnie w jednym korycie. Wartość ta wpływa na współczynnik korekcyjny prądów obciążenia (wg PN-EN 61537:2007).',
                      style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Zmniejsz',
                onPressed: _trayGroupedPowerCircuits > 1
                    ? () {
                        setState(() {
                          _trayGroupedPowerCircuits -= 1;
                        });
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                tooltip: 'Zwieksz',
                onPressed: _trayGroupedPowerCircuits < 6
                    ? () {
                        setState(() {
                          _trayGroupedPowerCircuits += 1;
                        });
                      }
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _trayVentilated,
            activeColor: _amber,
            title: const Text(
              'Koryto wentylowane',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            subtitle: Text(
              _trayVentilated
                  ? 'Koryto perforowane/siatkowe/drabinkowe (z otworami, lepsze chlodzenie kabli)'
                  : 'Koryto zamkniete/pelne (bez otworow – silniejsze korekty termiczne)',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
            onChanged: (value) {
              setState(() {
                _trayVentilated = value;
              });
            },
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _cardNavy,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _amber.withOpacity(0.8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'W wybranym korycie zmiesci sie: ${result.finalCount} szt. (${CableData.typeToString(data.type)})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Limit zajetosci: ${result.maxByFill} szt. | limit obciazenia: ${result.maxByLoad} szt.',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                if (result.isPowerCable)
                  Text(
                    'Limit termiczny: ${result.maxByThermal} szt. (wspolczynnik ${result.thermalFactor.toStringAsFixed(2)})',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                if (result.isPowerCable)
                  Text(
                    'Korekty normatywne: kt=${result.tempCorrection.toStringAsFixed(2)}, kg=${result.groupingCorrection.toStringAsFixed(2)}, kv=${result.ventilationCorrection.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.grey[300], fontSize: 12),
                  ),
                Text(
                  'Czynnik ograniczajacy: ${_trayLimitingFactor(result)}',
                  style: TextStyle(color: Colors.grey[300], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masa kabla: ${result.cableMassKgPerM.toStringAsFixed(2)} kg/m (${result.massFromDatabase ? 'z bazy' : 'szacowana'})',
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingConditionChip(WorkingCondition condition) {
    final isSelected = _selectedWorkingCondition == condition;
    return InkWell(
      onTap: () => _onWorkingConditionSelected(condition),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _electricBlue : _deepNavy,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _amber : Colors.grey[700]!,
            width: 1.5,
          ),
        ),
        child: Text(
          CableData.workingConditionToString(condition),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  IconData _getApplicationIcon(CableApplication app) {
    switch (app) {
      case CableApplication.electrical:
        return Icons.power;
      case CableApplication.mediumVoltage:
        return Icons.bolt;
      case CableApplication.fireproof:
        return Icons.local_fire_department;
      case CableApplication.control:
        return Icons.settings_remote;
      case CableApplication.telecom:
        return Icons.phone;
      case CableApplication.power:
        return Icons.electrical_services;
      case CableApplication.industrial:
        return Icons.factory;
    }
  }
}
