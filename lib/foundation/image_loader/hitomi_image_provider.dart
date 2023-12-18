import 'dart:async' show Future, StreamController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import '../image_manager.dart';
import 'base_image_provider.dart';

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

class HitomiCachedImageProvider
    extends BaseImageProvider<HitomiCachedImageProvider> {

  /// Image provider for normal image.
  const HitomiCachedImageProvider(this.image, this.id);

  ///Hitomi图像信息
  final HitomiFile image;

  ///画廊ID
  final String id;

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    chunkEvents.add(const ImageChunkEvent(
        cumulativeBytesLoaded: 0,
        expectedTotalBytes: 100)
    );
    var manager = ImageManager();
    DownloadProgress? finishProgress;

    var stream = manager.getHitomiImage(image, id);
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
  Future<HitomiCachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => image.hash;
}
