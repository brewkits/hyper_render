#!/bin/bash
echo "🚀 Running tests for all packages..."
# Tìm tất cả thư mục chứa pubspec.yaml và chạy test
for dir in $(find packages -name "pubspec.yaml" -exec dirname {} \;); do
  echo "🧪 Testing $dir..."
  (cd "$dir" && fvm flutter test)
done
echo "✅ All tests completed."
