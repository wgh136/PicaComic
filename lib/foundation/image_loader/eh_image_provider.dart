import 'dart:async' show Future, StreamController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../network/eh_network/eh_models.dart';
import '../image_manager.dart';
import 'base_image_provider.dart';
import 'eh_image_provider.dart' as image_provider;

/// Function which is called after loading the image failed.
typedef ErrorListener = void Function();

class EhCachedImageProvider
    extends BaseImageProvider<image_provider.EhCachedImageProvider> {

  /// Image provider for eh image.
  const EhCachedImageProvider(this.gallery, this.page);

  final Gallery gallery;

  final int page;

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    chunkEvents.add(const ImageChunkEvent(
        cumulativeBytesLoaded: 0,
        expectedTotalBytes: 100)
    );
    var manager = ImageManager();
    DownloadProgress? finishProgress;

    var stream = manager.getEhImageNew(gallery, page);
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
  Future<EhCachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => "${gallery.link} : $page";
}
