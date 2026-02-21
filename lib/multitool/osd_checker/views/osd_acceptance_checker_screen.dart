import 'package:flutter/material.dart';

enum _OsdOperator { pge, tauron, energa, enea, stoen }

enum _TaskCategory { formal, technical, finalAcceptance }

enum _OsdTechnicalScope {
  nnDirectMetering,
  nnSemiIndirectWithMainSwitchboard,
  snStationAndMvSwitchgear,
}

class _ChecklistTask {
  const _ChecklistTask({
    required this.id,
    required this.title,
    required this.details,
    required this.category,
  });

  final String id;
  final String title;
  final String details;
  final _TaskCategory category;
}

class _OperatorChecklist {
  const _OperatorChecklist({
    required this.name,
    required this.area,
    required this.sources,
    required this.tasks,
  });

  final String name;
  final String area;
  final List<String> sources;
  final List<_ChecklistTask> tasks;
}

class _ProcessHelpRef {
  const _ProcessHelpRef({
    required this.label,
    required this.title,
    required this.details,
    required this.checklist,
  });

  final String label;
  final String title;
  final String details;
  final List<String> checklist;
}

class OSDAcceptanceCheckerScreen extends StatefulWidget {
  const OSDAcceptanceCheckerScreen({super.key});

  @override
  State<OSDAcceptanceCheckerScreen> createState() =>
      _OSDAcceptanceCheckerScreenState();
}

