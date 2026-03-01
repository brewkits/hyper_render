import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Image load state
enum ImageLoadState {
  loading,
  loaded,
  error,
}

/// Cached image data
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

  // BUG-A FIX: Capture listener so it can be removed after first event.
  // Without this, the listener is permanently retained by the ImageStream,
  // leaking closures and preventing GC of onLoad/onError references.
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
