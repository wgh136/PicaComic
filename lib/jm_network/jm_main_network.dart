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
        return Res<String>(null,error: e.message??"未知错误");
      }
      return Res<String>(null,error: "未知错误");
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return Res<String>(null,error: "未知错误");
    }
  }

  ///获取主页
  Future<Res<HomePageData>> getHomePage() async{
    var res = await get("$baseUrl/promote?$baseData&page=0");
    if(res.error != null){
      return Res(null,error: res.error);
    }

      var data = HomePageData([]);
      for(var item in res.data){
        var comics = <JmComicBrief>[];
        for(var comic in item["content"]){
          var categories = <Category>[];
          if(comic["category"]["id"] != null && comic["category"]["title"] != null){
            categories.add(Category(comic["category"]["id"], comic["category"]["title"]));
          }
          if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
            categories.add(Category(comic["category_sub"]["id"], comic["category_sub"]["title"]));
          }
          comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
        }
        data.items.add(HomePageItem(item["title"], item["id"].toString(), comics));
      }
      return Res(data);

  }

  Future<Res<PromoteList>> getPromoteList(String id) async{
    var res = await get("$baseUrl/promote_list?$baseData&id=$id&page=0");
    if(res.error != null){
      return Res(null,error: res.error);
    }
    try{
      var list = PromoteList(id, []);
      list.total = int.parse(res.data["total"]);
      for(var comic in (res.data["list"])){
        var categories = <Category>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(Category(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(Category(comic["category_sub"]["id"], comic["category_sub"]["title"]));
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
      return Res(null, error: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadMorePromoteListComics(PromoteList list) async{
    if(list.loaded >= list.total){
      return;
    }
    var res = await get("$baseUrl/promote_list?$baseData&id=${list.id}&page=${list.page}");
    if(res.error != null){
      return;
    }
    try{
      for(var comic in (res.data["list"])){
        var categories = <Category>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(Category(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(Category(comic["category_sub"]["id"], comic["category_sub"]["title"]));
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
    if(res.error != null){
      return Res(null,error: res.error);
    }
    try{
      var comics = <JmComicBrief>[];
      for(var comic in (res.data)){
        var categories = <Category>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(Category(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(Category(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"], categories));
      }
      return Res(comics);
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return Res(null, error: "解析失败: ${e.toString()}");
    }
  }

  ///获取热搜词
  Future<void> getHotTags() async{
    var res = await get("$baseUrl/hot_tags?$baseData");
    if(res.error == null){
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

  Future<Res<SearchRes>> search(String keyword) async{
    var res = await get("$baseUrl/search?$baseData&search_query=${Uri.encodeComponent(keyword)}");
    if(res.error != null){
      return Res(null,error: res.error);
    }
    try{
      var comics = <JmComicBrief>[];
      for(var comic in (res.data["content"])){
        var categories = <Category>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(Category(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(Category(comic["category_sub"]["id"], comic["category_sub"]["title"]));
        }
        comics.add(JmComicBrief(comic["id"], comic["author"], comic["name"], comic["description"]??"", categories));
      }
      return Res(
        SearchRes(keyword, comics.length, int.parse(res.data["total"]), comics),
      );
    }
    catch(e){
      return Res(null, error: "解析失败: ${e.toString()}");
    }
  }

  Future<void> loadSearchNextPage(SearchRes search) async{
    var res = await get("$baseUrl/search?$baseData&search_query=${Uri.encodeComponent(search.keyword)}&page=${search.loadedPage+1}");
    if(res.error != null){
      return;
    }
    try{
      for(var comic in (res.data["content"])){
        var categories = <Category>[];
        if(comic["category"]["id"] != null && comic["category"]["title"] != null){
          categories.add(Category(comic["category"]["id"], comic["category"]["title"]));
        }
        if(comic["category_sub"]["id"] != null && comic["category_sub"]["title"] != null){
          categories.add(Category(comic["category_sub"]["id"], comic["category_sub"]["title"]));
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
}