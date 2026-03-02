/// Global configuration for HyperRender's runtime behavior.
///
/// Call [HyperRenderConfig.configure] once at app startup (e.g., in `main()`)
/// before any [HyperRenderWidget] is created.
///
/// ```dart
/// void main() {
///   HyperRenderConfig.configure(
///     imageCacheMaxMb: 100,
///     textPainterCacheMaxEntries: 2000,
///   );
///   runApp(const MyApp());
/// }
/// ```
class HyperRenderConfig {
  HyperRenderConfig._();

  /// Maximum image cache size in megabytes. Default: 50 MB.
  static int imageCacheMaxMb = 50;

  /// Maximum number of [TextPainter] entries in the LRU cache. Default: 5000.
  static int textPainterCacheMaxEntries = 5000;

  /// Configure global rendering defaults. Call before creating any HyperViewer.
  static void configure({
    int? imageCacheMaxMb,
    int? textPainterCacheMaxEntries,
  }) {
    if (imageCacheMaxMb != null) {
      HyperRenderConfig.imageCacheMaxMb = imageCacheMaxMb;
    }
    if (textPainterCacheMaxEntries != null) {
      HyperRenderConfig.textPainterCacheMaxEntries = textPainterCacheMaxEntries;
    }
  }
}
