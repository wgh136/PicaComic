import 'dart:async' show Future, StreamController, scheduleMicrotask;
import 'dart:ui' as ui show Codec;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract class BaseImageProvider<T extends BaseImageProvider<T>> extends ImageProvider<T>{
  const BaseImageProvider();

  @override
  ImageStreamCompleter loadImage(T key,
      ImageDecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadBufferAsync(key, chunkEvents, decode),
      chunkEvents: chunkEvents.stream,
      scale: 1.0,
      informationCollector: () sync* {
        yield DiagnosticsProperty<ImageProvider>(
          'Image provider: $this \n Image key: $key',
          this,
          style: DiagnosticsTreeStyle.errorProperty,
        );
      },
    );
  }

  Future<ui.Codec> _loadBufferAsync(
      T key,
      StreamController<ImageChunkEvent> chunkEvents,
      ImageDecoderCallback decode,
      ) async{
    try {
      int retryTime = 1;

      while(true){
        try {
          final buffer = await ImmutableBuffer.fromUint8List(
              await load(chunkEvents));
          return decode(buffer);
        }
        catch(e){
          if(e.toString().contains("Your IP address")){
            rethrow;
          }
          retryTime <<= 1;
          if(retryTime > (2 << 6)){
            rethrow;
          }
          await Future.delayed(Duration(seconds: retryTime));
        }
      }

    }
    catch(e){
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    }
    finally{
      chunkEvents.close();
    }
  }

  Future<Uint8List> load(StreamController<ImageChunkEvent> chunkEvents);

  String get key;

  @override
  bool operator ==(Object other) {
    return other is BaseImageProvider<T> && key == other.key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() {
    return "$runtimeType($key)";
  }
}

typedef FileDecoderCallback = Future<ui.Codec> Function(Uint8List);