import 'dart:math' as math;

import 'package:flutter/material.dart';

enum _SystemType { dc, ac }

enum _InstallationType { singlePhase, threePhase }

enum _ConductorMaterial { copper, aluminum }

enum _CircuitCategory { lighting, general }

enum _InputMode { current, powerKw, powerW }

class VoltageDropCalculatorScreen extends StatefulWidget {
  const VoltageDropCalculatorScreen({super.key});

  @override
  State<VoltageDropCalculatorScreen> createState() =>
      _VoltageDropCalculatorScreenState();
}

class _VoltageDropCalculatorScreenState
    extends State<VoltageDropCalculatorScreen> {
  final _lengthController = TextEditingController();
  final _currentController = TextEditingController();
  final _powerKwController = TextEditingController();
  final _powerWController = TextEditingController();
  final _crossSectionController = TextEditingController();
  final _voltageController = TextEditingController();
  final _powerFactorController = TextEditingController(text: '0.9');

  _SystemType _systemType = _SystemType.ac;
  _InstallationType _installationType = _InstallationType.singlePhase;
  _ConductorMaterial _material = _ConductorMaterial.copper;
  _CircuitCategory _category = _CircuitCategory.general;
  _InputMode _inputMode = _InputMode.current;

  String? _error;
  _VoltageDropResult? _result;

  @override
  void dispose() {
    _lengthController.dispose();
    _currentController.dispose();
    _powerKwController.dispose();
    _powerWController.dispose();
    _crossSectionController.dispose();
    _voltageController.dispose();
    _powerFactorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Spadek napięcia',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kalkulator oparty na wzorach dla instalacji nn oraz wytycznych PN-HD 60364-5-52.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _buildSelectors(theme),
              const SizedBox(height: 12),
              _buildInputs(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: const Text('Oblicz spadek napięcia'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _InfoBox(
                  color: Colors.red.shade50,
                  borderColor: Colors.red.shade300,
                  icon: Icons.error_outline,
                  title: 'Błąd danych wejściowych',
                  message: _error!,
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                _buildResultCard(_result!, theme),
                const SizedBox(height: 12),
                _buildSuggestions(_result!, theme),
              ],
              const SizedBox(height: 18),
              _buildDisclaimer(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectors(ThemeData theme) {
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w700,
    );

    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Typ układu', style: titleStyle),
            const SizedBox(height: 8),
            SegmentedButton<_SystemType>(
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _SystemType.dc, label: Text('DC')),
                ButtonSegment(value: _SystemType.ac, label: Text('AC')),
              ],
              selected: {_systemType},
              onSelectionChanged: (selection) {
                setState(() {
                  _systemType = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Instalacja', style: titleStyle),
            const SizedBox(height: 8),
            SegmentedButton<_InstallationType>(
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _InstallationType.singlePhase,
                  label: Text('1-fazowa'),
                ),
                ButtonSegment(
                  value: _InstallationType.threePhase,
                  label: Text('3-fazowa'),
                ),
              ],
              selected: {_installationType},
              onSelectionChanged: (selection) {
                setState(() {
                  _installationType = selection.first;
                });
              },
            ),
            if (_systemType == _SystemType.dc &&
                _installationType == _InstallationType.threePhase) ...[
              const SizedBox(height: 8),
              Text(
                'Dla DC zalecany jest tryb 1-fazowa (obwód dwuprzewodowy).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dane obciążenia',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<_InputMode>(
              style: SegmentedButton.styleFrom(
                foregroundColor: Colors.black87,
              ),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _InputMode.current, label: Text('Prąd [A]')),
                ButtonSegment(value: _InputMode.powerKw, label: Text('Moc [kW]')),
                ButtonSegment(value: _InputMode.powerW, label: Text('Moc [W]')),
              ],
              selected: {_inputMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _inputMode = selection.first;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    controller: _lengthController,
                    label: 'Długość trasy L [m]',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numberField(
                    controller: _inputMode == _InputMode.current
                        ? _currentController
                        : _inputMode == _InputMode.powerKw
                            ? _powerKwController
                            : _powerWController,
                    label: _inputMode == _InputMode.current
                        ? 'Prąd obciążenia I [A]'
                        : _inputMode == _InputMode.powerKw
                            ? 'Moc czynna P [kW]'
                            : 'Moc czynna P [W]',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    controller: _crossSectionController,
                    label: 'Przekrój żyły S [mm²]',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _numberField(
                    controller: _voltageController,
                    label: 'Napięcie znam. U [V]',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<_ConductorMaterial>(
              initialValue: _material,
              style: const TextStyle(color: Colors.black87),
              dropdownColor: Colors.white,
              decoration: const InputDecoration(
                labelText: 'Materiał żyły',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black87),
              ),
              items: const [
                DropdownMenuItem(
                  value: _ConductorMaterial.copper,
                  child: Text(
                    'Miedź (Cu)',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                DropdownMenuItem(
                  value: _ConductorMaterial.aluminum,
                  child: Text(
                    'Aluminium (Al)',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _material = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<_CircuitCategory>(
              initialValue: _category,
              isExpanded: true,
              style: const TextStyle(color: Colors.black87),
              dropdownColor: Colors.white,
              decoration: const InputDecoration(
                labelText: 'Rodzaj obwodu (do oceny normowej)',
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black87),
              ),
              items: const [
                DropdownMenuItem(
                  value: _CircuitCategory.lighting,
                  child: Text(
                    'Oświetleniowy (zalecenie 3%)',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                DropdownMenuItem(
                  value: _CircuitCategory.general,
                  child: Text(
                    'Pozostałe odbiorcze (zalecenie 5%)',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ],
              selectedItemBuilder: (context) => const [
                Text('Oświetleniowy (3%)', style: TextStyle(color: Colors.black87)),
                Text('Pozostałe odbiorcze (5%)', style: TextStyle(color: Colors.black87)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _category = value;
                });
              },
            ),
            if (_systemType == _SystemType.ac) ...[
              const SizedBox(height: 10),
              _numberField(
                controller: _powerFactorController,
                label: 'Współczynnik mocy cosφ (AC)',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black87),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildResultCard(_VoltageDropResult result, ThemeData theme) {
    final highContrast = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.black87,
    );
    final highContrastTitle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w700,
    );

    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.shade300, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wynik obliczeń', style: highContrastTitle),
            const SizedBox(height: 8),
            Text(
              'Spadek napięcia ΔU: ${result.deltaVoltage.toStringAsFixed(2)} V',
              style: highContrast,
            ),
            Text(
              'Spadek procentowy: ${result.deltaPercent.toStringAsFixed(2)} %',
              style: highContrast,
            ),
            if (result.inputMode != _InputMode.current)
              Text(
                'Prąd obliczony z mocy: ${result.calculatedCurrent.toStringAsFixed(2)} A',
                style: highContrast,
              ),
            const SizedBox(height: 8),
            Text('Wzór: ${result.formulaLabel}', style: highContrast),
            const SizedBox(height: 10),
            _InfoBox(
              color: result.compliant ? Colors.green.shade50 : Colors.orange.shade50,
              borderColor: result.compliant ? Colors.green.shade300 : Colors.orange.shade300,
              icon: result.compliant ? Icons.check_circle_outline : Icons.warning_amber,
              title: result.compliant
                  ? 'Wynik mieści się w zaleceniu'
                  : 'Wynik przekracza zalecenie',
              message:
                  'Limit referencyjny: ${result.limitPercent.toStringAsFixed(1)}% (${_categoryLabel(_category)}).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(_VoltageDropResult result, ThemeData theme) {
    final highContrast = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.black87,
    );
    final highContrastTitle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.black87,
      fontWeight: FontWeight.w700,
    );

    final suggestions = <String>[
      if (!result.compliant)
        'Zwiększ przekrój żyły o 1–2 stopnie handlowe i porównaj wynik ponownie.',
      if (!result.compliant)
        'Rozważ skrócenie trasy kablowej lub podział obwodu na krótsze odcinki.',
      if (_material == _ConductorMaterial.aluminum)
        'Dla tej samej geometrii przewodu miedź zwykle daje mniejszy spadek napięcia.',
      if (_systemType == _SystemType.ac && _result != null && _result!.deltaPercent > 3)
        'Zweryfikuj także spadek przy rozruchu odbiorników o dużym prądzie startowym.',
      'Uwzględnij łączny spadek od złącza do najdalszego punktu odbioru, nie tylko ten odcinek.',
    ];

    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueGrey.shade300, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sugestie praktyczne', style: highContrastTitle),
            const SizedBox(height: 8),
            ...suggestions.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: highContrast),
                    Expanded(child: Text(entry, style: highContrast)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Text(
        'Disclaimer: narzędzie ma charakter pomocniczy i edukacyjny. Wynik oparto na uproszczonych modelach obliczeniowych (rezystancja materiału w 20°C oraz przybliżona reaktancja dla AC). Dobór końcowy należy każdorazowo potwierdzić obliczeniami projektowymi oraz aktualnymi wymaganiami norm, w tym PN-HD 60364 i dokumentacją producenta przewodów.',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87),
      ),
    );
  }

  void _calculate() {
    setState(() {
      _error = null;
      _result = null;
    });

    final length = _parse(_lengthController.text);
    final currentInput =
        _inputMode == _InputMode.current ? _parse(_currentController.text) : null;
    final powerInputKw =
      _inputMode == _InputMode.powerKw ? _parse(_powerKwController.text) : null;
    final powerInputW =
      _inputMode == _InputMode.powerW ? _parse(_powerWController.text) : null;
    final crossSection = _parse(_crossSectionController.text);
    final nominalVoltage = _parse(_voltageController.text);
    final powerFactor = _systemType == _SystemType.ac
        ? _parse(_powerFactorController.text)
        : 1.0;

    if ([length, crossSection, nominalVoltage].any((e) => e == null) ||
        (_inputMode == _InputMode.current && currentInput == null) ||
        (_inputMode == _InputMode.powerKw && powerInputKw == null) ||
        (_inputMode == _InputMode.powerW && powerInputW == null)) {
      setState(() {
        _error = 'Wprowadź poprawne wartości liczbowe we wszystkich wymaganych polach.';
      });
      return;
    }

    if (length! <= 0 ||
        crossSection! <= 0 ||
        nominalVoltage! <= 0 ||
        (_inputMode == _InputMode.current && currentInput! <= 0) ||
        (_inputMode == _InputMode.powerKw && powerInputKw! <= 0) ||
        (_inputMode == _InputMode.powerW && powerInputW! <= 0)) {
      setState(() {
        _error = 'Wartości L, I, S i U muszą być większe od zera.';
      });
      return;
    }

    if (_systemType == _SystemType.ac &&
        (powerFactor == null || powerFactor <= 0 || powerFactor > 1)) {
      setState(() {
        _error = 'Dla AC podaj poprawny cosφ w zakresie 0–1.';
      });
      return;
    }

    if (_inputMode != _InputMode.current &&
        _systemType == _SystemType.dc &&
        _installationType == _InstallationType.threePhase) {
      setState(() {
        _error = 'Tryb mocy dla DC wymaga instalacji 1-fazowej (obwód dwuprzewodowy).';
      });
      return;
    }

    final current = _inputMode == _InputMode.current
        ? currentInput!
        : _computeCurrentFromPower(
            powerW: _inputMode == _InputMode.powerKw
                ? powerInputKw! * 1000
                : powerInputW!,
            nominalVoltage: nominalVoltage,
            cosPhi: powerFactor!,
          );

    if (current <= 0 || current.isNaN || current.isInfinite) {
      setState(() {
        _error = 'Nie udało się wyznaczyć prądu z mocy dla podanych parametrów.';
      });
      return;
    }

    final rho = _material == _ConductorMaterial.copper ? 0.0175 : 0.0285;
    final rPerMeter = rho / crossSection;
    final xPerMeter = _systemType == _SystemType.ac ? 0.00008 : 0.0;
    final cosPhi = _systemType == _SystemType.ac ? powerFactor! : 1.0;
    final sinPhi = _systemType == _SystemType.ac
        ? math.sqrt(math.max(0, 1 - (cosPhi * cosPhi)))
        : 0.0;

    final baseImpedance = (rPerMeter * cosPhi) + (xPerMeter * sinPhi);
    final multiplier = _installationType == _InstallationType.singlePhase
        ? 2.0
        : math.sqrt(3);

    final deltaVoltage = multiplier * current * length * baseImpedance;
    final deltaPercent = (deltaVoltage / nominalVoltage) * 100;
    final limitPercent = _category == _CircuitCategory.lighting ? 3.0 : 5.0;

    final formulaLabel = _installationType == _InstallationType.singlePhase
        ? 'ΔU = 2 · I · L · (R·cosφ + X·sinφ)'
        : 'ΔU = √3 · I · L · (R·cosφ + X·sinφ)';

    setState(() {
      _result = _VoltageDropResult(
        deltaVoltage: deltaVoltage,
        deltaPercent: deltaPercent,
        limitPercent: limitPercent,
        formulaLabel: formulaLabel,
        compliant: deltaPercent <= limitPercent,
        calculatedCurrent: current,
        inputMode: _inputMode,
      );
    });
  }

  double _computeCurrentFromPower({
    required double powerW,
    required double nominalVoltage,
    required double cosPhi,
  }) {
    if (_systemType == _SystemType.dc) {
      return powerW / nominalVoltage;
    }

    if (_installationType == _InstallationType.threePhase) {
      return powerW / (math.sqrt(3) * nominalVoltage * cosPhi);
    }

    return powerW / (nominalVoltage * cosPhi);
  }

  double? _parse(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _categoryLabel(_CircuitCategory category) {
    switch (category) {
      case _CircuitCategory.lighting:
        return 'obwód oświetleniowy';
      case _CircuitCategory.general:
        return 'obwód odbiorczy ogólny';
    }
  }
}

class _VoltageDropResult {
  const _VoltageDropResult({
    required this.deltaVoltage,
    required this.deltaPercent,
    required this.limitPercent,
    required this.formulaLabel,
    required this.compliant,
    required this.calculatedCurrent,
    required this.inputMode,
  });

  final double deltaVoltage;
  final double deltaPercent;
  final double limitPercent;
  final String formulaLabel;
  final bool compliant;
  final double calculatedCurrent;
  final _InputMode inputMode;
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Color color;
  final Color borderColor;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: textColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}