class _OSDAcceptanceCheckerScreenState extends State<OSDAcceptanceCheckerScreen> {
  static const Map<_OsdOperator, _OperatorChecklist> _checklists = {
    _OsdOperator.pge: _OperatorChecklist(
      name: 'PGE Dystrybucja',
      area: 'Wiele regionów kraju (OSD).',
      sources: [
        'https://pgedystrybucja.pl/przylaczenia',
        'https://pgedystrybucja.pl/przylaczenia/przylaczenia-online',
      ],
      tasks: [
        _ChecklistTask(
          id: 'pge_f1',
          title: 'Określ typ obiektu i moc przyłączeniową',
          details:
              'Dopasuj moc do realnego jednoczesnego obciążenia i charakteru obiektu. Błąd na tym etapie skutkuje korektą warunków i opóźnieniem odbioru.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'pge_f2',
          title: 'Złóż właściwy wniosek i komplet załączników',
          details:
              'Dobierz właściwy formularz (obiekt/zmiana parametrów/mikroinstalacja) i dołącz pełen zestaw dokumentów formalnych.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'pge_f3',
          title: 'Zweryfikuj warunki i podpisz umowę o przyłączenie',
          details:
              'Przed podpisem sprawdź punkt przyłączenia, granicę własności, harmonogram i obowiązki stron.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'pge_t1',
          title: 'Sprawdź układ pomiarowy i zabezpieczenie przedlicznikowe',
          details:
              'Potwierdź zgodność lokalizacji i typu układu pomiarowego oraz zabezpieczenia przedlicznikowego z warunkami przyłączenia.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'pge_t2',
          title: 'Zweryfikuj WLZ, przekroje i oznaczenia',
          details:
              'Skontroluj wykonanie WLZ, przekroje, tor PE/N oraz oznaczenia w rozdzielnicy zgodnie z dokumentacją i warunkami OSD.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'pge_t3',
          title: 'Skompletuj pomiary odbiorcze',
          details:
              'Przygotuj wymagane protokoły (m.in. izolacja, impedancja pętli zwarcia, ciągłość PE, RCD – jeżeli dotyczy).',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'pge_o1',
          title: 'Zgłoś gotowość instalacji i dostarcz dokumenty',
          details:
              'Przekaż oświadczenia i protokoły zgodnie z wymogami operatora oraz warunkami umowy.',
          category: _TaskCategory.finalAcceptance,
        ),
        _ChecklistTask(
          id: 'pge_o2',
          title: 'Dopnij umowę dystrybucji/kompleksową i termin załączenia',
          details:
              'Bez domkniętych formalności umownych uruchomienie przyłącza może zostać przesunięte.',
          category: _TaskCategory.finalAcceptance,
        ),
      ],
    ),
    _OsdOperator.tauron: _OperatorChecklist(
      name: 'TAURON Dystrybucja',
      area: 'Południowa i południowo-zachodnia Polska (OSD).',
      sources: [
        'https://www.tauron-dystrybucja.pl/przylaczenie-do-sieci/wniosek-online',
        'https://www.tauron-dystrybucja.pl/przylaczenie-do-sieci/formularze-online',
      ],
      tasks: [
        _ChecklistTask(
          id: 'tau_f1',
          title: 'Wybierz właściwą ścieżkę nN/SN',
          details:
              'TAURON rozdziela proces m.in. wg mocy (nN do 180 kW, SN powyżej 180 kW). Dobór ścieżki wpływa na komplet dokumentów.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'tau_f2',
          title: 'Złóż poprawny wniosek online',
          details:
              'Wskaż prawidłowy przypadek: nowe przyłączenie / zwiększenie mocy / przebudowa / rozdział / scalenie.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'tau_f3',
          title: 'Podpisz umowę odpowiednim kanałem',
          details:
              'Upewnij się, że forma podpisu i przekazania umowy odpowiada wymaganiom operatora.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'tau_t1',
          title: 'Sprawdź standard punktu pomiarowego',
          details:
              'Zweryfikuj zabudowę, dostęp serwisowy i zgodność lokalizacji punktu pomiarowego z warunkami przyłączenia.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'tau_t2',
          title: 'Skontroluj zabezpieczenia i selektywność',
          details:
              'Potwierdź poprawny dobór zabezpieczeń przedlicznikowych/zalicznikowych względem mocy i warunków.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'tau_t3',
          title: 'Przygotuj protokoły pomiarowe',
          details:
              'Dostarcz komplet pomiarów wymaganych do odbioru technicznego i załączenia napięcia.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'tau_o1',
          title: 'Rozlicz opłatę przyłączeniową',
          details:
              'Potwierdzenie opłaty jest zwykle warunkiem przejścia do kolejnych etapów realizacji.',
          category: _TaskCategory.finalAcceptance,
        ),
        _ChecklistTask(
          id: 'tau_o2',
          title: 'Domknij formalności i uruchomienie',
          details:
              'Przed terminem załączenia dopilnuj aktywnej umowy i kompletu dokumentów końcowych.',
          category: _TaskCategory.finalAcceptance,
        ),
      ],
    ),
    _OsdOperator.energa: _OperatorChecklist(
      name: 'Energa-Operator',
      area: 'Północna i północno-centralna Polska (OSD).',
      sources: [
        'https://energa-operator.pl/przylaczenie-do-sieci',
        'https://energa-operator.pl/dokumenty-i-formularze/przylaczenia-do-sieci',
      ],
      tasks: [
        _ChecklistTask(
          id: 'ene_f1',
          title: 'Wybierz właściwy tryb przyłączenia',
          details:
              'Rozróżnij: nowe przyłącze, zmiany na istniejącym przyłączu, mikroinstalacja lub przyłącze tymczasowe.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'ene_f2',
          title: 'Wypełnij komplet formularzy odbiorcy',
          details:
              'Uzupełnij dane inwestora i parametry techniczne bez niespójności między formularzem i załącznikami.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'ene_f3',
          title: 'Zweryfikuj warunki i podział obowiązków',
          details:
              'Przed rozpoczęciem robót potwierdź zakres prac po stronie inwestora i OSD.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'ene_t1',
          title: 'Sprawdź punkt i konfigurację pomiaru',
          details:
              'Upewnij się, że układ pomiarowy i jego lokalizacja są zgodne z wydanymi warunkami.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'ene_t2',
          title: 'Zweryfikuj WLZ i zabezpieczenia',
          details:
              'Skontroluj zgodność wykonania instalacji odbiorczej, doboru zabezpieczeń i ochrony przeciwporażeniowej.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'ene_t3',
          title: 'Skompletuj pomiary odbiorcze',
          details:
              'Przygotuj pełny pakiet protokołów pomiarowych wymaganych przez operatora i przepisy.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'ene_o1',
          title: 'Zgłoś gotowość i przekaż dokumenty końcowe',
          details:
              'Przed uruchomieniem przyłącza złóż oświadczenia i dokumentację odbiorową.',
          category: _TaskCategory.finalAcceptance,
        ),
        _ChecklistTask(
          id: 'ene_o2',
          title: 'Dopnij umowę i termin podania napięcia',
          details:
              'Brak finalnych formalności umownych może wstrzymać fizyczne uruchomienie przyłącza.',
          category: _TaskCategory.finalAcceptance,
        ),
      ],
    ),
    _OsdOperator.enea: _OperatorChecklist(
      name: 'Enea Operator',
      area: 'Zachodnia i północno-zachodnia Polska (OSD).',
      sources: [
        'https://www.operator.enea.pl/przylaczenie-do-sieci/procedura-krok-po-kroku-dla-domu',
        'https://www.operator.enea.pl/uslugi-dystrybucyjne/dla-domu/pliki-do-pobrania',
      ],
      tasks: [
        _ChecklistTask(
          id: 'ena_f1',
          title: 'Przygotuj dane do wniosku',
          details:
              'W Enea kluczowe są: dane identyfikacyjne, moc przyłączeniowa, planowany termin poboru i dane obiektu.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'ena_f2',
          title: 'Dołącz plan sytuacyjny i tytuł prawny',
          details:
              'To kluczowe załączniki wskazane w procedurze krok po kroku.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'ena_f3',
          title: 'Podpisz umowę o przyłączenie',
          details:
              'Po otrzymaniu warunków zaakceptuj umowę we właściwej formie i pilnuj terminów.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'ena_t1',
          title: 'Zweryfikuj punkt pomiarowy i WLZ',
          details:
              'Wykonanie musi być zgodne z warunkami przyłączenia oraz zakresem po stronie inwestora.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'ena_t2',
          title: 'Skontroluj zabezpieczenia i ochronę PE',
          details:
              'Przed odbiorem potwierdź skuteczność ochrony przeciwporażeniowej i zgodność konfiguracji zabezpieczeń.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'ena_t3',
          title: 'Skompletuj dokumentację pomiarową',
          details:
              'Przygotuj protokoły pomiarów z podpisami osób uprawnionych.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'ena_o1',
          title: 'Zgłoś gotowość instalacji',
          details:
              'W procedurze Enea zgłoszenie gotowości i komplet dokumentów warunkują finalny odbiór.',
          category: _TaskCategory.finalAcceptance,
        ),
        _ChecklistTask(
          id: 'ena_o2',
          title: 'Dopnij umowę dystrybucji/kompleksową',
          details:
              'Umowa musi być aktywna przed fizycznym uruchomieniem przyłącza.',
          category: _TaskCategory.finalAcceptance,
        ),
      ],
    ),
    _OsdOperator.stoen: _OperatorChecklist(
      name: 'Stoen Operator',
      area: 'm.st. Warszawa i obszar działania operatora.',
      sources: ['https://www.stoenoperator.pl/'],
      tasks: [
        _ChecklistTask(
          id: 'sto_f1',
          title: 'Potwierdź obszar działania operatora',
          details:
              'Najpierw zweryfikuj, czy punkt przyłączenia leży w obszarze obsługiwanym przez Stoen Operator.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'sto_f2',
          title: 'Wybierz poprawny typ procesu przyłączeniowego',
          details:
              'Określ czy to nowe przyłącze, zmiana mocy, przebudowa lub inna zmiana parametrów.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'sto_f3',
          title: 'Przygotuj komplet dokumentów formalnych',
          details:
              'Zbierz dane inwestora, tytuł prawny i dokumenty lokalizacyjne wymagane we wniosku.',
          category: _TaskCategory.formal,
        ),
        _ChecklistTask(
          id: 'sto_t1',
          title: 'Zweryfikuj punkt pomiarowy i szafkę',
          details:
              'Sprawdź przygotowanie i dostęp punktu pomiarowego zgodnie z warunkami przyłączenia.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'sto_t2',
          title: 'Skontroluj zabezpieczenia i ciągłość PE',
          details:
              'Potwierdź zgodność techniczną instalacji i skuteczność ochrony przeciwporażeniowej.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'sto_t3',
          title: 'Skompletuj pomiary odbiorcze',
          details:
              'Przed zgłoszeniem gotowości przygotuj protokoły i dokumentację odbiorową.',
          category: _TaskCategory.technical,
        ),
        _ChecklistTask(
          id: 'sto_o1',
          title: 'Zgłoś gotowość i dopełnij dokumenty końcowe',
          details:
              'Przekaż oświadczenia i dokumenty końcowe wynikające z warunków przyłączenia.',
          category: _TaskCategory.finalAcceptance,
        ),
        _ChecklistTask(
          id: 'sto_o2',
          title: 'Domknij umowę i uzgodnij uruchomienie',
          details:
              'Dopnij formalności umowne i termin montażu/uruchomienia przyłącza.',
          category: _TaskCategory.finalAcceptance,
        ),
      ],
    ),
  };

