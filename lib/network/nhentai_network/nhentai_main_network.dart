import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/res.dart';

class NhentaiNetwork{
  factory NhentaiNetwork() => _cache ?? (_cache = NhentaiNetwork._create());
  NhentaiNetwork._create();

  var ua = "Pica Comic";

  static NhentaiNetwork? _cache;

  PersistCookieJar? cookieJar;

  Future<void> _init() async{
    var path = (await getApplicationSupportDirectory()).path;
    path = "$path$pathSep${"cookies"}";
    cookieJar = PersistCookieJar(storage: FileStorage(path));
  }

  Future<Res> get() async{
    if(cookieJar == null){
      await _init();
    }
    var dio = CachedNetwork();
    try {
      var res = await dio.get("https://nhentai.net", BaseOptions(
          headers: {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Accept-Language": "zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6",
            "User-Agent": ua
          },
          validateStatus: (i) => i == 200 || i == 403
      ), expiredTime: CacheExpiredTime.no, cookieJar: cookieJar);
      if(res.statusCode == 403){
        return const Res(null, errorMessage: "403");  // need to bypass cloudflare
      }
      return Res(res.data);
    }
    catch(e){
      return Res(null, errorMessage: e.toString());
    }
  }
}