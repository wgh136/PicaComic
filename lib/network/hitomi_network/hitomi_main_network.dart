import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
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
  /// 发送请求时需要在请求头设置开始接收位置和最后接收位置,
  ///
  /// 获取主页时不需要传入end, 因为需要和js脚本保持一致, 设置获取宽度100, 避免出现问题
  ///
  /// 响应头中 Content-Range 指明数据范围, 此函数用subData形式返回此值
  Future<Res<List<int>>> fetchComicData(String url, int start, {int? maxLength, int? endData, String? ref}) async{
    try{
      var end = start + 100 - 1;
      if(endData != null){
        end = endData;
      }
      if(maxLength != null && maxLength < end){
        end = maxLength;
      }
      assert(start < end);
      var dio = Dio();
      dio.options.responseType = ResponseType.bytes;
      dio.options.headers = {
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
        "Range": "bytes=$start-$end",
        if(ref != null)
          "Referer": ref
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
      var range = (res.headers["content-range"]?? res.headers["Content-Range"])![0];
      int i = 0;
      for(;i<range.length;i++){
        if(range[i] == '/') break;
      }
      return Res(comicIds, subData: range.substring(i+1));
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
    var comicIds = await fetchComicData(comicList.url, comicList.toLoad, maxLength: comicList.total);
    if(comicIds.error){
      return Res(false, errorMessage: comicIds.errorMessage!);
    }
    comicList.total = int.parse(comicIds.subData);
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

  Future<void> search(String keyword) async{
    //首先需要获取版本号
    var version = await get("https://ltn.hitomi.la/galleriesindex/version?_=${DateTime.now().millisecondsSinceEpoch ~/ 1000}");
    if(version.error){
      //TODO
    }
    //然后进行搜索
    //TODO
    /*
    这东西比较复杂, 居然有一部分逻辑在本地段进行
    以下是chatgpt的解析:
      1. 解码查询字符串：通过decodeURIComponent()函数解码URL查询字符串，
        并使用正则表达式替换掉字符串开头的“?”，得到实际的查询字符串。
      2. 设置搜索框内容：将查询字符串设置为页面上的搜索框中的值。
      3. 拆分查询字符串： 使用正则表达式拆分查询字符串并生成一个搜索词数组。
         同时，准备两个空数组positive_terms和negative_terms来存储正向和负向搜索词。
      4. 遍历搜索词数组并将其分类： 对搜索词数组进行迭代，如果该词以“-”开头，
        则将其添加到negative_terms数组中。否则，则将其添加到positive_terms数组中。
      5. 执行搜索：使用Promise对象确保搜索的顺序性。
        首先，如果没有指定任何正向搜索词，则直接调用get_galleryids_from_nozomi()函数，
        否则调用get_galleryids_for_query()函数获取与第一个正向搜索词相关联的图库ID列表。
      6. 处理正向搜索：对于每个其他的正向搜索词，
        都调用get_galleryids_for_query()函数来获取与该词相关联的图库ID列表，
        并使用Promise.all()方法并行处理这些搜索词。
        对于每个结果集，我们使用Set()对象生成一个新的结果集，并将其与现有结果进行过滤。
      7. 处理负向搜索：对于每个负向搜索词，同样调用get_galleryids_for_query()函数，
        并使用Promise.all()方法并行处理所有负向搜索词。
        对于每个结果集，我们使用Set()对象生成一个新的结果集，再通过过滤操作将它们从现有结果集中删除。
      8. 处理最终结果：计算最终结果数并在页面上显示它们。
        如果结果为空，则隐藏加载条并显示“no-results-content”内容；否则，在页面上显示结果。

        get_galleryids_for_query()
        此函数期望传入一个查询字符串query，并返回一个Promise对象。在解析查询之前，它会先将下划线替换为空格。
      1. 如果查询字符串中包含冒号（:），则会根据冒号的位置对查询字符串进行分割。
        第一部分将作为命名空间（namespace），第二部分将作为标签（tag）。
        如果命名空间是female或male，则查询将在标签区域执行，而标记将保持不变。
        如果命名空间是language，则查询将在所有语言的索引中执行，而标记将被设置为“index”。
      2. 否则，该函数将使用哈希算法处理查询字符串，以获得散列键（key），
        并在指定字段（field）的节点（node）中搜索键值（key）。
        如果找到匹配项，则从数据中提取画廊ID（gallery ids）并将其返回。
      3.如果未能找到匹配项，则返回一个空数组。
        注意，此函数可能返回一个Promise对象，因此可能需要使用async/await或.then()语法来处理结果
     */
    var res = await fetchComicData(
        "https://ltn.hitomi.la/galleriesindex/galleries.${version.data}.data",
        85097004,
        endData: 85152907,
        ref: "https://hitomi.la/search.html?${Uri.encodeComponent(keyword)}"
    );
    print(res.data);
  }

  Future<void> getComicInfo(String id) async{
    await get("https://ltn.hitomi.la/galleries/$id.js");
    //返回一个js脚本, 图片url也在这里面
    //直接将前面的"var galleryinfo = "删掉, 然后作为json解析即可
    //TODO
  }
}

class HitomiDataUrls{
  static String homePageAll = 'https://ltn.hitomi.la/index-all.nozomi';
  static String homePageCn = "https://ltn.hitomi.la/index-chinese.nozomi";
  static String homePageJp = "https://ltn.hitomi.la/index-japanese.nozomi";
  static String todayPopular = "https://ltn.hitomi.la/popular/today-all.nozomi";
  static String weekPopular = "https://ltn.hitomi.la/popular/week-all.nozomi";
  static String monthPopular = "https://ltn.hitomi.la/popular/month-all.nozomi";
  static String yearPopular = "https://ltn.hitomi.la/popular/year-all.nozomi";
}