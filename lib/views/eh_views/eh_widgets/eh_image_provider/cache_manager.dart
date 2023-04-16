import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../../../base.dart';

///提供一个简单的图片缓存管理
class MyCacheManager{
  static MyCacheManager? cache;

  factory MyCacheManager() {
    return cache??(cache = MyCacheManager._create());
  }

  MyCacheManager._create();

  Map<String, String>? _paths;

  Future<void> readData() async{
    if(_paths == null){
      var appDataPath = (await getApplicationSupportDirectory()).path;
      var file = File("$appDataPath${pathSep}cache.json");
      if(file.existsSync()){
        _paths = Map<String, String>.from(const JsonDecoder().convert(await file.readAsString()));
      }else{
        _paths = {};
      }
    }
  }

  ///保存数据同时清除内存中的数据
  Future<void> saveData() async{
    if(_paths != null){
      var appDataPath = (await getApplicationSupportDirectory()).path;
      var file = File("$appDataPath${pathSep}cache.json");
      if(! file.existsSync()){
        await file.create();
      }
      while(_paths!.length > 8000){
        //删除数据, 过多的记录没有意义
        _paths!.remove(_paths!.keys.first);
      }
      await file.writeAsString(const JsonEncoder().convert(_paths),mode: FileMode.writeOnly);
      _paths = null;
    }
  }

  ///获取图片, 如果缓存中没有, 则尝试下载
  Stream<DownloadProgress> getImage(String url, Map<String, String>? headers) async*{
    await readData();
    var directory = Directory("${(await getTemporaryDirectory()).path}${pathSep}imageCache");
    if(!directory.existsSync()){
      directory.create();
    }

    //检查缓存
    if(_paths![url] != null){
      if(File(_paths![url]!).existsSync()) {
        yield DownloadProgress(1, 1, url, _paths![url]!);
      }else{
        _paths!.remove(url);
      }
    }
    //获取信息
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
    yield DownloadProgress(0, 1, url, savePath);

    try{
      var res =
          await dio.get<ResponseBody>(url, options: Options(responseType: ResponseType.stream));
      var stream = res.data!.stream;
      var file = File(savePath);
      if(! file.existsSync()){
        file.create();
      }
      int? expectedBytes;
      try {
        expectedBytes = int.parse(res.data!.headers["Content-Length"]![0]);
      }
      catch(e){
        try{
          expectedBytes = int.parse(res.data!.headers["content-length"]![0]);
        }
        catch(e){
          //忽视
        }
      }
      var currentBytes = 0;
      await for (var bytes in stream) {
        file.writeAsBytesSync(bytes.toList(),mode: FileMode.append);
        currentBytes += bytes.length;
        yield DownloadProgress(currentBytes, expectedBytes??currentBytes, url, savePath);
      }
    }
    catch(e){
      rethrow;
    }

    yield DownloadProgress(1, 1, url, savePath);
    saveInfo(url, savePath);
  }

  Future<void> saveInfo(String url, String savePath) async{
    _paths![url] = savePath;
    //await saveData();
  }

  Future<File?> getFile(String url) async{
    await readData();
    return _paths?[url]==null?null:File(_paths![url]!);
  }
}

@immutable
class DownloadProgress{
  final int _currentBytes;
  final int _expectedBytes;
  final String url;
  final String savePath;

  get currentBytes => _currentBytes;
  get expectedBytes => _expectedBytes;

  const DownloadProgress(this._currentBytes, this._expectedBytes, this.url, this.savePath);

  File getFile() => File(savePath);
}