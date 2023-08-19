import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'models.dart';
import 'package:html/parser.dart';
import 'package:get/get.dart';

export 'models.dart';

class NhentaiNetwork{
  factory NhentaiNetwork() => _cache ?? (_cache = NhentaiNetwork._create());
  NhentaiNetwork._create();

  String get ua => appdata.nhentaiData[0];

  set ua(String value){
    appdata.nhentaiData[0] = value;
    appdata.updateNhentai();
  }

  static NhentaiNetwork? _cache;

  PersistCookieJar? cookieJar;

  static const String needCloudflareChallengeMessage = "need Cloudflare Challenge";

  Future<void> _init() async{
    var path = (await getApplicationSupportDirectory()).path;
    path = "$path$pathSep${"cookies"}";
    cookieJar = PersistCookieJar(storage: FileStorage(path));
  }

  Future<Res<String>> get(String url) async{
    if(cookieJar == null){
      await _init();
    }
    var dio = CachedNetwork();
    try {
      var res = await dio.get(url, BaseOptions(
          headers: {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
            "Accept-Language": "zh-CN,zh-TW;q=0.9,zh;q=0.8,en-US;q=0.7,en;q=0.6",
            if(url != "https://nhentai.net/")
              "Referer": "https://nhentai.net",
            "User-Agent": ua
          },
          validateStatus: (i) => i == 200 || i == 403
      ), expiredTime: CacheExpiredTime.no, cookieJar: cookieJar);
      if(res.statusCode == 403){
        return const Res(null, errorMessage: needCloudflareChallengeMessage);  // need to bypass cloudflare
      }
      return Res(res.data);
    }
    catch(e){
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<NhentaiHomePageData>> getHomePage() async{
    var res = await get("https://nhentai.net");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      NhentaiComicBrief parseComic(Element comicDom){
        var img = comicDom.querySelector("a > img")!.attributes["data-src"]!;
        var name = comicDom.querySelector("div.caption")!.text;
        var id = comicDom.querySelector("a")!.attributes["href"]!.nums;
        return NhentaiComicBrief(name, img, id);
      }

      var document = parse(res.data);
      var popularDoms = document.querySelectorAll(
          "div.container.index-container.index-popular > div.gallery");
      var latest = document.querySelectorAll(
          "div.container.index-container > div.gallery");

      return Res(NhentaiHomePageData(
          List.generate(popularDoms.length, (index) => parseComic(popularDoms[index])),
          List.generate(latest.length-popularDoms.length, (index) => parseComic(latest[index+popularDoms.length]))));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  Future<Res<bool>> loadMoreHomePageData(NhentaiHomePageData data) async{
    var res = await get("https://nhentai.net?page=${data.page+1}");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      NhentaiComicBrief parseComic(Element comicDom){
        var img = comicDom.querySelector("a > img")!.attributes["data-src"]!;
        var name = comicDom.querySelector("div.caption")!.text;
        var id = comicDom.querySelector("a")!.attributes["href"]!.nums;
        return NhentaiComicBrief(name, img, id);
      }

      var document = parse(res.data);

      var latest = document.querySelectorAll("div.gallery");

      data.latest.addAll(List.generate(latest.length, (index) => parseComic(latest[index])));

      data.page++;

      return const Res(true);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  Future<Res<List<NhentaiComicBrief>>> search(String keyword, int page) async{
    if(appdata.searchHistory.contains(keyword)){
      appdata.searchHistory.remove(keyword);
    }
    appdata.searchHistory.add(keyword);
    appdata.writeHistory();
    var res = await get("https://nhentai.net/search/?q=${Uri.encodeComponent(keyword)}&page=$page");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      NhentaiComicBrief parseComic(Element comicDom){
        var img = comicDom.querySelector("a > img")!.attributes["data-src"]!;
        var name = comicDom.querySelector("div.caption")!.text;
        var id = comicDom.querySelector("a")!.attributes["href"]!.nums;
        return NhentaiComicBrief(name, img, id);
      }

      var document = parse(res.data);

      var comicDoms = document.querySelectorAll("div.gallery");

      var results = document.querySelector("div#content > h1")!.text;

      Future.microtask(() => Get.find<PreSearchController>().update());

      if(comicDoms.isEmpty){
        return const Res([], subData: 0);
      }

      return Res(List.generate(comicDoms.length,
              (index) => parseComic(comicDoms[index])),
          subData: (int.parse(results.nums) / comicDoms.length).ceil());
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  Future<Res<NhentaiComic>> getComicInfo(String id) async{
    var res = await get("https://nhentai.net/g/$id/");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      NhentaiComicBrief parseComic(Element comicDom){
        var img = comicDom.querySelector("a > img")!.attributes["data-src"]!;
        var name = comicDom.querySelector("div.caption")!.text;
        var id = comicDom.querySelector("a")!.attributes["href"]!.nums;
        return NhentaiComicBrief(name, img, id);
      }

      String combineSpans(Element title){
        var res = "";
        for(var span in title.children){
          res += span.text;
        }
        return res;
      }

      var document = parse(res.data);

      var cover = document.querySelector("div#cover > a > img")!.attributes["data-src"]!;

      var title = combineSpans(document.querySelector("h1.title")!);

      var subTitle = combineSpans(document.querySelector("h2.title")!);

      Map<String, List<String>> tags = {};
      for(var field in document.querySelectorAll("div.tag-container")){
        var fieldName = field.text.removeAllBlank.replaceFirst(RegExp(r":.+"), "");
        if(fieldName == "Uploaded") continue;
        tags[fieldName] = [];
        for(var span in field.querySelectorAll("span.name")){
          tags[fieldName]!.add(span.text);
        }
      }

      bool favorite = document.querySelector("button#favorite > span.text")?.text == "Favorite";

      var thumbnails = <String>[];
      for(var t in document.querySelectorAll("a.gallerythumb > img")){
        thumbnails.add(t.attributes["data-src"]!);
      }

      var recommendations = <NhentaiComicBrief>[];
      for(var comic in document.querySelectorAll("div.gallery")){
        recommendations.add(parseComic(comic));
      }

      return Res(NhentaiComic(id, title, subTitle, cover, tags, favorite, thumbnails, recommendations));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  Future<Res<List<NhentaiComment>>> getComments(String id) async{
    var res = await get("https://nhentai.net/api/gallery/$id/comments");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      var json = const JsonDecoder().convert(res.data);
      var comments = <NhentaiComment>[];
      for(var c in json){
        comments.add(NhentaiComment(
            c["poster"]["username"], "https://i3.nhentai.net/" + c["poster"]["avatar_url"], c["body"],
            c["post_date"]));
      }
      return Res(comments);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  Future<Res<List<String>>> getImages(String id) async{
    var res = await get("https://nhentai.net/g/$id/1/");
    if(res.error){
      return Res.fromErrorRes(res);
    }
    try{
      var document = parse(res.data);
      var script = document.querySelectorAll("script").firstWhere(
              (element) => element.text.contains("window._gallery")).text;


      Map<String, dynamic> parseJavaScriptJson(String jsCode) {
        String jsonText = jsCode.split('JSON.parse("')[1].split('");')[0];
        String decodedJsonText = jsonText.replaceAll("\\u0022", "\"");

        return json.decode(decodedJsonText);
      }

      var galleryData = parseJavaScriptJson(script);

      String mediaId = galleryData["media_id"];

      var images = <String>[];

      for(var image in galleryData["images"]["pages"]){
        images.add("https://i7.nhentai.net/galleries/$mediaId/${images.length+1}"
            ".${image["t"] == 'j' ? 'jpg' : 'png'}");
      }
      return Res(images);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }
}