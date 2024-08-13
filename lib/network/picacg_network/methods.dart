import 'package:dio/dio.dart';
import 'package:pica_comic/comic_source/built_in/picacg.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'dart:convert' as convert;
import 'package:pica_comic/network/picacg_network/headers.dart';
import 'package:pica_comic/network/http_client.dart';
import 'package:pica_comic/pages/pre_search_page.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../../foundation/log.dart';
import '../app_dio.dart';
import '../res.dart';
import 'models.dart';

export "models.dart";

const defaultAvatarUrl = "DEFAULT AVATAR URL";

///哔咔网络请求类
class PicacgNetwork {
  factory PicacgNetwork() =>
      cache ?? (cache = PicacgNetwork._create());

  static PicacgNetwork? cache;

  PicacgNetwork._create() {
    if(picacg.data['user'] != null) {
      try {
        user = Profile.fromJson(picacg.data['user']);
      } finally {}
    }
  }

  final String apiUrl = "https://picaapi.picacomic.com";

  String get token => picacg.data['token'];

  Profile? user;

  Future<Res<Map<String, dynamic>>> get(String url,
      {CacheExpiredTime expiredTime = CacheExpiredTime.short,
      bool log = true}) async {
    if (token == "") {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Res(null, errorMessage: "未登录");
    }
    await setNetworkProxy();
    var dio = CachedNetwork();
    var options = getHeaders("get", token, url.replaceAll("$apiUrl/", ""));
    options.validateStatus = (i) => i == 200 || i == 400 || i == 401;

    try {
      var res = await dio.get(url, options, expiredTime: expiredTime, log: log);
      if (res.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(res.data) as Map<String, dynamic>;
        return Res(jsonResponse);
      } else if (res.statusCode == 400) {
        var jsonResponse = convert.jsonDecode(res.data) as Map<String, dynamic>;
        return Res(null, errorMessage: jsonResponse["message"]);
      } else if (res.statusCode == 401) {
        var reLogin = await loginFromAppdata();
        if (reLogin.error) {
          return const Res(null, errorMessage: "登录失效且重新登录失败");
        } else {
          return get(url, expiredTime: expiredTime);
        }
      } else {
        return Res(null, errorMessage: "Invalid Status Code ${res.statusCode}");
      }
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout) {
        message = "连接超时";
      } else if (e.type != DioExceptionType.unknown) {
        message = e.message!;
      } else {
        message = e.toString().split("\n")[1];
      }
      return Res(null, errorMessage: message);
    } catch (e, stack) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$stack");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<Map<String, dynamic>>> post(
      String url, Map<String, String>? data) async {
    var api = "https://picaapi.picacomic.com";
    if (token == "" &&
        url != '$api/auth/sign-in' &&
        url != "https://picaapi.picacomic.com/auth/register") {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Res(null, errorMessage: "未登录");
    }
    var dio = logDio();
    dio.options = getHeaders("post", token, url.replaceAll("$apiUrl/", ""));
    try {
      await setNetworkProxy();
      var res = await dio.post<String>(url,
          data: data,
          options: Options(
              responseType: ResponseType.plain,
              validateStatus: (i) {
                return i == 200 || i == 400 || i == 401;
              }));

      if (res.data == null) {
        throw Exception("Empty data");
      }

      if (res.statusCode == 200) {
        var jsonResponse =
            convert.jsonDecode(res.data!) as Map<String, dynamic>;
        return Res(jsonResponse);
      } else if (res.statusCode == 400) {
        var jsonResponse =
            convert.jsonDecode(res.data!) as Map<String, dynamic>;
        return Res(null, errorMessage: jsonResponse["message"]);
      } else if (res.statusCode == 401) {
        var reLogin = await loginFromAppdata();
        if (reLogin.error) {
          return const Res(null, errorMessage: "登录失效且重新登录失败");
        } else {
          return post(url, data);
        }
      } else {
        return Res(null, errorMessage: "Invalid Status Code ${res.statusCode}");
      }
    } on DioException catch (e) {
      String message;
      if (e.type == DioExceptionType.connectionTimeout) {
        message = "连接超时";
      } else if (e.type != DioExceptionType.unknown) {
        message = e.message!;
      } else {
        message = e.toString().split("\n")[1];
      }
      return Res(null, errorMessage: message);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///登录, 返回token
  Future<Res<String>> login(String email, String password) async {
    var api = "https://picaapi.picacomic.com";
    var response = await post('$api/auth/sign-in', {
      "email": email,
      "password": password,
    });
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    if (res["message"] == "success") {
      try {
        return Res(res["data"]["token"]);
      } catch (e) {
        return const Res(null, errorMessage: "Failed to get token");
      }
    } else {
      return Res(null, errorMessage: res["message"]);
    }
  }

  Future<Res<bool>> loginFromAppdata() async {
    var res = await picacg.reLogin();
    if(res) {
      return const Res(true);
    } else {
      return const Res.error("Failed to re-login");
    }
  }

  ///获取用户信息
  Future<Res<Profile>> getProfile([bool log = true]) async {
    var response = await get("$apiUrl/users/profile",
        expiredTime: CacheExpiredTime.no, log: log);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    res = res["data"]["user"];
    String url = "";
    if (res["avatar"] == null) {
      url = defaultAvatarUrl;
    } else {
      url = res["avatar"]["fileServer"] + "/static/" + res["avatar"]["path"];
    }
    var p = Profile(
        res["_id"],
        url,
        res["email"],
        res["exp"],
        res["level"],
        res["name"],
        res["title"],
        res["isPunched"],
        res["slogan"],
        res["character"]);
    return Res(p);
  }

  Future<Res<bool>> updateProfile() async {
    if (token == "") {
      return const Res(true);
    }
    var res = await getProfile();
    if (res.error) {
      return Res.fromErrorRes(res);
    }
    user = res.data;
    picacg.data['user'] = user!.toJson();
    picacg.saveData();
    return const Res(true);
  }

  Future<Res<List<String>>> getHotTags() async {
    var response =
        await get("$apiUrl/keywords", expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessageWithoutNull);
    }
    var res = response.data;
    var k = <String>[];
    for (int i = 0; i < (res["data"]["keywords"] ?? []).length; i++) {
      k.add(res["data"]["keywords"][i]);
    }
    return Res(k);
  }

  ///获取分类
  Future<Res<List<CategoryItem>>> getCategories() async {
    var response =
        await get("$apiUrl/categories", expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    try {
      var c = <CategoryItem>[];
      for (int i = 0; i < res["data"]["categories"].length; i++) {
        if (res["data"]["categories"][i]["isWeb"] == true) continue;
        String url = res["data"]["categories"][i]["thumb"]["fileServer"];
        if (url[url.length - 1] != '/') {
          url = '$url/static/';
        }
        url = url + res["data"]["categories"][i]["thumb"]["path"];
        var ca = CategoryItem(res["data"]["categories"][i]["title"], url);
        c.add(ca);
      }
      return Res(c);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取分流ip
  ///
  /// 已被废弃, 要在Flutter中使用IP访问只有两种方式, 直接http连接或者忽略证书校验
  ///
  /// 由于存在安全问题, 因此放弃
  Future<String?> init() async {
    try {
      var dio = Dio();
      var res = await dio.get("http://68.183.234.72/init");
      var jsonResponse =
          convert.jsonDecode(res.toString()) as Map<String, dynamic>;
      return jsonResponse["addresses"][0];
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return null;
    }
  }

  ///搜索
  Future<Res<List<ComicItemBrief>>> search(
      String keyWord, String sort, int page,
      {bool addToHistory = false}) async {
    var response = await post('$apiUrl/comics/advanced-search?page=$page',
        {"keyword": keyWord, "sort": sort});
    if (page == 1 && addToHistory && keyWord != "") {
      appdata.searchHistory.remove(keyWord);
      appdata.searchHistory.add(keyWord);
      appdata.writeHistory();
    }
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    try {
      var pages = res["data"]["comics"]["pages"];
      var comics = <ComicItemBrief>[];
      for (int i = 0; i < res["data"]["comics"]["docs"].length; i++) {
        try {
          var tags = <String>[];
          tags.addAll(List<String>.from(
              res["data"]["comics"]["docs"][i]["tags"] ?? []));
          tags.addAll(List<String>.from(
              res["data"]["comics"]["docs"][i]["categories"] ?? []));
          var si = ComicItemBrief(
              res["data"]["comics"]["docs"][i]["title"] ?? "Unknown",
              res["data"]["comics"]["docs"][i]["author"] ?? "Unknown",
              int.parse(
                  res["data"]["comics"]["docs"][i]["likesCount"].toString()),
              res["data"]["comics"]["docs"][i]["thumb"]["fileServer"] +
                  "/static/" +
                  res["data"]["comics"]["docs"][i]["thumb"]["path"],
              res["data"]["comics"]["docs"][i]["_id"],
              tags,
              pages: res["data"]["comics"]["docs"][i]["pagesCount"]);
          comics.add(si);
        } catch (e) {
          continue;
        }
      }
      if (addToHistory) {
        Future.delayed(const Duration(microseconds: 500), () {
          try {
            StateController.find<PreSearchController>().update();
          } catch (e) {
            //忽视
          }
        });
      }
      return Res(comics, subData: pages);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取漫画信息
  Future<Res<ComicItem>> getComicInfo(String id) async {
    var response =
        await get("$apiUrl/comics/$id", expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    var epsRes = await getEps(id);
    if (epsRes.error) {
      return Res(null, errorMessage: epsRes.errorMessage);
    }
    var recommendationRes = await getRecommendation(id);
    if (recommendationRes.error) {
      recommendationRes = const Res([]);
    }
    try {
      String url;
      if (res["data"]["comic"]["_creator"]["avatar"] == null) {
        url = defaultAvatarUrl;
      } else {
        url = res["data"]["comic"]["_creator"]["avatar"]["fileServer"] +
            "/static/" +
            res["data"]["comic"]["_creator"]["avatar"]["path"];
      }
      var creator = Profile(
          res["data"]["comic"]["_id"],
          url,
          "",
          res["data"]["comic"]["_creator"]["exp"],
          res["data"]["comic"]["_creator"]["level"],
          res["data"]["comic"]["_creator"]["name"],
          res["data"]["comic"]["_creator"]["title"] ?? "Unknown",
          null,
          res["data"]["comic"]["_creator"]["slogan"] ?? "无",
          null);
      var categories = <String>[];
      for (int i = 0; i < res["data"]["comic"]["categories"].length; i++) {
        categories.add(res["data"]["comic"]["categories"][i]);
      }
      var tags = <String>[];
      for (int i = 0; i < res["data"]["comic"]["tags"].length; i++) {
        tags.add(res["data"]["comic"]["tags"][i]);
      }
      var ci = ComicItem(
          creator,
          res["data"]["comic"]["title"] ?? "Unknown",
          res["data"]["comic"]["description"] ?? "无",
          res["data"]["comic"]["thumb"]["fileServer"] +
                  "/static/" +
                  res["data"]["comic"]["thumb"]["path"] ??
              "",
          res["data"]["comic"]["author"] ?? "Unknown",
          res["data"]["comic"]["chineseTeam"] ?? "Unknown",
          categories,
          tags,
          res["data"]["comic"]["likesCount"] ?? 0,
          res["data"]["comic"]["commentsCount"] ?? 0,
          res["data"]["comic"]["isFavourite"] ?? false,
          res["data"]["comic"]["isLiked"] ?? false,
          res["data"]["comic"]["epsCount"] ?? 0,
          id,
          res["data"]["comic"]["pagesCount"],
          res["data"]["comic"]["updated_at"],
          epsRes.data,
          recommendationRes.data);
      return Res(ci);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///获取漫画的章节信息
  Future<Res<List<String>>> getEps(String id) async {
    var eps = <String>[];
    int i = 0;
    bool flag = true;
    try {
      while (flag) {
        i++;
        var res = await get("$apiUrl/comics/$id/eps?page=$i",
            expiredTime: CacheExpiredTime.no);
        if (res.error) {
          return Res(null, errorMessage: res.errorMessage);
        } else if (res.data["data"]["eps"]["pages"] == i) {
          flag = false;
        }
        for (int j = 0; j < res.data["data"]["eps"]["docs"].length; j++) {
          eps.add(res.data["data"]["eps"]["docs"][j]["title"]);
        }
      }
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analyse", "$s\n$s");
      return Res(null, errorMessage: e.toString());
    }
    return Res(eps.reversed.toList());
  }

  /// 获取漫画章节的图片链接
  Future<Res<List<String>>> getComicContent(String id, int order) async {
    var imageUrls = <String>[];
    int i = 0;
    bool flag = true;
    while (flag) {
      i++;
      var res = await get("$apiUrl/comics/$id/order/$order/pages?page=$i",
          expiredTime: CacheExpiredTime.no);
      if (res.error) {
        return Res(null, errorMessage: res.errorMessage);
      } else if (res.data["data"]["pages"]["pages"] == i) {
        flag = false;
      }
      for (int j = 0; j < res.data["data"]["pages"]["docs"].length; j++) {
        imageUrls.add(res.data["data"]["pages"]["docs"][j]["media"]
                ["fileServer"] +
            "/static/" +
            res.data["data"]["pages"]["docs"][j]["media"]["path"]);
      }
    }
    return Res(imageUrls);
  }

  Future<Res<bool>> loadMoreCommends(Comments c,
      {String type = "comics"}) async {
    if (c.loaded != c.pages) {
      var response = await get(
          "$apiUrl/$type/${c.id}/comments?page=${c.loaded + 1}",
          expiredTime: CacheExpiredTime.no);
      if (response.error) {
        return Res(null, errorMessage: response.errorMessage);
      }
      var res = response.data;
      c.pages = res["data"]["comments"]["pages"];
      for (int i = 0; i < res["data"]["comments"]["docs"].length; i++) {
        String url = "";
        try {
          url = res["data"]["comments"]["docs"][i]["_user"]["avatar"]
                  ["fileServer"] +
              "/static/" +
              res["data"]["comments"]["docs"][i]["_user"]["avatar"]["path"];
        } catch (e) {
          url = defaultAvatarUrl;
        }
        var t = Comment("", "", "", 1, "", 0, "", false, 0, null, null, "");
        if (res["data"]["comments"]["docs"][i]["_user"] != null) {
          t = Comment(
              res["data"]["comments"]["docs"][i]["_user"]["name"],
              url,
              res["data"]["comments"]["docs"][i]["_user"]["_id"],
              res["data"]["comments"]["docs"][i]["_user"]["level"],
              res["data"]["comments"]["docs"][i]["content"],
              res["data"]["comments"]["docs"][i]["commentsCount"],
              res["data"]["comments"]["docs"][i]["_id"],
              res["data"]["comments"]["docs"][i]["isLiked"],
              res["data"]["comments"]["docs"][i]["likesCount"],
              res["data"]["comments"]["docs"][i]["_user"]["character"],
              res["data"]["comments"]["docs"][i]["_user"]["slogan"],
              res["data"]["comments"]["docs"][i]["created_at"]);
        } else {
          t = Comment(
              "Unknown",
              url,
              "",
              1,
              res["data"]["comments"]["docs"][i]["content"],
              res["data"]["comments"]["docs"][i]["commentsCount"],
              res["data"]["comments"]["docs"][i]["_id"],
              res["data"]["comments"]["docs"][i]["isLiked"],
              res["data"]["comments"]["docs"][i]["likesCount"],
              null,
              null,
              res["data"]["comments"]["docs"][i]["created_at"]);
        }
        c.comments.add(t);
      }
      c.loaded++;
    }
    return const Res(true);
  }

  Future<Comments> getCommends(String id, {String type = "comics"}) async {
    var t = Comments([], id, 1, 0);
    await loadMoreCommends(t, type: type);
    return t;
  }

  /// 获取收藏夹
  Future<Res<List<ComicItemBrief>>> getFavorites(
      int page, bool newToOld) async {
    var response = await get(
        "$apiUrl/users/favourite?s=${newToOld ? "dd" : "da"}&page=$page",
        expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    try {
      var pages = res["data"]["comics"]["pages"];
      var comics = <ComicItemBrief>[];
      for (int i = 0; i < res["data"]["comics"]["docs"].length; i++) {
        var tags = <String>[];
        tags.addAll(
            List<String>.from(res["data"]["comics"]["docs"][i]["tags"] ?? []));
        tags.addAll(List<String>.from(
            res["data"]["comics"]["docs"][i]["categories"] ?? []));
        var si = ComicItemBrief(
            res["data"]["comics"]["docs"][i]["title"] ?? "Unknown",
            res["data"]["comics"]["docs"][i]["author"] ?? "Unknown",
            int.parse(
                res["data"]["comics"]["docs"][i]["likesCount"].toString()),
            res["data"]["comics"]["docs"][i]["thumb"]["fileServer"] +
                "/static/" +
                res["data"]["comics"]["docs"][i]["thumb"]["path"],
            res["data"]["comics"]["docs"][i]["_id"],
            tags,
            ignoreExamination: true,
            pages: res["data"]["comics"]["docs"][i]["pagesCount"]);
        comics.add(si);
      }
      return Res(comics, subData: pages);
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  Future<Res<List<ComicItemBrief>>> getRandomComics() async {
    var comics = <ComicItemBrief>[];
    var response =
        await get("$apiUrl/comics/random", expiredTime: CacheExpiredTime.no);
    if (response.success) {
      var res = response.data;
      for (int i = 0; i < res["data"]["comics"].length; i++) {
        try {
          var tags = <String>[];
          tags.addAll(
              List<String>.from(res["data"]["comics"][i]["tags"] ?? []));
          tags.addAll(
              List<String>.from(res["data"]["comics"][i]["categories"] ?? []));
          var si = ComicItemBrief(
              res["data"]["comics"][i]["title"] ?? "Unknown",
              res["data"]["comics"][i]["author"] ?? "Unknown",
              res["data"]["comics"][i]["totalLikes"] ?? 0,
              res["data"]["comics"][i]["thumb"]["fileServer"] +
                  "/static/" +
                  res["data"]["comics"][i]["thumb"]["path"],
              res["data"]["comics"][i]["_id"],
              tags,
              pages: res["data"]["comics"][i]["pagesCount"]);
          comics.add(si);
        } catch (e) {
          //出现错误跳过
        }
      }
    } else {
      return Res.fromErrorRes(response);
    }
    return Res(comics);
  }

  Future<bool> likeOrUnlikeComic(String id) async {
    var res = await post('$apiUrl/comics/$id/like', {});
    if (res.success) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> favouriteOrUnfavouriteComic(String id) async {
    var res = await post('$apiUrl/comics/$id/favourite', {});
    if (res.error) {
      return false;
    }
    return true;
  }

  /// 获取排行榜, 传入参数为时间
  /// - H24: 过去24小时
  /// - D7: 过去7天
  /// - D30: 过去30天
  Future<Res<List<ComicItemBrief>>> getLeaderboard(String time) async {
    var response = await get("$apiUrl/comics/leaderboard?tt=$time&ct=VC",
        expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    var comics = <ComicItemBrief>[];
    for (int i = 0; i < res["data"]["comics"].length; i++) {
      try {
        var tags = <String>[];
        tags.addAll(List<String>.from(res["data"]["comics"][i]["tags"] ?? []));
        tags.addAll(
            List<String>.from(res["data"]["comics"][i]["categories"] ?? []));
        var si = ComicItemBrief(
          res["data"]["comics"][i]["title"] ?? "Unknown",
          res["data"]["comics"][i]["author"] ?? "Unknown",
          res["data"]["comics"][i]["totalLikes"] ?? 0,
          res["data"]["comics"][i]["thumb"]["fileServer"] +
              "/static/" +
              res["data"]["comics"][i]["thumb"]["path"],
          res["data"]["comics"][i]["_id"],
          tags,
          pages: res["data"]["comics"][i]["pagesCount"],
        );
        comics.add(si);
      } catch (e) {
        //出现错误跳过
      }
    }
    return Res(comics, subData: 1);
  }

  Future<Res<String>> register(
      String ans1,
      String ans2,
      String ans3,
      String birthday,
      String account,
      String gender,
      String name,
      String password,
      String que1,
      String que2,
      String que3) async {
    //gender:m,f,bot
    var res = await post("https://picaapi.picacomic.com/auth/register", {
      "answer1": ans1,
      "answer2": ans2,
      "answer3": ans3,
      "birthday": birthday,
      "email": account,
      "gender": gender,
      "name": name,
      "password": password,
      "question1": que1,
      "question2": que2,
      "question3": que3
    });
    if (res.error) {
      return Res(null, errorMessage: res.errorMessageWithoutNull);
    } else if (res.data["message"] == "failure") {
      return const Res(null, errorMessage: "注册失败, 用户名或账号可能已存在");
    } else {
      return const Res("注册成功");
    }
  }

  ///打卡
  Future<bool> punchIn() async {
    var res = await post("$apiUrl/users/punch-in", null);
    if (res.success) {
      return true;
    } else {
      return false;
    }
  }

  /// 上传头像
  Future<bool> uploadAvatar(String imageData) async {
    //数据仍然是json, 只有一条"avatar"数据, 数据内容为base64编码的图像, 例如{"avatar":"[在这里放图像数据]"}
    var url = "$apiUrl/users/avatar";
    var dio = logDio();
    dio.options = getHeaders("put", token, url.replaceAll("$apiUrl/", ""));
    try {
      var res = await dio.put(url, data: {"avatar": imageData});
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changeSlogan(String slogan) async {
    var url = "$apiUrl/users/profile";
    var dio = logDio();
    dio.options = getHeaders("put", token, url.replaceAll("$apiUrl/", ""));
    try {
      var res = await dio.put(url, data: {"slogan": slogan});
      if (res.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> getMoreReply(Reply reply) async {
    if (reply.loaded == reply.total) return;
    var response = await get(
        "$apiUrl/comments/${reply.id}/childrens?page=${reply.loaded + 1}",
        expiredTime: CacheExpiredTime.no); //哔咔的英语水平有点烂
    if (response.success) {
      var res = response.data;
      reply.total = res["data"]["comments"]["pages"];
      for (int i = 0; i < res["data"]["comments"]["docs"].length; i++) {
        String url = "";
        try {
          url = res["data"]["comments"]["docs"][i]["_user"]["avatar"]
                  ["fileServer"] +
              "/static/" +
              res["data"]["comments"]["docs"][i]["_user"]["avatar"]["path"];
        } catch (e) {
          url = defaultAvatarUrl;
        }
        var t = Comment("", "", "", 1, "", 0, "", false, 0, null, null, "");
        if (res["data"]["comments"]["docs"][i]["_user"] != null) {
          t = Comment(
              res["data"]["comments"]["docs"][i]["_user"]["name"] ?? "Unknown",
              url,
              res["data"]["comments"]["docs"][i]["_user"]["_id"] ?? "",
              res["data"]["comments"]["docs"][i]["_user"]["level"] ?? 0,
              res["data"]["comments"]["docs"][i]["content"] ?? "",
              0,
              "",
              res["data"]["comments"]["docs"][i]["isLiked"],
              res["data"]["comments"]["docs"][i]["likesCount"] ?? 0,
              res["data"]["comments"]["docs"][i]["_user"]["character"],
              res["data"]["comments"]["docs"][i]["_user"]["slogan"] ?? "",
              res["data"]["comments"]["docs"][i]["created_at"]);
        } else {
          t = Comment(
              "Unknown",
              url,
              "",
              1,
              res["data"]["comments"]["docs"][i]["content"],
              0,
              "",
              res["data"]["comments"]["docs"][i]["isLiked"],
              res["data"]["comments"]["docs"][i]["likesCount"],
              null,
              null,
              res["data"]["comments"]["docs"][i]["created_at"]);
        }
        reply.comments.add(t);
      }
      reply.loaded++;
    }
  }

  Future<Reply> getReply(String id) async {
    var reply = Reply(id, 0, 1, []);
    await getMoreReply(reply);
    return reply;
  }

  Future<bool> likeOrUnlikeComment(String id) async {
    var res = await post("$apiUrl/comments/$id/like", {});
    return res.success;
  }

  Future<bool> comment(String id, String text, bool isReply,
      {String type = "comics"}) async {
    Res<Map<String, dynamic>?> res;
    if (!isReply) {
      res = await post("$apiUrl/$type/$id/comments", {"content": text});
    } else {
      res = await post("$apiUrl/comments/$id", {"content": text});
    }
    return res.success;
  }

  /// 获取相关推荐
  Future<Res<List<ComicItemBrief>>> getRecommendation(String id) async {
    var comics = <ComicItemBrief>[];
    var response = await get("$apiUrl/comics/$id/recommendation");
    if (response.success) {
      var res = response.data;
      for (int i = 0; i < res["data"]["comics"].length; i++) {
        try {
          var tags = <String>[];
          tags.addAll(
              List<String>.from(res["data"]["comics"][i]["tags"] ?? []));
          tags.addAll(
              List<String>.from(res["data"]["comics"][i]["categories"] ?? []));
          var si = ComicItemBrief(
              res["data"]["comics"][i]["title"] ?? "Unknown",
              res["data"]["comics"][i]["author"] ?? "Unknown",
              int.parse(res["data"]["comics"][i]["likesCount"].toString()),
              res["data"]["comics"][i]["thumb"]["fileServer"] +
                  "/static/" +
                  res["data"]["comics"][i]["thumb"]["path"],
              res["data"]["comics"][i]["_id"],
              tags,
              ignoreExamination: true);
          comics.add(si);
        } catch (e) {
          //出现错误跳过
        }
      }
    } else {
      return Res.fromErrorRes(response);
    }
    return Res(comics);
  }

  /// 获取本子母/本子妹推荐
  Future<Res<List<List<ComicItemBrief>>>> getCollection() async {
    var comics = <List<ComicItemBrief>>[[], []];
    var response =
        await get("$apiUrl/collections", expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    try {
      for (int i = 0; i < res["data"]["collections"][0]["comics"].length; i++) {
        try {
          var si = ComicItemBrief(
            res["data"]["collections"][0]["comics"][i]["title"] ?? "Unknown",
            res["data"]["collections"][0]["comics"][i]["author"] ?? "Unknown",
            res["data"]["collections"][0]["comics"][i]["totalLikes"] ?? 0,
            res["data"]["collections"][0]["comics"][i]["thumb"]["fileServer"] +
                "/static/" +
                res["data"]["collections"][0]["comics"][i]["thumb"]["path"],
            res["data"]["collections"][0]["comics"][i]["_id"],
            [],
            ignoreExamination: true,
            pages: res["data"]["collections"][0]["comics"][i]["pagesCount"],
          );
          comics[0].add(si);
        } catch (e) {
          //出现错误跳过
        }
      }
    } catch (e) {
      //跳过
    }
    try {
      for (int i = 0; i < res["data"]["collections"][1]["comics"].length; i++) {
        try {
          var si = ComicItemBrief(
            res["data"]["collections"][1]["comics"][i]["title"] ?? "Unknown",
            res["data"]["collections"][1]["comics"][i]["author"] ?? "Unknown",
            res["data"]["collections"][1]["comics"][i]["totalLikes"] ?? 0,
            res["data"]["collections"][1]["comics"][i]["thumb"]["fileServer"] +
                "/static/" +
                res["data"]["collections"][1]["comics"][i]["thumb"]["path"],
            res["data"]["collections"][1]["comics"][i]["_id"],
            [],
            ignoreExamination: true,
            pages: res["data"]["collections"][1]["comics"][i]["pagesCount"],
          );
          comics[1].add(si);
        } catch (e) {
          //出现错误跳过}
        }
      }
    } catch (e) {
      //跳过
    }
    return Res(comics);
  }

  Future<void> getMoreGames(Games games) async {
    if (games.total == games.loaded) return;
    var response = await get("$apiUrl/games?page=${games.loaded + 1}",
        expiredTime: CacheExpiredTime.no);
    if (response.success) {
      var res = response.data;
      games.total = res["data"]["games"]["pages"];
      for (int i = 0; i < res["data"]["games"]["docs"].length; i++) {
        var game = GameItemBrief(
            res["data"]["games"]["docs"][i]["_id"] ?? "",
            res["data"]["games"]["docs"][i]["title"] ?? "Unknown",
            res["data"]["games"]["docs"][i]["adult"],
            res["data"]["games"]["docs"][i]["icon"]["fileServer"] +
                "/static/" +
                res["data"]["games"]["docs"][i]["icon"]["path"],
            res["data"]["games"]["docs"][i]["publisher"] ?? "Unknown");
        games.games.add(game);
      }
    }
    games.loaded++;
  }

  Future<Games> getGames() async {
    var games = Games([], 0, 1);
    await getMoreGames(games);
    return games;
  }

  Future<Res<GameInfo>> getGameInfo(String id) async {
    var response = await get("$apiUrl/games/$id");
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    var gameInfo = GameInfo(
        id,
        res["data"]["game"]["title"] ?? "Unknown",
        res["data"]["game"]["description"],
        res["data"]["game"]["icon"]["fileServer"] +
            "/static/" +
            res["data"]["game"]["icon"]["path"],
        res["data"]["game"]["publisher"],
        [],
        res["data"]["game"]["androidLinks"][0],
        res["data"]["game"]["isLiked"],
        res["data"]["game"]["likesCount"],
        res["data"]["game"]["commentsCount"]);
    for (int i = 0; i < res["data"]["game"]["screenshots"].length; i++) {
      gameInfo.screenshots.add(res["data"]["game"]["screenshots"][i]
              ["fileServer"] +
          "/static/" +
          res["data"]["game"]["screenshots"][i]["path"]);
    }
    return Res(gameInfo);
  }

  Future<bool> likeGame(String id) async {
    var res = await post("$apiUrl/games/$id/like", {});
    return res.success;
  }

  Future<Res<bool>> changePassword(
      String oldPassword, String newPassword) async {
    var url = "$apiUrl/users/password";
    var dio = logDio();
    dio.options = getHeaders("put", token, url.replaceAll("$apiUrl/", ""));
    try {
      var res = await dio.put(url,
          data: {"new_password": newPassword, "old_password": oldPassword},
          options: Options(validateStatus: (i) => i == 200 || i == 400));
      if (res.statusCode == 200) {
        return const Res(true);
      } else {
        return const Res(false);
      }
    } on DioException catch (e) {
      return Res(null, errorMessage: e.toString());
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  /// 获取分类中的漫画
  Future<Res<List<ComicItemBrief>>> getCategoryComics(
      String keyWord, int page, String sort,
      [String type = "c"]) async {
    var response = await get(
        '$apiUrl/comics?page=$page&$type=${Uri.encodeComponent(keyWord)}&s=$sort',
        expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    var pages = res["data"]["comics"]["pages"];
    var comics = <ComicItemBrief>[];
    for (int i = 0; i < res["data"]["comics"]["docs"].length; i++) {
      try {
        var tags = <String>[];
        tags.addAll(
            List<String>.from(res["data"]["comics"]["docs"][i]["tags"] ?? []));
        tags.addAll(List<String>.from(
            res["data"]["comics"]["docs"][i]["categories"] ?? []));
        var si = ComicItemBrief(
          res["data"]["comics"]["docs"][i]["title"] ?? "Unknown",
          res["data"]["comics"]["docs"][i]["author"] ?? "Unknown",
          int.parse(res["data"]["comics"]["docs"][i]["likesCount"].toString()),
          res["data"]["comics"]["docs"][i]["thumb"]["fileServer"] +
              "/static/" +
              res["data"]["comics"]["docs"][i]["thumb"]["path"],
          res["data"]["comics"]["docs"][i]["_id"],
          tags,
          pages: res["data"]["comics"]["docs"][i]["pagesCount"],
        );
        comics.add(si);
      } catch (e) {
        continue;
      }
    }
    return Res(comics, subData: pages);
  }

  ///获取最新漫画
  Future<Res<List<ComicItemBrief>>> getLatest(int page) async {
    var response = await get("$apiUrl/comics?page=$page&s=dd",
        expiredTime: CacheExpiredTime.no);
    if (response.error) {
      return Res(null, errorMessage: response.errorMessage);
    }
    var res = response.data;
    var comics = <ComicItemBrief>[];
    for (int i = 0; i < res["data"]["comics"]["docs"].length; i++) {
      try {
        var tags = <String>[];
        tags.addAll(
            List<String>.from(res["data"]["comics"]["docs"][i]["tags"] ?? []));
        tags.addAll(List<String>.from(
            res["data"]["comics"]["docs"][i]["categories"] ?? []));

        var si = ComicItemBrief(
          res["data"]["comics"]["docs"][i]["title"] ?? "Unknown",
          res["data"]["comics"]["docs"][i]["author"] ?? "Unknown",
          int.parse(res["data"]["comics"]["docs"][i]["likesCount"].toString()),
          res["data"]["comics"]["docs"][i]["thumb"]["fileServer"] +
              "/static/" +
              res["data"]["comics"]["docs"][i]["thumb"]["path"],
          res["data"]["comics"]["docs"][i]["_id"],
          tags,
          pages: res["data"]["comics"]["docs"][i]["pagesCount"],
        );
        comics.add(si);
      } catch (e) {
        continue;
      }
    }
    return Res(comics);
  }
}

String getImageUrl(String url) {
  return url;
}

PicacgNetwork get network => PicacgNetwork();
