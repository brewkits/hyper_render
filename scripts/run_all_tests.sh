#!/bin/bash
echo "🚀 Running tests for all packages..."
# Find all directories containing pubspec.yaml and run tests
for dir in $(find packages -name "pubspec.yaml" -exec dirname {} \;); do
  echo "🧪 Testing $dir..."
  (cd "$dir" && fvm flutter test)
done
echo "✅ All tests completed."
