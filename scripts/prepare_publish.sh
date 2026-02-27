#!/bin/bash
# Script to prepare package for pub.dev publication
# Usage: ./scripts/prepare_publish.sh

set -e

echo "🚀 Preparing HyperRender for pub.dev publication..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi

if ! command -v dart &> /dev/null; then
    echo -e "${RED}❌ Dart not found. Please install Dart first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites OK${NC}"

# Run tests
echo ""
echo "🧪 Running tests..."
flutter test || {
    echo -e "${RED}❌ Tests failed. Fix tests before publishing.${NC}"
    exit 1
}
echo -e "${GREEN}✅ All tests passed${NC}"

# Run analyzer
echo ""
echo "🔍 Running static analysis..."
flutter analyze --no-pub || {
    echo -e "${YELLOW}⚠️  Static analysis found issues. Review before publishing.${NC}"
}

# Check for path dependencies
echo ""
echo "🔗 Checking for path dependencies..."
if grep -q "path: packages/" pubspec.yaml; then
    echo -e "${YELLOW}⚠️  Found path dependencies in pubspec.yaml${NC}"
    echo ""
    echo "Do you want to use pubspec_publish_ready.yaml? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        cp pubspec.yaml pubspec.yaml.backup
        cp pubspec_publish_ready.yaml pubspec.yaml
        echo -e "${GREEN}✅ Updated pubspec.yaml (backup saved as pubspec.yaml.backup)${NC}"
    else
        echo -e "${YELLOW}⚠️  Please manually fix path dependencies before publishing${NC}"
    fi
fi

# Generate coverage
echo ""
echo "📊 Generating test coverage..."
flutter test --coverage || {
    echo -e "${YELLOW}⚠️  Coverage generation failed${NC}"
}

if [ -f "coverage/lcov.info" ]; then
    # Calculate coverage percentage (requires lcov tools)
    if command -v lcov &> /dev/null; then
        total_lines=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | cut -d'%' -f1)
        echo -e "${GREEN}📊 Test coverage: ${total_lines}%${NC}"

        if (( $(echo "$total_lines < 65" | bc -l) )); then
            echo -e "${YELLOW}⚠️  Coverage below 65% target${NC}"
        fi
    fi
fi

# Check documentation
echo ""
echo "📚 Checking documentation..."
missing_docs=0

if [ ! -f "README.md" ]; then
    echo -e "${RED}❌ README.md missing${NC}"
    missing_docs=1
fi

if [ ! -f "CHANGELOG.md" ]; then
    echo -e "${YELLOW}⚠️  CHANGELOG.md missing${NC}"
fi

if [ ! -f "LICENSE" ]; then
    echo -e "${RED}❌ LICENSE file missing${NC}"
    missing_docs=1
fi

if [ $missing_docs -eq 0 ]; then
    echo -e "${GREEN}✅ Documentation OK${NC}"
fi

# Dry run publish
echo ""
echo "🔍 Running dry-run publish..."
dart pub publish --dry-run || {
    echo -e "${RED}❌ Dry-run publish failed. Fix issues before publishing.${NC}"
    exit 1
}

echo ""
echo -e "${GREEN}✅ Package is ready for publication!${NC}"
echo ""
echo "Next steps:"
echo "1. Review all changes"
echo "2. Update version in pubspec.yaml if needed"
echo "3. Update CHANGELOG.md with release notes"
echo "4. Run: dart pub publish"
echo ""
echo -e "${YELLOW}Note: Make sure all sub-packages are published first:${NC}"
echo "  - hyper_render_core"
echo "  - hyper_render_html"
echo "  - hyper_render_markdown"
echo "  - hyper_render_highlight"
