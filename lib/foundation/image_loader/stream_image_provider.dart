import 'dart:async' show Future, StreamController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../image_manager.dart';
import 'base_image_provider.dart';

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

class StreamImageProvider
    extends BaseImageProvider<StreamImageProvider> {

  /// Image provider with [Stream<DownloadProgress>].
  const StreamImageProvider(this.stream, this.key);

  final Stream<DownloadProgress> stream;

  @override
  final String key;

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    chunkEvents.add(const ImageChunkEvent(
        cumulativeBytesLoaded: 0,
        expectedTotalBytes: 100)
    );
    DownloadProgress? finishProgress;

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
  Future<StreamImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }
}
