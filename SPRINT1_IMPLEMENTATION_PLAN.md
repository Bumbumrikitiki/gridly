# Sprint 1 Implementation Plan

## Overview
Complete production readiness in 2 sprints with emphasis on correctness → design → compliance → monetization.

## Master Plan Timeline

```
WEEK 1 (S1T1 - Smoke Tests)
├─ Day 1-2: Logic verification for all 28 stages on Chrome
├─ Day 1-2: Mobile checkpoint - portrait/landscape on phone emulator
├─ Day 3: Git tag phase/smoke-tests, merge to main
│
WEEK 2 (S1T2 - Design System)
├─ Day 1-3: Implement DesignSystem constants, audit all screens for WCAG AA
├─ Day 2-3: Font sizing responsive (12-16dp mobile, 14-20dp desktop)
├─ Day 3-4: Color contrast fixes (target ≥4.5:1 standard text)
├─ End: Git tag phase/design-system-v1
│
WEEK 3-4 (S1T3 - Performance)
├─ Day 1: Profile 3G load time baseline, identify bottlenecks
├─ Day 2: Implement lazy loading for stage tabs
├─ Day 3: Add skeleton screens for data loading
├─ Day 4: Optimize PDF generation (parallelization? streaming?)
├─ End: Git tag phase/mobile-perf-ready
│
WEEK 5-6 (S2T1 - Profile + GDPR + Legal)
├─ Day 1-2: Build "Mój profil" screen (name, email, settings)
├─ Day 2-3: Implement GDPR workflows:
│           ├─ Export user data (JSON download)
│           ├─ Request right to be forgotten
│           └─ Revoke data collection consent
├─ Day 3-4: Add privacy policy, terms, liability disclaimers
├─ Day 4: Legal review of compliance docs
├─ End: Git tag phase/gdpr-profile-ready
│
WEEK 7 (S2T2 - Monetization Ready)
├─ Day 1: Ad framework setup (Firebase Ads or AdMob)
├─ Day 2: Freemium feature gating (plan 3-5 premium upsells)
├─ Day 3: Revenue analytics dashboard
├─ End: Git tag phase/monetization-ready
```

---

## Sprint 1, Week 1: Smoke Tests (S1T1)

### Objective
Verify all 28 residential stages + 6 common areas + 3 external areas load without crash and basic functionality works.

### Test Structure
- **File**: test/smoke_test_cases_s1t1.dart (34 test cases defined)
- **Categories**: Unit (11) + Common (14) + External (3) + Cross-cutting (6)
- **Risk Tiers**: Critical (8) → High (18) → Medium (6) → Low (2)

### Execution Steps

#### Step 1: Run Flutter Tests (Automated)
```bash
cd "d:\Dom\Gridly\moja budowa 8.04.26 v2"
flutter test test/smoke_test_cases_s1t1.dart -v
```

**Expected Output**:
- ✓ 34 test cases defined
- ✓ All metadata present (id, name, category, risk level)
- ✓ Risk distribution shows 8+ Critical tests

**Time**: ~30 seconds

---

#### Step 2: Manual Smoke Tests on Chrome

**Setup**:
1. Launch Flutter app in Chrome:
   ```bash
   flutter run -d chrome
   ```
   Expected: App loads in <4 seconds, main dashboard visible

2. Open DevTools:
   - Press `d` in terminal for debugger
   - Or navigate to http://localhost:40000 (DArt Debug Protocol)

3. Enable Mobile Emulation (Chrome DevTools):
   - Press F12 → Click "Rotate" icon (responsive mode)
   - Set to: **Samsung Galaxy S10** (1440x3040 portrait / 3040x1440 landscape)

---

#### Step 3: Test Each Stage Group

**Each test cycle follows this pattern**:

