import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

const String appVersion = "1.5.1";

BaseOptions getHeader(int time, {bool post=false, Map<String, String>? headers}){

  var token = md5.convert(const Utf8Encoder().convert("${time}18comicAPPContent"));

  return BaseOptions(
    receiveDataWhenStatusError: true,
    connectTimeout: const Duration(seconds: 8),
    responseType: ResponseType.bytes,
    headers: {
      "token": token.toString(),
      "tokenparam": "$time,$appVersion",
      "user-agent": "okhttp/3.12.1",
      "accept-encoding": "gzip",
      ...headers??{},
      if(post)
        "Content-Type": "application/x-www-form-urlencoded"
    }
  );
}