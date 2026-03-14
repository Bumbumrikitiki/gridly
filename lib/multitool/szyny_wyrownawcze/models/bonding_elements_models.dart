/// Przewodnik Szyn Wyrównawczych i Uziemienia Budowlanego
/// 
/// ⚠️ OGRANICZENIE ODPOWIEDZIALNOŚCI:
/// - Wartości w tym narzędziu są ORIENTACYJNE i oparte na normach PN-HD 60364-5-54, PN-EN 50164, PN-IEC 61936
/// - Wartości stanowią WSPARCIE dla projektanta/inspektora, nie zastępcę obliczeń szczegółowych
/// - OBOWIĄZKOWA weryfikacja przez uprawnionych projektantów i inspektorów ds. bezpieczeństwa
/// - W przypadku wątpliwości - zawsze konsultacja z projektantem/inspektorem elektrykiem
/// - Użytkownik aplikacji ponosi PEŁNĄ odpowiedzialność za prawidłowość wyboru parametrów
/// - Producent aplikacji nie ponosi odpowiedzialności za błędy w doborze materiałów wynikłe z użycia tego narzędzia
library;

// Definicja typów elementów wymagających uziemienia/wyrównania potencjału
enum BondingElementType {
  przedzielnica, // Rozdzielnica główna (RB, RBTK)
  ruPH, // Rura przewodu handlowego
  ruWoda, // Rura wodna (stalowa)
  ruKanalizacja, // Rura kanalizacyjna (stalowa)
  ruGas, // Rura gazowa (stalowa)
  ruInstalacyjna, // Rura instalacyjna (stalowa)
  rusztowanie, // Rusztowanie metalowe
  barak, // Barak (drewniana obudowa metalowa)
  kontener, // Kontener budowlany
  maszyna, // Maszyna budowlana (żuraw, podnośnik)
  przykladownikStacji, // Przyciągacz stacji trafo
  studzienkaElektryczna, // Studzienka elektroenergetyczna
  latarnia, // Słup oświetleniowy
  maszt, // Maszt (sygnalizacyjny, antenowy)
}

// Enumeracja przekrojów mosiężnych szyn wyrównawczych
enum SzynaWyrownawczaRozmiar {
  mm10x10, // 10 x 10 mm = 100 mm² - małe obiekty
  mm10x20, // 10 x 20 mm = 200 mm² - średnie obiekty
  mm10x30, // 10 x 30 mm = 300 mm² - duże obiekty
  mm16x20, // 16 x 20 mm = 320 mm² - bardzo duże
}

// Materiał szyny
enum SzynaMaterial {
  mosiadz, // Najczęściej stosowany, TM02 (CW617N), odporny na korozję
  miedz, // Alternatywa, droższy
  aluminium, // Rzadko, wymaga specjalnych połączeń
}

// Metoda połączenia szyny z elementem
enum SposobPoczenia {
  srubaM10, // Standardowy śrub M10 (dokręcić 25-30 Nm)
  srubaM12, // Dla większych prądów
  spawanie, // Trwałe, do 200 A²s²
  klem, // Szybkie, ale mniej niezawodne
  plastron, // Medyczne złącze trzypunktowe (certyfikowane)
}

// Prądy nominalne dla potrzeb doboru
enum PradNominalny {
  i16A, // Gniazda, oświetlenie
  i20A, // Oświetlenie duże, kontenery
  i25A, // Karczownica, mała maszyna
  i32A, // Maszyny średnie, barak RB
  i63A, // Żuraw, moje rozdzielnice
  i125A, // Rozdzielnice główne
  i160A, // Trafo główny
  i200A, // Duże trany, zasilanie główne
}

// Przekroje przewodów miedzianych (PE/N) wg PN-HD 60364-5-54
enum PrzekrojKabla {
  mm2_1_5, // 1,5 mm² - małe prądy I≤16A (rzadko)
  mm2_2_5, // 2,5 mm² - I≤20A, gniazda
  mm2_4, // 4 mm² - I≤25A, oświetlenie
  mm2_6, // 6 mm² - I≤32A, zasilanie
  mm2_10, // 10 mm² - I≤50A, maszyny
  mm2_16, // 16 mm² - I≤63A, większe maszyny
  mm2_25, // 25 mm² - I≤100A, rozdzielnice
  mm2_35, // 35 mm² - I≤125A
  mm2_50, // 50 mm² - I≤160A
  mm2_70, // 70 mm² - I≤200A, zasilanie główne
}

