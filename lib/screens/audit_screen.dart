import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/multitool/calculators/logic/engineering_calculators.dart';
import 'package:gridly/services/monetization_provider.dart';
import 'package:gridly/services/pdf_service.dart';

enum CableWires { four, five }

enum NetworkType { tnc, tns }

enum ProtectionType {
  b, // 3-5 × In
  c, // 5-10 × In
  d, // 10-20 × In
}

enum ReceiverType { resistive, motor, mixed }

class CircuitAssessmentScreen extends StatefulWidget {
  const CircuitAssessmentScreen({super.key});

  @override
  State<CircuitAssessmentScreen> createState() => _CircuitAssessmentScreenState();
}

class _CircuitAssessmentScreenState extends State<CircuitAssessmentScreen> {
  static const double _minAllowedVoltage = 12.0;
  static const double _maxAllowedVoltage = 1000.0;
  static const double _minAllowedPowerKw = 0.5;
  static const double _maxAllowedPowerKw = 100.0;
  static const double _minAllowedLengthM = 1.0;
  static const double _maxAllowedLengthM = 200.0;
  static const double _minAllowedImpedanceOhm = 0.1;
  static const double _maxAllowedImpedanceOhm = 5.0;
  static const double _minAllowedZextOhm = 0.05;
  static const double _maxAllowedZextOhm = 2.0;

  static const List<double> _crossSections = [
    1.5,
    2.5,
    4,
    6,
    10,
    16,
    25,
    35,
    50,
    70,
    95,
    120,
    150,
    185,
    240,
  ];

  static const List<double> _inValues = [
    6,
    10,
    13,
    16,
    20,
    25,
    32,
    40,
    50,
    63,
    80,
    100,
    125,
    160,
  ];

  static final Map<double, double> _methodCCu = {
    1.5: 13.5,
    2.5: 18.0,
    4.0: 24.0,
    6.0: 31.0,
    10.0: 42.0,
    16.0: 56.0,
    25.0: 73.0,
    35.0: 89.0,
    50.0: 108.0,
    70.0: 136.0,
    95.0: 164.0,
    120.0: 188.0,
    150.0: 216.0,
    185.0: 245.0,
    240.0: 286.0,
  };

  static final Map<double, double> _methodCAl = {
    2.5: 14.0,
    4.0: 19.0,
    6.0: 24.0,
    10.0: 32.0,
    16.0: 43.0,
    25.0: 57.0,
    35.0: 70.0,
    50.0: 84.0,
    70.0: 106.0,
    95.0: 128.0,
    120.0: 147.0,
    150.0: 169.0,
    185.0: 192.0,
    240.0: 223.0,
  };

  double _selectedCrossSection = 2.5;
  ConductorMaterial _selectedMaterial = ConductorMaterial.cu;
  double _length = 10.0;
  double _selectedIn = 16.0;
  CableWires _selectedWires = CableWires.five;
  NetworkType _selectedNetworkType = NetworkType.tns;
  bool _isPenSplitPoint = false;
  bool _resultCalculated = false;
  bool _isAllowed = false;
  double _maxCurrent = 0.0;

  // Nowe parametry
  double _power = 5.5; // kW
  double _voltage = 400.0; // V
  bool _isThreePhase = true;
  double _impedance = 0.5; // Ohm (ręczny)
  ReceiverType _receiverType = ReceiverType.mixed;
  double _powerFactor = 0.9;
  double _efficiency = 0.95;

  // Obliczanie impedancji
  bool _autoCalculateZ = false;
  double _zext = 0.2; // Impedancja zewnętrzna [Ohm]
  double _peCrossSection = 2.5; // Przekrój PE [mm²]
  ProtectionType _protectionType = ProtectionType.c;

  // Wyniki obliczeń
  double _calculatedCurrent = 0.0;
  double _voltageDrop = 0.0;
  double _shortCircuitCurrent = 0.0;
  String _requiredStrength = '';
  bool _voltageDropOk = true;
  bool _shortCircuitOk = true;
  bool _protectionCurrentOk = true;
  double _calculatedImpedance = 0.0;
  double _maxVoltageDropPercent = 3.0;
  String _recommendation = '';
  bool _decisionSupportConfirmed = false;
  bool _missingShortCircuitData = false;
  bool _isPartialResult = false;
  bool _extendedVerificationMode = false;
  String _extendedInsight = '';
  List<_AuditVariant> _extendedVariants = const [];
  late final TextEditingController _voltageController;
  String? _voltageInputError;

