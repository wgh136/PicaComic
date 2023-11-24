import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/foundation/state_controller.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/log_dio.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'jm_image.dart';
import 'jm_models.dart';

class JmNetwork {
  /// Network requests for JmComic.
  ///
  /// Use web api.
  factory JmNetwork() =>
      _cache == null ? (_cache = JmNetwork.create()) : _cache!;

  JmNetwork.create();

  static JmNetwork? _cache;

  static String get baseUrl => appdata.settings[56];

  static const cloudflareChallenge = "JM: need cloudflare challenge";

  set ua(String value) {
    appdata.nhentaiData[0] = value;
    appdata.updateNhentai();
  }

  String get ua => appdata.nhentaiData[0];

  PersistCookieJar? cookieJar;

  Future<void> init() async {
    var path = (await getApplicationSupportDirectory()).path;
    path = "$path$pathSep${"jm_cookies"}";
    cookieJar = PersistCookieJar(storage: FileStorage(path));
    loginFromAppdata();
  }

  Future<Res<String>> get(String url) async {
    if (cookieJar == null) {
      await init();
    }
    var dio = CachedNetwork();

    try {
      var res = await dio.get(
          url,
          BaseOptions(headers: {
            "User-Agent": ua,
            "Accept":
                "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Accept-Language":
                "zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6",
            "Referer": baseUrl
          }, validateStatus: (i) => i==200 || i==403 || i==301, responseType: ResponseType.plain,
          followRedirects: true),
          expiredTime: CacheExpiredTime.no,
          http2: true,
          cookieJar: cookieJar);

      if (res.statusCode == 403) {
        if (res.data.contains("Just a moment...")) {
          throw cloudflareChallenge;
        }
      }

      if(res.statusCode == 301){
        return get(res.headers["location"]!.first);
      }

      if (res.statusCode != 200) {
        return Res(null,
            errorMessage: "Invalid Status Code: ${res.statusCode}");
      }
      return Res(res.data);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<String>> post(String url, dynamic data, [String? contentType]) async{
    if (cookieJar == null) {
      await init();
    }
    var dio = logDio(BaseOptions(), true);

    dio.interceptors.add(CookieManager(cookieJar!));

    try {
      var res = await dio.post(
          url,
          data: data,
          options: Options(
            headers: {
              "User-Agent": ua,
              "Accept":
              "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
              "Accept-Language":
              "zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6",
              "Referer": baseUrl,
              if(contentType != null)
                "Content-Type": contentType,
            },
            followRedirects: false,
            validateStatus: (i) => i == 200 || i == 302 || i == 301
          ));
      if(res.statusCode == 302 || res.statusCode == 301){
        return const Res("Redirect");
      }
      if (res.statusCode != 200) {
        return Res(null,
            errorMessage: "Invalid Status Code: ${res.statusCode}");
      }
      return Res(res.data);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> loginFromAppdata() async{
    var account = appdata.jmName;
    var pwd = appdata.jmPwd;
    if (account == "") {
      return const Res(true);
    }
    return login(account, pwd);
  }

  JmComicBrief? _parseComic(dom.Element element) {
    try {
      var name = element.querySelector("span.video-title")!.text;
      var author = element.querySelector("div.title-truncate-index > a")?.text;
      author ??= element.querySelector("div.title-truncate > a")!.text;
      var tags = element.querySelectorAll("a.tag").map((e) => e.text).toList();
      tags.addAll(element.querySelectorAll("div.title-truncate > a")
          .map((e) => e.text).toList());
      var categories = element
          .querySelector("div.category-icon")
          ?.children
          .map((e) => e.text.removeAllBlank)
          .toList();
      categories ??= [
        element.querySelector("div.label-sub")!.text.removeAllBlank
      ];
      var id = (element.querySelector("div.thumb-overlay-albums > a") ??
          element.querySelector("div.thumb-overlay > a"))!
          .attributes["href"]!
          .split("/")
          .firstWhere((element) => element.isNum);
      return JmComicBrief(id, author, name, "",
          categories.map((e) => ComicCategoryInfo("", e)).toList(), tags.toSet().toList());
    } catch (e) {
      return null;
    }
  }

  (List<JmComicBrief>, int) _parsePageComics(dom.Document element) {
    var comics = element
        .querySelectorAll("div.p-b-15.p-l-5.p-r-5")
        .map((e) => _parseComic(e))
        .toList();

    while (comics.remove(null)) {}

    var pageSelectors =
        element.querySelectorAll("ul.pagination > li > select > option");
    int pages;
    try {
      pages = int.parse(pageSelectors.last.text);
    }
    catch(e){
      pages = 1;
    }

    return (List.from(comics), pages);
  }

  Future<Res<HomePageData>> getHomePage() async {
    try {
      var res = await get(baseUrl);
      if (res.error) {
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);

      var rows = document.querySelectorAll(
          "div.container > div.col-lg-12.col-md-12 > div.row");

      var data = HomePageData([]);

      for (int i = 0; i + 1 < rows.length; i += 2) {
        try {
          final title = rows[i].querySelector("div.pull-left > h4")!.text;
          final id =
          rows[i].querySelector("div.pull-right > a")!.attributes["href"];
          var comics = <JmComicBrief>[];
          for (var element
          in rows[i + 1].querySelectorAll("div.well.p-b-15.p-l-5.p-r-5")) {
            var comic = _parseComic(element);
            if (comic != null) {
              comics.add(comic);
            }
          }
          data.items.add(HomePageItem(title, id!, comics, true));
        }
        catch(e){
          break;
        }
      }
      return Res(data);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<JmComicBrief>>> getLatest(int page) async {
    try {
      var res = await get("$baseUrl/albums?o=mr&page=$page");
      if (res.error) {
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);
      var (comics, _) = _parsePageComics(document);
      return Res(comics);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<(List<JmComicBrief>, int)>> getComicsPage(
      String link, int page) async {
    var url = "$baseUrl$link";

    if (url.contains("?")) {
      url = "$url&page=$page";
    } else {
      url = "$url?page=$page";
    }
    try {
      var res = await get(url);
      if (res.error) {
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);
      var (comics, maxPage) = _parsePageComics(document);
      return Res((comics, maxPage));
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<JmComicBrief>>> searchNew(
      String keyword, int page, ComicsOrder order) async {
    appdata.searchHistory.remove(keyword);
    appdata.searchHistory.add(keyword);
    appdata.writeHistory();
    var res = await getComicsPage(
        "/search/photos?main_tag=0&search_query=${Uri.encodeComponent(keyword)}&o=$order",
        page);
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    Future.delayed(const Duration(microseconds: 500), () {
      StateController.findOrNull<PreSearchController>()?.update();
    });
    return Res(res.data.$1, subData: res.data.$2);
  }

  Future<Res<List<JmComicBrief>>> getLeaderBoard(ComicsOrder order, int page) async{
    var params = order.value.split("_");
    var url = "/albums?o=${params[0]}";
    if(params.length == 2){
      url = "$url&t=${params[1]}";
    }
    var res = await getComicsPage(url, page);
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    return Res(res.data.$1, subData: res.data.$2);
  }

  Future<Res<JmComicInfo>> getComicInfo(String id) async {
    try{
      var res = await get("$baseUrl/album/$id");
      if(res.error){
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);
      var name = document.querySelector("h1")!.text;
      var author = <String>[];
      var tags = <String>[];
      for(var element in document.querySelectorAll("div.tag-block")){
        if(element.children.length < 2){
          break;
        }
        if(element.className.contains("hot")){
          continue;
        }
        if(element.firstChild!.text!.contains("作者")){
          author.addAll(element.querySelectorAll("a").map((e) => e.text));
        } else {
          tags.addAll(element.querySelectorAll("a").map((e) => e.text.trim()));
        }
      }
      final description = document.querySelectorAll("div.col-lg-7 > div > div.p-t-5.p-b-5")[1].text;
      final likes = int.tryParse(document.querySelector("span#albim_likes_$id")!
          .text.toLowerCase().replaceAll("k", "000")) ?? 0;
      var series = <int, String>{};
      var epNames = <String>[];
      for(var element in document.querySelectorAll("div.nav-tab-content div.episode > ul > a")){
        series[series.length+1] = element.attributes["data-album"]!;
        epNames.add(element.children[0].nodes[0].text!.replaceAll("\n", " ").replaceAll("\t", "").trim());
      }
      if(series.isEmpty){
        series[1] = id;
      }
      var favorite = document.querySelector("i.far.fa-bookmark.fa-2x") == null;
      var liked = document.querySelector("i.glyphicon.glyphicon-heart.fa-2x")!.attributes["style"] != null;
      final comments = int.parse(document.querySelector("div#total_video_comments")?.text ?? "0");
      return Res(JmComicInfo(name, id, author, description, likes, 0, series,
          tags, _parsePageComics(document).$1, liked, favorite, comments, epNames));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<String>>> getChapter(String id) async{
    var res = await get("$baseUrl/photo/$id");
    if (res.error) {
      return Res(null, errorMessage: res.errorMessage);
    }
    try {
      var document = parse(res.data);
      var images = <String>[];
      for (var s in document.querySelectorAll("div.center.scramble-page")) {
        images.add(getJmImageUrl(s.id, id));
      }
      return Res(images);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> login(String account, String pwd) async {
    var res = await post("$baseUrl/login",
        "username=$account&password=${Uri.encodeComponent(pwd)}&login_remember=on&submit_login="
        , "application/x-www-form-urlencoded");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    if(res.data == "Redirect"){
      appdata.jmName = account;
      appdata.jmPwd = pwd;
      appdata.writeData();
      return const Res(true);
    }
    return const Res(null, errorMessage: "Failed to login");
  }

  Future<void> logout() async {
    var cookies = await cookieJar!.loadForRequest(Uri.parse(baseUrl));
    var cookie = cookies.firstWhereOrNull((element) => element.name == "cf_clearance");
    await cookieJar!.deleteAll();
    if(cookie != null) {
      cookieJar!.saveFromResponse(Uri.parse(baseUrl), [cookie]);
    }
    appdata.jmName = "";
    appdata.jmPwd = "";
    await appdata.writeData();
  }

  Future<Res<bool>> likeComic(String id) async {
    var res = await post("$baseUrl/ajax/vote_album", "album_id=$id&vote=likes"
        , "application/x-www-form-urlencoded; charset=UTF-8");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    return const Res(true);
  }

  Future<Res<List<JmComicBrief>>> getFolderComicsWithPage(
      String id, int page) async {
    ComicsOrder order =
      appdata.settings[42] == "0" ? ComicsOrder.latest : ComicsOrder.update;
    var folderIdParam = "";
    if(id != "0"){
      folderIdParam = "folder=$id&";
    }
    var res = await get("$baseUrl/user/${appdata.jmName}/favorite/albums?${folderIdParam}o=$order&page=$page");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      var document = parse(res.data);
      var comics = <JmComicBrief>[];
      for(final element in document.querySelectorAll("div.col-xs-6.col-sm-3.col-md-3.m-b-15.list-col")){
        final id = element.querySelector("a")!.attributes["href"]!.nums;
        final title = element.querySelector("div.video-title")!.text;
        comics.add(JmComicBrief(id, "", title, "", [], []));
      }
      try {
        var pageLis = document.querySelectorAll(
            "ul.pagination.pagination-lg > li");
        var pages = int.tryParse(pageLis[pageLis.length - 2].text);
        return Res(comics, subData: pages!);
      }
      catch(e){
        return Res(comics, subData: 1);
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<Map<String, String>>> getFolders() async {
    var res = await get("$baseUrl/user/${appdata.jmName}/favorite/albums");
    if(res.error){
      if(res.errorMessage!.contains("301")){
        return const Res(null, errorMessage: "Login Required");
      }
      return Res.fromErrorRes(res);
    }
    try{
      var document = parse(res.data);
      var folders = <String, String>{};
      for(var element in document.querySelectorAll("div#folder_list > ul > a")){
        if(element.attributes["href"] != null && element.attributes["href"]!.contains("folder")){
          var id = element.attributes["href"]!.split("folder=").last;
          var name = element.querySelector("li")!.text.trim();
          folders[id] = name;
        }
      }
      return Res(folders);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> favorite(String comicId, String? folderId) async {
    Res res;
    if(folderId != null) {
      res = await post("https://18comic.vip/ajax/favorite_album",
          "album_id=$comicId&fid=$folderId"
          , "application/x-www-form-urlencoded; charset=UTF-8");
    } else {
      res = await post("https://18comic.vip/ajax/delete_favorite_album",
          "album_id=$comicId"
          , "application/x-www-form-urlencoded; charset=UTF-8");
    }
    if(res.error){
      return Res.fromErrorRes(res);
    }
    return const Res(true);
  }

  Future<Res<List<Comment>>> getComment(String id, int page) async {
    List<Comment> parseComments(dom.Document element) {
      var res = <Comment>[];
      for(var e in element.querySelectorAll("div.panel.panel-default.timeline-panel")){
        final id = e.querySelector("div.timeline")!.attributes["data-cid"]!;
        final avatar = e.querySelector("div.timeline-left > a > img")!.attributes["src"];
        final name = e.querySelector("span.timeline-username")!.text.trim();
        final time = e.querySelector("div.timeline-date")!.text.trim();
        final content = e.querySelector("div.timeline-content")!.text.trim();
        res.add(Comment(id, "$baseUrl$avatar", name, time, content, []));
      }
      return res;
    }

    try{
      var res = await post("$baseUrl/ajax/album_pagination",
          "video_id=$id&page=$page", "application/x-www-form-urlencoded; charset=UTF-8");
      if(res.error){
        return Res.fromErrorRes(res);
      }
      var document = parse(res.data);
      var comments = parseComments(document);
      if(comments.isEmpty){
        return const Res(null, errorMessage: "No comments");
      }
      return Res(comments);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> deleteFolder(String id) async {
    var res = await post(
        "$baseUrl/user/${appdata.jmName}/favorite/albums",
        "deletefolder-name=$id",
        "application/x-www-form-urlencoded"
    );
    if(res.error){
      return Res.fromErrorRes(res);
    }
    return const Res(true);
  }

  Future<Res<Map<String, String>>> getWeekRecommendation() async {
    var res = await get("$baseUrl/week");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      var document = parse(res.data);
      var weeks = <String, String>{};
      for(var element in document.querySelectorAll("li.week-time-item > a")){
        final id = element.attributes["href"]!.nums;
        final name = element.querySelector("p.week-time")!.text;
        weeks[id] = name;
      }
      return Res(weeks);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<JmComicBrief>>> getWeekRecommendationComics(
      String id, WeekRecommendationType type) async {
    var res = await get("$baseUrl/week/$id?type=$type");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      var document = parse(res.data);
      var comics = <JmComicBrief>[];
      for(var element in document.querySelectorAll("div.weekly-video-item")){
        final id = element.querySelector("a")!.attributes["href"]!.split("/")
            .firstWhere((element) => element.isNum);
        final name = element.querySelector("p.video-title")!.text;
        final author = element.querySelectorAll("p.title-truncate > a").map((e) => e.text);
        final category = element.querySelector("div.label-category")!.text;
        final tags = element.querySelectorAll("a.label-category").map((e) => e.text);
        comics.add(JmComicBrief(id, author.first, name, "",
            [ComicCategoryInfo("", category)], tags.toList()));
      }
      return Res(comics, subData: 1);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<bool>> comment(String aid, String content) async {
    var res = await post("$baseUrl/ajax/album_comment",
        "video_id=$aid&comment=${Uri.encodeComponent(content)}&oringinator=&status=false",
        "application/x-www-form-urlencoded"
    );
    if(res.error){
      return Res.fromErrorRes(res);
    }
    var data = const JsonDecoder().convert(res.data);
    if(data["err"] == true){
      return const Res(null, errorMessage: "Failed to comment");
    }
    return const Res(true);
  }

  Future<Res<bool>> createFolder(String folder) async{
    var res = await post(
        "$baseUrl/user/${appdata.jmName}/favorite/albums",
        "addfolder-name=$folder",
        "application/x-www-form-urlencoded"
    );
    if(res.error){
      return Res.fromErrorRes(res);
    }
    return const Res(true);
  }
}

enum WeekRecommendationType {
  korean("hanman"),
  manga("manga"),
  another("another");

  const WeekRecommendationType(this.value);

  final String value;

  @override
  String toString() => value;
}

final jmNetwork = JmNetwork();

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
}
