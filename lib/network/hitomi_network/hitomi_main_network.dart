import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:pica_comic/tools/debug.dart';
import '../res.dart';
import 'hitomi_models.dart';

/// 用于 hitomi.la 的网络请求类
class HiNetwork{
  factory HiNetwork() => cache==null ? (cache=HiNetwork._create()) : cache!;

  HiNetwork._create();

  static HiNetwork? cache;

  final baseUrl = "https://hitomi.la/";

  ///改写自 hitomi.la 网站上的js脚本
  ///
  /// 接收byte数据, 将每4个byte合成1个int32即为漫画id
  ///
  /// 发送请求时需要在请求头设置开始接收位置和最后接收位置, 为和js脚本保持一致, 设置长度为 100 byte,
  /// 因此只需要传入开始位置即可
  ///
  /// 响应头中 Content-Range 指明数据范围, 此函数用subData形式返回此值
  Future<Res<List<int>>> fetchComicData(String url, int start, {int? maxLength}) async{
    try{
      var end = start + 100 - 1;
      var dio = Dio();
      dio.options.responseType = ResponseType.bytes;
      dio.options.headers = {
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        "Range": "bytes=$start-$end"
      };
      var res = await dio.get(url);
      var bytes = Uint8List.fromList(res.data);
      var comicIds = <int>[];
      for (int i = 0; i < bytes.length; i += 4) {
        Int8List list = Int8List(4);
        list[0] = bytes[i];
        list[1] = bytes[i + 1];
        list[2] = bytes[i + 2];
        list[3] = bytes[i + 3];
        int number = list.buffer.asByteData().getInt32(0);
        comicIds.add(number);
      }
      var range = res.headers["content-range"]?? res.headers["Content-Range"];
      int i = 0;
      for(;i<range!.length;i++){
        if(range[i] == '/') break;
      }
      return Res(comicIds, subData: range.sublist(i));
    }
    catch(e){
      return Res(null, errorMessage: e.toString()=="null" ? "未知错误" : e.toString());
    }
  }

  ///基本的get请求
  Future<Res<String>> get(String url) async{
    try{
      var dio = Dio();
      dio.options.headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",

      };
      var res = await dio.get(url);
      saveDebugData(res.data);
      return Res(res.data.toString());
    }
    catch(e){
      return Res(null, errorMessage: e.toString()=="null"?"未知错误":e.toString());
    }
  }

  ///从一个漫画列表中获取所有的漫画
  Future<Res<ComicList>> getComics(String url) async{
    var comicList = ComicList(url);
    var res = await loadNextPage(comicList);
    if(res.error){
      return Res(null, errorMessage: res.errorMessage!);
    }else{
      return Res(comicList);
    }
  }

  Future<Res<bool>> loadNextPage(ComicList comicList) async{
    if(comicList.toLoad >= comicList.total) return Res(false);
    var comicIds = await fetchComicData(comicList.url, comicList.toLoad);
    if(comicIds.error){
      return Res(false, errorMessage: comicIds.errorMessage!);
    }
    int loadingItem = 0;
    for(var id in comicIds.data){
      if(loadingItem > 5){
        //同时加载过多会导致卡顿
        await Future.delayed(const Duration(milliseconds: 500));
      }
      loadingItem++;
      getComicInfoBrief(id.toString()).then((comic){
        if(! comic.error){
          comicList.comics.add(comic.data);
          loadingItem--;
        }else{
          //不管了
          loadingItem--;
        }
      });
    }
    //设置一个计时器, 限制等待时间, 避免一些特殊情况导致卡住
    int timer = 0;
    while(loadingItem != 0){
      timer++;
      await Future.delayed(const Duration(milliseconds: 500));
      if(timer > 17){
        return Res(null, errorMessage: "请求超时");
      }
    }
    comicList.toLoad += 100;
    return Res(true);
  }

  ///获取一个漫画的简略信息
  Future<Res<HitomiComicBrief>> getComicInfoBrief(String id) async{
    var res = await get("https://ltn.hitomi.la/galleryblock/$id.html");
    if(res.error){
      return Res(null, errorMessage: res.errorMessage!);
    }
    try{
      var comicDiv = parse(res.data);
      var name = comicDiv.querySelector("h1.lillie > a")!.text;
      var link = comicDiv.querySelector("h1.lillie > a")!.attributes["href"]!;
      link = baseUrl + link;
      var artist = comicDiv.querySelector("div.artist-list")!.text;
      var cover = comicDiv.querySelector("div.dj-img1 > picture > source")!.attributes["data-srcset"]!;
      cover = cover.substring(2);
      cover = "https://a$cover";
      cover = cover.replaceAll(RegExp(r"2x.*"), "");
      cover = cover.removeAllWhitespace;
      var table = comicDiv.querySelectorAll("table.dj-desc > tbody");
      String type = "", lang = "";
      var tags = <Tag>[];
      for (var tr in table) {
        if (tr.firstChild!.text == "Type") {
          type = tr.children[1].text;
        } else if (tr.firstChild!.text == "Language") {
          lang = tr.children[1].text;
        } else if (tr.firstChild!.text == "Tags") {
          for (var liA in tr.querySelectorAll("td.relatedtags > ul > li > a")) {
            tags.add(Tag(liA.text, liA.attributes["href"]!));
          }
        }
      }
      var time = comicDiv.querySelector("div.dj-content > p")!.text;
      return Res(HitomiComicBrief(name, type, lang, tags, time, artist, link, cover));
    }
    catch(e){
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }
}

class HitomiDataUrls{
  static String homePageAll = 'https://ltn.hitomi.la/index-all.nozomi';
  static String homePageCn = "https://ltn.hitomi.la/index-chinese.nozomi";
  static String homePageJp = "https://ltn.hitomi.la/index-japanese.nozomi";
}