import 'package:flutter/material.dart';
import 'package:gridly/models/grid_models.dart';
import 'package:gridly/theme/grid_theme.dart';
import 'package:uuid/uuid.dart';

class AddNodeDialog extends StatefulWidget {
  final Function(GridNode) onSave;

  const AddNodeDialog({
    super.key,
    required this.onSave,
  });

  @override
  State<AddNodeDialog> createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends State<AddNodeDialog> {
  late TextEditingController _nameController;
  late TextEditingController _powerController;
  late TextEditingController _lengthController;
  late TextEditingController _crossSectionController;
  late TextEditingController _ratedCurrentController;
  late TextEditingController _notesController;

  String _nodeType =
      'DistributionBoard'; // 'DistributionBoard' or 'PowerReceiver'
  String _material = 'cu'; // 'cu' or 'al'

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _powerController = TextEditingController(text: '10');
    _lengthController = TextEditingController(text: '50');
    _crossSectionController = TextEditingController(text: '2.5');
    _ratedCurrentController = TextEditingController(text: '16');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _powerController.dispose();
    _lengthController.dispose();
    _crossSectionController.dispose();
    _ratedCurrentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Dodaj nowy element',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Node Type Selection
                RadioGroup<String>(
                  groupValue: _nodeType,
                  onChanged: (value) {
                    setState(() => _nodeType = value ?? 'DistributionBoard');
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Rozdzielnica (RG/RB/RO)'),
                          value: 'DistributionBoard',
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Odbiornik'),
                          value: 'PowerReceiver',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa',
                    hintText: 'np. RG, RB-1, RO-2, ZKP-1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Power and Length
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _powerController,
                        decoration: const InputDecoration(
                          labelText: 'Moc (kW)',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _lengthController,
                        decoration: const InputDecoration(
                          labelText: 'Długość (m)',
                          hintText: '50',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cross Section and Material
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _crossSectionController,
                        decoration: const InputDecoration(
                          labelText: 'Przekrój (mm²)',
                          hintText: '2.5',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _material,
                        items: const [
                          DropdownMenuItem(value: 'cu', child: Text('Cu')),
                          DropdownMenuItem(value: 'al', child: Text('Al')),
                        ],
                        onChanged: (value) {
                          setState(() => _material = value ?? 'cu');
                        },
                        decoration: const InputDecoration(
                          labelText: 'Materiał',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Rated Current
                TextField(
                  controller: _ratedCurrentController,
                  decoration: const InputDecoration(
                    labelText: 'Prąd znamionowy (A)',
                    hintText: '16',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Uwagi',
                    hintText: 'Dodaj uwagi...',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: null,
                ),
                const SizedBox(height: 16),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Anuluj'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final nodeId = const Uuid().v4();
                        final materialEnum = _material == 'cu'
                            ? ConductorMaterial.cu
                            : ConductorMaterial.al;

                        final powerKw =
                            double.tryParse(_powerController.text) ?? 10;
                        final lengthM =
                            double.tryParse(_lengthController.text) ?? 50;
                        final crossSectionMm2 =
                            double.tryParse(_crossSectionController.text) ??
                                2.5;
                        final ratedCurrentA =
                            double.tryParse(_ratedCurrentController.text) ?? 16;

                        if (_nodeType == 'DistributionBoard') {
                          final node = DistributionBoard(
                            id: nodeId,
                            name: _nameController.text,
                            powerKw: powerKw,
                            lengthM: lengthM,
                            crossSectionMm2: crossSectionMm2,
                            ratedCurrentA: ratedCurrentA,
                            material: materialEnum,
                            circuitLines: [],
                          );
                          widget.onSave(node);
                        } else {
                          final node = PowerReceiver(
                            id: nodeId,
                            name: _nameController.text,
                            powerKw: powerKw,
                            lengthM: lengthM,
                            crossSectionMm2: crossSectionMm2,
                            ratedCurrentA: ratedCurrentA,
                            material: materialEnum,
                            circuitLines: [],
                          );
                          widget.onSave(node);
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridTheme.electricYellow,
                        foregroundColor: GridTheme.deepNavy,
                      ),
                      child: const Text('Dodaj'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
