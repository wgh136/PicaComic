import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/cache_manager.dart';

/// ImageLoader class to load images on IO platforms.
class ImageLoader{

  Stream<ui.Codec> loadBufferAsync(
      String url,
      String? cacheKey,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      int? maxHeight,
      int? maxWidth,
      Map<String, String>? headers,
      Function()? errorListener,
      Function() evictImage) {
    return _load(
      url,
      cacheKey,
      chunkEvents,
      (bytes) async {
        final buffer = await ImmutableBuffer.fromUint8List(bytes);
        return decode(buffer);
      },
      maxHeight,
      maxWidth,
      headers,
      errorListener,
      evictImage,
    );
  }

  Stream<ui.Codec> _load(
    String url,
    String? cacheKey,
    StreamController<ImageChunkEvent> chunkEvents,
    _FileDecoderCallback decode,
    int? maxHeight,
    int? maxWidth,
    Map<String, String>? headers,
    Function()? errorListener,
    Function() evictImage,
  ) async* {
    try {
      chunkEvents.add(const ImageChunkEvent(
          cumulativeBytesLoaded: 0,
          expectedTotalBytes: 100)
      );
      var manager = MyCacheManager();
      var stream = manager.getEhImage(url);

      DownloadProgress? finishProgress;

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
      Codec decoded;
      try {
        decoded = await decode(bytes);
      }
      catch(e){
        await manager.delete(url);
        if(finishProgress.loadFail == null){
          rethrow;
        }
        stream = manager.getEhImage(finishProgress.loadFail!);
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
        decoded = await decode(bytes);
      }
      yield decoded;
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
