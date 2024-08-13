import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:pica_comic/comic_source/built_in/picacg.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

var apiKey = "C69BAF41DA5ABD1FFEDC6D2FEA56B";

String createNonce() {
  var uuid = const Uuid();
  String nonce = uuid.v1();
  return nonce.replaceAll("-", "");
}

String createSignature(String path, String nonce, String time, String method) {
  String key = path + time + nonce + method + apiKey;
  String data =
      '~d}\$Q7\$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn';
  var s = utf8.encode(key.toLowerCase());
  var f = utf8.encode(data);
  var hmacSha256 = Hmac(sha256, f);
  var digest = hmacSha256.convert(s);
  return digest.toString();
}

BaseOptions getHeaders(String method, String token, String url) {
  var nonce = createNonce();
  var time = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
  var signature = createSignature(url, nonce, time, method.toUpperCase());
  var headers = {
    "api-key": "C69BAF41DA5ABD1FFEDC6D2FEA56B",
    "accept": "application/vnd.picacomic.com.v1+json",
    "app-channel": picacg.data['appChannel'] ?? '3',
    "authorization": token,
    "time": time,
    "nonce": nonce,
    "app-version": "2.2.1.3.3.4",
    "app-uuid": "defaultUuid",
    "image-quality": picacg.data['imageQuality'] ?? "original",
    "app-platform": "android",
    "app-build-version": "45",
    "Content-Type": "application/json; charset=UTF-8",
    "user-agent": "okhttp/3.8.1",
    "version": "v1.4.1",
    "Host": "picaapi.picacomic.com",
    "signature": signature,
  };
  return BaseOptions(
    receiveDataWhenStatusError: true,
    responseType: ResponseType.plain,
    headers: headers,
  );
}
