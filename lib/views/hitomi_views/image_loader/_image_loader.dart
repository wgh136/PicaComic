import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';

/// ImageLoader class to load images on IO platforms.
class ImageLoader{

  Future<ui.Codec> loadBufferAsync(
      HitomiFile image,
      String galleryID,
      String? cacheKey,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      int? maxHeight,
      int? maxWidth,
      Map<String, String>? headers,
      Function()? errorListener,
      Function() evictImage) {
    return _load(
      image,
      galleryID,
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

  Future<ui.Codec> _load(
    HitomiFile image,
    String id,
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
      var manager = ImageManager();

      DownloadProgress? finishProgress;

      for(int i = 0; i<3; i++){
        try{
          var stream = manager.getHitomiImage(image, id);
          await for(var progress in stream){
            if(progress.currentBytes == progress.expectedBytes){
              finishProgress = progress;
            }
            chunkEvents.add(ImageChunkEvent(
                cumulativeBytesLoaded: progress.currentBytes,
                expectedTotalBytes: progress.expectedBytes)
            );
          }
          break;
        }
        catch(e){
          if(i == 2){
            rethrow;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
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
