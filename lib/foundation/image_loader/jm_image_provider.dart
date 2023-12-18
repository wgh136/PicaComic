import 'dart:async' show Future, StreamController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../image_manager.dart';
import 'base_image_provider.dart';

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

class JmCachedImageProvider
    extends BaseImageProvider<JmCachedImageProvider> {

  /// Image provider for jm image.
  const JmCachedImageProvider(this.url, this.epsId);

  final String url;

  final String epsId;

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    chunkEvents.add(const ImageChunkEvent(
        cumulativeBytesLoaded: 0,
        expectedTotalBytes: 100)
    );
    var manager = ImageManager();
    DownloadProgress? finishProgress;

    var bookId = "";
    for(int i = url.length-1;i>=0;i--){
      if(url[i] == '/'){
        bookId = url.substring(i+1,url.length-5);
        break;
      }
    }
    var stream = manager.getJmImage(url, {}, epsId: epsId, scrambleId: "220980", bookId: bookId);
    await for (var progress in stream) {
      if (progress.currentBytes == progress.expectedBytes) {
        finishProgress = progress;
      }
      chunkEvents.add(ImageChunkEvent(
          cumulativeBytesLoaded: progress.currentBytes,
          expectedTotalBytes: progress.expectedBytes)
      );
    }

    var file = finishProgress!.getFile();
    return await file.readAsBytes();
  }

  @override
  Future<JmCachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => url;
}
