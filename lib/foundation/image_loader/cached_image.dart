import 'dart:async' show Future, StreamController;
import 'dart:ui' as ui show Codec;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'cached_image.dart' as image_provider;
import '_image_loader.dart';

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

/// 适用于正常图片加载的CachedImageProvider
class CachedImageProvider
    extends ImageProvider<image_provider.CachedImageProvider> {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const CachedImageProvider(
      this.url, {
        this.maxHeight,
        this.maxWidth,
        this.scale = 1.0,
        this.errorListener,
        this.headers,
        this.cacheKey,
      });


  /// Web url of the image to load
  final String url;

  /// Cache key of the image to cache
  final String? cacheKey;

  /// Scale of the image
  final double scale;

  /// Listener to be called when images fails to load.
  final image_provider.ErrorListener? errorListener;

  /// Set headers for the image provider, for example for authentication
  final Map<String, String>? headers;

  /// Maximum height of the loaded image. If not null and using an
  /// [ImageCacheManager] the image is resized on disk to fit the height.
  final int? maxHeight;

  /// Maximum width of the loaded image. If not null and using an
  /// [ImageCacheManager] the image is resized on disk to fit the width.
  final int? maxWidth;

  @override
  Future<CachedImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<CachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(image_provider.CachedImageProvider key,
      ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadBufferAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Future<ui.Codec> _loadBufferAsync(
      image_provider.CachedImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      ) {
    assert(key == this);
    return ImageLoader().loadBufferAsync(
      url,
      cacheKey,
      chunkEvents,
      decode,
      maxHeight,
      maxWidth,
      headers,
      errorListener,
          () => PaintingBinding.instance.imageCache.evict(key),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is CachedImageProvider) {
      return ((cacheKey ?? url) == (other.cacheKey ?? other.url)) &&
          scale == other.scale &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(cacheKey ?? url, scale, maxHeight, maxWidth);

  @override
  String toString() => '$runtimeType("$url", scale: $scale)';
}
