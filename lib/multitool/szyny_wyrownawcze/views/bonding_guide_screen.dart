import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bonding_elements_models.dart';
import '../logic/bonding_calculator.dart';

class BondingGuideScreen extends StatefulWidget {
  const BondingGuideScreen({Key? key}) : super(key: key);

  @override
  State<BondingGuideScreen> createState() => _BondingGuideScreenState();
}

class _BondingGuideScreenState extends State<BondingGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BondingCalculatorProvider(),
      child: Consumer<BondingCalculatorProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Szyny Wyrównawcze i Uziemienie'),
              centerTitle: true,
              elevation: 0,
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.calculate), text: 'Kalkulator'),
                  Tab(icon: Icon(Icons.table_chart), text: 'Elementy'),
                  Tab(icon: Icon(Icons.book), text: 'Normy'),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context, provider),
                _buildCalculatorTab(context, provider),
                _buildElementsTab(context, provider),
                _buildNormsTab(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// TAB 1 - Informacje i disclaimer
  Widget _buildInfoTab(BuildContext context, BondingCalculatorProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DISCLAIMER GŁÓWNY
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red.shade700, size: 28),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'OGRANICZENIE ODPOWIEDZIALNOŚCI',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  BondingCalculatorProvider.disclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade900,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Co to jest szyna wyrównawcza?
          _buildSection(
            'Co to jest Szyna Wyrównawcza (GSW)?',
            '''GSW to metalowy pręt/taśma łączący wszystkie uziemienia w budowie w jeden punkt (potencjał zerowy).

Funkcje:
• Wyrównanie potencjału między elementami
• Rozprowadzenie prądów błądzących
• Ochrona przed porażeniami elektrycznymi
• Bezpieczeństwo pracowników i maszyn

Materiały: Mosiądz (najczęściej), miedź, aluminium
Rozmiary: 10×10 mm do 16×20 mm (przekrój 100-320 mm²)
Norma: PN-IEC 60364-5-54, PN-EN 50164
''',
          ),

          const SizedBox(height: 16),

          // Elementy wymagające uziemienia
          _buildSection(
            'Elementy wymagające uziemienia',
            '''Na budowie muszą być uziemione:

✓ Rozdzielnice elektryczne (RB, RBTK)
✓ Metalowe rury wchodzące (woda, gaz, kanalizacja)
✓ Rusztowania metalowe
✓ Baraki (obudowa metalowa)
✓ Kontenery budowlane
✓ Maszyny budowlane (żurawie, podnośniki)
✓ Słupy oświetleniowe
✓ Maszty antenowe

Każde połączenie musi być:
• Stałe i niezawodne
• Sprawdzone działającym ądem
• Udokumentowane
''',
          ),

          const SizedBox(height: 16),

          // Metody połączenia
          _buildSection(
            'Sposoby połączenia',
            '''
⚡ ŚRUBOWE (M10, M12)
   • Najczęściej stosowane
   • Dokręcić: 25-30 Nm (dla M12)
   • Obowiązkowy docisk i kontakty

🔥 SPAWANIE
   • Dla rusztowań (obowiązkowe)
   • Każde połączenie: min. 200 A²s²
   • Certyfikat spawacza wymagany

🏗️ CERTYFIKOWANE ZŁĄCZE
   • Przy rurach gazowych (OBOWIĄZKOWE!)
   • Przy rurach wodnych
   • Wg PN-EN 50164

⚠️ LUŹNE KLEMISY
   • Tylko tymczasowo
   • Niska niezawodność - unikać
   • Sprawdzanie co 2 tygodnie
''',
          ),

          const SizedBox(height: 16),

          // Podział PEN
          _buildSection(
            'Podział PEN na PE i N',
            '''W Polsce standard to system TN-C-S:
• PEN wchodzi z sieci
• W głównej rozdzielniey następuje podział na PE i N
• Następnie biegną osobno

Wymogi:
• Podział TYLKO w głównej rozdzielniey
• Przekrój PE: ≥16 mm² Cu (dla I≤63A)
• Przekrój N: = przekrojowi fazowemu (min. 16 mm²)
• Połączenia do szyny PE/N: oddzielne, dokładne

Zabrania się:
✗ Ponownego połączenia PE i N po podziale
✗ Umieszczania odłącznika PEN przed głównym wyłącznikiem
✗ Rozdzielania PEN w poszczególnych gałęziach
''',
          ),
        ],
      ),
    );
  }

  /// TAB 2 - Kalkulator do doboru kabla
  Widget _buildCalculatorTab(
      BuildContext context, BondingCalculatorProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disclaimer mini
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              border: Border.all(color: Colors.amber.shade700),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Wartości orientacyjne - wymaga weryfikacji!',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Wybór elementu
          const Text('1. Wybierz element',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: provider.getDostepneElementy().length,
              itemBuilder: (context, index) {
                final element = provider.getDostepneElementy()[index];
                final isSelected = provider.selectedElement == element;
                return GestureDetector(
                  onTap: () => provider.ustawElement(element),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        provider.getOpisElementu(element),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.blue : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Wybór prądu
          const Text('2. Wybierz prąd nominalny',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: provider.getDostepnePrady().length,
              itemBuilder: (context, index) {
                final prad = provider.getDostepnePrady()[index];
                final isSelected = provider.selectedPrad == prad;
                return GestureDetector(
                  onTap: () => provider.ustawPrad(prad),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        provider.getOpisPradu(prad),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.green : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Przycisk Oblicz
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => provider.obliczRekomendacje(),
              icon: const Icon(Icons.calculate),
              label: const Text('Oblicz rekomendację'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // WYNIK
          if (provider.ostatniaRekomendacja != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✓ WYNIK',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
                  const SizedBox(height: 12),
                  _resultRow('Przekrój kabla:',
                      provider.ostatniaRekomendacja!.przekrojMM),
                  _resultRow('Sposób połączenia:',
                      provider.ostatniaRekomendacja!.rekomendowanySposob.toString().split('.').last),
                  _resultRow(
                      'Norma', provider.ostatniaRekomendacja!.norma),
                  const SizedBox(height: 8),
                  Text(
                    'Uzasadnienie:\n${provider.ostatniaRekomendacja!.dlaczego}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // OSTRZEŻENIA
          if (provider.ostrzezenie.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      const Text('OSTRZEŻENIA',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(provider.ostrzezenie,
                      style: const TextStyle(fontSize: 11, height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Przycisk Eksportuj
          if (provider.ostatniaRekomendacja != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final tekst = provider.eksportRekomendacji();
                  _showExportDialog(context, tekst);
                },
                icon: const Icon(Icons.file_download),
                label: const Text('Eksportuj rekomendację'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// TAB 3 - Tabela elementów i wymogi
  Widget _buildElementsTab(BuildContext context, BondingCalculatorProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Elementy wymagające uziemienia - wymogi szczegółowe',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...BazaRekomendacji.standardoweElementy
              .map((element) => _buildElementCard(context, element))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildElementCard(BuildContext context, ElementUziemienia element) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek
            Text(element.nazwa,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 4),
            Text(element.opis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
            const Divider(),
            // Szczegóły
            _elementDetailRow('Wymogany przekrój:', element.wymaganyPrzekrocj),
            _elementDetailRow(
                'Punkt podłączenia:', element.punktPodlaczenia),
            _elementDetailRow('Sposób podłączenia:',
                element.rekomendowanySposob.toString().split('.').last),
            if (element.wymagaSpawania)
              _elementDetailRow('⚠️ Wymaga:', 'SPAWANIA (200 A²s² min)'),
            if (element.wymagaPrintosowania)
              _elementDetailRow('⚠️ Wymaga:', 'Certyfikowanego złącza!'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Specjalne: ${element.specjalnePrzypisy}',
                style: const TextStyle(fontSize: 10, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _elementDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade800)),
          ),
        ],
      ),
    );
  }

  /// TAB 4 - Normy i referencje
  Widget _buildNormsTab(BuildContext context, BondingCalculatorProvider provider) {
    final tabelaPrzekrojow = provider.getTabelaPrzekrojow();
    final szynaWymagania = provider.getWymagaSzynyWyrownawczej();
    final penWymagania = provider.getWymagaPodzialuPEN();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabela przekrojów
          _buildNormSection(
            'Tabela przekrojów kabla (PN-IEC 60364-5-54)',
            tabelaPrzekrojow,
          ),
          const SizedBox(height: 24),

          // Główna szyna wyrówn
          _buildNormSection(
            'Wymogi dla Głównej Szyny Wyrównawczej',
            szynaWymagania,
          ),
          const SizedBox(height: 24),

          // Podział PEN
          _buildNormSection(
            'Wymogi dla podziału PEN (PN-IEC 60364-4-41)',
            penWymagania,
          ),
          const SizedBox(height: 24),

          // Normy i dokumenty
          _buildSection(
            'Normy stosowane w tym narzędziu',
            '''
📘 PN-IEC 60364-5-54:2017
   Normy elektroenergetyczne - Projekt instalacji
   Tabela 54.1: Wymogi dla przewodów ochronnych

📘 PN-IEC 60364-4-41:2020
   Normy elektroenergetyczne - Zabezpieczenie przed porażeniami
   Sys­temy TN-S, TN-C-S, TT

📘 PN-EN 50164:2012
   Przewody ochronne i szyny wyrównawcze
   Wymogi dla materiałów i połączeń

📘 PN-ISO 12811:2012
   Bezpieczeństwo na budowach - Rusztowania
   Warunki bezpiecznego stawiania i eksploatacji

📘 PN-EN 1004-1:2004
   Rusztowania mobilne - Wymagania bezpieczeństwa

Wszystkie wartości w tym narzędziu bazują na powyższych normach!
Szczegóły - zaradź u projektanta ds. bezpieczeństwa elektryk.
''',
          ),
        ],
      ),
    );
  }

  Widget _buildNormSection(String title, Map<String, String> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...data.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(entry.key + ':',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text(entry.value,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            height: 1.4)),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(content,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  height: 1.6)),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label + ' ',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eksportuj rekomendację'),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }
}
