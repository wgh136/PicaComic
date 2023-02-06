import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert' as convert;
import 'package:pica_comic/network/headers.dart';
import 'models.dart';

const defaultAvatarUrl = "https://cdn-icons-png.flaticon.com/512/1946/1946429.png";

class Network{
  final String apiUrl = "https://picaapi.picacomic.com";
  InitData? initData;
  String token;
  Network([this.token=""]);
  final dio = Dio()
    ..interceptors.add(LogInterceptor())
    ..httpClientAdapter = Http2Adapter(
        ConnectionManager(
          idleTimeout: 10000,
          // Ignore bad certificate
          onClientCreate: (_, config) => config.onBadCertificate = (_) => true,
        ),)
  ;

  Future<Map<String, dynamic>?> get(String url) async{
    dio.options = getHeaders("get", token, url.replaceAll("$apiUrl/", ""));
    //从url获取json
    if (kDebugMode) {
      print('Try to get response from $url');
    }
    try{
      var res = await dio.get(url);
      if(res.statusCode == 200){
        if (kDebugMode) {
          print('Get response successfully');
          print(res);
        }
        var jsonResponse = convert.jsonDecode(res.toString()) as Map<String, dynamic>;
        return jsonResponse;
      }
      else{
        return null;
      }
    }
    catch(e){
      return null;
    }
  }

  Future<Map<String, dynamic>?> post(String url,Map<String,String> data) async{
    dio.options = getHeaders("post", token, url.replaceAll("$apiUrl/", ""));
    //从url获取json
    if (kDebugMode) {
      print('Try to get response from $url');
    }
    try{
      var res = await dio.post(url,data:data);
      if (kDebugMode) {
        print(res);
      }
      if(res.statusCode == 200){
        if (kDebugMode) {
          print('Get response successfully');
        }
        var jsonResponse = convert.jsonDecode(res.toString()) as Map<String, dynamic>;
        return jsonResponse;
      }
      else{
        return null;
      }
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
      return null;
    }
  }

  Future<bool> login(String email, String password) async {
    //登录
    var res = await post('$apiUrl/auth/sign-in',{
      "email":email,
      "password":password,
    });
    if(res!=null){
      if(res["message"]=="success"){
        token = res["data"]["token"];
        dio.options.headers["authorization"] = token;
        if(kDebugMode){
          print("Logging successfully");
        }
        return true;
      }else{
        return false;
      }
    }else{
      return false;
    }
  }

  Future<Profile?> getProfile() async {
    //获取用户信息
    var res = await get("$apiUrl/users/profile");
    if(res != null){
      res = res["data"]["user"];
      String url = "";
      if(res!["avatar"]==null){
        url = defaultAvatarUrl;
      }else{
        url = res["avatar"]["fileServer"] + "/static/" + res["avatar"]["path"];
      }
      var p = Profile(res["_id"], url, res["email"], res["exp"], res["level"], res["name"], res["title"]);
      return p;
    }else{
      return null;
    }
  }

  Future<KeyWords?> getKeyWords() async{
    //获取热搜词
    var res = await get("$apiUrl/keywords");
    if(res != null){
      var k = KeyWords();
      for(int i=0;i<res["data"]["keywords"].length;i++){
        k.keyWords.add(res["data"]["keywords"][i]);
      }
      return k;
    }else{
      return null;
    }
  }

  Future<List<CategoryItem>?> getCategories() async{
    //获取分类
    var res = await get("$apiUrl/categories");
    if(res!=null){
      var c = <CategoryItem>[];
      for(int i=0;i<res["data"]["categories"].length;i++){
        String url = res["data"]["categories"][i]["thumb"]["fileServer"];
        if(url[url.length-1]!='/'){
          url = '$url/static/';
        }
        url = url + res["data"]["categories"][i]["thumb"]["path"];
        var ca = CategoryItem(res["data"]["categories"][i]["title"], url);
        c.add(ca);
      }
      return c;
    }else{
      return null;
    }
  }

  Future<bool> init() async {
    //获取基本信息:imageServer,fileServer(已测试)
    var res = await get("$apiUrl/init?platform=android");
    if(res != null){
      var id = InitData(res["data"]["imageServer"], res["data"]["latestApplication"]["apk"]["fileServer"]);
      initData = id;
      return true;
    }else{
      return false;
    }
  }

