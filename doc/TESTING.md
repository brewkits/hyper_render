# Testing

How HyperRender is tested, where each kind of test lives, and how to run it.

## Commands

```bash
# Everything that gates a release (root + core, goldens excluded)
flutter test test/ packages/hyper_render_core/test/ --exclude-tags golden

# Publish staging and failure handling (fake Flutter; never uploads)
python3 scripts/tests/test_publish.py

# One file / one test
flutter test test/line_breaking_regression_test.dart
flutter test test/html_adapter_test.dart --plain-name 'parses links'

# Sub-packages the root does not depend on run from inside the package
(cd packages/hyper_render_html && flutter test)      # also _markdown, _highlight, _math, _epub, _clipboard, _devtools
(cd packages/hyper_render_devtools/devtools_ui && flutter test --platform chrome)

# The line-breaking suites also run on the web (native ICU line breaking)
flutter test --platform chrome test/line_breaking_regression_test.dart \
  test/line_breaking_perf_and_parity_test.dart test/line_breaking_stress_test.dart \
  test/fuzz/layout_fuzz_test.dart

# Demo app: 44 widget tests, then every demo screen on a real device
(cd example && flutter test)
(cd example && flutter test integration_test/all_demos_test.dart -d macos)

# Coverage across root, core and the other in-repo packages
flutter test --coverage --coverage-package='hyper_render_core|hyper_render' \
  test/ packages/hyper_render_core/test/ --exclude-tags golden
```

## What lives where

| Kind | What it proves | Where |
|---|---|---|
| **Unit** | One class or function in isolation: CSS parsing and resolution, adapters, fragments, selection maths | `packages/hyper_render_core/test/`, `test/*_test.dart` (parsers, `html_adapter_test`, `css_*`, `text_breaking_test`, …) |
| **Integration** | Several layers together on realistic content | `test/integration/` (real-world HTML, selection, lifecycle, error recovery, dark mode), `test/integration_test*.dart` |
| **System** | The whole app and pixels | `test/golden/` (pixel tests, CI-only), `example/integration_test/all_demos_test.dart` (opens every demo screen, fails on any `FlutterError`) |
| **Performance** | Cost does not grow faster than it should | `test/line_breaking_perf_and_parity_test.dart` (counts `TextPainter` layouts, checks N→2N scaling; no clock), `test/integration/performance_*`, `test/streaming_engine_benchmark_test.dart`, `packages/hyper_render_core/test/*performance*`, `benchmark/` |
| **Stress** | Very large or degenerate input terminates and stays correct | `test/line_breaking_stress_test.dart` (200 000-character paragraphs, zero-width and 1 px boxes, padding or floats wider than the container, narrow glyphs), `test/hyper_render_stress_test.dart`, `test/integration/large_document_test.dart`, `cjk_stress_test.dart`, `animation_v150_stress_test.dart` |
| **Security** | Hostile input cannot execute, escape, or hang the parser | `test/html_sanitizer_test.dart` (incl. ReDoS timing), `test/hyper_render_security_test.dart`, `test/security_edge_cases_test.dart`, `test/integration/*security*`, `url_safety` tests, `stylesheet_var_security_test.dart` |
| **Fuzz** | Mutated input never throws or hangs | `test/fuzz/parser_fuzz_test.dart` (parse only), `test/fuzz/layout_fuzz_test.dart` (lays mutants out at widths 0, 1, 37 and 300) |
| **Docs sync** | The CSS matrix never over-claims | `test/docs_matrix_sync_test.dart` |

## Conventions that have caught real bugs

- **Test the behavior, not that nothing threw.** A 0×0 widget satisfies
  `findsOneWidget`; assert sizes, line positions or pixels.
- **Mutation-check new regression tests.** Revert the fix and confirm the test
  fails. Several tests in this repo were written to a passing state that did not
  actually exercise the code.
- **Flutter's test font (Ahem) makes every glyph 1 em wide.** That hides any bug
  that depends on narrow glyphs; `TextScaler.linear(0.5)` is the way to reach
  them (see `line_breaking_stress_test.dart`). Real-font checks need a device.
- **Layout assertions use `debugLineFragments()`**, which reports the position
  and character range each fragment actually has on its line.
- **Prefer counts and ratios to wall-clock thresholds.** Performance tests that
  compare milliseconds flake on shared CI runners.
- **A synchronous hang cannot be interrupted by the test timeout.** A breaker
  regression that turns linear work quadratic blocks the isolate until the CI job
  timeout rather than failing cleanly.
- **Goldens only match on the CI runner** (pinned Ubuntu image, Flutter version
  and fonts). Do not regenerate them locally: run the `Visual Regression`
  workflow with `workflow_dispatch`, then review every changed image next to
  its previous version before accepting it.
- **Repo tests cannot catch a missing export** from the root barrel
  (`lib/hyper_render.dart`), because they resolve through `dependency_overrides`.
  After publishing, install the real packages into a throwaway project and
  analyze code that names every new public type.
