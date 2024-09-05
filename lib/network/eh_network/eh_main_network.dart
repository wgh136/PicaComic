import 'dart:collection';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:pica_comic/comic_source/built_in/ehentai.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/pre_search_page.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/js.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../base.dart';
import '../http_client.dart';

class EhNetwork {
  factory EhNetwork() => cache == null ? (cache = EhNetwork.create()) : cache!;

  static EhNetwork? cache;

  static EhNetwork createEhNetwork() => EhNetwork();

  late List<String> folderNames;

  EhNetwork.create() {
    getCookies(true);
    folderNames = List.from(ehentai.data["favoriteNames"] ?? []);
    if(folderNames.length != 10){
      folderNames = List.generate(10, (index) => "Favorite $index");
    }
  }

  ///e-hentai的url
  String get ehBaseUrl => appdata.settings[20] == "0"
      ? "https://e-hentai.org"
      : "https://exhentai.org";

  ///api url
  get ehApiUrl => appdata.settings[20] == "0"
      ? "https://api.e-hentai.org/api.php"
      : "https://exhentai.org/api.php";

  final cookieJar = SingleInstanceCookieJar.instance!;

  ///给图片加载使用的cookie
  String cookiesStr = "";

  // 用于账号详情页面显示
  String id = "";
  String hash = "";
  String igneous = "";

  ///设置请求cookie
  Future<String> getCookies(bool setNW, [String? url]) async {
    url ??= ehBaseUrl;

    var shouldAdd = [
      if (setNW) Cookie("nw", "1")
      else Cookie("nw", "0"),
      if (appdata.settings[75] != "")
        Cookie("sp", appdata.settings[75]),
    ];

    var cookies = cookieJar.loadForRequest(Uri.parse(url));
    
    if(ehentai.isLogin
        && cookies.every((element) => element.name != "ipb_member_id")){
      // 迁移旧版本数据
      SharedPreferences prefs = await SharedPreferences.getInstance();
      id = prefs.getString("ehId") ?? "";
      hash = prefs.getString("ehPassHash") ?? "";
      igneous = prefs.getString("ehIgneous") ?? "";

      shouldAdd.add(Cookie("ipb_member_id", id));
      shouldAdd.add(Cookie("ipb_pass_hash", hash));
      if(igneous.isNotEmpty) {
        shouldAdd.add(Cookie("igneous", igneous));
      }
    }

    cookieJar.saveFromResponse(Uri.parse(url), shouldAdd);

    var res = "";
    for (var cookie in cookies) {
      res += "${cookie.name}=${cookie.value}; ";
      if(cookie.name == "ipb_member_id"){
        id = cookie.value;
      } else if(cookie.name == "ipb_pass_hash"){
        hash = cookie.value;
      } else if(cookie.name == "igneous"){
        igneous = cookie.value;
      }
    }
    if (res.length < 2) {
      return "";
    }
    cookiesStr = res.substring(0, res.length - 2);
    return cookiesStr;
  }

