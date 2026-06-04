#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "========================================="
echo "  HyperRender Publish Preparation Script "
echo "========================================="

echo "=> Fetching dependencies for root..."
flutter pub get

echo "=> Fetching dependencies for all sub-packages..."
for dir in packages/*; do
  if [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ]; then
    echo "   -> $dir"
    (cd "$dir" && flutter pub get)
  fi
done

echo "=> Fetching dependencies for example app..."
(cd example && flutter pub get)

echo ""
echo "=> Formatting code..."
dart format .

echo ""
echo "=> Running static analysis..."
flutter analyze --fatal-warnings

echo ""
echo "=> Running tests with coverage..."
# Run the test suite. Golden tests are run without the --update-goldens flag.
flutter test --coverage

echo ""
echo "=> Building example demo app (APK)..."
(cd example && flutter build apk --debug)

echo "========================================="
echo "  SUCCESS! All checks passed.            "
echo "  The demo app has been built.           "
echo "  The project is ready for publishing!   "
echo "========================================="
