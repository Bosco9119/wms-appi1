// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:auto_anywhere_app/main.dart';
import 'package:auto_anywhere_app/shared/providers/customer_provider.dart';

void main() {
  testWidgets('AutoAnywhere App smoke test', (WidgetTester tester) async {
    // Build our app with required providers and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => CustomerProvider())],
        child: const AutoAnywhereApp(),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
