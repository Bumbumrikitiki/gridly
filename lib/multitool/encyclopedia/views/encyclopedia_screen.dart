import 'package:flutter/material.dart';
import 'package:gridly/multitool/encyclopedia/models/encyclopedia_models.dart';
import 'package:gridly/multitool/encyclopedia/services/encyclopedia_database.dart';
import 'package:gridly/theme/grid_theme.dart';

class EncyclopediaScreen extends StatefulWidget {
  const EncyclopediaScreen({super.key});

  @override
  State<EncyclopediaScreen> createState() => _EncyclopediaScreenState();
}

class _EncyclopediaScreenState extends State<EncyclopediaScreen> {
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encyklopedia Symboli'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Category selector
          _buildCategoryTabs(),
          // Grid of symbols
          Expanded(
            child: _buildSymbolsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // All symbols
          _buildCategoryChip(
            null,
            'Wszystko',
            '📋',
          ),
          // Categories
          ...EncyclopediaDatabase.categories.map((cat) =>
              _buildCategoryChip(cat.name, cat.name, cat.icon)),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String? value, String label, String icon) {
    final isSelected = selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            selectedCategory = selected ? value : null;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: GridTheme.electricYellow,
        labelStyle: TextStyle(
          color: isSelected ? GridTheme.deepNavy : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSymbolsGrid() {
    final symbols = selectedCategory == null
        ? EncyclopediaDatabase.getAllSymbols()
        : EncyclopediaDatabase.getSymbolsByCategory(selectedCategory!);

    if (symbols.isEmpty) {
      return Center(
        child: Text(
          'Brak symboli w tej kategorii',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 3 : 5;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: symbols.length,
      itemBuilder: (context, index) {
        final symbol = symbols[index];
        return _buildSymbolCard(context, symbol);
      },
    );
  }

  Widget _buildSymbolCard(BuildContext context, ElectricalSymbol symbol) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showSymbolDetail(context, symbol);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                symbol.icon,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                symbol.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                symbol.description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 10,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSymbolDetail(BuildContext context, ElectricalSymbol symbol) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildDetailSheet(symbol),
    );
  }

  Widget _buildDetailSheet(ElectricalSymbol symbol) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Symbol and title
            Row(
              children: [
                Text(
                  symbol.icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        symbol.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GridTheme.electricYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          symbol.category ?? 'Inne',
                          style: TextStyle(
                            fontSize: 12,
                            color: GridTheme.electricYellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            Text(
              symbol.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 20),

            // Full description
            if (symbol.fullDescription != null) ...[
              Text(
                'Opis',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                symbol.fullDescription!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
            ],

            // Parameters
            if (symbol.parameters != null && symbol.parameters!.isNotEmpty) ...[
              Text(
                'Parametry techniczne',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...symbol.parameters!.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildParameterRow(
                      context,
                      entry.key,
                      entry.value,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParameterRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: GridTheme.electricYellow,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
