/// Real Screen Smoke Tests — Sprint 1, Phase 1
///
/// Covers actual routes registered in main.dart and validates real user flows.
/// The app is booted through GridlyApp(firebaseEnabled: false), matching the
/// existing smoke-test pattern used in this repository.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gridly/main.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  required Size surfaceSize,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const GridlyApp(firebaseEnabled: false));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> _openRouteFromDashboard(
  WidgetTester tester,
  String label,
) async {
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

Future<void> _pushNamedRoute(
  WidgetTester tester,
  String routeName,
) async {
  final context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).pushNamed(routeName);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}

void main() {
  group('Real screen smoke tests', () {
    testWidgets('RT-01 dashboard renders core quick actions', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      expect(find.text('Gridly Electrical Checker'), findsOneWidget);
      expect(find.text('Moja budowa'), findsOneWidget);
      expect(find.text('Zasilanie placu budowy'), findsOneWidget);
      expect(find.text('Obwody elektryczne'), findsOneWidget);
      expect(find.text('Multitool'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RT-02 profile opens from dashboard action', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      await tester.tap(find.byTooltip('Profil i ustawienia'));
      await tester.pumpAndSettle();

      expect(find.text('Profil i ustawienia'), findsOneWidget);
      expect(find.text('Zaloguj przez Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RT-03 paywall opens from dashboard PRO action', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      await tester.tap(find.widgetWithText(TextButton, 'PRO'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Gridly PRO'), findsOneWidget);
      expect(find.textContaining('Odblokuj Gridly PRO'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RT-04 construction-power route opens from dashboard', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      await _openRouteFromDashboard(tester, 'Zasilanie placu budowy');

      expect(find.text('Zasilanie placu budowy'), findsWidgets);
      expect(find.textContaining('Plac budowy:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RT-05 audit route opens from dashboard', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      await _openRouteFromDashboard(tester, 'Obwody elektryczne');

      expect(find.text('Obwody elektryczne'), findsOneWidget);
      expect(
        find.textContaining('Wyniki mają charakter orientacyjny'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('RT-06 multitool route opens from dashboard', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      await _openRouteFromDashboard(tester, 'Multitool');

      expect(find.text('Multitool'), findsWidgets);
      expect(find.textContaining('funkcji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RT-07 auth route opens by named navigation', (
      WidgetTester tester,
    ) async {
      await _pumpApp(tester, surfaceSize: const Size(412, 915));

      await _pushNamedRoute(tester, '/auth');

      expect(find.text('Konto i subskrypcja'), findsOneWidget);
      expect(find.textContaining('Status konta:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
