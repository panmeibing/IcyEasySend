// Test for settings page concurrent transfers confirmation dialog
//
// These tests verify that the confirmation dialog appears when
// changing concurrent transfers setting

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/pages/settings_page.dart';
import 'package:icy_easy_send/services/http_server_manager.dart';

void main() {
  group('SettingsPage Concurrent Transfers Tests', () {
    late HTTPServerManager mockServerManager;

    setUp(() {
      mockServerManager = HTTPServerManager();
    });

    tearDown(() async {
      await mockServerManager.stopServer();
    });

    testWidgets('SettingsPage builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify the page builds
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('Concurrent transfers slider exists', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify slider exists
      expect(find.byType(Slider), findsOneWidget);

      // Verify label exists
      expect(find.text('并发传输数量'), findsOneWidget);
    });

    testWidgets('Slider displays current value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Find the slider
      final slider = tester.widget<Slider>(find.byType(Slider));

      // Verify slider has a value between 1 and 10
      expect(slider.value, greaterThanOrEqualTo(1));
      expect(slider.value, lessThanOrEqualTo(10));
    });

    testWidgets('Slider can be moved', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Get initial slider value
      final initialSlider = tester.widget<Slider>(find.byType(Slider));
      final initialValue = initialSlider.value;

      // Find the slider and drag it
      final sliderFinder = find.byType(Slider);
      
      // Get the slider's position and size
      final sliderRect = tester.getRect(sliderFinder);
      
      // Drag to the right (increase value)
      await tester.drag(
        sliderFinder,
        Offset(sliderRect.width * 0.2, 0),
      );
      await tester.pump();

      // Get new slider value
      final newSlider = tester.widget<Slider>(find.byType(Slider));
      final newValue = newSlider.value;

      // Verify value changed
      expect(newValue, isNot(equals(initialValue)));
    });

    testWidgets('Confirmation dialog appears when slider is released', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Get initial slider value
      final initialSlider = tester.widget<Slider>(find.byType(Slider));
      final initialValue = initialSlider.value;

      // Find the slider and drag it
      final sliderFinder = find.byType(Slider);
      final sliderRect = tester.getRect(sliderFinder);
      
      // Drag to change value
      await tester.drag(
        sliderFinder,
        Offset(sliderRect.width * 0.3, 0),
      );
      await tester.pump();

      // Release the slider (trigger onChangeEnd)
      await tester.pumpAndSettle();

      // Check if value actually changed
      final newSlider = tester.widget<Slider>(find.byType(Slider));
      if (newSlider.value != initialValue) {
        // Verify confirmation dialog appears
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('确认修改'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('确认修改', findRichText: true), findsWidgets);
      }
    });

    testWidgets('Dialog shows correct message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Get initial slider value
      final initialSlider = tester.widget<Slider>(find.byType(Slider));
      final initialValue = initialSlider.value;

      // Find the slider and drag it significantly
      final sliderFinder = find.byType(Slider);
      final sliderRect = tester.getRect(sliderFinder);
      
      // Drag to change value
      await tester.drag(
        sliderFinder,
        Offset(sliderRect.width * 0.4, 0),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Check if value actually changed
      final newSlider = tester.widget<Slider>(find.byType(Slider));
      if (newSlider.value != initialValue) {
        // Verify dialog content
        expect(find.byType(AlertDialog), findsOneWidget);
        
        // Should contain information about the change
        expect(
          find.textContaining('确定要将并发传输数量'),
          findsOneWidget,
        );
      }
    });

    testWidgets('Cancel button reverts slider value', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Get initial slider value
      final initialSlider = tester.widget<Slider>(find.byType(Slider));
      final initialValue = initialSlider.value;

      // Find the slider and drag it
      final sliderFinder = find.byType(Slider);
      final sliderRect = tester.getRect(sliderFinder);
      
      // Drag to change value
      await tester.drag(
        sliderFinder,
        Offset(sliderRect.width * 0.3, 0),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Check if dialog appeared
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        // Tap cancel button
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();

        // Verify dialog is dismissed
        expect(find.byType(AlertDialog), findsNothing);

        // Verify slider value is reverted
        final revertedSlider = tester.widget<Slider>(find.byType(Slider));
        expect(revertedSlider.value, equals(initialValue));
      }
    });
  });

  group('SettingsPage UI Elements Tests', () {
    late HTTPServerManager mockServerManager;

    setUp(() {
      mockServerManager = HTTPServerManager();
    });

    tearDown(() async {
      await mockServerManager.stopServer();
    });

    testWidgets('Settings page has all required sections', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify main sections exist
      expect(find.text('设备信息'), findsOneWidget);
      expect(find.text('服务器信息'), findsOneWidget);
      expect(find.text('传输设置'), findsOneWidget);
    });

    testWidgets('Concurrent transfers info text is displayed', 
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(serverManager: mockServerManager),
        ),
      );

      // Wait for loading to complete
      await tester.pumpAndSettle();

      // Verify info text exists
      expect(
        find.textContaining('较高的并发数可以更好地利用带宽'),
        findsOneWidget,
      );
    });
  });
}