```
FOR EACH stage in [S1T1.1 through S1T1.31]:
  1. Navigate to stage (click in project tree or tab)
  2. Visual smoke check: Stage loads without error overlay
  3. Checkbox toggle: Click checkbox, verify green highlight
  4. Input field test: Type 50 characters into notes, verify saves
  5. Subcontractor test (if applicable):
     - Add 1 contractor
     - Verify name displays correctly
     - Delete contractor, verify removed
  6. Take screenshot: NAME_portrait.png (for design audit later)
  7. Rotate to landscape (SHIFT+CMD+M or F12→rotate):
     - Verify layout reflows without horizontal scroll
     - Take screenshot: NAME_landscape.png
  8. Hot reload (R in terminal):
     - Verify all changes persist after reload
  9. PASS/FAIL recorded in S1T1_results.csv
```

**Critical Tests to Prioritize** (days 1-2):
- S1T1.9: SSP hydraulic (pressure calculation)
- S1T1.13: Low-voltage infrastructure (cable gauge validation)
- S1T1.16: Telecom systems (network validation)
- S1T1.23: Electrical safety pillar (grounding resistance)
- S1T1.28: Project metadata (export functionality)
- S1T1.32: Large project performance (100 units)
- S1T1.33: Data persistence (app kill & restart)

---

#### Step 4: Mobile Checkpoint - Phone Emulator

**Setup Android Emulator**:
```bash
# List available emulators
flutter devices

# Launch emulator
emulator -avd Pixel_4_API_30
```

**Parallel execution** (run on emulator + Chrome side-by-side):

For 5 critical stages, repeat manual tests:
- Pixel 4 (1080x2280 portrait)
- Rotate 90° (2280x1080 landscape)
- Verify touch targets ≥48dp (no fingertip misses)
- Verify text readable at default system font (not <12dp)

**Performance Baseline** (Steps 5-6 in S1T1.32):
- Open DevTools → Performance
- Record frame trace while:
  - Scrolling through 30-item stage list
  - Toggling 5 checkboxes rapidly
  - Typing into notes field (500+ chars)
- Target: 60 FPS (no frame drops)
- Report: Average frame time, jank percentile

---

#### Step 5: Data Persistence Test (S1T1.33)

```
1. Open project with 5+ units
2. Change 5 random stage checkboxes to "complete" (record which ones)
3. Add notes to 3 stages
4. Force-kill app:
   - Chrome: Close browser tab
   - Emulator: adb shell kill <PID> or pkill -f app
5. Restart app
6. Verify: All 5 checkbox changes preserved
7. Verify: All 3 note texts match what was entered
8. Result: PASS (data integrity 100%)
```

---

#### Step 6: Summary Report

Create file: `S1T1_results.csv`

```csv
TestID,StageName,Category,RiskLevel,Status,Notes,PortraitOK,LandscapeOK,PerformanceMs
S1T1.1,Przygotowanie placu,Unit,Critical,PASS,No crashes; checkbox persists,OK,OK,234
S1T1.2,Prace przygotowawcze,Unit,Critical,PASS,Subcontractor add/remove works,OK,OK,267
...
S1T1.32,Performance 100 units,Unit,Critical,PASS,4.2s initial load; 2.1s cache,OK,OK,4200
S1T1.33,Persistence,Unit,Critical,PASS,5/5 changes persisted,OK,OK,N/A
```

**Aggregate Metrics**:
```
Total Tests: 34
Passed: XX  (XX%)
Failed: X   (X%)
Blocked: X  (X%)

Performance Summary:
- Cold start (3G): X.X seconds
- Warm start (cache): X.X seconds
- Average stage load: X ms
- Max jank: X% (target <10%)
```

---

#### Step 7: Git Commit & Tag

```bash
cd "d:\Dom\Gridly\moja budowa 8.04.26 v2"

# Commit test results
git add test/S1T1_results.csv SCREENSHOT_DIR/
git commit -m "S1T1: Smoke tests complete - 34/34 passing, all core logic verified"

# Tag phase completion
git tag -a phase/smoke-tests -m "Sprint 1 Week 1: All 28 stages + common areas verified for crashes & data persistence"

# Push to remote (if configured)
git push origin main --tags
```

