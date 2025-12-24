import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:egg_walker/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EggWalkerApp()));

    // Verify that the app title is present (or some key element)
    // Note: Localization might make finding text tricky without setup,
    // so we look for basic structure or Key if available.
    // For now, just checking if it pumps without error is a good start.

    // Allow time for async init if any
    await tester.pumpAndSettle();

    // Just verify we have a scaffold or something basic
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
