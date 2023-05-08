import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:pica_comic/views/jm_views/jm_image_provider/image_recombine.dart';
import '../../../../base.dart';

///提供一个简单的图片缓存管理
///
/// 此缓存管理用于eh和禁漫阅读器,
/// 前者在加载时需要爬取url, 后者需要对图片拆分重组
///
/// 看个本子真不容易 ε(┬┬﹏┬┬)3
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
      if(_paths!.length > 1000){
        var keys = _paths!.keys.toList();
        for(int i = keys.length-1;i>=1000;i--){
          var file = File(_paths![keys[i]]!);
          if(file.existsSync()){
            file.deleteSync();
          }
          _paths!.remove(keys[i]);
        }
      }
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
  Stream<DownloadProgress> getImage(String url, Map<String, String>? headers, {bool jm=false, String? epsId, String? scrambleId, String? bookId}) async*{
    if(jm && (epsId==null || scrambleId == null || bookId == null)){
      throw ArgumentError("参数不正确");
    }

    await readData();
    var directory = Directory("${(await getTemporaryDirectory()).path}${pathSep}imageCache");
    if(!directory.existsSync()){
      directory.create();
    }
    //检查缓存
    if(_paths![url] != null){
      if(File(_paths![url]!).existsSync()) {
        yield DownloadProgress(1, 1, url, _paths![url]!);
        return;
      }else{
        _paths!.remove(url);
      }
    }
    //生成文件名
    var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
    if(fileName.length>10){
      fileName = fileName.substring(0,10);
    }
    int l;
    for(l = url.length-1;l>=0;l--){
      if(url[l] == '.'){
        break;
      }
    }
    fileName += url.substring(l);
    final savePath = "${(await getTemporaryDirectory()).path}${pathSep}imageCache$pathSep$fileName";

    var dio = Dio();
    yield DownloadProgress(0, 1, url, savePath);

    var bytes = <int>[];
    try{
      var res =
          await dio.get<ResponseBody>(url, options: Options(responseType: ResponseType.stream));
      var stream = res.data!.stream;
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

      await for (var b in stream) {
        //不直接写入文件, 因为禁漫太离谱了, 处理完成后再写入
        bytes.addAll(b.toList());
        currentBytes += b.length;
        if(jm) {
          //构建虚假的进度条, 由于无法获取jm文件大小, 出此下策
          //当获取到数据时, 就告知完成一半
          yield DownloadProgress((currentBytes * 0.5).floor(), expectedBytes??currentBytes, url, savePath);
        } else {
          //由于未完成写入文件, 此处加一, 告知加载未完成
          yield DownloadProgress(currentBytes, (expectedBytes??currentBytes)+1, url, savePath);
        }
      }
      if(jm) {
        //当获取到数据时, 告知完成3/4
        yield DownloadProgress((currentBytes * 0.75).floor(), expectedBytes??currentBytes, url, savePath);
      }
    }
    catch(e){
      rethrow;
    }

    var file = File(savePath);
    if(! file.existsSync()){
      file.create();
    }
    if(jm) {
      var newBytes = await startRecombineImage(Uint8List.fromList(bytes), epsId!, scrambleId!, bookId!);
      await startWriteFile(WriteInfo(savePath, newBytes));
    } else {
      await startWriteFile(WriteInfo(savePath, bytes));
    }
    //告知完成
    await saveInfo(url, savePath);
    yield DownloadProgress(1, 1, url, savePath);
  }

  Future<void> saveInfo(String url, String savePath) async{
    if(_paths == null){
      //此时为退出了阅读器, 数据已清除
      var file = File(savePath);
      file.deleteSync();
      throw StateError("已退出阅读器");
    }
    _paths![url] = savePath;
    //await saveData();
  }

  Future<File?> getFile(String url) async{
    await readData();
    return _paths?[url]==null?null:File(_paths![url]!);
  }

  Future<void> clear() async{
    var appDataPath = (await getApplicationSupportDirectory()).path;
    var file = File("$appDataPath${pathSep}cache.json");
    if(file.existsSync()) {
      file.delete();
    }
    if(_paths != null){
      _paths!.clear();
    }
    final savePath = Directory("${(await getTemporaryDirectory()).path}${pathSep}imageCache");
    if(savePath.existsSync()) {
      savePath.deleteSync(recursive: true);
    }
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

class WriteInfo{
  String path;
  List<int> bytes;

  WriteInfo(this.path, this.bytes);
}

Future<void> writeData(WriteInfo info) async{
  var file = File(info.path);
  if(!file.existsSync()){
    file.createSync();
  }
  file.writeAsBytesSync(info.bytes);
}

Future<void> startWriteFile(WriteInfo info) async{
  return compute(writeData, info);
}