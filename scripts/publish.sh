#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# HyperRender publish helper
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
#   5. hyper_render_epub (depends on root)
#
# Strategy:
#   Stage each package outside the checkout so ancestor .pubignore rules do not
#   exclude packages/*. Strip local overrides only in the disposable copy.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODE="${1:-dry-run}"   # dry-run | publish
case "$MODE" in
  dry-run|publish) ;;
  *) echo "Usage: $0 {dry-run|publish}" >&2; exit 2 ;;
esac

STAGING_ROOT=""
_cleanup() {
  if [[ -n "$STAGING_ROOT" ]]; then
    rm -rf -- "$STAGING_ROOT"
  fi
}
trap _cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

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
    r'(?m)^dependency_overrides:[^\n]*\n(?:(?:[ \t]+[^\n]*|\s*|#[^\n]*)\n)*',
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

# Copy only the requested package to a directory outside the Git checkout.
# Keep its own ignore files; pub will apply them when building the archive.
_stage_package() {
  local source="$1"
  local name="$2"
  if [[ -z "$STAGING_ROOT" ]]; then
    STAGING_ROOT="$(mktemp -d /tmp/hyper-render-publish.XXXXXX)"
  fi
  STAGED_DIR="$STAGING_ROOT/$name"
  mkdir -p "$STAGED_DIR"
  rsync -a --exclude='.git/' --exclude='.dart_tool/' --exclude='/build/' --exclude='/example/build/' \
    --exclude='pubspec_overrides.yaml' --exclude='/packages/' \
    "$source/" "$STAGED_DIR/"
  _remove_overrides "$STAGED_DIR/pubspec.yaml"
  _remove_publish_to_none "$STAGED_DIR/pubspec.yaml"
}

publish_package() {
  local name="$1"
  local source="${2:-$ROOT/packages/$name}"
  echo ""
  echo "  Package: $name"
  _stage_package "$source" "$name"
  (
    cd "$STAGED_DIR"
    echo "  Running: $FLUTTER pub publish $DRY_FLAG $FORCE_FLAG"
    set +e
    output=$($FLUTTER pub publish $DRY_FLAG $FORCE_FLAG 2>&1)
    exit_code=$?
    echo "$output"
    if [[ $exit_code -ne 0 ]]; then
      if [[ "$MODE" == "publish" ]] && echo "$output" | grep -q "already exists"; then
        echo "  ℹ Package $name version already published on pub.dev, continuing..."
      else
        exit "$exit_code"
      fi
    fi
  )
}

publish_root() {
  publish_package "hyper_render" "$ROOT"
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
  if $FLUTTER analyze --no-pub lib/ --fatal-warnings 2>&1 | tail -3; then
    echo "  ✓ $pkg OK"
  else
    echo "  ✗ $pkg FAILED"
    ANALYZE_FAILED=1
  fi
done
cd "$ROOT"
echo ""
echo "  Analyzing hyper_render..."
if $FLUTTER analyze --no-pub lib/ --fatal-warnings 2>&1 | tail -3; then
  echo "  ✓ hyper_render OK"
else
  echo "  ✗ hyper_render FAILED"
  ANALYZE_FAILED=1
fi

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
  echo "  ✓ Publish run complete (already-published versions were skipped)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
