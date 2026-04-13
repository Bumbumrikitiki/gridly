# Instrukcja przeprowadzenia testów Smoke S1T1

## Status

✅ **Infrastruktura gotowa**
- design_system.dart: WCAG AA paleta kolorów, typografia, spacing
- smoke_test_cases_s1t1.dart: 34 przypadki testowe zdefiniowane
- auto_backup_s1.ps1: Script backupu z Git tagowaniem
- S1T1_results.csv: Pusty formularz dla wyników

## Fase 1: Sprawdzenie Struktury Testów (5 minut)

```bash
cd "d:\Dom\Gridly\moja budowa 8.04.26 v2"
flutter test test/smoke_test_cases_s1t1.dart -v
```

**Oczekiwane wyniki**:
```
✓ Verify test case count matches requirement (28 unit + 6 common = 34)
✓ All test cases have required metadata
✓ Count test cases by category
✓ Count test cases by risk level
✓ Print all test cases for manual verification
```

---

## Faza 2: Testy Manualne na Chrome (1.5 - 2 dni)

### Krok 1: Uruchomienie Aplikacji

```bash
# Terminal 1 - Start Flutter
flutter run -d chrome

# Oczekiwane: App ładuje się w <4 sekundy, widoczny główny dashboard
```

### Krok 2: Konfiguracja Emulacji Mobilnej

**Chrome DevTools F12**:
1. Kliknij ikonę urządzenia (Toggle device toolbar)
2. Wybierz: **Samsung Galaxy S10** (1440×3040 portrait)
3. Ustaw Density: 2.0 (dwukrotny zoom)

### Krok 3: Test Każdego Etapu

**Szablon testu dla każdego S1T1.X**:

```
┌─ TEST: S1T1.1 "Przygotowanie placu budowy"
│
├─ Krok 1: Nawigacja
│  └─ Kliknij "Mieszkania" tab → pierwszy projekt
│     Expected: Brak crash overlay, stage ładuje się <1s
│
├─ Krok 2: Checkbox Toggle
│  ├─ Kliknij checkbox "Ukończone"
│  ├─ Verify: Zaznaczone (✓), zielony highlight
│  ├─ Kliknij ponownie
│  ├─ Verify: Zaznaczenie usunięte, brak koloru
│  └─ Screenshot: PORTRAIT_S1T1.1_checkbox.png
│
├─ Krok 3: Pole Notatek
│  ├─ Kliknij pole "Uwagi"
│  ├─ Wstaw 50+ znaków tekstu
│  ├─ Scroll w dół (jeśli potrzeba)
│  ├─ Verify: Tekst widoczny, nie obcięty
│  └─ Screenshot: PORTRAIT_S1T1.1_notes.png
│
├─ Krok 4: Subkontraktor (jeśli dostępny)
│  ├─ Kliknij "Dodaj podwykonawcę"
│  ├─ Wybierz istniejącego (lub przejdź do dodania nowego)
│  ├─ Verify: Nazwa wyświetlana: "Imię · Budynek X · Klatka A"
│  ├─ Kliknij "Usuń" (X button)
│  ├─ Verify: Podwykonawca usunięty, brak błędu
│  └─ Screenshot: PORTRAIT_S1T1.1_contractor.png
│
├─ Krok 5: Landscape Mode
│  ├─ Naciśnij Ctrl+Shift+M (lub kliknij rotacja)
│  ├─ Verify: Layout się przeformatuje (bez horizontal scroll)
│  ├─ Verify: Pola wciąż dostępne i klikalne
│  ├─ Verify: Tekst czytelny (≥12dp)
│  └─ Screenshot: LANDSCAPE_S1T1.1.png
│
├─ Krok 6: Hot Reload
│  ├─ Terminal: Naciśnij R
│  ├─ Wait: 766-1298ms (typical hot reload time)
│  ├─ Verify: Wszystkie zmiany persystują
│  ├─ Verify: Checkbox wciąż zaznaczony, tekst w notatkach
│  └─ Marker: Reload OK ✓
│
└─ Wynik: PASS ✓ (jeśli wszystko OK)

Repozytorium: Zrzut ekranu plików do folderu screenshots/S1T1/
```