  Future<void> loadMoreSearch(SearchResult s) async{
    if(s.loaded!=s.pages){
      var res  = await post('$apiUrl/comics/advanced-search?page=${s.loaded+1}',{"keyword": s.keyWord,"sort":s.sort});
      if(res!=null) {
        s.loaded++;
        s.pages = res["data"]["comics"]["pages"];
        for (int i = 0; i < res["data"]["comics"]["docs"].length; i++) {
          var si = ComicItemBrief(res["data"]["comics"]["docs"][i]["title"],
              res["data"]["comics"]["docs"][i]["author"],
              res["data"]["comics"]["docs"][i]["likesCount"],
              res["data"]["comics"]["docs"][i]["thumb"]["fileServer"] + "/static/" +
                  res["data"]["comics"]["docs"][i]["thumb"]["path"],
              res["data"]["comics"]["docs"][i]["_id"]
          );
          s.comics.add(si);
        }
      }
    }
  }

  Future<SearchResult> searchNew(String keyWord,String sort) async{
    /*
    sort:
        dd: 新到书
        da: 旧到新
        ld: 最多喜欢
        vd: 最多绅士指名
     */
    var s = SearchResult(keyWord, sort, [], 1, 0);
    await loadMoreSearch(s);
    return s;
  }

  Future<ComicItem?> getComicInfo(String id) async {
    //获取漫画信息
    var res = await get("$apiUrl/comics/$id");
    if(res != null){
      String url;
      if(res["data"]["comic"]["_creator"]["avatar"]==null){
        url = defaultAvatarUrl;
      }else{
        url = res["data"]["comic"]["_creator"]["avatar"]["fileServer"]+"/static/"+res["data"]["comic"]["_creator"]["avatar"]["path"];
      }
      var creator = Profile(
          res["data"]["comic"]["_id"],
          url,
          "",
          res["data"]["comic"]["_creator"]["exp"],
          res["data"]["comic"]["_creator"]["level"],
          res["data"]["comic"]["_creator"]["name"],
          res["data"]["comic"]["_creator"]["title"]
      );
      var categories = <String>[];
      for(int i=0;i<res["data"]["comic"]["categories"].length;i++){
        categories.add(res["data"]["comic"]["categories"][i]);
      }
      var tags = <String>[];
      for(int i=0;i<res["data"]["comic"]["tags"].length;i++){
        tags.add(res["data"]["comic"]["tags"][i]);
      }
      var ci = ComicItem(
          creator,
          res["data"]["comic"]["title"]??"未知",
          res["data"]["comic"]["description"]??"无",
          res["data"]["comic"]["thumb"]["fileServer"]+"/static/"+res["data"]["comic"]["thumb"]["path"]??"",
          res["data"]["comic"]["author"]??"未知",
          res["data"]["comic"]["chineseTeam"]??"未知",
          categories,
          tags,
          res["data"]["comic"]["likesCount"]??0,
          res["data"]["comic"]["commentsCount"]??0,
          res["data"]["comic"]["isFavourite"]??false,
          res["data"]["comic"]["isLiked"]??false,
          res["data"]["comic"]["epsCount"]??0,
        id
      );
      return ci;
    }else{
      return null;
    }
  }

  Future<List<String>> getEps(String id) async{
    //获取漫画章节信息
    var eps = <String>[];
    int i=0;
    bool flag = true;
    while(flag){
      i++;
      var res = await get("$apiUrl/comics/$id/eps?page=$i");
      if(res == null){
        return eps;
      }else if(res["data"]["eps"]["pages"]==i){
        flag = false;
      }
      for(int j=0;j<res["data"]["eps"]["docs"].length;j++){
        eps.add(res["data"]["eps"]["docs"][j]["title"]);
      }
    }
    eps.add("");
    return eps.reversed.toList();
  }

  Future<List<String>> getComicContent(String id, int order) async{
    //获取漫画内容
    var imageUrls = <String>[];
    int i=0;
    bool flag = true;
    while(flag){
      i++;
      var res = await get("$apiUrl/comics/$id/order/$order/pages?page=$i");
      if(res == null){
        return imageUrls;
      }else if(res["data"]["pages"]["pages"]==i){
        flag = false;
      }
      for(int j=0;j<res["data"]["pages"]["docs"].length;j++){
        imageUrls.add(res["data"]["pages"]["docs"][j]["media"]["fileServer"]+"/static/"+res["data"]["pages"]["docs"][j]["media"]["path"]);
      }
    }
    return imageUrls;
  }