/// Model typu PEN
/// W Polsce standard to podział PEN na PE i N wg PN-HD 60364-4-41
class PodzialPEN {
  final String nazwa; // Np. "Podział PEN na budowie"
  final String opis;
  final String przekrojPE; // Np. "≥ 16 mm² Cu"
  final String przekrojN; // Np. "= 16 mm² Cu"
  final String miejscePodzial; // Gdzie się dzieli? Rozdzielnica główna
  final String uwagi;

  PodzialPEN({
    required this.nazwa,
    required this.opis,
    required this.przekrojPE,
    required this.przekrojN,
    required this.miejscePodzial,
    required this.uwagi,
  });
}

/// Szyna wyrównawcza / Główna Szyna Wyrównawcza (GSW)
class SzynaWyrownawcza {
  final String nazwa; // Np. "GSW budowy"
  final SzynaWyrownawczaRozmiar rozmiar; // 10x20, 10x30...
  final SzynaMaterial material; // Mosiądz, miedź
  final String powierzchnia; // "200 mm²"
  final String rezystancja; // "ρ ≈ 0.0175 Ω·mm²/m"
  final String dozwolonyPrad; // "Bez ograniczeń dla rozm. >100mm²"
  final List<SposobPoczenia> dostepneSposoby; // Jakie połączenia?
  final String norma; // PN-HD 60364-5-54
  final String uwagi;

  SzynaWyrownawcza({
    required this.nazwa,
    required this.rozmiar,
    required this.material,
    required this.powierzchnia,
    required this.rezystancja,
    required this.dozwolonyPrad,
    required this.dostepneSposoby,
    required this.norma,
    required this.uwagi,
  });
}

/// Element wymagający uziemienia / wyrównania potencjału
class ElementUziemienia {
  final BondingElementType typ;
  final String nazwa; // Opisowa nazwa
  final String opis; // Co dokładnie to jest?
  
  // Wymagane połączenie
  final String wymaganyPrzekrocj; // np. "≥ 6 mm² Cu dla I≤32A"
  final List<PrzekrojKabla> dopuszczalnePrzekroje;
  final String dlaczego; // Wyjaśnienie normatywne
  
  // Punkt podłączenia
  final String punktPodlaczenia; // Gdzie podłączyć na elemencie?
  final SposobPoczenia rekomendowanySposob; // Jak podłączyć?
  
  // Dodatkowe wymogi
  final bool wymagaSpawania; // Czy musi być spawane?
  final bool wymagaPrintosowania; // Czy wymagane certyfikowane złącze?
  final String specjalnePrzypisy; // Np. "Max 2 m do GSW"
  
  // Normy
  final List<String> normy; // PN-HD 60364-5-54, PN-EN 50164 itd
  
  ElementUziemienia({
    required this.typ,
    required this.nazwa,
    required this.opis,
    required this.wymaganyPrzekrocj,
    required this.dopuszczalnePrzekroje,
    required this.dlaczego,
    required this.punktPodlaczenia,
    required this.rekomendowanySposob,
    required this.wymagaSpawania,
    required this.wymagaPrintosowania,
    required this.specjalnePrzypisy,
    required this.normy,
  });
}

/// Rekomendacja doboru kabla dla elementu
class RekomendacjaKabla {
  final BondingElementType element;
  final String nazwaElementu;
  final PrzekrojKabla przekroj;
  final String przekrojMM; // "6 mm²"
  final List<PradNominalny> zasilanieNa;
  final SposobPoczenia rekomendowanySposob;
  final String dlaczego; // Uzasadnienie normatywne
  final String uwagi; // Specjalne uwagi dla tego elementu
  final List<String> warunkiBudowy; // Rodzaj budowy, w której to się stosuje
  final String norma; // Norma (np. PN-HD 60364-5-54)
  final String disclaimer; // DISCLAIMER

  RekomendacjaKabla({
    required this.element,
    required this.nazwaElementu,
    required this.przekroj,
    required this.przekrojMM,
    required this.zasilanieNa,
    required this.rekomendowanySposob,
    required this.dlaczego,
    required this.uwagi,
    required this.warunkiBudowy,
    required this.norma,
    required this.disclaimer,
  });
}

