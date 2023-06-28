import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/views/jm_views/jm_image_provider/image_recombine.dart';
import '../base.dart';
import '../network/eh_network/eh_main_network.dart';
import '../network/hitomi_network/image.dart';

///用于阅读器的图片缓存管理
class MyCacheManager{
  static MyCacheManager? cache;

  ///用于标记正在加载的项目, 避免出现多个异步函数加载同一张图片
  static Map<String, bool> loadingItems = {};

  factory MyCacheManager() {
    createFolder();
    return cache??(cache = MyCacheManager._create());
  }

  static void createFolder() async{
    var folder = Directory("${(await getTemporaryDirectory()).path}${pathSep}imageCache");
    if(!folder.existsSync()){
        folder.createSync(recursive: true);
    }
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
        for(int i = 0;i<1000-_paths!.length;i++){
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
      await file.writeAsString(const JsonEncoder().convert(_paths),mode: FileMode.writeOnly);
      _paths = null;
    }
    loadingItems.clear();
  }

  /// 获取图片, 适用于没有任何限制的图片链接
  Stream<DownloadProgress> getImage(String url) async*{
    while(loadingItems[url] != null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[url] = true;
    try {
      await readData();
      //检查缓存
      if (_paths![url] != null) {
        if (File(_paths![url]!).existsSync()) {
          yield DownloadProgress(1, 1, url, _paths![url]!);
          return;
        } else {
          _paths!.remove(url);
        }
      }
      var options = BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          followRedirects: true,
          headers: {
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
            "cookie": EhNetwork().cookiesStr
          }
      );
      //生成文件名
      var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
      if (fileName.length > 10) {
        fileName = fileName.substring(0, 10);
      }
      fileName = "$fileName.jpg";
      final savePath = "${(await getTemporaryDirectory())
          .path}${pathSep}imageCache$pathSep$fileName";
      yield DownloadProgress(0, 100, url, savePath);
      var dio = Dio(options);
      var dioRes = await dio.get<ResponseBody>(
          url, options: Options(responseType: ResponseType.stream));
      if (dioRes.data == null) {
        throw Exception("无数据");
      }
      List<int> imageData = [];
      int? expectedBytes;
      try {
        expectedBytes = int.parse(dioRes.data!.headers["Content-Length"]![0]) + 1;
      }
      catch (e) {
        //忽略
      }
      var file = File(savePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      await for (var res in dioRes.data!.stream) {
        imageData.addAll(res);
        file.writeAsBytesSync(res, mode: FileMode.append);
        yield DownloadProgress(
            imageData.length, expectedBytes ?? (imageData.length + 1), url, savePath);
      }
      await saveInfo(url, savePath);
      yield DownloadProgress(1, 1, url, savePath);
    }
    catch(e){
      rethrow;
    }
    finally{
      loadingItems.remove(url);
    }
  }

  ///获取eh图片, 传入的为阅读器地址
  Stream<DownloadProgress> getEhImage(String url) async*{
    while(loadingItems[url] != null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[url] = true;
    try {
      await readData();
      //检查缓存
      if (_paths![url] != null) {
        if (File(_paths![url]!).existsSync()) {
          yield DownloadProgress(1, 1, url, _paths![url]!);
          return;
        } else {
          _paths!.remove(url);
        }
      }
      var options = BaseOptions(
          connectTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          followRedirects: true,
          headers: {
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
            "cookie": EhNetwork().cookiesStr
          }
      );

      //生成文件名
      var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
      if (fileName.length > 10) {
        fileName = fileName.substring(0, 10);
      }
      fileName = "$fileName.jpg";
      final savePath = "${(await getTemporaryDirectory())
          .path}${pathSep}imageCache$pathSep$fileName";
      yield DownloadProgress(0, 100, url, savePath);

      //获取图片地址
      var dio = Dio(options);
      var html = await dio.get(url);
      var document = parse(html.data);
      var image = document.querySelector("img#img")!.attributes["src"]!;
      var nl = document.getElementById("loadfail")!.attributes["onclick"]!;
      if (image == "https://ehgt.org/g/509.gif") {
        throw ImageExceedError();
      }
      var originImage = document
          .querySelector("div#i7 > a")
          ?.attributes["href"];

      Response<ResponseBody> res;
      if (originImage == null) {
        html = await dio.get("$url?nl=${nl.substring(11, nl.length - 2)}");
        document = parse(html.data);
        image = document.querySelector("img#img")!.attributes["src"]!;
        if (image == "https://ehgt.org/g/509.gif") {
          throw ImageExceedError();
        }
      } else {
        image = originImage;
      }
      res =
      await dio.get<ResponseBody>(image, options: Options(responseType: ResponseType.stream));

      if (res.data!.headers["Content-Type"]?[0] == "text/html; charset=UTF-8"
          || res.data!.headers["content-type"]?[0] == "text/html; charset=UTF-8") {
        throw ImageExceedError();
      }

      var stream = res.data!.stream;
      int? expectedBytes;
      try {
        expectedBytes = int.parse(res.data!.headers["Content-Length"]![0]);
      }
      catch (e) {
        try {
          expectedBytes = int.parse(res.data!.headers["content-length"]![0]);
        }
        catch (e) {
          //忽视
        }
      }
      var currentBytes = 0;
      var file = File(savePath);
      if (!file.existsSync()) {
        file.create();
      } else {
        file.deleteSync();
        file.createSync();
      }
      await for (var b in stream) {
        file.writeAsBytesSync(b, mode: FileMode.append);
        currentBytes += b.length;
        yield DownloadProgress(currentBytes, (expectedBytes ?? currentBytes) + 1, url, savePath);
      }
      await saveInfo(url, savePath);
      yield DownloadProgress(1, 1, url, savePath);
    }
    catch(e){
      rethrow;
    }
    finally{
      loadingItems.remove(url);
    }
  }

