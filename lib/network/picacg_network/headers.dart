import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:pica_comic/base.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

var apiKey = "C69BAF41DA5ABD1FFEDC6D2FEA56B";

String createNonce(){
  var uuid = const Uuid();
  String nonce = uuid.v1();
  return nonce.replaceAll("-", "");
}

String createSignature(String path, String nonce, String time, String method){
  String key = path + time + nonce + method + apiKey;
  String data = '~d}\$Q7\$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn';
  var s = utf8.encode(key.toLowerCase());
  var f = utf8.encode(data);
  var hmacSha256 = Hmac(sha256,f);
  var digest = hmacSha256.convert(s);
  return digest.toString();
}

BaseOptions getHeaders(String method,String token,String url){
  var nonce = createNonce();
  var time = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  if(token == ""){
    return BaseOptions(
       connectTimeout: const Duration(milliseconds: 8000),
        receiveTimeout: const Duration(milliseconds: 8000),
        sendTimeout: const Duration(milliseconds: 8000),
        receiveDataWhenStatusError: true,
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": appdata.appChannel,
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "POST"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":appdata.imageQuality,
          "app-platform":"android",
          "app-build-version":"45",
          "Content-Type":"application/json; charset=UTF-8",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1",
          "Host": "picaapi.picacomic.com"
        }
    );
  }
  if(method == 'post'){
    return BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(milliseconds: 8000),
        receiveTimeout: const Duration(milliseconds: 8000),
        sendTimeout: const Duration(milliseconds: 8000),
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "authorization": token,
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": appdata.appChannel,
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "POST"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":appdata.imageQuality,
          "app-platform":"android",
          "app-build-version":"45",
          "content-Type":"application/json; charset=UTF-8",
          "accept-encoding": "gzip",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1",
          "Host": "picaapi.picacomic.com"
        }
    );
  }else if(method == "get"){
    return BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(milliseconds: 8000),
        receiveTimeout: const Duration(milliseconds: 8000),
        sendTimeout: const Duration(milliseconds: 8000),
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "authorization": token,
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": appdata.appChannel,
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "GET"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":appdata.imageQuality,
          "app-platform":"android",
          "app-build-version":"45",
          "accept-encoding": "gzip",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1",
          "Host": "picaapi.picacomic.com"
        }
    );
  }else{
    return BaseOptions(
        receiveDataWhenStatusError: true,
        connectTimeout: const Duration(milliseconds: 8000),
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "authorization": token,
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": appdata.appChannel,
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "PUT"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":appdata.imageQuality,
          "app-platform":"android",
          "app-build-version":"45",
          "Content-Type":"application/json; charset=UTF-8",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1",
          "Host": "picaapi.picacomic.com"
        }
    );
  }
}