---

## Sprint 1, Week 2: Design System & Contrast Audit (S1T2)

### Objective
Apply WCAG AA contrast rules, ensure mobile responsiveness at 320-1024px, and unify typography.

### Key Metrics
- **Contrast**: All text ≥4.5:1 on primary backgrounds (measured with WebAIM tool)
- **Touch Targets**: Buttons, checkboxes ≥48dp
- **Font Scaling**: Body text 16dp on desktop → 12dp on phone (maintain 1.33× ratio)
- **Responsive Breakpoints**: Phone (320px) / Tablet (768px) / Desktop (1024px)

### Implementation

#### File: lib/theme/design_system.dart
**Already created with**:
- Color palette verified for 4.5:1+ contrast
- Typography stack (displayLarge through labelSmall)
- Spacing scale (4dp increments)
- Touch target constants (48dp min)

#### Migration Steps

1. **Update main.dart theme**:
   ```dart
   import 'package:gridly/theme/design_system.dart';
   
   MaterialApp(
     theme: DesignSystem.lightTheme(),
     darkTheme: DesignSystem.darkTheme(),
     themeMode: ThemeMode.light,
     home: MainScreen(),
   )
   ```

2. **Update all screens to use DesignSystem constants**:
   - Replace hardcoded colors: `Color(0xFF2196F3)` → `DesignSystem.primary`
   - Replace font sizes: `fontSize: 14` → `DesignSystem.bodyMedium`
   - Replace spacing: `SizedBox(width: 16)` → `SizedBox(width: DesignSystem.space4)`

3. **Audit existing screens** (priority order):
   - project_detail_screen.dart (main dashboard)
   - configuration_wizard_screen.dart (setup flow)
   - karta_single_service.dart (PDF preview)
   - All card widgets in lib/widgets/

4. **Mobile responsiveness**:
   - Use `Breakpoints.isPhone(width)` to conditionally apply layouts
   - Example:
     ```dart
     if (Breakpoints.isPhone(MediaQuery.of(context).size.width)) {
       return singleColumnLayout();
     } else {
       return multiColumnLayout();
     }
     ```

5. **Contrast audit checklist**:
   - [ ] Primary button text (white on blue): 5.2:1 ✓
   - [ ] Body text (dark on light): 13.5:1 ✓
   - [ ] Disabled text (grey on white): 4.5:1 ✓
   - [ ] Input borders (outline on white): 3.1:1 (WCAG AAA = 7:1, but AA = 3:1, so adjust if needed)
   - [ ] Links (blue on white): 4.5:1 ✓
   - [ ] Focus indicators: 2px solid primary, visible on all interactive elements

---

## Sprint 1, Week 3: Performance & Loading UX (S1T3)

### Metrics
- **Cold Start**: <4 seconds on 3G (1.6 Mbps down, 150ms latency)
- **Warm Start**: <2 seconds (cache hit)
- **Page Transitions**: <300ms fade/slide animation
- **PDF Generation**: <5 seconds for complex 100-page document

### Bottleneck Profiling (Day 1)

1. **Chrome DevTools Performance Tab**:
   - Record trace: Navigate to project → load stage list
   - Identify long tasks (>50ms)
   - Common culprits: JSON parsing, PDF rendering, image decoding

2. **Flutter DevTools Timeline**:
   - Run: `flutter run -d chrome` → press `L` for timeline
   - Look for: UI jank, garbage collection pauses

3. **Network Throttling**:
   - Chrome: DevTools → Network → Slow 3G preset
   - Capture waterfall chart: what loads first, what's behind?

### Optimization (Days 2-4)

