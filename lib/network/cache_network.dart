import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/network/http_client.dart';
import 'app_dio.dart';

///缓存网络请求, 仅提供get方法, 其它的没有意义
class CachedNetwork {
  Future<CachedNetworkRes<String>> get(String url, BaseOptions options,
      {CacheExpiredTime expiredTime = CacheExpiredTime.short,
      CookieJarSql? cookieJar, bool log = true, bool http2 = false}) async {
    await setNetworkProxy();
    var fileName = md5
        .convert(const Utf8Encoder()
            .convert(url.replaceFirst("inline_set=ts_l&", "")))
        .toString();
    if (fileName.length > 20) {
      fileName = fileName.substring(0, 21);
    }
    final key = url;
    var cache = await CacheManager().findCache(key);
    if (cache != null) {
      var file = File(cache);
      return CachedNetworkRes(await file.readAsString(), 200, url);
    }
    options.responseType = ResponseType.bytes;
    var dio = log?logDio(options, http2):Dio(options);
    if (cookieJar != null) {
      dio.interceptors.add(CookieManagerSql(cookieJar));
    }

    var res = await dio.get<Uint8List>(url);
    if (res.data == null && !url.contains("random")) {
      throw Exception("Empty data");
    }
    if (expiredTime != CacheExpiredTime.no) {
      await CacheManager().writeCache(key, res.data!, expiredTime.time);
    }
    return CachedNetworkRes(utf8.decoder.convert(res.data!), res.statusCode,
        res.realUri.toString(), res.headers.map);
  }

  void delete(String url) async{
    await CacheManager().delete(url);
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
  String url;

  CachedNetworkRes(this.data, this.statusCode, this.url, [this.headers = const {}]);
}
