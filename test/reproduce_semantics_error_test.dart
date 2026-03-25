import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render/hyper_render.dart';

void main() {
  testWidgets(
      'Reproduce semantics.parentDataDirty assertion error with nested tables',
      (tester) async {
    // Create a deeply nested table structure to trigger deep semantics recursion
    String nestedTableHtml = '<table>';
    for (int i = 0; i < 5; i++) {
      nestedTableHtml += '<tr><td>Table Level $i <table>';
    }
    nestedTableHtml += '<tr><td>Leaf Content</td></tr>';
    for (int i = 0; i < 5; i++) {
      nestedTableHtml += '</table></td></tr>';
    }
    nestedTableHtml += '</table>';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HyperViewer(
              html: nestedTableHtml,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Trigger a semantics update by enabling semantics
    final SemanticsHandle handle = tester.ensureSemantics();

    // Change something to trigger a rebuild and semantics update
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HyperViewer(
              html: '$nestedTableHtml<p>Trigger update</p>',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    handle.dispose();
  });
}