  static const Map<String, String> _criticalTipsByTaskId = {
    'pge_f1': 'Najczęstszy błąd: zaniżona moc przyłączeniowa względem realnych odbiorników. OSD odsyła do korekty lub wymaga zmiany warunków.',
    'pge_t1': 'Najczęściej uwalają za niezgodną lokalizację punktu pomiarowego i/lub niezgodną wartość zabezpieczenia przedlicznikowego.',
    'pge_t3': 'Braki podpisów/uprawnień na protokołach pomiarowych to częsty powód zatrzymania odbioru.',
    'tau_f2': 'Wniosek z błędną ścieżką procesu (np. rozdział/scalenie) najczęściej kończy się wezwaniem do korekty.',
    'tau_t1': 'Najczęstsza uwaga: brak zgodności zabudowy i dostępności układu pomiarowego z warunkami operatora.',
    'tau_t2': 'Uwaga krytyczna: rozjazd między mocą umowną, zabezpieczeniem i projektem rozdzielnicy.',
    'ene_f2': 'Niespójne dane między formularzem i załącznikami to klasyczny powód wydłużenia procesu.',
    'ene_t1': 'OSD często blokuje odbiór przez niezgodny punkt pomiarowy lub brak wymaganego dostępu eksploatacyjnego.',
    'ene_t3': 'Brak pełnego pakietu pomiarów (lub nieaktualne daty) bardzo często zatrzymuje finalny etap.',
    'ena_f2': 'Brak planu sytuacyjnego lub niejednoznaczny tytuł prawny to typowe powody wezwań do uzupełnień.',
    'ena_t1': 'Najczęstsza uwaga: rozbieżność pomiędzy warunkami a faktycznym wykonaniem WLZ i miejsca pomiaru.',
    'ena_t3': 'Uważaj na kompletność protokołów i zgodność danych obiektu we wszystkich dokumentach.',
    'sto_f1': 'Przed startem potwierdź obszar OSD — prowadzenie sprawy u niewłaściwego operatora blokuje cały proces.',
    'sto_t1': 'Największe ryzyko odbiorowe: niezgodność zabudowy punktu pomiarowego z wymaganiami warunków.',
    'sto_t3': 'Braki formalne w dokumentacji pomiarowej to częsta przyczyna przesunięcia uruchomienia.',
  };

  static const Map<String, List<String>> _technicalChecksByTaskId = {
    'pge_t1': [
      'Porównaj lokalizację układu pomiarowego 1:1 z warunkami przyłączenia i granicą eksploatacji.',
      'Zweryfikuj wartość i charakterystykę zabezpieczenia przedlicznikowego względem mocy przyłączeniowej.',
      'Sprawdź dostęp serwisowy, wysokość montażu, możliwość plombowania i czytelność oznaczeń.',
    ],
    'pge_t2': [
      'Potwierdź przekrój i materiał WLZ oraz zgodność z obliczonym prądem obciążenia i spadkiem napięcia.',
      'Skontroluj rozdział PEN/PE/N zgodnie z przyjętym układem sieci i dokumentacją wykonawczą.',
      'Zweryfikuj opisy torów i aparatów w rozdzielnicy oraz zgodność schematu powykonawczego z rzeczywistością.',
    ],
    'pge_t3': [
      'Pomiar rezystancji izolacji wykonaj dla wszystkich torów odbiorczych po właściwym przygotowaniu odbiorników.',
      'Zweryfikuj impedancję pętli zwarcia i warunek samoczynnego wyłączenia dla najdalszych punktów obwodów.',
      'Potwierdź ciągłość PE oraz czasy/prądy zadziałania RCD i wpisz wyniki do podpisanych protokołów.',
    ],
    'tau_t1': [
      'Sprawdź zgodność typu szafki i jej zabudowy z aktualnym standardem technicznym operatora.',
      'Upewnij się, że dojście i przestrzeń manewrowa spełniają wymagania bezpiecznej obsługi.',
      'Zweryfikuj przygotowanie miejsca pod licznik, aparaturę i elementy plombowane.',
    ],
    'tau_t2': [
      'Porównaj prądy znamionowe zabezpieczeń z mocą umowną i obciążalnością przewodów.',
      'Skontroluj selektywność zabezpieczeń przedlicznikowych i zalicznikowych na podstawie danych producenta.',
      'Potwierdź kompatybilność charakterystyk zabezpieczeń z typem odbiorów (silniki, LED, elektronika).',
    ],
    'tau_t3': [
      'Sporządź protokoły: izolacja, IPZ, ciągłość przewodów ochronnych, RCD oraz oględziny instalacji.',
      'Dopilnuj identyfikowalności obiektu na każdym protokole (adres, punkt poboru, data, osoba uprawniona).',
      'Zweryfikuj ważność świadectwa wzorcowania mierników użytych do pomiarów.',
    ],
    'ene_t1': [
      'Sprawdź lokalizację i konfigurację punktu pomiaru względem zapisów warunków przyłączenia.',
      'Potwierdź zgodność torów prądowych/napięciowych oraz przygotowanie pod wymagany licznik.',
      'Zweryfikuj dostęp techniczny OSD i spełnienie warunków eksploatacyjnych miejsca pomiaru.',
    ],
    'ene_t2': [
      'Skontroluj przekroje WLZ i przewodów ochronnych pod kątem obciążalności i ochrony przeciwporażeniowej.',
      'Zweryfikuj poprawność doboru aparatów nadprądowych i różnicowoprądowych do charakteru obwodów.',
      'Sprawdź połączenia wyrównawcze główne/miejscowe oraz ciągłość przewodów ochronnych.',
    ],
    'ene_t3': [
      'Wykonaj komplet pomiarów odbiorczych wg obowiązujących norm i dokumentacji projektowej.',
      'Porównaj wyniki pomiarów z dopuszczalnymi wartościami i zaznacz ewentualne niezgodności.',
      'Zamknij pakiet dokumentacji: protokoły, oświadczenia, schemat powykonawczy, lista zastosowanych zabezpieczeń.',
    ],
    'ena_t1': [
      'Potwierdź zgodność miejsca pomiaru oraz trasy WLZ z zatwierdzonym rozwiązaniem przyłączeniowym.',
      'Sprawdź zabezpieczenie mechaniczne WLZ i sposób prowadzenia przewodów przez strefy instalacyjne.',
      'Zweryfikuj wymagane oznaczenia i opis rozdzielnicy głównej oraz punktu granicznego stron.',
    ],
    'ena_t2': [
      'Skontroluj skuteczność ochrony przez samoczynne wyłączenie zasilania dla obwodów końcowych.',
      'Sprawdź poprawność podziału PEN oraz brak niedozwolonych mostków PE-N za punktem rozdziału.',
      'Zweryfikuj koordynację zabezpieczeń z obciążalnością długotrwałą przewodów i warunkami zwarciowymi.',
    ],
    'ena_t3': [
      'Dopilnuj, aby protokoły zawierały komplet danych: metoda, miernik, wynik, kryterium oceny.',
      'Sprawdź spójność nazw obwodów i aparatów między protokołami a rzeczywistymi opisami w rozdzielni.',
      'Upewnij się, że dokumenty są podpisane przez osobę z odpowiednimi uprawnieniami i datowane.',
    ],
    'sto_t1': [
      'Zweryfikuj wykonanie szafki pomiarowej pod kątem standardu operatora i warunków przyłączenia.',
      'Sprawdź możliwość bezpiecznego odczytu/licznikowania oraz wymagane strefy dostępu serwisowego.',
      'Potwierdź gotowość elementów do plombowania i komplet osprzętu pomiarowego.',
    ],
    'sto_t2': [
      'Sprawdź ciągłość PE i połączenia wyrównawcze, szczególnie dla metalowych elementów instalacji.',
      'Zweryfikuj parametry zabezpieczeń nadprądowych i różnicowoprądowych względem obciążeń projektowych.',
      'Potwierdź spełnienie warunku ochrony przeciwporażeniowej na podstawie wyników pomiarów.',
    ],
    'sto_t3': [
      'Przygotuj pakiet protokołów pomiarowych z jednoznaczną identyfikacją obiektu i punktu poboru.',
      'Dołącz wyniki oględzin oraz listę stwierdzonych i usuniętych niezgodności przed odbiorem.',
      'Zweryfikuj kompletność formalną: podpisy, daty, numery uprawnień i aktualność dokumentów.',
    ],
  };

