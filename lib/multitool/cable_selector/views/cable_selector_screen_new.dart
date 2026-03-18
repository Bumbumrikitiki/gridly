import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gridly/multitool/cable_selector/logic/cable_data_provider.dart';
import 'package:gridly/multitool/cable_selector/models/cable_data.dart';

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
  int? _selectedGroupNumber;
  String? _selectedVoltageFilter;
  String _typeSearchQuery = '';
  CableType? _selectedType;
  WireConfiguration? _selectedWireConfiguration;
  double? _selectedCrossSection;
  WorkingCondition _selectedWorkingCondition = WorkingCondition.interior;
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
      _selectedGroupNumber = null;
      _selectedVoltageFilter = null;
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
      _selectedGroupNumber = null;
      _selectedVoltageFilter = null;
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
      if (_selectedGroupNumber != null &&
          CableData.typeGroupNumber(type) != _selectedGroupNumber) {
        return false;
      }

      if (_selectedVoltageFilter != null &&
          !_typeMatchesVoltage(type, _selectedVoltageFilter!)) {
        return false;
      }

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

  int _activeFilterCount() {
    var count = 0;
    if (_selectedGroupNumber != null) {
      count += 1;
    }
    if (_selectedVoltageFilter != null) {
      count += 1;
    }
    if (_typeSearchQuery.trim().isNotEmpty) {
      count += 1;
    }
    return count;
  }

  void _applyQuickSearchChip(String value) {
    setState(() {
      _typeSearchQuery = value;
      _typeSearchController.text = value;
      _typeSearchController.selection =
          TextSelection.collapsed(offset: value.length);
    });
  }

  void _clearTypeFilters() {
    setState(() {
      _selectedGroupNumber = null;
      _selectedVoltageFilter = null;
      _typeSearchQuery = '';
      _typeSearchController.clear();
    });
  }

  void _openMobileFilterSheet(List<int> groups, List<String> voltages) {
    var tempGroup = _selectedGroupNumber;
    var tempVoltage = _selectedVoltageFilter;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, color: Colors.white),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Filtry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempGroup = null;
                              tempVoltage = null;
                            });
                          },
                          child: const Text('Wyczysc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Grupa',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Wszystkie'),
                          selected: tempGroup == null,
                          onSelected: (_) =>
                              setModalState(() => tempGroup = null),
                        ),
                        for (final group in groups)
                          ChoiceChip(
                            label: Text('Grupa $group'),
                            selected: tempGroup == group,
                            onSelected: (_) =>
                                setModalState(() => tempGroup = group),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Napiecie',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Wszystkie'),
                          selected: tempVoltage == null,
                          onSelected: (_) =>
                              setModalState(() => tempVoltage = null),
                        ),
                        for (final voltage in voltages)
                          ChoiceChip(
                            label: Text(voltage),
                            selected: tempVoltage == voltage,
                            onSelected: (_) =>
                                setModalState(() => tempVoltage = voltage),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedGroupNumber = tempGroup;
                            _selectedVoltageFilter = tempVoltage;
                          });
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Zastosuj'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _electricBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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

  Future<void> _copyResultToClipboard(CableData data) async {
    final dimensionLabel =
        _isFlatCable(data) ? 'Wymiary zewnetrzne' : 'Srednica zewnetrzna';
    final tubeStandard = CableDataProvider.suggestTubeStandardForCondition(
      _selectedWorkingCondition,
    );
    final suggestedTubes = CableDataProvider.suggestTubesForCable(
      data.outerDiameter,
      _selectedWorkingCondition,
    );
    final rigidConduits = CableDataProvider.suggestRigidConduitDiameters(
      data.outerDiameter,
    );

    final textParts = <String>[
      'Parametry techniczne',
      'Grupa: ${CableData.typeGroupLabel(data.type)}',
      'Typ kabla: ${CableData.typeToString(data.type)}',
      'Zastosowanie: ${CableData.applicationToString(data.application)}',
      'Material zyly: ${CableData.materialToString(data.material)}',
      'Przekroj: ${data.crossSection} mm2',
      'Ilosc zyl: ${CableData.wireConfigToString(data.wireConfiguration)}',
      'Typ zyly: ${CableData.coreTypeToString(data.coreType)}',
      '$dimensionLabel: ${_externalDimensionValue(data)}',
      'Napiecie max: ${data.maxVoltage}',
      'Zakres temperatur: ${data.temperatureRange}',
    ];

    if (_hasValue(data.cpr)) {
      textParts.add('CPR/Ognioodpornosc: ${data.cpr!.trim()}');
    }
    if (_hasValue(data.insulation)) {
      textParts.add('Izolacja/plaszcz: ${data.insulation!.trim()}');
    }
    if (_hasValue(data.halogenFree)) {
      textParts.add('Halogen free: ${data.halogenFree!.trim()}');
    }
    if (_hasValue(data.usage)) {
      textParts.add('Zastosowanie (zrodlo): ${data.usage!.trim()}');
    }
    if (_hasValue(data.notes)) {
      textParts.add('Uwagi: ${data.notes!.trim()}');
    }

    textParts.addAll([
      '',
      'Zalecane materialy',
      'Warunki pracy: ${CableData.workingConditionToString(_selectedWorkingCondition)}',
      'Standard rury: ${HeatShrinkTube.standardToString(tubeStandard)}',
      'Oslona (3:1): ${data.heatShrinkSleeve}',
      'Znacznik (2:1): ${data.heatShrinkLabel}',
    ]);

    if (suggestedTubes.isNotEmpty) {
      final tubeValues = suggestedTubes
          .take(4)
          .map((tube) => tube.description)
          .join(', ');
      textParts.add('Dopasowane srednice (z zapasem 20%): $tubeValues');
    }

    if (rigidConduits.isNotEmpty) {
      final conduitValues = rigidConduits.map((d) => 'DN $d mm').join(', ');
      textParts.add('Sugerowane rury sztywne (orientacyjnie): $conduitValues');
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
    setState(() {
      _selectedWorkingCondition = condition;
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
                _buildDatabaseInfoBanner(),
                const SizedBox(height: 12),
                Text(
                  'Baza kabli: szybkie wyszukiwanie',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Filtruj po: zastosowanie, grupa, typ, ilosc zyl, przekroj.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[300],
                      ),
                ),
                const SizedBox(height: 16),
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

  Widget _buildDatabaseInfoBanner() {
    final total = _databaseStats['totalRecords'] ?? 0;
    final imported = _databaseStats['localImportedRecords'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            _databaseInitialized ? Icons.storage : Icons.hourglass_top,
            color: _amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _databaseInitialized
                  ? 'Lokalna baza aktywna: $total rekordow (dodatkowe z assets: $imported).'
                  : 'Inicjalizacja lokalnej bazy danych...',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
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
    final groups = _getAvailableGroupNumbersForCurrentSelection();
    final voltages = _getAvailableVoltagesForCurrentSelection();
    final types = _getFilteredTypes();
    final activeFilters = _activeFilterCount();
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Wyszukiwanie i filtry',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[300],
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openMobileFilterSheet(groups, voltages),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                  activeFilters > 0 ? 'Filtry ($activeFilters)' : 'Filtry'),
            ),
            if (activeFilters > 0)
              TextButton(
                onPressed: _clearTypeFilters,
                child: const Text('Wyczysc'),
              ),
          ],
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
                    onPressed: () {
                      setState(() {
                        _typeSearchQuery = '';
                        _typeSearchController.clear();
                      });
                    },
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

    final matchingVariants = _getMatchingVariants();

    final tubeStandard = CableDataProvider.suggestTubeStandardForCondition(
      _selectedWorkingCondition,
    );
    final suggestedTubes = CableDataProvider.suggestTubesForCable(
      _result!.outerDiameter,
      _selectedWorkingCondition,
    );
    final rigidConduits =
        CableDataProvider.suggestRigidConduitDiameters(_result!.outerDiameter);
    final quality = _qualityLabel(_result!);

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
                Text(
                  'Zalecane materiały',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _amber,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CableDataProvider.getAvailableWorkingConditions()
                      .map(
                        (condition) => _buildWorkingConditionChip(condition),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                _buildResultRow(
                  'Standard rury',
                  HeatShrinkTube.standardToString(tubeStandard),
                  Icons.rule,
                ),
                const SizedBox(height: 8),
                _buildTubeStandardBadge(tubeStandard),
                const SizedBox(height: 16),
                Text(
                  'Rekomendowane rury',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _amber,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildResultRow(
                  'Osłona (3:1)',
                  _result!.heatShrinkSleeve,
                  Icons.water_drop,
                ),
                const SizedBox(height: 12),
                _buildResultRow(
                  'Znacznik (2:1)',
                  _result!.heatShrinkLabel,
                  Icons.label,
                ),
                if (suggestedTubes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Dopasowane średnice (z zapasem 20%)',
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
                    children: suggestedTubes
                        .take(4)
                        .map(
                          (tube) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _deepNavy,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[700]!),
                            ),
                            child: Text(
                              tube.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (rigidConduits.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sugerowane rury sztywne (orientacyjnie)',
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
                    children: rigidConduits
                        .map(
                          (d) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _deepNavy,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[700]!),
                            ),
                            child: Text(
                              'DN $d mm',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
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

  Widget _buildTubeStandardBadge(HeatShrinkStandard standard) {
    final color = _getTubeStandardColor(standard);
    final shortLabel = standard.name.toUpperCase();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color, width: 1.4),
        ),
        child: Text(
          shortLabel,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Color _getTubeStandardColor(HeatShrinkStandard standard) {
    switch (standard) {
      case HeatShrinkStandard.rc:
        return const Color(0xFF4FC3F7);
      case HeatShrinkStandard.rck:
        return _amber;
      case HeatShrinkStandard.rgk:
        return const Color(0xFFFF6B6B);
    }
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
