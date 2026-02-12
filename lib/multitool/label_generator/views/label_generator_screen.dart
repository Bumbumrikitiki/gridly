import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/label_generator/logic/label_provider.dart';
import 'package:gridly/multitool/label_generator/models/label_models.dart';
import 'package:gridly/multitool/label_generator/services/label_pdf_service.dart';

class LabelGeneratorScreen extends StatelessWidget {
  const LabelGeneratorScreen({super.key});

  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabelProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generator Etykiet'),
          actions: [
            Consumer<LabelProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: provider.label.blocks.isEmpty
                      ? null
                      : () {
                          provider.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Wyczyszczono etykietę'),
                            ),
                          );
                        },
                  tooltip: 'Wyczyść',
                );
              },
            ),
          ],
        ),
        body: Container(
          color: _deepNavy,
          child: Column(
            children: [
              // Panel ustawień
              _buildSettingsPanel(),

              // Podgląd etykiety
              Expanded(child: _buildLabelPreview()),

              // Panel dodawania bloków
              _buildAddBlockPanel(),

              // Przycisk generowania PDF
              _buildGenerateButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Consumer<LabelProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardNavy,
            border: Border(bottom: BorderSide(color: _amber.withOpacity(0.3))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ustawienia etykiety',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Wysokość:',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(width: 12),
                  ...LabelHeight.values.map((height) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(height.label),
                        selected: provider.label.height == height,
                        onSelected: (selected) {
                          if (selected) provider.setHeight(height);
                        },
                        selectedColor: _amber,
                        labelStyle: TextStyle(
                          color: provider.label.height == height
                              ? _deepNavy
                              : Colors.white,
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Szerokość: ${provider.label.totalWidthMm.toStringAsFixed(1)} mm',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabelPreview() {
    return Consumer<LabelProvider>(
      builder: (context, provider, _) {
        if (provider.label.blocks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.label_outline, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'Dodaj bloki aby rozpocząć',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Informacja o skali
                Text(
                  'Podgląd (skala 1:1 w mm)',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                ),
                const SizedBox(height: 16),

                // Etykieta
                _buildPreviewLabel(provider.label),

                const SizedBox(height: 24),

                // Lista bloków do edycji
                ...provider.label.blocks.map((block) {
                  return _buildBlockEditor(context, provider, block);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewLabel(Label label) {
    // Skala wyświetlania: 1mm w rzeczywistości = 2 piksele na ekranie
    const scale = 2.0;

    return Container(
      width: label.totalWidthMm * scale,
      height: label.height.heightMm * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: label.blocks.map((block) {
          return Container(
            width: block.widthMm * scale,
            height: label.height.heightMm * scale,
            decoration: BoxDecoration(
              color: block.backgroundColor,
              border: Border(
                right: BorderSide(color: Colors.black54, width: 1),
              ),
            ),
            child: Center(
              child: block.isVerticalText
                  ? RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        block.text,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Text(
                      block.text,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBlockEditor(
    BuildContext context,
    LabelProvider provider,
    LabelBlock block,
  ) {
    final index = provider.label.blocks.indexOf(block);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Blok ${index + 1}',
                style: TextStyle(color: _amber, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<ModuleWidth>(
                value: block.width,
                dropdownColor: _cardNavy,
                style: TextStyle(color: Colors.white),
                items: ModuleWidth.values.map((width) {
                  return DropdownMenuItem(
                    value: width,
                    child: Text(width.label),
                  );
                }).toList(),
                onChanged: (width) {
                  if (width != null) {
                    provider.updateBlockWidth(block.id, width);
                  }
                },
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.arrow_upward, size: 20),
                color: index > 0 ? Colors.white70 : Colors.white24,
                onPressed: index > 0
                    ? () => provider.moveBlockLeft(block.id)
                    : null,
                tooltip: 'W lewo',
              ),
              IconButton(
                icon: Icon(Icons.arrow_downward, size: 20),
                color: index < provider.label.blocks.length - 1
                    ? Colors.white70
                    : Colors.white24,
                onPressed: index < provider.label.blocks.length - 1
                    ? () => provider.moveBlockRight(block.id)
                    : null,
                tooltip: 'W prawo',
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20),
                color: Colors.redAccent,
                onPressed: () => provider.removeBlock(block.id),
                tooltip: 'Usuń',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: block.text)
              ..selection = TextSelection.collapsed(offset: block.text.length),
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tekst',
              labelStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _amber),
              ),
            ),
            onChanged: (text) => provider.updateBlockText(block.id, text),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorButton(
                context,
                provider,
                block,
                'Biały',
                Colors.white,
              ),
              _buildColorButton(
                context,
                provider,
                block,
                'Żółty',
                Colors.yellow.shade600,
              ),
              _buildColorButton(
                context,
                provider,
                block,
                'Niebieski',
                Colors.blue.shade300,
              ),
              _buildColorButton(
                context,
                provider,
                block,
                'Zielony',
                Colors.green.shade300,
              ),
              _buildColorButton(
                context,
                provider,
                block,
                'Czerwony',
                Colors.red.shade300,
              ),
              _buildColorButton(
                context,
                provider,
                block,
                'Pomarańczowy',
                Colors.orange.shade300,
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: Text(
              'Tekst pionowy (90°)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            value: block.isVerticalText,
            onChanged: (_) => provider.toggleBlockTextOrientation(block.id),
            activeColor: _amber,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(
    BuildContext context,
    LabelProvider provider,
    LabelBlock block,
    String label,
    Color color,
  ) {
    final isSelected = block.backgroundColor == color;

    return InkWell(
      onTap: () => provider.updateBlockColor(block.id, color),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? _amber : Colors.black,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAddBlockPanel() {
    return Consumer<LabelProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cardNavy,
            border: Border(top: BorderSide(color: _amber.withOpacity(0.3))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dodaj moduł',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ModuleWidth.values.map((width) {
                  return ElevatedButton(
                    onPressed: () => provider.addBlock(width),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amber,
                      foregroundColor: _deepNavy,
                    ),
                    child: Text(width.label),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return Consumer<LabelProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _deepNavy,
            border: Border(top: BorderSide(color: _amber.withOpacity(0.3))),
          ),
          child: SafeArea(
            top: false,
            child: ElevatedButton.icon(
              onPressed: provider.label.blocks.isEmpty
                  ? null
                  : () async {
                      await LabelPdfService.showPreview(
                        context,
                        provider.label,
                      );
                    },
              icon: const Icon(Icons.print),
              label: const Text('Generuj PDF do druku'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: _deepNavy,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        );
      },
    );
  }
}