  static const Map<_OsdTechnicalScope, List<String>> _minimumMeasurementsByScope = {
    _OsdTechnicalScope.nnDirectMetering: [
      'Układ pomiarowy nN bezpośredni: potwierdź zgodność typu/licznika, miejsca zabudowy i możliwości plombowania z warunkami OSD.',
      'Złącze kablowe (ZK): sprawdź wykonanie torów, oznaczenia, zgodność przekrojów i układu sieci (TN-C/TN-S/TN-C-S) z dokumentacją.',
      'Zabezpieczenie przedlicznikowe: zweryfikuj typ, wartość i charakterystykę zgodnie z mocą przyłączeniową i warunkami.',
      'RG (rozdzielnica główna): potwierdź poprawność rozdziału PEN/PE/N, opisy pól i selektywność stopni zabezpieczeń.',
      'Pomiary odbiorcze nN: izolacja, ciągłość PE, impedancja pętli zwarcia oraz warunek samoczynnego wyłączenia zasilania.',
      'Dokumenty: komplet protokołów + oświadczenie o gotowości instalacji zgodne z identyfikacją punktu poboru.',
    ],
    _OsdTechnicalScope.nnSemiIndirectWithMainSwitchboard: [
      'Układ półpośredni nN: zgodność przekładników prądowych (klasa, przekładnia, moc) i kierunkowości torów pomiarowych.',
      'Obwody wtórne przekładników: kontrola zacisków, zwarć serwisowych, oznaczeń i zabezpieczenia przed nieuprawnionym dostępem.',
      'Rozdzielnica główna nN: weryfikacja szyn, aparatury głównej, selektywności i nastaw zabezpieczeń względem warunków OSD.',
      'Złącze / pole zasilające: potwierdź zgodność wykonania z dokumentacją powykonawczą i granicą własności stron.',
      'Pomiary techniczne: izolacja, ciągłość PE, IPZ oraz weryfikacja ochrony przeciwporażeniowej dla torów zasilających.',
      'Pakiet odbiorowy: protokoły pomiarowe, schemat jednokreskowy powykonawczy, zestawienie aparatów i nastaw.',
    ],
    _OsdTechnicalScope.snStationAndMvSwitchgear: [
      'Stacja SN/nN: potwierdź zgodność wyposażenia pól SN, transformatora i rozdzielni nN z dokumentacją i uzgodnieniami OSD.',
      'Rozdzielnica SN: kontrola blokad mechanicznych/elektrycznych, stanu uziemników i możliwości bezpiecznych manewrów.',
      'Ochrona i automatyka: sprawdź spójność nastaw zabezpieczeń z warunkami przyłączenia oraz koordynacją po stronie OSD.',
      'Układ pomiarowy (SN lub nN wg warunków): zgodność torów napięciowych/prądowych, oznaczeń i punktów plombowania.',
      'Uziemienie stacji: pomiary i protokoły rezystancji uziemienia oraz ciągłości połączeń ochronnych i wyrównawczych.',
      'Dokumentacja odbiorowa stacji: protokoły prób i pomiarów, schematy powykonawcze, karty urządzeń i instrukcje eksploatacji.',
    ],
  };

