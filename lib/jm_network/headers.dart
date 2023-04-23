import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

const String jmAppVersion = "1.5.1";

BaseOptions getHeader(int time, {bool post=false, Map<String, String>? headers, bool byte=true}){

  var token = md5.convert(const Utf8Encoder().convert("${time}18comicAPPContent"));

  return BaseOptions(
    receiveDataWhenStatusError: true,
    connectTimeout: const Duration(seconds: 8),
    responseType: byte?ResponseType.bytes:null,
    headers: {
      "token": token.toString(),
      "tokenparam": "$time,$jmAppVersion",
      "user-agent": "okhttp/3.12.1",
      "accept-encoding": "gzip",
      ...headers??{},
      if(post)
        "Content-Type": "application/x-www-form-urlencoded"
    }
  );
}