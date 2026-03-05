/// Kalkulator harmonogramu prac elektrycznych
/// 
/// Dynamicznie generuje harmonogram na podstawie:
/// - Liczby budynków, klatek, pięter, mieszkań
/// - Wybranych systemów elektrycznych
/// - Warunków klimatycznych Polski
/// - Złożoności projektu

import '../models/building_hierarchy.dart';
import '../models/project_models.dart';

class ScheduleCalculator {
  /// Oblicz całkolwity czas potrzebny na projekt w tygodniach
  static int calculateTotalWeeks(
    AdvancedProjectConfiguration config, {
    double climateMultiplier = 1.0,
  }) {
    // Base: 1 tydzień per 50 mieszkań + 0.5 tygodnia per system
    int baseWeeks = (config.totalUnits / 50 + config.selectedSystems.length * 0.5).ceil();
    
    // Dodaj za piętra podziemne (garaż)
    if (config.hasAnyGarage) {
      baseWeeks += config.totalBasementLevels;
    }
    
    // Dodaj za windy
    if (config.totalElevators > 0) {
      baseWeeks += (config.totalElevators * 0.5).ceil();
    }
    
    // Zastosuj mnożnik klimatyczny
    return (baseWeeks * climateMultiplier).ceil();
  }
  
  /// Generate etapy budowy z datami
  static List<ProjectPhase> generateProjectPhases(
    DateTime startDate,
    int totalWeeks,
  ) {
    final phases = <ProjectPhase>[];
    
    // Proporcje faz (% całego czasu)
    const phaseProportions = {
      BuildingStage.przygotowanie: 0.05,
      BuildingStage.fundamenty: 0.15,
      BuildingStage.konstrukcja: 0.20,
      BuildingStage.przegrody: 0.15,
      BuildingStage.tynki: 0.10,
      BuildingStage.posadzki: 0.08,
      BuildingStage.osprzet: 0.12, // Głównie prace elektryczne
      BuildingStage.malowanie: 0.05,
      BuildingStage.finalizacja: 0.05,
      BuildingStage.oddawanie: 0.05,
    };
    
    DateTime phaseStart = startDate;
    
    BuildingStage.values.forEach((stage) {
      final proportion = phaseProportions[stage] ?? 0.0;
      final phaseDays = (totalWeeks * 7 * proportion).ceil();
      final phaseEnd = phaseStart.add(Duration(days: phaseDays));
      
      phases.add(
        ProjectPhase(
          stage: stage,
          startDate: phaseStart,
          endDate: phaseEnd,
          description: _getPhaseDescription(stage),
          criticalTasks: _getCriticalTasks(stage),
        ),
      );
      
      phaseStart = phaseEnd;
    });
    
    return phases;
  }
  
  /// Oceń złożoność projektu
  static String assessComplexity(AdvancedProjectConfiguration config) {
    int complexityScore = 0;
    
    // Za każdy system +10 punktów
    complexityScore += config.selectedSystems.length * 10;
    
    // Za dużą liczbę mieszkań +20 / 100 mieszkań
    complexityScore += (config.totalUnits ~/ 5);
    
    // Za windy +15
    if (config.totalElevators > 0) {
      complexityScore += 15 * config.totalElevators;
    }
    
    // Za garaż +20
    if (config.hasAnyGarage) {
      complexityScore += 20 * config.totalBasementLevels;
    }
    
    // Za wiele klatek +10 per klatka ponad 3
    int extraStairCases = config.totalStairCases > 3 ? config.totalStairCases - 3 : 0;
    complexityScore += extraStairCases * 10;
    
    if (complexityScore < 50) return 'PROSTA';
    if (complexityScore < 100) return 'ŚREDNIA';
    if (complexityScore < 200) return 'ZŁOŻONA';
    return 'BARDZO ZŁOŻONA';
  }
  