  static const Map<_OsdTechnicalScope, List<String>> _requiredDocumentsByScope = {
    _OsdTechnicalScope.nnDirectMetering: [
      'Warunki przyłączenia + potwierdzenie realizacji zakresu po stronie inwestora.',
      'Oświadczenie o gotowości instalacji do przyłączenia (zgodne z wymaganym formularzem OSD).',
      'Protokoły pomiarowe instalacji odbiorczej (izolacja, IPZ, ciągłość PE, RCD jeżeli występuje).',
      'Schemat jednokreskowy powykonawczy RG i zasilania od punktu granicznego.',
      'Zestawienie aparatów i zabezpieczeń (typy, prądy znamionowe, charakterystyki).',
    ],
    _OsdTechnicalScope.nnSemiIndirectWithMainSwitchboard: [
      'Pełny schemat pomiaru półpośredniego z oznaczeniem torów prądowych i napięciowych.',
      'Dane przekładników prądowych: przekładnia, klasa dokładności, moc znamionowa, współczynnik bezpieczeństwa.',
      'Protokół sprawdzenia kierunku/przypisania faz i zacisków obwodów wtórnych przekładników.',
      'Protokoły pomiarowe i oświadczenie o gotowości instalacji do przyłączenia.',
      'Dokumentacja powykonawcza RG z aktualnymi nastawami zabezpieczeń i selektywnością.',
    ],
    _OsdTechnicalScope.snStationAndMvSwitchgear: [
      'Schematy jednokreskowe SN/nN oraz dokumentacja powykonawcza stacji i pól rozdzielczych.',
      'Karty nastaw zabezpieczeń i automatyki z potwierdzeniem uzgodnienia z wymaganiami OSD.',
      'Dokumentacja układu pomiarowego SN/nN (CT/VT: przekładnie, klasy, moce, konfiguracja obwodów wtórnych).',
      'Protokoły prób i pomiarów stacji: uziemienie, ciągłość połączeń ochronnych, próby funkcjonalne i manewrowe.',
      'Instrukcja eksploatacji, wykaz urządzeń, protokół odbioru i komplet oświadczeń do załączenia.',
    ],
  };

  static const Map<_OsdTechnicalScope, List<String>> _criticalParametersByScope = {
    _OsdTechnicalScope.nnDirectMetering: [
      'Zgodność zabezpieczenia przedlicznikowego z mocą przyłączeniową i warunkami.',
      'Spójność przekrojów WLZ i torów zasilania z obciążalnością długotrwałą i warunkami zwarciowymi.',
      'Warunek samoczynnego wyłączenia zasilania potwierdzony pomiarami IPZ.',
    ],
    _OsdTechnicalScope.nnSemiIndirectWithMainSwitchboard: [
      'Przekładniki prądowe: właściwa przekładnia oraz klasa dokładności adekwatna do układu pomiarowego.',
      'Zgodność obciążenia obwodów wtórnych z mocą znamionową przekładników (bez przeciążania rdzenia pomiarowego).',
      'Poprawna biegunowość, kolejność faz i numeracja zacisków CT w całym torze pomiarowym.',
      'Koordynacja nastaw zabezpieczeń RG z zabezpieczeniem przedlicznikowym i wymaganiami OSD.',
    ],
    _OsdTechnicalScope.snStationAndMvSwitchgear: [
      'Parametry CT/VT zgodne z funkcją (pomiar/ochrona), wymaganymi klasami i konfiguracją stacji.',
      'Nastawy zabezpieczeń SN (czasowo-prądowe, ziemnozwarciowe itp.) zgodne z uzgodnioną filozofią pracy sieci.',
      'Rezystancja uziemienia i ciągłość połączeń ochronnych stacji potwierdzone protokołami.',
      'Sprawdzone blokady i logika manewrowa rozdzielnicy SN w scenariuszach eksploatacyjnych.',
    ],
  };

  static const List<String> _formalGateChecklist = [
    'Spójność danych inwestora/obiektu we wszystkich dokumentach (wniosek, warunki, oświadczenia, protokoły).',
    'Zgodność parametrów przyłącza z warunkami: moc, grupa przyłączeniowa, miejsce pomiaru, granica własności.',
    'Komplet podpisów/uprawnień i dat na protokołach oraz oświadczeniach (bez braków formalnych).',
    'Aktualny schemat powykonawczy i zestawienie aparatów zgodne z rzeczywistym wykonaniem.',
    'Domknięte formalności umowne i gotowość do uruchomienia wg procedury właściwego OSD.',
  ];

  static const List<String> _technicalGateChecklist = [
    'Skuteczność ochrony przeciwporażeniowej potwierdzona pomiarami (SWZ/IPZ/PE/RCD wg zakresu).',
    'Zgodność wykonania punktu pomiarowego, ZK/RG/stacji z warunkami przyłączenia i standardem OSD.',
    'Koordynacja i selektywność zabezpieczeń oraz zgodność nastaw z dokumentacją i obliczeniami.',
    'Dla układów przekładnikowych: przekładnie, klasy, obciążenie wtórne, biegunowość i fazowanie torów.',
    'Pełna identyfikowalność pomiarów: obiekt, punkt poboru, przyrządy, metody i kryteria oceny.',
  ];

  static const Map<_OsdOperator, List<String>> _operatorFormalHotspots = {
    _OsdOperator.pge: [
      'Najczęściej blokuje: rozjazd mocy przyłączeniowej z rzeczywistymi odbiorami i dokumentacją.',
      'Krytyczne: zgodność lokalizacji punktu pomiarowego i zabezpieczenia przedlicznikowego z warunkami.',
    ],
    _OsdOperator.tauron: [
      'Krytyczny wybór właściwej ścieżki procesu (nowe przyłącze / zmiana / podział / scalenie).',
      'Braki formalne we wniosku online często kończą się wezwaniem do korekty i wydłużeniem terminu.',
    ],
    _OsdOperator.energa: [
      'Wysokie ryzyko: niespójność danych między formularzem i załącznikami technicznymi.',
      'Przed zgłoszeniem gotowości wymagany pełny, aktualny pakiet dokumentów odbiorowych.',
    ],
    _OsdOperator.enea: [
      'Częsty problem: niejednoznaczny tytuł prawny lub niepełny plan sytuacyjny.',
      'Krytyczne: zgodność WLZ i punktu pomiarowego z zakresem z warunków przyłączenia.',
    ],
    _OsdOperator.stoen: [
      'Pierwsza kontrola formalna: poprawny obszar działania operatora dla punktu przyłączenia.',
      'Najczęstsze opóźnienie: braki formalne w dokumentacji końcowej i protokołach pomiarowych.',
    ],
  };

  static const Map<_OsdOperator, List<String>> _operatorTechnicalHotspots = {
    _OsdOperator.pge: [
      'Weryfikuj wykonanie punktu pomiarowego i plombowalność elementów zgodnie z warunkami.',
      'Dopilnuj poprawnego rozdziału PEN/PE/N oraz identyfikowalności torów w RG.',
    ],
    _OsdOperator.tauron: [
      'Krytyczne są standard zabudowy i dostęp serwisowy układu pomiarowego.',
      'Sprawdź selektywność zabezpieczeń względem mocy i charakteru obciążeń.',
    ],
    _OsdOperator.energa: [
      'Częste uwagi dotyczą konfiguracji punktu pomiarowego i dostępu eksploatacyjnego.',
      'Przed odbiorem potwierdź komplet pomiarów i zgodność wyników z kryteriami normowymi.',
    ],
    _OsdOperator.enea: [
      'Krytyczne: zgodność wykonania WLZ, miejsca pomiaru i opisów pól rozdzielnicy.',
      'Dopilnuj formalno-technicznej spójności protokołów i danych obiektu.',
    ],
    _OsdOperator.stoen: [
      'Najwyższe ryzyko: niezgodny standard szafki/punktu pomiarowego względem warunków.',
      'Przed zgłoszeniem gotowości zweryfikuj pakiet protokołów i kompletność danych technicznych.',
    ],
  };