  @override
  void initState() {
    super.initState();
    _voltageController = TextEditingController(
      text: _voltage.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _voltageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ocena orientacyjna obwodu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wyniki mają charakter orientacyjny i informacyjny; nie stanowią porady wykonawczej.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            _buildVerificationModeSelector(),
            const SizedBox(height: 20),
            _buildCrossSectionDropdown(),
            const SizedBox(height: 20),
            _buildMaterialRadio(),
            const SizedBox(height: 20),
            _buildReceiverParameters(),
            const SizedBox(height: 20),
            _buildVoltageAndPhaseInput(),
            const SizedBox(height: 20),
            _buildWiresDropdown(),
            const SizedBox(height: 20),
            _buildNetworkTypeRadio(),
            const SizedBox(height: 20),
            _buildProtectionTypeDropdown(),
            const SizedBox(height: 20),
            _buildImpedanceSection(),
            const SizedBox(height: 20),
            _buildPenSplitPointSwitch(),
            const SizedBox(height: 20),
            _buildLengthSlider(),
            const SizedBox(height: 20),
            _buildVoltageDropLimitSelector(),
            const SizedBox(height: 20),
            _buildInDropdown(),
            const SizedBox(height: 20),
            _buildDecisionSupportConfirmation(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                if (!_decisionSupportConfirmed) {
                  _showErrorDialog(
                    'Potwierdzenie wymagane',
                    'Przed obliczeniem potwierdź, że zweryfikowano dane wejściowe i pomiary terenowe.',
                  );
                  return;
                }

                final confirmed = await _confirmUserAction(
                  actionLabel: 'obliczenia',
                );
                if (!confirmed) {
                  return;
                }

                final calculated = _calculate();
                if (calculated && mounted) {
                  _showResultDialog();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Oblicz'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _resultCalculated ? _generatePdfReport : null,
              icon: const Icon(Icons.description),
              label: const Text('Generuj Raport PDF'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResultDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Wynik weryfikacji'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: _buildResult(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCrossSectionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Przekrój kabla [mm²]',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: DropdownButtonFormField<double>(
            initialValue: _selectedCrossSection,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            dropdownColor: Theme.of(context).cardColor,
            items: _crossSections.map((value) {
              return DropdownMenuItem<double>(
                value: value,
                child: Text('$value mm²'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCrossSection = value;
                  _resultCalculated = false;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationModeSelector() {
    return Consumer<MonetizationProvider>(
      builder: (context, monetization, _) {
        final isPro = monetization.isPro;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tryb weryfikacji',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                const ButtonSegment<bool>(
                  value: false,
                  label: Text('Podstawowa'),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(isPro ? 'Rozszerzona' : 'Rozszerzona (PRO)'),
                ),
              ],
              selected: {_extendedVerificationMode},
              onSelectionChanged: (selection) {
                final wantsExtended = selection.first;

                if (wantsExtended && !isPro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tryb rozszerzony jest dostępny w wersji PRO.'),
                    ),
                  );
                  return;
                }

                setState(() {
                  _extendedVerificationMode = wantsExtended;
                  _resultCalculated = false;
                });
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMaterialRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Materiał przewodu',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        RadioGroup<ConductorMaterial>(
          groupValue: _selectedMaterial,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedMaterial = value;
                _resultCalculated = false;
              });
            }
          },
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: const RadioListTile<ConductorMaterial>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Miedź (Cu)'),
                  value: ConductorMaterial.cu,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: const RadioListTile<ConductorMaterial>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Aluminium (Al)'),
                  value: ConductorMaterial.al,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLengthSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Długość kabla: ${_length.toStringAsFixed(0)} m',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 30),
          child: Slider(
            value: _length,
            min: 1,
            max: 200,
            divisions: 199,
            label: '${_length.toStringAsFixed(0)} m',
            onChanged: (value) {
              setState(() {
                _length = value;
                _resultCalculated = false;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prąd znamionowy zabezpieczenia [A]',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: DropdownButtonFormField<double>(
            initialValue: _selectedIn,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            dropdownColor: Theme.of(context).cardColor,
            items: _inValues.map((value) {
              return DropdownMenuItem<double>(
                value: value,
                child: Text('$value A'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedIn = value;
                  _resultCalculated = false;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWiresDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liczba żył kabla',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: DropdownButtonFormField<CableWires>(
            initialValue: _selectedWires,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            dropdownColor: Theme.of(context).cardColor,
            items: const [
              DropdownMenuItem(
                value: CableWires.four,
                child: Text('4-żyłowy (3L + PEN)'),
              ),
              DropdownMenuItem(
                value: CableWires.five,
                child: Text('5-żyłowy (3L + N + PE)'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedWires = value;
                  _resultCalculated = false;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNetworkTypeRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Typ sieci', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        RadioGroup<NetworkType>(
          groupValue: _selectedNetworkType,
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedNetworkType = value;
                _resultCalculated = false;
              });
            }
          },
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: const RadioListTile<NetworkType>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('TN-C'),
                  subtitle: Text('PEN wspólny'),
                  value: NetworkType.tnc,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: const RadioListTile<NetworkType>(
                  contentPadding: EdgeInsets.zero,
                  title: Text('TN-S'),
                  subtitle: Text('PE i N oddzielne'),
                  value: NetworkType.tns,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReceiverParameters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parametry odbiornika',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReceiverType>(
          initialValue: _receiverType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            labelText: 'Typ odbiornika',
          ),
          items: const [
            DropdownMenuItem(
              value: ReceiverType.resistive,
              child: Text('Rezystancyjny (np. grzałka)'),
            ),
            DropdownMenuItem(
              value: ReceiverType.motor,
              child: Text('Silnikowy / indukcyjny'),
            ),
            DropdownMenuItem(
              value: ReceiverType.mixed,
              child: Text('Mieszany / ogólny'),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _receiverType = value;
              if (value == ReceiverType.resistive) {
                _powerFactor = 1.0;
                _efficiency = 1.0;
              } else if (value == ReceiverType.motor) {
                _powerFactor = 0.85;
                _efficiency = 0.92;
              }
              _resultCalculated = false;
            });
          },
        ),
        const SizedBox(height: 12),
        Text(
          'Moc obciążenia: ${_power.toStringAsFixed(1)} kW',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Slider(
          value: _power,
          min: 0.5,
          max: 100,
          divisions: 199,
          label: '${_power.toStringAsFixed(1)} kW',
          onChanged: (value) {
            setState(() {
              _power = value;
              _resultCalculated = false;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Współczynnik mocy cosφ: ${_powerFactor.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: _powerFactor,
          min: 0.6,
          max: 1.0,
          divisions: 40,
          label: _powerFactor.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _powerFactor = value;
              _resultCalculated = false;
            });
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Sprawność η: ${_efficiency.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: _efficiency,
          min: 0.7,
          max: 1.0,
          divisions: 30,
          label: _efficiency.toStringAsFixed(2),
          onChanged: (value) {
            setState(() {
              _efficiency = value;
              _resultCalculated = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildVoltageAndPhaseInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Napięcie [V]',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9\.,]'),
                      ),
                      LengthLimitingTextInputFormatter(7),
                    ],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: '400',
                      helperText: 'Zakres: 12–1000 V',
                      errorText: _voltageInputError,
                    ),
                    controller: _voltageController,
                    onChanged: (value) {
                      _handleVoltageInputChanged(value);
                    },
                    onEditingComplete: () {
                      _normalizeAndApplyVoltageInput();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Układ', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(_isThreePhase ? '3-fazowy' : '1-fazowy'),
                    value: _isThreePhase,
                    onChanged: (value) {
                      setState(() {
                        _isThreePhase = value;
                        _voltage = value ? 400 : 230;
                        _voltageController.text = _voltage.toStringAsFixed(0);
                        _voltageInputError = null;
                        _resultCalculated = false;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProtectionTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Charakterystyka zabezpieczenia',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ProtectionType>(
          initialValue: _protectionType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          dropdownColor: Theme.of(context).cardColor,
          items: const [
            DropdownMenuItem(
              value: ProtectionType.b,
              child: Text('Typ B (3-5 × In)'),
            ),
            DropdownMenuItem(
              value: ProtectionType.c,
              child: Text('Typ C (5-10 × In)'),
            ),
            DropdownMenuItem(
              value: ProtectionType.d,
              child: Text('Typ D (10-20 × In)'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _protectionType = value;
                _resultCalculated = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildVoltageDropLimitSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dopuszczalny spadek napięcia [%]',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<double>(
          segments: const [
            ButtonSegment<double>(
              value: 3.0,
              label: Text('3%'),
            ),
            ButtonSegment<double>(
              value: 5.0,
              label: Text('5%'),
            ),
          ],
          selected: {_maxVoltageDropPercent},
          onSelectionChanged: (selection) {
            setState(() {
              _maxVoltageDropPercent = selection.first;
              _resultCalculated = false;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDecisionSupportConfirmation() {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      value: _decisionSupportConfirmed,
      onChanged: (value) {
        setState(() {
          _decisionSupportConfirmed = value ?? false;
        });
      },
      title: const Text('Potwierdzam weryfikację danych i pomiarów'),
      subtitle: const Text(
        'Narzędzie ma charakter orientacyjny (decision support) i nie zastępuje projektu wykonawczego.',
      ),
    );
  }

  Widget _buildImpedanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Brak danych zwarciowych (tryb częściowy)'),
          subtitle: const Text(
            'Włącz, jeśli nie masz danych Zs/Zext. Wynik będzie orientacyjny i niepełny.',
          ),
          value: _missingShortCircuitData,
          onChanged: (value) {
            setState(() {
              _missingShortCircuitData = value;
              _resultCalculated = false;
            });
          },
        ),
        const SizedBox(height: 8),
        if (_missingShortCircuitData)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Analiza zwarcia zostanie pominięta. Raport i wynik będą oznaczone jako częściowe.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        if (_missingShortCircuitData) const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Impedancja pętli zwarcia',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Auto', style: Theme.of(context).textTheme.bodyMedium),
                Switch(
                  value: _autoCalculateZ,
                  onChanged: (value) {
                    setState(() {
                      _autoCalculateZ = value;
                      _resultCalculated = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        if (_missingShortCircuitData)
          const SizedBox.shrink()
        else ...[
          const SizedBox(height: 8),
          if (_autoCalculateZ) ...[
          // Auto-obliczanie Zs
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zs = Zext + R_fazy + R_PE',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Impedancja zewnętrzna Zext: ${_zext.toStringAsFixed(2)} Ω',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _zext,
                  min: 0.05,
                  max: 2.0,
                  divisions: 39,
                  label: '${_zext.toStringAsFixed(2)} Ω',
                  onChanged: (value) {
                    setState(() {
                      _zext = value;
                      _resultCalculated = false;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Przekrój przewodu PE [mm²]',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<double>(
                  initialValue: _peCrossSection,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  dropdownColor: Theme.of(context).cardColor,
                  items: _crossSections.map((value) {
                    return DropdownMenuItem<double>(
                      value: value,
                      child: Text('$value mm²'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _peCrossSection = value;
                        _resultCalculated = false;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          ] else ...[
          // Ręczne wprowadzanie impedancji
          Text(
            'Zs: ${_impedance.toStringAsFixed(2)} Ω',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Slider(
            value: _impedance,
            min: 0.1,
            max: 5.0,
            divisions: 49,
            label: '${_impedance.toStringAsFixed(2)} Ω',
            onChanged: (value) {
              setState(() {
                _impedance = value;
                _resultCalculated = false;
              });
            },
          ),
          ],
        ],
      ],
    );
  }

  Widget _buildPenSplitPointSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 50),
          child: SwitchListTile(
            title: Text(
              'Punkt podziału PEN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: const Text('Czy to miejsce rozdziału PEN na PE i N?'),
            value: _isPenSplitPoint,
            onChanged: (value) {
              setState(() {
                _isPenSplitPoint = value;
                _resultCalculated = false;
              });
            },
          ),
        ),
        if (_isPenSplitPoint) ...[
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.blueAccent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dla punktu podziału PEN parametry uziemienia i konfiguracji mogą wymagać dodatkowej weryfikacji terenowej.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResult() {
    final color = _isPartialResult
      ? Colors.orangeAccent
      : (_isAllowed ? Colors.greenAccent : Colors.redAccent);
    final text = _isPartialResult
      ? 'Wynik częściowy: brak danych zwarciowych. Uzupełnij Zs/Zext dla pełnej weryfikacji.'
      : (_isAllowed
        ? null
        : 'Wskaźnik orientacyjny: parametry mogą sugerować niezgodność.');
    final icon = _isPartialResult
      ? Icons.info_outline
      : (_isAllowed ? Icons.circle : Icons.warning);

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 80),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 48),
            if (text != null) ...[
              const SizedBox(height: 12),
              Text(
                text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            Divider(color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            _buildResultRow(
              'Obciążalność kabla:',
              '${_maxCurrent.toStringAsFixed(1)} A',
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Zabezpieczenie In:',
              '${_selectedIn.toStringAsFixed(0)} A',
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Przekrój:',
              '${_selectedCrossSection.toStringAsFixed(1)} mm²',
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Materiał:',
              _selectedMaterial == ConductorMaterial.cu ? 'Miedź' : 'Aluminium',
            ),
            const SizedBox(height: 16),
            Divider(color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            _buildResultRow(
              'Moc obciążenia:',
              '${_power.toStringAsFixed(1)} kW',
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Typ odbiornika:',
              _receiverTypeLabel(_receiverType),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'cosφ / η:',
              '${_powerFactor.toStringAsFixed(2)} / ${_efficiency.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Prąd obliczeniowy:',
              '${_calculatedCurrent.toStringAsFixed(1)} A',
            ),
            const SizedBox(height: 8),
            _buildResultRowWithStatus(
              'Warunek Ib ≤ In:',
              '${_calculatedCurrent.toStringAsFixed(1)} A ≤ ${_selectedIn.toStringAsFixed(0)} A',
              _protectionCurrentOk,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Napięcie:',
              '${_voltage.toStringAsFixed(0)} V (${_isThreePhase ? "3-fazowy" : "1-fazowy"})',
            ),
            const SizedBox(height: 16),
            Divider(color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            _buildResultRowWithStatus(
              'Spadek napięcia:',
              '${_voltageDrop.toStringAsFixed(2)}% (limit ${_maxVoltageDropPercent.toStringAsFixed(0)}%)',
              _voltageDropOk,
            ),
            const SizedBox(height: 16),
            Divider(color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 8),
            Text(
              'Analiza zwarcia',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isPartialResult) ...[
              _buildResultRow('Status:', 'Pominięto (brak danych)'),
              const SizedBox(height: 8),
              _buildResultRow('Wymagana wytrzymałość:', 'Brak danych'),
              const SizedBox(height: 8),
              _buildResultRow(
                'Charakterystyka:',
                _protectionTypeLabel(_protectionType),
              ),
            ] else if (_autoCalculateZ) ...[
              _buildResultRow(
                'Impedancja pętli (obliczona):',
                '${_calculatedImpedance.toStringAsFixed(3)} Ω',
              ),
              const SizedBox(height: 8),
              _buildResultRow('Zext:', '${_zext.toStringAsFixed(2)} Ω'),
              const SizedBox(height: 8),
              _buildResultRow(
                'Przekrój PE:',
                '${_peCrossSection.toStringAsFixed(1)} mm²',
              ),
            ] else ...[
              _buildResultRow(
                'Impedancja pętli:',
                '${_impedance.toStringAsFixed(2)} Ω',
              ),
            ],
            const SizedBox(height: 8),
            _buildResultRowWithStatus(
              'Prąd zwarcia:',
              '${(_shortCircuitCurrent / 1000).toStringAsFixed(2)} kA',
              _shortCircuitOk,
            ),
            const SizedBox(height: 8),
            _buildResultRow('Wymagana wytrzymałość:', _requiredStrength),
            const SizedBox(height: 8),
            _buildResultRow(
              'Charakterystyka:',
              _protectionTypeLabel(_protectionType),
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Min. Ik dla wyzwolenia:',
              '${(_selectedIn * _getMinTripMultiplier()).toStringAsFixed(0)} A',
            ),
            const SizedBox(height: 16),
            Divider(color: color.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            _buildResultRow(
              'Liczba żył:',
              _selectedWires == CableWires.four ? '4-żyłowy' : '5-żyłowy',
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Typ sieci:',
              _selectedNetworkType == NetworkType.tnc ? 'TN-C' : 'TN-S',
            ),
            if (_isPenSplitPoint) ...[
              const SizedBox(height: 8),
              _buildResultRow('Punkt podziału PEN:', 'TAK'),
            ],
            if (_recommendation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: color.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              _buildResultRow('Rekomendacja:', _recommendation),
            ],
            if (_extendedVerificationMode && _extendedInsight.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: color.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text(
                'Rozszerzona analiza (PRO)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              _buildResultRow('Wskaźniki rozszerzone:', _extendedInsight),
              if (_extendedVariants.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Warianty A/B/C',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                for (final variant in _extendedVariants) ...[
                  _buildExtendedVariantTile(variant),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExtendedVariantTile(_AuditVariant variant) {
    final statusColor = variant.isOk ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.8)),
        color: statusColor.withValues(alpha: 0.12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultRow('Wariant ${variant.label}', '${variant.crossSection.toStringAsFixed(1)} mm²'),
          const SizedBox(height: 4),
          _buildResultRow('Obciążalność', '${variant.maxCurrent.toStringAsFixed(1)} A'),
          const SizedBox(height: 4),
          _buildResultRow('Spadek napięcia', '${variant.voltageDrop.toStringAsFixed(2)}%'),
          const SizedBox(height: 4),
          _buildResultRow('Ocena', variant.isOk ? 'OK' : 'Do weryfikacji'),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildResultRowWithStatus(String label, String value, bool isOk) {
    final statusColor = isOk ? Colors.greenAccent : Colors.redAccent;
    final statusIcon = isOk ? Icons.check_circle : Icons.warning;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Icon(statusIcon, color: statusColor, size: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
        ),
      ],
    );
  }

  /// Oblicza impedancję pętli zwarcia Zs = Zext + R_fazy + R_PE
  /// R = (ρ × L) / S, gdzie ρ = 1/γ
  /// γ_Cu = 56 m/(Ω·mm²), γ_Al = 34 m/(Ω·mm²)
  double _calculateLoopImpedance() {
    // Rezystywność przy 20°C
    final gamma = _selectedMaterial == ConductorMaterial.cu ? 56.0 : 34.0;
    final rho = 1 / gamma; // Ω·mm²/m

    // Rezystancja przewodu fazowego
    final rPhase = (rho * _length) / _selectedCrossSection;

    // Rezystancja przewodu ochronnego PE
    final rPe = (rho * _length) / _peCrossSection;

    // Całkowita impedancja pętli
    return _zext + rPhase + rPe;
  }

  String _protectionTypeLabel(ProtectionType type) {
    switch (type) {
      case ProtectionType.b:
        return 'Typ B (3-5 × In)';
      case ProtectionType.c:
        return 'Typ C (5-10 × In)';
      case ProtectionType.d:
        return 'Typ D (10-20 × In)';
    }
  }

  String _receiverTypeLabel(ReceiverType type) {
    switch (type) {
      case ReceiverType.resistive:
        return 'Rezystancyjny';
      case ReceiverType.motor:
        return 'Silnikowy';
      case ReceiverType.mixed:
        return 'Mieszany';
    }
  }

  double _getMinTripMultiplier() {
    switch (_protectionType) {
      case ProtectionType.b:
        return 3.0;
      case ProtectionType.c:
        return 5.0;
      case ProtectionType.d:
        return 10.0;
    }
  }

  bool _calculate() {
    _normalizeAndApplyVoltageInput();

    if (_voltageInputError != null) {
      _showErrorDialog(
        'Nieprawidłowe napięcie',
        _voltageInputError!,
      );
      return false;
    }

    if (_voltage <= 0) {
      _showErrorDialog(
        'Nieprawidłowe napięcie',
        'Napięcie musi być większe od 0 V.',
      );
      return false;
    }

    final numericValidationMessage = _validateNumericInputs();
    if (numericValidationMessage != null) {
      _showErrorDialog('Nieprawidłowe dane wejściowe', numericValidationMessage);
      return false;
    }

    // Walidacja: TN-S wymaga 5 żył
    if (_selectedNetworkType == NetworkType.tns &&
        _selectedWires == CableWires.four) {
      _showErrorDialog(
        'Informacja o konfiguracji',
        'Wprowadzone parametry wskazują układ TN-S przy przewodzie 4-żyłowym. Obliczenie nie zostało wykonane.',
      );
      return false;
    }

    // Walidacja: TN-C wymaga 4 żył
    if (_selectedNetworkType == NetworkType.tnc &&
        _selectedWires == CableWires.five) {
      _showErrorDialog(
        'Informacja o konfiguracji',
        'Wprowadzone parametry wskazują układ TN-C przy przewodzie 5-żyłowym. Obliczenie nie zostało wykonane.',
      );
      return false;
    }

    // Walidacja: Punkt podziału PEN
    if (_isPenSplitPoint && _selectedWires == CableWires.four) {
      _showErrorDialog(
        'Informacja o konfiguracji',
        'Dla wskazanego punktu podziału PEN ustawiono przewód 4-żyłowy. Obliczenie nie zostało wykonane.',
      );
      return false;
    }

    final table =
        _selectedMaterial == ConductorMaterial.cu ? _methodCCu : _methodCAl;
    final maxCurrent = table[_selectedCrossSection];

    if (maxCurrent == null) {
      _showErrorDialog(
        'Informacja o danych wejściowych',
        'Wprowadzony przekrój nie został rozpoznany dla wybranego materiału.',
      );
      return false;
    }

    // Oblicz prąd obliczeniowy
    _calculatedCurrent = _isThreePhase
      ? (_power * 1000) / (_voltage * 1.732 * _powerFactor * _efficiency)
      : (_power * 1000) / (_voltage * _powerFactor * _efficiency);
    _protectionCurrentOk = _calculatedCurrent <= _selectedIn;

    // Oblicz spadek napięcia
    _voltageDrop = _isThreePhase
        ? EngineeringCalculators.calculateVoltageDrop3Phase(
            powerKw: _power,
            lengthM: _length,
            crossSectionMm2: _selectedCrossSection,
            voltageV: _voltage,
            isCopper: _selectedMaterial == ConductorMaterial.cu,
          )
        : EngineeringCalculators.calculateVoltageDrop1Phase(
            powerKw: _power,
            lengthM: _length,
            crossSectionMm2: _selectedCrossSection,
            voltageV: _voltage,
            isCopper: _selectedMaterial == ConductorMaterial.cu,
          );
            _voltageDropOk = _voltageDrop <= _maxVoltageDropPercent;

    // Oblicz lub użyj impedancji pętli
    final impedanceToUse = _missingShortCircuitData
      ? 0.0
      : (_autoCalculateZ ? _calculateLoopImpedance() : _impedance);

    if (_autoCalculateZ && !_missingShortCircuitData) {
      _calculatedImpedance = impedanceToUse;
    }

    final shortCircuitVoltage = _isThreePhase
        ? (_voltage / math.sqrt(3))
        : _voltage;

    final minTripMultiplier = _getMinTripMultiplier();

    if (_missingShortCircuitData) {
      _shortCircuitCurrent = 0.0;
      _requiredStrength = 'Brak danych';
      _shortCircuitOk = true;
      _isPartialResult = true;
    } else {
      // Oblicz prąd zwarcia
      _shortCircuitCurrent = EngineeringCalculators.calculateShortCircuitCurrent(
        voltageV: shortCircuitVoltage,
        impedanceOhm: impedanceToUse,
      );
      _requiredStrength = EngineeringCalculators.getRequiredStrength(
        _shortCircuitCurrent,
      );

      // Sprawdź czy instalacja jest bezpieczna pod kątem zwarcia
      _shortCircuitOk =
          _shortCircuitCurrent >= (_selectedIn * minTripMultiplier);
      _isPartialResult = false;
    }

    final recommendationParts = <String>[];
    if (_selectedIn > maxCurrent) {
      recommendationParts.add(
        'dobierz niższe zabezpieczenie lub większy przekrój',
      );
    }
    if (!_protectionCurrentOk) {
      recommendationParts.add('zwiększ In albo zmniejsz obciążenie (warunek Ib ≤ In niespełniony)');
    }
    if (!_voltageDropOk) {
      recommendationParts.add('zwiększ przekrój lub skróć długość obwodu');
    }
    if (!_shortCircuitOk && !_missingShortCircuitData) {
      recommendationParts.add('zmniejsz impedancję pętli lub zmień typ zabezpieczenia');
    }
    if (_missingShortCircuitData) {
      recommendationParts.add('uzupełnij Zs/Zext dla pełnej weryfikacji');
    }

    _recommendation = recommendationParts.isEmpty
        ? 'Parametry mieszczą się w przyjętych kryteriach orientacyjnych.'
        : recommendationParts.join('; ');

    final loadReservePercent =
      ((maxCurrent - _selectedIn) / maxCurrent * 100).clamp(-999.0, 999.0);
    final voltageReservePercent =
      (_maxVoltageDropPercent - _voltageDrop).clamp(-999.0, 999.0);

    _extendedInsight = _extendedVerificationMode
      ? 'Zapas obciążalności: ${loadReservePercent.toStringAsFixed(1)}%; '
        'zapas spadku napięcia: ${voltageReservePercent.toStringAsFixed(2)} p.p.; '
        'tryb: ${_isPartialResult ? "częściowy" : "pełny"}'
      : '';

    _extendedVariants = _extendedVerificationMode
      ? _buildExtendedVariants(table)
      : const [];

    setState(() {
      _maxCurrent = maxCurrent;
      _isAllowed =
          _protectionCurrentOk && _selectedIn <= maxCurrent && _voltageDropOk &&
          (_missingShortCircuitData ? true : _shortCircuitOk);
      _resultCalculated = true;
    });

    return true;
  }

  String? _validateNumericInputs() {
    if (_power < _minAllowedPowerKw || _power > _maxAllowedPowerKw) {
      return 'Moc obciążenia musi mieścić się w zakresie '
          '${_minAllowedPowerKw.toStringAsFixed(1)}–${_maxAllowedPowerKw.toStringAsFixed(0)} kW.';
    }

    if (_powerFactor < 0.6 || _powerFactor > 1.0) {
      return 'Współczynnik mocy cosφ musi być w zakresie 0.60–1.00.';
    }

    if (_efficiency < 0.7 || _efficiency > 1.0) {
      return 'Sprawność η musi być w zakresie 0.70–1.00.';
    }

    if (_length < _minAllowedLengthM || _length > _maxAllowedLengthM) {
      return 'Długość kabla musi mieścić się w zakresie '
          '${_minAllowedLengthM.toStringAsFixed(0)}–${_maxAllowedLengthM.toStringAsFixed(0)} m.';
    }

    if (_missingShortCircuitData) {
      // Pomijamy walidację danych zwarciowych - wynik będzie częściowy.
    } else if (_autoCalculateZ) {
      if (_zext < _minAllowedZextOhm || _zext > _maxAllowedZextOhm) {
        return 'Impedancja zewnętrzna Zext musi mieścić się w zakresie '
            '${_minAllowedZextOhm.toStringAsFixed(2)}–${_maxAllowedZextOhm.toStringAsFixed(1)} Ω.';
      }

      if (_peCrossSection <= 0) {
        return 'Przekrój przewodu PE musi być większy od 0 mm².';
      }
    } else {
      if (_impedance < _minAllowedImpedanceOhm ||
          _impedance > _maxAllowedImpedanceOhm) {
        return 'Impedancja pętli zwarcia musi mieścić się w zakresie '
            '${_minAllowedImpedanceOhm.toStringAsFixed(1)}–${_maxAllowedImpedanceOhm.toStringAsFixed(1)} Ω.';
      }
    }

    if (_selectedIn <= 0) {
      return 'Prąd znamionowy zabezpieczenia musi być większy od 0 A.';
    }

    if (_selectedCrossSection <= 0) {
      return 'Przekrój kabla musi być większy od 0 mm².';
    }

    return null;
  }

  List<_AuditVariant> _buildExtendedVariants(Map<double, double> table) {
    final availableSections = table.keys.toList()..sort();
    if (availableSections.isEmpty) {
      return const [];
    }

    var startIndex = availableSections.indexWhere(
      (section) => section >= _selectedCrossSection,
    );
    if (startIndex == -1) {
      startIndex = availableSections.length - 1;
    }

    final pickedSections = <double>[];
    for (var index = startIndex; index < availableSections.length; index++) {
      pickedSections.add(availableSections[index]);
      if (pickedSections.length == 3) {
        break;
      }
    }

    if (pickedSections.length < 3 && startIndex > 0) {
      for (var index = startIndex - 1; index >= 0; index--) {
        pickedSections.insert(0, availableSections[index]);
        if (pickedSections.length == 3) {
          break;
        }
      }
    }

    final labels = ['A', 'B', 'C'];
    final variants = <_AuditVariant>[];

    for (var i = 0; i < pickedSections.length && i < labels.length; i++) {
      final section = pickedSections[i];
      final maxCurrent = table[section] ?? 0.0;
      final drop = _isThreePhase
          ? EngineeringCalculators.calculateVoltageDrop3Phase(
              powerKw: _power,
              lengthM: _length,
              crossSectionMm2: section,
              voltageV: _voltage,
              isCopper: _selectedMaterial == ConductorMaterial.cu,
            )
          : EngineeringCalculators.calculateVoltageDrop1Phase(
              powerKw: _power,
              lengthM: _length,
              crossSectionMm2: section,
              voltageV: _voltage,
              isCopper: _selectedMaterial == ConductorMaterial.cu,
            );

      final isCapacityOk = _selectedIn <= maxCurrent;
      final isDropOk = drop <= _maxVoltageDropPercent;

      variants.add(
        _AuditVariant(
          label: labels[i],
          crossSection: section,
          maxCurrent: maxCurrent,
          voltageDrop: drop,
          isOk: isCapacityOk && isDropOk,
        ),
      );
    }

    return variants;
  }

  void _handleVoltageInputChanged(String rawValue) {
    final normalized = rawValue.replaceAll(',', '.').trim();

    if (normalized.isEmpty) {
      setState(() {
        _voltageInputError = 'Pole napięcia nie może być puste.';
        _resultCalculated = false;
      });
      return;
    }

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      setState(() {
        _voltageInputError = 'Wpisz poprawną wartość liczbową.';
        _resultCalculated = false;
      });
      return;
    }

    if (parsed < _minAllowedVoltage || parsed > _maxAllowedVoltage) {
      setState(() {
        _voltageInputError =
            'Dozwolony zakres napięcia: ${_minAllowedVoltage.toStringAsFixed(0)}–${_maxAllowedVoltage.toStringAsFixed(0)} V.';
        _resultCalculated = false;
      });
      return;
    }

    setState(() {
      _voltage = parsed;
      _voltageInputError = null;
      _resultCalculated = false;
    });
  }

  void _normalizeAndApplyVoltageInput() {
    final normalized = _voltageController.text.replaceAll(',', '.').trim();

    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      setState(() {
        _voltageInputError = 'Wpisz poprawną wartość liczbową.';
      });
      return;
    }

    if (parsed < _minAllowedVoltage || parsed > _maxAllowedVoltage) {
      setState(() {
        _voltageInputError =
            'Dozwolony zakres napięcia: ${_minAllowedVoltage.toStringAsFixed(0)}–${_maxAllowedVoltage.toStringAsFixed(0)} V.';
      });
      return;
    }

    setState(() {
      _voltage = parsed;
      _voltageInputError = null;
      _voltageController.text = _voltage.toStringAsFixed(0);
      _voltageController.selection = TextSelection.collapsed(
        offset: _voltageController.text.length,
      );
    });
  }

  Future<void> _generatePdfReport() async {
    if (!_decisionSupportConfirmed) {
      _showErrorDialog(
        'Potwierdzenie wymagane',
        'Przed generowaniem PDF potwierdź weryfikację danych i pomiarów terenowych.',
      );
      return;
    }

    final confirmed = await _confirmUserAction(actionLabel: 'generowanie PDF');
    if (!confirmed) {
      return;
    }
    if (!mounted) {
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final buildingName = 'OBIEKT_TECH_$timestamp';

    final impedanceToUse = _missingShortCircuitData
        ? 0.0
        : (_autoCalculateZ ? _calculatedImpedance : _impedance);

    await PdfService.generateCircuitAssessmentReport(
      buildingName: buildingName,
      crossSection: _selectedCrossSection,
      material: _selectedMaterial == ConductorMaterial.cu
          ? 'Miedź (Cu)'
          : 'Aluminium (Al)',
      power: _power,
      voltage: _voltage,
      isThreePhase: _isThreePhase,
      length: _length,
      nominalCurrent: _selectedIn,
      maxCurrent: _maxCurrent,
      calculatedCurrent: _calculatedCurrent,
      voltageDrop: _voltageDrop,
      shortCircuitCurrent: _shortCircuitCurrent,
      requiredStrength: _requiredStrength,
      protectionType: _protectionTypeLabel(_protectionType),
      impedance: impedanceToUse,
      voltageDropLimitPercent: _maxVoltageDropPercent,
      isAutoImpedance: _autoCalculateZ,
      zext: _autoCalculateZ ? _zext : null,
      peCrossSection: _autoCalculateZ ? _peCrossSection : null,
      isAllowed: _isAllowed,
      isPartialResult: _isPartialResult,
    );
  }

  Future<bool> _confirmUserAction({required String actionLabel}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Potwierdzenie'),
          content: Text(
            'Potwierdź uruchomienie: $actionLabel. Wyniki mają charakter orientacyjny i informacyjny i nie stanowią porady wykonawczej ani gotowego projektu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Potwierdź'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }
}

class _AuditVariant {
  const _AuditVariant({
    required this.label,
    required this.crossSection,
    required this.maxCurrent,
    required this.voltageDrop,
    required this.isOk,
  });

  final String label;
  final double crossSection;
  final double maxCurrent;
  final double voltageDrop;
  final bool isOk;
}
