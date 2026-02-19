/// Integration Test Suite Runner
///
/// Run all integration tests with:
/// ```bash
/// flutter test test/integration_test_all.dart
/// ```
library;

import 'integration/real_world_html_test.dart' as real_world;
import 'integration/large_document_test.dart' as large_doc;
import 'integration/performance_regression_test.dart' as performance;
import 'integration/error_recovery_test.dart' as error_recovery;
import 'integration/security_integration_test.dart' as security;
import 'integration/selection_integration_test.dart' as selection;

void main() {
  // Real-world content tests
  real_world.main();

  // Large document handling
  large_doc.main();

  // Performance regression tests
  performance.main();

  // Error recovery & robustness
  error_recovery.main();

  // Security & XSS prevention
  security.main();

  // Selection functionality
  selection.main();
}
