import 'dart:async' show Future;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/download.dart';

class FileImageProvider extends ImageProvider<FileImageProvider> {

  /// Image provider for downloaded comic
  const FileImageProvider(this.id, this.ep, this.index);

  final String id;

  final int ep;

  final int index;

  @override
  Future<FileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FileImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(FileImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode: decode),
      scale: 1.0,
      debugLabel: key.toString(),
    );
  }

  Future<Codec> _loadAsync(
      FileImageProvider key, {
        required ImageDecoderCallback decode,
      }) async {
    var file = await DownloadManager().getImageAsync(id, ep, index);
    final int lengthInBytes = await file.length();
    if (lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }
    return decode(await ImmutableBuffer.fromFilePath(file.path));
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is FileImageProvider
        && other.id == id
        && other.ep == ep
        && other.index == index;
  }

  @override
  int get hashCode => Object.hash("FileImageProvider", id, ep, index);

  @override
  String toString() => 'FileImageProvider $id $ep $index';
}