  ///为Hitomi设计的图片加载函数
  ///
  /// 使用hash标识图片
  Stream<DownloadProgress> getHitomiImage(HitomiFile image, String galleryId) async*{
    while(loadingItems[image.hash] != null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[image.hash] = true;
    try {
      await readData();
      //检查缓存
      if (_paths![image.hash] != null) {
        if (File(_paths![image.hash]!).existsSync()) {
          yield DownloadProgress(1, 1, image.hash, _paths![image.hash]!);
          return;
        } else {
          _paths!.remove(image.hash);
        }
      }
      var directory = Directory("${(await getTemporaryDirectory()).path}${pathSep}imageCache");
      if (!directory.existsSync()) {
        directory.create();
      }
      final gg = GG();
      var url = await gg.urlFromUrlFromHash(galleryId, image, 'webp', null);
      int l;
      for (l = url.length - 1; l >= 0; l--) {
        if (url[l] == '.') {
          break;
        }
      }
      var fileName = image.hash + url.substring(l);
      final savePath = "${(await getTemporaryDirectory())
          .path}${pathSep}imageCache$pathSep$fileName";
      var dio = Dio();
      dio.options.headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        "Referer": "https://hitomi.la/reader/$galleryId.html"
      };
      var file = File(savePath);
      try {
        var res =
        await dio.get<ResponseBody>(url, options: Options(responseType: ResponseType.stream));
        var stream = res.data!.stream;
        int? expectedBytes;
        try {
          expectedBytes = int.parse(res.data!.headers["Content-Length"]![0]);
        }
        catch (e) {
          try {
            expectedBytes = int.parse(res.data!.headers["content-length"]![0]);
          }
          catch (e) {
            //忽视
          }
        }
        if (!file.existsSync()) {
          file.create();
        }
        var currentBytes = 0;
        await for (var b in stream) {
          file.writeAsBytesSync(b.toList(), mode: FileMode.append);
          currentBytes += b.length;
          yield DownloadProgress(currentBytes, expectedBytes ?? (currentBytes + 1), url, savePath);
        }
        yield DownloadProgress(currentBytes, currentBytes, url, savePath);
      }
      catch (e) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        rethrow;
      }
      await saveInfo(image.hash, savePath);
    }
    catch(e){
      rethrow;
    }
    finally{
      loadingItems.remove(image.hash);
    }
  }

  ///获取禁漫图片, 如果缓存中没有, 则尝试下载
  Stream<DownloadProgress> getJmImage(
      String url,
      Map<String, String>? headers,
      {bool jm=true, required String epsId, required String scrambleId, required String bookId}
      ) async*{
    while(loadingItems[url] != null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[url] = true;
    try {
      await readData();
      var directory = Directory("${(await getTemporaryDirectory()).path}${pathSep}imageCache");
      if (!directory.existsSync()) {
        directory.create();
      }
      //检查缓存
      if (_paths![url] != null) {
        if (File(_paths![url]!).existsSync()) {
          yield DownloadProgress(1, 1, url, _paths![url]!);
          return;
        } else {
          _paths!.remove(url);
        }
      }
      //生成文件名
      var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
      if (fileName.length > 10) {
        fileName = fileName.substring(0, 10);
      }
      int l;
      for (l = url.length - 1; l >= 0; l--) {
        if (url[l] == '.') {
          break;
        }
      }
      fileName += url.substring(l);
      final savePath = "${(await getTemporaryDirectory())
          .path}${pathSep}imageCache$pathSep$fileName";

      var dio = Dio();
      yield DownloadProgress(0, 1, url, savePath);

      var bytes = <int>[];
      try {
        var res =
        await dio.get<ResponseBody>(url, options: Options(responseType: ResponseType.stream));
        var stream = res.data!.stream;
        int i = 0;
        await for (var b in stream) {
          //不直接写入文件, 因为需要对图片进行重组, 处理完成后再写入
          bytes.addAll(b.toList());
          //构建虚假的进度条, 由于无法获取jm文件大小, 出此下策
          //每获取到一次数据, 进度条增加1%
          i += 5;
          if (i > 750) {
            i = 750;
          }
          yield DownloadProgress(i, 1000, url, savePath);
        }
      }
      catch (e) {
        rethrow;
      }
      yield DownloadProgress(750, 1000, url, savePath);
      var file = File(savePath);
      if (!file.existsSync()) {
        file.create();
      }
      var newBytes = await startRecombineImage(
          Uint8List.fromList(bytes), epsId, scrambleId, bookId);
      await startWriteFile(WriteInfo(savePath, newBytes));
      //告知完成
      await saveInfo(url, savePath);
      yield DownloadProgress(1, 1, url, savePath);
    }
    catch(e){
      rethrow;
    }
    finally{
      loadingItems.remove(url);
    }
  }

  Future<void> saveInfo(String url, String savePath) async{
    if(_paths == null){
      //此时为退出了阅读器, 数据已清除
      return;
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

  Future<bool> find(String key) async{
    await readData();
    return _paths![key] != null;
  }

  Future<void> delete(String key) async{
    await readData();
    try{
      var file = File(_paths![key]!);
      file.deleteSync();
    }
    catch(e){
      //忽视
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

class ImageExceedError extends Error{
  @override
  String toString()=>"当前IP超出E-Hentai图片限制";
}