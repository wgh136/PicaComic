import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:html/parser.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/built_in/jm.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/pages/pre_search_page.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/ecb.dart';

import '../../foundation/cache_manager.dart';
import '../../foundation/log.dart';
import '../app_dio.dart';
import '../http_client.dart';
import '../res.dart';
import 'headers.dart';
import 'jm_image.dart';
import 'jm_models.dart';

extension _CachedNetwork on CachedNetwork {
  Future<CachedNetworkRes<String>> getJm(
      String url, BaseOptions options, int time,
      {CacheExpiredTime expiredTime = CacheExpiredTime.short,
      CookieJar? cookieJar}) async {
    await setNetworkProxy();
    final key = url;
    var cache = await CacheManager().findCache(key);
    if (cache != null) {
      var file = File(cache);
      return CachedNetworkRes(await file.readAsString(), 200, url);
    }
    options.responseType = ResponseType.bytes;
    var dio = logDio(options);
    if (cookieJar != null) {
      dio.interceptors.add(CookieManager(cookieJar));
    }
    var res = await dio.get<Uint8List>(url);
    if (res.data == null) {
      throw Exception("Empty data");
    }
    var body = utf8.decoder.convert(res.data!);
    if (res.statusCode != 200) {
      return CachedNetworkRes(body, res.statusCode, res.realUri.toString());
    }
    var json = const JsonDecoder().convert(body);
    var data = json["data"];
    if (data is List && data.isEmpty) {
      throw Exception("Empty data");
    } else if (data is List) {
      throw Exception("Data parsing error");
    }
    var decodedData = JmNetwork.convertData(data, time);
    if (expiredTime != CacheExpiredTime.no) {
      await CacheManager().writeCache(key, res.data!, expiredTime.time);
    }
    return CachedNetworkRes(
        decodedData, res.statusCode, res.realUri.toString());
  }
}

class JmNetwork {
  static const baseData = "";

  // 禁漫的cookie无需持久化储存, 因为有效期非常短
  final cookieJar = CookieJar(ignoreExpires: true);

  var hotTags = <String>[];

  factory JmNetwork() => cache == null ? (cache = JmNetwork.create()) : cache!;

  JmNetwork.create();

  static JmNetwork? cache;

  static const urls = <String>[
    "https://www.jmeadpoolcdn.one",
    "https://www.jmeadpoolcdn.life",
    "https://www.jmapiproxyxxx.one",
    "https://www.jmfreedomproxy.xyz"
  ];

  String get baseUrl => urls[int.parse(appdata.settings[17])];

  static const kJmSecret = '185Hcomic3PAPP7R';

  bool _performingLogin = false;

  ///解密数据
  static String convertData(String input, int time) {
    //key为时间+18comicAPPContent的md5结果
    var key = md5.convert(const Utf8Encoder().convert("$time$kJmSecret"));
    BlockCipher cipher = ECBBlockCipher(AESEngine())
      ..init(false, KeyParameter(const Utf8Encoder().convert(key.toString())));
    //先将数据进行base64解码
    final data = base64Decode(input);
    //再进行AES-ECB解密
    var offset = 0;
    var paddedPlainText = Uint8List(data.length);
    while (offset < data.length) {
      offset += cipher.processBlock(data, offset, paddedPlainText, offset);
    }
    //将得到的数据进行Utf8解码
    var res = const Utf8Decoder().convert(paddedPlainText);
    //得到的数据在末尾有一些乱码
    int i = res.length - 1;
    for (; i >= 0; i--) {
      if (res[i] == '}' || res[i] == ']') {
        break;
      }
    }
    return res.substring(0, i + 1);
  }

  Future<void> init() async {
    loginFromAppdata();
  }

