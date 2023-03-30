import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../tools/proxy.dart';

Future<Dio> request() async{
  //返回一个设置好代理的Dio
  var dio = Dio()
    ..interceptors.add(LogInterceptor());
  if(GetPlatform.isWindows) {
    var proxy = await getProxy();
    if(kDebugMode){
      print(proxy);
    }
    if(proxy!=null) {
      dio.httpClientAdapter = IOHttpClientAdapter()
      ..onHttpClientCreate = (client){
        client.findProxy = (uri) {
          return 'PROXY $proxy';
        };
        return client;
      };
    }
  }
  return dio;
}