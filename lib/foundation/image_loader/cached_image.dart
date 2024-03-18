import 'dart:async' show Future, StreamController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../image_manager.dart';
import 'base_image_provider.dart';
import 'cached_image.dart' as image_provider;

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

class CachedImageProvider
    extends BaseImageProvider<image_provider.CachedImageProvider> {

  /// Image provider for normal image.
  const CachedImageProvider(this.url, {this.headers});

  final String url;

  final Map<String, String>? headers;

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    chunkEvents.add(const ImageChunkEvent(
        cumulativeBytesLoaded: 0,
        expectedTotalBytes: 100)
    );
    var manager = ImageManager();
    DownloadProgress? finishProgress;

    var stream = manager.getImage(url, headers);
    await for (var progress in stream) {
      if (progress.currentBytes == progress.expectedBytes) {
        finishProgress = progress;
      }
      chunkEvents.add(ImageChunkEvent(
          cumulativeBytesLoaded: progress.currentBytes,
          expectedTotalBytes: progress.expectedBytes)
      );
    }

    if(finishProgress!.data != null){
      return finishProgress.data!;
    }

    var file = finishProgress.getFile();
    return await file.readAsBytes();
  }

  @override
  Future<CachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => url;
}
