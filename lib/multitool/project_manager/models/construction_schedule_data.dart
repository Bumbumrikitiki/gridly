/// Dane harmonogramu budowy dla mieszkalnych i biurowych budynków
/// Źródło: Dokument "Uzupełniony i kompletny etap dla budowy budynku mieszkalnego wielorodzinnego i budynku biurowego"
///
/// System obsługuje:
/// - Budynki 4-12+ kondygnacyjne
/// - Garaże podziemne 0-2 poziomy
/// - Dostosowywanie harmonogramu na podstawie liczby pięter i garaży
/// - Specjalistyczne kroki dla pomezczczeń podziemnych
library;

import 'package:gridly/multitool/project_manager/models/project_models.dart';

/// Dane etapów budowy dla różnych konfiguracji
class ConstructionScheduleDatabase {
  // ═══════════════════════════════════════════════════════════════════════════
  // BAZOWE PROPORCJE DLA BUDYNKÓW MIESZKALNYCH WIELORODZINNYCH
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Bazowe proporcje czasu dla budynku mieszkalnego 5-8 kondygnacyjny + 1 garaż
  /// Całkowity czas: 18-24 miesiące
  static final Map<BuildingStage, ResidentialStageData> residentialStages = {
    BuildingStage.przygotowanie: ResidentialStageData(
      label: 'Etap przygotowawczy',
      weekRange: (2, 4),
      timePercentage: 0.125, // 10-15%
      description: 'Projekty, harmonogram, zamówienia, przygotowanie terenu',
      tasks: [
        'Uzyskanie ostatecznej decyzji o pozwoleniu na budowę',
        'Zgłoszenie rozpoczęcia robót do PINB',
        'Wyznaczenie kierownika budowy',
        'Przejęcie terenu budowy od inwestora',
        'Zawarcie umów na dostawy mediów tymczasowych',
        'Opracowanie projektu organizacji robót (POR)',
        'Plan BIOZ i plan zapewnienia jakości',
        'Harmonogram szczegółowy',
        'Geodezyjna inwentaryzacja stanu istniejącego',
        'Wytyczenie granic działki i obrysu budynku',
        'Badania geotechniczne',
        'Wycinka drzew i krzewów',
        'Usunięcie humusu',
        'Ogrodzenie terenu budowy',
        'Bramy wjazdowe i kontrola dostępu',
        'Drogi tymczasowe i place składowe',
        'Zaplecze socjalno-biurowe',
        'Przyłącze energetyczne tymczasowe',
      ],
    ),
    BuildingStage.fundamenty: ResidentialStageData(
      label: 'Roboty ziemne i fundamentowe',
      weekRange: (3, 5),
      timePercentage: 0.175, // 15-20%
      description: 'Wykopy, zabezpieczenie wykopu, płyta fundamentowa, ścianki podziemia, strop nad garażem',
      tasks: [
        'Roboty przygotowawcze wykopu',
        'Zabezpieczenie wykopu (ścianki szczelne/palisady)',
        'Wykop główny',
        'Projekt odwodnienia wykopu',
        'Monitoring przemieszczeń',
        'Płyta fundacyjna (typ)',
        'Ścianki żelbetowe obwodowe',
        'Słupy żelbetowe podziemia',
        'Stropy podziemia (poziomy -2, -1)',
        'Izolacje przeciwwodne (ciężkie)',
      ],
    ),
    BuildingStage.konstrukcja: ResidentialStageData(
      label: 'Konstrukcja nadziemna (stan surowy otwarty)',
      weekRange: (5, 8),
      timePercentage: 0.30, // 25-35%
      description: 'Słupy, stropy, cykl stropowy 3-4 tygodnie/kondygnacja',
      tasks: [
        'Przygotowanie terenu dla budowy słupów',
        'Zagazienie słupów żelbetowych',
        'Montaż słupów',
        'Montaż belek poprzecznych',
        'Zabudowa sufitów pośrednich',
        'Montaż stropów (cykl: 3-4 tygodnie/kondygnacja)',
        'Roboty przygotowawcze na stropach',
        'Wznoszenie ścian nośnych betonowych',
        'Montaż wind budowlanych',
        'Rozmontaż czasowych podpór',
      ],
    ),
    BuildingStage.przegrody: ResidentialStageData(
      label: 'Stan surowy zamknięty (fasada, stolarka, dach)',
      weekRange: (3, 5),
      timePercentage: 0.175, // 15-20% (wykonywane częściowo równolegle z konstrukcją)
      description: 'Fasada, stolarka okienne, dach, system zagęszczania',
      tasks: [
        'Wznoszenie ścian działowych (cegła, suche zabudowy)',
        'Montaż ram okiennych',
        'Montaż drzwi wejściowych',
        'Montaż rolet zewnętrznych',
        'Zabudowa gniazd przejść instalacji',
        'Przygotowanie do okablowania',
        'Montaż dachu',
        'Obróbka blacharskie równoległa',
        'Uszczelnieni połączeń',
      ],
    ),
    BuildingStage.tynki: ResidentialStageData(
      label: 'Tynki',
      weekRange: (3, 4),
      timePercentage: 0.175, // 15-20%
      description: 'Tynki wewnętrzne i zewnętrzne',
      tasks: [
        'Przygotowanie ścian do obtynkowania',
        'Montaż szyn niwelacyjnych',
        'Tynkowanie ścian wewnętrznych',
        'Tynkowanie ścian zewnętrznych',
        'Szpachowanie wylewek',
      ],
    ),
    BuildingStage.posadzki: ResidentialStageData(
      label: 'Posadzki i wylewki',
      weekRange: (2, 3),
      timePercentage: 0.10, // 10%
      description: 'Posadzki betonowe, wylewki samowyrównujące',
      tasks: [
        'Przygotowanie podłoża',
        'Montaż systemów grzejnych w posadzce',
        'Wylewki betonowe',
        'Wylewki samowyrównujące',
      ],
    ),
    BuildingStage.osprzet: ResidentialStageData(
      label: 'Osprzęt elektryczny i oprawy oświetleniowe',
      weekRange: (2, 3),
      timePercentage: 0.10, // 10%
      description: 'Montaż osprzętu elektrycznego, opraw, wyłączników, gniazd',
      tasks: [
        'Montaż przełączników i wyłączników',
        'Montaż gniazd zasilających',
        'Montaż opraw sufitowych',
        'Montaż kinkietów ściennych',
        'Podłączenie osprzętu do instalacji',
        'Testowanie połączeń',
      ],
    ),
    BuildingStage.malowanie: ResidentialStageData(
      label: 'Malowanie i lakierowanie',
      weekRange: (2, 3),
      timePercentage: 0.10, // 10%
      description: 'Malowanie ścian i sufitów, lakierowanie drzwi',
      tasks: [
        'Szpachlowanie i wyrównanie powierzchni',
        'Gruntowanie ścian',
        'Malowanie ścian',
        'Malowanie sufitów',
        'Lakierowanie obramowań drzwi',
        'Czyszczenie i remonty',
      ],
    ),
    BuildingStage.finalizacja: ResidentialStageData(
      label: 'Finalizacja (drzwi, meblościany)',
      weekRange: (2, 4),
      timePercentage: 0.10, // 10%
      description: 'Montaż drzwi finalnych, zabudowa meblościan',
      tasks: [
        'Montaż drzwi pokojowych',
        'Montaż drzwi wejściowych do jednostek',
        'Zabudowa meblościan',
        'Zabudowa systemów przechowywania',
        'Czyszczenie mieszkań',
      ],
    ),
    BuildingStage.oddawanie: ResidentialStageData(
      label: 'Rozruchy, odbiory i pozwolenie na użytkowanie',
      weekRange: (1, 2),
      timePercentage: 0.065, // 5-8%
      description: 'Pomiary, dokumentacja, odbiory branżowe, pozwolenie na użytkowanie',
      tasks: [
        'Pomiary instalacji elektrycznej (pomiary rezystancji)',
        'Pomiary uziemienia',
        'Pomiary instalacji wod-kan',
        'Odbiory branżowe',
        'Usunięcie wad zgłoszonych',
        'Wznowienie dokumentacji (Rysunki as-built)',
        'Przygotowanie wniosku o pozwolenie na użytkowanie',
        'Zgłoszenie do Powiatowego Inspektora Nadzoru Budowlanego',
        'Uzyskanie pozwolenia na użytkowanie',
        'Odbiór końcowy inwestora',
      ],
    ),
    BuildingStage.ozeInstalacje: ResidentialStageData(
      label: 'Instalacje OZE (Odnawialne Źródła Energii)',
      weekRange: (2, 4),
      timePercentage: 0.04, // 3-5%
      description: 'Montaż instalacji fotowoltaiki, magazynów energii (BESS), inwerterów i systemów zabezpieczających',
      tasks: [
        'Montaż konstrukcji wsporczej dla paneli PV',
        'Montaż modułów fotowoltaicznych',
        'Instalacja inwertera trójfazowego (jeśli dotyczy)',
        'Montaż magazynu energii (BESS) - baterie litowo-jonowe',
        'Instalacja systemu zabezpieczającego (DC/AC)',
        'Okablowanie sieci DC i AC',
        'Podłączenie do systemu elektroinstalacji budynku',
        'Pomiary parametrów instalacji fotowoltaicznej',
        'Test izolacji przewodów DC',
        'Uruchomienie systemu OZE',
        'Przygotowanie dokumentacji technicznej (wykresy schematów)',
        'Kalibracja i ustawienie parametrów falownika',
      ],
    ),
    BuildingStage.evInfrastruktura: ResidentialStageData(
      label: 'Infrastruktura elektromobilności (Ładowarki EV)',
      weekRange: (2, 3),
      timePercentage: 0.03, // 2-4%
      description: 'Instalacja stacji ładowania pojazdów elektrycznych, magistrali zasilającej, systemu DLM i przejęcia UDT',
      tasks: [
        'Prowadzenie magistrali zasilającej do stanowisk ładowania',
        'Montaż rozdzielnic zasilających dla stacji ładowania',
        'Montaż wallboxów lub słupków ładowania',
        'Instalacja przewodów ognioodpornych (jeśli wymagane)',
        'Instalacja systemu zarządzenia burtą (DLM)',
        'Konfiguracja balansu obciążenia w systemie DLM',
        'Podłączenie modułów komunikacyjne do centrali',
        'Testy funkcjonalne każdej stacji ładowania',
        'Badanie i pomiary przez UDT',
        'Uzyskanie decyzji UDT (dopuszczenie do eksploatacji)',
        'Szkolenie użytkowników obsługi stacji ładowania',
        'Przygotowanie dokumentacji eksploatacyjnej',
      ],
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // MODYFIKATORY DLA GARAŻY PODZIEMNYCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Modyfikatory czasu dla garaży podziemnych
  /// Każdy poziom garaży dodaje czas do etapów fundamentów i przygotowania
  static const Map<int, BasementModifier> basementModifiers = {
    1: BasementModifier(
      label: 'Garaż 1 poziom (-1)',
      additionalPrepWeeks: 1,
      additionalFoundationWeeks: 2,
      additionalTasks: [
        'Projekt zabezpieczenia wykopu (ścianki szczelne)',
        'Palisady lub grodzice ochronne',
        'Wymiana i zwiezienie gruntu',
        'Odwodnienie igłofiltrami (6-10 tygodni)',
        'Monitoring przemieszczeń',
      ],
      description: 'Garaż jednostopniowy: +1-2 miesiące do harmonogramu',
    ),
    2: BasementModifier(
      label: 'Garaż 2 poziomy (-1, -2)',
      additionalPrepWeeks: 2,
      additionalFoundationWeeks: 5,
      additionalTasks: [
        'Projekt zabezpieczenia wykopu (ścianki szczelne na pełną głębokość)',
        'Palisady grodzicowe 8-10m',
        'Wymiana i zwiezienie dużych ilości gruntu',
        'Odwodnienie igłofiltrami (8-12 tygodni)',
        'Monitoring przemieszczeń',
        'Pompy odwodniające',
        'Specjalistyczne pomiary geodezyjne',
        'Budowa ponton podziemnego (-2)',
        'Ścianki nośne podziemia',
        'Stropy międzypoziomowe (-1 i -2)',
        'Izolacje przeciwwodne (ciężkie)',
      ],
      description: 'Garaż dwupoziomowy: +2-4 miesiące do harmonogramu',
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // DANE BUDYNKÓW BIUROWYCH
  // ═══════════════════════════════════════════════════════════════════════════

  static final Map<BuildingStage, ResidentialStageData> commercialStages = {
    // Dane dla budynków biurowych będą podobne, ale z innym czasowaniem
    // dla większych pomieszczeń otwartych i większych obciążeń elektrycznych
    BuildingStage.przygotowanie: ResidentialStageData(
      label: 'Faza przygotowawcza (Budynek biurowy)',
      weekRange: (2, 4),
      timePercentage: 0.125,
      description: 'Przygotowanie terenu, zamówienia, projekty',
      tasks: [
        'Pozwolenie na budowę',
        'Zgłoszenie rozpoczęcia prac',
        'Wyznaczenie kierownika',
        'Przygotowanie harmonogramu',
        'Badania geotechniczne',
        'Wytyczenie budynku',
      ],
    ),
    BuildingStage.fundamenty: ResidentialStageData(
      label: 'Fundamenty i prace ziemne',
      weekRange: (4, 6),
      timePercentage: 0.20,
      description: 'Wykopu głębokie, systemy odwodniające',
      tasks: [
        'Wykopy i przygotowanie',
        'Zabezpieczenie wykopu',
        'Płyty fundamentowe',
        'Ścianki podziemia',
      ],
    ),
    BuildingStage.konstrukcja: ResidentialStageData(
      label: 'Konstrukcja (stan surowy)',
      weekRange: (6, 10),
      timePercentage: 0.35,
      description: 'Słupy, stropy, cykl 4-5 tygodni na kondy (większe powierzchnie)',
      tasks: [
        'Montaż konstrukcji',
        'Stropy międzykondygnacyjne',
        'Wznoszenie ścian nośnych',
      ],
    ),
    BuildingStage.przegrody: ResidentialStageData(
      label: 'Przegrody i dach',
      weekRange: (4, 6),
      timePercentage: 0.20,
      description: 'Ścianki działowe, fasada, dach',
      tasks: [
        'Ścianki działowe',
        'Montaż okien',
        'Dach',
      ],
    ),
    BuildingStage.tynki: ResidentialStageData(
      label: 'Tynki',
      weekRange: (3, 4),
      timePercentage: 0.10,
      description: 'Tynkowanie',
      tasks: [
        'Tynki wewnętrzne',
        'Tynki zewnętrzne',
      ],
    ),
    BuildingStage.posadzki: ResidentialStageData(
      label: 'Posadzki',
      weekRange: (2, 3),
      timePercentage: 0.08,
      description: 'Wylewki i posadzki',
      tasks: [
        'Wylewki betonowe',
        'Posadzki',
      ],
    ),
    BuildingStage.osprzet: ResidentialStageData(
      label: 'Osprzęt elektryczny',
      weekRange: (2, 3),
      timePercentage: 0.08,
      description: 'Montaż osprzętu',
      tasks: [
        'Osprzęt elektryczny',
        'Oprawy',
      ],
    ),
    BuildingStage.malowanie: ResidentialStageData(
      label: 'Malowanie',
      weekRange: (2, 3),
      timePercentage: 0.08,
      description: 'Prace malarskie',
      tasks: [
        'Malowanie ścian',
      ],
    ),
    BuildingStage.finalizacja: ResidentialStageData(
      label: 'Finalizacja (drzwi, ścianki)',
      weekRange: (2, 3),
      timePercentage: 0.08,
      description: 'Ostatnie prace montażowe',
      tasks: [
        'Drzwi',
        'Ścianki',
      ],
    ),
    BuildingStage.oddawanie: ResidentialStageData(
      label: 'Rozruchy i odbiory',
      weekRange: (1, 2),
      timePercentage: 0.05,
      description: 'Ostateczne odbiory',
      tasks: [
        'Pomiary',
        'Odbiory',
      ],
    ),
    BuildingStage.ozeInstalacje: ResidentialStageData(
      label: 'Instalacje OZE (Odnawialne Źródła Energii)',
      weekRange: (2, 4),
      timePercentage: 0.04,
      description: 'Montaż instalacji fotowoltaiki, magazynów energii (BESS), inwerterów i systemów zabezpieczających',
      tasks: [
        'Montaż konstrukcji wsporczej dla paneli PV',
        'Montaż modułów fotowoltaicznych',
        'Instalacja inwertera trójfazowego (jeśli dotyczy)',
        'Montaż magazynu energii (BESS) - baterie litowo-jonowe',
        'Instalacja systemu zabezpieczającego (DC/AC)',
      ],
    ),
    BuildingStage.evInfrastruktura: ResidentialStageData(
      label: 'Infrastruktura elektromobilności (Ładowarki EV)',
      weekRange: (2, 3),
      timePercentage: 0.03,
      description: 'Instalacja stacji ładowania pojazdów elektrycznych, magistrali zasilającej, systemu DLM i przejęcia UDT',
      tasks: [
        'Prowadzenie magistrali zasilającej do stanowisk ładowania',
        'Montaż rozdzielnic zasilających dla stacji ładowania',
        'Montaż wallboxów lub słupków ładowania',
        'Instalacja systemu zarządzenia burtą (DLM)',
        'Badanie i pomiary przez UDT',
      ],
    ),
  };

  // ═══════════════════════════════════════════════════════════════════════════
  // METODY OBLICZENIOWE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Oblicz całkowity czas dla budynku na podstawie liczby pięter i garaży
  static int calculateTotalWeeks(
    int aboveGroundFloors,
    int basementLevels,
    BuildingType buildingType,
  ) {
    // Bazowy czas dla 5-8 pięter
    int baseWeeks = buildingType == BuildingType.mieszkalny ? 90 : 110;

    // Mnożnik dla liczby pięter (każde piętro ponad 5 to +3 tygodnie)
    int floorAdjustment = 0;
    if (aboveGroundFloors < 5) {
      floorAdjustment = -((5 - aboveGroundFloors) * 2); // Mniej pięter = krócej
    } else if (aboveGroundFloors > 8) {
      floorAdjustment = (aboveGroundFloors - 8) * 3; // Więcej pięter = dłużej
    }

    // Dodaj czas za garaż
    int basementAdjustment = 0;
    if (basementLevels > 0) {
      basementAdjustment = basementModifiers[basementLevels]?.additionalFoundationWeeks ?? 0;
    }

    return baseWeeks + floorAdjustment + (basementAdjustment * 7).toInt();
  }

  /// Pobierz dane etapów dla typu budynku
  static Map<BuildingStage, ResidentialStageData> getStagesForBuildingType(
    BuildingType buildingType,
  ) {
    return buildingType == BuildingType.mieszkalny 
        ? residentialStages 
        : commercialStages;
  }

  /// Oblicz czas dla konkretnego etapu uwzględniając parametry budynku
  static int calculateStageWeeks(
    BuildingStage stage,
    BuildingConfiguration config,
  ) {
    final stages = getStagesForBuildingType(config.buildingType);
    final stageData = stages[stage];
    
    if (stageData == null) return 4; // Domyślnie 4 tygodnie

    // Bazowy czas 
    final totalWeeks = calculateTotalWeeks(
      config.totalLevels,
      config.basementLevels,
      config.buildingType,
    );

    // Oblicz czas etapu na podstawie procentu
    int stageWeeks = ((stageData.timePercentage * totalWeeks).round())
        .clamp(stageData.weekRange.$1, stageData.weekRange.$2);

    // Dodatkowe tygodnie dla garaży na etapach fundamentu
    if (stage == BuildingStage.fundamenty && config.basementLevels > 0) {
      stageWeeks += basementModifiers[config.basementLevels]?.additionalFoundationWeeks ?? 0;
    }

    return stageWeeks;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TYPY I ENUMERACJA
// ═══════════════════════════════════════════════════════════════════════════

/// Dane pojedynczej fazy budowy
class ResidentialStageData {
  final String label;
  final (int, int) weekRange; // (min, max)
  final double timePercentage; // % całkowitego czasu
  final String description;
  final List<String> tasks;

  const ResidentialStageData({
    required this.label,
    required this.weekRange,
    required this.timePercentage,
    required this.description,
    required this.tasks,
  });
}

/// Modyfikator czasów dla garaży podziemnych
class BasementModifier {
  final String label;
  final int additionalPrepWeeks;
  final int additionalFoundationWeeks;
  final List<String> additionalTasks;
  final String description;

  const BasementModifier({
    required this.label,
    required this.additionalPrepWeeks,
    required this.additionalFoundationWeeks,
    required this.additionalTasks,
    required this.description,
  });
}

/// Rozszerzone dane o granularzności zadań
class DetailedConstructionTask {
  final String taskName;
  final BuildingStage stage;
  final Duration estimatedDuration;
  final List<String> dependencies;
  final bool affectedByWeather;
  final List<ElectricalSystemType> relatedSystems;

  const DetailedConstructionTask({
    required this.taskName,
    required this.stage,
    required this.estimatedDuration,
    required this.dependencies,
    this.affectedByWeather = false,
    this.relatedSystems = const [],
  });
}