### Krok 4: Prioritet - Testy Krytyczne Najpierw

**Dzień 1-2 (Krytyczne - 8 testów, ~1h każdy)**:

| TestID | Nazwa | Sprawdzenie |
|--------|-------|------------|
| S1T1.9 | Systemy hydrauliczne i gaz | Walidacja ciśnienia (kPa), obliczania upuszczenia nagłówka |
| S1T1.13 | Infrastruktura niskiego prądu | Wielość opornika (AWG), gradient napięcia, kalkulator |
| S1T1.16 | Systemy teletechniczne | Panel sieciowy, przypisanie párów, test straty mocy |
| S1T1.23 | Elektryczne bezpieczeństwo | Szyna zborcza, opór uziemienia ≤10Ω |
| S1T1.28 | Metadane projektowe | Eksport PDF, Excel, CSV - wszystkie formaty generują |
| S1T1.32 | Performance 100 jednostek | Cold start <4s na 3G, warm start <2s |
| S1T1.33 | Persistence | Force-kill (Task Manager) → restart → dane zachowane |
| S1T1.34 | Workflow podwykonawcy | Przypisanie do 3 etapów, cascade removal |

---

## Faza 3: Mobile Emulator Checkpoint (Opcjonalnie, Dzień 2 Wieczorem)

```bash
# Start Android Emulator
emulator -avd Pixel_4_API_30  # (lub swój emulator)

# W nowym terminalu:
flutter run -d emulator-5554

# Powtórz 5 testów krytycznych:
# - Portrait: S1T1.9, S1T1.13, S1T1.16, S1T1.23, S1T1.32
# - Landscape: Obrót 90° dla każdego, verify reflow
# - Touch Targets: Kliknij checkbox 5× szybko (must be ≥48dp)
```

---

## Faza 4: Zapis Wyników

### Po każdym teście S1T1.X:

Edytuj `test/S1T1_results.csv`:

```csv
S1T1.1,Przygotowanie placu,Unit,Mieszkaniowa,Critical,PASS,OK_no_scroll,OK_landscape_reflow,245ms,Yes,N/A,OK
S1T1.9,Systemy hydrauliczne,Unit,Mieszkaniowa,Critical,PASS,OK_pressure_validation,OK_landscape_table,312ms,Yes,N/A,OK
...
```

**Pola**:
- **Status**: PASS / FAIL / BLOCKED
- **Notes_Portrait**: Text krótki (OK_no_crash, OK_no_scroll, etc.)
- **Notes_Landscape**: Layout reflow, text visibility
- **PerformanceMs**: Czas ładowania etapu (oczekiwane <500ms)
- **DataPersisted**: Czy zmiany persystują (Yes/No)
- **Contractor_AddRemove**: Czy dodanie/usunięcie działa (OK/FAIL/N/A)

### Końcowe podsumowanie:

```csv
SUMMARY,,,,,PASS,34,34,,,100%
CRITICAL_PASS,,,,,PASS,8,8,,,100%
FAILED_TESTS,,,,,,,0
AVERAGE_PERF_MS,,,,,245,245,245
COLD_START_3G,,,,,3800ms
WARM_START_CACHE,,,,,1200ms
```

---

## Faza 5: Git Commit & Tag

```bash
cd "d:\Dom\Gridly\moja budowa 8.04.26 v2"

# Dodaj wyniki
git add test/S1T1_results.csv screenshots/
git add -A

# Commit
git commit -m "S1T1: Smoke tests complete - 34/34 passing

✓ All 28 unit stages verified for crashes
✓ All 6 common area stages working correctly
✓ Mobile responsive on portrait/landscape (Samsung S10 emulation)
✓ Data persistence verified (app kill & restart test)
✓ Performance: Cold start 3.8s on 3G, warm 1.2s cache
✓ All touch targets ≥48dp (mobile safe)
✓ No layout overflow or horizontal scroll
✓ PDF export functional for metadata (S1T1.28)
✓ Contractor add/remove workflow smooth

Results: 34/34 PASS (100%)
Risk levels: 8 Critical (PASS), 18 High (PASS), 6 Medium (PASS), 2 Low (PASS)"

# Tag phase
git tag -a phase/smoke-tests -m "Sprint 1, Week 1: All core functionality verified for crashes, data persistence, and mobile responsiveness"

# Show tag created
git tag -l | grep smoke
```

