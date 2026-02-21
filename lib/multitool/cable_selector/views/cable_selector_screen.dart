import 'package:flutter/material.dart';
import 'package:gridly/multitool/cable_selector/logic/cable_data_provider.dart';
import 'package:gridly/multitool/cable_selector/models/cable_data.dart';

class CableSelectorScreen extends StatefulWidget {
  const CableSelectorScreen({super.key});

  @override
  State<CableSelectorScreen> createState() => _CableSelectorScreenState();
}

class _CableSelectorScreenState extends State<CableSelectorScreen> {
  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  CableMaterial? _selectedMaterial;
  CableType? _selectedType;
  double? _selectedCrossSection;
  CableData? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dobór rur termokurczliwych')),
      body: Container(
        color: _deepNavy,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Wybierz parametry przewodu/kabla',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 24),
                _buildMaterialDropdown(),
                const SizedBox(height: 16),
                if (_selectedMaterial != null) ...[
                  _buildTypeDropdown(),
                  const SizedBox(height: 16),
                ],
                if (_selectedType != null) ...[
                  _buildCrossSectionDropdown(),
                  const SizedBox(height: 24),
                ],
                if (_result != null) ...[_buildResultCard()],
                const SizedBox(height: 20),
                Text(
                  'Uwaga: średnica zewnętrzna kabla może się nieznacznie różnić w zależności od producenta i konstrukcji przewodu.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialDropdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Materiał przewodnika',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CableMaterial>(
            initialValue: _selectedMaterial,
            dropdownColor: _cardNavy,
            decoration: InputDecoration(
              filled: true,
              fillColor: _deepNavy,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text(
              'Wybierz materiał',
              style: TextStyle(color: Colors.white70),
            ),
            style: TextStyle(color: Colors.white),
            items: CableMaterial.values.map((material) {
              return DropdownMenuItem(
                value: material,
                child: Text(CableData.materialToString(material)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedMaterial = value;
                _selectedType = null;
                _selectedCrossSection = null;
                _result = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    final types = CableDataProvider.getAvailableTypes(_selectedMaterial!);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typ kabla',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<CableType>(
            initialValue: _selectedType,
            dropdownColor: _cardNavy,
            decoration: InputDecoration(
              filled: true,
              fillColor: _deepNavy,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text('Wybierz typ', style: TextStyle(color: Colors.white70)),
            style: TextStyle(color: Colors.white),
            items: types.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(CableData.typeToString(type)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value;
                _selectedCrossSection = null;
                _result = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCrossSectionDropdown() {
    final crossSections = CableDataProvider.getAvailableCrossSections(
      _selectedMaterial!,
      _selectedType!,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Przekrój',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<double>(
            initialValue: _selectedCrossSection,
            dropdownColor: _cardNavy,
            decoration: InputDecoration(
              filled: true,
              fillColor: _deepNavy,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            hint: Text(
              'Wybierz przekrój',
              style: TextStyle(color: Colors.white70),
            ),
            style: TextStyle(color: Colors.white),
            items: crossSections.map((crossSection) {
              return DropdownMenuItem(
                value: crossSection,
                child: Text('$crossSection mm²'),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCrossSection = value;
                if (value != null) {
                  _result = CableDataProvider.getCableData(
                    _selectedMaterial!,
                    _selectedType!,
                    value,
                  );
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    if (_result == null) return const SizedBox.shrink();

    final sleeveVariant1 = _recommendedHeatShrink3to1(_result!.outerDiameter);
    final sleeveVariant2 = _recommendedHeatShrink2to1(_result!.outerDiameter);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: _amber, size: 32),
              const SizedBox(width: 12),
              Text(
                'Wynik',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResultRow(
            'Materiał:',
            CableData.materialToString(_result!.material),
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            'Typ przewodu/kabla:',
            CableData.typeToString(_result!.type),
          ),
          const SizedBox(height: 12),
          _buildResultRow('Przekrój:', '${_result!.crossSection} mm²'),
          const SizedBox(height: 12),
          Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _buildResultRow(
            'Typ żyły:',
            CableData.coreTypeToString(_result!.coreType),
            valueColor: _amber,
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            'Średnica zewnętrzna:',
            '${_result!.outerDiameter} mm',
            valueColor: _amber,
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Text(
            'Termokurczliwe:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            '  • Wariant 1 (grubościenna z klejem, 3:1):',
            sleeveVariant1,
          ),
          const SizedBox(height: 8),
          _buildResultRow(
            '  • Wariant 2 (cienkościenna oznacznikowa, 2:1):',
            sleeveVariant2,
          ),
          const SizedBox(height: 12),
          Text(
            'Dobór wykonano dla płaszcza zewnętrznego kabla Ø ${_result!.outerDiameter.toStringAsFixed(1)} mm.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  String _recommendedHeatShrink3to1(double outerDiameter) {
    const catalog = [
      (12.0, 4.0),
      (15.0, 5.0),
      (18.0, 6.0),
      (24.0, 8.0),
      (30.0, 10.0),
      (40.0, 13.0),
      (50.0, 17.0),
      (60.0, 20.0),
      (75.0, 25.0),
      (95.0, 31.0),
      (120.0, 40.0),
    ];

    final requiredBeforeShrink =
      (outerDiameter * 1.15) > (outerDiameter + 5.0)
        ? (outerDiameter * 1.15)
        : (outerDiameter + 5.0);
    for (final item in catalog) {
      final before = item.$1;
      final after = item.$2;
      if (before >= requiredBeforeShrink && after <= outerDiameter) {
        return '${before.toStringAsFixed(0)}/${after.toStringAsFixed(0)}';
      }
    }

    final max = catalog.last;
    return '${max.$1.toStringAsFixed(0)}/${max.$2.toStringAsFixed(0)} (max katalog)';
  }

  String _recommendedHeatShrink2to1(double outerDiameter) {
    const catalog = [
      (3.2, 1.6),
      (4.8, 2.4),
      (6.4, 3.2),
      (9.5, 4.8),
      (12.7, 6.4),
      (19.0, 9.5),
      (25.4, 12.7),
      (38.0, 19.0),
      (50.8, 25.4),
      (64.0, 32.0),
      (76.0, 38.0),
      (102.0, 51.0),
    ];

    final requiredBeforeShrink =
      (outerDiameter * 1.12) > (outerDiameter + 4.0)
        ? (outerDiameter * 1.12)
        : (outerDiameter + 4.0);
    for (final item in catalog) {
      final before = item.$1;
      final after = item.$2;
      if (before >= requiredBeforeShrink && after <= outerDiameter) {
        final beforeText = before % 1 == 0
            ? before.toStringAsFixed(0)
            : before.toStringAsFixed(1);
        final afterText = after % 1 == 0
            ? after.toStringAsFixed(0)
            : after.toStringAsFixed(1);
        return '$beforeText/$afterText';
      }
    }

    final max = catalog.last;
    return '${max.$1.toStringAsFixed(0)}/${max.$2.toStringAsFixed(0)} (max katalog)';
  }

  Widget _buildResultRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
