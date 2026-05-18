import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_render_devtools/hyper_render_devtools.dart';

/// Smoke test for [HyperRenderDevtools.register]. The full service-extension
/// surface needs a live VM service to exercise; here we verify the contract
/// that calling [register] is:
///
///   1. Safe to call (no exceptions in any build mode).
///   2. Idempotent — calling twice doesn't double-register or throw.
///
/// In release / profile / test builds `register()` is a no-op (the `kDebugMode`
/// guard returns early) so this test mainly protects against future
/// refactors accidentally crashing the caller.
void main() {
  group('HyperRenderDevtools.register', () {
    test('does not throw on first call', () {
      expect(HyperRenderDevtools.register, returnsNormally);
    });

    test('idempotent — second call is a no-op', () {
      expect(HyperRenderDevtools.register, returnsNormally);
      expect(HyperRenderDevtools.register, returnsNormally);
    });
  });
}