  /// Wygeneruj szczegółowy harmonogram z wyliczeniami
  static String generateDetailedScheduleReport(
    AdvancedProjectConfiguration config,
    int totalWeeks, {
    double climateMultiplier = 1.0,
  }) {
    return '''
╔══════════════════════════════════════════════════════════════╗
║            HARMONOGRAM PROJEKTU ELEKTRYCZNEGO               ║
╚══════════════════════════════════════════════════════════════╝

PROJEKT: ${config.projectName}
Adres: ${config.address}
Okres: ${_formatDate(config.projectStartDate)} - ${_formatDate(config.projectEndDate)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PARAMETRY PROJEKTU:
  • Budynków: ${config.buildings.length}
  • Klatek schodowych: ${config.totalStairCases}
  • Pięter: ${config.totalFloors} (podziemne: ${config.totalBasementLevels})
  • Mieszkań/lokali: ${config.totalUnits}
  • Wind: ${config.totalElevators}
  • Systemów elektrycznych: ${config.selectedSystems.length}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WYLICZENIE CZASU:
  Base (1 tyd./50 mieszkań): ${(config.totalUnits / 50).toStringAsFixed(1)} tygodni
  Systemy (0.5 tyd./system): ${(config.selectedSystems.length * 0.5).toStringAsFixed(1)} tygodni
  ${config.hasAnyGarage ? 'Garaż: ${config.totalBasementLevels} tygodni' : ''}
  ${config.totalElevators > 0 ? 'Windy: ${(config.totalElevators * 0.5).toStringAsFixed(1)} tygodni' : ''}
  Mnożnik klimatyczny: ${climateMultiplier.toStringAsFixed(2)}x
  
  ► RAZEM: $totalWeeks tygodni (${totalWeeks * 7} dni)

ZŁOŻONOŚĆ: ${assessComplexity(config)}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
  }
  
  static String _getPhaseDescription(BuildingStage stage) {
    switch (stage) {
      case BuildingStage.przygotowanie:
        return 'Projekty, harmonogramy, zamówienia materiałów';
      case BuildingStage.fundamenty:
        return 'Fundamenty, dreny, uziemienia fundamentowe';
      case BuildingStage.konstrukcja:
        return 'Szkielety, stropy, słupy';
      case BuildingStage.przegrody:
        return 'Ścianki działowe, przechody, kanały instalacyjne';
      case BuildingStage.tynki:
        return 'Tynki wewnętrzne i zewnętrzne';
      case BuildingStage.posadzki:
        return 'Posadzki, wylewki, podkłady';
      case BuildingStage.osprzet:
        return 'Osprzęt elektryczny, gniazda, włączniki, oprawy';
      case BuildingStage.malowanie:
        return 'Malowanie, lakierowanie (po pierwszych instalacjach)';
      case BuildingStage.finalizacja:
        return 'Drzwi finalne, meblościany, ostatnie poprawki';
      case BuildingStage.ozeInstalacje:
        return 'Instalacje fotowoltaiczne (PV), magazyny energii (BESS)';
      case BuildingStage.evInfrastruktura:
        return 'Infrastruktura ładowania EV, punkty ładowania, DLM';
      case BuildingStage.oddawanie:
        return 'Pomiary, dokumentacja, certyfikaty, odbiór;';
    }
  }
  
  static List<String> _getCriticalTasks(BuildingStage stage) {
    switch (stage) {
      case BuildingStage.przygotowanie:
        return [
          'Projekt elektryczny',
          'Harmonogram prac',
          'Zamówienie materiałów głównych',
        ];
      case BuildingStage.fundamenty:
        return [
          'Uziemienie fundamentowe',
          'Dreny dookoła budynku',
        ];
      case BuildingStage.przegrody:
        return [
          'Kanały instalacyjne',
          'Przechody dla przewodów',
        ];
      case BuildingStage.osprzet:
        return [
          'Rozdzielnice elektryczne',
          'Gniazda elektryczne',
          'Oprawy oświetleniowe',
        ];
      case BuildingStage.oddawanie:
        return [
          'Pomiary rezystancji izolacji',
          'Pomiary uziemienia',
          'Certyfikat SEP',
          'Podpisanie OC i gwarancji',
        ];
      default:
        return [];
    }
  }
  
  static String _formatDate(DateTime date) {
    const months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
