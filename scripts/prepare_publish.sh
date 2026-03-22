#!/bin/bash
# Prepare HyperRender for pub.dev publication.
# Usage: ./scripts/prepare_publish.sh
#
# Publish order (sub-packages FIRST, then root):
#   1. hyper_render_core
#   2. hyper_render_html
#   3. hyper_render_markdown
#   4. hyper_render_highlight
#   5. hyper_render (root)

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
flutter test || fail "Tests failed. Fix before publishing."
ok "All tests passed"

# ── 2. Static analysis ───────────────────────────────────────────────────────
step "Static analysis..."
result=$(flutter analyze --no-pub 2>&1)
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

# ── 5. pubspec swap ──────────────────────────────────────────────────────────
step "Swapping pubspec.yaml for pub.dev..."
if grep -q "path: packages/" pubspec.yaml; then
  cp pubspec.yaml pubspec.yaml.backup
  cp pubspec_publish_ready.yaml pubspec.yaml
  ok "pubspec.yaml swapped from publish_ready template (backup saved)"
else
  ok "pubspec.yaml already has version deps"
fi

# Remove publish_to: none from root and all sub-packages
for f in pubspec.yaml \
          packages/hyper_render_core/pubspec.yaml \
          packages/hyper_render_html/pubspec.yaml \
          packages/hyper_render_markdown/pubspec.yaml \
          packages/hyper_render_highlight/pubspec.yaml \
          packages/hyper_render_clipboard/pubspec.yaml; do
  if [ -f "$f" ] && grep -q "^publish_to: none" "$f"; then
    # BSD sed (macOS) needs '' after -i; GNU sed does not
    sed -i '' '/^publish_to: none/d' "$f" 2>/dev/null || sed -i '/^publish_to: none/d' "$f"
    ok "Removed 'publish_to: none' from $f"
  fi
done

# ── 6. Verify no path: deps remain ──────────────────────────────────────────
step "Verifying path: dependencies removed..."
if grep -q "path:" pubspec.yaml; then
  fail "pubspec.yaml still has path: deps. Check manually."
fi
ok "No path: dependencies in root pubspec"

# ── 7. dart pub publish --dry-run ────────────────────────────────────────────
step "Running dart pub publish --dry-run..."
dart pub publish --dry-run 2>&1 | tee /tmp/hr_dry_run.txt || {
  path_errors=$(grep -c "path dependency" /tmp/hr_dry_run.txt 2>/dev/null || true)
  if [ "$path_errors" -gt 0 ]; then
    warn "Dry-run shows path-dep errors — expected until sub-packages are on pub.dev"
  else
    fail "Dry-run failed unexpectedly. Check /tmp/hr_dry_run.txt"
  fi
}
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
echo "    5. dart pub publish    (from repo root)"
echo ""
echo -e "${YELLOW}  After publishing, restore dev pubspec:${NC}"
echo "    cp pubspec.yaml.backup pubspec.yaml"
echo ""