  static const List<String> _processTimeline = [
    '1) Wniosek i załączniki: składasz komplet formalno-techniczny zgodny z przypadkiem (nowe przyłącze / zmiana mocy / przebudowa / mikroinstalacja).',
    '2) Weryfikacja formalna przez OSD: operator sprawdza kompletność i zgodność danych; przy brakach wysyła wezwanie do uzupełnień.',
    '3) Warunki przyłączenia: po pozytywnej weryfikacji otrzymujesz warunki, zakres prac stron i parametry techniczne przyłącza.',
    '4) Umowa o przyłączenie: podpisujesz umowę i realizujesz warunki po stronie inwestora (układ pomiarowy, ZK/RG/stacja, WLZ, dokumenty).',
    '5) Gotowość do odbioru: wykonujesz pomiary, kompletujesz protokoły i składasz zgłoszenie gotowości instalacji.',
    '6) Odbiór i uruchomienie: OSD weryfikuje dokumenty/stan techniczny, montuje lub aktywuje układ pomiarowy i podaje napięcie po domknięciu formalności.',
  ];

  static const List<String> _requiredSubmissionDocuments = [
    'Wniosek właściwy dla procesu (typ przyłącza/zmiany parametrów).',
    'Dokument potwierdzający tytuł prawny do obiektu lub nieruchomości (jeżeli wymagany).',
    'Plan sytuacyjny / lokalizacyjny oraz dane punktu poboru.',
    'Parametry techniczne: moc, przewidywany charakter obciążenia, docelowy układ pomiarowy.',
    'Na etapie gotowości: oświadczenie instalatora, protokoły pomiarowe, schemat powykonawczy i zestawienie aparatów.',
  ];

  static const List<String> _timelineGuidance = [
    'Czas OSD zależy od grupy przyłączeniowej, mocy, napięcia i kompletności dokumentów.',
    'W praktyce najwięcej opóźnień powodują uzupełnienia formalne i niespójności dokumentacji.',
    'Terminy graniczne i harmonogram zawsze bierz z aktualnych warunków przyłączenia i umowy (to dokument nadrzędny).',
    'Termin wizji/odbioru zwykle jest ustalany po skutecznym zgłoszeniu gotowości i pozytywnej weryfikacji dokumentów.',
  ];

  static const List<String> _acceptanceDayChecklist = [
    'Komplet oryginałów/protokołów podpisanych przez osobę z właściwymi uprawnieniami.',
    'Dostęp do punktu pomiarowego, ZK, RG lub stacji SN, zapewnione warunki bezpiecznej obsługi.',
    'Czytelne oznaczenia obwodów, aparatów i punktów granicznych stron.',
    'Potwierdzenie zgodności wykonania z warunkami oraz dokumentacją powykonawczą.',
    'Osoba techniczna na miejscu zdolna udzielić wyjaśnień dot. nastaw, pomiarów i rozwiązań wykonawczych.',
  ];

  static const List<String> _refusalOrHoldReasons = [
    'Braki formalne: niekompletne dokumenty, brak podpisów, niespójne dane obiektu/inwestora.',
    'Niezgodność techniczna z warunkami: inna lokalizacja punktu pomiarowego, inne zabezpieczenie, inny zakres wykonania.',
    'Nieprawidłowe lub niepełne protokoły pomiarowe, brak identyfikowalności wyników.',
    'Niespełnienie wymagań bezpieczeństwa eksploatacji (dostęp, plombowanie, ochrona przeciwporażeniowa).',
  ];

  static const List<String> _whenOsdDoesNotAccept = [
    'Poproś o pisemny wykaz niezgodności (punkt po punkcie) i podstawę wymagań.',
    'Usuń niezgodności techniczne/formalne i zaktualizuj dokumenty powykonawcze.',
    'Wykonaj ponowne pomiary w zakresie zmian i przygotuj uzupełnione protokoły.',
    'Zgłoś ponowną gotowość odbiorową zgodnie z procedurą operatora i zachowaj potwierdzenia zgłoszeń.',
  ];

  static const List<String> _reacceptanceRules = [
    'Liczba ponownych zgłoszeń wynika z procedury OSD i postanowień umowy — praktycznie zgłaszasz do skutecznego usunięcia niezgodności.',
    'Terminy ponownego odbioru nie są uniwersalne — operator wyznacza je po przyjęciu kompletnego ponownego zgłoszenia.',
    'Przy każdym kolejnym zgłoszeniu dołącz pełny pakiet aktualnych dokumentów, nie tylko „delta changes”.',
  ];

  static const List<String> _potentialCosts = [
    'Opłata przyłączeniowa wynikająca z umowy o przyłączenie.',
    'Koszty wykonawcze po stronie inwestora (ZK/RG/stacja, WLZ, aparatura, pomiary, dokumentacja).',
    'Koszty poprawek i ponownych pomiarów po stwierdzeniu niezgodności.',
    'W niektórych przypadkach możliwe opłaty związane z dodatkowymi czynnościami operatora — sprawdź taryfę OSD i umowę.',
  ];

