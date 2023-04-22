import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
  show kDebugMode;
import 'package:pica_comic/jm_network/headers.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/jm_network/res.dart';
import 'package:pica_comic/tools/debug.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pointycastle/export.dart';
import 'package:get/get.dart';

class JmNetwork{
  final baseUrl = "https://www.jmapinode.cc";
  final baseData = "key=0b931a6f4b5ccc3f8d870839d07ae7b2&view_mode_debug=1&view_mode=null";

  var hotTags = <String>[];

  ///解密数据
  String _convertData(String input, int time){
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
    int i = res.length-1;
    for(;i>=0;i--){
      if(res[i]=='}'||res[i]==']'){
        break;
      }
    }
    return res.substring(0,i+1);
  }

  ///get请求, 返回Json数据中的data
  Future<Res<dynamic>> get(String url, {Map<String, String>? header}) async{
    try {
      int time = DateTime
          .now()
          .millisecondsSinceEpoch ~/ 1000;
      var dio = Dio(getHeader(time))
        ..interceptors.add(LogInterceptor());
      var res = await dio.get(url);
      var data = _convertData(
          (const JsonDecoder().convert(const Utf8Decoder().convert(res.data)))["data"], time);
      if(kDebugMode) {
        saveDebugData(data);
      }
      return Res<dynamic>(const JsonDecoder().convert(data));
    }
    on DioError catch(e){
      if (kDebugMode) {
        print(e);
      }
      if(e.type!=DioErrorType.unknown){
        return Res<String>(null,errorMessage: e.message??"网络错误");
      }
      return Res<String>(null,errorMessage: "网络错误");
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return Res<String>(null,errorMessage: "网络错误");
    }
  }

  ///获取主页
  Future<Res<HomePageData>> getHomePage() async{
    var res = await get("$baseUrl/promote?$baseData&page=0");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }

