import 'package:flutter/material.dart';
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
  CableType? _selectedType;
  double? _selectedCrossSection;
  CableData? _result;

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
      _selectedType = null;
      _selectedCrossSection = null;
      _result = null;
    });
    _animationController.forward(from: 0);
  }

  void _onMaterialSelected(CableMaterial material) {
    setState(() {
      _selectedMaterial = material;
      _selectedType = null;
      _selectedCrossSection = null;
      _result = null;
    });
    _animationController.forward(from: 0);
  }

  void _onTypeSelected(CableType type) {
    setState(() {
      _selectedType = type;
      _selectedCrossSection = null;
      _result = null;
    });
    _animationController.forward(from: 0);
  }

  void _onCrossSectionSelected(double crossSection) {
    setState(() {
      _selectedCrossSection = crossSection;
      if (_selectedMaterial != null && _selectedType != null) {
        _result = CableDataProvider.getCableData(
          _selectedMaterial!,
          _selectedType!,
          crossSection,
        );
      }
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
                  'Wybierz zastosowanie kabla',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildApplicationSelection(),
                if (_selectedApplication != null) ...[
                  const SizedBox(height: 24),
                  _buildMaterialSelection(),
                ],
                if (_selectedMaterial != null) ...[
                  const SizedBox(height: 24),
                  _buildTypeSelection(),
                ],
                if (_selectedType != null) ...[
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

  Widget _buildTypeSelection() {
    final types = CableDataProvider.getTypesByApplicationAndMaterial(
      _selectedApplication!,
      _selectedMaterial!,
    );

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Text(
                    CableData.typeToString(type),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
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
    final crossSections = CableDataProvider.getAvailableCrossSections(
      _selectedMaterial!,
      _selectedType!,
    );

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
                  ],
                ),
                const Divider(height: 32, color: Colors.grey),
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

  IconData _getApplicationIcon(CableApplication app) {
    switch (app) {
      case CableApplication.electrical:
        return Icons.power;
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
