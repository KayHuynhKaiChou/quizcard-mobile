// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizcard_mobile/main.dart';

void main() {
  testWidgets('shows onboarding welcome screen', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 1200));
    await tester.pumpWidget(const QuizcardApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to\nTerminology Master!'), findsOneWidget);
    await tester.binding.setSurfaceSize(null);
  });
}
