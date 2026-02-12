import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:gridly/models/circuit_line.dart';
import 'package:gridly/theme/grid_theme.dart';

class CircuitLineEditDialog extends StatefulWidget {
  final CircuitLine? initialLine;
  final Function(CircuitLine) onSave;

  const CircuitLineEditDialog({
    super.key,
    this.initialLine,
    required this.onSave,
  });

  @override
  State<CircuitLineEditDialog> createState() => _CircuitLineEditDialogState();
}

class _CircuitLineEditDialogState extends State<CircuitLineEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _protectionCurrentController;
  late TextEditingController _cableLengthController;
  late TextEditingController _cableSectionController;
  late TextEditingController _ipRatingController;
  late TextEditingController _notesController;

  late String _protectionType;
  late String _cableMaterial;
  late DateTime? _installationDate;
  late DateTime? _lastFailureDate;
  late DateTime? _lastMeasurementDate;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final line = widget.initialLine;
    _nameController = TextEditingController(text: line?.name ?? 'Linia');
    _protectionType = line?.protectionType ?? 'B';
    _protectionCurrentController =
        TextEditingController(text: '${line?.protectionCurrentA ?? 16}');
    _cableLengthController =
        TextEditingController(text: '${line?.cableLength ?? 10}');
    _cableSectionController =
        TextEditingController(text: '${line?.cableCrossSectionMm2 ?? 2.5}');
    _cableMaterial = line?.cableMaterial ?? 'Cu';
    _ipRatingController = TextEditingController(text: line?.ipRating ?? 'IP20');
    _notesController = TextEditingController(text: line?.notes ?? '');
    _installationDate = line?.installationDate;
    _lastFailureDate = line?.lastFailureDate;
    _lastMeasurementDate = line?.lastMeasurementDate;
    _isActive = line?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _protectionCurrentController.dispose();
    _cableLengthController.dispose();
    _cableSectionController.dispose();
    _ipRatingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime) onDateSelected,
    DateTime? initialDate,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      onDateSelected(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  widget.initialLine == null ? 'Nowa linia' : 'Edytuj linię',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // Basic Info
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa linii',
                    hintText: 'np. Linia 1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Protection
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _protectionType,
                        items: ['A', 'B', 'C', 'D'].map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _protectionType = value ?? 'B');
                        },
                        decoration: const InputDecoration(
                          labelText: 'Typ bezp.',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _protectionCurrentController,
                        decoration: const InputDecoration(
                          labelText: 'In (A)',
                          hintText: '16',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cable Parameters
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cableLengthController,
                        decoration: const InputDecoration(
                          labelText: 'Długość (m)',
                          hintText: '10',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _cableSectionController,
                        decoration: const InputDecoration(
                          labelText: 'Przekrój (mm²)',
                          hintText: '2.5',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _cableMaterial,
                        items: const [
                          DropdownMenuItem(value: 'Cu', child: Text('Cu')),
                          DropdownMenuItem(value: 'Al', child: Text('Al')),
                        ],
                        onChanged: (value) {
                          setState(() => _cableMaterial = value ?? 'Cu');
                        },
                        decoration: const InputDecoration(
                          labelText: 'Materiał',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ipRatingController,
                        decoration: const InputDecoration(
                          labelText: 'IP',
                          hintText: 'IP20',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dates
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Data montażu:'),
                      TextButton(
                        onPressed: () => _selectDate(
                          context,
                          (date) => setState(() => _installationDate = date),
                          _installationDate,
                        ),
                        child: Text(
                          _installationDate?.toString().split(' ')[0] ??
                              'Brak',
                          style:
                              const TextStyle(color: GridTheme.electricYellow),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ostatnia awaria:'),
                      TextButton(
                        onPressed: () => _selectDate(
                          context,
                          (date) => setState(() => _lastFailureDate = date),
                          _lastFailureDate,
                        ),
                        child: Text(
                          _lastFailureDate?.toString().split(' ')[0] ??
                              'Brak',
                          style:
                              const TextStyle(color: GridTheme.electricYellow),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ostatni pomiar:'),
                      TextButton(
                        onPressed: () => _selectDate(
                          context,
                          (date) =>
                              setState(() => _lastMeasurementDate = date),
                          _lastMeasurementDate,
                        ),
                        child: Text(
                          _lastMeasurementDate?.toString().split(' ')[0] ??
                              'Brak',
                          style:
                              const TextStyle(color: GridTheme.electricYellow),
                        ),
                      ),
                    ],
                  ),
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
                const SizedBox(height: 12),

                // Active status
                CheckboxListTile(
                  title: const Text('Linia aktywna'),
                  value: _isActive,
                  onChanged: (value) =>
                      setState(() => _isActive = value ?? true),
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
                        final line = CircuitLine(
                          id: widget.initialLine?.id ?? const Uuid().v4(),
                          name: _nameController.text,
                          protectionType: _protectionType,
                          protectionCurrentA: double.tryParse(
                                  _protectionCurrentController.text) ??
                              16,
                          cableLength: double.tryParse(
                                  _cableLengthController.text) ??
                              10,
                          cableCrossSectionMm2: double.tryParse(
                                  _cableSectionController.text) ??
                              2.5,
                          cableMaterial: _cableMaterial,
                          ipRating: _ipRatingController.text,
                          installationDate: _installationDate,
                          lastFailureDate: _lastFailureDate,
                          lastMeasurementDate: _lastMeasurementDate,
                          notes: _notesController.text,
                          isActive: _isActive,
                        );
                        widget.onSave(line);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridTheme.electricYellow,
                        foregroundColor: GridTheme.deepNavy,
                      ),
                      child: const Text('Zapisz'),
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
