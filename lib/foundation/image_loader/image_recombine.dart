import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;
import 'package:crypto/crypto.dart';

/// 转换自 https://github.com/tonquer/JMComic-qt/blob/main/src/tools/tool.py
int _getSegmentationNum(String epsId, String scrambleID, String pictureName) {
  int scrambleId = int.parse(scrambleID);
  int epsID = int.parse(epsId);
  int num = 0;

  if (epsID < scrambleId) {
    num = 0;
  } else if (epsID < 268850) {
    num = 10;
  } else if (epsID > 421926) {
    String string = epsID.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 8;
    num = remainder * 2 + 2;
  } else {
    String string = epsID.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 10;
    num = remainder * 2 + 2;
  }

  return num;
}

/// 转换自 https://github.com/tonquer/JMComic-qt/blob/main/src/tools/tool.py
Future<Uint8List> _segmentationPicture(_RecombinationTask data) async {
  int num = _getSegmentationNum(data.epsId, data.scrambleId, data.bookId);

  if (num <= 1) {
    return data.imgData;
  }
  image.Image srcImg;
  try {
    srcImg = image.decodeImage(data.imgData)!;
  }
  catch(e){
    throw Exception("Failed to decode image: Data length is ${data.imgData.length} bytes");
  }

  int blockSize = (srcImg.height / num).floor();
  int remainder = srcImg.height % num;

  List<Map<String, int>> blocks = [];

  for (int i = 0; i < num; i++) {
    int start = i * blockSize;
    int end = start + blockSize + ((i != num - 1) ? 0 : remainder);
    blocks.add({'start': start, 'end': end});
  }

  image.Image desImg = image.Image(width: srcImg.width, height: srcImg.height);

  int y = 0;
  for (int i = blocks.length - 1; i >= 0; i--) {
    var block = blocks[i];
    int currBlockHeight = block['end']! - block['start']!;
    var range = srcImg.getRange(0, block['start']!, srcImg.width, currBlockHeight);
    var desRange = desImg.getRange(0, y, srcImg.width, currBlockHeight);
    while(range.moveNext() && desRange.moveNext()){
      desRange.current.r = range.current.r;
      desRange.current.g = range.current.g;
      desRange.current.b = range.current.b;
      desRange.current.a = range.current.a;
    }
    y += currBlockHeight;
  }

  return image.encodeJpg(desImg);
}

Future<Uint8List> _recombineImageAndWriteFile(_RecombinationTask data) async {
  var bytes = await _segmentationPicture(data);
  var file = File(data.savePath!);
  if (file.existsSync()) {
    file.deleteSync();
  }
  file.writeAsBytesSync(bytes);
  return bytes;
}


class _RecombinationTask {
  Uint8List imgData;
  String epsId;
  String scrambleId;
  String bookId;
  String? savePath;
  Completer<Uint8List>? completer;

  _RecombinationTask removeCompleter(){
    return _RecombinationTask(imgData, epsId, scrambleId, bookId, null, savePath);
  }

  _RecombinationTask(this.imgData, this.epsId, this.scrambleId, this.bookId, this.completer,
      [this.savePath]);
}

class JmRecombine{
  static Isolate? _isolate;

  static ReceivePort? _receivePort;

  static SendPort? _sendPort;

  static final List<_RecombinationTask> _tasks = [];

  static _RecombinationTask? _current;

  static Timer? _timer;

  static Future<Uint8List> recombineImage(Uint8List imgData, String epsId,
      String scrambleId, String bookId, String savePath) async{
    _timer?.cancel();
    _timer = null;
    Completer<Uint8List> completer = Completer();
    _RecombinationTask task =
      _RecombinationTask(imgData, epsId, scrambleId, bookId, completer, savePath);
    _tasks.add(task);
    if(_isolate == null){
      await _start();
    } else {
      _pushTask();
    }
    return completer.future;
  }

  static void _pushTask(){
    if(_tasks.isEmpty){
      _timer ??= Timer(const Duration(seconds: 5), (){
          if(_tasks.isEmpty){
            _isolate!.kill(priority: Isolate.immediate);
            _isolate = null;
            _receivePort?.close();
            _receivePort = null;
            _sendPort = null;
            _timer = null;
          }
        });
      return;
    }

    if(_sendPort != null && _current == null){
      _current = _tasks.removeAt(0);
      _sendPort!.send(_current!.removeCompleter());
    }
  }

  static _start() async{
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_run, _receivePort!.sendPort);
    _listen();
  }

  static void _listen(){
    _receivePort!.listen((message) {
      if (message is SendPort){
        _sendPort = message;
        _pushTask();
      } else if(message is Uint8List){
        _current!.completer!.complete(message);
        _current = null;
        _pushTask();
      }
    });
  }

  static void _run(SendPort port){
    _receivePort = ReceivePort();
    _receivePort!.listen((message) async{
      if (message is _RecombinationTask){
        _RecombinationTask task = message;
        Uint8List bytes = await _recombineImageAndWriteFile(task);
        port.send(bytes);
      }
    });
    port.send(_receivePort!.sendPort);
  }
}

///启动一个新的线程转换图片并且写入文件
Future<Uint8List> startRecombineAndWriteImage(Uint8List imgData, String epsId,
    String scrambleId, String bookId, String savePath) {
  return JmRecombine.recombineImage(imgData, epsId, scrambleId, bookId, savePath);
}