  Future<void> loadMoreCommends(Commends c) async{
    if(c.loaded != c.pages){
      var res = await get("$apiUrl/comics/${c.id}/comments?page=${c.loaded+1}");
      if(res!=null){
        c.pages = res["data"]["comments"]["pages"];
        for(int i=0;i<res["data"]["comments"]["docs"].length;i++){
          String url = "";
          if(res["data"]["comments"]["docs"][i]["_user"]["avatar"] != null){
            url = res["data"]["comments"]["docs"][i]["_user"]["avatar"]["fileServer"]+"/static/"+res["data"]["comments"]["docs"][i]["_user"]["avatar"]["path"];
          }else{
            //没有头像时, 将其替换为person图标
            url = defaultAvatarUrl;
          }
          var t = Commend(
              res["data"]["comments"]["docs"][i]["_user"]["name"],
              url,
              res["data"]["comments"]["docs"][i]["_user"]["_id"],
              res["data"]["comments"]["docs"][i]["_user"]["level"],
              res["data"]["comments"]["docs"][i]["content"]
          );
          c.commends.add(t);
        }
        c.loaded++;
      }
    }
  }

  Future<Commends> getCommends(String id) async{
    var t = Commends([], id, 1, 0);
    await loadMoreCommends(t);
    return t;
  }

  Future<void> loadMoreFavorites(Favorites f) async{
    if(f.loaded!=f.pages){
      var res = await get("$apiUrl/users/favourite?s=dd&page=${f.loaded+1}");
      if(res != null) {
        f.loaded++;
        f.pages = res["data"]["comics"]["pages"];
        for (int i = 0; i < res["data"]["comics"]["docs"].length; i++) {
          var si = ComicItemBrief(res["data"]["comics"]["docs"][i]["title"],
              res["data"]["comics"]["docs"][i]["author"],
              res["data"]["comics"]["docs"][i]["likesCount"],
              res["data"]["comics"]["docs"][i]["thumb"]["fileServer"] + "/static/" +
                  res["data"]["comics"]["docs"][i]["thumb"]["path"],
              res["data"]["comics"]["docs"][i]["_id"]
          );
          f.comics.add(si);
        }
      }
    }
  }

  Future<Favorites> getFavorites() async{
    var f = Favorites([], 1, 0);
    await loadMoreFavorites(f);
    return f;
  }

  Future<List<ComicItemBrief>> getRandomComics() async {
    var comics = <ComicItemBrief>[];
    var res = await get("$apiUrl/comics/random");
    if (res != null) {
      for (int i = 0; i < res["data"]["comics"].length; i++) {
        try {
          var si = ComicItemBrief(
              res["data"]["comics"][i]["title"],
              res["data"]["comics"][i]["author"],
              res["data"]["comics"][i]["totalLikes"],
              res["data"]["comics"][i]["thumb"]["fileServer"] + "/static/" +
                  res["data"]["comics"][i]["thumb"]["path"],
              res["data"]["comics"][i]["_id"]
          );
          comics.add(si);
        }
        catch (e) {//出现错误跳过}
        }
      }
    }
    return comics;
  }

  Future<bool> likeOrUnlikeComic(String id) async{
    var res = await post('$apiUrl/comics/$id/like',{});
    if(res != null){
      return true;
    }else{
      return false;
    }
  }

  Future<bool> favouriteOrUnfavoriteComic(String id) async {
    var res = await post('$apiUrl/comics/$id/favourite',{});
    if(res != null){
      return true;
    }else{
      return false;
    }
  }

  Future<List<ComicItemBrief>> getLeaderboard(String time) async{
    /*
    Time:
      H24 过去24小时
      D7 过去7天
      D30 过去30天
     */
    var res = await get("$apiUrl/comics/leaderboard?tt=$time&ct=VC");
    var comics = <ComicItemBrief>[];
    if(res!=null){
      for (int i = 0; i < res["data"]["comics"].length; i++) {
        try {
          var si = ComicItemBrief(
              res["data"]["comics"][i]["title"],
              res["data"]["comics"][i]["author"],
              res["data"]["comics"][i]["totalLikes"],
              res["data"]["comics"][i]["thumb"]["fileServer"] + "/static/" +
                  res["data"]["comics"][i]["thumb"]["path"],
              res["data"]["comics"][i]["_id"]
          );
          comics.add(si);
        }
        catch (e) {//出现错误跳过}
        }
      }
    }
    return comics;
  }
}