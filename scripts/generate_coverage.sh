#!/bin/bash
# Generate test coverage report for HyperRender
# Usage: ./scripts/generate_coverage.sh

set -e

echo "📊 Generating test coverage for HyperRender..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Clean previous coverage
rm -rf coverage/
echo "🧹 Cleaned previous coverage data"

# Run tests with coverage
echo ""
echo "🧪 Running tests with coverage..."
flutter test --coverage || {
    echo -e "${RED}❌ Tests failed${NC}"
    exit 1
}

# Check if coverage file exists
if [ ! -f "coverage/lcov.info" ]; then
    echo -e "${RED}❌ Coverage file not generated${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Coverage data generated${NC}"

# Generate HTML report (requires lcov tools)
if command -v genhtml &> /dev/null; then
    echo ""
    echo "📄 Generating HTML report..."
    genhtml coverage/lcov.info -o coverage/html --quiet
    echo -e "${GREEN}✅ HTML report generated at coverage/html/index.html${NC}"

    # Calculate coverage percentage
    if command -v lcov &> /dev/null; then
        echo ""
        echo "📈 Coverage Summary:"
        lcov --summary coverage/lcov.info 2>&1 | grep -E "lines|functions"

        # Extract line coverage percentage
        coverage=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | cut -d'%' -f1)

        echo ""
        if (( $(echo "$coverage >= 80" | bc -l) )); then
            echo -e "${GREEN}✅ Excellent coverage: ${coverage}%${NC}"
        elif (( $(echo "$coverage >= 65" | bc -l) )); then
            echo -e "${GREEN}✅ Good coverage: ${coverage}%${NC}"
        elif (( $(echo "$coverage >= 50" | bc -l) )); then
            echo -e "${YELLOW}⚠️  Acceptable coverage: ${coverage}%${NC}"
        else
            echo -e "${RED}❌ Low coverage: ${coverage}%${NC}"
            echo -e "${YELLOW}   Target: 65%+ overall, 80%+ for core${NC}"
        fi
    fi

    # Open in browser (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo ""
        echo "Opening coverage report in browser..."
        open coverage/html/index.html
    fi
else
    echo -e "${YELLOW}⚠️  lcov tools not installed${NC}"
    echo "Install with: brew install lcov (macOS) or apt-get install lcov (Linux)"
    echo ""
    echo "Coverage data available in: coverage/lcov.info"
fi

# Check for uncovered files
echo ""
echo "🔍 Checking for completely uncovered files..."
if command -v lcov &> /dev/null; then
    uncovered=$(lcov --summary coverage/lcov.info 2>&1 | grep " 0\.0%" | wc -l)
    if [ "$uncovered" -gt 0 ]; then
        echo -e "${RED}⚠️  Found $uncovered files with 0% coverage${NC}"
        echo "Run: lcov --list coverage/lcov.info | grep ' 0.0%'"
    else
        echo -e "${GREEN}✅ No files with 0% coverage${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Coverage generation complete!${NC}"