---

## Jeśli Test FAILs...

### Scenariusz 1: Crash pada
```
❌ S1T1.15 "Oddymianie" - CRASH on load

1. Otwórz DevTools (F12) → Console
2. Kopiuj error message
3. Otwórz lib/screens/PROJECT/oddymianie_screen.dart
4. Sprawdź: Widget.build() logic
5. Uruchom: flutter pub get && flutter pub upgrade
6. Hot reload (R)
```

### Scenariusz 2: Layout overflow
```
❌ S1T1.16 "Teletechnika" - Horizontal scroll w landscape

Przyczyna: Tekst zbioru > szerokość ekranu

Rozwiązanie w design_system.dart:
- Zwiększ labelMedium.fontSize z 14 na 12 (portrait only)
- Lub zmień headlineSmall z 16 na 14

Potem: Hot reload (R)
```

### Scenariusz 3: Dane nie persystują
```
❌ S1T1.33 "Persistence" - Notes znikają po restarcie

1. Otwórz DevTools → Console → check error logs
2. Sprawdź: shared_preferences package zainstalowany?
   flutter pub list-package-dirs
3. Jeśli brakuje: flutter pub get
4. Jeśli problem dalej: Check project_manager_provider.dart
   - Verify: saveToLocalStorage() called na każdej zmianie
   - Verify: loadFromLocalStorage() called na app init
```

---

## Metryki Sukcesu (Baseline dla S1T1)

| Metryka | Target | Aktualne | Status |
|---------|--------|----------|--------|
| Testy zdane | 34/34 | TBD | ⏳ |
| Crash-free | 100% | TBD | ⏳ |
| Cold start (3G) | <4s | TBD | ⏳ |
| Warm start | <2s | TBD | ⏳ |
| Mobile responsive | ✓ Portrait + Landscape | TBD | ⏳ |
| Data persistence | 100% | TBD | ⏳ |
| Average load stage | <500ms | TBD | ⏳ |
| Touch targets | ≥48dp | TBD | ⏳ |

---

## Next Steps (Po S1T1 PASS)

1. ✅ S1T1: Smoke tests complete
2. ⏳ **S1T2** (Week 2): Design System Audit
   - Implement DesignSystem constants w wszystkich screenach
   - WCAG AA contrast audit (all text ≥4.5:1)
   - Mobile font scaling (adaptive zwischen 12-20dp)
   
3. ⏳ **S1T3** (Week 3-4): Performance Optimization
   - Lazy loading dla tab system
   - Skeleton screens dla data fetch
   - PDF streaming (jeśli >100 stron)

4. ⏳ **S2T1** (Week 5-6): Profile + GDPR
   - Profile screen
   - Export data workflow
   - Delete account countdown
   - Legal documents

5. ⏳ **S2T2** (Week 7): Monetization
   - Firebase Ads integration
   - Freemium feature gating
   - Analytics

---

## Helpful Commands During Testing

```bash
# Clean build cache
flutter clean

# Rebuild assets
flutter pub get
flutter pub upgrade

# Check for Dart errors
dart analyze

# Format all Dart files
dart format lib/ test/

# Hot reload (while app running)
# - Press R in terminal

# Profile performance
# - Chrome URL: chrome://devtools -> Performance tab

# View logs
flutter logs

# Kill all Flutter processes
taskkill /F /IM "chrome.exe"  # Close app completely
```

---

**Good luck! Report progress to Git tags as you go:**
- `git tag phase/smoke-tests` → After S1T1 PASS

