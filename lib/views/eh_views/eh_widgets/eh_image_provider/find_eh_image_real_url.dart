import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';

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
  //如果ip被ban, 解析失败会出现错误
  return document.querySelector("img#img")!.attributes["src"]!;
}

///管理eh阅读器url与实际图片url的对应关系
class EhImageUrlsManager{
  Map<String,dynamic> _urls = {};

  ///储存数据
  ///为确保在所有平台均可以运行, 使用Json储存数据
  Future<void> saveData() async{
    //仅记录8000条数据
    if(_urls.length>8000){
      _urls.remove(_urls.keys.first);
    }
    var path = await getApplicationSupportDirectory();
    var file = File("${path.path}${Platform.pathSeparator}urls.json");
    if(!file.existsSync()){
      file.create();
      return;
    }
    file.writeAsStringSync(const JsonEncoder().convert(_urls));
  }

  Future<void> readData() async{
    var path = await getApplicationSupportDirectory();
    var file = File("${path.path}${Platform.pathSeparator}urls.json");
    if(!file.existsSync()){
      return;
    }else{
      _urls = const JsonDecoder().convert(file.readAsStringSync());
    }
  }

  Future<String> get(String url) async{
    await readData();
    var res =  _urls[url];
    if(res == null){
      try {
        res = await getEhImageUrl(url);
      }
      catch(e){
        _urls.clear();
        rethrow;
      }
      _urls[url] = res;
      await saveData();
    }
    _urls.clear();
    return res;
  }

  Future<void> delete(String url) async{
    await readData();
    _urls.remove(url);
    await saveData();
  }
}