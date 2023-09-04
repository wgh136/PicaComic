import 'dart:convert';
import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/proxy.dart';
import 'log_dio.dart';

///缓存网络请求, 仅提供get方法, 其它的没有意义
class CachedNetwork {
  String? _path;

  Future<void> init() async {
    _path =
        "${(await getTemporaryDirectory()).path}${Platform.pathSeparator}cachedNetwork";
    if (!Directory(_path!).existsSync()) {
      Directory(_path!).createSync(recursive: true);
    }
  }

  static Future<void> clearCache() async {
    var path =
        "${(await getTemporaryDirectory()).path}${Platform.pathSeparator}cachedNetwork";
    if (Directory(path).existsSync()) {
      Directory(path).deleteSync(recursive: true);
      Directory(path).createSync();
    }
  }

  Future<CachedNetworkRes<String>> get(String url, BaseOptions options,
      {CacheExpiredTime expiredTime = CacheExpiredTime.short,
      CookieJar? cookieJar, bool log = true}) async {
    await setNetworkProxy();
    await init();
    var fileName = md5
        .convert(const Utf8Encoder()
            .convert(url.replaceFirst("inline_set=ts_l&", "")))
        .toString();
    if (fileName.length > 20) {
      fileName = fileName.substring(0, 21);
    }
    var file = File(_path! + Platform.pathSeparator + fileName);
    if (file.existsSync()) {
      var time = file.lastModifiedSync();
      if (expiredTime == CacheExpiredTime.persistent ||
          DateTime.now().millisecondsSinceEpoch - time.millisecondsSinceEpoch <
              expiredTime.time) {
        return CachedNetworkRes(file.readAsStringSync(), 200);
      }
    }
    options.responseType = ResponseType.plain;
    var dio = log?logDio(options):Dio(options);
    if (cookieJar != null) {
      dio.interceptors.add(CookieManager(cookieJar));
    }

    var res = await dio.get(url);
    if (res.data == null && !url.contains("random")) {
      throw Exception("无数据");
    }
    if (expiredTime != CacheExpiredTime.no) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      file.writeAsStringSync(res.data);
    }
    return CachedNetworkRes(res.data ?? "", res.statusCode, res.headers.map);
  }

  Future<CachedNetworkRes<String>> getJm(
      String url, BaseOptions options, int time,
      {CacheExpiredTime expiredTime = CacheExpiredTime.short,
      CookieJar? cookieJar}) async {
    await setNetworkProxy();
    await init();
    var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
    if (fileName.length > 20) {
      fileName = fileName.substring(0, 21);
    }
    var file = File(_path! + Platform.pathSeparator + fileName);
    if (file.existsSync()) {
      var time = file.lastModifiedSync();
      if (expiredTime == CacheExpiredTime.persistent ||
          DateTime.now().millisecondsSinceEpoch - time.millisecondsSinceEpoch <
              expiredTime.time) {
        return CachedNetworkRes(file.readAsStringSync(), 200);
      }
    }
    options.responseType = ResponseType.plain;
    var dio = logDio(options);
    if (cookieJar != null) {
      dio.interceptors.add(CookieManager(cookieJar));
    }
    var res = await dio.get(url);
    if (res.statusCode != 200) {
      return CachedNetworkRes(res.data.toString(), res.statusCode);
    }
    var json = const JsonDecoder().convert(res.data);
    var data = json["data"];
    if (data is List && data.isEmpty) {
      throw Exception("无数据");
    } else if (data is List) {
      throw Exception("解析出错");
    }
    var decodedData = JmNetwork.convertData(data, time);
    if (expiredTime != CacheExpiredTime.no) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      file.writeAsStringSync(decodedData);
    }
    return CachedNetworkRes(decodedData, res.statusCode);
  }
}

enum CacheExpiredTime {
  no(-1),
  short(86400000),
  long(604800000),
  persistent(0);

  ///过期时间, 单位为微秒
  final int time;

  const CacheExpiredTime(this.time);
}

class CachedNetworkRes<T> {
  T data;
  int? statusCode;
  Map<String, List<String>> headers;

  CachedNetworkRes(this.data, this.statusCode, [this.headers = const {}]);
}
