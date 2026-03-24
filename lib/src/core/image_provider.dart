import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Image load state
 /// State of image loading.
enum ImageLoadState {
  loading,
  loaded,
  error,
}

/// Cached image data
 /// Cache entry for images.
class CachedImage {
  final ui.Image? image;
  final ImageLoadState state;
  final String? error;

  const CachedImage({
    this.image,
    required this.state,
    this.error,
  });
}

/// Callback for loading images
/// 
/// This allows users to provide custom image loading implementations
/// (e.g., using cached_network_image, custom caching, etc.)
/// 
/// Parameters:
/// - src: The image URL
/// - onLoad: Callback when image loads successfully
/// - onError: Callback when image fails to load
 /// Loader for fetching images.
typedef HyperImageLoader = void Function(
  String src,
  void Function(ui.Image image) onLoad,
  void Function(Object error) onError,
);

/// Default image loader using Flutter's NetworkImage
void defaultImageLoader(
  String src,
  void Function(ui.Image image) onLoad,
  void Function(Object error) onError,
) {
  // Use NetworkImage with cache headers
  final imageProvider = NetworkImage(
    src,
    headers: const {
      'Cache-Control': 'max-age=3600',
    },
  );

  final imageStream = imageProvider.resolve(
    const ImageConfiguration(
      devicePixelRatio: 1.0,
    ),
  );

  // BUG-A FIX: Listener must be stored and removed after first invocation.
  // Without removal the ImageStream holds a strong ref to the listener forever,
  // leaking onLoad/onError closures (and any RenderBox state they close over).
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (ImageInfo info, bool synchronousCall) {
      imageStream.removeListener(listener);
      onLoad(info.image);
    },
    onError: (exception, stackTrace) {
      imageStream.removeListener(listener);
      onError(exception);
    },
  );
  imageStream.addListener(listener);
}
