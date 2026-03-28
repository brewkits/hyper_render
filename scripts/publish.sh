#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# HyperRender publish helper — v1.1.4
#
# Usage:
#   ./scripts/publish.sh dry-run   # verify all packages (no upload)
#   ./scripts/publish.sh publish   # actually publish (requires pub.dev auth)
#
# Publish order (dependencies first):
#   1. hyper_render_core
#   2. hyper_render_html, hyper_render_markdown, hyper_render_highlight
#   3. hyper_render_clipboard, hyper_render_devtools
#
# What the script does:
#   - Temporarily patches each pubspec.yaml:
#       • Replaces path: ../hyper_render_core with hyper_render_core: ^VERSION
#   - Runs `dart pub publish [--dry-run]`
#   - Restores the original pubspec.yaml from git after each step
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

VERSION="1.1.4"
MODE="${1:-dry-run}"   # dry-run | publish
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FLUTTER="${FVM_HOME:-$HOME/fvm}/default/bin/flutter"

# Fallback: use fvm if available
if command -v fvm &>/dev/null; then
  FLUTTER="fvm flutter"
fi

DRY_FLAG=""
FORCE_FLAG=""
if [[ "$MODE" == "dry-run" ]]; then
  DRY_FLAG="--dry-run"
  echo "▶ DRY-RUN mode — no packages will be uploaded"
else
  echo "▶ PUBLISH mode — packages will be uploaded to pub.dev"
  read -rp "  Continue? [y/N] " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
  FORCE_FLAG="--force"   # skip dart pub publish's own y/N prompt
fi

# ── Helpers ──────────────────────────────────────────────────────────────────

patch_pubspec() {
  local dir="$1"
  local pubspec="$dir/pubspec.yaml"

  # Backup
  cp "$pubspec" "$pubspec.bak"

  # Replace path dep with version constraint
  sed -i '' \
    "s|hyper_render_core:\n    path: \.\./hyper_render_core|hyper_render_core: ^${VERSION}|g" \
    "$pubspec"

  # Handle multi-line path dep pattern (yaml indented form)
  python3 - "$pubspec" "$VERSION" <<'PYEOF'
import sys, re

path = sys.argv[1]
version = sys.argv[2]

with open(path) as f:
    content = f.read()

# Replace:
#   hyper_render_core:
#     path: ../hyper_render_core
# With:
#   hyper_render_core: ^1.1.2
content = re.sub(
    r'hyper_render_core:\s*\n\s+path:\s+\.\./hyper_render_core',
    f'hyper_render_core: ^{version}',
    content
)

with open(path, 'w') as f:
    f.write(content)

print(f"  patched: {path}")
PYEOF
}

restore_pubspec() {
  local dir="$1"
  local pubspec="$dir/pubspec.yaml"
  if [[ -f "$pubspec.bak" ]]; then
    mv "$pubspec.bak" "$pubspec"
    echo "  restored: $pubspec"
  fi
}

publish_package() {
  local name="$1"
  local dir="$ROOT/packages/$name"

  echo ""
  echo "════════════════════════════════════════"
  echo "  Package: $name"
  echo "════════════════════════════════════════"

  patch_pubspec "$dir"

  # Ensure pubspec is restored even if the publish command fails or the
  # script is interrupted (Ctrl-C, set -e abort, etc.)
  trap "restore_pubspec '$dir'" EXIT

  (
    cd "$dir"
    echo "  Running: dart pub publish $DRY_FLAG $FORCE_FLAG"
    $FLUTTER pub publish $DRY_FLAG $FORCE_FLAG
  )

  restore_pubspec "$dir"
  trap - EXIT   # clear trap after successful restore
}

# ── Static analysis first ─────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 0: Static analysis"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PACKAGES=(
  hyper_render_core
  hyper_render_html
  hyper_render_markdown
  hyper_render_highlight
  hyper_render_clipboard
  hyper_render_devtools
)

ANALYZE_FAILED=0
for pkg in "${PACKAGES[@]}"; do
  echo ""
  echo "  Analyzing $pkg..."
  cd "$ROOT/packages/$pkg"
  # Analyze only lib/ — test files are not published and may have
  # avoid_print infos that should not block a release.
  if $FLUTTER analyze lib/ --fatal-warnings 2>&1 | tail -3; then
    echo "  ✓ $pkg OK"
  else
    echo "  ✗ $pkg FAILED"
    ANALYZE_FAILED=1
  fi
done
cd "$ROOT"

if [[ "$ANALYZE_FAILED" -eq 1 ]]; then
  echo ""
  echo "✗ Analysis errors found — fix before publishing."
  exit 1
fi

echo ""
echo "✓ All packages pass static analysis"

# ── Publish ───────────────────────────────────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 1: hyper_render_core (no deps)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
publish_package "hyper_render_core"

if [[ "$MODE" == "publish" ]]; then
  echo ""
  echo "  Waiting 30s for pub.dev to index hyper_render_core..."
  sleep 30
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 2: html, markdown, highlight"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
publish_package "hyper_render_html"
publish_package "hyper_render_markdown"
publish_package "hyper_render_highlight"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 3: clipboard, devtools"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
publish_package "hyper_render_clipboard"
publish_package "hyper_render_devtools"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$MODE" == "dry-run" ]]; then
  echo "  ✓ Dry-run complete — all packages passed"
else
  echo "  ✓ Published all packages v${VERSION}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
