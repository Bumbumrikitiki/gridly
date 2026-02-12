// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:gridly/main.dart';

void main() {
  testWidgets('App starts and navigates to dashboard', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const GridlyApp());

    // Splash screen shows branding.
    expect(find.text('GRIDLY ELECTRICAL CHECKER'), findsOneWidget);

    // Let splash delay pass and show startup disclaimer.
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Informacja'), findsOneWidget);
    expect(find.text('Rozumiem'), findsOneWidget);

    // Accept disclaimer and allow navigation to dashboard.
    await tester.tap(find.text('Rozumiem'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Dashboard is visible.
    expect(find.text('Gridly Electrical Checker'), findsWidgets);
    expect(find.text('Ocena orientacyjna obwodu'), findsOneWidget);
  });
}