  static const List<_ProcessHelpRef> _processHelpRefs = [
    _ProcessHelpRef(
      label: 'Pomoc: wniosek',
      title: 'Pomoc do etapu: wniosek i załączniki',
      details:
          'Skup się na spójności danych formalnych i technicznych. Najczęściej odrzucenia wynikają z braków załączników lub rozjazdu parametrów przyłącza.',
      checklist: [
        'Zweryfikuj dane inwestora, adres obiektu i tytuł prawny.',
        'Upewnij się, że moc i parametry techniczne są zgodne w całym pakiecie.',
        'Dołącz wymagane mapy/plany/schematy zgodnie z formularzem OSD.',
      ],
    ),
    _ProcessHelpRef(
      label: 'Pomoc: warunki',
      title: 'Pomoc do etapu: analiza warunków i umowy',
      details:
          'Po otrzymaniu warunków priorytetem jest identyfikacja krytycznych parametrów technicznych i granicy obowiązków stron.',
      checklist: [
        'Sprawdź punkt pomiarowy, granicę własności i wymagany układ pomiarowy.',
        'Potwierdź zabezpieczenia przedlicznikowe i wymagania wykonawcze OSD.',
        'Zmapuj zakres prac inwestora i terminy umowne przed startem robót.',
      ],
    ),
    _ProcessHelpRef(
      label: 'Pomoc: gotowość',
      title: 'Pomoc do etapu: zgłoszenie gotowości',
      details:
          'Na tym etapie musisz zamknąć pełny pakiet formalny i pomiarowy. Brak jednego elementu często blokuje termin odbioru.',
      checklist: [
        'Skompletuj protokoły pomiarowe i oświadczenie gotowości.',
        'Zweryfikuj zgodność schematu powykonawczego z wykonaniem na obiekcie.',
        'Sprawdź podpisy, daty, uprawnienia i identyfikację punktu poboru.',
      ],
    ),
    _ProcessHelpRef(
      label: 'Pomoc: odbiór',
      title: 'Pomoc do etapu: odbiór OSD na obiekcie',
      details:
          'Odbiór to jednoczesna kontrola techniczna i formalna. Musisz mieć przygotowany obiekt oraz osobę zdolną technicznie wyjaśnić przyjęte rozwiązania.',
      checklist: [
        'Zapewnij dostęp do punktu pomiarowego, ZK, RG lub stacji.',
        'Przygotuj kompletny pakiet dokumentów i protokołów w jednej teczce.',
        'Zweryfikuj czytelność opisów i oznaczeń aparatów/obwodów.',
      ],
    ),
    _ProcessHelpRef(
      label: 'Pomoc: odmowa',
      title: 'Pomoc do etapu: odmowa / ponowny odbiór',
      details:
          'Po odmowie kluczowe jest formalne domknięcie niezgodności punkt po punkcie i ponowne zgłoszenie z pełnym, zaktualizowanym pakietem dokumentów.',
      checklist: [
        'Uzyskaj pisemny wykaz niezgodności i podstawę wymagań.',
        'Wprowadź poprawki techniczne i odśwież dokumentację oraz protokoły.',
        'Zgłoś ponowną gotowość i zachowaj potwierdzenie złożenia dokumentów.',
      ],
    ),
  ];

  _OsdOperator _selectedOperator = _OsdOperator.pge;
  _TaskCategory? _selectedCategory;
  _OsdTechnicalScope _selectedScope =
      _OsdTechnicalScope.nnSemiIndirectWithMainSwitchboard;
  final Map<_OsdOperator, Set<String>> _completedByOperator = {};
  final Map<_OsdOperator, Map<String, String>> _evidenceByOperator = {};

  Set<String> get _completedTasks {
    return _completedByOperator.putIfAbsent(_selectedOperator, () => <String>{});
  }

  Map<String, String> get _evidenceMap {
    return _evidenceByOperator.putIfAbsent(_selectedOperator, () => <String, String>{});
  }

  void _toggleTask(String id, bool selected) {
    setState(() {
      if (selected) {
        _completedTasks.add(id);
      } else {
        _completedTasks.remove(id);
      }
    });
  }

  String _categoryLabel(_TaskCategory category) {
    switch (category) {
      case _TaskCategory.formal:
        return 'Formalne';
      case _TaskCategory.technical:
        return 'Techniczne';
      case _TaskCategory.finalAcceptance:
        return 'Odbiór końcowy';
    }
  }

  IconData _categoryIcon(_TaskCategory category) {
    switch (category) {
      case _TaskCategory.formal:
        return Icons.assignment;
      case _TaskCategory.technical:
        return Icons.electrical_services;
      case _TaskCategory.finalAcceptance:
        return Icons.task_alt;
    }
  }

  String _scopeLabel(_OsdTechnicalScope scope) {
    switch (scope) {
      case _OsdTechnicalScope.nnDirectMetering:
        return 'nN — układ pomiarowy bezpośredni';
      case _OsdTechnicalScope.nnSemiIndirectWithMainSwitchboard:
        return 'nN — półpośredni + RG';
      case _OsdTechnicalScope.snStationAndMvSwitchgear:
        return 'Stacja SN / rozdzielnica SN';
    }
  }

  String? _taskTip(_ChecklistTask task) => _criticalTipsByTaskId[task.id];

  List<String>? _taskTechnicalChecks(_ChecklistTask task) =>
      _technicalChecksByTaskId[task.id];

  bool _hasTip(_ChecklistTask task) => _taskTip(task) != null;

  bool _hasTechnicalChecks(_ChecklistTask task) =>
      _taskTechnicalChecks(task)?.isNotEmpty ?? false;

