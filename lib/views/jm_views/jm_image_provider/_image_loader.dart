import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_image_provider/cache_manager.dart';
import 'image_recombine.dart';


/// 为禁漫提供的ImageLoader class, 需要对image重组
class ImageLoader{

  Stream<ui.Codec> loadBufferAsync(
      String url,
      String? cacheKey,
      StreamController<ImageChunkEvent> chunkEvents,
      DecoderBufferCallback decode,
      int? maxHeight,
      int? maxWidth,
      Map<String, String>? headers,
      String epsId,
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
      epsId,
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
      String epsId
      ) async* {
    try {

      var manager = MyCacheManager();
      var stream = manager.getImage(url, headers);

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
      var bookId = "";
      for(int i = url.length-1;i>=0;i--){
        if(url[i] == '/'){
          bookId = url.substring(i+1,url.length-5);
          break;
        }
      }
      bytes = segmentationPicture(bytes, epsId, "220980", bookId);
      var decoded = await decode(bytes);
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