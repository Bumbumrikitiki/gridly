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

Future<void> _openDashboardRoute(
  WidgetTester tester,
  String label,
) async {
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  group('Remaining modules mobile smoke tests', () {
    testWidgets('opens construction power module from dashboard', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      await _openDashboardRoute(tester, 'Zasilanie placu budowy');

      expect(find.textContaining('topologię'), findsWidgets);
      expect(find.text('Pokaż tylko rozdzielnice'), findsOneWidget);
      expect(find.text('Tylko elementy z problemami'), findsOneWidget);
    });

    testWidgets('opens circuit assessment module from dashboard', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      await _openDashboardRoute(tester, 'Obwody elektryczne');

      expect(find.text('Obwody elektryczne'), findsOneWidget);
      expect(
        find.text('Potwierdzam weryfikację danych i pomiarów'),
        findsOneWidget,
      );
      expect(find.text('Oblicz'), findsOneWidget);
      expect(find.text('Generuj Raport PDF'), findsOneWidget);
    });

    testWidgets('opens multitool module from dashboard', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      await _openDashboardRoute(tester, 'Multitool');

      expect(find.text('Multitool'), findsWidgets);
      expect(find.text('7 funkcji'), findsOneWidget);
      expect(find.text('Obliczanie spadku napięcia'), findsOneWidget);
      expect(find.text('Przygotowanie do odbiorów OSD'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens voltage drop tool from multitool grid', (
      WidgetTester tester,
    ) async {
      await _pumpDashboard(tester, surfaceSize: const Size(412, 915));

      await _openDashboardRoute(tester, 'Multitool');

      await tester.tap(find.text('Obliczanie spadku napięcia'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Spadek napięcia'), findsOneWidget);
      expect(find.text('Oblicz spadek napięcia'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });
}