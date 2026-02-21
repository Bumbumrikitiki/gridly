import 'package:flutter/material.dart';
import 'package:gridly/multitool/symbols/models/single_line_symbol.dart';
import 'package:gridly/multitool/symbols/services/single_line_symbols_database.dart';

class SingleLineSymbolsScreen extends StatefulWidget {
  const SingleLineSymbolsScreen({super.key});

  @override
  State<SingleLineSymbolsScreen> createState() => _SingleLineSymbolsScreenState();
}

class _SingleLineSymbolsScreenState extends State<SingleLineSymbolsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Wszystkie';
  bool _strictIecMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = SingleLineSymbolsDatabase.categories();
    final symbols = SingleLineSymbolsDatabase.symbols;

    final filtered = symbols.where((symbol) {
      final query = _searchQuery.trim().toLowerCase();
      final matchesCategory =
          _selectedCategory == 'Wszystkie' || symbol.category == _selectedCategory;
      final matchesQuery = query.isEmpty ||
          symbol.code.toLowerCase().contains(query) ||
          symbol.name.toLowerCase().contains(query) ||
          symbol.description.toLowerCase().contains(query) ||
          symbol.useCase.toLowerCase().contains(query) ||
          (symbol.standardRef?.toLowerCase().contains(query) ?? false) ||
          symbol.keywords.any((keyword) => keyword.toLowerCase().contains(query));
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Symbole jednokreskowe'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Szukaj po nazwie, kodzie lub opisie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: categories.length,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.rule, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _strictIecMode
                        ? 'Tryb symboli: PN-EN 60617'
                        : 'Tryb symboli: projektowy',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Switch(
                  value: _strictIecMode,
                  onChanged: (value) {
                    setState(() {
                      _strictIecMode = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('Brak symboli spełniających kryteria.'),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final symbol = filtered[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black26),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: _SingleLineSymbolGraphic(
                                  symbol: symbol,
                                  color: Colors.black87,
                                  strictIecMode: _strictIecMode,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            symbol.code,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      symbol.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      symbol.description,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showDetails(context, symbol),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, SingleLineSymbol symbol) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[500],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(label: symbol.code),
                      _TagChip(label: symbol.category),
                      if (symbol.standardRef != null)
                        _TagChip(label: symbol.standardRef!),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    height: 96,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black26),
                      color: Colors.white,
                    ),
                    child: _SingleLineSymbolGraphic(
                      symbol: symbol,
                      color: Colors.black87,
                      strokeWidth: 2.4,
                      strictIecMode: _strictIecMode,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    symbol.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Opis',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(symbol.description),
                  const SizedBox(height: 14),
                  Text(
                    'Gdzie stosować',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(symbol.useCase),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SingleLineSymbolGraphic extends StatelessWidget {
  const _SingleLineSymbolGraphic({
    required this.symbol,
    required this.color,
    required this.strictIecMode,
    this.strokeWidth = 2,
  });

  final SingleLineSymbol symbol;
  final Color color;
  final bool strictIecMode;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SingleLineSymbolPainter(
        symbol: symbol,
        color: color,
        strictIecMode: strictIecMode,
        strokeWidth: strokeWidth,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SingleLineSymbolPainter extends CustomPainter {
  const _SingleLineSymbolPainter({
    required this.symbol,
    required this.color,
    required this.strictIecMode,
    required this.strokeWidth,
  });

  final SingleLineSymbol symbol;
  final Color color;
  final bool strictIecMode;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final cy = h / 2;
    final type = symbol.graphicType;

    void drawCodeTag(String text) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: (h * 0.14).clamp(8, 12).toDouble(),
            fontWeight: FontWeight.w700,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: w - 8);
      textPainter.paint(canvas, Offset(w - textPainter.width - 3, 2));
    }

    void drawMainLine() {
      canvas.drawLine(Offset(4, cy), Offset(w - 4, cy), paint);
    }

    bool drawCodeSpecific() {
      switch (symbol.code) {
        case 'QF':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 14, height: 11), paint);
          canvas.drawLine(Offset(w / 2 - 5, cy), Offset(w / 2 + 5, cy), paint);
          return true;
        case 'QFM':
        case 'ACB':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 22, height: 13), paint);
          canvas.drawLine(Offset(w / 2 - 8, cy - 4), Offset(w / 2 + 8, cy + 4), paint);
          return true;
        case 'QFD':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 13), paint);
          canvas.drawLine(Offset(w / 2 - 6, cy - 6), Offset(w / 2 + 6, cy + 6), paint);
          canvas.drawCircle(Offset(w / 2, cy - 8), 1.8, paint);
          return true;
        case 'QFRC':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 20, height: 13), paint);
          canvas.drawLine(Offset(w / 2 - 7, cy - 6), Offset(w / 2 + 7, cy + 6), paint);
          canvas.drawLine(Offset(w / 2 - 6, cy), Offset(w / 2 + 6, cy), paint);
          return true;
        case 'QS':
        case 'Q0':
        case 'QD':
          canvas.drawLine(Offset(4, cy), Offset(w / 2 - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 4, cy), paint);
          canvas.drawLine(Offset(w / 2 - 2, cy + 7), Offset(w / 2 + 8, cy - 6), paint);
          return true;
        case 'FU':
        case 'FR':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 14, height: 8), paint);
          canvas.drawLine(Offset(w / 2 - 5, cy + 4), Offset(w / 2 + 5, cy - 4), paint);
          return true;
        case 'KM':
        case 'KA':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 8, paint);
          canvas.drawLine(Offset(w / 2 - 5, cy), Offset(w / 2 + 5, cy), paint);
          return true;
        case 'RT':
          drawMainLine();
          final thermalPath = Path()
            ..moveTo(w / 2 - 8, cy + 4)
            ..quadraticBezierTo(w / 2 - 2, cy - 7, w / 2 + 4, cy + 4)
            ..quadraticBezierTo(w / 2 + 6, cy + 8, w / 2 + 8, cy + 2);
          canvas.drawPath(thermalPath, paint);
          return true;
        case 'M':
        case 'MS':
        case 'PMP':
        case 'PMP-FIRE':
        case 'FAN':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 11, paint);
          if (symbol.code == 'PMP' || symbol.code == 'PMP-FIRE') {
            final tri = Path()
              ..moveTo(w / 2 + 3, cy)
              ..lineTo(w / 2 + 10, cy - 4)
              ..lineTo(w / 2 + 10, cy + 4)
              ..close();
            canvas.drawPath(tri, paint);
          }
          if (symbol.code == 'FAN') {
            canvas.drawLine(Offset(w / 2 - 6, cy), Offset(w / 2 + 6, cy), paint);
            canvas.drawLine(Offset(w / 2, cy - 6), Offset(w / 2, cy + 6), paint);
          }
          return true;
        case 'TR':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2 - 6, cy), 6, paint);
          canvas.drawCircle(Offset(w / 2 + 6, cy), 6, paint);
          canvas.drawLine(Offset(w / 2 - 1, cy - 6), Offset(w / 2 - 1, cy + 6), paint);
          canvas.drawLine(Offset(w / 2 + 1, cy - 6), Offset(w / 2 + 1, cy + 6), paint);
          return true;
        case 'G':
        case 'CHP':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 10, paint);
          canvas.drawLine(Offset(w / 2 - 4, cy - 4), Offset(w / 2 + 4, cy + 4), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy + 4), Offset(w / 2 + 4, cy - 4), paint);
          return true;
        case 'PV':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 15, height: 10), paint);
          canvas.drawLine(Offset(w / 2, cy - 10), Offset(w / 2, cy - 14), paint);
          canvas.drawLine(Offset(w / 2 - 10, cy - 10), Offset(w / 2 - 13, cy - 13), paint);
          canvas.drawLine(Offset(w / 2 + 10, cy - 10), Offset(w / 2 + 13, cy - 13), paint);
          return true;
        case 'BAT':
        case 'ESS':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 16, height: 10), paint);
          canvas.drawLine(Offset(w / 2 + 8, cy - 3), Offset(w / 2 + 10, cy - 3), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy), Offset(w / 2 + 2, cy), paint);
          canvas.drawLine(Offset(w / 2 - 1, cy - 3), Offset(w / 2 - 1, cy + 3), paint);
          return true;
        case 'UPS':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 12), paint);
          final wave = Path()
            ..moveTo(w / 2 - 6, cy + 2)
            ..quadraticBezierTo(w / 2 - 3, cy - 2, w / 2, cy + 2)
            ..quadraticBezierTo(w / 2 + 3, cy + 6, w / 2 + 6, cy + 2);
          canvas.drawPath(wave, paint);
          return true;
        case 'INV':
        case 'VFD':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 17, height: 12), paint);
          canvas.drawLine(Offset(w / 2 - 5, cy + 5), Offset(w / 2 + 5, cy + 5), paint);
          canvas.drawLine(Offset(w / 2 + 5, cy + 5), Offset(w / 2 + 2, cy + 2), paint);
          canvas.drawLine(Offset(w / 2 + 5, cy + 5), Offset(w / 2 + 2, cy + 8), paint);
          return true;
        case 'ATS':
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 24, height: 16), paint);
          canvas.drawLine(Offset(w / 2 - 12, cy), Offset(4, cy), paint);
          canvas.drawLine(Offset(w / 2 + 12, cy), Offset(w - 4, cy), paint);
          canvas.drawLine(Offset(w / 2 - 5, cy - 4), Offset(w / 2 + 5, cy + 4), paint);
          return true;
        case 'RG':
        case 'RP':
        case 'RPOZ':
          canvas.drawRect(Rect.fromLTWH(8, 10, w - 16, h - 20), paint);
          canvas.drawLine(Offset(12, cy), Offset(w - 12, cy), paint);
          return true;
        case 'TB':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2 - 7, cy), 2, paint);
          canvas.drawCircle(Offset(w / 2, cy), 2, paint);
          canvas.drawCircle(Offset(w / 2 + 7, cy), 2, paint);
          return true;
        case 'MSB':
        case 'BB-CPL':
        case 'BB':
          canvas.drawLine(Offset(4, cy), Offset(w - 4, cy), paint..strokeWidth = strokeWidth + 1.6);
          if (symbol.code == 'BB-CPL') {
            canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 8, height: 8), paint);
          }
          return true;
        case 'PE':
        case 'GSU':
        case 'LPS':
          canvas.drawLine(Offset(w / 2, 8), Offset(w / 2, cy + 2), paint);
          canvas.drawLine(Offset(w / 2 - 10, cy + 2), Offset(w / 2 + 10, cy + 2), paint);
          canvas.drawLine(Offset(w / 2 - 7, cy + 7), Offset(w / 2 + 7, cy + 7), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy + 11), Offset(w / 2 + 4, cy + 11), paint);
          return true;
        case 'SPD-T1':
        case 'SPD-T2':
          canvas.drawLine(Offset(4, cy), Offset(w / 2 - 2, cy), paint);
          canvas.drawLine(Offset(w / 2 + 2, cy), Offset(w - 12, cy), paint);
          canvas.drawLine(Offset(w - 12, cy), Offset(w - 12, cy + 8), paint);
          canvas.drawLine(Offset(w - 18, cy + 8), Offset(w - 6, cy + 8), paint);
          canvas.drawLine(Offset(w - 15, cy + 12), Offset(w - 9, cy + 12), paint);
          final lightning = Path()
            ..moveTo(w / 2 - 1, cy - 8)
            ..lineTo(w / 2 + 5, cy - 1)
            ..lineTo(w / 2 + 1, cy - 1)
            ..lineTo(w / 2 + 7, cy + 7);
          canvas.drawPath(lightning, paint);
          return true;
        case 'PEN':
          drawMainLine();
          canvas.drawLine(Offset(w / 2, cy), Offset(w / 2, h - 12), paint);
          canvas.drawLine(Offset(w / 2 - 7, h - 12), Offset(w / 2 + 7, h - 12), paint);
          canvas.drawLine(Offset(w / 2 - 4, h - 8), Offset(w / 2 + 4, h - 8), paint);
          return true;
        case 'CT':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 7, paint);
          return true;
        case 'VT':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 16, height: 12), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy - 4), Offset(w / 2 + 4, cy + 4), paint);
          canvas.drawLine(Offset(w / 2 + 4, cy - 4), Offset(w / 2 - 4, cy + 4), paint);
          return true;
        case 'kWh':
        case 'PQM':
        case 'A':
        case 'V':
        case 'Hz':
        case 'cosφ':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 14), paint);
          return true;
        case 'APFC':
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 20, height: 14), paint);
          canvas.drawLine(Offset(w / 2 - 5, cy + 4), Offset(w / 2 + 5, cy + 4), paint);
          return true;
        case 'XK':
        case 'YKY':
        case 'N2XH':
        case 'PH90':
          final cablePath = Path()
            ..moveTo(4, cy + 4)
            ..quadraticBezierTo(w / 4, cy - 6, w / 2, cy + 4)
            ..quadraticBezierTo(3 * w / 4, cy + 12, w - 4, cy + 4);
          canvas.drawPath(cablePath, paint);
          return true;
        case 'TRAY':
          canvas.drawLine(Offset(4, cy - 3), Offset(w - 4, cy - 3), paint);
          canvas.drawLine(Offset(4, cy + 3), Offset(w - 4, cy + 3), paint);
          return true;
        case 'NO':
          canvas.drawLine(Offset(6, cy), Offset(w / 2 - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy + 6), Offset(w / 2 + 5, cy - 6), paint);
          return true;
        case 'NC':
          canvas.drawLine(Offset(6, cy), Offset(w / 2 - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy - 6), Offset(w / 2 + 5, cy + 6), paint);
          return true;
        case 'S0':
        case 'S1':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy - 8), 4, paint);
          canvas.drawLine(Offset(w / 2, cy - 4), Offset(w / 2, cy + 5), paint);
          return true;
        case 'H':
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 9, paint);
          canvas.drawLine(Offset(w / 2 - 5, cy - 5), Offset(w / 2 + 5, cy + 5), paint);
          canvas.drawLine(Offset(w / 2 + 5, cy - 5), Offset(w / 2 - 5, cy + 5), paint);
          return true;
        case 'PLC':
        case 'I/O':
        case 'HMI':
        case 'BMS':
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 24, height: 16), paint);
          canvas.drawLine(Offset(w / 2 - 12, cy), Offset(4, cy), paint);
          canvas.drawLine(Offset(w / 2 + 12, cy), Offset(w - 4, cy), paint);
          return true;
        case 'PWP':
        case 'EPO':
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 24, height: 16), paint);
          canvas.drawCircle(Offset(w / 2, cy), 5, paint);
          return true;
        case 'XREF':
          canvas.drawCircle(Offset(w / 2, cy), 9, paint);
          canvas.drawLine(Offset(w / 2 + 5, cy - 5), Offset(w / 2 + 12, cy - 12), paint);
          canvas.drawLine(Offset(w / 2 + 12, cy - 12), Offset(w / 2 + 8, cy - 12), paint);
          canvas.drawLine(Offset(w / 2 + 12, cy - 12), Offset(w / 2 + 12, cy - 8), paint);
          return true;
        default:
          return false;
      }
    }

    void drawStrictByType() {
      switch (type) {
        case SingleLineGraphicType.breaker:
          drawMainLine();
          canvas.drawRect(
            Rect.fromCenter(center: Offset(w / 2, cy), width: 16, height: 12),
            paint,
          );
          break;
        case SingleLineGraphicType.rcd:
          drawMainLine();
          canvas.drawRect(
            Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 13),
            paint,
          );
          canvas.drawLine(
            Offset(w / 2 - 6, cy - 6),
            Offset(w / 2 + 6, cy + 6),
            paint,
          );
          break;
        case SingleLineGraphicType.rcbo:
          drawMainLine();
          canvas.drawRect(
            Rect.fromCenter(center: Offset(w / 2, cy), width: 20, height: 13),
            paint,
          );
          canvas.drawLine(
            Offset(w / 2 - 7, cy - 6),
            Offset(w / 2 + 7, cy + 6),
            paint,
          );
          break;
        case SingleLineGraphicType.isolator:
          canvas.drawLine(Offset(4, cy), Offset(w / 2 - 5, cy), paint);
          canvas.drawLine(Offset(w / 2 + 5, cy), Offset(w - 4, cy), paint);
          canvas.drawLine(Offset(w / 2 - 3, cy + 6), Offset(w / 2 + 5, cy - 6), paint);
          break;
        case SingleLineGraphicType.fuse:
          drawMainLine();
          canvas.drawRect(
            Rect.fromCenter(center: Offset(w / 2, cy), width: 14, height: 8),
            paint,
          );
          break;
        case SingleLineGraphicType.contactor:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 8, paint);
          break;
        case SingleLineGraphicType.thermal:
          drawMainLine();
          final path = Path()
            ..moveTo(w / 2 - 8, cy + 5)
            ..quadraticBezierTo(w / 2 - 2, cy - 6, w / 2 + 4, cy + 4)
            ..quadraticBezierTo(w / 2 + 6, cy + 7, w / 2 + 8, cy + 2);
          canvas.drawPath(path, paint);
          break;
        case SingleLineGraphicType.motor:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 11, paint);
          break;
        case SingleLineGraphicType.source:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 10, paint);
          break;
        case SingleLineGraphicType.transformer:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2 - 6, cy), 6, paint);
          canvas.drawCircle(Offset(w / 2 + 6, cy), 6, paint);
          break;
        case SingleLineGraphicType.board:
          canvas.drawRect(Rect.fromLTWH(8, 10, w - 16, h - 20), paint);
          break;
        case SingleLineGraphicType.terminal:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2 - 7, cy), 2, paint);
          canvas.drawCircle(Offset(w / 2 + 7, cy), 2, paint);
          break;
        case SingleLineGraphicType.phase:
          drawMainLine();
          canvas.drawLine(Offset(w / 2 - 10, cy - 9), Offset(w / 2 - 10, cy + 9), paint);
          canvas.drawLine(Offset(w / 2, cy - 9), Offset(w / 2, cy + 9), paint);
          canvas.drawLine(Offset(w / 2 + 10, cy - 9), Offset(w / 2 + 10, cy + 9), paint);
          break;
        case SingleLineGraphicType.neutral:
          drawMainLine();
          canvas.drawLine(Offset(w / 2, cy - 9), Offset(w / 2, cy + 9), paint);
          break;
        case SingleLineGraphicType.pe:
        case SingleLineGraphicType.grounding:
          canvas.drawLine(Offset(w / 2, 8), Offset(w / 2, cy + 2), paint);
          canvas.drawLine(Offset(w / 2 - 10, cy + 2), Offset(w / 2 + 10, cy + 2), paint);
          canvas.drawLine(Offset(w / 2 - 7, cy + 7), Offset(w / 2 + 7, cy + 7), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy + 11), Offset(w / 2 + 4, cy + 11), paint);
          break;
        case SingleLineGraphicType.pen:
          drawMainLine();
          canvas.drawLine(Offset(w / 2, cy), Offset(w / 2, h - 12), paint);
          canvas.drawLine(Offset(w / 2 - 7, h - 12), Offset(w / 2 + 7, h - 12), paint);
          canvas.drawLine(Offset(w / 2 - 4, h - 8), Offset(w / 2 + 4, h - 8), paint);
          break;
        case SingleLineGraphicType.meter:
          drawMainLine();
          canvas.drawRect(
            Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 14),
            paint,
          );
          break;
        case SingleLineGraphicType.cable:
          final path = Path()
            ..moveTo(4, cy + 4)
            ..quadraticBezierTo(w / 4, cy - 6, w / 2, cy + 4)
            ..quadraticBezierTo(3 * w / 4, cy + 12, w - 4, cy + 4);
          canvas.drawPath(path, paint);
          break;
        case SingleLineGraphicType.busbar:
          canvas.drawLine(Offset(4, cy), Offset(w - 4, cy), paint..strokeWidth = strokeWidth + 1.5);
          break;
        case SingleLineGraphicType.lineReserved:
          const dash = 6.0;
          const gap = 4.0;
          double x = 4;
          while (x < w - 4) {
            canvas.drawLine(Offset(x, cy), Offset((x + dash).clamp(0, w - 4), cy), paint);
            x += dash + gap;
          }
          break;
        case SingleLineGraphicType.noContact:
          canvas.drawLine(Offset(6, cy), Offset(w / 2 - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy + 6), Offset(w / 2 + 5, cy - 6), paint);
          break;
        case SingleLineGraphicType.ncContact:
          canvas.drawLine(Offset(6, cy), Offset(w / 2 - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 6, cy), paint);
          canvas.drawLine(Offset(w / 2 - 4, cy - 6), Offset(w / 2 + 5, cy + 6), paint);
          break;
        case SingleLineGraphicType.pushButton:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy - 8), 4, paint);
          canvas.drawLine(Offset(w / 2, cy - 4), Offset(w / 2, cy + 5), paint);
          break;
        case SingleLineGraphicType.lamp:
          drawMainLine();
          canvas.drawCircle(Offset(w / 2, cy), 9, paint);
          canvas.drawLine(Offset(w / 2 - 5, cy - 5), Offset(w / 2 + 5, cy + 5), paint);
          canvas.drawLine(Offset(w / 2 + 5, cy - 5), Offset(w / 2 - 5, cy + 5), paint);
          break;
        case SingleLineGraphicType.automation:
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 24, height: 16), paint);
          canvas.drawLine(Offset(w / 2 - 12, cy), Offset(4, cy), paint);
          canvas.drawLine(Offset(w / 2 + 12, cy), Offset(w - 4, cy), paint);
          break;
        case SingleLineGraphicType.generic:
          drawMainLine();
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 12, height: 12), paint);
          break;
      }
    }

    if (strictIecMode) {
      drawStrictByType();
      return;
    }

    if (drawCodeSpecific()) {
      drawCodeTag(symbol.code);
      return;
    }

    switch (type) {
      case SingleLineGraphicType.breaker:
        drawMainLine();
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 16, height: 12), paint);
        break;
      case SingleLineGraphicType.rcd:
        drawMainLine();
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 13), paint);
        canvas.drawLine(Offset(w / 2 - 6, cy - 6), Offset(w / 2 + 6, cy + 6), paint);
        break;
      case SingleLineGraphicType.rcbo:
        drawMainLine();
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 20, height: 13), paint);
        canvas.drawLine(Offset(w / 2 - 7, cy - 6), Offset(w / 2 + 7, cy + 6), paint);
        canvas.drawCircle(Offset(w / 2 + 8, cy - 8), 2.2, paint);
        break;
      case SingleLineGraphicType.isolator:
        canvas.drawLine(Offset(4, cy), Offset(w / 2 - 5, cy), paint);
        canvas.drawLine(Offset(w / 2 + 5, cy), Offset(w - 4, cy), paint);
        canvas.drawLine(Offset(w / 2 - 3, cy + 6), Offset(w / 2 + 5, cy - 6), paint);
        break;
      case SingleLineGraphicType.fuse:
        drawMainLine();
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 14, height: 8), paint);
        break;
      case SingleLineGraphicType.contactor:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2, cy), 8, paint);
        break;
      case SingleLineGraphicType.thermal:
        drawMainLine();
        final path = Path()
          ..moveTo(w / 2 - 8, cy + 5)
          ..quadraticBezierTo(w / 2 - 2, cy - 6, w / 2 + 4, cy + 4)
          ..quadraticBezierTo(w / 2 + 6, cy + 7, w / 2 + 8, cy + 2);
        canvas.drawPath(path, paint);
        break;
      case SingleLineGraphicType.motor:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2, cy), 11, paint);
        if (symbol.code == 'PMP' || symbol.code == 'PMP-FIRE') {
          final tri = Path()
            ..moveTo(w / 2 + 3, cy)
            ..lineTo(w / 2 + 10, cy - 4)
            ..lineTo(w / 2 + 10, cy + 4)
            ..close();
          canvas.drawPath(tri, paint);
        }
        if (symbol.code == 'FAN') {
          canvas.drawLine(Offset(w / 2 - 6, cy), Offset(w / 2 + 6, cy), paint);
          canvas.drawLine(Offset(w / 2, cy - 6), Offset(w / 2, cy + 6), paint);
        }
        break;
      case SingleLineGraphicType.source:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2, cy), 10, paint);
        canvas.drawLine(Offset(w / 2 - 4, cy), Offset(w / 2 + 4, cy), paint);
        if (symbol.code == 'PV') {
          canvas.drawCircle(Offset(w / 2, cy), 3, paint);
          canvas.drawLine(Offset(w / 2, cy - 8), Offset(w / 2, cy - 12), paint);
          canvas.drawLine(Offset(w / 2 + 8, cy), Offset(w / 2 + 12, cy), paint);
          canvas.drawLine(Offset(w / 2, cy + 8), Offset(w / 2, cy + 12), paint);
          canvas.drawLine(Offset(w / 2 - 8, cy), Offset(w / 2 - 12, cy), paint);
        }
        if (symbol.code == 'BAT' || symbol.code == 'ESS') {
          canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 14, height: 8), paint);
          canvas.drawLine(Offset(w / 2 + 7, cy - 2), Offset(w / 2 + 9, cy - 2), paint);
          canvas.drawLine(Offset(w / 2 - 3, cy), Offset(w / 2 + 3, cy), paint);
          canvas.drawLine(Offset(w / 2, cy - 3), Offset(w / 2, cy + 3), paint);
        }
        if (symbol.code == 'UPS') {
          final wave = Path()
            ..moveTo(w / 2 - 7, cy + 8)
            ..quadraticBezierTo(w / 2 - 4, cy + 4, w / 2, cy + 8)
            ..quadraticBezierTo(w / 2 + 4, cy + 12, w / 2 + 7, cy + 8);
          canvas.drawPath(wave, paint);
        }
        if (symbol.code == 'INV' || symbol.code == 'VFD') {
          canvas.drawLine(Offset(w / 2 - 6, cy + 8), Offset(w / 2 + 6, cy + 8), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy + 8), Offset(w / 2 + 2, cy + 4), paint);
          canvas.drawLine(Offset(w / 2 + 6, cy + 8), Offset(w / 2 + 2, cy + 12), paint);
        }
        break;
      case SingleLineGraphicType.transformer:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2 - 6, cy), 6, paint);
        canvas.drawCircle(Offset(w / 2 + 6, cy), 6, paint);
        break;
      case SingleLineGraphicType.board:
        canvas.drawRect(Rect.fromLTWH(8, 10, w - 16, h - 20), paint);
        break;
      case SingleLineGraphicType.terminal:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2 - 7, cy), 2, paint);
        canvas.drawCircle(Offset(w / 2 + 7, cy), 2, paint);
        break;
      case SingleLineGraphicType.phase:
        drawMainLine();
        canvas.drawLine(Offset(w / 2 - 10, cy - 9), Offset(w / 2 - 10, cy + 9), paint);
        canvas.drawLine(Offset(w / 2, cy - 9), Offset(w / 2, cy + 9), paint);
        canvas.drawLine(Offset(w / 2 + 10, cy - 9), Offset(w / 2 + 10, cy + 9), paint);
        break;
      case SingleLineGraphicType.neutral:
        drawMainLine();
        canvas.drawLine(Offset(w / 2, cy - 9), Offset(w / 2, cy + 9), paint);
        break;
      case SingleLineGraphicType.pe:
      case SingleLineGraphicType.grounding:
        canvas.drawLine(Offset(w / 2, 8), Offset(w / 2, cy + 2), paint);
        canvas.drawLine(Offset(w / 2 - 10, cy + 2), Offset(w / 2 + 10, cy + 2), paint);
        canvas.drawLine(Offset(w / 2 - 7, cy + 7), Offset(w / 2 + 7, cy + 7), paint);
        canvas.drawLine(Offset(w / 2 - 4, cy + 11), Offset(w / 2 + 4, cy + 11), paint);
        if (symbol.code.startsWith('SPD')) {
          canvas.drawLine(Offset(w / 2 + 10, cy - 8), Offset(w / 2 + 4, cy - 1), paint);
          canvas.drawLine(Offset(w / 2 + 4, cy - 1), Offset(w / 2 + 9, cy - 1), paint);
          canvas.drawLine(Offset(w / 2 + 9, cy - 1), Offset(w / 2 + 3, cy + 7), paint);
        }
        break;
      case SingleLineGraphicType.pen:
        drawMainLine();
        canvas.drawLine(Offset(w / 2, cy), Offset(w / 2, h - 12), paint);
        canvas.drawLine(Offset(w / 2 - 7, h - 12), Offset(w / 2 + 7, h - 12), paint);
        canvas.drawLine(Offset(w / 2 - 4, h - 8), Offset(w / 2 + 4, h - 8), paint);
        break;
      case SingleLineGraphicType.meter:
        drawMainLine();
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 18, height: 14), paint);
        canvas.drawLine(Offset(w / 2 - 5, cy + 3), Offset(w / 2 + 5, cy + 3), paint);
        if (symbol.code == 'CT') {
          canvas.drawCircle(Offset(w / 2, cy - 2), 4, paint);
        }
        if (symbol.code == 'VT') {
          canvas.drawLine(Offset(w / 2 - 4, cy - 5), Offset(w / 2 + 4, cy + 3), paint);
          canvas.drawLine(Offset(w / 2 + 4, cy - 5), Offset(w / 2 - 4, cy + 3), paint);
        }
        break;
      case SingleLineGraphicType.cable:
        final path = Path();
        path.moveTo(4, cy + 4);
        path.quadraticBezierTo(w / 4, cy - 6, w / 2, cy + 4);
        path.quadraticBezierTo(3 * w / 4, cy + 12, w - 4, cy + 4);
        canvas.drawPath(path, paint);
        break;
      case SingleLineGraphicType.busbar:
        canvas.drawLine(Offset(4, cy), Offset(w - 4, cy), paint..strokeWidth = strokeWidth + 1.5);
        break;
      case SingleLineGraphicType.lineReserved:
        const dash = 6.0;
        const gap = 4.0;
        double x = 4;
        while (x < w - 4) {
          canvas.drawLine(Offset(x, cy), Offset((x + dash).clamp(0, w - 4), cy), paint);
          x += dash + gap;
        }
        break;
      case SingleLineGraphicType.noContact:
        canvas.drawLine(Offset(6, cy), Offset(w / 2 - 6, cy), paint);
        canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 6, cy), paint);
        canvas.drawLine(Offset(w / 2 - 4, cy + 6), Offset(w / 2 + 5, cy - 6), paint);
        break;
      case SingleLineGraphicType.ncContact:
        canvas.drawLine(Offset(6, cy), Offset(w / 2 - 6, cy), paint);
        canvas.drawLine(Offset(w / 2 + 6, cy), Offset(w - 6, cy), paint);
        canvas.drawLine(Offset(w / 2 - 4, cy - 6), Offset(w / 2 + 5, cy + 6), paint);
        break;
      case SingleLineGraphicType.pushButton:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2, cy - 8), 4, paint);
        canvas.drawLine(Offset(w / 2, cy - 4), Offset(w / 2, cy + 5), paint);
        break;
      case SingleLineGraphicType.lamp:
        drawMainLine();
        canvas.drawCircle(Offset(w / 2, cy), 9, paint);
        canvas.drawLine(Offset(w / 2 - 5, cy - 5), Offset(w / 2 + 5, cy + 5), paint);
        canvas.drawLine(Offset(w / 2 + 5, cy - 5), Offset(w / 2 - 5, cy + 5), paint);
        break;
      case SingleLineGraphicType.automation:
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 24, height: 16), paint);
        canvas.drawLine(Offset(w / 2 - 12, cy), Offset(4, cy), paint);
        canvas.drawLine(Offset(w / 2 + 12, cy), Offset(w - 4, cy), paint);
        if (symbol.code == 'ATS') {
          canvas.drawLine(Offset(w / 2 - 5, cy - 4), Offset(w / 2 + 5, cy + 4), paint);
        }
        if (symbol.code == 'PWP' || symbol.code == 'EPO') {
          canvas.drawCircle(Offset(w / 2, cy), 5, paint);
        }
        break;
      case SingleLineGraphicType.generic:
        drawMainLine();
        canvas.drawRect(Rect.fromCenter(center: Offset(w / 2, cy), width: 12, height: 12), paint);
        break;
    }

    drawCodeTag(symbol.code);
  }

  @override
  bool shouldRepaint(covariant _SingleLineSymbolPainter oldDelegate) {
    return oldDelegate.symbol.code != symbol.code ||
        oldDelegate.symbol.graphicType != symbol.graphicType ||
        oldDelegate.strictIecMode != strictIecMode ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
