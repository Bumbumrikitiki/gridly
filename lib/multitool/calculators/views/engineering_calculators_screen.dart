import 'package:flutter/material.dart';
import 'package:gridly/multitool/calculators/logic/engineering_calculators.dart';

class EngineeringCalculatorsScreen extends StatefulWidget {
  const EngineeringCalculatorsScreen({super.key});

  @override
  State<EngineeringCalculatorsScreen> createState() =>
      _EngineeringCalculatorsScreenState();
}

class _EngineeringCalculatorsScreenState
    extends State<EngineeringCalculatorsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalkulatory'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _amber,
          labelColor: _amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Spadek U'),
            Tab(text: 'Zwarcie'),
            Tab(text: 'Zabezpieczenia'),
          ],
        ),
      ),
      body: Container(
        color: _deepNavy,
        child: TabBarView(
          controller: _tabController,
          children: const [
            _VoltageDropCalculator(),
            _ShortCircuitCalculator(),
            _ProtectionCalculator(),
          ],
        ),
      ),
    );
  }
}

// ===== Kalkulator spadku napięcia =====
class _VoltageDropCalculator extends StatefulWidget {
  const _VoltageDropCalculator();

  @override
  State<_VoltageDropCalculator> createState() => _VoltageDropCalculatorState();
}

class _VoltageDropCalculatorState extends State<_VoltageDropCalculator> {
  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  final _powerController = TextEditingController(text: '10');
  final _lengthController = TextEditingController(text: '50');
  final _crossSectionController = TextEditingController(text: '2.5');
  final _voltageController = TextEditingController(text: '230');

  bool _isThreePhase = false;
  bool _isCopper = true;
  double? _result;

  @override
  void dispose() {
    _powerController.dispose();
    _lengthController.dispose();
    _crossSectionController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final power = double.tryParse(_powerController.text);
    final length = double.tryParse(_lengthController.text);
    final crossSection = double.tryParse(_crossSectionController.text);
    final voltage = double.tryParse(_voltageController.text);

    if (power == null ||
        length == null ||
        crossSection == null ||
        voltage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź poprawne wartości')),
      );
      return;
    }

