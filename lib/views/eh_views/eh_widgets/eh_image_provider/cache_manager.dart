import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../../base.dart';

///提供一个简单的图片缓存管理
class MyCacheManager{
  Map<String, String>? _paths;

  Future<void> readData() async{
    if(_paths == null){
      var appDataPath = (await getApplicationSupportDirectory()).path;
      var file = File("$appDataPath${pathSep}cache.json");
      if(file.existsSync()){
        _paths = const JsonDecoder().convert(await file.readAsString());
      }else{
        _paths = {};
      }
    }
  }

  Future<void> saveData() async{
    if(_paths != null){
      var appDataPath = (await getApplicationSupportDirectory()).path;
      var file = File("$appDataPath${pathSep}cache.json");
      if(! file.existsSync()){
        await file.create();
      }
      await file.writeAsString(const JsonEncoder().convert(_paths),mode: FileMode.writeOnly);
      _paths = null;
    }
  }

  Future<DownloadProgress> getImage(String url, Map<String, String>? headers) async{
    await readData();
    if(_paths![url] != null){
      return DownloadProgress(0, (p0, p1) {}, url, _paths![url]!);
    }
    var fileName = "";
    int l;
    for(l = url.length-1;l>=0;l--){
      if(url[l] == '/'){
        break;
      }
    }
    fileName = url.substring(l+1);
    final savePath = "${(await getTemporaryDirectory()).path}${pathSep}imageCache$pathSep$fileName";
    var dio = Dio();
    var downloadProgress = DownloadProgress(1, saveInfo, url, savePath);
    dio.download(
        url,
        savePath,
        onReceiveProgress: downloadProgress.onReceiveProgress,
        options: Options(
          headers: headers
        )
    );
    return downloadProgress;
  }

  Future<void> saveInfo(String url, String savePath) async{
    _paths![url] = savePath;
    await saveData();
  }
}

class DownloadProgress{
  int _currentBytes = 0;
  int _expectedBytes;
  final String url;
  final String savePath;
  void Function(String, String) whenFinish;

  get currentBytes => _currentBytes;
  get expectedBytes => _expectedBytes;

  DownloadProgress(this._expectedBytes, this.whenFinish, this.url, this.savePath);

  void onReceiveProgress(int a, int b){
    _currentBytes = a;
    _expectedBytes = b;
  }

  File getFile() => File(savePath);
}