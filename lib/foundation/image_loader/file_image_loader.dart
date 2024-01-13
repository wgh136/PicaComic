import 'dart:async' show Future, StreamController;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/download.dart';
import 'base_image_provider.dart';

class FileImageProvider
    extends BaseImageProvider<FileImageProvider> {

  /// Image provider for downloaded comic
  const FileImageProvider(this.id, this.ep, this.index);

  final String id;

  final int ep;

  final int index;

  @override
  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents) async{
    var file = await DownloadManager().getImageAsync(id, ep, index);
    return await file.readAsBytes();
  }

  @override
  Future<FileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  String get key => "$id:$ep:$index";
}
