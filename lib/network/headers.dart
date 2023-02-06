import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:uuid/uuid.dart';

var netConfig = {
  "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
  "accept": "application/vnd.picacomic.com.v1+json",
  "app-channel": "1",
  "app-version":"2.2.1.3.3.4",
  "app-uuid":"defaultUuid",
  "image-quality":"medium",
  "app-platform":"android",
  "app-build-version":"45",
  "content-type":"application/json; charset=UTF-8",
  "content-length":"49",
  "accept-encoding":"gzip",
  "user-agent":"okhttp/3.8.1",
};

String createNonce(){
  var uuid = const Uuid();
  String nonce = uuid.v1();
  return nonce.replaceAll("-", "");
}

String createSignature(String path, String nonce, String time, String method){
  String key = path + time + nonce + method + netConfig["api-key"]!;
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
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": "1",
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "POST"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":"medium",
          "app-platform":"android",
          "app-build-version":"45",
          "Content-Type":"application/json; charset=UTF-8",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1"
        }
    );
  }
  if(method == 'post'){
    return BaseOptions(
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "authorization": token,
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": "1",
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "POST"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":"original",
          "app-platform":"android",
          "app-build-version":"45",
          "Content-Type":"application/json; charset=UTF-8",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1"
        }
    );
  }else{
    return BaseOptions(
        headers: {
          "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
          "authorization": token,
          "accept": "application/vnd.picacomic.com.v1+json",
          "app-channel": "1",
          "time": time,
          "nonce": nonce,
          "signature": createSignature(url, nonce, time, "GET"),
          "app-version":"2.2.1.3.3.4",
          "app-uuid":"defaultUuid",
          "image-quality":"original",
          "app-platform":"android",
          "app-build-version":"45",
          "user-agent":"okhttp/3.8.1",
          "version": "v1.4.1"
        }
    );
  }
}