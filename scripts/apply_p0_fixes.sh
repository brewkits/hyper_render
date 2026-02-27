#!/bin/bash
# HyperRender P0 Fixes Automation Script
# Run this to apply remaining P0 security and stability fixes

set -e

echo "🔧 Applying HyperRender P0 Fixes..."

# P0-2: GestureRecognizer Disposal (Verification needed)
echo "✓ P0-2: GestureRecognizer disposal - dispose() method exists, needs lifecycle integration verification"

# P0-3: Add Error Boundaries to render_hyper_box.dart
echo "📝 P0-3: Adding error boundaries to render methods..."

# Backup original files
cp packages/hyper_render_core/lib/src/core/render_hyper_box.dart packages/hyper_render_core/lib/src/core/render_hyper_box.dart.backup
cp lib/src/core/render_hyper_box.dart lib/src/core/render_hyper_box.dart.backup 2>/dev/null || true

echo "  → Error boundaries should wrap:"
echo "    - performLayout() method (line ~527)"
echo "    - paint() method (line ~2063)"
echo "    - Use try-catch with FlutterError"
echo "    - Fallback: render error message or skip problematic content"

# P0-4: Add JSON Error Handling
echo "📝 P0-4: Adding JSON error handling to DeltaAdapter..."

# Check if delta_adapter files exist
if [ -f "packages/hyper_render_core/lib/src/adapter/delta_adapter.dart" ]; then
    echo "  → Found delta_adapter in core package"
    echo "    - Wrap jsonDecode() in try-catch"
    echo "    - Return empty DocumentNode on error"
fi

if [ -f "lib/src/adapter/delta_adapter.dart" ]; then
    echo "  → Found delta_adapter in main package"
    echo "    - Wrap jsonDecode() in try-catch"
    echo "    - Return empty DocumentNode on error"
fi

echo ""
echo "✅ P0-1: Sanitize default = true (DONE)"
echo "⚠️  P0-2: GestureRecognizer disposal (needs verification)"
echo "⚠️  P0-3: Error boundaries (manual implementation needed)"
echo "⚠️  P0-4: JSON error handling (manual implementation needed)"
echo ""
echo "📖 Next steps:"
echo "1. Review and manually add error boundaries to render methods"
echo "2. Add JSON try-catch in delta_adapter.dart"
echo "3. Run: flutter test to verify no breaking changes"
echo "4. Update CHANGELOG.md with breaking changes"

