// Widget tests for Icy Easy Send app
//
// These tests verify the UI components and interactions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:icy_easy_send/main.dart';

void main() {
  testWidgets('App initializes and shows loading indicator', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Initially should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('App title is correct', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(const MyApp());

    // Verify app title
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, equals('Icy Easy Send'));
  });
}
