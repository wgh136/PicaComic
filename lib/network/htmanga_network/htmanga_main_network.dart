import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/log_dio.dart';
import 'package:pica_comic/network/res.dart';
import 'package:html/parser.dart';

class HtmangaNetwork{
  ///用于获取绅士漫画的网络请求类
  factory HtmangaNetwork() => _cache??(_cache=HtmangaNetwork._create());

  static HtmangaNetwork? _cache;

  HtmangaNetwork._create();

  static const String baseUrl = "https://www.wnacg.com/";

  ///基本的Get请求
  Future<Res<String>> get(String url) async{
    var dio = logDio(BaseOptions(
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36",
      },
      connectTimeout: const Duration(seconds: 8),
      responseType: ResponseType.plain
    ));
    try{
      var res = await dio.get<String>(url);
      if(res.data == null){
        return const Res(null, errorMessage: "无数据");
      }
      return Res(res.data);
    }
    on DioException catch(e){
      if(e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout){
        return const Res(null, errorMessage: "连接超时");
      }else{
        return Res(null, errorMessage: e.message);
      }
    }
    catch(e){
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<HtHomePageData>> getHomePage() async{
    var res = await get(baseUrl);
    if(res.error){
      return Res(null, errorMessage: res.errorMessage);
    }
    try{
      var document = parse(res.data);
      var titles = document.querySelectorAll("div.title_sort");
      var comicBlocks = document.querySelectorAll("div.bodywrap");
      Map<String, String> titleRes = {};
      for(var title in titles){
        var text = title.querySelector("div.title_h2")!.text;
        text = text.replaceAll("\n", "");
        var link = title.querySelector("div.r > a")!.attributes["href"]!;
        link = baseUrl + link;
        titleRes[text] = link;
      }
      var comicsRes = <List<HtComicBrief>>[];
      for(var block in comicBlocks){
        var cs = block.querySelectorAll("div.gallary_wrap > ul.cc > li");
        var comics = <HtComicBrief>[];
        for(var c in cs){
          var link = c.querySelector("div.pic_box > a")!.attributes["href"]!;
          var image = c.querySelector("div.pic_box > a > img")!.attributes["src"]!;
          image = "https:$image";
          var name = c.querySelector("div.info > div.title > a")!.text;
          var infoCol = c.querySelector("div.info > div.info_col")!.text;
          var lr = infoCol.split(",");
          var time = lr[0];
          var pagesStr = "";
          for(int i = 0;i < lr[1].length; i++){
            if(lr[1][i].isNum){
              pagesStr += lr[1][i];
            }
          }
          var pages = int.parse(pagesStr);
          comics.add(HtComicBrief(name, time, image, link, pages));
        }
        comicsRes.add(comics);
      }
      if(comicsRes.length != titleRes.length){
        throw Exception("漫画块数量和标题数量不相等");
      }
      return Res(HtHomePageData(comicsRes, titleRes));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyze", "$e\n$s");
      return Res(null, errorMessage: "解析失败: $e");
    }
  }

  /// 获取给定漫画列表页面的漫画
  Future<Res<List<HtComicBrief>>> getComicList(String url, int page) async{
    if(page != 1){
      if(! url.contains("-")){
        url = url.replaceAll(".html", "-.html");
      }
      var lr = url.split("albums-");
      lr[1] = "index-page-$page${lr[1]}";
      url = "${lr[0]}albums-${lr[1]}";
    }
    var res = await get(url);
    if(res.error){
      return Res(null, errorMessage: res.errorMessage);
    }
    try{
      var document = parse(res.data);
      var comics = <HtComicBrief>[];
      for(var comic in document.querySelectorAll("div.grid > div.gallary_wrap > ul.cc > li")){
        try {
          var link = comic.querySelector("div.pic_box > a")!.attributes["href"]!;
          var image = comic.querySelector("div.pic_box > a > img")!.attributes["src"]!;
          image = "https:$image";
          var name = comic.querySelector("div.info > div.title > a")!.text;
          var infoCol = comic.querySelector("div.info > div.info_col")!.text;
          var lr = infoCol.split("，");
          var time = lr[1];
          time = time.replaceAll("\n", "");
          var pagesStr = "";
          for (int i = 0; i < lr[0].length; i++) {
            if (lr[1][i].isNum) {
              pagesStr += lr[1][i];
            }
          }
          var pages = int.parse(pagesStr);
          comics.add(HtComicBrief(name, time, image, link, pages));
        }
        catch(e){
          continue;
        }
      }
      var pagesLink = document.querySelectorAll("div.f_left.paginator > a");
      var pages = int.parse(pagesLink.last.text);
      return Res(comics, subData: pages);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }
}