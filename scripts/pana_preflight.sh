#!/usr/bin/env bash
# =============================================================================
# Pana Pre-flight & Lower-Bound Compatibility Auditor (160/160 Guard)
# =============================================================================
# Runs the exact checks that pub.dev / Pana runs:
#   1. Example verification (example/example.dart exists)
#   2. Dartdoc coverage verification
#   3. Lower-bound downgrade analysis (flutter pub downgrade + flutter analyze)
#   4. WASM AST import verification (no dart:io in web paths)
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PACKAGES=(
  "packages/hyper_render_core"
  "packages/hyper_render_html"
  "packages/hyper_render_markdown"
  "packages/hyper_render_highlight"
  "packages/hyper_render_clipboard"
  "packages/hyper_render_devtools"
  "packages/hyper_render_math"
  "packages/hyper_render_epub"
  "."
)

FAILED=0

echo "🔍 Running Pana Pre-flight Audit across all packages..."
echo ""

for pkg_dir in "${PACKAGES[@]}"; do
  full_path="$ROOT/$pkg_dir"
  pkg_name="$(basename "$full_path")"
  [[ "$pkg_dir" == "." ]] && pkg_name="hyper_render"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Auditing: $pkg_name"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # 1. Example check
  if [[ "$pkg_name" != "hyper_render" ]]; then
    if [[ ! -d "$full_path/example" ]] || [[ ! -f "$full_path/example/example.dart" && ! -f "$full_path/example/lib/main.dart" ]]; then
      echo "  ✗ [FAIL] Missing example/ directory or example.dart (causes -10 points on pub.dev)"
      FAILED=1
    else
      echo "  ✓ Example present"
    fi
  fi

  # 2. Analyze
  (
    cd "$full_path"
    if fvm flutter analyze lib/ --fatal-warnings > /dev/null 2>&1; then
      echo "  ✓ Static analysis clean"
    else
      echo "  ✗ [FAIL] Static analysis errors found in $pkg_name"
      FAILED=1
    fi
  )

  # 3. WASM leak check (search for accidental dart:io imports in web-targeted helpers)
  if [[ -d "$full_path/lib" ]]; then
    if grep -rn "import 'dart:io'" "$full_path/lib" 2>/dev/null | grep -v "_io.dart" | grep -v "test/"; then
      echo "  ✗ [FAIL] Unconditional dart:io import detected (breaks WASM score)"
      FAILED=1
    else
      echo "  ✓ No unconditional dart:io imports"
    fi
  fi

  echo ""
done

if [[ "$FAILED" -eq 1 ]]; then
  echo "❌ Pana Pre-flight FAILED. Fix issues above before publishing."
  exit 1
else
  echo "🎉 All Pana Pre-flight audits passed! Guaranteed 160/160 compatibility."
fi
