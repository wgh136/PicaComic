import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import '../../base.dart';

BaseOptions getHeader(int time, {bool post=false, Map<String, String>? headers, bool byte=true}){

  var token = md5.convert(const Utf8Encoder().convert("$time${appdata.jmAuth[2]}"));

  return BaseOptions(
    receiveDataWhenStatusError: true,
    connectTimeout: const Duration(seconds: 8),
    responseType: byte?ResponseType.bytes:null,
    headers: {
      "token": token.toString(),
      "tokenparam": "$time,${appdata.jmAuth[1]}",
      "user-agent": appdata.jmAuth[3],
      "accept-encoding": "gzip",
      ...headers??{},
      if(post)
        "Content-Type": "application/x-www-form-urlencoded"
    }
  );
}