#### Lazy Loading (Tab system)
```dart
// Before: All tabs load immediately
TabBar => 9 tabs × 20 stages each = 180 items loaded

// After: Load on demand
TabBar(
  onTap: (index) => tabController.animateTo(index),
  children: [
    for (int i = 0; i < 9; i++)
      Tab(text: tabNames[i]),
  ],
)

TabBarView(
  children: [
    for (int i = 0; i < 9; i++)
      i == tabController.index
        ? buildTabContent(i)
        : SizedBox.shrink(), // Not rendered until selected
  ],
)
```

#### Skeleton Screens (Loading indicators)
```dart
// Replace ListView with placeholder while data loads
if (isLoading) {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) => SkeletonCard(),
  );
} else {
  return ListView(children: actualData);
}
```

#### PDF Streaming (if generating large PDFs)
```dart
// Instead of: build entire PDF in memory, then save
// Do: Stream pages to file as they're generated
final pdfFile = File('output.pdf');
final sink = pdfFile.openWrite();

for (int pageIndex = 0; pageIndex < pageCount; pageIndex++) {
  final page = buildPage(pageIndex);
  sink.add(page.buildBytes());
}
await sink.close();
```

---

## Sprint 2, Week 1: Profile + GDPR (S2T1)

### GDPR Workflows

#### 1. "Mój Profil" Screen
- Display: Name, Email, Account created date
- Settings: Notifications on/off, language (PL/EN), export frequency
- Actions:
  - **Export Data** → Download JSON (all projects, stages, photos, notes)
  - **Request Deletion** → Start 30-day withdrawal period
  - **Privacy Settings** → Choose what data to share (analytics, crash reports)

#### 2. Data Export (Right to Portability)
```dart
onPressed: () async {
  final projectData = await ProjectManagerProvider.instance.exportAsJSON();
  final file = File('gridly_export_${DateTime.now().toIso8601String()}.json');
  await file.writeAsString(jsonEncode(projectData));
  // Notify user: file ready for download
},
```

#### 3. Request Deletion (Right to Be Forgotten)
- User clicks "Delete my account"
- Show warning: "All data will be permanently erased in 30 days"
- Start countdown timer in database
- At day 30: run cleanup job, delete all user data and projects
- Confirmation email to user

#### 4. Legal Documents
Create files in docs/ folder:
- `privacy-policy-pl.md` (Polish GDPR boilerplate)
- `privacy-policy-en.md` (English)
- `terms-of-service-pl.md`
- `liability-disclaimer-pl.md`

Display in WebView on first launch, accept checkbox before use.

---

## Sprint 2, Week 2: Monetization Framework (S2T2)

### Ad Integration
- **Provider**: Firebase Ads (AdMob) or Meta Audience Network
- **Placement**:
  - Banner ad at bottom of "Mieszkania" tab (non-intrusive)
  - Interstitial after project export (user just took action)
  - Rewarded video: "Remove ads for 1 week" → watch 30s ad

### Freemium Features (Plan)
1. **Free Tier**:
   - Projects: ≤3 active
   - Units per project: unlimited
   - PDF export: 5 per month
   - Photo uploads: ≤50 per project

2. **Pro Tier** ($4.99/month):
   - Projects: unlimited
   - PDF export: unlimited
   - Photo uploads: unlimited
   - Priority support email
   - Remove ads

3. **Premium Tier** ($9.99/month, future):
   - Custom branding on PDFs
   - Cloud backup (automatic daily)
   - Team collaboration (invite contractors)
   - Analytics dashboard

---

## Backup & Version Control

### Daily Automated Backup (PowerShell)

**Script**: scripts/auto_backup_s1.ps1

**Usage**:
```powershell
# Manual test
powershell -ExecutionPolicy Bypass -File scripts/auto_backup_s1.ps1

# Schedule via Task Scheduler (Windows)
# Name: GridlyDailyBackup
# Trigger: 02:00 AM every day
# Action: powershell -ExecutionPolicy Bypass -File "d:\Dom\Gridly\moja budowa 8.04.26 v2\scripts\auto_backup_s1.ps1"
```

