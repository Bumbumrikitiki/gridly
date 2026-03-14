/// Rozszerzona integracja harmonogramu z pełnym podziałem na systemy
/// elektryczne i teletechniczne dla budynków mieszkalnych i biurowych
/// 
/// Uwzględnia specyficzne wymagania każdego rodzaju budynku
library;

import 'package:gridly/multitool/project_manager/models/project_models.dart';

/// Generatory tasków dla wszystkich systemów elektrycznych i teletechnicznych
/// Zawiera specjalizowane metody dla każdego typu systemu
class ElectricalSystemsTaskGenerator {

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEMY PODSTAWOWE (dla obu typów budynków)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Zasilanie - KRYTYCZNE DLA WSZYSTKICH BUDYNKÓW
  static List<ChecklistTask> generatePowerSupplyTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.zasilanie)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'zasilanie-001-projekt',
        title: '📋 Projekt systemu zasilania',
        description:
          'Opracuj projekt elektroenergetyczny. Uwzględnij moc szczytową, liczę obciążenia, rodzaj zasilania (NN, SN, wł. generacja).',
        system: ElectricalSystemType.zasilanie,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 21,
      ),
      ChecklistTask(
        id: 'zasilanie-002-zamowienie',
        title: '🚚 Zamówienie rozdzielnic głównych i podrzędnych',
        description:
          'Wyślij rozdzielnice do prefabrykacji. WAŻNE: 4-6 tygodni czasu realizacji! Musi być wysłane 4 tygodnie PRZED fazą przegród.',
        system: ElectricalSystemType.zasilanie,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 28,
        notes: 'Potwierdzić dostęp do hali prefabrykacji i terminarz dostaw',
      ),
      ChecklistTask(
        id: 'zasilanie-003-przeboje',
        title: '⚒️ Przeboje na trasach zasilaczy głównych',
        description:
          'Wykonaj przeboje w słupach i ścianach nośnych dla zasilaczy głównych. Etap: podczas wznoszenia konstrukcji.',
        system: ElectricalSystemType.zasilanie,
        stage: BuildingStage.konstrukcja,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['zasilanie-002-zamowienie'],
      ),
      ChecklistTask(
        id: 'zasilanie-004-okablowanie',
        title: '🔌 Okablowanie zasilaczy głównych i podrzędnych',
        description:
          'Zainstaluj kable zasilaczy. Etap: podczas montażu osprzętu elektrycznego. Rezystancja izolacji: min. 10MΩ.',
        system: ElectricalSystemType.zasilanie,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['zasilanie-003-przeboje'],
      ),
      ChecklistTask(
        id: 'zasilanie-005-montaz',
        title: '🔧 Montaż rozdzielnic głównych i podrzędnych',
        description:
          'Zainstaluj rozdzielnice. Sprawdź połączenia, etykietowanie i uziemienie obudów.',
        system: ElectricalSystemType.zasilanie,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['zasilanie-004-okablowanie'],
      ),
      ChecklistTask(
        id: 'zasilanie-006-pomiary',
        title: '📊 Pomiary i testy zasilania',
        description:
          'Pomiary rezystancji uziemienia, napięcia, prądów, impedancji pętli. Test funkcjonalny wszystkich wyłączników.',
        system: ElectricalSystemType.zasilanie,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['zasilanie-005-montaz'],
        notes: 'Współpraca z dostawcą energii dla włączenia zasilania',
      ),
    ];
  }

  /// Oświetlenie - OBOWIĄZKOWE
  static List<ChecklistTask> generateLightingTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.oswietlenie)) {
      return [];
    }

    final isBiuro = config.buildingType == BuildingType.biurowy;
    
    return [
      ChecklistTask(
        id: 'oswietlenie-001-projekt',
        title: '💡 Projekt oświetlenia',
        description: isBiuro
          ? 'Projekt oświetlenia dla biur (min. 300 lx, LED). Czujniki ruchu i zmierzchu dla korytarzy.'
          : 'Projekt oświetlenia: mieszkania (min. 150 lx), schody (min. 50 lx), podwórko (min. 20 lx).',
        system: ElectricalSystemType.oswietlenie,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
      ),
      ChecklistTask(
        id: 'oswietlenie-002-zamowienie',
        title: '📦 Zamówienie opraw oświetleniowych',
        description: 'Zamów oprawy LED (DLC certified jeśli biuro) w ilości: ${isBiuro ? "duże oprawy do biur + korytarze" : "do mieszkań + wspólne"}',
        system: ElectricalSystemType.oswietlenie,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
        notes: 'Czas: 2-4 tygodnie dla dużych zamówień',
      ),
      ChecklistTask(
        id: 'oswietlenie-003-kanaly',
        title: '🔲 Przygotowanie kanałów dla oświetlenia',
        description: 'Osadź kanały I pudełka dla przewodów oświetleniowych zgodnie z projektem.',
        system: ElectricalSystemType.oswietlenie,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['oswietlenie-001-projekt'],
      ),
      ChecklistTask(
        id: 'oswietlenie-004-przewody',
        title: '🧵 Okablowanie oświetleniowe',
        description: 'Zainstaluj przewody oświetleniowe zgodnie z planem. Przechody dla sufitów pośrednich.',
        system: ElectricalSystemType.oswietlenie,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['oswietlenie-003-kanaly'],
      ),
      ChecklistTask(
        id: 'oswietlenie-005-montaz',
        title: '💡 Montaż opraw oświetleniowych',
        description: 'Zainstaluj oprawy sufitowe i ścienne. Połącz z przewodami. Pierwszy test.',
        system: ElectricalSystemType.oswietlenie,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 5,
        dependsOnTaskIds: ['oswietlenie-004-przewody'],
      ),
      ChecklistTask(
        id: 'oswietlenie-006-test',
        title: '✅ Test i odbiór oświetlenia',
        description: 'Sprawdzenie funkcjonalności całej instalacji. Pomiary natężenia światła (lux).',
        system: ElectricalSystemType.oswietlenie,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['oswietlenie-005-montaz'],
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEMY SPECJALIZOWANE DLA WSZYSTKICH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Internet i Telekomunikacja
  static List<ChecklistTask> generateInternetTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.internet)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'internet-001-projekt',
        title: '🌐 Projekt infrastruktury IT',
        description:
          'Projekt kablażu strukturalnego (kategoria 6A minimum), szaf sieciowych i punktów dostępu WiFi.',
        system: ElectricalSystemType.internet,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 7,
      ),
      ChecklistTask(
        id: 'internet-002-kanaly',
        title: '📍 Kanały dla kablażu IT',
        description: 'Osadź kanały, przepusty i pudełka standardowe dla infrastruktury IT.',
        system: ElectricalSystemType.internet,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['internet-001-projekt'],
      ),
      ChecklistTask(
        id: 'internet-003-kablowanie',
        title: '🔗 Kablowanie strukturalne',
        description: 'Zainstaluj kable Ethernet kategoria 6A, opto włókna (jeśli SN). Certyfikacja.',
        system: ElectricalSystemType.internet,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['internet-002-kanaly'],
      ),
      ChecklistTask(
        id: 'internet-004-szafy',
        title: '🗄️ Montaż rozdzielnic sieciowych i WiFi AP',
        description: 'Zainstaluj szafy sieciowe, switche, routery i punkty dostępu WiFi.',
        system: ElectricalSystemType.internet,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 3,
        dependsOnTaskIds: ['internet-003-kablowanie'],
      ),
      ChecklistTask(
        id: 'internet-005-test',
        title: '📡 Test przepustowości i zasięgu WiFi',
        description: 'Pomiary prędkości, latencji, zasięgu WiFi. Dokumentacja.',
        system: ElectricalSystemType.internet,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['internet-004-szafy'],
      ),
    ];
  }

  /// Monitoring CCTV
  static List<ChecklistTask> generateCCTVTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.cctv)) {
      return [];
    }

    final isBiuro = config.buildingType == BuildingType.biurowy;
    final kamerCount = isBiuro ? '40-80 kamer' : '8-16 kamer';

    return [
      ChecklistTask(
        id: 'cctv-001-projekt',
        title: '📹 Projekt systemu CCTV',
        description:
          'Rozmieszczenie $kamerCount, typ (kopułkowe, turretki, kuliste), rejestratory, serwery. Rezolucja min. 2MP (biuro 4-8MP).',
        system: ElectricalSystemType.cctv,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
      ),
      ChecklistTask(
        id: 'cctv-002-kanaly',
        title: '📍 Kanały i pudełka do kamer',
        description: 'Osadź kanały koaksjaln dla kamer analogowych lub kategoria 5e dla IP.',
        system: ElectricalSystemType.cctv,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['cctv-001-projekt'],
      ),
      ChecklistTask(
        id: 'cctv-003-zasilanie',
        title: '⚡ Zasilanie dla systemu CCTV',
        description: 'Dedykowane zasilanie, UPS dla rejestratorów, zasilanie PoE dla kamer IP.',
        system: ElectricalSystemType.cctv,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['cctv-002-kanaly'],
      ),
      ChecklistTask(
        id: 'cctv-004-montaz',
        title: '🔧 Montaż kamer i rejestratorów',
        description: '$kamerCount - ustawienie kątów widzenia, ostrość, testowanie.',
        system: ElectricalSystemType.cctv,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 5,
        dependsOnTaskIds: ['cctv-003-zasilanie'],
      ),
      ChecklistTask(
        id: 'cctv-005-konfiguracja',
        title: '⚙️ Konfiguracja i test CCTV',
        description: 'Ustawienie rejestracji, alerts, zdalny dostęp, kopia zapasowa.',
        system: ElectricalSystemType.cctv,
        stage: BuildingStage.finalizacja,
        daysBeforeStageEnd: 3,
        dependsOnTaskIds: ['cctv-004-montaz'],
      ),
    ];
  }

  /// Systemy Ppoż (Fire Alarm)
  static List<ChecklistTask> generateFireAlarmTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.ppoz)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'ppoz-001-projekt',
        title: '🔥 Projekt systemu sygnalizacji pożarowej',
        description:
          'Rozmieszczenie detektorów dymu, czujników temperatury, syren, przycisków alarmowych.',
        system: ElectricalSystemType.ppoz,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 7,
      ),
      ChecklistTask(
        id: 'ppoz-002-kanaly',
        title: '📍 Kanały dla sygnalizacji pożarowej',
        description: 'Osadź kanały dedykowane dla przewodów ppoż (oddzielnie od innych sieci!)',
        system: ElectricalSystemType.ppoz,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['ppoz-001-projekt'],
      ),
      ChecklistTask(
        id: 'ppoz-003-zasilanie',
        title: '⚡ Zasilanie centrali ppoż',
        description: 'Dedykowane zasilanie z zasilaczem awaryjnym (UPS, 24h)',
        system: ElectricalSystemType.ppoz,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['ppoz-002-kanaly'],
      ),
      ChecklistTask(
        id: 'ppoz-004-montaz',
        title: '🚨 Montaż detektorów i centrali',
        description: 'Zainstaluj detektory, czujniki, syrenę główną, przygotuj pulpit kontrolny.',
        system: ElectricalSystemType.ppoz,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['ppoz-003-zasilanie'],
      ),
      ChecklistTask(
        id: 'ppoz-005-test',
        title: '✅ Test i certyfikacja systemu ppoż',
        description: 'Testy wszystkich detektorów, syren, przycisków. Certyfikacja przez organ ppoż.',
        system: ElectricalSystemType.ppoz,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['ppoz-004-montaz'],
        notes: 'Wymagane zaświadczenie z wojewódzkiego inspektoratu ppoż',
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEMY SPECJALIZOWANE DLA BUDYNKÓW BIUROWYCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Klimatyzacja / HVAC - KRYTYCZNE DLA BIUROWCÓW
  static List<ChecklistTask> generateAirConditioningTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (config.buildingType != BuildingType.biurowy ||
        !config.selectedSystems.contains(ElectricalSystemType.klimatyzacja)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'klimat-001-projekt',
        title: '❄️ Projekt systemu klimatyzacji',
        description:
          'Projekt HVAC z obliczeniem mocy chłodzenia (należy 22-24°C), kanałów powietrza, jednostek wewnętrznych.',
        system: ElectricalSystemType.klimatyzacja,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
      ),
      ChecklistTask(
        id: 'klimat-002-zamowienie',
        title: '🚚 Zamówienie urządzeń klimatyzacyjnych',
        description:
          'Nagrzewnice, jednostki wewnętrzne, centrale wentylacyjne. Czas: 3-6 tygodni.',
        system: ElectricalSystemType.klimatyzacja,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 28,
      ),
      ChecklistTask(
        id: 'klimat-003-kanaly',
        title: '🔲 Montaż kanałów nawietrania',
        description:
          'Zainstaluj kanały powietrza, przechody przez ściany, tłumiki dźwięku.',
        system: ElectricalSystemType.klimatyzacja,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 21,
        dependsOnTaskIds: ['klimat-002-zamowienie'],
      ),
      ChecklistTask(
        id: 'klimat-004-zasilanie',
        title: '⚡ Zasilanie jednostek klimatyzacyjnych',
        description:
          'Dedykowane linie zasilające dla kompresorów (trójfazowe). Sterowanie i czujniki temperatury.',
        system: ElectricalSystemType.klimatyzacja,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['klimat-003-kanaly'],
      ),
      ChecklistTask(
        id: 'klimat-005-montaz',
        title: '🔧 Montaż jednostek wewnętrznych i centralnych',
        description:
          'Zainstaluj jednostki wewnętrzne w biurach, pompę ciepła, regulator temperatury.',
        system: ElectricalSystemType.klimatyzacja,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 5,
        dependsOnTaskIds: ['klimat-004-zasilanie'],
      ),
      ChecklistTask(
        id: 'klimat-006-test',
        title: '❄️ Uruchomienie i test klimatyzacji',
        description:
          'Test chłodzenia/ogrzewania, pomiary temperatury w pomieszczeniach, regulacja.',
        system: ElectricalSystemType.klimatyzacja,
        stage: BuildingStage.finalizacja,
        daysBeforeStageEnd: 3,
        dependsOnTaskIds: ['klimat-005-montaz'],
      ),
    ];
  }

  /// BMS (Building Management System) - DLA BIUROWCÓW
  static List<ChecklistTask> generateBMSTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (config.buildingType != BuildingType.biurowy ||
        !config.selectedSystems.contains(ElectricalSystemType.bms)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'bms-001-projekt',
        title: '🏛️ Projekt systemu zarządzania budynkiem (BMS)',
        description:
          'Architektura sys temowa: czujniki, serwery, kontrolery. Integracja: oświetlenie, klimat, alarmy, parking.',
        system: ElectricalSystemType.bms,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
      ),
      ChecklistTask(
        id: 'bms-002-serwery',
        title: '🖥️ Instalacja serwerów i kontrolerów BMS',
        description:
          'Serwery główne, wielozadaniowe, dedykowane zasilanie, klimatyzacja sali serwerowej, backup dyski.',
        system: ElectricalSystemType.bms,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['bms-001-projekt'],
      ),
      ChecklistTask(
        id: 'bms-003-sensory',
        title: '📊 Instalacja czujników BMS',
        description:
          'Czujniki temperatury, wilgotności, CO2, oświetlenia, zajętości, energii.',
        system: ElectricalSystemType.bms,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['bms-002-serwery'],
      ),
      ChecklistTask(
        id: 'bms-004-siec',
        title: '🔗 Sieć komunikacyjna BMS',
        description:
          'Dedykowana sieć M-Bus, Bacnet lub Lonworks. Bezpieczeństwo sieciowe.',
        system: ElectricalSystemType.bms,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 5,
        dependsOnTaskIds: ['bms-003-sensory'],
      ),
      ChecklistTask(
        id: 'bms-005-oprogramowanie',
        title: '⚙️ Konfiguracja i testowanie oprogramowania BMS',
        description:
          'Integracja systemów, ustawienie reguł automatyzacji, raporty energii, alarmy.',
        system: ElectricalSystemType.bms,
        stage: BuildingStage.finalizacja,
        daysBeforeStageEnd: 3,
        dependsOnTaskIds: ['bms-004-siec'],
        notes: 'Szkolenie dla operatorów',
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEMY SPECJALIZOWANE DLA BUDYNKÓW MIESZKALNYCH
  // ═══════════════════════════════════════════════════════════════════════════

  /// Domofon / Interkom - DLA MIESZKALNYCH
  static List<ChecklistTask> generateIntercomTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (config.buildingType != BuildingType.mieszkalny ||
        !config.selectedSystems.contains(ElectricalSystemType.domofonowa)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'domofon-001-projekt',
        title: '📱 Projekt systemu domofonowego',
        description:
          'Analogowy lub cyfrowy domofon z kamerą (HD 1080p). Liczba przycisków = liczba jednostek.',
        system: ElectricalSystemType.domofonowa,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 7,
      ),
      ChecklistTask(
        id: 'domofon-002-kanaly',
        title: '📍 Kanały dla okablowania domofonowego',
        description:
          'Osadź kanały od wejścia głównego do każdej jednostki oddzielna linia.',
        system: ElectricalSystemType.domofonowa,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['domofon-001-projekt'],
      ),
      ChecklistTask(
        id: 'domofon-003-zasilanie',
        title: '⚡ Zasilanie central domofonowych',
        description:
          'Dedykowane zasilanie z baterią awaryjną (12V, min. 2h autonomii).',
        system: ElectricalSystemType.domofonowa,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['domofon-002-kanaly'],
      ),
      ChecklistTask(
        id: 'domofon-004-montaz',
        title: '📹 Montaż kamery głównej i słuchawek',
        description:
          'Zainstaluj kamerę wejściową, słuchawki w mieszkaniach, sygnalizator.',
        system: ElectricalSystemType.domofonowa,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 5,
        dependsOnTaskIds: ['domofon-003-zasilanie'],
      ),
      ChecklistTask(
        id: 'domofon-005-test',
        title: '✅ Test systemu domofonowego',
        description:
          'Test rozmów, obrazu, otwarcia drzwi, baterii awaryjnej.',
        system: ElectricalSystemType.domofonowa,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['domofon-004-montaz'],
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYSTEMY DODATKOWE (dla obu typów budynków)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Panele słoneczne (PV)
  static List<ChecklistTask> generatePVTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.panelePV)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'pv-001-projekt',
        title: '☀️ Projekt instalacji PV',
        description:
          'Moc systemu, rozmieszczenie paneli, falowniki, akumulatory (jeśli off-grid).',
        system: ElectricalSystemType.panelePV,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 14,
      ),
      ChecklistTask(
        id: 'pv-002-konstrukcja',
        title: '🏗️ Przygotowanie konstrukcji dachu',
        description:
          'Wzmocnienie dachu, przygotowanie systemów mocujących.',
        system: ElectricalSystemType.panelePV,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 14,
        dependsOnTaskIds: ['pv-001-projekt'],
      ),
      ChecklistTask(
        id: 'pv-003-zasilanie',
        title: '⚡ Zasilanie falowników i akumulatorów',
        description:
          'Dedykowane zasilanie 3-fazowe, rozdzielnica DC, system ochrony.',
        system: ElectricalSystemType.panelePV,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['pv-002-konstrukcja'],
      ),
      ChecklistTask(
        id: 'pv-004-montaz',
        title: '📦 Montaż paneli i falowników',
        description:
          'Zainstaluj panele, falowniki, akumulatory (jeśli są). Uziemienie i piorunochronia.',
        system: ElectricalSystemType.panelePV,
        stage: BuildingStage.osprzet,
        daysBeforeStageEnd: 5,
        dependsOnTaskIds: ['pv-003-zasilanie'],
      ),
      ChecklistTask(
        id: 'pv-005-uruchomienie',
        title: '🔌 Uruchomienie i rejestracja PV',
        description:
          'Test produkcji energii, rejestracja u operatora sieci, podpisanie umowy.',
        system: ElectricalSystemType.panelePV,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['pv-004-montaz'],
      ),
    ];
  }

  /// Ochrona odgromowa
  static List<ChecklistTask> generateLightningProtectionTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    if (!config.selectedSystems.contains(ElectricalSystemType.odgromowa)) {
      return [];
    }

    return [
      ChecklistTask(
        id: 'odgrom-001-projekt',
        title: '⛈️ Projekt systemu ochrony odgromowej',
        description:
          'Ilość piorunochronów, trasy uziemniające, klasa ochrony I, II lub III.',
        system: ElectricalSystemType.odgromowa,
        stage: BuildingStage.przygotowanie,
        daysBeforeStageEnd: 7,
      ),
      ChecklistTask(
        id: 'odgrom-002-instalacja',
        title: '🔧 Instalacja piorunochronów i przewodów uziemniających',
        description:
          'Zainstaluj piorunochrony na dachu, przewody uziemniające, połącz z uziemieniem.',
        system: ElectricalSystemType.odgromowa,
        stage: BuildingStage.przegrody,
        daysBeforeStageEnd: 7,
        dependsOnTaskIds: ['odgrom-001-projekt'],
      ),
      ChecklistTask(
        id: 'odgrom-003-pomiary',
        title: '📊 Pomiary rezystancji uziemnienia',
        description:
          'Pomiar rezystancji uziemienia: max. 10Ω. Certyfikat.',
        system: ElectricalSystemType.odgromowa,
        stage: BuildingStage.oddawanie,
        daysBeforeStageEnd: 0,
        dependsOnTaskIds: ['odgrom-002-instalacja'],
      ),
    ];
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // METODA GŁÓWNA - GENERATOR TASKÓW DLA WSZYSTKICH SYSTEMÓW
  // ═════════════════════════════════════════════════════════════════════════════

  /// Wygeneruj wszystkie taskami dla wybranych systemów
  static List<ChecklistTask> generateAllSystemTasks(
    BuildingConfiguration config,
    List<ProjectPhase> phases,
  ) {
    final allTasks = <ChecklistTask>[];

    // ZAWSZE obowiązkowe
    allTasks.addAll(generatePowerSupplyTasks(config, phases));
    allTasks.addAll(generateLightingTasks(config, phases));

    // Uniwersalne
    for (final system in config.selectedSystems) {
      switch (system) {
        case ElectricalSystemType.internet:
          allTasks.addAll(generateInternetTasks(config, phases));
          break;
        case ElectricalSystemType.cctv:
          allTasks.addAll(generateCCTVTasks(config, phases));
          break;
        case ElectricalSystemType.ppoz:
          allTasks.addAll(generateFireAlarmTasks(config, phases));
          break;
        case ElectricalSystemType.panelePV:
          allTasks.addAll(generatePVTasks(config, phases));
          break;
        case ElectricalSystemType.odgromowa:
          allTasks.addAll(generateLightningProtectionTasks(config, phases));
          break;
        default:
          break;
      }
    }

    // BIURO
    if (config.buildingType == BuildingType.biurowy) {
      allTasks.addAll(generateAirConditioningTasks(config, phases));
      allTasks.addAll(generateBMSTasks(config, phases));
    }

    // MIESZKALNY
    if (config.buildingType == BuildingType.mieszkalny) {
      allTasks.addAll(generateIntercomTasks(config, phases));
    }

    return allTasks;
  }
}
