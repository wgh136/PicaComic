import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:pica_comic/network/http_client.dart';
import '../base.dart';
import '../foundation/app.dart';

class MyLogInterceptor implements Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LogManager.addLog(LogLevel.error, "Network",
        "${err.requestOptions.method} ${err.requestOptions.path}\n$err");
    handler.next(err);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    LogManager.addLog(
        (response.statusCode != null && response.statusCode! < 400)
            ? LogLevel.info : LogLevel.error,
        "Network",
        "Response ${response.realUri.toString()} ${response.statusCode}\nheaders:\n${response.headers}\n${response.data.toString()}");
    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }
}

class AppHttpAdapter implements HttpClientAdapter{
  final HttpClientAdapter adapter;

  AppHttpAdapter(bool http2):
      adapter = http2 ? Http2Adapter(ConnectionManager(
        idleTimeout: const Duration(seconds: 10),
        onClientCreate: (_, config) {
          if (proxyHttpOverrides?.proxyStr != null && appdata.settings[58] != "1") {
            config.proxy = Uri.parse('http://${proxyHttpOverrides?.proxyStr}');
          }
        },
      ),) : IOHttpClientAdapter();

  @override
  void close({bool force = false}) {
    adapter.close(force: force);
  }


  /// 直接使用ip访问绕过sni
  bool changeHost(RequestOptions options){
    var config = const JsonDecoder().convert(File("${App.dataPath}/rule.json").readAsStringSync());
    if((config["sni"] ?? []).contains(options.uri.host) && (config["rule"] ?? {})[options.uri.host] != null) {
      options.path = options.path.replaceFirst(
          options.uri.host, config["rule"][options.uri.host]!);
      return true;
    }
    return false;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async{
    var options = o.copyWith();
    LogManager.addLog(LogLevel.info, "Network",
        "${options.method} ${options.path}\nheaders:\n${options.headers.toString()}\ndata:${options.data}");
    if(appdata.settings[58] == "0"){
      return await adapter.fetch(options, requestStream, cancelFuture);
    }
    if(options.headers["host"] == null && options.headers["Host"] == null){
      options.headers["host"] = options.uri.host;
    }
    if(!changeHost(options)){
      return await adapter.fetch(options, requestStream, cancelFuture);
    }
    options.followRedirects = false;
    var res = await adapter.fetch(options, requestStream, cancelFuture);
    while(res.statusCode < 400 && res.statusCode > 300){
      var location = res.headers["location"]!.first;
      if(location.contains("http") && Uri.tryParse(location) != null){
        if(Uri.parse(location).host != o.uri.host){
          options.path = location;
          changeHost(options);
          res = await adapter.fetch(options, requestStream, cancelFuture);
        } else {
          location = Uri
              .parse(location)
              .path;
          options.path = options.path.contains("https://")
              ? "https://${options.uri.host}$location"
              : "http://${options.uri.host}$location";
          res = await adapter.fetch(options, requestStream, cancelFuture);
        }
      } else {
        options.path = options.path.contains("https://")
            ? "https://${options.uri.host}$location"
            : "http://${options.uri.host}$location";
        res = await adapter.fetch(options, requestStream, cancelFuture);
      }
    }
    return res;
  }

}

Dio logDio([BaseOptions? options, bool http2 = false]) {
  var dio = Dio(options)..interceptors.add(MyLogInterceptor());
  dio.httpClientAdapter = AppHttpAdapter(http2);
  return dio;
}


