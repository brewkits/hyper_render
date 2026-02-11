# Platform Setup Guide

This guide covers platform-specific configuration required for `hyper_render_clipboard` to work properly on each supported platform.

## Table of Contents

- [Overview](#overview)
- [macOS](#macos)
- [iOS](#ios)
- [Android](#android)
- [Windows](#windows)
- [Linux](#linux)
- [Web](#web)

---

## Overview

`hyper_render_clipboard` uses several native platform features that require specific permissions and configurations:

| Feature | Requirement |
|---------|-------------|
| Network access | Required for downloading images from URLs |
| Clipboard access | Automatic (handled by `super_clipboard`) |
| File system access | Required for saving images |
| Share functionality | Automatic (handled by `share_plus`) |

---

## macOS

### 1. Network Client Entitlement

For your app to download images from the internet, you need to enable network client capabilities.

**DebugProfile.entitlements** (`macos/Runner/DebugProfile.entitlements`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<key>com.apple.security.cs.allow-jit</key>
	<true/>
	<key>com.apple.security.network.server</key>
	<true/>
	<!-- Add this for network access -->
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

**Release.entitlements** (`macos/Runner/Release.entitlements`):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
	<!-- Add this for network access -->
	<key>com.apple.security.network.client</key>
	<true/>
</dict>
</plist>
```

### 2. File Access (Optional)

If you want to save images to custom locations outside the app sandbox, add:

```xml
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### 3. Info.plist Configuration

No additional Info.plist configuration is required for clipboard operations.

### Testing on macOS

```bash
# Run your app
flutter run -d macos

# Test clipboard functionality
# Long-press on an image and select "Copy Image"
# Open another app (like Preview or TextEdit) and paste
```

---

## iOS

### 1. Internet Access

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

For production, it's better to whitelist specific domains:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 2. Photo Library Access (Optional)

If you want to save images to the photo library, add:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to save images to your photo library</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need access to save images to your photo library</string>
```

### 3. Camera Roll Access (iOS 14+)

For iOS 14 and later:

```xml
<key>PHPhotoLibraryPreventAutomaticLimitedAccessAlert</key>
<true/>
```

### Testing on iOS

```bash
# Run on simulator
flutter run -d "iPhone 15 Pro"

# Run on physical device
flutter run -d <device-id>
```

---

## Android

### 1. Internet Permission

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Add these permissions -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>

    <application
        ...>
        ...
    </application>
</manifest>
```

### 2. Storage Permissions (Android 9 and below)

For Android 9 (API 28) and below:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### 3. Scoped Storage (Android 10+)

For Android 10 (API 29) and above, scoped storage is used automatically. No additional configuration needed.

If you need legacy external storage access:

```xml
<application
    android:requestLegacyExternalStorage="true"
    ...>
```

### 4. Network Security Configuration

For HTTP (non-HTTPS) URLs, create `android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

Then reference it in AndroidManifest.xml:

```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

### 5. Minimum SDK Version

Ensure your `android/app/build.gradle` has:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimum for share_plus
        targetSdkVersion 34
        ...
    }
}
```

### Testing on Android

```bash
# Run on emulator
flutter run -d emulator-5554

# Run on physical device
flutter run -d <device-id>

# Check permissions
adb shell dumpsys package com.your.package | grep permission
```

---

## Windows

### 1. No Special Configuration Required

Windows support works out of the box with no additional configuration.

### 2. Internet Access

Windows apps have internet access by default. No manifest changes needed.

### 3. File System Access

The app can save to standard user directories (Documents, Downloads) without special permissions.

### 4. Minimum Windows Version

Requires Windows 10 or later.

### Testing on Windows

```bash
# Run on Windows
flutter run -d windows

# Build release
flutter build windows
```

---

## Linux

### 1. Install xclip (Required for Clipboard)

The clipboard functionality requires `xclip` to be installed:

**Ubuntu/Debian:**
```bash
sudo apt-get install xclip
```

**Fedora:**
```bash
sudo dnf install xclip
```

**Arch Linux:**
```bash
sudo pacman -S xclip
```

### 2. GTK+ Dependencies

Ensure GTK+ 3.0 is installed:

**Ubuntu/Debian:**
```bash
sudo apt-get install libgtk-3-dev
```

**Fedora:**
```bash
sudo dnf install gtk3-devel
```

### 3. No Special Permissions Required

Linux apps have access to clipboard and file system by default.

### 4. Check xclip Installation

```bash
# Verify xclip is installed
which xclip

# Test xclip
echo "test" | xclip -selection clipboard
xclip -selection clipboard -o
```

### Testing on Linux

```bash
# Run on Linux
flutter run -d linux

# Build release
flutter build linux
```

### Troubleshooting Linux

If clipboard operations fail:

1. Check if xclip is installed: `which xclip`
2. Check if xclip works: `echo "test" | xclip -selection clipboard`
3. Check X11 display: `echo $DISPLAY` (should output `:0` or similar)
4. Try running with `DISPLAY=:0 flutter run -d linux`

---

## Web

### 1. Limited Clipboard Support

Web browsers have strict clipboard API restrictions:

- ✅ Share functionality works
- ⚠️ Copy to clipboard has limited support (requires user gesture)
- ❌ Save to file system not supported (browser downloads instead)

### 2. CORS Configuration

Images must be served with proper CORS headers to be accessible:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET
```

### 3. HTTPS Required

Modern browsers require HTTPS for clipboard API access (except localhost).

### 4. Clipboard API Support

Check browser compatibility:
- Chrome 86+
- Firefox 87+
- Safari 13.1+
- Edge 86+

### 5. Web Configuration

No special configuration needed in `web/index.html`, but ensure:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <!-- Ensure HTTPS in production -->
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'self';
                 img-src 'self' https: data:;
                 script-src 'self' 'unsafe-inline';
                 style-src 'self' 'unsafe-inline';">
</head>
<body>
  ...
</body>
</html>
```

### Testing on Web

```bash
# Run with chrome
flutter run -d chrome

# Run with edge
flutter run -d edge

# Build for web
flutter build web
```

### Web Limitations

```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Prefer share over copy on web
  await handler.shareImageFromUrl(imageUrl);
} else {
  // Use full clipboard functionality
  await handler.copyImageFromUrl(imageUrl);
}
```

---

## Platform Feature Matrix

| Feature | macOS | iOS | Android | Windows | Linux | Web |
|---------|-------|-----|---------|---------|-------|-----|
| Copy to Clipboard | ✅ | ✅ | ✅ | ✅ | ✅* | ⚠️ |
| Save to Storage | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Share Dialog | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Network Access | ✅** | ✅** | ✅** | ✅ | ✅ | ✅*** |
| Byte Operations | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |

**Legend:**
- ✅ Fully supported
- ⚠️ Limited support
- ❌ Not supported
- \* Requires xclip
- \*\* Requires configuration
- \*\*\* Subject to CORS

---

## Verification Checklist

After setup, verify functionality:

### macOS
- [ ] Can copy images to clipboard
- [ ] Can save images to Downloads folder
- [ ] Can share images via system dialog
- [ ] Network images load properly

### iOS
- [ ] Can copy images to clipboard
- [ ] Can save images to Files app
- [ ] Can share images via share sheet
- [ ] Network images load properly

### Android
- [ ] Can copy images to clipboard
- [ ] Can save images to device storage
- [ ] Can share images via share menu
- [ ] Network images load properly
- [ ] Permissions requested properly

### Windows
- [ ] Can copy images to clipboard
- [ ] Can save images to Downloads folder
- [ ] Network images load properly

### Linux
- [ ] xclip is installed
- [ ] Can copy images to clipboard
- [ ] Can save images to Downloads folder
- [ ] Network images load properly

### Web
- [ ] Can share images
- [ ] CORS properly configured
- [ ] Running on HTTPS (in production)

---

## Common Issues

### macOS: "The operation couldn't be completed"
- Check entitlements are properly configured
- Ensure network client permission is enabled
- Restart Xcode/Flutter

### iOS: "Image download failed"
- Check Info.plist for NSAppTransportSecurity
- Verify network permissions
- Check if running on HTTPS

### Android: "Permission denied"
- Check AndroidManifest.xml permissions
- Test on API 29+ (scoped storage)
- Verify minSdkVersion is 21+

### Windows: Works without issues
- Usually no configuration problems

### Linux: "Clipboard operation failed"
- Install xclip: `sudo apt-get install xclip`
- Check DISPLAY variable: `echo $DISPLAY`
- Test xclip manually

### Web: "Clipboard not available"
- Ensure HTTPS (or localhost)
- Check browser compatibility
- Use share as fallback

---

## Next Steps

- Read the [Usage Guide](usage_guide.md) for implementation examples
- Check the [API Reference](api_reference.md) for method details
- See [Troubleshooting](troubleshooting.md) for debugging help
