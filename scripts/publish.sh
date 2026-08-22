#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# HyperRender publish helper — v1.3.3
#
# Usage:
#   ./scripts/publish.sh dry-run   # verify all packages (no upload)
#   ./scripts/publish.sh publish   # actually publish (requires pub.dev auth)
#
# Publish order (dependencies first):
#   1. hyper_render_core
#   2. hyper_render_html, hyper_render_markdown, hyper_render_highlight
#   3. hyper_render_clipboard, hyper_render_devtools, hyper_render_math
#   4. hyper_render (root wrapper)
#
# Strategy:
#   Each pubspec.yaml already has version deps (e.g. hyper_render_core: ^1.3.2)
#   in `dependencies:`. The `dependency_overrides:` block redirects to local
#   paths for monorepo dev. Before publishing each package, we remove the
#   `dependency_overrides:` block, run `dart pub publish`, then restore the
#   pubspec from git.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

VERSION="1.7.0"
MODE="${1:-dry-run}"   # dry-run | publish
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Use fvm if available, otherwise fall back to system flutter
if command -v fvm &>/dev/null; then
  FLUTTER="fvm flutter"
else
  FLUTTER="flutter"
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

# Remove the dependency_overrides: block from a pubspec.yaml.
# The block starts with "^dependency_overrides:" and includes all indented
# lines beneath it, up to the next top-level key or EOF.
_remove_overrides() {
  local f="$1"
  if [ -f "$f" ] && grep -q "^dependency_overrides:" "$f"; then
    python3 - "$f" <<'PYEOF'
import re, sys
with open(sys.argv[1]) as fh:
    content = fh.read()
# Remove dependency_overrides block: top-level key + all following indented/blank lines
content = re.sub(
    r'\ndependency_overrides:\n(?:[ \t]+[^\n]*\n|\n)*',
    '\n',
    content,
)
with open(sys.argv[1], 'w') as fh:
    fh.write(content)
PYEOF
    echo "  ✓ Removed dependency_overrides from $f"
  fi
}

# Remove publish_to: none if present
_remove_publish_to_none() {
  local f="$1"
  if [ -f "$f" ] && grep -q "^publish_to: none" "$f"; then
    sed -i '' '/^publish_to: none/d' "$f" 2>/dev/null || sed -i '/^publish_to: none/d' "$f"
    echo "  ✓ Removed publish_to: none from $f"
  fi
}

# Restore a pubspec.yaml from git (undo all local modifications)
_restore_pubspec() {
  local f="$1"
  git checkout -- "$f" 2>/dev/null && echo "  ✓ Restored $f" || true
}

publish_package() {
  local name="$1"
  local dir="$ROOT/packages/$name"
  local pubspec="$dir/pubspec.yaml"

  echo ""
  echo "════════════════════════════════════════"
  echo "  Package: $name"
  echo "════════════════════════════════════════"

  _remove_overrides "$pubspec"
  _remove_publish_to_none "$pubspec"

  # Ensure restore even on failure
  trap "_restore_pubspec '$pubspec'" EXIT

  (
    cd "$dir"
    echo "  Running: $FLUTTER pub publish $DRY_FLAG $FORCE_FLAG"
    set +e
    output=$($FLUTTER pub publish $DRY_FLAG $FORCE_FLAG 2>&1)
    exit_code=$?
    echo "$output"
    if [[ $exit_code -ne 0 ]]; then
      if echo "$output" | grep -q "already exists"; then
        echo "  ℹ Package $name version already published on pub.dev, continuing..."
      else
        exit $exit_code
      fi
    fi
  )

  _restore_pubspec "$pubspec"
  trap - EXIT
}

publish_root() {
  local pubspec="$ROOT/pubspec.yaml"

  echo ""
  echo "════════════════════════════════════════"
  echo "  Package: hyper_render (root)"
  echo "════════════════════════════════════════"

  _remove_overrides "$pubspec"
  _remove_publish_to_none "$pubspec"

  trap "_restore_pubspec '$pubspec'" EXIT

  (
    cd "$ROOT"
    echo "  Running: $FLUTTER pub publish $DRY_FLAG $FORCE_FLAG"
    set +e
    output=$($FLUTTER pub publish $DRY_FLAG $FORCE_FLAG 2>&1)
    exit_code=$?
    echo "$output"
    if [[ $exit_code -ne 0 ]]; then
      if echo "$output" | grep -q "already exists"; then
        echo "  ℹ Package hyper_render version already published on pub.dev, continuing..."
      else
        exit $exit_code
      fi
    fi
  )

  _restore_pubspec "$pubspec"
  trap - EXIT
}

# ── Static analysis ───────────────────────────────────────────────────────────

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
  hyper_render_math
  hyper_render_epub
)

ANALYZE_FAILED=0
for pkg in "${PACKAGES[@]}"; do
  echo ""
  echo "  Analyzing $pkg..."
  cd "$ROOT/packages/$pkg"
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
  echo "  Waiting 120s for pub.dev to index hyper_render_core..."
  sleep 120
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
echo "  Step 3: clipboard, devtools, math"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
publish_package "hyper_render_clipboard"
publish_package "hyper_render_devtools"
publish_package "hyper_render_math"

if [[ "$MODE" == "publish" ]]; then
  echo ""
  echo "  Waiting 30s for pub.dev to index all sub-packages..."
  sleep 30
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 4: hyper_render (root wrapper)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
publish_root

if [[ "$MODE" == "publish" ]]; then
  echo ""
  echo "  Waiting 30s for pub.dev to index hyper_render..."
  sleep 30
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Step 5: hyper_render_epub (depends on root)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
publish_package "hyper_render_epub"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$MODE" == "dry-run" ]]; then
  echo "  ✓ Dry-run complete — all packages passed"
else
  echo "  ✓ Published all packages v${VERSION}"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
