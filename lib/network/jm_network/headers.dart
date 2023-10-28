import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';

const jmAuth = <String>[
  "1",
  "1.6.1",
  "18comicAPPContent",
  "Mozilla/5.0 (Linux; Android 13; 8d41w854d Build/TQ1A.230205.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36"
];

BaseOptions getHeader(int time,
    {bool post = false, Map<String, String>? headers, bool byte = true}) {
  var token = md5.convert(const Utf8Encoder().convert("$time${jmAuth[2]}"));

  return BaseOptions(
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 8),
      responseType: byte ? ResponseType.bytes : null,
      headers: {
        "token": token.toString(),
        "tokenparam": "$time,${jmAuth[1]}",
        "user-agent": jmAuth[3],
        "accept-encoding": "gzip",
        "Host": JmNetwork().baseUrl.replaceFirst("https://", ""),
        ...headers ?? {},
        if (post) "Content-Type": "application/x-www-form-urlencoded"
      });
}
