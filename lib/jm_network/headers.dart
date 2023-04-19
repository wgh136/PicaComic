import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';


BaseOptions getHeader(int time){

  var token = md5.convert(const Utf8Encoder().convert("${time}18comicAPPContent"));

  return BaseOptions(
    receiveDataWhenStatusError: true,
    connectTimeout: const Duration(seconds: 8),
    responseType: ResponseType.bytes,
    headers: {
      "token": token.toString(),
      "tokenparam": "$time,1.4.7",
      "user-agent": "okhttp/3.12.1",
      "accept-encoding": "gzip",
    }
  );
}

Options getHeader2(){
  int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

  var token = md5.convert(const Utf8Encoder().convert("${time}18comicAPPContent"));

  return Options(
      receiveDataWhenStatusError: true,
      headers: {
        "token": token.toString(),
        "tokenparam": "$time,1.4.7",
        "user-agent": "okhttp/3.12.1",
        "accept-encoding": "gzip",
      }
  );
}