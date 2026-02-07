// Smoke test pour l'application OPEXUNIT.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opexunit_mobile/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const OpexUnitApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