  ///从url获取数据, 在请求时设置了cookie
  Future<Res<String>> request(String url,
      {Map<String, String>? headers,
      CacheExpiredTime expiredTime = CacheExpiredTime.short,
      bool setNW = true}) async {
    await getCookies(setNW, url);
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        followRedirects: true,
        headers: {
          "user-agent": webUA,
          ...?headers,
          "host": Uri.parse(url).host
        });
    var dio = CachedNetwork();
    try {
      var data = await dio.get(url, options,
          cookieJar: cookieJar, expiredTime: expiredTime);
      if (data.data.isEmpty) {
        throw Exception("Empty Data. "
            "No permission to access this page.\n"
            "Please check your account and cookie.");
      }
      
      if(data.url.contains("bounce_login.php")){
        throw Exception("需要登录或者登录过期".tl);
      }
      
      await getCookies(true);
      if ((data.data).substring(0, 4) == "Your") {
        dio.delete(url);
        return const Res(null,
            errorMessage: "Your IP address has been temporarily banned");
      }
      return Res(data.data);
    } on DioException catch (e) {
      String? message;
      if (e.type != DioExceptionType.unknown) {
        message = e.message ?? "未知".tl;
      } else {
        message = e.toString().split("\n").elementAtOrNull(1);
      }
      return Res(null, errorMessage: message ?? "Network Error");
    } catch (e) {
      String? message;
      if (e.toString() != "null") {
        message = e.toString();
      }
      if(message?.contains("Redirect loop") ?? false){
        message = "Redirect loop: No permission to view this page. \nCheck your account and cookie.";
      }
      return Res(null, errorMessage: message ?? "Network Error");
    }
  }

  final apiDio = logDio(BaseOptions());

  ///eh APi请求
  Future<Res<String>> apiRequest(
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    await getCookies(false, ehApiUrl);
    await setNetworkProxy();

    try {
      var res = await apiDio.post<String>(ehApiUrl,
          data: data,
          options: Options(headers: {
            "user-agent": webUA,
            ...?headers,
            "host": Uri.parse(ehBaseUrl).host,
            "Cookie": cookiesStr
          }));
      return Res(res.data);
    } on DioException catch (e) {
      String? message;
      if (e.type != DioExceptionType.unknown) {
        message = e.message ?? "未知".tl;
      } else {
        message = e.toString().split("\n").elementAtOrNull(1);
      }
      return Res(null, errorMessage: message ?? "Network Error");
    } catch (e) {
      String? message;
      if (e.toString() != "null") {
        message = e.toString();
      }
      return Res(null, errorMessage: message ?? "Network Error");
    }
  }

  Future<Res<String>> post(
    String url,
    dynamic data, {
    Map<String, String>? headers,
  }) async {
    await getCookies(true, url);
    await setNetworkProxy(); //更新代理
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        receiveDataWhenStatusError: true,
        validateStatus: (status) => status == 200 || status == 302,
        headers: {"user-agent": webUA, ...?headers});

    var dio = logDio(options)..interceptors.add(LogInterceptor());
    dio.interceptors.add(CookieManagerSql(cookieJar));
    try {
      var res = await dio.post<String>(url, data: data);
      return Res(res.data ?? "");
    } on DioException catch (e) {
      String? message;
      if (e.type != DioExceptionType.unknown) {
        message = e.message ?? "未知".tl;
      } else {
        message = e.toString().split("\n").elementAtOrNull(1);
      }
      return Res(null, errorMessage: message ?? "Network Error");
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      String? message;
      if (e.toString() != "null") {
        message = e.toString();
      }
      return Res(null, errorMessage: message ?? "Network Error");
    }
  }

  ///获取用户名, 同时用于检测cookie是否有效
  Future<bool> getUserName() async {
    try {
      var res = await request("https://forums.e-hentai.org/",
          headers: {
            "referer": "https://forums.e-hentai.org/index.php?",
            "accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "accept-encoding": "gzip, deflate, br",
            "accept-language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"
          },
          expiredTime: CacheExpiredTime.no);
      if (res.error) {
        return false;
      }

      var html = parse(res.data);
      var name = html.querySelector("div#userlinks > p.home > b > a");
      ehentai.data['name'] = name?.text ?? '';
      return name != null;
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return false;
    }
  }

  ///解析星星的html元素的位置属性, 返回评分
  double getStarsFromPosition(String position) {
    int i = 0;
    while (position[i] != ";") {
      i++;
      if (i == position.length) {
        break;
      }
    }
    switch (position.substring(0, i)) {
      case "background-position:0px -1px":
        return 5;
      case "background-position:0px -21px":
        return 4.5;
      case "background-position:-16px -1px":
        return 4;
      case "background-position:-16px -21px":
        return 3.5;
      case "background-position:-32px -1px":
        return 3;
      case "background-position:-32px -21px":
        return 2.5;
      case "background-position:-48px -1px":
        return 2;
      case "background-position:-48px -21px":
        return 1.5;
      case "background-position:-64px -1px":
        return 1;
      case "background-position:-64px -21px":
        return 0.5;
    }
    return 0.5;
  }

  ///从e-hentai链接中获取当前页面的所有画廊
  Future<Res<Galleries>> getGalleries(String url,
      {bool leaderboard = false, bool favoritePage = false}) async {
    //从一个链接中获取所有画廊, 同时获得下一页的链接
    //leaderboard比正常的表格多了第一列
    int t = 0;
    if (leaderboard) {
      t++;
    }
    var res = await request(url, expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var galleries = <EhGalleryBrief>[];

      // compact mode
      for (var item in document.querySelectorAll("table.itg.gltc > tbody > tr")) {
        try {
          var type = item.children[0 + t].children[0].text;
          var time = item.children[1 + t].children[2].children[0].text;
          var stars = getStarsFromPosition(item
              .children[1 + t].children[2].children[1].attributes["style"]!);
          var cover = item.children[1 + t].children[1].children[0].children[0].attributes["src"];
          if (cover![0] == 'd') {
            cover = item.children[1 + t].children[1].children[0].children[0].attributes["data-src"];
          }
          var title = item.children[2 + t].children[0].children[0].text;
          var link = item.children[2 + t].children[0].attributes["href"];
          String uploader = "";
          int? pages;
          try {
            uploader = item.children[3 + t].children[0].children[0].text;
            pages = int.parse(item.children[3 + t].children[1].text.nums);
          } catch (e) {
            //收藏夹页没有uploader
          }
          var tags = <String>[];
          for (var node
              in item.children[2 + t].children[0].children[1].children) {
            tags.add(node.attributes["title"]!);
          }

          galleries.add(EhGalleryBrief(
              title, type, time, uploader, cover!, stars, link!, tags, pages: pages));
        } catch (e) {
          //表格中存在空行或者被屏蔽
          continue;
        }
      }

      // Thumbnail mode
      for (var item in document.querySelectorAll("div.gl1t")) {
        try {
          final title = item.querySelector("a")?.text ?? "Unknown";
          final type =
              item.querySelector("div.gl5t > div > div.cs")?.text ?? "Unknown";
          final time = item
                  .querySelectorAll("div.gl5t > div > div")
                  .firstWhereOrNull(
                      (element) => DateTime.tryParse(element.text) != null)
                  ?.text ??
              "Unknown";
          final coverPath = item.querySelector("img")?.attributes["src"] ?? "";
          final stars = getStarsFromPosition(item
                  .querySelector("div.gl5t > div > div.ir")
                  ?.attributes["style"] ??
              "");
          final link = item.querySelector("a")?.attributes["href"] ?? "";
          final pages = int.tryParse(item
                  .querySelectorAll("div.gl5t > div > div")
                  .firstWhereOrNull((element) => element.text.contains("pages"))
                  ?.text
                  .nums ??
              "");
          galleries.add(EhGalleryBrief(
              title, type, time, "", coverPath, stars, link, [],
              pages: pages));
        } catch (e) {
          //忽视
        }
      }

      // Extended mode
      for(var item in document.querySelectorAll("table.itg.glte > tbody > tr")){
        try{
          final title = item.querySelector("td.gl2e > div > a > div > div.glink")?.text ?? "Unknown";
          final type = item.querySelector("td.gl2e > div > div.gl3e > div.cn")?.text ?? "Unknown";
          final time = item.querySelectorAll("td.gl2e > div > div.gl3e > div")
              .firstWhereOrNull((element) => DateTime.tryParse(element.text) != null)?.text ?? "Unknown";
          final uploader = item.querySelector("td.gl2e > div > div.gl3e > div > a")?.text ?? "Unknown";
          final coverPath = item.querySelector("td.gl1e > div > a > img")?.attributes["src"] ?? "";
          final stars = getStarsFromPosition(item.querySelector("td.gl2e > div > div.gl3e > div.ir")?.attributes["style"] ?? "");
          final link = item.querySelector("td.gl1e > div > a")?.attributes["href"] ?? "";
          final tags = item.querySelectorAll("div.gtl").map((e) => e.attributes["title"] ?? "").toList();
          final pages = int.tryParse(item.querySelectorAll("td.gl2e > div > div.gl3e > div")
              .firstWhereOrNull((element) => element.text.contains("pages"))?.text.nums ?? "");
          galleries.add(EhGalleryBrief(title, type, time, uploader, coverPath, stars, link, tags, pages: pages));
        }
        catch(e){
          //忽视
        }
      }

      // minimal mode
      for(var item in document.querySelectorAll("table.itg.gltm > tbody > tr")){
        try{
          final title = item.querySelector("td.gl3m > a > div.glink")?.text ?? "Unknown";
          final type = item.querySelector("td.gl1m > div.cs")?.text ?? "Unknown";
          final time = item.querySelectorAll("td.gl2m > div")
              .firstWhereOrNull((element) => DateTime.tryParse(element.text) != null)?.text ?? "Unknown";
          final uploader = item.querySelector("td.gl5m > div > a")?.text ?? "Unknown";
          final coverPath = item.querySelector("td.gl2m > div > div > img")?.attributes["src"] ?? "";
          final stars = getStarsFromPosition(item.querySelector("td.gl4m > div.ir")?.attributes["style"] ?? "");
          final link = item.querySelector("td.gl3m > a")?.attributes["href"] ?? "";
          galleries.add(EhGalleryBrief(title, type, time, uploader, coverPath, stars, link, []));
        }
        catch(e){
          //忽视
        }
      }

      var g = Galleries();
      var nextButton = document.getElementById("dnext");
      if (nextButton == null) {
        g.next = null;
      } else {
        g.next = nextButton.attributes["href"];
      }
      g.galleries = galleries;

      //获取收藏夹名称
      if (favoritePage && ehentai.isLogin) {
        var names = <String>[];
        try {
          var folderDivs = document.querySelectorAll("div.fp");
          for (var folderDiv in folderDivs) {
            var name = folderDiv.children.elementAtOrNull(2)?.text ??
                "Favorite ${names.length}";
            var length = folderDiv.children.elementAtOrNull(0)?.text;
            if (length != null) {
              length = " ($length)";
            }
            length ??= "";
            names.add("$name$length");
          }
          if (names.length != 10) {
            names = names.sublist(0, 10);
          }
          bool isSame = true;
          if (folderNames.length == names.length) {
            for (int i = 0; i < folderNames.length; i++) {
              if (folderNames[i] != names[i]) {
                isSame = false;
                break;
              }
            }
          } else {
            isSame = false;
          }
          if (!isSame) {
            folderNames = names;
            ehentai.data["favoriteNames"] = names;
            ehentai.saveData();
          }
        } catch (e) {
          //忽视
        }
        return Res(g, subData: folderNames);
      }
      return Res(g);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取画廊的下一页
  Future<bool> getNextPageGalleries(Galleries galleries) async {
    if (galleries.next == null) return true;
    var next = await getGalleries(galleries.next!);
    if (next.error) return false;
    galleries.galleries.addAll(next.data.galleries);
    galleries.next = next.data.next;
    return true;
  }

  Comment _parseComment(dom.Element e) {
    var name = e
        .getElementsByClassName("c3")[0]
        .getElementsByTagName("a")
        .elementAtOrNull(0)
        ?.text ??
        "未知";
    var time = e.getElementsByClassName("c3")[0].text.subStringOrNull(11, 32) ??
        "Unknown";
    var content = e.getElementsByClassName("c6")[0].text;
    var score = int.parse(e.querySelector("div.c5 > span")?.text ?? '0');
    var id = e.previousElementSibling?.attributes['name']?.nums ?? "0";
    bool voteUp = e.querySelector("a#comment_vote_up_$id")?.attributes['style']?.isNotEmpty == true;
    bool voteDown = e.querySelector("a#comment_vote_down_$id")?.attributes['style']?.isNotEmpty == true;
    bool? vote;
    if(voteUp){
      vote = true;
    } else if(voteDown){
      vote = false;
    }
    return Comment(id, name, content, time, score, vote);
  }

  ///从漫画详情页链接中获取漫画详细信息
  Future<Res<Gallery>> getGalleryInfo(String link, [bool setNW = true]) async {
    try {
      var res =
          await request(link, expiredTime: CacheExpiredTime.no, setNW: setNW);
      if (res.error) {
        return Res(null, errorMessage: res.errorMessage);
      }
      if (res.data.contains("Content Warning") &&
          res.data.contains("Never Warn Me Again")) {
        return const Res(null, errorMessage: "Content Warning");
      }
      var document = parse(res.data);
      //tags
      var tags = <String, List<String>>{};
      var tagLists =
          document.querySelectorAll("div#taglist > table > tbody > tr");
      for (var tr in tagLists) {
        var list = <String>[];
        for (var div in tr.children[1].children) {
          list.add(div.children[0].text);
        }
        tags[tr.children[0].text.substring(0, tr.children[0].text.length - 1)] =
            list;
      }
      String maxPage = "1";

      for (var element in document.querySelectorAll("td.gdt2")) {
        if (element.text.contains("pages")) {
          maxPage = element.text.nums;
        }
      }

      bool favorite = true;
      if (document.getElementById("favoritelink")?.text ==
          " Add to Favorites") {
        favorite = false;
      }
      var coverPath = document
          .querySelector("div#gleft > div#gd1 > div")!
          .attributes["style"]!;
      coverPath =
          RegExp(r"https?://([-a-zA-Z0-9.]+(/\S*)?\.(?:jpg|jpeg|gif|png))")
              .firstMatch(coverPath)![0]!;
      //评论
      var comments = <Comment>[];
      for (var c in document.getElementsByClassName("c1")) {
        comments.add(_parseComment(c));
      }
      //上传者
      var uploader =
          document.getElementById("gdn")!.children.elementAtOrNull(0)?.text ??
              "未知";

      //星星
      var stars = getStarsFromPosition(
          document.getElementById("rating_image")!.attributes["style"]!);

      //平均分数
      var rating = document.getElementById("rating_label")?.text;
      //类型
      var type = document.getElementsByClassName("cs")[0].text;
      //时间
      var time = document
          .querySelector("div#gdd > table > tbody > tr > td.gdt2")!
          .text;
      //身份认证数据
      var auth = getVariablesFromJsCode(res.data);
      var thumbnailUrls = <String>[];
      var title = document.querySelector("h1#gn")!.text;
      var subTitle = document.querySelector("h1#gj")?.text;
      if (subTitle != null && subTitle.removeAllBlank == "") {
        subTitle = null;
      }
      var thumbnailDiv =
          document.querySelectorAll("div.gdtm > div").elementAtOrNull(0);
      if (thumbnailDiv != null) {
        var pattern = RegExp(r"/m/(\d+)/");
        var match = pattern.firstMatch(thumbnailDiv.attributes["style"] ?? "");

        if (match != null) {
          var extractedValue = match.group(1);
          if (extractedValue != null) {
            auth["thumbnailKey"] = extractedValue;
          }
        }
      } else {
        var imgDom = document.querySelectorAll("div.gdtl > a > img");
        for (var i in imgDom) {
          if (i.attributes["src"] != null) {
            thumbnailUrls.add(i.attributes["src"]!);
          }
        }
        var totalPages = document.querySelectorAll("table.ptt > tbody > tr > td > a")
            .where((element) => element.text.isNum).last.text;
        auth["thumbnailKey"] = "large thumbnail: $totalPages";
      }
      var archiveDownload = document.querySelectorAll('a')
          .firstWhereOrNull((element) => element.text == "Archive Download")
          ?.attributes["onclick"];
      if(archiveDownload != null){
        archiveDownload = archiveDownload.split("'")[1];
        if(archiveDownload.isURL){
          auth["archiveDownload"] = archiveDownload;
        }
      }
      return Res(Gallery(
          title,
          type,
          time,
          uploader,
          stars,
          rating,
          coverPath,
          tags,
          comments,
          auth,
          favorite,
          link,
          maxPage,
          thumbnailUrls,
          subTitle));
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<Comment>>> getComments(String url) async {
    var res = await request("$url?hc=1", expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var resComments = <Comment>[];
      var comments = document.getElementsByClassName("c1");
      for (var c in comments) {
        resComments.add(_parseComment(c));
      }
      return Res(resComments);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Set<String> loadingReaderLinks = {};

  Future<Res<String>> getReaderLink(String gLink, int page) async {
    var res = await _getReaderLinks(gLink, 1);
    if (page <= res.data.length) {
      return Res(res.data[page - 1]);
    }
    var urlsOnePage = res.data.length;

    final shouldLoadPage = (page - 1) ~/ urlsOnePage + 1;
    final urlsRes = (await _getReaderLinks(gLink, shouldLoadPage));
    if (urlsRes.error) {
      return Res.fromErrorRes(urlsRes);
    }
    return Res(urlsRes.data[(page - 1) % urlsOnePage]);
  }

  /// page starts from 1
  Future<Res<List<String>>> _getReaderLinks(String link, int page) async {
    String url = link;
    if (page != 1) {
      url = url.contains("?") ? "$url&p=${page - 1}" : "$url?p=${page - 1}";
    }
    while (loadingReaderLinks.contains(url)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    loadingReaderLinks.add(url);
    var res = await request(url);
    loadingReaderLinks.remove(url);
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var urls_ = <String>[];
      var temp = parse(res.data);
      var links = temp.querySelectorAll("div#gdt > div.gdtm > div > a");
      for (var link in links) {
        urls_.add(link.attributes["href"]!);
      }
      links = temp.querySelectorAll("div#gdt > div.gdtl > a");
      for (var link in links) {
        urls_.add(link.attributes["href"]!);
      }
      return Res(urls_);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<(String image, String? nl)> getImageLinkWithNL(
      String gid, String imgKey, int p, String nl) async {
    var res = await request("$ehBaseUrl/s/$imgKey/$gid-$p?nl=$nl");
    if (res.error) {
      throw res.errorMessage ?? "error";
    } else {
      var document = parse(res.data);
      var image = document.querySelector("div#i3 > a > img")?.attributes["src"];
      var nl = document
          .querySelector("div#i6 > div > a#loadfail")
          ?.attributes["onclick"]
          ?.split('\'')
          .firstWhereOrNull((element) => element.contains('-'));
      return (image ?? (throw "Failed to get image."), nl);
    }
  }

  Future<Res<List<String>>> getThumbnailUrls(Gallery gallery) async {
    if (gallery.auth!["thumbnailKey"] == null) {
      var res = await request(gallery.link);
      if (res.error) {
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);
      var thumbnailDiv = document.querySelectorAll("div.gdtm > div")[0];
      var pattern = RegExp(r'url\((.*?)\)');
      var match = pattern.firstMatch(thumbnailDiv.attributes["style"] ?? "");

      if (match != null) {
        var extractedValue = match.group(1);
        if (extractedValue != null) {
          gallery.auth!["thumbnailKey"] = extractedValue.replaceRange(
            extractedValue.lastIndexOf('/'),
            null,
            '',
          );
        }
      } else {
        return const Res(null, errorMessage: "Failed to get Thumbnail");
      }
    }
    return Res(List.generate(int.parse(gallery.maxPage), (index) {
      var page = (index ~/ 20).toString();
      if (page.length == 1) {
        page = "0$page";
      }
      return "${gallery.auth!["thumbnailKey"]!}/${getGalleryId(gallery.link)}-$page.jpg";
    }));
  }

  Future<Res<List<String>>> getLargeThumbnails(Gallery gallery, int page) async{
    var res = await request("${gallery.link}?p=$page");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    var document = parse(res.data);
    return Res(document.querySelectorAll("div.gdtl > a > img").map((e) => e.attributes["src"] ?? "").toList());
  }

  List<String> _splitKeyword(String keyword) {
    var res = <String>[];
    var buffer = StringBuffer();
    var qs = Queue<String>();
    for(int i = 0; i<keyword.length; i++) {
      var char = keyword[i];
      if(char == '"' || char == "'") {
        if(qs.isEmpty) {
          qs.add(char);
        } else {
          if(qs.first == char) {
            qs.removeFirst();
          } else {
            qs.add(char);
          }
        }
      }
      if(char == ' ') {
        if(qs.isEmpty) {
          res.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      } else {
        buffer.write(char);
      }
    }
    if(buffer.isNotEmpty) {
      res.add(buffer.toString());
    }
    return res;
  }

  ///搜索e-hentai
  Future<Res<Galleries>> search(String keyword,
      {int? fCats, int? startPages, int? endPages, int? minStars}) async {
    if (keyword != "") {
      appdata.searchHistory.remove(keyword);
      appdata.searchHistory.add(keyword);
      appdata.writeHistory();
    }
    keyword = keyword.replaceAll(RegExp(r"\s+"), " ").trim();
    if(keyword.contains(" | ")) {
      var keywords = _splitKeyword(keyword);
      var newKeywords = <String>[];
      for(var k in keywords) {
        if(!k.contains(' | '))  {
          newKeywords.add(k);
        } else {
          var lr = k.split(':');
          if(lr.length != 2
              && !((lr[1].startsWith('"') && lr[1].endsWith('"'))
              || (lr[1].startsWith("'") && lr[1].endsWith("'")))
          ) {
            newKeywords.add(k);
          } else {
            var key = lr[0];
            var value = lr[1].substring(1, lr[1].length-1);
            value = '${value.split(' | ').first}\$';
            newKeywords.add('$key:"$value"');
          }
        }
      }
      keyword = newKeywords.join(' ');
    }
    var requestUrl = "$ehBaseUrl/?f_search=$keyword";
    if (fCats != null) {
      requestUrl += "&f_cats=$fCats";
    }
    if (startPages != null) {
      requestUrl += "&f_spf=$startPages";
    }
    if (endPages != null) {
      requestUrl += "&f_spt=$endPages";
    }
    if (minStars != null) {
      requestUrl += "&f_srdd=$minStars";
    }
    var res = await getGalleries(requestUrl);
    Future.delayed(const Duration(microseconds: 500), () {
      try {
        StateController.find<PreSearchController>().update();
      } catch (e) {
        //忽视
      }
    });
    return res;
  }

  Future<Res<List<EhGalleryBrief>>> getLeaderBoardByPage(
      int type, int page) async {
    var res = await getGalleries(
      "https://e-hentai.org/toplist.php?tl=$type&p=$page",
      leaderboard: true,
    );
    if(res.error){
      return Res.fromErrorRes(res);
    }
    return Res(res.data.galleries, subData: 200);
  }

  ///获取排行榜
  Future<Res<EhLeaderboard>> getLeaderboard(EhLeaderboardType type) async {
    var res = await getGalleries(
        "https://e-hentai.org/toplist.php?tl=${type.value}",
        leaderboard: true);
    if (res.error) return Res(null, errorMessage: res.errorMessage);
    return Res(EhLeaderboard(type, res.data.galleries, 0));
  }

  ///获取排行榜的下一页
  Future<void> getLeaderboardNextPage(EhLeaderboard leaderboard) async {
    if (leaderboard.loaded == EhLeaderboard.max) {
      return;
    } else {
      var res = await getGalleries(
          "https://e-hentai.org/toplist.php?tl=${leaderboard.type.value}&p=${leaderboard.loaded + 1}",
          leaderboard: true);
      if (!res.error) {
        leaderboard.galleries.addAll(res.data.galleries);
      }
      leaderboard.loaded++;
    }
  }

  ///评分
  Future<bool> rateGallery(Map<String, String> auth, int rating) async {
    var res = await apiRequest({
      "method": "rategallery",
      "apiuid": auth["apiuid"],
      "apikey": auth["apikey"],
      "gid": auth["gid"],
      "token": auth["token"],
      "rating": rating
    });
    return !res.error;
  }

  ///收藏
  Future<bool> favorite(String gid, String token, {String id = "0"}) async {
    var res = await post(
        "https://e-hentai.org/gallerypopups.php?gid=$gid&t=$token&act=addfav",
        "favcat=$id&favnote=&apply=Add+to+Favorites&update=1",
        headers: {"Content-Type": "application/x-www-form-urlencoded"});
    if (res.error) {
      return false;
    }
    if (res.error || res.data.isEmpty || res.data[0] != "<") {
      return false;
    } else {
      return true;
    }
  }

  ///取消收藏
  Future<bool> unfavorite(String gid, String token) async {
    var res = await post(
        "https://e-hentai.org/gallerypopups.php?gid=$gid&t=$token&act=addfav",
        "favcat=favdel&favnote=&apply=Apply+Changes&update=1",
        headers: {"Content-Type": "application/x-www-form-urlencoded"});
    if (res.error || res.data[0] != "<") {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> unfavorite2(String gid) async {
    var res = await post("https://e-hentai.org/favorites.php",
        "ddact=delete&modifygids%5B%5D=$gid",
        headers: {"Content-Type": "application/x-www-form-urlencoded"});
    if (res.error) {
      return false;
    } else {
      return true;
    }
  }

  ///发送评论
  Future<Res<bool>> comment(String content, String link) async {
    var res = await post(
        link, "commenttext_new=${Uri.encodeComponent(content)}",
        headers: {"Content-Type": "application/x-www-form-urlencoded"});

    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    var document = parse(res.data);
    if (document.querySelector("p.br") != null) {
      return Res(null, errorMessage: document.querySelector("p.br")!.text);
    }
    return const Res(true);
  }

  Future<Res<EhImageLimit>> getImageLimit() async{
    if(!ehentai.isLogin){
      return const Res(null, errorMessage: "Not logged in");
    }
    var [res, res1] = await Future.wait([
      request("https://e-hentai.org/home.php", expiredTime: CacheExpiredTime.no),
      request("https://e-hentai.org/exchange.php?t=gp", expiredTime: CacheExpiredTime.no)
    ]);
    if(res.error){
      return Res.fromErrorRes(res);
    }
    if(res1.error){
      return Res.fromErrorRes(res1);
    }
    var document = parse(res.data);
    var infoBox = document.querySelectorAll("div.homebox > p")
        .firstWhere((element) => element.text.contains("You are currently at"));
    var [current, limit] = infoBox.querySelectorAll("strong").map((e) => e.text).toList();
    var resetBox = document.querySelectorAll("div.homebox > p")
        .firstWhere((element) => element.text.contains("Reset Cost"));
    var cost = resetBox.querySelector("strong")!.text;
    document = parse(res1.data);
    var credits = document.querySelectorAll("div.outer > div > div")
        .where((element) => element.children.isEmpty && element.text.contains("Credits")).map((e) => e.text.nums).first;
    var gp = document.querySelectorAll("div.outer > div > div")
        .where((element) => element.children.isEmpty && element.text.contains("kGP")).map((e) => e.text.nums).first;
    return Res(EhImageLimit(int.parse(current.nums), int.parse(limit.nums),
        int.parse(cost.nums), int.parse(gp.nums), int.parse(credits.nums)));
  }

  Future<bool> resetImageLimit() async{
    if(!ehentai.isLogin){
      return false;
    }
    var res = await post("https://e-hentai.org/home.php", "reset_imagelimit=Reset+Limit",
        headers: {"Content-Type": "application/x-www-form-urlencoded"});
    if(res.error){
      return false;
    }
    return true;
  }
  
  /// key - value: id - name
  Future<Res<Map<String, String>>> getProfiles() async{
    var res = await request("$ehBaseUrl/uconfig.php", expiredTime: CacheExpiredTime.no);
    if(res.error){
      return Res.fromErrorRes(res);
    }
    var document = parse(res.data);
    var options = document.querySelectorAll("select[name=profile_set] > option");
    if(options.isEmpty){
      return const Res.error("No profiles found");
    } else {
      return Res({ for (var e in options) e.attributes["value"] ?? "" : e.text });
    }
  }

  Future<Res<ArchiveDownloadInfo>> getArchiveDownloadInfo(String url) async{
    var res = await request(url, expiredTime: CacheExpiredTime.no);
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    try {
      var document = parse(res.data);
      var body = document.querySelector("div#db")!;
      int index = url.contains("exhentai") ? 1 : 3;
      var origin = body.children[index].children[0];
      var originCost = origin.querySelector("div > strong")!.text;
      var originSize = origin.querySelector("p > strong")!.text;
      var resample = body.children[index].children[1];
      var resampleCost = resample.querySelector("div > strong")!.text;
      var resampleSize = resample.querySelector("p > strong")!.text;
      return Res(ArchiveDownloadInfo(originSize, resampleSize,
          originCost, resampleCost,
          document.querySelector("form#invalidate_form")?.attributes["action"],
      ));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s\n${res.data}");
      return Res.error(e.toString());
    }
  }

  Future<Res<ArchiveDownloadInfo>> cancelAndReloadArchiveInfo(ArchiveDownloadInfo info) async{
    var url = info.cancelUnlockUrl!;
    var res = await post(url, "invalidate_sessions=1", headers: {
      "content-type": "application/x-www-form-urlencoded",
    });
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    try {
      var document = parse(res.data);
      var body = document.querySelector("div#db")!;
      int index = url.contains("exhentai") ? 1 : 3;
      var origin = body.children[index].children[0];
      var originCost = origin.querySelector("div > strong")!.text;
      var originSize = origin.querySelector("p > strong")!.text;
      var resample = body.children[index].children[1];
      var resampleCost = resample.querySelector("div > strong")!.text;
      var resampleSize = resample.querySelector("p > strong")!.text;
      return Res(ArchiveDownloadInfo(originSize, resampleSize,
          originCost, resampleCost,
          document.querySelector("form#invalidate_form")?.attributes["action"],
      ));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s\n${res.data}");
      return Res.error(e.toString());
    }
  }

  Future<Res<String>> getArchiveDownloadLink(String apiUrl, int type) async{
    try {
      var data = type == 1
          ? "dltype=org&dlcheck=Download+Original+Archive"
          : "dltype=res&dlcheck=Download+Resample+Archive";
      var res = await post(apiUrl, data, headers: {
        "content-type": "application/x-www-form-urlencoded",
      });
      if (res.error) {
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);
      var link = document
          .querySelector("a")
          ?.attributes["href"];
      if (link == null) {
        return const Res.error("Failed to get download link");
      }
      var res2 = await logDio().get<String>(link);
      document = parse(res2.data);
      var link2 = document
          .querySelector("a")
          ?.attributes["href"];
      var host = Uri.parse(link).host;
      return Res("https://$host$link2");
    }
    catch(e){
      return Res.error(e.toString());
    }
  }

  Future<Res<int>> voteComment(Map<String, String> auth, String cid, bool isUp) async {
    var res = await apiRequest({
      "method": "votecomment",
      "apikey": auth["apikey"],
      "apiuid": auth["apiuid"],
      "comment_id": cid,
      "gid": auth["gid"],
      "token": auth["token"],
      "comment_vote": isUp ? "1" : "-1"
    });
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try {
      var json = jsonDecode(res.data);
      var newScore = json["comment_score"];
      if(newScore is! int) {
        return const Res.error("Failed to get new score");
      }
      return Res(newScore);
    }
    catch(e){
      return Res.error(e.toString());
    }
  }
}
