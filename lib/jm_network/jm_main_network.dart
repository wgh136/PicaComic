import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pica_comic/jm_network/headers.dart';
import 'package:pica_comic/jm_network/jm_image.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/jm_network/res.dart';
import 'package:pica_comic/tools/debug.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pointycastle/export.dart';
import 'package:get/get.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

import '../base.dart';

class JmNetwork {
  /*
  关于一些注意事项:
    1. jm的漫画列表加载, 当page大于存在的数量时返回最后一页, 而不是报错
   */

  ///禁漫api地址
  ///
  /// "https://www.jmapinode1.cc", "https://www.jmapinode.cc",
  /// "https://www.jmapibranch1.cc", "https://www.jmapibranch2.cc"
  var baseUrl = "https://www.jmapinode1.cc";

  final baseData = "key=0b931a6f4b5ccc3f8d870839d07ae7b2&view_mode_debug=1&view_mode=null";

  final cookieJar = CookieJar(ignoreExpires: true);

  var hotTags = <String>[];

  void updateApi(){
    var urls = <String>[
      "https://www.jmapinode1.cc",
      "https://www.jmapinode.cc",
      "https://www.jmapibranch1.cc",
      "https://www.jmapibranch2.cc"
    ];
    baseUrl = urls[int.parse(appdata.settings[17])];
  }

  ///解密数据
  String _convertData(String input, int time) {
    //key为时间+18comicAPPContent的md5结果
    var key = md5.convert(const Utf8Encoder().convert("${time}18comicAPPContent"));
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
    //得到的数据再末尾有一些乱码
    int i = res.length - 1;
    for (; i >= 0; i--) {
      if (res[i] == '}' || res[i] == ']') {
        break;
      }
    }
    return res.substring(0, i + 1);
  }

