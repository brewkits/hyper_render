# Virtualized wrappers and publish staging verification

Date: 2026-11-06. No packages uploaded.

## Changes

- Both HTML adapters reconstruct wrapper ancestry per chunk, retaining CSS
  classes, inline styles and parent links. Single-child wrappers also split.
- Semantic article containers have block defaults in adapters and the core CSS
  resolver. The default sanitizer preserves `main`.
- Publishing stages each package outside the checkout, strips local overrides
  only in the staged copy, and analyzes all nine packages without updating local
  dependencies. Dry-run errors propagate and temporary directories are cleaned.

## Results

| Check | Result |
| --- | --- |
| Root `flutter test --no-pub` | 1,948 passed; 27 existing golden failures |
| Core `flutter test --no-pub` | 814 passed |
| HTML `flutter test --no-pub` | 74 passed |
| `python3 scripts/tests/test_publish.py` | 3 passed (including validation-failure subcases) |
| `bash scripts/publish.sh dry-run` | All 9 archives nonempty, all 9 validations report 0 warnings; static analysis clean |
| `bash -n scripts/publish.sh` / `git diff --check` | Passed |

The wrapper tests cover auto and explicit virtualized modes at 400, 240 and
180 px, before and after scrolling to later chunks. They verify paragraph order
and completeness, nested ancestry, centering and parent padding.

Golden failures were reproduced from a separate clean `git archive HEAD` copy
using the same SDK and dependency configuration. All 27 rendered failure images
are byte-identical between HEAD and the changed checkout. Golden baselines were
not updated.

`example/pubspec.lock` remains byte-identical to the snapshot taken before this
completion pass; its pre-existing local changes were retained.

## Remaining scope

Chunk wrappers remain separate boxes: vertical spacing and decorations repeat
at boundaries, and structural selectors see only the siblings in each chunk.
See `../LIMITATIONS.md`. Continuous decorated wrappers require sync mode.

This verification does not publish a new version or change package versions.
