/// DOKUMENTACJA: Integracja harmonogramu budowy budynków
/// 
/// Źródło: Dokument "Uzupełniony i kompletny etap dla budowy budynku mieszkalnego 
/// wielorodzinnego i budynku biurowego"
/// 
/// 📋 PRZEGLĄD SYSTEMU
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// System automatycznie dostosowuje harmonogram projektu budowlanego na podstawie:
/// 1. Liczby pięter nadziemnych
/// 2. Liczby poziomów garaży podziemnych  
/// 3. Typu budynku (mieszkalny/biurowy)
/// 4. Wybranych systemów elektrycznych
/// 
/// 📊 DANE BAZOWE DLA BUDYNKÓW MIESZKALNYCH
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Referencja z dokumentu: Budynek 5–8 kondygnacyjny + 1 garaż podziemny
/// Całkowity czas: 18–24 miesiące (78-104 tygodnie)
/// 
/// Proporcje etapów:
/// ┌─────────────────────────────┬──────────────┬──────────────┐
/// │ Etap                        │ Czas         │ % całkowitego │
/// ├─────────────────────────────┼──────────────┼──────────────┤
/// │ 1. Przygotowanie            │ 2–4 mies.    │ 10–15%       │
/// │ 2. Roboty ziemne i fundament│ 3–5 mies.    │ 15–20%       │
/// │ 3. Konstrukcja nadziemna    │ 5–8 mies.    │ 25–35%  ★    │
/// │ 4. Stan surowy zamknięty    │ 3–5 mies.    │ 15–20%       │
/// │ 5. Tynki                    │ 3–4 mies.    │ 15–20%       │
/// │ 6. Posadzki                 │ 2–3 mies.    │ 10–15%       │
/// │ 7. Osprzęt elektryczny      │ 2–3 mies.    │ 10–15%       │
/// │ 8. Malowanie i lakierowanie │ 2–3 mies.    │ 10–15%       │
/// │ 9. Finalizacja              │ 2–4 mies.    │ 10–15%       │
/// │ 10. Rozruchy i odbiory      │ 1–2 mies.    │ 5–8%         │
/// └─────────────────────────────┴──────────────┴──────────────┘
/// ★ = Rdzeń harmonogramu (najkrytyczniejsza faza)
/// 
/// 🏢 WPŁYW LICZBY PIĘTER NA HARMONOGRAM
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Typowe czasy realizacji:
/// ┌──────────────────────────────────────────┬────────────────┐
/// │ Typ budynku                              │ Czas realizacji│
/// ├──────────────────────────────────────────┼────────────────┤
/// │ 4 kondygnacje bez garażu                 │ 14–18 mies.    │
/// │ 6–8 kondygnacji + garaż                  │ 18–24 mies.    │
/// │ 10–12 kondygnacji + 2 poziomy garażu     │ 22–30 mies.    │
/// └──────────────────────────────────────────┴────────────────┘
/// 
/// Każde dodatkowe piętro ponad 8 kondygnacji dodaje ~3 tygodnie
/// Każde piętro poniżej 5 kondygnacji odejmuje ~2 tygodnie
/// 
/// 🏗️ WPŁYW GARAŻY PODZIEMNYCH NA HARMONOGRAM
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// 1️⃣ GARAŻ JEDNOSTOPNIOWY (-1):
///    Dodatkowe czasy:
///    • Przygotowanie: +1 miesiąc
///    • Fundamenty: +2 miesiące
///    
///    Dodatkowe prace:
///    • Projekt zabezpieczenia wykopu (ścianki szczelne)
///    • Palisady ochronne
///    • Wymiana i zwiezienie gruntu
///    • Odwodnienie igłofiltrami (6–10 tygodni)
///    • Monitoring przemieszczeń
/// 
/// 2️⃣ GARAŻ DWUSTOPNIOWY (-1, -2):
///    Dodatkowe czasy:
///    • Przygotowanie: +2 miesiące
///    • Fundamenty: +5 miesięcy
///    
///    Dodatkowe prace:
///    • Projekt zabezpieczenia wykopu (ścianki szczelne na pełną głębokość)
///    • Palisady grodzicowe 8–10 m
///    • Wymiana dużych ilości gruntu
///    • Odwodnienie igłofiltrami (8–12 tygodni)
///    • Pompy odwodniające
///    • Pomiary geodezyjne
///    • Budowa pontonu podziemnego
///    • Ścianki nośne podziemia
///    • Stropy międzypoziomowe
///    • Izolacje przeciwwodne (ciężkie)
/// 
/// 📈 ALGORYTM OBLICZANIA HARMONOGRAMU
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// TotalWeeks = BaseWeeks + FloorAdjustment + BasementAdjustment
/// 
/// Gdzie:
/// • BaseWeeks = 90 (dla mieszkalnego), 110 (dla biurowego)
/// • FloorAdjustment = max(0, (totalFloors - 5) * 3)
///            lub = -(min(0, totalFloors - 5) * 2)
/// • BasementAdjustment = basementModifiers[levels].additionalFoundationWeeks * 7
/// 
/// ⚡ PRZYKŁAD
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Scenariusz: Budynek mieszkalny 10 kondygnacji + garaż 2-poziomy
/// 
/// 1. BaseWeeks = 90 tygodni
/// 2. FloorAdjustment = (10 - 5) * 3 = 15 tygodni (+3+ miesiące)
/// 3. BasementAdjustment = 5 miesięcy = ~20 tygodni
/// 4. TotalWeeks = 90 + 15 + 20 = 125 tygodni = ~30 miesięcy
/// 
/// Rozkład etapów dla tego scenariusza:
/// ┌─────────────────────────────┬──────────┐
/// │ Etap                        │ Tygodnie │
/// ├─────────────────────────────┼──────────┤
/// │ Przygotowanie               │ 4        │
/// │ Fundamenty (!!!)            │ 12 (+5)  │
/// │ Konstrukcja (rdzeń)         │ 18       │
/// │ Stan surowy zamknięty       │ 8        │
/// │ Tynki                       │ 8        │
/// │ Posadzki                    │ 4        │
/// │ Osprzęt elektryczny         │ 6        │
/// │ Malowanie                   │ 8        │
/// │ Finalizacja                 │ 6        │
/// │ Rozruchy i odbiory          │ 3        │
/// └─────────────────────────────┴──────────┘
/// 
/// 🔧 IMPLEMENTACJA W KODZIE
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// 1. ConstructionScheduleDatabase
///    └─ Zawiera dane etapów budowy (weekRange, timePercentage, tasks)
///    └─ BasementModifier dla wpływu garaży
/// 
/// 2. ScheduleDataIntegration
///    └─ generateSchedulePhases() - oblicza etapy z datami
///    └─ generateElectricalTasksForStages() - tworzy zadania
/// 
/// 3. ScheduleCalculator
///    └─ calculateSchedule() - oblicza czas dla każdego etapu
///    └─ generatePhases() - deleguje do ScheduleDataIntegration
/// 
/// 4. ProjectChecklistGenerator
///    └─ generateProject() - tworzy kompletny projekt z harmonogramem
/// 
/// 💡 CECHY SYSTEMU
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// ✅ Dynamiczne dostosowanie harmonogramu:
///    - Na podstawie liczby pięter
///    - Na podstawie liczby poziomów garaży
///    - Na podstawie typu budynku (mieszkalny/biurowy)
///    - Na podstawie wybranych systemów elektrycznych
/// 
/// ✅ Inteligentne planowanie instalalacji elektrycznych:
///    - Zasilanie: zamówienia 4 tygodnie przed przegrodami
///    - Osprzęt: montaż podrzędny odbiorem zasilaczy
///    - Systemy specjalistyczne: dostosowane do etapów
/// 
/// ✅ Warunki klimatyczne:
///    - PolishClimateAnalyzer uwzględnia pory roku
///    - Prace na zewnątrz dostosowane do wydajności sezonowa
/// 
/// ✅ Obsługa garaży podziemnych:
///    - Dodatkowe prace przygotowawcze
///    - Specjalne etapy dla fundamentów
///    - Monitoring przemieszczeń
/// 
/// 📚 ROZSZERZENIA
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Na podstawie dokumentu można rozszerzyć o:
/// 1. Detektory zmiany warunków gruntowych (m.in. woda gruntowa)
/// 2. Szczegółowe plany logistyki budowy
/// 3. Plany gospodarki odpadami
/// 4. Alerty dla zbliżających się krytycznych faz
/// 5. Raport porównawczy: plan vs. faktycze tempo
/// 6. Zastosowanie zasobów na konkretnych etapach
/// 
/// 📎 STOSOWANIE W UI
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// 1. Ekran konfiguracji budynku:
///    - Wybór typu budynku
///    - Liczba pięter nadziemnych (4-12+)
///    - Liczba poziomów garaży (0-2)
///    - Wybór systemów elektrycznych
/// 
/// 2. Wizualny harmonogram na gantcie:
///    - Etapy budowy z datami
///    - Procent wykonania
///    - Alerty dla opóźnień
/// 
/// 3. Dynamiczna lista zadań:
///    - Taskami zgrupowane po etapach
///    - Zależności i blokady
///    - Status wykonania
/// 
/// 4. Analiza wpływu:
///    - "Co się stanie jeśli dodamy dodatkowe piętro?"
///    - "Ile czasu zajmie garaż 2-poziomowy?"
/// 
/// ═══════════════════════════════════════════════════════════════════════════
/// 
/// Wersja: 1.0
/// Data ostatniej aktualizacji: 24.02.2026
/// Źródło dokumentu: Dokument użytkownika
