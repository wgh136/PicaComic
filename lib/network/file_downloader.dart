import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pica_comic/network/http_client.dart';

class FileDownloader{
  final String url;
  final String savePath;
  final int startByte;
  final String? proxy;

  FileDownloader(this.url, this.savePath, this.startByte, this.proxy);

  late int currentBytes = startByte;

  var token = CancelToken();

  Stream<DownloadingStatus> download() async*{
    var file = File(savePath);
    if(!file.existsSync()){
      file.createSync();
    } else if(startByte == 0){
      file.writeAsBytesSync([]);
    }
    setProxy(proxy);
    var dio = Dio();
    var buffer = <int>[];
    var res =
        await dio.get<ResponseBody>(
            url,
            options: Options(responseType: ResponseType.stream, headers: {
              "range": "bytes=$currentBytes-"
            }),
            cancelToken: token,
        );
    var length = res.headers["content-length"]?.first;
    var total = length == null ? null : int.parse(length);
    if(currentBytes == total){
      yield DownloadingStatus(currentBytes, currentBytes);
      return;
    }
    yield DownloadingStatus(currentBytes, total ?? (buffer.length + 1));
    if(res.data == null){
      throw Exception("Empty data");
    }
    await for(var data in res.data!.stream){
      buffer.addAll(data);
      if(buffer.length > 1024 * 2) {
        currentBytes += buffer.length;
        yield DownloadingStatus(currentBytes, total ?? (currentBytes + 1));
        file.writeAsBytesSync(buffer, mode: FileMode.append);
        buffer.clear();
      }
    }
    if(buffer.isNotEmpty) {
      currentBytes += buffer.length;
      file.writeAsBytesSync(buffer, mode: FileMode.append);
      buffer.clear();
    }
    yield DownloadingStatus(currentBytes, currentBytes);
  }

  void stop(){
    token.cancel();
  }
}

class DownloadingStatus{
  final int downloadedBytes;
  final int totalBytes;

  const DownloadingStatus(this.downloadedBytes, this.totalBytes);
}