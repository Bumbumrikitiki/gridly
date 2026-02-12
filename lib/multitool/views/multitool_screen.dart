import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gridly/multitool/logic/multitool_provider.dart';
import 'package:gridly/multitool/models/multitool_item.dart';
import 'package:gridly/multitool/cable_selector/views/cable_selector_screen.dart';
import 'package:gridly/multitool/calculators/views/engineering_calculators_screen.dart';
import 'package:gridly/multitool/label_generator/views/label_generator_screen.dart';
import 'package:gridly/multitool/field_guide/views/field_guide_screen.dart';
import 'package:gridly/multitool/rcd_selector/views/rcd_selector_screen.dart';
import 'package:gridly/multitool/encyclopedia/views/encyclopedia_screen.dart';

class MultitoolScreen extends StatelessWidget {
  const MultitoolScreen({super.key});

  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Multitool')),
      floatingActionButton: Consumer<MultitoolProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton(
            backgroundColor: _amber,
            onPressed: () async {
              try {
                await provider.toggleTorch();
              } catch (error) {
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nie mozna wlaczyc latarki.')),
                );
              }
            },
            child: Icon(
              provider.torchEnabled
                  ? Icons.flashlight_on
                  : Icons.flashlight_off,
              color: _deepNavy,
            ),
          );
        },
      ),
      body: Container(
        color: _deepNavy,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<MultitoolProvider>(
              builder: (context, provider, _) {
                final isMobile = MediaQuery.of(context).size.width < 600;
                final crossAxisCount = isMobile ? 2 : 4;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Multitool',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const Spacer(),
                        Text(
                          '${provider.items.length} funkcji',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.95,
                        ),
                        itemCount: provider.items.length,
                        itemBuilder: (context, index) {
                          final item = provider.items[index];
                          return _ToolCard(
                            item: item,
                            onTap: () {
                              switch (item.id) {
                                case 'srednice':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CableSelectorScreen(),
                                    ),
                                  );
                                  break;
                                case 'kalkulatory':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const EngineeringCalculatorsScreen(),
                                    ),
                                  );
                                  break;
                                case 'opisowki':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const LabelGeneratorScreen(),
                                    ),
                                  );
                                  break;
                                case 'spadki':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FieldGuideScreen(),
                                    ),
                                  );
                                  break;
                                case 'rcd_selector':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RcdSelectorScreen(),
                                    ),
                                  );
                                  break;
                                case 'encyclopedia':
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const EncyclopediaScreen(),
                                    ),
                                  );
                                  break;
                                default:
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Funkcja w przygotowaniu'),
                                    ),
                                  );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.item, required this.onTap});

  final MultitoolItem item;
  final VoidCallback onTap;

  static const Color _deepNavy = Color(0xFF102A43);
  static const Color _amber = Color(0xFFF7B500);
  static const Color _cardNavy = Color(0xFF243B53);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardNavy,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _deepNavy, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _deepNavy,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: _amber, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 11,
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
}