  Future<void> _openEvidenceEditor(_ChecklistTask task) async {
    final controller = TextEditingController(text: _evidenceMap[task.id] ?? '');
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: Text('Uwagi: ${task.title}'),
          content: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Np. numer protokołu, data, wykonawca, status / komentarz',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _evidenceMap.remove(task.id);
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Wyczyść'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () {
                final value = controller.text.trim();
                setState(() {
                  if (value.isEmpty) {
                    _evidenceMap.remove(task.id);
                  } else {
                    _evidenceMap[task.id] = value;
                  }
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  void _openProcessHelp(_ProcessHelpRef helpRef) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: Text(helpRef.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(helpRef.details),
                const SizedBox(height: 10),
                Text(
                  'Checklista pomocnicza',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final item in helpRef.checklist)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $item'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _openTaskDetails(_ChecklistTask task) {
    final tip = _taskTip(task);
    final technicalChecks = _taskTechnicalChecks(task);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(task.title),
              const SizedBox(height: 6),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(_categoryIcon(task.category), size: 16),
                label: Text(_categoryLabel(task.category)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(task.details),
                if (technicalChecks != null && technicalChecks.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Checklista techniczna',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final check in technicalChecks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $check'),
                    ),
                ],
                if (tip != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'TIP: $tip',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _openEvidenceEditor(task);
              },
              icon: const Icon(Icons.note_alt_outlined),
              label: const Text('Uwagi'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final checklist = _checklists[_selectedOperator]!;
    final allTasks = checklist.tasks;
    final visibleTasks = _selectedCategory == null
        ? allTasks
        : allTasks.where((task) => task.category == _selectedCategory).toList();

    final completedCount =
        allTasks.where((task) => _completedTasks.contains(task.id)).length;
    final evidenceCount =
        _evidenceMap.values.where((value) => value.trim().isNotEmpty).length;
    final progress = allTasks.isEmpty ? 0.0 : completedCount / allTasks.length;
    final minimumMeasurements =
      _minimumMeasurementsByScope[_selectedScope] ?? const <String>[];
    final requiredDocuments =
      _requiredDocumentsByScope[_selectedScope] ?? const <String>[];
    final criticalParameters =
      _criticalParametersByScope[_selectedScope] ?? const <String>[];
    final operatorFormalHotspots =
      _operatorFormalHotspots[_selectedOperator] ?? const <String>[];
    final operatorTechnicalHotspots =
      _operatorTechnicalHotspots[_selectedOperator] ?? const <String>[];

    final tasksByCategory = <_TaskCategory, List<_ChecklistTask>>{};
    for (final task in visibleTasks) {
      tasksByCategory.putIfAbsent(task.category, () => <_ChecklistTask>[]);
      tasksByCategory[task.category]!.add(task);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Przygotowanie do odbiorów OSD')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wybierz operatora OSD dla budowy i przejdź checklistę formalną, techniczną oraz odbiorową.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chronologia procesu OSD (praktycznie)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    for (final step in _processTimeline)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(step),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Dokumenty do złożenia',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _requiredSubmissionDocuments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Czas i terminy (orientacyjnie)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _timelineGuidance)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Jak wygląda odbiór i co przygotować',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _acceptanceDayChecklist)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Kiedy OSD może odmówić / wstrzymać odbiór',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _refusalOrHoldReasons)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Gdy OSD nie odbiera / odmawia',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _whenOsdDoesNotAccept)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Ponowny odbiór / ponowne zgłoszenia',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _reacceptanceRules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Koszty — co zwykle występuje',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _potentialCosts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Odnośniki do pomocy (kontekstowo)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final helpRef in _processHelpRefs)
                          ActionChip(
                            avatar: const Icon(Icons.help_outline, size: 16),
                            label: Text(helpRef.label),
                            onPressed: () => _openProcessHelp(helpRef),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.gavel_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disclaimer: moduł ma charakter informacyjny i pomocniczy. Nie stanowi oficjalnej interpretacji wymagań OSD ani porady prawnej. Wiążące są aktualne warunki przyłączenia, formularze operatora, umowa oraz obowiązujące przepisy i normy.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_OsdOperator>(
              initialValue: _selectedOperator,
              decoration: const InputDecoration(
                labelText: 'Operator OSD',
                border: OutlineInputBorder(),
              ),
              items: _checklists.entries
                  .map(
                    (entry) => DropdownMenuItem<_OsdOperator>(
                      value: entry.key,
                      child: Text(entry.value.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedOperator = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Wszystkie'),
                  selected: _selectedCategory == null,
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                for (final category in _TaskCategory.values)
                  ChoiceChip(
                    label: Text(_categoryLabel(category)),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(checklist.name, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(checklist.area, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text('Postęp: $completedCount/${allTasks.length}'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      'Uwagi: $evidenceCount/${allTasks.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _completedTasks.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _completedTasks.clear();
                                  });
                                },
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Wyczyść odhaczenia'),
                        ),
                        TextButton.icon(
                          onPressed: _evidenceMap.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _evidenceMap.clear();
                                  });
                                },
                          icon: const Icon(Icons.note_alt_outlined),
                          label: const Text('Wyczyść uwagi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brama formalna i techniczna (must-pass)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aspekty formalne — kontrola krzyżowa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _formalGateChecklist)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Aspekty techniczne — kryteria odbiorowe',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final item in _technicalGateChecklist)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Punkty krytyczne dla ${checklist.name}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Formalne:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final item in operatorFormalHotspots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Techniczne:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final item in operatorTechnicalHotspots)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $item'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minimum pomiarowe przed odbiorem',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Wybierz zakres techniczny przyłącza/obiektu, aby przejść minimalny pakiet kontroli wymagany na etapie odbioru OSD.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final scope in _OsdTechnicalScope.values)
                          ChoiceChip(
                            label: Text(_scopeLabel(scope)),
                            selected: _selectedScope == scope,
                            onSelected: (_) {
                              setState(() {
                                _selectedScope = scope;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final measurement in minimumMeasurements)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $measurement'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wymagane dokumenty i parametry krytyczne',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pakiet dokumentów do odbioru',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final document in requiredDocuments)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $document'),
                      ),
                    const SizedBox(height: 10),
                    Text(
                      'Parametry krytyczne do weryfikacji',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (final parameter in criticalParameters)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $parameter'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    for (final category in _TaskCategory.values)
                      if (tasksByCategory.containsKey(category)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                          child: Row(
                            children: [
                              Icon(_categoryIcon(category), size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _categoryLabel(category),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                        for (final task in tasksByCategory[category]!)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            leading: Checkbox(
                              value: _completedTasks.contains(task.id),
                              onChanged: (value) => _toggleTask(task.id, value ?? false),
                            ),
                            title: Text(task.title),
                            subtitle: Text(
                              _evidenceMap.containsKey(task.id)
                                  ? ((_hasTip(task) || _hasTechnicalChecks(task))
                                    ? 'Objaśnienie + checklista/TIP + uwagi uzupełnione'
                                        : 'Objaśnienie + uwagi uzupełnione')
                                  : ((_hasTip(task) || _hasTechnicalChecks(task))
                                    ? 'Naciśnij, aby zobaczyć objaśnienie i checklistę/TIP'
                                        : 'Naciśnij, aby zobaczyć objaśnienie'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_hasTip(task))
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 18,
                                  ),
                                if (_hasTip(task)) const SizedBox(width: 4),
                                IconButton(
                                  onPressed: () => _openEvidenceEditor(task),
                                  icon: Icon(
                                    _evidenceMap.containsKey(task.id)
                                        ? Icons.note_alt
                                        : Icons.note_alt_outlined,
                                  ),
                                ),
                                const Icon(Icons.open_in_new),
                              ],
                            ),
                            onTap: () => _openTaskDetails(task),
                          ),
                      ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Źródła operatora', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    for (final source in checklist.sources)
                      SelectableText(source, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Text(
                      'Stan merytoryczny: luty 2026, na podstawie publicznych materiałów OSD. Wymagania techniczne zawsze potwierdź z aktualnymi warunkami przyłączenia dla konkretnego punktu.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
