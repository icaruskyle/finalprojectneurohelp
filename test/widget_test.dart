import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projects/main.dart';

void main() {
  testWidgets('App loads WelcomeScreen when no user is logged in', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Wait for AuthWrapper to settle
    await tester.pumpAndSettle();

    // Test for WelcomeScreen widgets
    expect(find.text('Welcome to NeuroHelp'), findsOneWidget);
  });
}