  ///get请求, 返回Json数据中的data
  Future<Res<dynamic>> get(String url, {Map<String, String>? header}) async {
    int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var dio = Dio(getHeader(time))..interceptors.add(LogInterceptor());
    dio.interceptors.add(CookieManager(cookieJar));
    try{
      var res = await dio.get(url, options: Options(validateStatus: (i) => i == 200 || i == 401));
      if (res.statusCode == 401) {
        return Res(null,
            errorMessage:
                const JsonDecoder().convert(const Utf8Decoder().convert(res.data))["errorMsg"] ??
                    "未知错误".toString());
      }
      var givenData = const JsonDecoder().convert(const Utf8Decoder().convert(res.data))["data"];
      if (givenData is List && givenData.isEmpty) {
        return Res(null, errorMessage: "无数据");
      } else if (givenData is List) {
        return Res(null, errorMessage: "解析出错");
      }
      var data = _convertData(givenData, time);
      if (kDebugMode && GetPlatform.isWindows) {
        saveDebugData(data);
      }
      return Res<dynamic>(const JsonDecoder().convert(data));
    } on DioError catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e.type != DioErrorType.unknown) {
        return Res<String>(null, errorMessage: e.message ?? "网络错误");
      }
      return Res<String>(null, errorMessage: "网络错误");
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return Res<String>(null, errorMessage: "网络错误");
    }

  }

  ///post请求, 与get请求的一个显著区别是请求头中的Content-Type
  Future<Res<dynamic>> post(String url, String data) async {
    try {
      int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      var dio = Dio(getHeader(time, post: true))..interceptors.add(LogInterceptor());
      dio.interceptors.add(CookieManager(cookieJar));
      var res = await dio.post(url,
          options: Options(validateStatus: (i) => i == 200 || i == 401), data: data);
      if (res.statusCode == 401) {
        return Res(null,
            errorMessage:
                const JsonDecoder().convert(const Utf8Decoder().convert(res.data))["errorMsg"] ??
                    "未知错误".toString());
      }
      var resData = _convertData(
          (const JsonDecoder().convert(const Utf8Decoder().convert(res.data)))["data"], time);
      if (kDebugMode) {
        saveDebugData(resData);
      }
      return Res<dynamic>(const JsonDecoder().convert(resData));
    } on DioError catch (e) {
      if (kDebugMode) {
        print(e);
      }
      if (e.type != DioErrorType.unknown) {
        return Res<String>(null, errorMessage: e.message ?? "网络错误");
      }
      return Res<String>(null, errorMessage: "网络错误");
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return Res<String>(null, errorMessage: "网络错误");
    }
  }

  ///获取主页
  Future<Res<HomePageData>> getHomePage() async {
    var res = await get("$baseUrl/promote?$baseData&page=0");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }

    var data = HomePageData([]);
    for (var item in res.data) {
      var comics = <JmComicBrief>[];
      for (var comic in item["content"]) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        //检查屏蔽词
        bool status = true;
        for (var s in appdata.blockingKeyword) {
          if (comic["author"] == appdata.blockingKeyword || (comic["name"] as String).contains(s)) {
            status = false;
          }
          for (var c in categories) {
            if (c.name == s) {
              status = false;
            }
          }
          if (!status) {
            break;
          }
        }
        if (status) {
          comics.add(JmComicBrief(
              comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        }
      }
      String type = item["type"];
      String id = item["id"].toString();
      if(type == "category_id"){
        id = item["slug"];
      }
      data.items.add(HomePageItem(item["title"], id, comics, type!="promote"));
    }
    return Res(data);
  }

  Future<Res<PromoteList>> getPromoteList(String id) async {
    var res = await get("$baseUrl/promote_list?$baseData&id=$id&page=0");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var list = PromoteList(id, []);
      list.total = int.parse(res.data["total"]);
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        list.comics.add(JmComicBrief(
            comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        list.loaded++;
      }
      list.page++;
      return Res(list);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadMorePromoteListComics(PromoteList list) async {
    if (list.loaded >= list.total) {
      return;
    }
    var res = await get("$baseUrl/promote_list?$baseData&id=${list.id}&page=${list.page}");
    if (res.error) {
      return;
    }
    try {
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        list.comics.add(JmComicBrief(
            comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        list.loaded++;
      }
      list.page++;
      return;
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return;
    }
  }

  Future<Res<List<JmComicBrief>>> getLatest() async {
    var res = await get("$baseUrl/latest?$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data)) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        //检查屏蔽词
        bool status = true;
        for (var s in appdata.blockingKeyword) {
          if (comic["author"] == appdata.blockingKeyword || (comic["name"] as String).contains(s)) {
            status = false;
          }
          for (var c in categories) {
            if (c.name == s) {
              status = false;
            }
          }
          if (!status) {
            break;
          }
        }
        if (status) {
          comics.add(JmComicBrief(
              comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        }
      }
      return Res(comics);
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  ///获取热搜词
  Future<void> getHotTags() async {
    var res = await get("$baseUrl/hot_tags?$baseData");
    if (res.error) {
      return;
    }
    hotTags.clear(); //在尚未完成请求时刷新页面会导致重复调用此方法, 清除以避免出现重复热搜
    for (var s in res.data) {
      hotTags.add(s);
    }
    try {
      Get.find<PreSearchController>().update();
    } catch (e) {
      //处于搜索页面时更新页面, 否则忽视
    }
  }

  ///搜索
  Future<Res<SearchRes>> search(String keyword) async {
    appdata.searchHistory.remove(keyword);
    appdata.searchHistory.add(keyword);
    appdata.writeData();
    var res = await get("$baseUrl/search?$baseData&search_query=${Uri.encodeComponent(keyword)}&o=${ComicsOrder.values[int.parse(appdata.settings[19])]}");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["content"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        //检查屏蔽词
        bool status = true;
        for (var s in appdata.blockingKeyword) {
          if (comic["author"] == appdata.blockingKeyword || (comic["name"] as String).contains(s)) {
            status = false;
          }
          for (var c in categories) {
            if (c.name == s) {
              status = false;
            }
          }
          if (!status) {
            break;
          }
        }
        if (status) {
          comics.add(JmComicBrief(
              comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        }
      }
      Future.delayed(
          const Duration(microseconds: 500), () => Get.find<PreSearchController>().update());
      return Res(
        SearchRes(keyword, comics.length, int.parse(res.data["total"]), comics),
      );
    } catch (e) {
      Future.delayed(
          const Duration(microseconds: 500), () => Get.find<PreSearchController>().update());
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadSearchNextPage(SearchRes search) async {
    if(search.loaded >= search.total){
      return;
    }
    var res = await get(
        "$baseUrl/search?$baseData&search_query=${Uri.encodeComponent(search.keyword)}&page=${search.loadedPage + 1}");
    if (res.error) {
      return;
    }
    try {
      for (var comic in (res.data["content"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        //检查屏蔽词
        bool status = true;
        for (var s in appdata.blockingKeyword) {
          if (comic["author"] == appdata.blockingKeyword || (comic["name"] as String).contains(s)) {
            status = false;
          }
          for (var c in categories) {
            if (c.name == s) {
              status = false;
            }
          }
          if (!status) {
            break;
          }
        }
        if (status) {
          search.comics.add(JmComicBrief(
              comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        }
      }
      search.loaded = search.comics.length;
      search.loadedPage++;
    } catch (e) {
      return;
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
    } catch (e) {
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  ///获取分类漫画
  Future<Res<CategoryComicsRes>> getCategoryComics(String category, ComicsOrder order) async {
    /*
    排序:
      最新，总排行，月排行，周排行，日排行，最多图片, 最多爱心
      mr, mv, mv_m, mv_w, mv_t, mp, tf
     */
    var res = await get("$baseUrl/categories/filter?$baseData&o=$order&c=$category&page=1");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["content"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        //检查屏蔽词
        bool status = true;
        for (var s in appdata.blockingKeyword) {
          if (comic["author"] == appdata.blockingKeyword || (comic["name"] as String).contains(s)) {
            status = false;
          }
          for (var c in categories) {
            if (c.name == s) {
              status = false;
            }
          }
          if (!status) {
            break;
          }
        }
        if (status) {
          comics.add(JmComicBrief(
              comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        }
      }
      return Res(CategoryComicsRes(
          category, order.toString(), comics.length, int.parse(res.data["total"]), 1, comics));
    } catch (e) {
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> getCategoriesComicNextPage(CategoryComicsRes comics) async {
    var res = await get(
        "$baseUrl/categories/filter?$baseData&o=${comics.sort}&c=${comics.category}&page=${comics.loadedPage+1}");
    if (res.error) {
      return;
    }
    try {
      for (var comic in (res.data["content"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        //检查屏蔽词
        bool status = true;
        for (var s in appdata.blockingKeyword) {
          if (comic["author"] == appdata.blockingKeyword || (comic["name"] as String).contains(s)) {
            status = false;
          }
          for (var c in categories) {
            if (c.name == s) {
              status = false;
            }
          }
          if (!status) {
            break;
          }
        }
        if (status) {
          comics.comics.add(JmComicBrief(
              comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
        }
      }
      comics.loadedPage++;
      comics.loaded = comics.comics.length;
    } catch (e) {
      return;
    }
  }

  Future<Res<JmComicInfo>> getComicInfo(String id) async {
    var res = await get("$baseUrl/album?$baseData&id=$id");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var author = <String>[];
      for (var s in res.data["author"] ?? "未知") {
        author.add(s);
      }
      var series = <int, String>{};
      for (var s in res.data["series"] ?? []) {
        series[int.parse(s["sort"])] = s["id"];
      }
      var tags = <String>[];
      for (var s in res.data["tags"] ?? []) {
        tags.add(s);
      }
      var related = <JmComicBrief>[];
      for (var c in res.data["related_list"] ?? []) {
        related.add(JmComicBrief(
            c["id"], c["author"] ?? "未知", c["name"] ?? "未知", c["description"] ?? "无", []));
      }
      return Res(JmComicInfo(
          res.data["name"] ?? "未知",
          res.data["id"].toString(),
          author,
          res.data["description"] ?? "无",
          int.parse(res.data["likes"] ?? "0"),
          int.parse(res.data["total_views"] ?? "0"),
          series,
          tags,
          related,
          res.data["liked"] ?? false,
          res.data["is_favorite"] ?? false,
          int.parse(res.data["comment_total"] ?? "0")));
    } catch (e) {
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<Res<bool>> login(String account, String pwd) async {
    var res = await post("$baseUrl/login", "username=$account&password=$pwd&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    appdata.jmName = account;
    appdata.jmEmail = res.data["email"] ?? "";
    appdata.jmPwd = pwd;
    appdata.writeData();
    return Res(true);
  }

  ///使用储存的数据进行登录, jm必须在每次启动app时进行登录
  Future<Res<bool>> loginFromAppdata() async {
    var account = appdata.jmName;
    var pwd = appdata.jmPwd;
    if (account == "") {
      return Res(true);
    }
    var res = await post("$baseUrl/login", "username=$account&password=$pwd&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    return Res(true);
  }

  Future<void> logout() async {
    await cookieJar.deleteAll();
    appdata.jmEmail = "";
    appdata.jmName = "";
    appdata.jmPwd = "";
    await appdata.writeData();
  }

  Future<void> likeComic(String id) async {
    await post("$baseUrl/like", "id=$id&$baseData");
  }

  ///创建收藏夹
  Future<Res<bool>> createFolder(String name) async {
    var res = await post("$baseUrl/favorite_folder", "type=add&folder_name=$name&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    } else {
      return Res(true);
    }
  }

  ///获取收藏夹中的漫画
  ///
  /// 需要提供收藏夹的ID
  ///
  /// 要获取全部收藏, 提供id为0
  Future<Res<FavoriteFolder>> getFolderComics(String id) async {
    var res = await get("$baseUrl/favorite?$baseData&page=1&folder_id=$id&o=${ComicsOrder.latest}");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comics = <JmComicBrief>[];
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(
            comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
      }
      return Res(FavoriteFolder(id, comics, 1, int.parse(res.data["total"]), comics.length));
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadFavoriteFolderNextPage(FavoriteFolder folder) async {
    if (folder.loadedComics >= folder.total) {
      return;
    }
    try {
      var res = await get(
          "$baseUrl/favorite?$baseData&page=${folder.loadedPage + 1}&folder_id=${folder.id}&o=${ComicsOrder.latest}");
      for (var comic in (res.data["list"])) {
        var categories = <ComicCategoryInfo>[];
        if (comic["category"]["id"] != null && comic["category"]["title"] != null) {
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if (comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null) {
          categories
              .add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        folder.comics.add(JmComicBrief(
            comic["id"], comic["author"], comic["name"], comic["description"] ?? "", categories));
      }
      folder.loadedPage++;
      folder.loadedComics = folder.comics.length;
    } catch (e) {
      //无所谓了
    }
  }

  ///获取收藏夹
  Future<Res<Map<String, String>>> getFolders() async {
    var res = await get("$baseUrl/favorite?$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try{
      var folders = <String, String>{};
      for(var folder in res.data["folder_list"]){
        folders[folder["FID"]] = folder["name"];
      }
      return Res(folders);
    }
    catch(e){
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  ///移动漫画至指定的收藏夹
  Future<Res<bool>> moveToFolder(String comicId, String folderId) async {
    var res = await post(
        "$baseUrl/favorite_folder", "type=move&folder_id=$folderId&aid=$comicId&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    } else {
      return Res(true);
    }
  }

  ///收藏漫画
  ///
  /// Jm的收藏逻辑大概为: 收藏后会加入收藏夹页的全部漫画中, 此时如果使用官方App会出现一个选择收藏夹的弹窗, 选择后将会
  /// 再次发送一个网络请求进行移动漫画
  Future<Res<bool>> favorite(String id) async {
    var res = await post("$baseUrl/favorite", "aid=$id&$baseData");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    } else {
      return Res(true);
    }
  }

  ///获取漫画图片
  Future<Res<List<String>>> getChapter(String id) async {
    var res = await get("$baseUrl/chapter?$baseData&id=$id");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var images = <String>[];
      for (var s in res.data["images"]) {
        images.add(getJmImageUrl(s, id));
      }
      return Res(images);
    } catch (e) {
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  ///获取scramble
  ///
  /// 此函数未使用, 因为似乎所有漫画的scramble都一样
  Future<String?> getScramble(String id) async {
    var dio = Dio(getHeader(DateTime.now().millisecondsSinceEpoch ~/ 1000, byte: false))
      ..interceptors.add(LogInterceptor());
    dio.interceptors.add(CookieManager(cookieJar));
    var res = await dio.get(
        "$baseUrl/chapter_view_template?id=$id&mode=vertical&page=0&app_ima_shunt=NaN&express=off");
    var exp = RegExp(r"(?<=var scramble_id = )\w+");
    return exp.firstMatch(res.data)!.group(0);
  }

  Future<Res<List<Comment>>> getComment(String id, int page) async {
    var res = await get("$baseUrl/forum?$baseData&aid=$id&page=$page");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var comments = <Comment>[];
      for (var c in res.data["list"]) {
        var reply = <Comment>[];
        for (var r in c["replys"] ?? []) {
          reply.add(Comment(
              r["CID"], getJmAvatarUrl(r["photo"]), r["username"], r["addtime"], r["content"], []));
        }
        comments.add(Comment(c["CID"], getJmAvatarUrl(c["photo"]), c["username"], c["addtime"],
            c["content"], reply));
      }
      return Res(comments, subData: int.parse(res.data["total"]));
    } catch (e) {
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
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
  maxLikes("tf");

  @override
  String toString() => value;

  final String value;
  const ComicsOrder(this.value);
}
