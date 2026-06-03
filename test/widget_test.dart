import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expence_tracking/main.dart';
import 'package:expence_tracking/providers/expense_provider.dart';
import 'package:expence_tracking/providers/wallet_provider.dart';
import 'package:expence_tracking/providers/category_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('App loads splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen text exists (adjust based on your actual splash screen text)
    // For now, we just check if the app builds without crashing.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
