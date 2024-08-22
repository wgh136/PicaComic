import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'jm_network.dart';

var _device = '';

String get _jmUA {
  // 生成随机的设备标识符
  if(_device.isEmpty) {
    var chars = "abcdefghijklmnopqrstuvwxyz0123456789";
    var random = math.Random();
    for (var i = 0; i < 9; i++) {
      _device += chars[random.nextInt(chars.length)];
    }
  }
  return "Mozilla/5.0 (Linux; Android 13; $_device Build/TQ1A.230305.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36";
}

const _jmVersion = "1.7.2";

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