/// Kalkulator - wejście: element + prąd => wyjście: przekrój kabla
class DobrorKablaWejscie {
  final BondingElementType element;
  final PradNominalny pradNominalny;
  final String opisBudowy; // "Barak", "RB mała", itp
  final bool wymagaSpawania; // Czy musi być spawane?

  DobrorKablaWejscie({
    required this.element,
    required this.pradNominalny,
    required this.opisBudowy,
    required this.wymagaSpawania,
  });
}

class DobrorKablaWyjscie {
  final BondingElementType element;
  final PrzekrojKabla rekomendowanyPrzekroj;
  final String przekrojMM;
  final String norma; // Odniesienie normatywne
  final String uzasadnienie;
  final SposobPoczenia rekomendowanySposob;
  final String uwagi;
  final bool wymegaCertyfikatu; // Czy wymaga certyfikowanego złącza?
  final String ostrzezenie; // Dodatkowe ostrzeżenia
  final String disclaimer; // DISCLAIMER
  
  DobrorKablaWyjscie({
    required this.element,
    required this.rekomendowanyPrzekroj,
    required this.przekrojMM,
    required this.norma,
    required this.uzasadnienie,
    required this.rekomendowanySposob,
    required this.uwagi,
    required this.wymegaCertyfikatu,
    required this.ostrzezenie,
    required this.disclaimer,
  });
}

/// Baza standardowych rekomendacji dla typowych przypadków budowlanych
class BazaRekomendacji {
  static final List<ElementUziemienia> standardoweElementy = [
    // ROZDZIELNICA
    ElementUziemienia(
      typ: BondingElementType.przedzielnica,
      nazwa: 'Rozdzielnica główna (RB)',
      opis: 'Rozdzielnica budowlana główna - punkt centralny uziemienia',
      wymaganyPrzekrocj: '≥ 16 mm² Cu (dla I≤63A) lub ≥ 25 mm² (dla I>63A)',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_16,
        PrzekrojKabla.mm2_25,
        PrzekrojKabla.mm2_35,
        PrzekrojKabla.mm2_50,
      ],
      dlaczego:
        'Rozdzielnica jest centralnym punktem dystrybucji i musi być niezawodnie uziemiona wg PN-HD 60364-5-54 (tab. 54.1).',
      punktPodlaczenia: 'Do szyny PE wewnątrz rozdzielnicy - dedykowany punkt',
      rekomendowanySposob: SposobPoczenia.srubaM12,
      wymagaSpawania: false,
      wymagaPrintosowania: false,
      specjalnePrzypisy: 'Połączenie musi wytrzymać min. 200 A²s²',
      normy: ['PN-HD 60364-5-54', 'PN-HD 60364-4-41', 'PN-EN 50164'],
    ),

