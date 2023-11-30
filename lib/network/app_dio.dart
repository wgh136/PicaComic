import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:pica_comic/network/http_client.dart';
import '../base.dart';

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
        response.statusCode == 200 ? LogLevel.info : LogLevel.error,
        "Network",
        "Response ${response.realUri.toString()}\nheaders:\n${response.headers}\n${response.data.toString()}");
    handler.next(response);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }
}

class AppHttpAdapter implements HttpClientAdapter{
  final adapter = IOHttpClientAdapter();

  @override
  void close({bool force = false}) {
    adapter.close(force: force);
  }

  static void createConfigFile(){
    var file = File("${App.dataPath}/hosts.json");
    if(!file.existsSync()){
      var rule = {
        "http": {
          "picaapi.picacomic.com": "104.18.201.187",
          "img.picacomic.com": "104.18.201.187",
          "storage1.picacomic.com": "104.18.201.187",
          "storage-b.picacomic.com": "104.18.201.187"
        },
        "https": {
          "e-hentai.org": "172.67.0.127",
          "exhentai.org": "178.175.129.254"
        }
      };

      var spaces = ' ' * 4;
      var encoder = JsonEncoder.withIndent(spaces);
      file.writeAsStringSync(encoder.convert(rule));
    }
  }

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async{
    var options = o.copyWith();
    LogManager.addLog(LogLevel.info, "Network",
        "${options.method} ${options.path}\nheaders:\n${options.headers.toString()}\ndata:${options.data}");
    if(appdata.settings[58] == "0"){
      return await adapter.fetch(options, requestStream, cancelFuture);
    }
    createConfigFile();
    var config = const JsonDecoder().convert(File("${App.dataPath}/hosts.json").readAsStringSync());
    if(options.headers["host"] == null && options.headers["Host"] == null){
      options.headers["host"] = options.uri.host;
    }
    if(config["https"][options.uri.host] != null){
      LogManager.addLog(LogLevel.info, "Network",
          "Change host from ${options.uri.host} to ${config["https"][options.uri.host]}");
      options.path = options.path.replaceFirst(options.uri.host, config["https"][options.uri.host]!);
    } else if(config["http"][options.uri.host] != null){
      LogManager.addLog(LogLevel.info, "Network",
          "Change host from ${options.uri.host} to ${config["http"][options.uri.host]}");
      options.path = options.path.replaceFirst(options.uri.host, config["http"][options.uri.host]!);
      options.path = options.path.replaceFirst("https://", "http://");
    }
    options.followRedirects = false;
    var res = await adapter.fetch(options, requestStream, cancelFuture);
    if(res.statusCode == 302){
      var location = res.headers["location"]!.first;
      options.path = options.path.contains("https://")
          ? "https://${options.uri.host}$location"
          : "http://${options.uri.host}$location";
      return await adapter.fetch(options, requestStream, cancelFuture);
    }
    return res;
  }

}

Dio logDio([BaseOptions? options, bool http2 = false]) {
  var dio = Dio(options)..interceptors.add(MyLogInterceptor());
  if (http2) {
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(
        idleTimeout: const Duration(seconds: 10),
        onClientCreate: (_, config) {
          if (proxyHttpOverrides?.proxyStr != null) {
            config.proxy = Uri.parse('http://${proxyHttpOverrides?.proxyStr}');
          }
        },
      ),
    );
  } else {
    dio.httpClientAdapter = AppHttpAdapter();
  }
  return dio;
}


