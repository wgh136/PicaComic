import 'hitomi_models.dart';
import 'package:dio/dio.dart';

///获取图像url使用的一个临时的类
///
/// 需要发起一个网络请求获取gg.js并对其进行解析
///
/// gg.js内容会动态变化
class GG{
  List<String> numbers = [];
  int mm(int g){
    if(numbers.contains(g.toString())){
      return 0;
    }else{
      return 1;
    }
  }

  static String s(String h) {
    RegExp exp = RegExp(r'(..)(.)$');
    Match? m = exp.firstMatch(h);
    if (m != null) {
      int g = int.parse(m.group(2)! + m.group(1)!, radix: 16);
      return g.toString();
    } else {
      return "";
    }
  }

  String? b;

  ///通过缓存减少请求时间, 短时间内gg.js不会变化
  static DateTime? cacheTime;
  static String? cacheB;
  static List<String>? cacheNumbers;

  Future<void> getGg(String galleryId) async{
    if(cacheTime!=null && DateTime.now().millisecondsSinceEpoch - cacheTime!.millisecondsSinceEpoch < 60000){
      numbers = cacheNumbers!;
      b = cacheB!;
    }
    var dio = Dio(BaseOptions(
        responseType: ResponseType.plain,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
          "Referer": "https://hitomi.la/reader/$galleryId.html"
        }
    ));
    var res = await dio.get<String>("https://ltn.hitomi.la/gg.js?_=1683939645979");
    RegExp exp = RegExp(r'(?<=case )\d+');
    Iterable<RegExpMatch> matches = exp.allMatches(res.data!);
    numbers = [];
    for (RegExpMatch match in matches) {
      numbers.add(match.group(0)!);
    }
    exp = RegExp(r"(?<=b: ')\d+");
    b = exp.firstMatch(res.data!)![0];
    cacheTime = DateTime.now();
    cacheB = b;
    cacheNumbers = numbers;
  }

  String subdomainFromUrl(String url, String? base){
    var retval = 'b';
    if (base != null) {
      retval = base;
    }

    var b = 16;
    var m = RegExp(r"/[0-9a-f]{61}([0-9a-f]{2})([0-9a-f])").firstMatch(url);
    if(m == null){
      return 'a';
    }
    int g = int.parse(m[2]! + m[1]!, radix: b);
    if (!g.isNaN) {
      retval = String.fromCharCode(97 + mm(g)) + retval;
    }
    return retval;
  }

  String fullPathFromHash(String hash) {
    return '$b/${GG.s(hash)}/$hash';
  }

  String urlFromUrl(String url, String? base) {
    return url.replaceFirst(RegExp(r"//..?\.hitomi\.la/"), '//${subdomainFromUrl(url, base)}.hitomi.la/');
  }

  String urlFromHash(HitomiFile image, String? dir, String? ext) {
    ext ??= dir ??= image.name.split('.').last;
    dir ??= 'images';
    return 'https://a.hitomi.la/$dir/${fullPathFromHash(image.hash)}.$ext';
  }

  ///获取图像信息
  Future<String> urlFromUrlFromHash(String galleryId, HitomiFile image, String? dir, String? ext) async{
    await getGg(galleryId);
    print(urlFromHash(image, dir, ext));
    return urlFromUrl(urlFromHash(image, dir, ext), 'a');
  }
}