    // RURY
    ElementUziemienia(
      typ: BondingElementType.ruWoda,
      nazwa: 'Rura wodna (stalowa)',
      opis: 'Metalowa rura wodociągowa wchodząca do budowy',
      wymaganyPrzekrocj: '≥ 6 mm² Cu (powyżej 2 m)',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_6,
        PrzekrojKabla.mm2_10,
        PrzekrojKabla.mm2_16,
      ],
      dlaczego:
        'Rury stalowe mogą być elementem wyrównania potencjałów - bezpieczeństwo wg PN-HD 60364-4-41.',
      punktPodlaczenia: 'Na rurę 30-50 cm od wejścia do budowy - opaską lub certyfikowanym zaciskiem',
      rekomendowanySposob: SposobPoczenia.srubaM10,
      wymagaSpawania: false,
      wymagaPrintosowania: true, // Wymagane certyfikowane złącze!
      specjalnePrzypisy:
        'Odległość od GSW max 2 m. Montaż min. 0,5 m od filtrów. Oczyścić warstwę ochronną przed montażem.',
      normy: ['PN-HD 60364-4-41', 'PN-EN 50164'],
    ),

    ElementUziemienia(
      typ: BondingElementType.ruGas,
      nazwa: 'Rura gazowa (stalowa)',
      opis: 'Metalowa rura gazowa wchodząca do budowy',
      wymaganyPrzekrocj: '≥ 6 mm² Cu',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_6,
        PrzekrojKabla.mm2_10,
        PrzekrojKabla.mm2_16,
      ],
      dlaczego: 'Ze względów bezpieczeństwa - przeciwdziałanie napięciom',
      punktPodlaczenia:
        'Na rurę 30 cm od wejścia - przed głównym zaworem. Certyfikowanym złączem!',
      rekomendowanySposob: SposobPoczenia.srubaM10,
      wymagaSpawania: false,
      wymagaPrintosowania: true, // BARDZO WAŻNE - rura gazowa!
      specjalnePrzypisy:
        'OBOWIĄZKOWE certyfikowane złącze wg PN-EN 50164. Połączenie wykonać przed szafką gazową.',
      normy: ['PN-HD 60364-4-41', 'PN-EN 50164', 'PN-EN 12098-5'],
    ),

    ElementUziemienia(
      typ: BondingElementType.ruInstalacyjna,
      nazwa: 'Rura kanalizacyjna (stalowa)',
      opis: 'Metalowa rura kanalizacyjna odchodząca z budowy',
      wymaganyPrzekrocj: '≥ 4 mm² Cu',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_4,
        PrzekrojKabla.mm2_6,
        PrzekrojKabla.mm2_10,
      ],
      dlaczego: 'Potencjalne prądy przejściowe - wyrównanie potencjału',
      punktPodlaczenia: 'Na rurę przed wyjściem z budowy - 20-30 cm od wypływu',
      rekomendowanySposob: SposobPoczenia.srubaM10,
      wymagaSpawania: false,
      wymagaPrintosowania: false,
      specjalnePrzypisy: 'Przeprowadzić u góry, przed wylaniem do gruntu',
      normy: ['PN-HD 60364-4-41'],
    ),

    // RUSZTOWANIE
    ElementUziemienia(
      typ: BondingElementType.rusztowanie,
      nazwa: 'Rusztowanie metalowe',
      opis:
        'Konstrukcja rusztowania metalowego - kluczowy element bezpieczeństwa pracowników i sprzętu',
      wymaganyPrzekrocj: '≥ 10 mm² Cu dla rusztowań >10 m',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_10,
        PrzekrojKabla.mm2_16,
        PrzekrojKabla.mm2_25,
      ],
      dlaczego:
        'Rusztowanie musi być wyrównane potencjałowo - praca na wysokości, bezpieczeństwo wg PN-ISO 12811',
      punktPodlaczenia: 'Min. 2 punkty - na górze i na dole konstrukcji',
      rekomendowanySposob: SposobPoczenia.spawanie, // Preferując spawanie
      wymagaSpawania: true, // TAK - rusztowanie wymaga spawania!
      wymagaPrintosowania: false,
      specjalnePrzypisy:
        'Spawanie do głównego słupa rusztowania. Min. 2 niezależne połączenia. Połączenia muszą wytrzymać 200 A²s²',
      normy: [
        'PN-ISO 12811',
        'PN-HD 60364-4-41',
        'PN-EN 1004 (rusztowania kołowe)',
      ],
    ),

    // BARAK
    ElementUziemienia(
      typ: BondingElementType.barak,
      nazwa: 'Barak (konstrukcja metalowa)',
      opis: 'Drewniany barak z elementami metalowej obudowy',
      wymaganyPrzekrocj: '≥ 6-10 mm² Cu',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_6,
        PrzekrojKabla.mm2_10,
        PrzekrojKabla.mm2_16,
      ],
      dlaczego:
        'Obudowa metalowa baraku musi być wyrównana - miejsca gdzie mogą przebywać ludzie',
      punktPodlaczenia: 'Na krawędzi drzwiowej i na belkach nośnych (min. 2 punkty)',
      rekomendowanySposob: SposobPoczenia.srubaM10,
      wymagaSpawania: false,
      wymagaPrintosowania: false,
      specjalnePrzypisy:
        'Każdy barak: min. 2 niezależne połączenia. Odbiór przez inspektora po ustawieniu.',
      normy: ['PN-HD 60364-4-41'],
    ),

    // KONTENER
    ElementUziemienia(
      typ: BondingElementType.kontener,
      nazwa: 'Kontener budowlany',
      opis: 'Metalowy kontener do przechowywania materiałów/narzędzi',
      wymaganyPrzekrocj: '≥ 6 mm² Cu',
      dopuszczalnePrzekroje: [
        PrzekrojKabla.mm2_6,
        PrzekrojKabla.mm2_10,
      ],
      dlaczego:
        'Kontener metalowy musi być objęty połączeniami wyrównawczymi i uziemieniem ochronnym.',
      punktPodlaczenia: 'Na ramie kontenera lub na nodze konstrukcyjnej',
      rekomendowanySposob: SposobPoczenia.srubaM10,
      wymagaSpawania: false,
      wymagaPrintosowania: false,
      specjalnePrzypisy: 'Sprawdzać regularnie stan połączenia (korozja)',
      normy: ['PN-HD 60364-4-41'],
    ),
  ];

  /// Pobierz rekomendację dla elementu i prądu
  static RekomendacjaKabla? dajRekomendacje(
    BondingElementType element,
    PradNominalny prad,
  ) {
    // Logika doboru przekroju na podstawie typu i prądu
    PrzekrojKabla przekroj = PrzekrojKabla.mm2_6; // Domyślnie
    String uzasadnienie = '';

    // Prosta logika - wg norm
    switch (element) {
      case BondingElementType.przedzielnica:
        if (prad == PradNominalny.i160A || prad == PradNominalny.i200A) {
          przekroj = PrzekrojKabla.mm2_50;
          uzasadnienie = 'Rozdzielnica główna - dla dużego prądu wg tab. 54.1';
        } else if (prad == PradNominalny.i125A) {
          przekroj = PrzekrojKabla.mm2_35;
        } else {
          przekroj = PrzekrojKabla.mm2_25;
          uzasadnienie = 'Rozdzielnica wg PN-HD 60364-5-54';
        }
        break;

      case BondingElementType.ruWoda:
      case BondingElementType.ruGas:
        przekroj = PrzekrojKabla.mm2_6;
        uzasadnienie = 'Rury wg PN-HD 60364-4-41 tab. 54.2';
        break;

      case BondingElementType.rusztowanie:
        if (prad == PradNominalny.i125A ||
            prad == PradNominalny.i160A ||
            prad == PradNominalny.i200A) {
          przekroj = PrzekrojKabla.mm2_25;
        } else {
          przekroj = PrzekrojKabla.mm2_16;
        }
        uzasadnienie = 'Rusztowanie wg PN-ISO 12811';
        break;

      case BondingElementType.barak:
      case BondingElementType.kontener:
        przekroj = PrzekrojKabla.mm2_6;
        uzasadnienie = 'Tymczasowe konstrukcje wg PN-HD 60364-4-41';
        break;

      default:
        przekroj = PrzekrojKabla.mm2_6;
        uzasadnienie = 'Rekomendacja standardowa';
    }

    return RekomendacjaKabla(
      element: element,
      nazwaElementu: element.toString().split('.').last,
      przekroj: przekroj,
      przekrojMM: _konwertujPrzekroj(przekroj),
      zasilanieNa: [prad],
      rekomendowanySposob: SposobPoczenia.srubaM10,
      dlaczego: uzasadnienie,
      uwagi: 'Orientacyjnie - wymaga konsultacji projektanta',
      warunkiBudowy: ['Budowy tymczasowe', 'Budowy czasowe wg PWN'],
      norma: 'PN-HD 60364-5-54 / PN-EN 50164',
      disclaimer: 'ℹ️ ORIENTACYJNIE - Wymaga weryfikacji projektanta/inspektora elektryk!',
    );
  }

  static String _konwertujPrzekroj(PrzekrojKabla p) {
    switch (p) {
      case PrzekrojKabla.mm2_1_5:
        return '1.5 mm²';
      case PrzekrojKabla.mm2_2_5:
        return '2.5 mm²';
      case PrzekrojKabla.mm2_4:
        return '4 mm²';
      case PrzekrojKabla.mm2_6:
        return '6 mm²';
      case PrzekrojKabla.mm2_10:
        return '10 mm²';
      case PrzekrojKabla.mm2_16:
        return '16 mm²';
      case PrzekrojKabla.mm2_25:
        return '25 mm²';
      case PrzekrojKabla.mm2_35:
        return '35 mm²';
      case PrzekrojKabla.mm2_50:
        return '50 mm²';
      case PrzekrojKabla.mm2_70:
        return '70 mm²';
    }
  }
}
