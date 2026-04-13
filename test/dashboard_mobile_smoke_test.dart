import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridly/main.dart';

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required Size surfaceSize,
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const GridlyApp(firebaseEnabled: false));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

void main() {
  group('Dashboard mobile smoke tests', () {
    testWidgets('renders correctly in portrait mobile viewport', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      expect(find.text('Gridly Electrical Checker'), findsOneWidget);
      expect(find.text('Moja budowa'), findsOneWidget);
      expect(find.text('Zasilanie placu budowy'), findsOneWidget);
      expect(find.text('Obwody elektryczne'), findsOneWidget);
      expect(find.text('Multitool'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in landscape mobile viewport', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(915, 412));

      expect(find.text('Gridly Electrical Checker'), findsOneWidget);
      expect(find.text('Moja budowa'), findsOneWidget);
      expect(find.text('Zasilanie placu budowy'), findsOneWidget);
      expect(find.text('Obwody elektryczne'), findsOneWidget);
      expect(find.text('Multitool'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens profile screen from app bar action', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      await tester.tap(find.byTooltip('Profil i ustawienia'));
      await tester.pumpAndSettle();

      expect(find.text('Profil i ustawienia'), findsOneWidget);
      expect(find.text('Zaloguj przez Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens project selector from dashboard quick action', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      await tester.tap(find.text('Moja budowa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Moja Budowa'), findsOneWidget);
      expect(find.text('Nowa Budowa'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}