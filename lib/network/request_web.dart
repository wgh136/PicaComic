import 'package:dio/dio.dart';
import 'package:dio/browser.dart';

Dio request(){
  var dio = Dio()
    ..interceptors.add(LogInterceptor());
  dio.httpClientAdapter = BrowserHttpClientAdapter();
  return dio;
}