      var data = HomePageData([]);
      for(var item in res.data){
        var comics = <JmComicBrief>[];
        for(var comic in item["content"]){
          var categories = <ComicCategoryInfo>[];
          if(comic["category"]["id"] != null && comic["category"]["title"] != null){
            categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
          }
          if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
            categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
          }
          comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
        }
        data.items.add(HomePageItem(item["title"], item["id"].toString(), comics));
      }
      return Res(data);

  }

  Future<Res<PromoteList>> getPromoteList(String id) async{
    var res = await get("$baseUrl/promote_list?$baseData&id=$id&page=0");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }
    try{
      var list = PromoteList(id, []);
      list.total = int.parse(res.data["total"]);
      for(var comic in (res.data["list"])){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        list.comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
        list.loaded++;
      }
      list.page++;
      return Res(list);
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadMorePromoteListComics(PromoteList list) async{
    if(list.loaded >= list.total){
      return;
    }
    var res = await get("$baseUrl/promote_list?$baseData&id=${list.id}&page=${list.page}");
    if(res.error){
      return;
    }
    try{
      for(var comic in (res.data["list"])){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        list.comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
        list.loaded++;
      }
      list.page++;
      return;
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return;
    }
  }

  Future<Res<List<JmComicBrief>>> getLatest(int page) async{
    var res = await get("$baseUrl/latest?$baseData&page=$page");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }
    try{
      var comics = <JmComicBrief>[];
      for(var comic in (res.data)){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"], categories));
      }
      return Res(comics);
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  ///获取热搜词
  Future<void> getHotTags() async{
    var res = await get("$baseUrl/hot_tags?$baseData");
    if(res.error){
      for(var s in res.data){
        hotTags.add(s);
      }
    }
    try{
      Get.find<PreSearchController>().update();
    }
    catch(e){
      //处于搜索页面时更新页面, 否则忽视
    }
  }

  ///搜索
  Future<Res<SearchRes>> search(String keyword) async{
    var res = await get("$baseUrl/search?$baseData&search_query=${Uri.encodeComponent(keyword)}");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }
    try{
      var comics = <JmComicBrief>[];
      for(var comic in (res.data["content"])){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
      }
      return Res(
        SearchRes(keyword, comics.length, int.parse(res.data["total"]), comics),
      );
    }
    catch(e){
      return Res(null, errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadSearchNextPage(SearchRes search) async{
    var res = await get("$baseUrl/search?$baseData&search_query=${Uri.encodeComponent(search.keyword)}&page=${search.loadedPage+1}");
    if(res.error){
      return;
    }
    try{
      for(var comic in (res.data["content"])){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        search.comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
      }
      search.loaded = search.comics.length;
      search.loadedPage++;
    }
    catch(e){
      return;
    }
  }

  ///获取分类信息
  Future<Res<List<Category>>> getCategories() async{
    var res = await get("$baseUrl/categories?$baseData");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }
    try{
      var categories = <Category>[];
      for(var c in res.data["categories"]){
        var subCategories = <SubCategory>[];
        for(var sc in c["sub_categories"]??[]){
          subCategories.add(SubCategory(sc["CID"], sc["name"], sc["slug"]));
        }
        categories.add(Category(c["name"], c["slug"], subCategories));
      }
      return Res(categories);
    }
    catch(e){
      return Res(null,errorMessage: "解析失败: ${e.toString()}");
    }
  }

  ///获取分类漫画
  Future<Res<CategoryComicsRes>> getCategoryComics(String category, ComicsOrder order) async{
    /*
    排序:
      最新，总排行，月排行，周排行，日排行，最多图片, 最多爱心
      mr, mv, mv_m, mv_w, mv_t, mp, tf
     */
    var res = await get("$baseUrl/categories/filter?$baseData&o=$order&c=$category&page=1");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }
    try{
      var comics = <JmComicBrief>[];
      for(var comic in (res.data["content"])){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
      }
      return Res(CategoryComicsRes(category, order.toString(), comics.length, int.parse(res.data["total"]), 1, comics));
    }
    catch(e){
      return Res(null,errorMessage: "解析失败: ${e.toString()}");
    }
  }

  Future<void> getCategoriesComicNextPage(CategoryComicsRes comics) async{
    var res = await get("$baseUrl/categories/filter?$baseData&o=${comics.sort}&c=${comics.category}&page=${comics.loadedPage}");
    if(res.error){
      return;
    }
    try{
      for(var comic in (res.data["content"])){
        var categories = <ComicCategoryInfo>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(ComicCategoryInfo(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
      }
      comics.loadedPage++;
      comics.loaded = comics.comics.length;
    }
    catch(e){
      return;
    }
  }

  Future<Res<JmComicInfo>> getComicInfo(String id) async{
    var res = await get("$baseUrl/album?$baseData&id=$id");
    if(res.error){
      return Res(null,errorMessage: res.errorMessage);
    }
    try {
      var author = <String>[];
      for (var s in res.data["author"]) {
        author.add(s);
      }
      var series = <int, String>{};
      for (var s in res.data["series"]) {
        series[int.parse(s["sort"])] = s["id"];
      }
      var tags = <String>[];
      for (var s in res.data["tags"]) {
        tags.add(s);
      }
      var related = <JmComicBrief>[];
      for (var c in res.data["related_list"]) {
        related.add(JmComicBrief(c["id"], c["author"], c["name"], c["description"], []));
      }
      return Res(JmComicInfo(
          res.data["name"],
          res.data["id"].toString(),
          author,
          res.data["description"],
          int.parse(res.data["likes"]),
          int.parse(res.data["total_views"]),
          series,
          tags,
          related,
          res.data["liked"],
          res.data["is_favorite"]));
    }
    catch(e){
      return Res(null,errorMessage: "解析失败: ${e.toString()}");
    }
  }
}

enum ComicsOrder{
  latest("mr"),
  totalRanking("mv"),
  monthRanking("mv_m"),
  weekRanking("mv_w"),
  dayRanking("mv_t"),
  maxPictures("mp"),
  maxLikes("tf");

  @override
  String toString() => value;

  final String value;
  const ComicsOrder(this.value);
}