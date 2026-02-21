import 'package:flutter/material.dart';
import 'package:gridly/theme/grid_theme.dart';

class EkspertKabliScreen extends StatefulWidget {
  const EkspertKabliScreen({super.key});

  @override
  State<EkspertKabliScreen> createState() => _EkspertKabliScreenState();
}

class _EkspertKabliScreenState extends State<EkspertKabliScreen> {
  final Map<String, bool> _answers = {
    'uv': false,
    'evacuationRoute': false,
    'fireSystems': false,
    'aggressiveChemicals': false,
    'emcSensitive': false,
  };

  _CableMaterial _selectedMaterial = _CableMaterial.pvc;
  _ShieldingType _selectedShielding = _ShieldingType.none;
  bool _hasPhECertificate = false;
  bool _humanTranslatorEnabled = true;
  bool _reportGenerated = false;

  @override
  Widget build(BuildContext context) {
    final report = _buildReport();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ekspert kabli'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTranslatorToggle(),
            const SizedBox(height: 20),
            _buildRiskQuestionnaire(context),
            const SizedBox(height: 20),
            _buildCableSelection(context),
            const SizedBox(height: 20),
            _buildActions(context),
            const SizedBox(height: 20),
            if (_reportGenerated) ...[
              _buildComplianceReport(context, report),
              const SizedBox(height: 20),
            ],
            _buildKnowledgeAcademy(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interaktywny weryfikator doboru przewodów',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Analiza ryzyka i zgodności oparta o PN-HD 60364 oraz PN-EN 50575 (CPR).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslatorToggle() {
    return SwitchListTile(
      value: _humanTranslatorEnabled,
      onChanged: (value) {
        setState(() {
          _humanTranslatorEnabled = value;
        });
      },
      title: const Text('Tryb edukacyjny: „Tłumacz na ludzki”'),
      subtitle: const Text('Wyjaśnia techniczne terminy prostym językiem.'),
      activeThumbColor: GridTheme.electricYellow,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRiskQuestionnaire(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1) Weryfikator Analizy Ryzyka (Tak/Nie)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            _buildYesNoQuestion(
              id: 'uv',
              title: 'Czy kabel będzie narażony na UV (na zewnątrz)?',
            ),
            _buildYesNoQuestion(
              id: 'evacuationRoute',
              title:
                  'Czy trasa przebiega wewnątrz strefy pożarowej (droga ewakuacyjna)?',
            ),
            _buildYesNoQuestion(
              id: 'fireSystems',
              title:
                  'Czy instalacja zasila systemy bezpieczeństwa (PPOŻ/pompy strażackie)?',
            ),
            _buildYesNoQuestion(
              id: 'aggressiveChemicals',
              title:
                  'Czy w otoczeniu występują substancje agresywne (oleje, kwasy)?',
            ),
            _buildYesNoQuestion(
              id: 'emcSensitive',
              title:
                  'Czy środowisko wymaga ochrony przed zakłóceniami (EMC/falowniki)?',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoQuestion({
    required String id,
    required String title,
  }) {
    final value = _answers[id] ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          const SizedBox(width: 8),
          ToggleButtons(
            isSelected: [!value, value],
            onPressed: (index) {
              setState(() {
                _answers[id] = index == 1;
              });
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Nie'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Tak'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCableSelection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dobór kabla i osłon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<_CableMaterial>(
              initialValue: _selectedMaterial,
              decoration: const InputDecoration(
                labelText: 'Materiał izolacji',
                border: OutlineInputBorder(),
              ),
              items: _CableMaterial.values
                  .map(
                    (material) => DropdownMenuItem(
                      value: material,
                      child: Text(material.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedMaterial = value;
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<_ShieldingType>(
              initialValue: _selectedShielding,
              decoration: const InputDecoration(
                labelText: 'Ekran/pancerz',
                border: OutlineInputBorder(),
              ),
              items: _ShieldingType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedShielding = value;
                });
              },
            ),
            const SizedBox(height: 10),
            CheckboxListTile(
              value: _hasPhECertificate,
              onChanged: (value) {
                setState(() {
                  _hasPhECertificate = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Kabel ma certyfikat PH/E (np. PH90/E90)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _reportGenerated = true;
          });
        },
        icon: const Icon(Icons.fact_check),
        label: const Text('Generuj Raport Zgodności'),
        style: ElevatedButton.styleFrom(
          backgroundColor: GridTheme.electricYellow,
          foregroundColor: GridTheme.deepNavy,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildComplianceReport(BuildContext context, _ComplianceReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Raport Zgodności',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: report.severityColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Text('Podstawa: PN-HD 60364 + PN-EN 50575 (CPR).'),
            const SizedBox(height: 10),
            Text(
              'Wnioski i zalecenia:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            ...report.recommendations
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $item'),
                    )),
            if (report.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Safety Filter:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              ...report.warnings.map(
                (warning) => Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: warning.isCritical
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: warning.isCritical ? Colors.red : Colors.orange,
                    ),
                  ),
                  child: Text(warning.message),
                ),
              ),
            ],
            const Divider(height: 24),
            Text(
              'GRIDLY Expert pełni rolę asystenta decyzyjnego. Wynik nie stanowi projektu budowlanego. Za ostateczny dobór odpowiada osoba z uprawnieniami projektowymi/wykonawczymi zgodnie z Prawem Budowlanym.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeAcademy(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2) Akademia CPR i Materiałoznawstwo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            _buildKnowledgeTile(
              title: 'PVC (Y)',
              technical:
                  'Typowo klasa Eca. Tani i popularny, ale z wysokim ryzykiem dymienia i gazów korozyjnych podczas pożaru.',
              human:
                  'Najtańszy standard. W pożarze robi dużo dymu i utrudnia ewakuację.',
            ),
            _buildKnowledgeTile(
              title: 'LSOH / LSZH (H)',
              technical:
                  'Typowe klasy B2ca/Cca. Niskodymny i bezhalogenowy, zalecany tam, gdzie liczy się bezpieczeństwo ludzi.',
              human:
                  'Mniej dymu, mniej trucizn. Lepszy wybór do budynków z ludźmi.',
            ),
            _buildKnowledgeTile(
              title: 'XLPE (2X)',
              technical:
                  'Izolacja o wyższej odporności termicznej. Temperatura robocza żyły zwykle do 90°C.',
              human:
                  'Lepiej znosi grzanie kabla przy dużych obciążeniach.',
            ),
            _buildKnowledgeTile(
              title: 'LiYCY vs SWA/STA',
              technical:
                  'LiYCY to ekran miedziany (EMC). SWA/STA to pancerz stalowy chroniący mechanicznie (nacisk, gryzonie).',
              human:
                  'LiYCY to parasol przeciw zakłóceniom. SWA/STA to zbroja dla kabla przeciw łopacie i zębom szczura.',
            ),
            _buildKnowledgeTile(
              title: 'CPR: klasy reakcji na ogień',
              technical:
                'Klasy od Aca do Fca określają zachowanie kabla w pożarze. W praktyce instalacyjnej często spotykane: B2ca, Cca, Dca, Eca.',
              human:
                'Im wyższa klasa (np. Cca/B2ca), tym kabel zwykle bezpieczniejszy pożarowo niż Eca.',
            ),
            _buildKnowledgeTile(
              title: 'Parametr s (dym)',
              technical:
                's1 oznacza niską emisję dymu, s2 średnią, s3 brak rygoru. Dym ogranicza widoczność i utrudnia ewakuację.',
              human:
                's1 = mniej dymu, łatwiej wyjść z budynku podczas pożaru.',
            ),
            _buildKnowledgeTile(
              title: 'Parametr d (krople)',
              technical:
                'd0 brak płonących kropli/cząstek, d1/d2 dopuszczają ich występowanie zależnie od klasyfikacji badawczej.',
              human:
                'd0 oznacza, że kabel nie „kapie ogniem”.',
            ),
            _buildKnowledgeTile(
              title: 'Parametr a (kwasowość gazów)',
              technical:
                'a1/a2/a3 opisują korozyjność i kwasowość gazów po spalaniu. Niższa korozyjność ogranicza szkody wtórne w instalacjach.',
              human:
                'Lepsza klasa „a” to mniej żrących oparów niszczących elektronikę i instalacje.',
            ),
            _buildKnowledgeTile(
              title: 'PH/E vs CPR',
              technical:
                'CPR dotyczy reakcji kabla na ogień, a PH/E dotyczy podtrzymania funkcji podczas pożaru. To dwa różne wymagania i często trzeba spełnić oba.',
              human:
                'CPR mówi jak kabel się pali, a PH/E czy działa dalej w ogniu.',
            ),
            _buildKnowledgeTile(
              title: 'Promień gięcia i montaż',
              technical:
                'Przekroczenie dopuszczalnego promienia gięcia może uszkodzić izolację/powłokę i pogorszyć trwałość kabla.',
              human:
                'Nie zaginaj kabla zbyt ostro, bo szybciej się zniszczy.',
            ),
            const SizedBox(height: 12),
            Text(
              '3) Słownik CPR',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildKnowledgeTile(
              title: 'Klasa d0',
              technical: 'Brak płonących kropli/cząstek podczas pożaru.',
              human:
                  'Zero płonących kropel. Nic nie kapie na głowę podczas ucieczki.',
            ),
            _buildKnowledgeTile(
              title: 'Cca',
              technical:
                'Klasa reakcji na ogień stosowana powszechnie w obiektach użyteczności i strefach o podwyższonych wymaganiach bezpieczeństwa.',
              human:
                'Cca to bezpieczniejsza półka kabli do budynków, gdzie są ludzie.',
            ),
            _buildKnowledgeTile(
              title: 'Eca',
              technical:
                'Podstawowa klasa CPR dla wielu prostych zastosowań; zwykle niższy poziom wymagań pożarowych niż Cca/B2ca.',
              human:
                'Eca to bardziej „bazowy” poziom odporności pożarowej kabla.',
            ),
            _buildKnowledgeTile(
              title: 's1',
              technical:
                'Niska emisja dymu potwierdzona badaniami CPR.',
              human:
                'Mniej dymu = lepsza widoczność podczas ewakuacji.',
            ),
            _buildKnowledgeTile(
              title: 'a1',
              technical:
                'Niska kwasowość i korozyjność gazów po spalaniu kabla.',
              human:
                'Mniej żrących oparów i mniejsze ryzyko uszkodzeń urządzeń.',
            ),
            _buildKnowledgeTile(
              title: 'DoP',
              technical:
                'Declaration of Performance (Deklaracja Właściwości Użytkowych) producenta, zawiera deklarowaną klasę CPR i parametry wyrobu.',
              human:
                'DoP to oficjalna karta producenta potwierdzająca parametry kabla.',
            ),
            _buildKnowledgeTile(
              title: 'AVCP',
              technical:
                'Assessment and Verification of Constancy of Performance — system oceny i weryfikacji stałości właściwości użytkowych.',
              human:
                'AVCP określa, jak sprawdza się, czy kabel stale spełnia deklarowane parametry.',
            ),
            _buildKnowledgeTile(
              title: 'Klasyfikacja ogniowa trasy',
              technical:
                'Dobór klasy CPR powinien wynikać z funkcji strefy, scenariusza pożaru i wymagań inwestora/projektu.',
              human:
                'Kabel dobiera się do miejsca montażu, a nie tylko do ceny.',
            ),
            _buildKnowledgeTile(
              title: 'Pancerz stalowy',
              technical:
                  'Dodatkowa osłona mechaniczna kabla w trudnych warunkach.',
              human:
                  'Zbroja dla kabla. Chroni przed łopatą i zębami szczura.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKnowledgeTile({
    required String title,
    required String technical,
    required String human,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(technical),
            if (_humanTranslatorEnabled) ...[
              const SizedBox(height: 6),
              Text(
                'Tłumacz na ludzki: $human',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _ComplianceReport _buildReport() {
    final warnings = <_ReportWarning>[];
    final recommendations = <String>[];

    if (_answers['uv'] == true) {
      recommendations.add(
        'Zastosuj kabel z powłoką odporną na UV (instalacje zewnętrzne).',
      );
    }

    if (_answers['evacuationRoute'] == true) {
      recommendations.add(
        'W strefach ewakuacji preferuj co najmniej Cca-s1,d0,a1 (niskodymne i bezhalogenowe).',
      );
      if (_selectedMaterial == _CableMaterial.pvc) {
        warnings.add(
          const _ReportWarning(
            message:
                'UWAGA: Ryzyko wysokiego zadymienia. Rozważ klasę min. Cca-s1,d0,a1 zgodnie z wytycznymi PPOŻ.',
            isCritical: false,
          ),
        );
      }
    }

    if (_answers['fireSystems'] == true) {
      recommendations.add(
        'Dla systemów PPOŻ wymagane jest podtrzymanie funkcji (weryfikuj PH/E i dokumentację producenta).',
      );
      if (!_hasPhECertificate) {
        warnings.add(
          const _ReportWarning(
            message:
                'KRYTYCZNE: Systemy PPOŻ wymagają podtrzymania funkcji. Sprawdź certyfikat PH90/E90.',
            isCritical: true,
          ),
        );
      }
    }

    if (_answers['aggressiveChemicals'] == true) {
      recommendations.add(
        'Zweryfikuj odporność chemiczną powłoki na oleje/kwasy dla danego środowiska.',
      );
    }

    if (_answers['emcSensitive'] == true) {
      if (_selectedShielding == _ShieldingType.none) {
        recommendations.add(
          'Rozważ kabel ekranowany (np. LiYCY) lub separację tras dla ograniczenia zakłóceń EMC.',
        );
      } else {
        recommendations.add(
          'Zastosowano osłonę wspierającą EMC/mechanikę — potwierdź poprawne uziemienie i zakończenie ekranu.',
        );
      }
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Brak podwyższonych czynników ryzyka w ankiecie. Zachowaj standardową weryfikację obciążalności i warunków montażu.',
      );
    }

    final hasCritical = warnings.any((w) => w.isCritical);
    final hasWarning = warnings.isNotEmpty;

    final status = hasCritical
        ? 'NIEZGODNOŚĆ KRYTYCZNA'
        : hasWarning
            ? 'ZGODNOŚĆ WARUNKOWA'
            : 'ZGODNOŚĆ WSTĘPNA';

    final severityColor = hasCritical
        ? Colors.red
        : hasWarning
            ? Colors.orange
            : Colors.green;

    return _ComplianceReport(
      status: status,
      severityColor: severityColor,
      warnings: warnings,
      recommendations: recommendations,
    );
  }
}

enum _CableMaterial {
  pvc('PVC (Y) - Eca'),
  lszh('LSOH/LSZH (H) - B2ca/Cca'),
  xlpe('XLPE (2X) - do 90°C');

  const _CableMaterial(this.label);
  final String label;
}

enum _ShieldingType {
  none('Brak'),
  licyc('LiYCY - ekran miedziany'),
  swaSta('SWA/STA - pancerz stalowy'),
  combined('LiYCY + SWA/STA');

  const _ShieldingType(this.label);
  final String label;
}

class _ComplianceReport {
  const _ComplianceReport({
    required this.status,
    required this.severityColor,
    required this.warnings,
    required this.recommendations,
  });

  final String status;
  final Color severityColor;
  final List<_ReportWarning> warnings;
  final List<String> recommendations;
}

class _ReportWarning {
  const _ReportWarning({
    required this.message,
    required this.isCritical,
  });

  final String message;
  final bool isCritical;
}
