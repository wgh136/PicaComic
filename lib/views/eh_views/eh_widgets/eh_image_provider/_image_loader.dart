import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';

/// ImageLoader class to load images on IO platforms.
class ImageLoader{

  Future<ui.Codec> loadBufferAsync(
      Gallery gallery,
      int page,
      String? cacheKey,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      int? maxHeight,
      int? maxWidth,
      Map<String, String>? headers,
      Function()? errorListener,
      Function() evictImage) {
    return _load(
      gallery,
      page,
      cacheKey,
      chunkEvents,
      (bytes) async {
        final buffer = await ImmutableBuffer.fromUint8List(bytes);
        try {
          return decode(buffer);
        }
        catch(e){
          ImageManager().delete("${gallery.link}$page");
          throw Exception("Invalid Image Data");
        }
      },
      maxHeight,
      maxWidth,
      headers,
      errorListener,
      evictImage,
    );
  }

  Future<ui.Codec> _load(
    Gallery gallery,
    int page,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    _FileDecoderCallback decode,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    Function()? errorListener,
    Function() evictImage,
  ) async {
    try {
      chunkEvents.add(const ImageChunkEvent(
          cumulativeBytesLoaded: 0,
          expectedTotalBytes: 100)
      );
      var manager = ImageManager();

      DownloadProgress? finishProgress;

      var stream = manager.getEhImageNew(gallery, page);
      await for(var progress in stream){
        if(progress.currentBytes == progress.expectedBytes){
          finishProgress = progress;
        }
        chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: progress.currentBytes,
            expectedTotalBytes: progress.expectedBytes)
        );
      }

      var file = finishProgress!.getFile();
      var bytes = await file.readAsBytes();
      var decoded = await decode(bytes);
      return decoded;
    } catch (e) {
      // Depending on where the exception was thrown, the image cache may not
      // have had a chance to track the key in the cache at all.
      // Schedule a microtask to give the cache a chance to add the key.
      scheduleMicrotask(() {
        evictImage();
      });
      errorListener?.call();
      rethrow;
    } finally {
      await chunkEvents.close();
    }
  }
}

typedef _FileDecoderCallback = Future<ui.Codec> Function(Uint8List);
