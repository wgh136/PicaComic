import 'dart:async' show Future, StreamController;
import 'dart:ui' as ui show Codec;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'eh_cached_image.dart' as image_provider;
import '_image_loader.dart';

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

/// IO implementation of the CachedNetworkImageProvider; the ImageProvider to
/// load network images using a cache.
class EhCachedImageProvider
    extends ImageProvider<image_provider.EhCachedImageProvider> {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const EhCachedImageProvider(
      this.gallery, this.page, {
        this.maxHeight,
        this.maxWidth,
        this.scale = 1.0,
        this.errorListener,
        this.headers,
        this.cacheKey,
      });

  final Gallery gallery;

  final int page;

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
  Future<EhCachedImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<EhCachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(image_provider.EhCachedImageProvider key,
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
      image_provider.EhCachedImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      ) {
    assert(key == this);
    return ImageLoader().loadBufferAsync(
      gallery,
      page,
      cacheKey,
      chunkEvents,
      decode,
      maxHeight,
      maxWidth,
      {
        "cookie": EhNetwork().cookiesStr
      },
      errorListener,
          () => PaintingBinding.instance.imageCache.evict(key),
    );
  }

  String get key => "${gallery.link}$page";

  @override
  bool operator ==(dynamic other) {
    if (other is EhCachedImageProvider) {
      return ((cacheKey ?? key) == (other.cacheKey ?? other.key)) &&
          scale == other.scale &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(cacheKey ?? key, scale, maxHeight, maxWidth);

  @override
  String toString() => '$runtimeType(key, scale: $scale)';
}
