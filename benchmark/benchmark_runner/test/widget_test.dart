// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:benchmark_runner/main.dart';

void main() {
  testWidgets('Benchmark app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MobileBenchmarkApp());

    // Verify that the benchmark home screen is shown
    expect(find.text('Mobile Benchmarks'), findsOneWidget);
    expect(find.text('Device Info'), findsOneWidget);

    // Verify the "Run Benchmarks" button is present
    expect(find.text('Run Benchmarks'), findsOneWidget);
  });
}
