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
  String _typeSearchQuery = '';
  CableType? _selectedType;
  WireConfiguration? _selectedWireConfiguration;
  double? _selectedCrossSection;
  WorkingCondition _selectedWorkingCondition = WorkingCondition.interior;
  CableData? _result;
  final Set<CableType> _favoriteTypes = <CableType>{};
  final List<CableType> _recentTypes = <CableType>[];

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onApplicationSelected(CableApplication app) {
    setState(() {
      _selectedApplication = app;
      _selectedMaterial = null;
      _selectedGroupNumber = null;
      _typeSearchQuery = '';
      _selectedType = null;
      _selectedWireConfiguration = null;
      _selectedCrossSection = null;
      _result = null;
    });
    _animationController.forward(from: 0);
  }

  void _onMaterialSelected(CableMaterial material) {
    setState(() {
      _selectedMaterial = material;
      _selectedGroupNumber = null;
      _typeSearchQuery = '';
      _selectedType = null;
      _selectedWireConfiguration = null;
      _selectedCrossSection = null;
      _result = null;
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
    final query = _typeSearchQuery.trim().toLowerCase();
    return _getBaseTypesForCurrentSelection().where((type) {
      if (_selectedGroupNumber != null &&
          CableData.typeGroupNumber(type) != _selectedGroupNumber) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        CableData.typeToString(type),
        CableData.typeGroupLabel(type),
        type.name,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  String _qualityLabel(CableData data) {
    if (data.groupNumber >= 6) {
      return 'Do weryfikacji';
    }
    return 'Przyblizone';
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
    final text = [
      'Typ: ${CableData.typeToString(data.type)}',
      'Grupa: ${CableData.typeGroupLabel(data.type)}',
      'Zastosowanie: ${CableData.applicationToString(data.application)}',
      'Material: ${CableData.materialToString(data.material)}',
      'Ilosc zyl: ${CableData.wireConfigToString(data.wireConfiguration)}',
      'Przekroj: ${data.crossSection} mm2',
      'Srednica zewnetrzna: ~${data.outerDiameter} mm',
      'Termokurcz oslonowy: ${data.heatShrinkSleeve}',
      'Termokurcz znacznikowy: ${data.heatShrinkLabel}',
    ].join('\n');

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
        final data = CableDataProvider.getCableData(
          _selectedMaterial!,
          _selectedType!,
          crossSection,
        );
        _result = data?.wireConfiguration == _selectedWireConfiguration
            ? data
            : null;
      }
    });
    _animationController.forward(from: 0);
  }

  List<WireConfiguration> _getAvailableWireConfigurations(CableType type) {
    if (_selectedMaterial == null) {
      return const [];
    }

    final crossSections = CableDataProvider.getAvailableCrossSections(
      _selectedMaterial!,
      type,
    );

    final configurations = crossSections
        .map(
          (cs) => CableDataProvider.getCableData(
            _selectedMaterial!,
            type,
            cs,
          )?.wireConfiguration,
        )
        .whereType<WireConfiguration>()
        .toSet()
        .toList();

    configurations.sort((a, b) => a.index.compareTo(b.index));
    return configurations;
  }

  List<double> _getFilteredCrossSections() {
    if (_selectedMaterial == null || _selectedType == null) {
      return const [];
    }

    final crossSections = CableDataProvider.getAvailableCrossSections(
      _selectedMaterial!,
      _selectedType!,
    );

    if (_selectedWireConfiguration == null) {
      return const [];
    }

    return crossSections.where((cs) {
      final data = CableDataProvider.getCableData(
        _selectedMaterial!,
        _selectedType!,
        cs,
      );
      return data?.wireConfiguration == _selectedWireConfiguration;
    }).toList();
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

  Widget _buildApplicationSelection() {
    final applications = CableDataProvider.getAvailableApplications();
    
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: applications.map((app) {
        final isSelected = _selectedApplication == app;
        return ScaleTransition(
          scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          children: [
            Expanded(
              child: _buildMaterialCard(CableMaterial.cu),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMaterialCard(CableMaterial.al),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMaterialCard(CableMaterial material) {
    final isSelected = _selectedMaterial == material;
    final label = material == CableMaterial.cu ? 'Miedź (Cu)' : 'Aluminium (Al)';
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
    final types = _getFilteredTypes();

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
          'Filtr grupy',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[300],
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Wszystkie'),
              selected: _selectedGroupNumber == null,
              onSelected: (_) {
                setState(() {
                  _selectedGroupNumber = null;
                });
              },
            ),
            for (final group in groups)
              ChoiceChip(
                label: Text('Grupa $group'),
                selected: _selectedGroupNumber == group,
                onSelected: (_) {
                  setState(() {
                    _selectedGroupNumber = group;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: (value) {
            setState(() {
              _typeSearchQuery = value;
            });
          },
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Szukaj typu (np. YKY, NHXH, UTP)',
            labelStyle: TextStyle(color: Colors.grey[300]),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: _cardNavy,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Wybierz typ kabla',
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
              scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
              child: InkWell(
                onTap: () => _onTypeSelected(type),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  constraints: const BoxConstraints(minWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                color: isSelected ? Colors.white : Colors.grey[300],
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CableData.typeGroupLabel(type),
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white70 : Colors.grey[500],
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
              scale:
                  isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
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
              scale: isSelected ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
              child: InkWell(
                onTap: () => _onCrossSectionSelected(cs),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                        'Wynik doboru',
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
                  'Średnica zewnętrzna',
                  '${_result!.outerDiameter} mm',
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
                const Divider(height: 32, color: Colors.grey),
                Text(
                  'Warunki pracy',
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
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyResultToClipboard(_result!),
                    icon: const Icon(Icons.copy_all),
                    label: const Text('Kopiuj parametry'),
                  ),
                ),
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
