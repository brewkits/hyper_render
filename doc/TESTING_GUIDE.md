# Testing Guide - HyperRender v1.0.x

**Last Updated:** 2026-03-06
**Status:** ✅ Comprehensive Test Suite Available

---

## Overview

This guide covers all testing capabilities in HyperRender, from unit tests to physical device benchmarks.

**Test Coverage:**
- ✅ **42+ unit test files** - Core functionality
- ✅ **8 integration test suites** - End-to-end workflows
- ✅ **2 benchmark tools** - Performance validation
- ✅ **Cross-platform validation** - iOS, Android, Desktop

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Unit Tests](#unit-tests)
3. [Integration Tests](#integration-tests)
4. [Physical Device Testing](#physical-device-testing)
5. [Benchmarks](#benchmarks)
6. [Cross-Platform Validation](#cross-platform-validation)
7. [CI/CD Integration](#cicd-integration)

---

## Quick Start

### Run All Tests

```bash
# Run all unit and integration tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/integration/end_to_end_integration_test.dart
```

### Run on Physical Devices

```bash
# List connected devices
flutter devices

# Run on specific device
flutter test --device-id=<device-id>

# Run benchmarks on physical device (RELEASE mode)
flutter run --release -d <device-id> benchmark/physical_device_benchmark.dart
```

---

## Unit Tests

### Location

```
test/
├── accessibility_test.dart
├── html_sanitizer_test.dart
├── hyper_render_test.dart
├── layout_logic_test.dart
├── memory/
│   ├── image_lru_test.dart
│   └── memory_profiling_test.dart
├── security/
│   ├── owasp_xss_evasion_test.dart
│   └── security_url_test.dart
├── style/
│   ├── css_bug_fixes_test.dart
│   └── named_colors_test.dart
└── ... (42+ files total)
```

### Run Unit Tests

```bash
# All unit tests
flutter test test/

# Specific category
flutter test test/security/
flutter test test/memory/
flutter test test/style/

# Single test file
flutter test test/html_sanitizer_test.dart
```

### Key Unit Test Areas

**Security:**
- ✅ XSS attack prevention (OWASP top 10)
- ✅ URL validation and sanitization
- ✅ HTML entity encoding

**Memory:**
- ✅ LRU cache behavior
- ✅ Image caching
- ✅ Memory leak detection

**Rendering:**
- ✅ CSS parsing and application
- ✅ Layout calculations
- ✅ Float layout
- ✅ Table rendering

---

## Integration Tests

### New Integration Test Suites (v1.0.x)

#### 1. End-to-End Integration Tests

**File:** `test/integration/end_to_end_integration_test.dart`

**Coverage:**
- ✅ Complete rendering pipeline (HTML → Parse → Layout → Render)
- ✅ User interactions (tap, drag, scroll)
- ✅ Error handling (malformed HTML, 404 images, XSS)
- ✅ Performance edge cases (deeply nested, many floats)
- ✅ Real-world scenarios (news, email, documentation)

**Run:**
```bash
flutter test test/integration/end_to_end_integration_test.dart
```

**Test Groups:**
- E2E Integration: Complete Rendering Pipeline
- E2E Integration: User Interactions
- E2E Integration: Error Handling
- E2E Integration: Performance Edge Cases
- E2E Integration: Real-World Scenarios

---

#### 2. Mobile Device Integration Tests

**File:** `test/integration/mobile_device_integration_test.dart`

**Coverage:**
- ✅ Touch interactions (tap, long press, drag, pinch zoom)
- ✅ Screen size variations (320px to 1024px)
- ✅ Memory constraints
- ✅ Platform-specific behaviors (iOS vs Android)
- ✅ Battery and resource usage

**Run:**
```bash
# On simulator/emulator
flutter test test/integration/mobile_device_integration_test.dart

# On physical device (recommended)
flutter test --device-id=<device-id> test/integration/mobile_device_integration_test.dart
```

**Test Groups:**
- Mobile Device: Touch Interactions
- Mobile Device: Screen Size Variations
- Mobile Device: Memory Constraints
- Mobile Device: Platform-Specific Behaviors
- Mobile Device: Performance Optimization
- Mobile Device: Battery and Resource Usage
- Mobile Device: Edge Cases

**Screen Sizes Tested:**
- 📱 Small Phone: 320x568 (iPhone SE)
- 📱 Standard Phone: 375x667 (iPhone 8)
- 📱 Large Phone: 428x926 (iPhone 14 Pro Max)
- 📱 Tablet: 768x1024 (iPad)
- 🔄 Landscape/Portrait rotation

---

#### 3. Cross-Platform Validation Tests

**File:** `test/integration/cross_platform_validation_test.dart`

**Coverage:**
- ✅ Consistent rendering across platforms
- ✅ Platform-specific features
- ✅ Performance benchmarks per platform
- ✅ Error handling consistency

**Run on Each Platform:**

```bash
# iOS
flutter test --device-id=<iphone-id> test/integration/cross_platform_validation_test.dart

# Android
flutter test --device-id=<android-id> test/integration/cross_platform_validation_test.dart

# macOS
flutter test test/integration/cross_platform_validation_test.dart

# Windows
flutter test test/integration/cross_platform_validation_test.dart

# Linux
flutter test test/integration/cross_platform_validation_test.dart
```

**Test Groups:**
- Cross-Platform: Core Rendering
- Cross-Platform: Text Selection
- Cross-Platform: Performance
- Cross-Platform: Platform-Specific Features
- Cross-Platform: Error Handling
- Cross-Platform: Complex Layouts
- Cross-Platform: Real-World Content

---

## Physical Device Testing

### Physical Device Benchmark Suite

**File:** `benchmark/physical_device_benchmark.dart`

**Features:**
- ⚡ Parse time benchmarks (1KB to 100KB)
- 💾 Memory profiling
- 📊 FPS measurement
- 👆 Touch interaction latency
- 🔋 Battery impact estimates
- 📱 Device-specific characteristics

**Run (MUST USE RELEASE MODE):**

```bash
# iOS Physical Device
flutter run --release -d <iphone-id> benchmark/physical_device_benchmark.dart

# Android Physical Device
flutter run --release -d <android-id> benchmark/physical_device_benchmark.dart
```

**⚠️ IMPORTANT:**
- ❌ DO NOT run in debug mode - results will be invalid
- ❌ DO NOT run on simulators/emulators - not representative
- ✅ ALWAYS use `--release` flag
- ✅ ALWAYS use physical devices

**Benchmark Categories:**

1. **Parse Time Benchmarks**
   - 1KB HTML (target: <50ms)
   - 5KB HTML (target: <100ms)
   - 10KB HTML (target: <150ms)
   - 25KB HTML (target: <300ms)
   - 50KB HTML (target: <600ms)
   - 100KB HTML (target: <1200ms)

2. **Memory Benchmarks**
   - 10KB document (target: <15MB)
   - 25KB document (target: <25MB)
   - 50KB document (target: <40MB)

3. **FPS Benchmarks**
   - Scroll 10KB (target: 60fps)
   - Scroll 25KB (target: 60fps)
   - Scroll 50KB (target: 50fps)

4. **Interaction Benchmarks**
   - Tap latency (target: <50ms)
   - Drag performance (target: <100ms)

5. **Layout Benchmarks**
   - Float layout (target: <200ms)
   - Table layout (target: <300ms)
   - Nested elements (target: <150ms)

6. **Real-World Scenarios**
   - News article (target: <250ms)
   - Email thread (target: <300ms)
   - Documentation (target: <200ms)

**Output Example:**

```
═══════════════════════════════════════════════════════════
           PHYSICAL DEVICE BENCHMARK RESULTS
═══════════════════════════════════════════════════════════
Platform: ios
Version: Version 17.2
Build Mode: RELEASE
Processors: 6
Date: 2026-03-06 14:30:00
═══════════════════════════════════════════════════════════

✅ Parse 1KB
   Time: 12ms (target: <50ms) - 1 nodes

✅ Parse 10KB
   Time: 45ms (target: <150ms) - 150 nodes

✅ Parse 25KB
   Time: 98ms (target: <300ms) - 375 nodes

...

═══════════════════════════════════════════════════════════
                    SUMMARY
═══════════════════════════════════════════════════════════
Total Tests: 20
Passed: 19
Failed: 1
Success Rate: 95.0%
═══════════════════════════════════════════════════════════

Performance Grade: A+ (Excellent)
Recommendation: Device performs excellently. Suitable for all content sizes.
```

---

## Benchmarks

### Mobile Benchmark Tool

**File:** `benchmark/mobile_benchmark.dart`

**Features:**
- Quick performance validation
- Parse time measurement
- Memory usage estimation
- Scrolling performance
- Text selection testing

**Run:**

```bash
# iOS Simulator (Debug mode OK for quick testing)
flutter run -d "iPhone 17 Pro Max" benchmark/mobile_benchmark.dart

# Physical device (Release mode recommended)
flutter run --release -d <device-id> benchmark/mobile_benchmark.dart
```

**Use Cases:**
- ✅ Quick sanity checks during development
- ✅ Pre-release validation
- ✅ CI/CD pipeline integration
- ⚠️ NOT for production benchmarks (use physical_device_benchmark.dart)

---

## Cross-Platform Validation

### Recommended Testing Matrix

| Platform | Device Type | Build Mode | Priority |
|----------|-------------|------------|----------|
| **iOS** | iPhone 12+ | Release | ⭐⭐⭐ HIGH |
| **iOS** | iPad | Release | ⭐⭐ MEDIUM |
| **Android** | Flagship (S22+) | Release | ⭐⭐⭐ HIGH |
| **Android** | Mid-range (4GB RAM) | Release | ⭐⭐ MEDIUM |
| **macOS** | Apple Silicon | Release | ⭐⭐ MEDIUM |
| **Windows** | x64 | Release | ⭐ LOW |
| **Linux** | x64 | Release | ⭐ LOW |

### Platform-Specific Commands

**iOS Physical Device:**
```bash
# List devices
flutter devices

# Run tests
flutter test --device-id=<iphone-id>

# Run benchmarks
flutter run --release -d <iphone-id> benchmark/physical_device_benchmark.dart

# Profile with Xcode Instruments
# 1. Open ios/Runner.xcworkspace in Xcode
# 2. Product > Profile
# 3. Choose "Allocations" or "Time Profiler"
```

**Android Physical Device:**
```bash
# List devices
flutter devices

# Run tests
flutter test --device-id=<android-id>

# Run benchmarks
flutter run --release -d <android-id> benchmark/physical_device_benchmark.dart

# Profile with Android Studio
flutter run --profile -d <android-id>
# Then open Android Studio > View > Tool Windows > Profiler
```

**macOS:**
```bash
flutter test

flutter run --release benchmark/physical_device_benchmark.dart
```

**Windows/Linux:**
```bash
flutter test

flutter run --release benchmark/physical_device_benchmark.dart
```

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]

    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Run unit tests
        run: flutter test

      - name: Run integration tests
        run: flutter test test/integration/

      - name: Generate coverage
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### Pre-Release Checklist

Before releasing a new version, run:

```bash
# 1. All unit tests
flutter test

# 2. Integration tests on each platform
flutter test test/integration/ --device-id=<ios-device>
flutter test test/integration/ --device-id=<android-device>
flutter test test/integration/ # macOS/Windows/Linux

# 3. Physical device benchmarks (RELEASE mode)
flutter run --release -d <iphone-id> benchmark/physical_device_benchmark.dart
flutter run --release -d <android-id> benchmark/physical_device_benchmark.dart

# 4. Coverage report
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Performance Targets

### Parse Time Targets (Release Mode, Physical Devices)

| Document Size | Target | Good | Excellent |
|---------------|--------|------|-----------|
| 1KB | <50ms | <30ms | <10ms |
| 10KB | <150ms | <100ms | <50ms |
| 25KB | <300ms | <200ms | <100ms |
| 50KB | <600ms | <400ms | <200ms |
| 100KB | <1200ms | <800ms | <500ms |

### Memory Usage Targets

| Document Size | Target | Good | Excellent |
|---------------|--------|------|-----------|
| 10KB | <15MB | <10MB | <5MB |
| 25KB | <25MB | <18MB | <12MB |
| 50KB | <40MB | <30MB | <20MB |

### FPS Targets

| Scenario | Target | Good | Excellent |
|----------|--------|------|-----------|
| Scroll 10KB | 60fps | 58fps | 60fps |
| Scroll 25KB | 60fps | 55fps | 60fps |
| Scroll 50KB | 50fps | 45fps | 55fps |

---

## Troubleshooting

### Common Issues

**1. Tests fail in debug mode but pass in release**
- ✅ Expected behavior - debug mode is 2-5x slower
- Use `--release` flag for accurate performance tests

**2. Simulator/Emulator results differ from physical device**
- ✅ Expected - simulators use host machine hardware
- Always validate on physical devices before release

**3. Memory tests don't show actual memory usage**
- Use platform-specific tools:
  - iOS: Xcode Instruments → Allocations
  - Android: Android Studio → Profiler

**4. FPS tests don't show actual frame rate**
- Use Flutter DevTools:
  ```bash
  flutter run --profile -d <device-id>
  # Open DevTools > Performance tab
  ```

**5. Tests timeout on slow devices**
- Increase timeout:
  ```dart
  testWidgets('test', (tester) async {
    // ...
  }, timeout: const Timeout(Duration(minutes: 5)));
  ```

---

## Best Practices

### For Unit Tests
- ✅ Test one thing per test
- ✅ Use descriptive test names
- ✅ Mock external dependencies
- ✅ Keep tests fast (<1s each)

### For Integration Tests
- ✅ Test complete user workflows
- ✅ Use realistic data
- ✅ Test error scenarios
- ✅ Verify performance

### For Device Testing
- ✅ Always use release mode for benchmarks
- ✅ Test on multiple device tiers (flagship, mid-range, low-end)
- ✅ Test on multiple OS versions
- ✅ Record results for comparison

### For CI/CD
- ✅ Run tests on every commit
- ✅ Block merges on test failures
- ✅ Generate and track coverage
- ✅ Run integration tests nightly

---

## Contributing Tests

When adding new features, include:

1. **Unit tests** for new functions/classes
2. **Integration tests** for new workflows
3. **Performance benchmarks** if affecting rendering
4. **Cross-platform validation** if platform-specific

**Test File Naming:**
- Unit test: `feature_name_test.dart`
- Integration test: `feature_workflow_integration_test.dart`
- Benchmark: `feature_benchmark.dart`

**Test Structure:**
```dart
group('Feature Name', () {
  setUp(() {
    // Setup code
  });

  tearDown(() {
    // Cleanup code
  });

  test('should do X when Y', () {
    // Arrange
    // Act
    // Assert
  });

  testWidgets('should render Z', (tester) async {
    // Arrange
    // Act
    await tester.pumpWidget(...);
    // Assert
    expect(find.byType(Widget), findsOneWidget);
  });
});
```

---

## Resources

**Documentation:**
- [Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

**Tools:**
- [Flutter DevTools](https://docs.flutter.dev/tools/devtools/overview)
- [Xcode Instruments](https://developer.apple.com/instruments/)
- [Android Profiler](https://developer.android.com/studio/profile)

**HyperRender Docs:**
- `README.md` - Main documentation
- `CHANGELOG.md` - Version history
- `benchmark/MOBILE_BENCHMARKS.md` - Mobile benchmark results

---

**Generated:** 2026-03-06
**Version:** 1.0.x
**Status:** ✅ Comprehensive test suite available
