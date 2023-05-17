import 'dart:async' show Future, StreamController;
import 'dart:ui' as ui show Codec;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'hitomi_cached_image_provider.dart' as image_provider;
import '_image_loader.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

///Hitomi阅读器中使用的ImageProvider
class HitomiCachedImageProvider
    extends ImageProvider<image_provider.HitomiCachedImageProvider> {
  /// Creates an ImageProvider which loads an image from the [url], using the [scale].
  /// When the image fails to load [errorListener] is called.
  const HitomiCachedImageProvider(
      this.image, this.id, {
        this.maxHeight,
        this.maxWidth,
        this.scale = 1.0,
        this.errorListener,
        this.headers,
        this.cacheKey,
      });

  ///Hitomi图像信息
  final HitomiFile image;

  ///画廊ID
  final String id;

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
  Future<HitomiCachedImageProvider> obtainKey(
      ImageConfiguration configuration) {
    return SynchronousFuture<HitomiCachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(image_provider.HitomiCachedImageProvider key,
      ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
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

  Stream<ui.Codec> _loadBufferAsync(
      image_provider.HitomiCachedImageProvider key,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      ) {
    assert(key == this);
    return ImageLoader().loadBufferAsync(
      image,
      id,
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

  @override
  bool operator ==(dynamic other) {
    if (other is HitomiCachedImageProvider) {
      return ((cacheKey ?? image.hash) == (other.cacheKey ?? other.image.hash)) &&
          scale == other.scale &&
          maxHeight == other.maxHeight &&
          maxWidth == other.maxWidth;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(cacheKey ?? image.hash, scale, maxHeight, maxWidth);

  @override
  String toString() => '$runtimeType("${image.hash}", scale: $scale)';
}
