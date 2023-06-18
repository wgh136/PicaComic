import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';

void sendLog(String error, String stacktrace) async{
  try {
    var dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      sendTimeout: const Duration(seconds: 3),
    ));
    await dio.post("https://api.kokoiro.xyz/logs", data: {
      "version": appVersion,
      "error": error,
      "stacktrace": stacktrace
    });
  }
  catch(e){
    //忽视
  }
}