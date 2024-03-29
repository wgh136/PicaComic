import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'jm_network.dart';

String get _jmUA {
  // 生成随机的设备标识符
  var device = List.generate(9, (index) => "0123456789abcdef".split("")[index]).join();
  return "Mozilla/5.0 (Linux; Android 13; $device Build/TQ1A.230305.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36";
}

const _jmVersion = "1.6.8";

const _jmAuthKey = "18comicAPPContent";

BaseOptions getHeader(int time,
    {bool post = false, Map<String, String>? headers, bool byte = true}) {
  var token = md5.convert(const Utf8Encoder().convert("$time$_jmAuthKey"));

  return BaseOptions(
      receiveDataWhenStatusError: true,
      connectTimeout: const Duration(seconds: 8),
      responseType: byte ? ResponseType.bytes : null,
      headers: {
        "token": token.toString(),
        "tokenparam": "$time,$_jmVersion",
        "user-agent": _jmUA,
        "accept-encoding": "gzip",
        "Host": JmNetwork().baseUrl.replaceFirst("https://", ""),
        ...headers ?? {},
        if (post) "Content-Type": "application/x-www-form-urlencoded"
      });
}