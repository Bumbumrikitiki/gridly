import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/label_generator/logic/label_provider.dart';
import 'package:gridly/multitool/label_generator/models/label_models.dart';
import 'package:gridly/multitool/label_generator/services/label_pdf_service.dart';

class LabelGeneratorScreen extends StatefulWidget {
  const LabelGeneratorScreen({super.key});

  @override
  State<LabelGeneratorScreen> createState() => _LabelGeneratorScreenState();
}

class _LabelGeneratorScreenState extends State<LabelGeneratorScreen> {

  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  final FocusNode _textFocusNode = FocusNode();
  final GlobalKey _editorKey = GlobalKey();

  @override
  void dispose() {
    _textFocusNode.dispose();
    super.dispose();
  }

  void _handleBlockSelected(
    BuildContext context,
    LabelProvider provider,
    String blockId,
  ) {
    provider.selectBlock(blockId);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final editorContext = _editorKey.currentContext;
      if (editorContext != null) {
        Scrollable.ensureVisible(
          editorContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      }

      _textFocusNode.requestFocus();
    });
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showOverflowDialog(
    BuildContext context,
    LabelProvider provider,
    ModuleWidth width,
  ) {
    final remaining =
        LabelProvider.maxLabelLengthMm - provider.label.totalWidthMm;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E3A5F),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Blok się nie mieści',
            style: TextStyle(color: Color(0xFFF7B500), fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Blok ${width.label} (${width.widthMm.toStringAsFixed(1)} mm) przekracza '
            'dostępne miejsce.\n\n'
            'Pozostało: ${remaining.toStringAsFixed(1)} mm '
            '(limit: ${LabelProvider.maxLabelLengthMm.toStringAsFixed(0)} mm).\n\n'
            'Utwórz nową stronę, aby dodać blok na osobnej etykiecie.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Anuluj',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            if (provider.canAddPage)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF7B500),
                  foregroundColor: const Color(0xFF102A43),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  final pageAdded = provider.addPage();
                  if (pageAdded) {
                    provider.addBlock(width);
                  } else {
                    _showInfo(context, 'Nie można dodać więcej stron.');
                  }
                },
                child: const Text('Utwórz nową stronę'),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Osiągnięto limit stron.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LabelProvider(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Generator znaczników opisowych'),
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ustawienia etykiety',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    onPressed: provider.toggleSettingsCollapsed,
                    tooltip: provider.isSettingsCollapsed ? 'Rozwiń' : 'Zwiń',
                    icon: Icon(
                      provider.isSettingsCollapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (!provider.isSettingsCollapsed) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: provider.currentPageIndex > 0
                        ? provider.previousPage
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Poprzednia'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  Text(
                    'Strona ${provider.currentPageIndex + 1}/${LabelProvider.maxPages}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                  OutlinedButton.icon(
                    onPressed: provider.currentPageIndex < provider.pagesCount - 1
                        ? provider.nextPage
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Następna'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: provider.canAddPage
                        ? () {
                            final created = provider.addPage();
                            if (!created) {
                              _showInfo(
                                context,
                                'Maksymalnie ${LabelProvider.maxPages} stron.',
                              );
                            }
                          }
                        : null,
                    icon: const Icon(Icons.note_add_outlined),
                    label: const Text('Nowa strona'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amber,
                      foregroundColor: _deepNavy,
                    ),
                  ),
                ],
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
                'Szerokość: ${provider.label.totalWidthMm.toStringAsFixed(1)} / ${LabelProvider.maxLabelLengthMm.toStringAsFixed(0)} mm',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                'Limit długości paska = dłuższy bok A4 (297 mm)',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text(
                    'Widok paska:',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  ChoiceChip(
                    label: const Text('Poziomo'),
                    selected: !provider.isPreviewVertical,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setPreviewVertical(false);
                      }
                    },
                    selectedColor: _amber,
                    labelStyle: TextStyle(
                      color: !provider.isPreviewVertical
                          ? _deepNavy
                          : Colors.white,
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Pionowo'),
                    selected: provider.isPreviewVertical,
                    onSelected: (selected) {
                      if (selected) {
                        provider.setPreviewVertical(true);
                      }
                    },
                    selectedColor: _amber,
                    labelStyle: TextStyle(
                      color: provider.isPreviewVertical
                          ? _deepNavy
                          : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: _amber,
                value: provider.fillA4Page,
                onChanged: provider.setFillA4Page,
                title: const Text(
                  'Wypełnij całą stronę A4',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Powiel pasek na całym arkuszu bez przerw',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeColor: _amber,
                value: provider.useSafePrintMargin,
                onChanged: provider.setUseSafePrintMargin,
                title: Text(
                  'Bezpieczny margines drukarki (${LabelProvider.safePrintMarginMm.toStringAsFixed(0)} mm)',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Zmniejsza ryzyko ucinania przy braku druku bez marginesów',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ],
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

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Podgląd (skala 1:1 w mm)',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: provider.isPreviewVertical
                    ? RotatedBox(
                        quarterTurns: 3,
                        child: _buildPreviewLabel(
                          provider.label,
                          provider.selectedBlockId,
                          onSelect: (blockId) => _handleBlockSelected(
                            context,
                            provider,
                            blockId,
                          ),
                        ),
                      )
                    : _buildPreviewLabel(
                        provider.label,
                        provider.selectedBlockId,
                        onSelect: (blockId) => _handleBlockSelected(
                          context,
                          provider,
                          blockId,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSharedTextEditor(context, provider),
            const SizedBox(height: 12),
            ...provider.label.blocks.map((block) {
              return _buildBlockEditor(
                context,
                provider,
                block,
                onSelect: (blockId) => _handleBlockSelected(
                  context,
                  provider,
                  blockId,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildPreviewLabel(
    Label label,
    String? selectedBlockId, {
    required ValueChanged<String> onSelect,
  }) {
    // Skala wyświetlania: 1mm w rzeczywistości = 2 piksele na ekranie
    const scale = 2.0;
    const borderCompensation = 4.0;

    return Container(
      width: (label.totalWidthMm * scale) + borderCompensation,
      height: (label.height.heightMm * scale) + borderCompensation,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: label.blocks.asMap().entries.map((entry) {
          final block = entry.value;
          final isLast = entry.key == label.blocks.length - 1;
          final isSelected = block.id == selectedBlockId;

          return InkWell(
            onTap: () => onSelect(block.id),
            child: Container(
              width: block.widthMm * scale,
              height: label.height.heightMm * scale,
              decoration: BoxDecoration(
                color: block.backgroundColor,
                border: isSelected
                    ? Border.all(color: _amber, width: 2)
                    : Border(
                        right: isLast
                            ? BorderSide.none
                            : BorderSide(color: Colors.black54, width: 1),
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
                            color: block.backgroundColor.computeLuminance() >
                                    0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Text(
                        block.text,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: block.backgroundColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
    LabelBlock block, {
    required ValueChanged<String> onSelect,
  }
  ) {
    final index = provider.label.blocks.indexOf(block);
    final isSelected = provider.selectedBlockId == block.id;

    return GestureDetector(
      onTap: () => onSelect(block.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _cardNavy,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _amber : _amber.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blok ${index + 1}',
                    style: TextStyle(color: _amber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Szerokość: ${block.width.label}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _amber,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AKTYWNY',
                  style: TextStyle(
                    color: _deepNavy,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedTextEditor(BuildContext context, LabelProvider provider) {
    final selected = provider.selectedBlock;
    final isEnabled = selected != null;
    final text = selected?.text ?? '';
    final selectedId = provider.selectedBlockId;
    final selectedIndex = selected == null
        ? -1
        : provider.label.blocks.indexWhere((block) => block.id == selected.id);

    return Container(
      key: _editorKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _cardNavy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _amber.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEnabled
                ? 'Edycja: Blok ${selectedIndex + 1}'
                : 'Edycja tekstu: wybierz blok',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                    color: _deepNavy.withOpacity(0.35),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ModuleWidth>(
                      value: selected?.width,
                      isExpanded: true,
                      hint: const Text('Szerokość modułu'),
                      dropdownColor: _cardNavy,
                      iconEnabledColor: _amber,
                      style: const TextStyle(color: Colors.white),
                      items: ModuleWidth.values.map((width) {
                        return DropdownMenuItem(
                          value: width,
                          child: Text(width.label),
                        );
                      }).toList(),
                      onChanged: isEnabled
                          ? (width) {
                              if (width == null || selectedId == null) return;
                              final updated = provider.updateBlockWidth(
                                selectedId,
                                width,
                              );
                              if (!updated) {
                                _showInfo(
                                  context,
                                  'Nie można przekroczyć ${LabelProvider.maxLabelLengthMm.toStringAsFixed(0)} mm (dłuższy bok A4).',
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                color: isEnabled && selectedIndex > 0
                    ? Colors.white70
                    : Colors.white24,
                onPressed: isEnabled && selectedIndex > 0
                    ? () => provider.moveBlockUpAt(selectedIndex)
                    : null,
                tooltip: 'Przesuń wyżej',
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                color: isEnabled && selectedIndex < provider.label.blocks.length - 1
                    ? Colors.white70
                    : Colors.white24,
                onPressed: isEnabled && selectedIndex < provider.label.blocks.length - 1
                    ? () => provider.moveBlockDownAt(selectedIndex)
                    : null,
                tooltip: 'Przesuń niżej',
              ),
              TextButton(
                onPressed: isEnabled && selectedId != null
                    ? () => provider.removeBlock(selectedId)
                    : null,
                child: const Text('Usuń pole'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey(selectedId ?? 'none'),
            enabled: isEnabled,
            focusNode: _textFocusNode,
            autofocus: isEnabled,
            initialValue: text,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Tekst pola',
              hintText: 'Kliknij blok i wpisz tekst',
              labelStyle: const TextStyle(color: Colors.white70),
              hintStyle: const TextStyle(color: Colors.white38),
              border: const OutlineInputBorder(),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _amber),
              ),
            ),
            onChanged: (value) {
              final selectedId = provider.selectedBlockId;
              if (selectedId != null) {
                provider.updateBlockText(selectedId, value);
              }
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildColorButton(
                context,
                provider,
                selected ?? LabelBlock(id: ''),
                'Biały',
                Colors.white,
              ),
              _buildColorButton(
                context,
                provider,
                selected ?? LabelBlock(id: ''),
                'Żółty',
                Colors.yellow.shade600,
              ),
              _buildColorButton(
                context,
                provider,
                selected ?? LabelBlock(id: ''),
                'Niebieski',
                Colors.blue.shade300,
              ),
              _buildColorButton(
                context,
                provider,
                selected ?? LabelBlock(id: ''),
                'Zielony',
                Colors.green.shade300,
              ),
              _buildColorButton(
                context,
                provider,
                selected ?? LabelBlock(id: ''),
                'Czerwony',
                Colors.red.shade300,
              ),
              _buildColorButton(
                context,
                provider,
                selected ?? LabelBlock(id: ''),
                'Pomarańczowy',
                Colors.orange.shade300,
              ),
            ],
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text(
              'Tekst pionowy (90°)',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            value: selected?.isVerticalText ?? false,
            onChanged: isEnabled && selectedId != null
                ? (_) => provider.toggleBlockTextOrientation(selectedId)
                : null,
            activeColor: _amber,
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
    if (block.id.isEmpty) {
      return Opacity(
        opacity: 0.4,
        child: IgnorePointer(
          child: _buildColorButtonContent(label, color, false),
        ),
      );
    }

    final isSelected = block.backgroundColor == color;

    return InkWell(
      onTap: () => provider.updateBlockColor(block.id, color),
      child: _buildColorButtonContent(label, color, isSelected),
    );
  }

  Widget _buildColorButtonContent(String label, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(
          color: isSelected ? _amber : Colors.black,
          width: isSelected ? 3 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        padding: EdgeInsets.zero,
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
                    onPressed: () {
                      final added = provider.addBlock(width);
                      if (!added) {
                        _showOverflowDialog(context, provider, width);
                      }
                    },
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
              onPressed: !provider.hasAnyContent
                  ? null
                  : () async {
                      await LabelPdfService.showPreview(
                        context,
                        provider.labels,
                        fillA4Page: provider.fillA4Page,
                        safeMarginMm: provider.useSafePrintMargin
                            ? LabelProvider.safePrintMarginMm
                            : 0,
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
