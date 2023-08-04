import 'dart:convert';
import 'dart:math';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:get/get.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/log_dio.dart';
import 'package:pica_comic/network/res.dart';
import 'package:html/parser.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import '../../base.dart';

class HtmangaNetwork {
  ///用于获取绅士漫画的网络请求类
  factory HtmangaNetwork() => _cache ?? (_cache = HtmangaNetwork._create());

  static HtmangaNetwork? _cache;

  HtmangaNetwork._create();

  static String get baseUrl => appdata.settings[31];

  var cookieJar = CookieJar();

  ///基本的Get请求
  Future<Res<String>> get(String url,
      {bool cache = true, Map<String, String>? headers}) async {
    var dio = CachedNetwork();
    try {
      var res = await dio.get(
          url,
          BaseOptions(headers: {
            "User-Agent":
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
            if (headers != null) ...headers
          }),
          cookieJar: cookieJar,
          expiredTime: cache ? CacheExpiredTime.short : CacheExpiredTime.no);
      return Res(res.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Res(null, errorMessage: "连接超时");
      } else {
        return Res(null, errorMessage: e.toString());
      }
    } catch (e) {
      return Res(null, errorMessage: e.toString());
    }
  }

  ///基本的Post请求
  Future<Res<String>> post(String url, String data) async {
    var dio = logDio(BaseOptions(headers: {
      "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
    }));
    dio.interceptors.add(CookieManager(cookieJar));
    try {
      var res = await dio.post(url, data: data);
      return Res(res.data);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Res(null, errorMessage: "连接超时");
      } else {
        return Res(null, errorMessage: e.toString());
      }
    } catch (e) {
      return Res(null, errorMessage: e.toString());
    }
  }

  ///登录
  Future<Res<String>> login(String account, String pwd) async {
    var res = await post("$baseUrl/users-check_login.html",
        "login_name=${Uri.encodeComponent(account)}&login_pass=${Uri.encodeComponent(pwd)}");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var json = const JsonDecoder().convert(res.data);
      if (json["html"].contains("登錄成功")) {
        appdata.htName = account;
        appdata.htPwd = pwd;
        appdata.writeData();
        return const Res("ok");
      }
      return Res(null, errorMessage: json["html"]);
    } catch (e) {
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<String>> loginFromAppdata() async {
    if (appdata.htName == "") return const Res("ok");
    return login(appdata.htName, appdata.htPwd);
  }

  Future<Res<HtHomePageData>> getHomePage() async {
    var res = await get(baseUrl, cache: false);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var titles = document.querySelectorAll("div.title_sort");
      var comicBlocks = document.querySelectorAll("div.bodywrap");
      Map<String, String> titleRes = {};
      for (var title in titles) {
        var text = title.querySelector("div.title_h2")!.text;
        text = text.replaceAll("\n", "").removeAllBlank;
        var link = title.querySelector("div.r > a")!.attributes["href"]!;
        link = baseUrl + link;
        titleRes[text] = link;
      }
      var comicsRes = <List<HtComicBrief>>[];
      for (var block in comicBlocks) {
        var cs = block.querySelectorAll("div.gallary_wrap > ul.cc > li");
        var comics = <HtComicBrief>[];
        for (var c in cs) {
          var link = c.querySelector("div.pic_box > a")!.attributes["href"]!;
          var id = RegExp(r"(?<=-aid-)[0-9]+").firstMatch(link)![0]!;
          var image =
              c.querySelector("div.pic_box > a > img")!.attributes["src"]!;
          image = "https:$image";
          var name = c.querySelector("div.info > div.title > a")!.text;
          var infoCol = c.querySelector("div.info > div.info_col")!.text;
          var lr = infoCol.split(",");
          var time = lr[0];
          var pagesStr = "";
          for (int i = 0; i < lr[1].length; i++) {
            if (lr[1][i].isNum) {
              pagesStr += lr[1][i];
            }
          }
          var pages = int.parse(pagesStr);
          comics.add(HtComicBrief(name, time, image, id, pages));
        }
        comicsRes.add(comics);
      }
      if (comicsRes.length != titleRes.length) {
        throw Exception("漫画块数量和标题数量不相等");
      }
      return Res(HtHomePageData(comicsRes, titleRes));
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyze", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  /// 获取给定漫画列表页面的漫画
  Future<Res<List<HtComicBrief>>> getComicList(String url, int page, {bool searchPage = false}) async {
    if (page != 1) {
      if (url.contains("search")) {
        url = "$url&p=$page";
      } else {
        if (!url.contains("-")) {
          url = url.replaceAll(".html", "-.html");
        }
        url = url.replaceAll("index", "");
        var lr = url.split("albums-");
        lr[1] = "index-page-$page${lr[1]}";
        url = "${lr[0]}albums-${lr[1]}";
      }
    }
    var res = await get(url, cache: false);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var comics = <HtComicBrief>[];
      for (var comic in document
          .querySelectorAll("div.grid div.gallary_wrap > ul.cc > li")) {
        try {
          var link =
              comic.querySelector("div.pic_box > a")!.attributes["href"]!;
          var id = RegExp(r"(?<=-aid-)[0-9]+").firstMatch(link)![0]!;
          var image =
              comic.querySelector("div.pic_box > a > img")!.attributes["src"]!;
          image = "https:$image";
          var name = comic
              .querySelector("div.info > div.title > a")!
              .attributes["title"]
              ?.replaceAll("<em>", "")
              .replaceAll("</em>", "");
          name = name ??
              comic
                  .querySelector("div.info > div.title > a")!
                  .text
                  .replaceAll("<em>", "")
                  .replaceAll("</em>", "");
          var infoCol = comic.querySelector("div.info > div.info_col")!.text;
          var lr = infoCol.split("，");
          var time = lr[1].removeAllBlank;
          time = time.replaceAll("\n", "");
          var pagesStr = "";
          for (int i = 0; i < lr[0].length; i++) {
            if (lr[0][i].isNum) {
              pagesStr += lr[0][i];
            }
          }
          var pages = pagesStr == "" ? 0 : int.parse(pagesStr);
          comics.add(HtComicBrief(name, time, image, id, pages));
        } catch (e) {
          continue;
        }
      }
      int pages;
      try {
        if(searchPage){
          var result = int.parse(document.querySelectorAll("p.result > b")[0].text);
          var comicsOnePage = document.querySelectorAll("div.grid div.gallary_wrap > ul.cc > li").length;
          pages = result ~/ comicsOnePage + 1;
        }else{
          var pagesLink = document.querySelectorAll("div.f_left.paginator > a");
          pages = int.parse(pagesLink.last.text);
        }
      } catch (e) {
        pages = 1;
      }
      return Res(comics, subData: pages);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<HtComicBrief>>> search(String keyword, int page) {
    if (keyword != "") {
      appdata.searchHistory.remove(keyword);
      appdata.searchHistory.add(keyword);
      appdata.writeHistory();
    }
    Future.delayed(const Duration(milliseconds: 300),
            () => Get.find<PreSearchController>().update())
        .onError((error, stackTrace) => null);
    return getComicList(
        "$baseUrl/search/?q=${Uri.encodeComponent(keyword)}&f=_all&s=create_time_DESC&syn=yes",
        page, searchPage: true);
  }

  /// 获取漫画详情, subData为第一页的缩略图
  Future<Res<HtComicInfo>> getComicInfo(String id) async {
    var res =
        await get("$baseUrl/photos-index-page-1-aid-$id.html", cache: false);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var name = document.querySelector("div.userwrap > h2")!.text;
      var coverPath = document
          .querySelector(
              "div.userwrap > div.asTB > div.asTBcell.uwthumb > img")!
          .attributes["src"]!;
      coverPath = "https:$coverPath";
      coverPath = coverPath.replaceRange(6, 8, "");
      var labels = document.querySelectorAll("div.asTBcell.uwconn > label");
      var category = labels[0].text.split("：")[1];
      var pages = int.parse(
          RegExp(r"\d+").firstMatch(labels[1].text.split("：")[1])![0]!);
      var tagsDom = document.querySelectorAll("a.tagshow");
      var tags = <String, String>{};
      for (var tag in tagsDom) {
        var link = tag.attributes["href"]!;
        tags[tag.text] = link;
      }
      var description = document.querySelector("div.asTBcell.uwconn > p")!.text;
      var uploader =
          document.querySelector("div.asTBcell.uwuinfo > a > p")!.text;
      var avatar = document
          .querySelector("div.asTBcell.uwuinfo > a > img")!
          .attributes["src"]!;
      avatar = "$baseUrl/$avatar";
      var uploadNum = int.parse(
          document.querySelector("div.asTBcell.uwuinfo > p > font")!.text);
      var photosDom = document.querySelectorAll("div.pic_box.tb > a > img");
      var photos = List<String>.generate(photosDom.length,
          (index) => "http:${photosDom[index].attributes["src"]!}");
      return Res(
          HtComicInfo(id, coverPath, name, category, pages, tags, description,
              uploader, avatar, uploadNum, photos));
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<String>>> getThumbnails(String id, int page) async {
    var res = await get("$baseUrl/photos-index-page-$page-aid-$id.html");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var photosDom = document.querySelectorAll("div.pic_box.tb > a > img");
      var photos = List<String>.generate(photosDom.length,
          (index) => "http:${photosDom[index].attributes["src"]!}");
      return Res(photos);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<String>>> getImages(String id) async {
    var res = await get("$baseUrl/photos-gallery-aid-$id.html");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var urls = RegExp(r"(?<=//)[\w./\[\]-]+").allMatches(res.data);
      var images = <String>[];
      for (var url in urls) {
        images.add("https://${url[0]!}");
      }
      print(images);
      return Res(images);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  /// 获取收藏夹
  ///
  /// 返回Map, 值为收藏夹名，键为ID
  Future<Res<Map<String, String>>> getFolders() async {
    var res = await get(
        "$baseUrl/users-addfav-id-210814.html"
        "?ajax=true&_t=${Random.secure().nextDouble()}",
        cache: false);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var data = <String, String>{};
      for (var option in document.querySelectorAll("option")) {
        if (option.attributes["value"] == "") continue;
        data[option.attributes["value"]!] = option.text;
      }
      return Res(data);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<bool> createFolder(String name) async => !(await post(
          "$baseUrl/users-favc_save-id.html",
          "favc_name=${Uri.encodeComponent(name)}"))
      .error;

  Future<bool> deleteFolder(String id) async => !(await get(
          "$baseUrl/users-favclass_del-id-$id.html"
          "?ajax=true&_t=${Random.secure().nextDouble()}",
          cache: false))
      .error;

  Future<Res<bool>> addFavorite(String comicId, String folderId) async {
    var res = await post(
        "$baseUrl/users-save_fav-id-$comicId.html", "favc_id=$folderId");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    return const Res(true);
  }

  Future<Res<bool>> delFavorite(String favoriteId) async {
    var res = await get(
      "$baseUrl/users-fav_del-id-$favoriteId.html?"
      "ajax=true&_t=${Random.secure().nextDouble()}",
      cache: false,
    );
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    return const Res(true);
  }

  ///获取收藏夹中的漫画
  Future<Res<List<HtComicBrief>>> getFavoriteFolderComics(
      String folderId, int page) async {
    var res = await get(
      "$baseUrl/users-users_fav-page-$page-c-$folderId.html",
      cache: false,
    );
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var comics = <HtComicBrief>[];
      for (var comic in document.querySelectorAll("div.asTB")) {
        var cover = comic
            .querySelector("div.asTBcell.thumb > div > img")!
            .attributes["src"]!;
        cover = "https:$cover";
        var time = comic
            .querySelector("div.box_cel.u_listcon > p.l_catg > span")!
            .text
            .replaceAll("創建時間：", "");
        var name =
            comic.querySelector("div.box_cel.u_listcon > p.l_title > a")!.text;
        var link = comic
            .querySelector("div.box_cel.u_listcon > p.l_title > a")!
            .attributes["href"]!;
        var id = RegExp(r"(?<=-aid-)[0-9]+").firstMatch(link)![0]!;
        var info =
            comic.querySelector("div.box_cel.u_listcon > p.l_detla")!.text;
        var pages = int.parse(RegExp(r"(?<=頁數：)[0-9]+").firstMatch(info)![0]!);
        var delUrl = comic
            .querySelector("div.box_cel.u_listcon > p.alopt > a")!
            .attributes["onclick"]!;
        var favoriteId = RegExp(r"(?<=del-id-)[0-9]+").firstMatch(delUrl)![0];
        comics.add(
            HtComicBrief(name, time, cover, id, pages, favoriteId: favoriteId));
      }
      int pages;
      try {
        var pagesLink = document.querySelectorAll("div.f_left.paginator > a");
        pages = int.parse(pagesLink.last.text);
      } catch (e) {
        pages = page;
      }
      return Res(comics, subData: pages);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }
}
