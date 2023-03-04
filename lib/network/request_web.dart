import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

Dio request(){
  //返回一个设置好代理的Dio
  var dio = Dio()
    ..interceptors.add(LogInterceptor());
  dio.httpClientAdapter = BrowserHttpClientAdapter();
  return dio;
}