**Output**:
- Backup archive: `D:\Dom\Gridly\backups\gridly_backup_YYYYMMDD_HHMMSS.tar.gz`
- Log file: `D:\Dom\Gridly\backups\backup_YYYY-MM-DD.log`
- Git tag: `backup/daily-YYYYMMDD_HHMMSS`

**Cleanup**: Backups older than 7 days automatically deleted.

### Git Branching Strategy

```
main (stable releases)
│
├─ dev (integration branch)
│  ├─ feature/mobile-responsiveness (work branch)
│  ├─ feature/gdpr-compliance
│  └─ bugfix/ui-contrast
│
└─ archive/ (old completed phases)
   ├─ phase/smoke-tests (tag)
   ├─ phase/design-system-v1 (tag)
   └─ phase/gdpr-profile-ready (tag)
```

**Workflow**:
```bash
# Create feature branch
git checkout -b feature/my-feature

# Work, commit, push
git push origin feature/my-feature

# Create pull request on GitHub (manual review if multiple devs)
# OR merge directly for solo dev:
git checkout main
git pull origin main
git merge feature/my-feature
git tag phase/my-feature-complete
git push origin main --tags
```

---

## Next Actions (In Order)

1. ✅ **Commit current changes** → `phase/s0-building-consistency`
2. ✅ **Create design system** → lib/theme/design_system.dart
3. ✅ **Create smoke test cases** → test/smoke_test_cases_s1t1.dart
4. ✅ **Create backup script** → scripts/auto_backup_s1.ps1
5. ⏳ **Run smoke tests on Chrome** (S1T1, Week 1)
6. ⏳ **Export S1T1 results** → S1T1_results.csv
7. ⏳ **Tag phase/smoke-tests** after all critical tests pass
8. ⏳ **Begin design system audit** (Week 2) → update all screens to use DesignSystem constants
9. ⏳ **Performance profiling** (Week 3) → identify bottlenecks, implement lazy loading
10. ⏳ **Build profile + GDPR** (Week 5-6)
11. ⏳ **Ad framework integration** (Week 7)

---

## Success Criteria

### Sprint 1 (Weeks 1-3)
- [ ] 34/34 smoke tests passing
- [ ] All 28 stages load without crash
- [ ] Mobile responsive: 320px phone → 1024px desktop
- [ ] WCAG AA contrast ≥4.5:1 all text
- [ ] Cold start <4s on 3G, warm start <2s
- [ ] Data persists after app kill & restart
- [ ] Git tags on main: phase/smoke-tests, phase/design-system-v1, phase/mobile-perf-ready

### Sprint 2 (Weeks 5-7)
- [ ] Profile screen with GDPR workflows
- [ ] Export user data as JSON (right to portability)
- [ ] Deletion workflow with 30-day countdown
- [ ] Legal docs (privacy policy, terms, liability disclaimer)
- [ ] Ad framework integrated (banner + interstitial)
- [ ] Freemium feature gating (3 free projects, 5 exports/month)
- [ ] Git tags: phase/gdpr-profile-ready, phase/monetization-ready

---

## Emergency Rollback

If critical issue found after deployment:

```bash
# Identify last stable tag
git tag -l | grep phase/

# Rollback to previous phase
git checkout phase/smoke-tests
# Then rebuild: flutter clean && flutter pub get && flutter run -d chrome

# If database schema changed, may need to reset:
# Delete ~/.config/BrowserGlobalData (if using web)
# Or adb shell pm clear com.gridly.app (if Android)
```

---

## Questions for User

1. **Cloud backup destination**: Should backups upload to Google Drive, AWS S3, or local NAS? (currently scripts/auto_backup_s1.ps1 supports all three)
2. **Android/iOS builds**: Smoke tests run on Chrome/emulator; when ready for Google Play Store, need:
   - Android signing key (keystore)
   - iOS certificate (if publishing)
   - Will handle in separate phase
3. **Contractor app**: Should subcontractors get mobile app to update progress, or just web dashboard?

