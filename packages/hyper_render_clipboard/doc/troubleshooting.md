# Troubleshooting Guide

Common issues and solutions when using `hyper_render_clipboard`.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Clipboard Issues](#clipboard-issues)
- [Network Issues](#network-issues)
- [Save/Storage Issues](#savestorage-issues)
- [Share Issues](#share-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Debugging Tips](#debugging-tips)

---

## Installation Issues

### Error: "Failed to resolve dependencies"

**Problem:**
```
Because hyper_render_clipboard depends on super_clipboard ^0.8.0...
```

**Solution:**
```bash
# Clear pub cache
flutter pub cache clean

# Get dependencies
flutter pub get

# If still fails, try upgrading
flutter pub upgrade
```

### Error: "Incompatible versions"

**Problem:**
Version conflicts between packages.

**Solution:**
```yaml
# pubspec.yaml - Use compatible versions
dependencies:
  hyper_render: ^1.0.0
  hyper_render_clipboard: ^1.0.0

# Or use dependency overrides
dependency_overrides:
  super_clipboard: ^0.8.24
```

---

## Clipboard Issues

### Problem: "copyImageFromUrl returns false"

**Symptoms:**
```dart
final success = await handler.copyImageFromUrl(url);
print(success); // false
```

**Possible Causes & Solutions:**

#### 1. Clipboard not available

**Check:**
```dart
final handler = SuperClipboardHandler();
if (!handler.isImageCopySupported) {
  print('Clipboard not supported on this platform');
}
```

**Solution:**
Web platform has limited clipboard support. Use share as fallback:
```dart
if (handler.isImageCopySupported) {
  await handler.copyImageFromUrl(url);
} else {
  await handler.shareImageFromUrl(url);
}
```

#### 2. Network error

**Check:**
```bash
# Test URL in browser
curl -I https://example.com/image.png
```

**Solution:**
Ensure URL is valid and accessible:
```dart
try {
  final response = await http.head(Uri.parse(imageUrl));
  if (response.statusCode == 200) {
    await handler.copyImageFromUrl(imageUrl);
  } else {
    print('Image not accessible: ${response.statusCode}');
  }
} catch (e) {
  print('Network error: $e');
}
```

#### 3. Unsupported format

**Check:**
```dart
final mimeType = 'image/tiff'; // Example
if (!handler.supportedFormats.contains(mimeType)) {
  print('Format $mimeType not supported');
}
```

**Solution:**
Convert to supported format before copying:
```dart
// Supported: PNG, JPEG, GIF, WebP, BMP
```

#### 4. Large image timeout

**Problem:**
Large images may timeout during download.

**Solution:**
Use custom HTTP client with longer timeout:
```dart
import 'package:http/http.dart' as http;

final client = http.Client();
final handler = SuperClipboardHandler(httpClient: client);

// Increase timeout at http level
// Or show loading indicator
```

---

## Network Issues

### Problem: "Network request failed"

#### macOS: Network permission denied

**Error:**
```
Error: Connection failed
```

**Solution:**
1. Check `macos/Runner/DebugProfile.entitlements`:
```xml
<key>com.apple.security.network.client</key>
<true/>
```

2. Check `macos/Runner/Release.entitlements` has same permission

3. Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run -d macos
```

#### iOS: ATS blocking HTTP URLs

**Error:**
```
Error: App Transport Security has blocked a cleartext HTTP resource
```

**Solution:**
Update `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

Or whitelist specific domains:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

#### Android: Cleartext traffic not permitted

**Error:**
```
CLEARTEXT communication not permitted
```

**Solution:**
1. Add internet permission in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

2. Allow cleartext traffic (if needed):
Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true" />
</network-security-config>
```

3. Reference in `AndroidManifest.xml`:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config">
```

#### Web: CORS error

**Error:**
```
Access to fetch at 'https://example.com/image.png' from origin 'http://localhost'
has been blocked by CORS policy
```

**Solution:**
Images must be served with CORS headers. Contact server admin or use CORS proxy:
```dart
// Use CORS proxy (development only)
final proxiedUrl = 'https://cors-anywhere.herokuapp.com/$imageUrl';
await handler.copyImageFromUrl(proxiedUrl);
```

---

## Save/Storage Issues

### Problem: "saveImageFromUrl returns null"

#### Permission denied (Android)

**Error:**
```dart
final path = await handler.saveImageFromUrl(url);
print(path); // null
```

**Solution for Android < 10:**
Add storage permissions:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

Request runtime permission:
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> saveWithPermission(String url) async {
  if (await Permission.storage.request().isGranted) {
    final path = await handler.saveImageFromUrl(url);
    print('Saved to: $path');
  } else {
    print('Storage permission denied');
  }
}
```

**Solution for Android 10+:**
Uses scoped storage automatically, no permission needed.

#### iOS: Can't save to Photos

**Problem:**
Want to save to photo library, not app documents.

**Solution:**
Use `image_gallery_saver` package:
```dart
import 'package:image_gallery_saver/image_gallery_saver.dart';

// Download image
final response = await http.get(Uri.parse(imageUrl));

// Save to gallery
final result = await ImageGallerySaver.saveImage(
  response.bodyBytes,
  quality: 100,
  name: 'my_image',
);
```

Add permission in `Info.plist`:
```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save images to your photo library</string>
```

#### Disk space full

**Problem:**
Device has no storage space.

**Solution:**
Check available space before saving:
```dart
import 'package:disk_space/disk_space.dart';

Future<void> saveIfSpaceAvailable(String url) async {
  final freeDiskSpace = await DiskSpace.getFreeDiskSpace;

  if (freeDiskSpace != null && freeDiskSpace > 100) { // 100 MB
    final path = await handler.saveImageFromUrl(url);
    if (path != null) {
      print('Saved to: $path');
    }
  } else {
    print('Not enough disk space');
  }
}
```

---

## Share Issues

### Problem: "shareImageFromUrl does nothing"

#### Share dialog not showing

**Symptoms:**
Method returns `true` but no dialog appears.

**Solution:**
Ensure you're awaiting the operation:
```dart
// Correct
await handler.shareImageFromUrl(url);

// Wrong - doesn't wait
handler.shareImageFromUrl(url); // Fire and forget
```

Check if running on main thread:
```dart
import 'package:flutter/scheduler.dart';

SchedulerBinding.instance.addPostFrameCallback((_) async {
  await handler.shareImageFromUrl(url);
});
```

#### No apps to share with

**Problem:**
No apps installed that can handle image sharing.

**Solution:**
Handle gracefully:
```dart
final success = await handler.shareImageFromUrl(url);
if (!success) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('No apps available to share')),
  );
}
```

---

## Platform-Specific Issues

### macOS

#### "The file doesn't exist" error

**Problem:**
Entitlements not properly configured.

**Solution:**
```bash
# Clean build
cd macos
rm -rf build
cd ..
flutter clean
flutter pub get
flutter run -d macos
```

Verify entitlements are applied:
```bash
codesign -d --entitlements - macos/build/macos/Build/Products/Debug/YourApp.app
```

### iOS

#### Simulator clipboard not working

**Problem:**
Simulator has different clipboard than host Mac.

**Solution:**
Test on physical device or use simulator clipboard:
```bash
# In simulator, use Edit > Paste in iOS apps
```

### Android

#### "FileNotFoundException" on Android 11+

**Problem:**
Scoped storage restrictions.

**Solution:**
Let package handle paths automatically:
```dart
// Package chooses correct path based on Android version
final path = await handler.saveImageFromUrl(url);
```

Or request all files access (not recommended):
```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
```

### Linux

#### "xclip: command not found"

**Problem:**
xclip not installed.

**Solution:**
Install xclip:
```bash
# Ubuntu/Debian
sudo apt-get install xclip

# Fedora
sudo dnf install xclip

# Arch
sudo pacman -S xclip
```

Verify installation:
```bash
which xclip
xclip -version
```

#### "Cannot open display" error

**Problem:**
DISPLAY environment variable not set.

**Solution:**
```bash
echo $DISPLAY  # Should show :0 or :1

# If empty, set it:
export DISPLAY=:0

# Run app
flutter run -d linux
```

### Web

#### Clipboard API not available

**Problem:**
Browser doesn't support Clipboard API or not on HTTPS.

**Solution:**
Use feature detection:
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Check if clipboard available
  if (handler.isImageCopySupported) {
    await handler.copyImageFromUrl(url);
  } else {
    // Fallback to share
    await handler.shareImageFromUrl(url);
  }
}
```

Ensure HTTPS in production:
```bash
# Development: use localhost (allowed)
flutter run -d chrome

# Production: deploy to HTTPS
```

---

## Debugging Tips

### Enable Debug Logging

The package uses Flutter's `debugPrint` for error logging. Enable verbose logging:

```dart
// In main.dart
void main() {
  // Enable debug mode
  debugPrint('Starting app...');

  runApp(MyApp());
}
```

Check Flutter logs:
```bash
# View all logs
flutter logs

# Filter for clipboard
flutter logs | grep -i clipboard

# Filter for errors
flutter logs | grep -i error
```

### Test URLs

Use these test URLs to verify functionality:

```dart
final testUrls = [
  // Small PNG
  'https://picsum.photos/200/300.jpg',

  // Larger image
  'https://picsum.photos/1920/1080.jpg',

  // Different formats
  'https://via.placeholder.com/500.png',
  'https://via.placeholder.com/500.gif',
];
```

### Check Handler State

```dart
void debugHandler(ImageClipboardHandler handler) {
  print('Copy supported: ${handler.isImageCopySupported}');
  print('Save supported: ${handler.isSaveSupported}');
  print('Share supported: ${handler.isShareSupported}');
  print('Formats: ${handler.supportedFormats}');
}

// Usage
final handler = SuperClipboardHandler();
debugHandler(handler);
```

### Isolate the Problem

Test each operation individually:

```dart
Future<void> testAllOperations(String imageUrl) async {
  final handler = SuperClipboardHandler();

  print('Testing copy...');
  final copySuccess = await handler.copyImageFromUrl(imageUrl);
  print('Copy result: $copySuccess');

  print('Testing save...');
  final savePath = await handler.saveImageFromUrl(imageUrl);
  print('Save result: $savePath');

  print('Testing share...');
  final shareSuccess = await handler.shareImageFromUrl(imageUrl);
  print('Share result: $shareSuccess');
}
```

### Network Debugging

Add HTTP logging:

```dart
import 'package:http/http.dart' as http;

class LoggingClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    print('Request: ${request.method} ${request.url}');
    final response = await _inner.send(request);
    print('Response: ${response.statusCode}');
    return response;
  }
}

// Usage
final client = LoggingClient();
final handler = SuperClipboardHandler(httpClient: client);
```

### Platform Detection

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void printPlatformInfo() {
  if (kIsWeb) {
    print('Running on Web');
  } else if (Platform.isAndroid) {
    print('Running on Android ${Platform.version}');
  } else if (Platform.isIOS) {
    print('Running on iOS ${Platform.version}');
  } else if (Platform.isMacOS) {
    print('Running on macOS ${Platform.version}');
  } else if (Platform.isWindows) {
    print('Running on Windows ${Platform.version}');
  } else if (Platform.isLinux) {
    print('Running on Linux ${Platform.version}');
  }
}
```

---

## Getting Help

If you're still experiencing issues:

1. **Check Documentation**
   - [API Reference](api_reference.md)
   - [Usage Guide](usage_guide.md)
   - [Platform Setup](platform_setup.md)

2. **Search Issues**
   - Check [GitHub Issues](https://github.com/your-repo/issues)
   - Search for similar problems

3. **Create an Issue**
   Include:
   - Platform and version
   - Flutter version (`flutter --version`)
   - Package version
   - Full error message
   - Minimal reproduction code
   - Steps to reproduce

4. **Example Issue Template**

```markdown
**Platform:** iOS 17.1
**Flutter version:** 3.16.0
**Package version:** 1.0.0

**Description:**
copyImageFromUrl returns false on iOS.

**Steps to reproduce:**
1. Run app on iOS device
2. Call handler.copyImageFromUrl('https://example.com/image.png')
3. Returns false

**Code:**
```dart
final handler = SuperClipboardHandler();
final success = await handler.copyImageFromUrl('https://example.com/image.png');
print(success); // false
```

**Logs:**
```
[log output here]
```

**Expected:**
Should copy image to clipboard

**Actual:**
Returns false without error
```

---

## Performance Tips

### Reduce Memory Usage

```dart
// Download and process in chunks
final response = await http.get(Uri.parse(imageUrl));
if (response.bodyBytes.length > 10 * 1024 * 1024) { // > 10MB
  print('Warning: Large image may cause memory issues');
}
```

### Cache Images

```dart
// Use cached_network_image for repeated images
import 'package:cached_network_image/cached_network_image.dart';
```

### Optimize Network Requests

```dart
// Reuse HTTP client
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final http.Client _httpClient;
  late final SuperClipboardHandler _handler;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    _handler = SuperClipboardHandler(httpClient: _httpClient);
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use _handler
  }
}
```

---

## Related Packages

If you need additional functionality:

- **image_picker** - Pick images from camera/gallery
- **image_gallery_saver** - Save images to photo library
- **cached_network_image** - Cache network images
- **permission_handler** - Handle runtime permissions
- **path_provider** - Get platform-specific paths

---

## See Also

- [API Reference](api_reference.md)
- [Usage Guide](usage_guide.md)
- [Platform Setup](platform_setup.md)
