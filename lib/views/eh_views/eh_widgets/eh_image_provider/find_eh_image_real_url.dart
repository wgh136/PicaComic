import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:get/get.dart';

///通过阅读器地址获取图片地址
Future<String> getEhImageUrl(String url) async{
  //通过爬虫获取图片地址
  var options = BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: true,
      headers: {
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
      }
  );

  var dio =  Dio(options)
    ..interceptors.add(LogInterceptor());
  var html = await dio.get(url);
  var document = parse(html.data);
  var nl = document.getElementById("loadfail")!.attributes["onclick"]!;
  html = await dio.get("$url?nl=${nl.substring(11,nl.length-2)}");
  document = parse(html.data);
  var res = document.querySelector("img#img")!.attributes["src"]!;
  if(res == "https://ehgt.org/g/509.gif"){
    showMessage(Get.context, "当前IP已超出E-Hentai的图片上限");
    throw ImageExceedError();
  }
  return res;
}

///管理eh阅读器url与实际图片url的对应关系
class EhImageUrlsManager{
  Map<String,dynamic> _urls = {};
  bool loaded = false;

  static EhImageUrlsManager? cache;

  factory EhImageUrlsManager(){
    return cache??(cache = EhImageUrlsManager._create());
  }

  EhImageUrlsManager._create();

  ///储存数据
  ///
  ///为确保在所有平台均可以运行, 使用Json储存数据
  Future<void> saveData() async{
    if(!loaded) return;
    var path = await getApplicationSupportDirectory();
    var file = File("${path.path}${Platform.pathSeparator}urls.json");
    if(!file.existsSync()){
      file.create();
      return;
    }
    file.writeAsStringSync(const JsonEncoder().convert(_urls));
    _urls.clear();
    loaded = false;
  }

  Future<void> readData() async{
    if(loaded)  return;
    loaded = true;
    var path = await getApplicationSupportDirectory();
    var file = File("${path.path}${Platform.pathSeparator}urls.json");
    if(!file.existsSync()){
      return;
    }else{
      _urls = const JsonDecoder().convert(file.readAsStringSync());
    }
  }

  ///获取图片真实地址
  ///
  /// 如果没有记录, 则发送请求并记录
  Future<String> get(String url) async{
    await readData();
    var res =  _urls[url];
    if(res == null){
      try {
        res = await getEhImageUrl(url);
      }
      catch(e){
        rethrow;
      }
      _urls[url] = res;
      //仅记录8000条数据
      if(_urls.length>8000){
        _urls.remove(_urls.keys.first);
      }
    }
    return res;
  }

  Future<void> delete(String url) async{
    await readData();
    _urls.remove(url);
  }

  static Future<String> getUrl(String url) async{
    return EhImageUrlsManager().get(url);
  }

  static Future<void> deleteUrl(String url) async{
    await EhImageUrlsManager().delete(url);
  }
}

class ImageExceedError extends Error{
  @override
  String toString()=>"Image limit exceeded";
}