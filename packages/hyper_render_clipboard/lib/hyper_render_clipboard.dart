/// HyperRender Clipboard - Image clipboard support for HyperRender
///
/// This package provides full image clipboard functionality including:
/// - Copying images to system clipboard (not just URLs)
/// - Saving images to device storage
/// - Sharing images via system share dialog
///
/// ## Installation
///
/// Add to your pubspec.yaml:
/// ```yaml
/// dependencies:
///   hyper_render: ^1.0.0
///   hyper_render_clipboard: ^1.0.0
/// ```
///
/// ## Usage
///
/// ```dart
/// import 'package:hyper_render/hyper_render.dart';
/// import 'package:hyper_render_clipboard/hyper_render_clipboard.dart';
///
/// // Use with HyperViewer
/// HyperViewer(
///   html: '<img src="https://example.com/image.jpg">',
///   imageClipboardHandler: SuperClipboardHandler(),
/// )
///
/// // Use with HyperImage directly
/// HyperImage(
///   src: 'https://example.com/image.jpg',
///   clipboardHandler: SuperClipboardHandler(),
/// )
/// ```
///
/// ## Platform Setup
///
/// ### macOS
/// Add to macos/Runner/DebugProfile.entitlements and macos/Runner/Release.entitlements:
/// ```xml
/// <key>com.apple.security.network.client</key>
/// <true/>
/// ```
///
/// ### Android
/// Add to android/app/src/main/AndroidManifest.xml:
/// ```xml
/// <uses-permission android:name="android.permission.INTERNET"/>
/// <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
/// ```
///
/// ### iOS
/// No additional setup required.
///
/// ### Windows/Linux
/// No additional setup required.
library;

export 'src/super_clipboard_handler.dart' show SuperClipboardHandler;

// Re-export interface from hyper_render_core for convenience
export 'package:hyper_render_core/hyper_render_core.dart'
    show ImageClipboardHandler, DefaultImageClipboardHandler, ImageOperationResult;