  ///get请求, 返回Json数据中的data
  Future<Res<dynamic>> get(String url,
      {Map<String, String>? header,
      CacheExpiredTime expiredTime = CacheExpiredTime.long,
      bool isRetry = false}) async {
    while (_performingLogin) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var dio = CachedNetwork();
    var options = getHeader(time);
    options.validateStatus = (i) => i == 200 || i == 401;
    try {
      var res = await dio.getJm(url, options, time,
          cookieJar: cookieJar, expiredTime: CacheExpiredTime.no);
      if (res.statusCode == 401) {
        var message =
            const JsonDecoder().convert(res.data)["errorMsg"] ?? "Error";
        if (message == "請先登入會員" && jm.isLogin && !isRetry) {
          var res = await jm.reLogin();
          if (res) {
            return get(
              url,
              header: header,
              expiredTime: expiredTime,
              isRetry: true,
            );
          }
        }
        return Res(null, errorMessage: message);
      }

      final data = const JsonDecoder().convert(res.data);

      return Res<dynamic>(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e.type != DioExceptionType.unknown) {
        return Res<String>(null, errorMessage: e.message ?? "Network Error");
      } else {
        return Res<String>(null, errorMessage: e.toString().split("\n")[1]);
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res<String>(null, errorMessage: e.toString());
    }
  }

  /// post请求
  Future<Res<dynamic>> post(String url, String data) async {
    try {
      await setNetworkProxy();
      int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var dio = logDio(getHeader(time, post: true));
      dio.interceptors.add(CookieManager(cookieJar));
      var res = await dio.post(url,
          options: Options(validateStatus: (i) => i == 200 || i == 401),
          data: data);
      if (res.statusCode == 401) {
        return Res(null,
            errorMessage: const JsonDecoder().convert(
                    const Utf8Decoder().convert(res.data))["errorMsg"] ??
                "Unknown Error".toString());
      }
      var resData = convertData(
          (const JsonDecoder()
              .convert(const Utf8Decoder().convert(res.data)))["data"],
          time);
      return Res<dynamic>(const JsonDecoder().convert(resData));
    } on DioException catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e.type != DioExceptionType.unknown) {
        return const Res.error("Network Error");
      } else {
        return Res.error(e.toString());
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return const Res.error("Network Error");
    }
  }

