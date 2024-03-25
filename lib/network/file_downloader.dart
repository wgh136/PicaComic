import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pica_comic/network/http_client.dart';

class FileDownloader{
  final String url;
  final String savePath;
  final int startByte;
  final String? proxy;
  final int maxConcurrent;

  FileDownloader(this.url, this.savePath, this.startByte, this.proxy,
      {this.maxConcurrent = 4});

  /// The current downloaded bytes which is written to file
  late int _currentBytes = startByte;

  /// The current downloaded bytes which may not be written to file
  late int _downloadedBytes = startByte;

  late int _fileSize;

  var dio = Dio();

  File? file;

  int _kChunkSize = 16 * 1024 * 1024;

  bool _canceled = false;

  Future<void> _head() async{
    var res = await dio.head(url);
    var length = res.headers["content-length"]?.first;
    _fileSize = length == null ? 0 : int.parse(length);

    if(_fileSize > 1024 * 1024 * 1024){
      _kChunkSize = 64 * 1024 * 1024;
    } else if(_fileSize > 512 * 1024 * 1024){
      _kChunkSize = 32 * 1024 * 1024;
    }
  }

  Stream<DownloadingStatus> start(){
    var stream = StreamController<DownloadingStatus>();
    _download(stream);
    return stream.stream;
  }

  void _reportStatus(StreamController<DownloadingStatus> stream){
    stream.add(DownloadingStatus(_downloadedBytes, _fileSize, _currentBytes));
  }

  void _download(StreamController<DownloadingStatus> resultStream) async{
    try {
      // open file
      file = File(savePath);
      if (!file!.existsSync()) {
        file!.createSync();
      } else {
        var length = file!.lengthSync();
        if (length > _currentBytes) {
          _currentBytes = 0;
          file!.writeAsBytesSync([], mode: FileMode.write);
        }
      }
      setProxy(proxy);

      // get file size
      await _head();

      if (_canceled) return;

      // check if file is downloaded
      if (_currentBytes >= _fileSize) {
        _reportStatus(resultStream);
        resultStream.close();
        return;
      }

      _reportStatus(resultStream);

      // download
      while (_currentBytes < _fileSize) {
        if (_canceled)  return;
        await _scheduleTasks(resultStream);
      }

      resultStream.add(DownloadingStatus(_currentBytes, _fileSize,
          _currentBytes, true));

      resultStream.close();
    }
    catch(e, s){
      resultStream.addError(e, s);
      resultStream.close();
    }
  }

  Future<void> _scheduleTasks(StreamController<DownloadingStatus> resultStream) async{
    var futures = <Future>[];
    for(var i = 0; i < maxConcurrent; i++){
      var start = _currentBytes + i * _kChunkSize;
      var end = start + _kChunkSize;
      futures.add(_fetchPart(start, end, resultStream));
    }
    await Future.wait(futures);
  }

  Future<void> _fetchPart(int start, int end, StreamController<DownloadingStatus> resultStream) async{
    if(start > _fileSize){
      return;
    }

    if(end > _fileSize){
      end = _fileSize;
    }

    var options = Options(
        responseType: ResponseType.stream,
        headers: {
          "Range": "bytes=$start-${end-1}",
          "Accept": "*/*",
          "Accept-Encoding": "deflate, gzip",
        },
        preserveHeaderCase: true,
    );
    var res = await dio.get<ResponseBody>(url, options: options);
    if(_canceled) return;
    if(res.data == null){
      throw Exception("Failed to download part $start-$end");
    }

    var buffer = <int>[];
    int bytesSinceLastReport = 0;
    await for (var data in res.data!.stream) {
      buffer.addAll(data);
      _downloadedBytes += data.length;
      bytesSinceLastReport += data.length;
      if(bytesSinceLastReport > 128 * 1024){
        _reportStatus(resultStream);
        bytesSinceLastReport = 0;
      }
      if(_canceled) return;
    }

    while(start != _currentBytes){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    file!.writeAsBytesSync(buffer, mode: FileMode.append);
    _currentBytes = end;
    _reportStatus(resultStream);
  }

  void stop(){
    _canceled = true;
  }
}

class DownloadingStatus{
  /// The current downloaded bytes which is written to file
  final int downloadedBytes;
  /// The total bytes of the file
  final int totalBytes;
  /// The current downloaded bytes which may not be written to file
  final int writeBytes;
  /// Whether the download is finished
  final bool isFinished;

  const DownloadingStatus(this.downloadedBytes, this.totalBytes, this.writeBytes,
      [this.isFinished = false]);

  @override
  String toString() {
    return "Downloaded: $downloadedBytes/$totalBytes ${isFinished ? "Finished" : ""}";
  }
}