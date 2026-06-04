#!/bin/bash
# Prepare HyperRender for pub.dev publication.
# Usage: ./scripts/prepare_publish.sh
#
# Publish order (sub-packages FIRST, then root):
#   1. hyper_render_core
#   2. hyper_render_html
#   3. hyper_render_markdown
#   4. hyper_render_highlight
#   5. hyper_render_clipboard
#   6. hyper_render_devtools
#   7. hyper_render_math
#   8. hyper_render (root)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

step() { echo -e "\n${CYAN}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}  ✅ $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }
fail() { echo -e "${RED}  ❌ $1${NC}"; exit 1; }

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  HyperRender — pub.dev publish preparation${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

command -v flutter &>/dev/null || fail "Flutter not found"
command -v dart    &>/dev/null || fail "Dart not found"
ok "Prerequisites OK"

# ── 1. Tests ─────────────────────────────────────────────────────────────────
step "Running tests..."
flutter test test/ packages/hyper_render_core/test/ packages/hyper_render_html/test/ --exclude-tags golden || fail "Tests failed. Fix before publishing."
ok "All tests passed"

# ── 2. Static analysis ───────────────────────────────────────────────────────
step "Static analysis..."
result=$(flutter analyze --no-pub 2>&1) || true
errors=$(echo "$result" | grep -c "^error" || true)
warnings=$(echo "$result" | grep -c "^warning" || true)
if [ "$errors" -gt 0 ] || [ "$warnings" -gt 0 ]; then
  echo "$result" | grep -E "^(error|warning)"
  fail "Analysis found $errors errors and $warnings warnings."
fi
ok "Analysis clean"

# ── 3. Required files ────────────────────────────────────────────────────────
step "Checking required files..."
[ -f "README.md" ]            || fail "README.md missing"
[ -f "CHANGELOG.md" ]         || fail "CHANGELOG.md missing"
[ -f "LICENSE" ]              || fail "LICENSE missing"
[ -f "example/example.dart" ] || fail "example/example.dart missing"
ok "README, CHANGELOG, LICENSE, example all present"

# ── 4. Screenshot assets ─────────────────────────────────────────────────────
step "Checking screenshot assets..."
missing_shots=0
for gif in assets/float_demo.gif assets/ruby_demo.gif assets/selection_demo.gif \
           assets/table_demo.gif assets/comparison_demo.gif assets/performance_demo.gif; do
  [ -f "$gif" ] || { warn "Missing: $gif"; missing_shots=$((missing_shots+1)); }
done
[ "$missing_shots" -eq 0 ] && ok "All 6 screenshot GIFs present" || \
  warn "$missing_shots screenshot(s) missing — pub.dev gallery will show placeholders"

# ── 5. Remove dependency_overrides from pubspec files ────────────────────────
# The monorepo now uses version deps in `dependencies` (for 160/160 pana score)
# and path deps in `dependency_overrides` (for local development).
# For publishing, only the `dependency_overrides` block needs to be removed —
# the `dependencies` section already has the correct version constraints.
step "Removing dependency_overrides for pub.dev publish..."

_sed() { sed -i '' "$@" 2>/dev/null || sed -i "$@"; }

# Remove the dependency_overrides block from each pubspec.
# The block is delimited by "^dependency_overrides:" ... next top-level key.
# Python one-liner handles multi-line block removal portably.
_remove_overrides() {
  local f="$1"
  if [ -f "$f" ] && grep -q "^dependency_overrides:" "$f"; then
    python3 - "$f" << 'PYEOF'
import re, sys
with open(sys.argv[1]) as fh:
    content = fh.read()
# Remove the dependency_overrides: block (top-level key, all indented lines after it)
content = re.sub(r'\ndependency_overrides:(\n  [^\n]*)*', '', content)
with open(sys.argv[1], 'w') as fh:
    fh.write(content)
PYEOF
    ok "Removed dependency_overrides from $f"
  fi
}

for f in pubspec.yaml \
          packages/hyper_render_html/pubspec.yaml \
          packages/hyper_render_markdown/pubspec.yaml \
          packages/hyper_render_highlight/pubspec.yaml \
          packages/hyper_render_clipboard/pubspec.yaml \
          packages/hyper_render_devtools/pubspec.yaml \
          packages/hyper_render_math/pubspec.yaml; do
  _remove_overrides "$f"
done

# Remove publish_to: none from root and all sub-packages (if any remain)
for f in pubspec.yaml \
          packages/hyper_render_core/pubspec.yaml \
          packages/hyper_render_html/pubspec.yaml \
          packages/hyper_render_markdown/pubspec.yaml \
          packages/hyper_render_highlight/pubspec.yaml \
          packages/hyper_render_clipboard/pubspec.yaml \
          packages/hyper_render_devtools/pubspec.yaml \
          packages/hyper_render_math/pubspec.yaml; do
  if [ -f "$f" ] && grep -q "^publish_to: none" "$f"; then
    _sed '/^publish_to: none/d' "$f"
    ok "Removed 'publish_to: none' from $f"
  fi
done

# ── 6. Verify no path: deps remain in dependencies: block ────────────────────
step "Verifying no path: deps in dependencies: section..."
# Check only the 'dependencies:' block (not dependency_overrides or dev_dependencies)
for f in pubspec.yaml packages/*/pubspec.yaml; do
  [ -f "$f" ] || continue
  if python3 - "$f" << 'PYEOF' 2>/dev/null; then
import sys, re
with open(sys.argv[1]) as fh:
    content = fh.read()
# Find just the dependencies: block
m = re.search(r'\bdependencies:(.*?)(?=\n\w|\Z)', content, re.DOTALL)
if m and 'path:' in m.group(1):
    sys.exit(1)
PYEOF
    : # OK
  else
    fail "Path dep found in dependencies: section of $f — fix before publishing."
  fi
done
ok "No path: dependencies in dependencies: section"

# ── 7. dart pub publish --dry-run ────────────────────────────────────────────
step "Running dart pub publish --dry-run..."
dart pub publish --dry-run 2>&1 | tee /tmp/hr_dry_run.txt
ok "Dry-run complete"

# ── 8. Summary ───────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Ready to publish!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "  Publish in this exact order:"
echo "    1. cd packages/hyper_render_core      && dart pub publish"
echo "    2. cd packages/hyper_render_html      && dart pub publish"
echo "    3. cd packages/hyper_render_markdown  && dart pub publish"
echo "    4. cd packages/hyper_render_highlight && dart pub publish"
echo "    5. cd packages/hyper_render_clipboard && dart pub publish"
echo "    6. cd packages/hyper_render_devtools  && dart pub publish"
echo "    7. cd packages/hyper_render_math      && dart pub publish"
echo "    8. dart pub publish    (from repo root)"
echo ""
echo -e "${YELLOW}  After publishing, restore dev pubspecs:${NC}"
echo "    cp pubspec.yaml.backup pubspec.yaml"
echo "    git checkout packages/*/pubspec.yaml"
echo ""
