import 'package:dio/dio.dart';
import 'package:pica_comic/foundation/log.dart';

class MyLogInterceptor implements Interceptor{
  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    LogManager.addLog(LogLevel.error, "Network", "${err.requestOptions.method} ${err.requestOptions.path}\n$err");
    handler.next(err);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    LogManager.addLog(LogLevel.info, "Network", "${options.method} ${options.path}\nheaders:\n${options.headers.toString()}\ndata:${options.data}");
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    LogManager.addLog(response.statusCode==200?LogLevel.info:LogLevel.error, "Network", "Response ${response.realUri.toString()}\nheaders:\n${response.headers}\n${response.data.toString()}");
    handler.next(response);
  }

}

Dio logDio([BaseOptions? options]){
  return Dio(options)..interceptors.add(MyLogInterceptor());
}