    final result = _isThreePhase
        ? EngineeringCalculators.calculateVoltageDrop3Phase(
            powerKw: power,
            lengthM: length,
            crossSectionMm2: crossSection,
            voltageV: voltage,
            isCopper: _isCopper,
          )
        : EngineeringCalculators.calculateVoltageDrop1Phase(
            powerKw: power,
            lengthM: length,
            crossSectionMm2: crossSection,
            voltageV: voltage,
            isCopper: _isCopper,
          );

    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Spadek napięcia',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildTextField('Moc [kW]', _powerController),
          const SizedBox(height: 16),
          _buildTextField('Długość [m]', _lengthController),
          const SizedBox(height: 16),
          _buildTextField('Przekrój [mm²]', _crossSectionController),
          const SizedBox(height: 16),
          _buildTextField('Napięcie [V]', _voltageController),
          const SizedBox(height: 16),
          _buildSwitch('Obwód trójfazowy', _isThreePhase, (value) {
            setState(() {
              _isThreePhase = value;
              _voltageController.text = value ? '400' : '230';
            });
          }),
          const SizedBox(height: 12),
          _buildSwitch('Miedź (Cu)', _isCopper, (value) {
            setState(() => _isCopper = value);
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: _deepNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Oblicz'),
          ),
          if (_result != null) ...[const SizedBox(height: 24), _buildResult()],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        value: value,
        activeThumbColor: _amber,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildResult() {
    final percentage = _result!;
    final isOk = percentage < 3.0;
    final color = isOk ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.warning,
            color: color,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Spadek napięcia',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            isOk
                ? 'Wskaźnik orientacyjny: wartość w zakresie referencyjnym (< 3%)'
                : 'Wskaźnik orientacyjny: wartość poza zakresem referencyjnym',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ===== Kalkulator prądu zwarcia =====
class _ShortCircuitCalculator extends StatefulWidget {
  const _ShortCircuitCalculator();

  @override
  State<_ShortCircuitCalculator> createState() =>
      _ShortCircuitCalculatorState();
}

class _ShortCircuitCalculatorState extends State<_ShortCircuitCalculator> {
  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  final _voltageController = TextEditingController(text: '230');
  final _impedanceController = TextEditingController(text: '0.5');

  double? _result;
  String? _strength;

  @override
  void dispose() {
    _voltageController.dispose();
    _impedanceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final voltage = double.tryParse(_voltageController.text);
    final impedance = double.tryParse(_impedanceController.text);

    if (voltage == null || impedance == null || impedance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź poprawne wartości')),
      );
      return;
    }

    final result = EngineeringCalculators.calculateShortCircuitCurrent(
      voltageV: voltage,
      impedanceOhm: impedance,
    );

    final strength = EngineeringCalculators.getRequiredStrength(result);

    setState(() {
      _result = result;
      _strength = strength;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Prąd zwarcia',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildTextField('Napięcie [V]', _voltageController),
          const SizedBox(height: 16),
          _buildTextField('Impedancja pętli [Ω]', _impedanceController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: _deepNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Oblicz'),
          ),
          if (_result != null) ...[const SizedBox(height: 24), _buildResult()],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.flash_on, color: _amber, size: 48),
          const SizedBox(height: 12),
          Text(
            'Prąd zwarcia',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_result! / 1000).toStringAsFixed(2)} kA',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: _amber,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'Wymagana wytrzymałość osprzętu:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            _strength!,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: _amber,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

// ===== Kalkulator doboru zabezpieczeń =====
class _ProtectionCalculator extends StatefulWidget {
  const _ProtectionCalculator();

  @override
  State<_ProtectionCalculator> createState() => _ProtectionCalculatorState();
}

class _ProtectionCalculatorState extends State<_ProtectionCalculator> {
  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  final _powerController = TextEditingController(text: '5.5');
  final _voltageController = TextEditingController(text: '400');

  bool _isThreePhase = true;
  bool _isCopper = true;
  ProtectionResult? _result;

  @override
  void dispose() {
    _powerController.dispose();
    _voltageController.dispose();
    super.dispose();
  }

  void _calculate() {
    final power = double.tryParse(_powerController.text);
    final voltage = double.tryParse(_voltageController.text);

    if (power == null || voltage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź poprawne wartości')),
      );
      return;
    }

    final result = EngineeringCalculators.selectProtection(
      powerKw: power,
      voltageV: voltage,
      isThreePhase: _isThreePhase,
      isCopper: _isCopper,
    );

    setState(() {
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dobór zabezpieczeń',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 24),
          _buildTextField('Moc [kW]', _powerController),
          const SizedBox(height: 16),
          _buildTextField('Napięcie [V]', _voltageController),
          const SizedBox(height: 16),
          _buildSwitch('Obwód trójfazowy', _isThreePhase, (value) {
            setState(() {
              _isThreePhase = value;
              _voltageController.text = value ? '400' : '230';
            });
          }),
          const SizedBox(height: 12),
          _buildSwitch('Miedź (Cu)', _isCopper, (value) {
            setState(() => _isCopper = value);
          }),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _calculate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _amber,
              foregroundColor: _deepNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Dobierz'),
          ),
          if (_result != null) ...[const SizedBox(height: 24), _buildResult()],
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(color: Colors.white)),
        value: value,
        activeThumbColor: _amber,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildResult() {
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
              Icon(Icons.shield, color: _amber, size: 32),
              const SizedBox(width: 12),
              Text(
                'Wynik doboru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _amber,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResultRow(
            'Prąd obliczeniowy:',
            '${_result!.calculatedCurrent.toStringAsFixed(1)} A',
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white24),
          const SizedBox(height: 12),
          _buildResultRow(
            'Prąd znamionowy In:',
            '${_result!.nominalCurrent.toStringAsFixed(0)} A',
            valueColor: _amber,
          ),
          const SizedBox(height: 12),
          _buildResultRow(
            'Minimalny przekrój:',
            '${_result!.minCrossSection.toStringAsFixed(1)} mm² ${_result!.material}',
            valueColor: _amber,
          ),
        ],
      ),
    );
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