  ///获取主页
  Future<Res<HomePageData>> getHomePage() async {
    var res = await get("$baseUrl/promote?$baseData&page=0",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var data = HomePageData([]);
      for (var item in res.data) {
        var comics = <JmComicBrief>[];
        for (var comic in item["content"]) {
          try {
            var categories = <ComicCategoryInfo>[];
            if (comic["category"]["id"] != null &&
                comic["category"]["title"] != null) {
              categories.add(ComicCategoryInfo(
                  comic["category"]["id"], comic["category"]["title"]));
            }
            if (comic["category_sub"]["id"] != null &&
                comic["category_sub"]["title"] != null) {
              categories.add(ComicCategoryInfo(
                  comic["category_sub"]["id"], comic["category_sub"]["title"]));
            }
            comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"],
                comic["description"] ?? "", categories));
          } catch (e) {
            continue;
          }
        }
        String type = item["type"];
        String id = item["id"].toString();
        if (type == "category_id") {
          id = item["slug"];
        }
        data.items
            .add(HomePageItem(item["title"], id, comics, type != "promote"));
      }
      return Res(data);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<PromoteList>> getPromoteList(String id) async {
    var res = await get("$baseUrl/promote_list?$baseData&id=$id&page=0",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var list = PromoteList(id, []);
      list.total = int.parse(res.data["total"]);
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null &&
            comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null &&
            comic["category_sub"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        try {
          list.comics.add(JmComicBrief(comic["id"], comic["author"],
              comic["name"], comic["description"] ?? "", categories));
        } catch (e) {
          //忽略
        }
        list.loaded++;
      }
      list.page++;
      return Res(list);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<void> loadMorePromoteListComics(PromoteList list) async {
    if (list.loaded >= list.total) {
      return;
    }
    var res = await get(
        "$baseUrl/promote_list?$baseData&id=${list.id}&page=${list.page}",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return;
    }
    try {
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null &&
            comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null &&
            comic["category_sub"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        try {
          list.comics.add(JmComicBrief(comic["id"], comic["author"],
              comic["name"], comic["description"] ?? "", categories));
        } catch (e) {
          //忽视
        }
        list.loaded++;
      }
      list.page++;
      return;
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return;
    }
  }

  Future<Res<List<JmComicBrief>>> getLatest(int page) async {
    var res = await get("$baseUrl/latest?$baseData&page=$page",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data)) {
        try {
          var categories = <ComicCategoryInfo>[];
          if (comic["category"]["id"] != null &&
              comic["category"]["title"] != null) {
            categories.add(ComicCategoryInfo(
                comic["category"]["id"], comic["category"]["title"]));
          }
          if (comic["category_sub"]["id"] != null &&
              comic["category_sub"]["title"] != null) {
            categories.add(ComicCategoryInfo(
                comic["category_sub"]["id"], comic["category_sub"]["title"]));
          }
          comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"],
              comic["description"] ?? "", categories));
        } catch (e) {
          continue;
        }
      }
      return Res(comics, subData: 99999);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取热搜词
  Future<Res<bool>> getHotTags() async {
    var res = await get("$baseUrl/hot_tags?$baseData",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    hotTags.clear();
    for (var s in res.data) {
      hotTags.add(s);
    }
    return const Res(true);
  }

  Future<Res<List<JmComicBrief>>> searchNew(
      String keyword, int page, ComicsOrder order) async {
    appdata.searchHistory.remove(keyword);
    appdata.searchHistory.add(keyword);
    keyword = keyword.trim();
    keyword = keyword.replaceAll('  ', ' ');
    keyword = Uri.encodeComponent(keyword);
    keyword = keyword.replaceAll('%20', '+');
    appdata.writeHistory();
    Res res;
    if (page != 1) {
      res = await get(
          "$baseUrl/search?&search_query=$keyword&o=$order&page=$page",
          expiredTime: CacheExpiredTime.no);
    } else {
      res = await get("$baseUrl/search?&search_query=$keyword&o=$order",
          expiredTime: CacheExpiredTime.no);
    }
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["content"])) {
        try {
          var categories = <ComicCategoryInfo>[];
          if (comic["category"]["id"] != null &&
              comic["category"]["title"] != null) {
            categories.add(ComicCategoryInfo(
                comic["category"]["id"], comic["category"]["title"]));
          }
          if (comic["category_sub"]["id"] != null &&
              comic["category_sub"]["title"] != null) {
            categories.add(ComicCategoryInfo(
                comic["category_sub"]["id"], comic["category_sub"]["title"]));
          }
          comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"],
              comic["description"] ?? "", categories));
        } catch (e) {
          continue;
        }
      }
      Future.delayed(const Duration(microseconds: 500), () {
        try {
          StateController.find<PreSearchController>().update();
        } catch (e) {
          //跳过
        }
      });
      return Res(comics,
          subData: comics.isEmpty
              ? 0
              : (int.parse(res.data["total"]) / res.data["content"].length)
                  .ceil());
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      Future.delayed(const Duration(microseconds: 500),
          () => StateController.find<PreSearchController>().update());
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取分类信息
  Future<Res<List<Category>>> getCategories() async {
    var res = await get("$baseUrl/categories?$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var categories = <Category>[];
      for (var c in res.data["categories"]) {
        var subCategories = <SubCategory>[];
        for (var sc in c["sub_categories"] ?? []) {
          subCategories.add(SubCategory(sc["CID"], sc["name"], sc["slug"]));
        }
        categories.add(Category(c["name"], c["slug"], subCategories));
      }
      return Res(categories);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<JmComicBrief>>> getCategoryComics(
      String category, ComicsOrder order, int page) async {
    var res = await get(
        "$baseUrl/categories/filter?$baseData&o=$order&c=${Uri.encodeComponent(category)}&page=$page",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["content"])) {
        try {
          var categories = <ComicCategoryInfo>[];
          if (comic["category"]["id"] != null &&
              comic["category"]["title"] != null) {
            categories.add(ComicCategoryInfo(
                comic["category"]["id"], comic["category"]["title"]));
          }
          if (comic["category_sub"]["id"] != null &&
              comic["category_sub"]["title"] != null) {
            categories.add(ComicCategoryInfo(
                comic["category_sub"]["id"], comic["category_sub"]["title"]));
          }
          comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"],
              comic["description"] ?? "", categories));
        } catch (e) {
          continue;
        }
      }
      Object total = res.data["total"];
      if (total is String) {
        total = int.parse(total);
      }
      var current = res.data["content"].length;
      var pagesCount = 1;
      if (current != 0) {
        pagesCount = ((total as int) / current).ceil();
      }
      return Res(comics, subData: pagesCount);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<JmComicInfo>> getComicInfo(String id) async {
    var res = await get("$baseUrl/album?comicName=&id=$id",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      if (res.errorMessage!.contains("Empty data")) {
        throw Exception("漫畫不存在: id = $id");
      }
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var author = <String>[];
      for (var s in res.data["author"] ?? "未知") {
        author.add(s);
      }
      var series = <int, String>{};
      var epNames = <String>[];
      int sort = 1;
      for (var s in res.data["series"] ?? []) {
        series[sort] = s["id"];
        sort++;
        var name = s["name"] as String;
        if (name.isEmpty) {
          name = "第${s["sort"]}話";
        }
        epNames.add(name);
      }
      var tags = <String>[];
      for (var s in res.data["tags"] ?? []) {
        tags.add(s);
      }
      var related = <JmComicBrief>[];
      for (var c in res.data["related_list"] ?? []) {
        related.add(JmComicBrief(c["id"], c["author"] ?? "Unknown",
            c["name"] ?? "Unknown", c["description"] ?? "None", []));
      }
      return Res(JmComicInfo(
          res.data["name"] ?? "未知",
          id,
          author,
          res.data["description"] ?? "无",
          int.parse(res.data["likes"] ?? "0"),
          int.parse(res.data["total_views"] ?? "0"),
          series,
          tags,
          related,
          res.data["liked"] ?? false,
          res.data["is_favorite"] ?? false,
          int.parse(res.data["comment_total"] ?? "0"),
          epNames));
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> login(String account, String pwd) async {
    _performingLogin = true;
    try {
      var res = await post("$baseUrl/login",
          "username=${Uri.encodeComponent(account)}&password=${Uri.encodeComponent(pwd)}");
      if (res.error) {
        return Res(null, errorMessage: res.errorMessage);
      }
      jm.data['name'] = account;
      appdata.writeData();
      return const Res(true);
    } finally {
      _performingLogin = false;
    }
  }

  /// 使用储存的数据进行登录
  Future<Res<bool>> loginFromAppdata() async {
    var res = await jm.reLogin();
    return res ? const Res(true) : const Res.error("error");
  }

  Future<void> logout() async {
    await cookieJar.deleteAll();
  }

  Future<void> likeComic(String id) async {
    await post("$baseUrl/like", "id=$id&$baseData");
  }

  ///创建收藏夹
  Future<Res<bool>> createFolder(String name) async {
    var res = await post(
        "$baseUrl/favorite_folder", "type=add&folder_name=$name&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    } else {
      return const Res(true);
    }
  }

  Future<Res<List<JmComicBrief>>> getFolderComicsPage(
      String id, int page) async {
    ComicsOrder order =
        appdata.settings[42] == "0" ? ComicsOrder.latest : ComicsOrder.update;
    var res = await get(
        "$baseUrl/favorite?$baseData&page=$page&folder_id=$id&o=$order",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null &&
            comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null &&
            comic["category_sub"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"],
            comic["description"] ?? "", categories));
      }
      int pages;
      if (comics.isNotEmpty) {
        pages = (int.parse(res.data["total"]) / comics.length).ceil();
      } else {
        pages = 0;
      }
      return Res(comics, subData: pages);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
      }
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取收藏夹
  Future<Res<Map<String, String>>> getFolders() async {
    var res = await get("$baseUrl/favorite?$baseData",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var folders = <String, String>{};
      for (var folder in res.data["folder_list"]) {
        folders[folder["FID"]] = folder["name"];
      }
      return Res(folders);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///移动漫画至指定的收藏夹
  Future<Res<bool>> moveToFolder(String comicId, String folderId) async {
    var res = await post("$baseUrl/favorite_folder",
        "type=move&folder_id=$folderId&aid=$comicId&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    } else {
      return const Res(true);
    }
  }

  ///收藏漫画, 如果folder为null, 则为取消收藏
  Future<Res<bool>> favorite(String id, String? folder) async {
    try {
      if (folder != null) {
        var res = await post("$baseUrl/favorite", "aid=$id&$baseData");
        if (res.data["type"] != "add") {
          res = await post("$baseUrl/favorite", "aid=$id&$baseData");
        }
        Res res2 = const Res(true);
        if (folder != "0") {
          res2 = await moveToFolder(id, folder);
        }
        if (res.error || res2.error) {
          return Res(null, errorMessage: res.errorMessage);
        } else {
          return const Res(true);
        }
      } else {
        var res = await post("$baseUrl/favorite", "aid=$id&$baseData");
        if (res.data["type"] == "add") {
          res = await post("$baseUrl/favorite", "aid=$id&$baseData");
        }
        return const Res(false);
      }
    } catch (e) {
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取漫画图片
  Future<Res<List<String>>> getChapter(String id) async {
    var res = await get("$baseUrl/chapter?&id=$id");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var images = <String>[];
      for (var s in res.data["images"]) {
        images.add(getJmImageUrl(s, id));
      }
      return Res(images);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取scramble
  ///
  /// 此函数未使用, 因为似乎所有漫画的scramble都一样
  Future<String?> getScramble(String id) async {
    var dio = Dio(
        getHeader(DateTime.now().millisecondsSinceEpoch ~/ 1000, byte: false))
      ..interceptors.add(LogInterceptor());
    dio.interceptors.add(CookieManager(cookieJar));
    var res = await dio.get(
        "$baseUrl/chapter_view_template?id=$id&mode=vertical&page=0&app_ima_shunt=NaN&express=off");
    var exp = RegExp(r"(?<=var scramble_id = )\w+");
    return exp.firstMatch(res.data)!.group(0);
  }

  /// 获取评论, 获取章节评论需要mode = all
  Future<Res<List<Comment>>> getComment(String id, int page,
      [String mode = "manhua"]) async {
    var res = await get("$baseUrl/forum?mode=$mode&aid=$id&page=$page",
        expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      String parseContent(String input) {
        var fragment = parseFragment(input);
        return fragment.querySelector("div")?.text ?? "";
      }

      var comments = <Comment>[];
      for (var c in res.data["list"]) {
        var reply = <Comment>[];
        for (var r in c["replys"] ?? []) {
          reply.add(Comment(r["CID"], getJmAvatarUrl(r["photo"]), r["username"],
              r["addtime"], parseContent(r["content"]), []));
        }
        comments.add(Comment(c["CID"], getJmAvatarUrl(c["photo"]),
            c["username"], c["addtime"], parseContent(c["content"]), reply));
      }
      return Res(
        comments,
        subData: res.data["total"] is int
            ? res.data["total"]
            : (int.tryParse(res.data["total"]) ?? 1),
      );
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> deleteFolder(String id) async {
    var res = await post(
        "$baseUrl/favorite_folder", "type=del&folder_id=$id&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    } else {
      if (res.data["code"] == 400) {
        return Res(null, errorMessage: res.data["msg"]);
      }
      return const Res(true);
    }
  }

  ///获取每周必看列表
  ///
  /// 返回Map, 键为ID, 值为名称
  Future<Res<Map<String, String>>> getWeekRecommendation() async {
    var res =
        await get("$baseUrl/week?$baseData", expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage!);
    }
    try {
      Map<String, String> categories = {};
      for (var c in res.data["categories"]) {
        categories[c["id"]] = c["time"];
      }
      return Res(categories);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取单个每周必看中的漫画
  ///
  /// 不需要传递page变量, 因为只有一页
  Future<Res<List<JmComicBrief>>> getWeekRecommendationComics(
      String id, WeekRecommendationType type) async {
    var res = await get("$baseUrl/week/filter?$baseData&id=$id&page=0$type");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage!);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null &&
            comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null &&
            comic["category_sub"]["title"] != null) {
          categories.add(ComicCategoryInfo(
              comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"],
            comic["description"] ?? "", categories));
      }
      return Res(comics);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<dynamic>> comment(String aid, String content) async {
    var res = await post("$baseUrl/comment",
        "comment=${Uri.encodeComponent(content)}&status=undefined&aid=$aid&$baseData");
    if (res.error) {
      return res;
    } else {
      return Res(res.data["msg"]);
    }
  }
}

///禁漫漫画排序模式
enum ComicsOrder {
  ///最新
  latest("mr"),

  ///总排行, 或者最多点击
  totalRanking("mv"),

  ///月排行, 仅分类中
  monthRanking("mv_m"),

  ///周排行, 仅分类中
  weekRanking("mv_w"),

  ///日排行, 仅分类中
  dayRanking("mv_t"),

  ///最多图片
  maxPictures("mp"),

  ///最多喜欢
  maxLikes("tf"),

  /// 最新更新(收藏夹)
  update("mp");

  @override
  String toString() => value;

  final String value;

  const ComicsOrder(this.value);

  static ComicsOrder fromValue(String value) {
    for (var v in ComicsOrder.values) {
      if (v.value == value) return v;
    }
    throw UnimplementedError();
  }
}

///每周必看的类型
enum WeekRecommendationType {
  korean("&type=hanman"),
  manga("&type=manga"),
  another("&type=another");

  const WeekRecommendationType(this.value);

  final String value;

  @override
  String toString() => value;
}

var jmNetwork = JmNetwork();
