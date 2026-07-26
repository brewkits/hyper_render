#!/usr/bin/env bash

# ==============================================================================
# Monorepo Publishing & Static Analysis Audit Script
# Verifies that root package and all 7 subpackages pass 'flutter analyze'
# and 'flutter pub publish --dry-run' with 0 warnings.
# ==============================================================================

set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "🚀 Starting Monorepo Publishing Audit at $ROOT_DIR"
echo "============================================================"

FAILED_PACKAGES=()

audit_package() {
  local pkg_path="$1"
  local pkg_name="$2"

  echo ""
  echo "📦 Auditing: $pkg_name ($pkg_path)"
  echo "------------------------------------------------------------"

  cd "$pkg_path"

  echo "  🔍 [1/2] Running static analysis..."
  if ! flutter analyze --no-pub --fatal-warnings --fatal-infos; then
    echo "  ❌ Static analysis failed for $pkg_name"
    FAILED_PACKAGES+=("$pkg_name (analyze)")
    return 1
  fi
  echo "  ✅ Static analysis passed."

  echo "  📦 [2/2] Running pub publish dry-run..."
  if ! flutter pub publish --dry-run; then
    echo "  ❌ Pub publish dry-run failed for $pkg_name"
    FAILED_PACKAGES+=("$pkg_name (pub publish)")
    return 1
  fi
  echo "  ✅ Pub publish dry-run passed."
}

# 1. Audit root package
audit_package "$ROOT_DIR" "hyper_render (root)"

# 2. Audit subpackages under packages/
for pkg_dir in "$ROOT_DIR"/packages/*; do
  if [ -d "$pkg_dir" ] && [ -f "$pkg_dir/pubspec.yaml" ]; then
    pkg_basename=$(basename "$pkg_dir")
    audit_package "$pkg_dir" "$pkg_basename"
  fi
done

echo ""
echo "============================================================"
if [ ${#FAILED_PACKAGES[@]} -eq 0 ]; then
  echo "🎉 MONOREPO PUBLISHING AUDIT SUCCESS: All packages passed with 0 warnings!"
  exit 0
else
  echo "💥 MONOREPO PUBLISHING AUDIT FAILED for: ${FAILED_PACKAGES[*]}"
  exit 1
fi
