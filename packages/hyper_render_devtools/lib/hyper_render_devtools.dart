/// HyperRender DevTools Extension
///
/// Provides VM service extensions and debugging utilities for inspecting
/// HyperRender's internal state from Flutter DevTools.
///
/// ## Setup
///
/// Register the service extensions early in your app (debug mode only):
///
/// ```dart
/// import 'package:hyper_render_devtools/hyper_render_devtools.dart';
///
/// void main() {
///   // Register in debug mode only
///   assert(() {
///     HyperRenderDevtools.register();
///     return true;
///   }());
///   runApp(const MyApp());
/// }
/// ```
///
/// ## What's Inspectable
///
/// - **UDT Tree**: Full document node hierarchy with tag names and attributes
/// - **Computed Styles**: All CSS properties for each node
/// - **Fragments**: Layout fragments with size/offset metrics
/// - **Lines**: Line info with baseline and float inset data
/// - **Performance**: Phase timing (parse/style/layout/paint)
library;

export 'src/service_extensions.dart' show HyperRenderDevtools;
export 'src/udt_serializer.dart' show UdtSerializer;
