import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/tools/js.dart';
import '../base.dart';
import '../tools/proxy.dart';
import 'package:html/parser.dart';
import 'package:get/get.dart';
import '../views/pre_search_page.dart';

class EhNetwork{
  ///e-hentai的url
  final ehBaseUrl = "https://e-hentai.org";
  final ehApiUrl = "https://api.e-hentai.org/api.php";

  ///给出当前请求的状态
  bool status = false;

  ///输出错误信息
  String message = "";

  ///从url获取数据, 在请求时设置了cookie
  Future<String?> request(String url, {Map<String,String>? headers,}) async{
    status = false; //重置
    await setNetworkProxy();//更新代理

    var options = BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: true,
      headers: {
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
        "cookie": "nw=1${appdata.ehId=="" ? "" : ";ipb_member_id=${appdata.ehId};ipb_pass_hash=${appdata.ehPassHash}"}",
        ...?headers
      }
    );

    var dio =  Dio(options)
      ..interceptors.add(LogInterceptor());
    try {
      var data = (await dio.get(url)).data;
      if((data as String).substring(0,4) == "Your"){
        status = true;
        message = "Your IP address has been temporarily banned";
        return null;
      }
      return data;
    }
    on DioError catch(e){
      if(e.type!=DioErrorType.unknown){
        status = true;
        message = e.message!;
      }
      return null;
    }
    catch(e){
      return null;
    }
  }

  ///eh APi请求
  Future<String?> apiRequest(Map<String, dynamic> data, {Map<String,String>? headers,}) async{
    status = false; //重置
    await setNetworkProxy();//更新代理
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
          "cookie": "nw=1${appdata.ehId=="" ? "" : ";ipb_member_id=${appdata.ehId};ipb_pass_hash=${appdata.ehPassHash}"}",
          ...?headers
        }
    );

    var dio =  Dio(options)
      ..interceptors.add(LogInterceptor());

    try{
      var res = await dio.post(ehApiUrl, data: data);
      return res.data;
    }
    on DioError catch(e){
      if(e.type!=DioErrorType.unknown){
        status = true;
        message = e.message!;
      }
      return null;
    }
    catch(e){
      return null;
    }
  }

  Future<String?> post(String url, dynamic data, {Map<String,String>? headers,}) async{
    status = false; //重置
    await setNetworkProxy();//更新代理
    var options = BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        receiveDataWhenStatusError: true,
        validateStatus: (status)=>status==200||status==302,
        headers: {
          "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36",
          "cookie": "nw=1${appdata.ehId=="" ? "" : ";ipb_member_id=${appdata.ehId};ipb_pass_hash=${appdata.ehPassHash}"}",
          ...?headers
        }
    );

    var dio =  Dio(options)
      ..interceptors.add(LogInterceptor());

    try{
      var res = await dio.post(url, data: data);
      return res.data??"";
    }
    on DioError catch(e){
      if(e.type!=DioErrorType.unknown){
        status = true;
        message = e.message!;
      }
      return null;
    }
    catch(e){
      return null;
    }
  }

  ///获取用户名, 同时用于检测cookie是否有效
  Future<bool> getUserName() async{
    var res = await request("https://forums.e-hentai.org/index.php?act=UserCP&CODE=00",headers: {
      "referer": "https://forums.e-hentai.org/index.php?",
      "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "accept-encoding": "gzip, deflate, br",
      "accept-language": "zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7"
    });
    if(res == null){
      return false;
    }
    var html = parse(res);
    var name = html.querySelector("div#userlinks > p.home > b > a");
    if (name != null) {
      appdata.ehAccount = name.text;
      appdata.writeData();
    }else{
      appdata.ehId = "";
      appdata.ehPassHash = "";
    }
    return name != null;
  }

  ///解析星星的html元素的位置属性, 返回评分
  double getStarsFromPosition(String position){
    int i =0;
    while(position[i]!=";"){
      i++;
      if(i == position.length){
        break;
      }
    }
    switch(position.substring(0,i)){
      case "background-position:0px -1px": return 5;
      case "background-position:0px -21px": return 4.5;
      case "background-position:-16px -1px": return 4;
      case "background-position:-16px -21px": return 3.5;
      case "background-position:-32px -1px": return 3;
      case "background-position:-32px -21px": return 2.5;
      case "background-position:-48px -1px": return 2;
      case "background-position:-48px -21px": return 1.5;
      case "background-position:-64px -1px": return 1;
      case "background-position:-64px -21px": return 0.5;
    }
    return 0.5;
  }

  ///从e-hentai链接中获取当前页面的所有画廊
  Future<Galleries?> getGalleries(String url,{bool leaderboard = false}) async{
    //从一个链接中获取所有画廊, 同时获得下一页的链接
    //leaderboard比正常的表格多了第一列
    int t = 0;
    if(leaderboard){
      t++;
    }
    var res = await request(url);
    if(res==null) return null;
    var document = parse(res);
    var items = document.querySelectorAll("table.itg.gltc > tbody > tr");
    var galleries = <EhGalleryBrief>[];
    for(int i = 1;i<items.length;i++){
      //items的第一个为表格的标题, 忽略
      try{
        var type = items[i].children[0+t].children[0].text;
        var time = items[i].children[1+t].children[2].children[0].text;
        var stars = getStarsFromPosition(items[i].children[1+t].children[2].children[1].attributes["style"]!);
        var cover = items[i].children[1+t].children[1].children[0].children[0].attributes["src"];
        if(cover![0]=='d'){
          cover = items[i].children[1+t].children[1].children[0].children[0].attributes["data-src"];
        }
        var title = items[i].children[2+t].children[0].children[0].text;
        var link = items[i].children[2+t].children[0].attributes["href"];
        String uploader = "";
        try{
          uploader = items[i].children[3 + t].children[0].children[0].text;
        }
        catch(e){
          //收藏夹页没有uploader
        }
        var tags = <String>[];
        for(var node in items[i].children[2+t].children[0].children[1].children){
          tags.add(node.attributes["title"]!);
        }
        //检查屏蔽词
        for(var word in appdata.blockingKeyword){
          if(title.contains(word)){
            continue;
          }
          if(type == word){
            continue;
          }
          if(tags.contains(word)){
            continue;
          }
        }
        galleries.add(EhGalleryBrief(title, type, time, uploader, cover!, stars, link!, tags));
      }
      catch(e){
        //表格中存在空行, 我也不知道为什么这样设计
        continue;
      }
    }
    var g = Galleries();
    var nextButton = document.getElementById("dnext");
    if(nextButton == null){
      g.next = null;
    }else{
      g.next = nextButton.attributes["href"];
    }
    g.galleries = galleries;
    return g;
  }

  ///获取画廊的下一页
  Future<void> getNextPageGalleries(Galleries galleries) async{
    if(galleries.next==null)  return;
    var next = await getGalleries(galleries.next!);
    galleries.galleries.addAll(next!.galleries);
    galleries.next = next.next;
  }

  ///从漫画详情页链接中获取漫画详细信息
  Future<Gallery?> getGalleryInfo(EhGalleryBrief brief) async{
    try{
      var res = await request("${brief.link}?/hc=1");
      if (res == null) return null;
      var document = parse(res);
      //tags
      var tags = <String, List<String>>{};
      var tagLists = document.querySelectorAll("div#taglist > table > tbody > tr");
      for (var tr in tagLists) {
        var list = <String>[];
        for (var div in tr.children[1].children) {
          list.add(div.children[0].text);
        }
        tags[tr.children[0].text.substring(0, tr.children[0].text.length - 1)] = list;
      }
      //图片链接, 仅加载第一页, 因为无需额外的网络请求, 剩下的进入阅读器加载
      var urls = <String>[];
      String maxPage = "1"; //缩略图列表的最大页数
      var pages = document.querySelectorAll("div.gtb > table.ptb > tbody > tr > td");
      maxPage = pages[pages.length - 2].text;
      try {
        var temp = document;
        var links = temp.querySelectorAll("div#gdt > div.gdtm > div > a");
        for (var link in links) {
          urls.add(link.attributes["href"]!);
        }
      } catch (e) {
        //获取图片链接失败
        return null;
      }
      bool favorite = true;
      if(document.getElementById("favoritelink")?.text == " Add to Favorites"){
        favorite = false;
      }
      var gallery = Gallery(brief, tags, urls, favorite,maxPage);
      //评论
      var comments = document.getElementsByClassName("c1");
      for(var c in comments){
        var name = c.getElementsByClassName("c3")[0].getElementsByTagName("a")[0].text;
        var time = c.getElementsByClassName("c3")[0].text.substring(11,32);
        var content = c.getElementsByClassName("c6")[0].text;
        gallery.comments.add(Comment(name, content, time));
      }
      //上传者
      var uploader = document.getElementById("gdn")!.children[0].text;
      gallery.uploader = uploader;
      //星星
      var stars =
          getStarsFromPosition(document.getElementById("rating_image")!.attributes["style"]!);
      gallery.stars = stars;
      //平均分数
      gallery.rating = document.getElementById("rating_label")?.text;
      //类型
      var type = document.getElementsByClassName("cs")[0].text;
      gallery.type = type;
      //时间
      var time = document.querySelector("div#gdd > table > tbody > tr > td.gdt2")!.text;
      gallery.time = time;
      //身份认证数据
      var js = document.getElementsByTagName("script")[3].text;
      gallery.auth = getVariablesFromJsCode(js);
      return gallery;
    }
    catch(e){
      status = true;
      message = "解析HTML时出现错误";
      if(kDebugMode){
        print(e);
      }
      return null;
    }
  }

  ///获取图片链接
  ///
  /// 返回2表示成功加载了一页
  /// 返回1表示加载完成
  /// 返回0表示失败
  Stream<int> loadGalleryPages(Gallery gallery) async*{
    for (int i = 1; i < int.parse(gallery.maxPage); i++) {
      try {
        var temp = parse(await request("${gallery.link}?p=$i"));
        var links = temp.querySelectorAll("div#gdt > div.gdtm > div > a");
        for (var link in links) {
          gallery.urls.add(link.attributes["href"]!);
        }
        yield 2;
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        //获取图片链接失败
        yield 0;
        break;
      }
    }
    yield 1;
  }

  ///搜索e-hentai
  Future<Galleries?> search(String keyword) async{
    if(keyword!=""){
      appdata.searchHistory.remove(keyword);
      appdata.searchHistory.add(keyword);
      appdata.writeData();
    }
    var res =  await getGalleries("$ehBaseUrl/?f_search=$keyword");
    Future.delayed(const Duration(microseconds: 500),()=>Get.find<PreSearchController>().update());
    return res;
  }

  ///获取排行榜
  Future<EhLeaderboard?> getLeaderboard(EhLeaderboardType type) async{
    var res = await getGalleries("$ehBaseUrl/toplist.php?tl=${type.value}",leaderboard: true);
    if(res == null) return null;
    return EhLeaderboard(type, res.galleries, 0);
  }

  ///获取排行榜的下一页
  Future<void> getLeaderboardNextPage(EhLeaderboard leaderboard) async{
    if(leaderboard.loaded == EhLeaderboard.max){
      return;
    }else{
      var res = await getGalleries("$ehBaseUrl/toplist.php?tl=${leaderboard.type.value}&p=${leaderboard.loaded+1}",leaderboard: true);
      if(res!=null){
        leaderboard.galleries.addAll(res.galleries);
      }
      leaderboard.loaded++;
    }
  }

  ///评分
  Future<bool> rateGallery(Map<String, String> auth, int rating) async{
    var res = await apiRequest({
      "method": "rategallery",
      "apiuid": auth["apiuid"],
      "apikey": auth["apikey"],
      "gid": auth["gid"],
      "token": auth["token"],
      "rating": rating
    });
    return res!=null;
  }

  ///收藏
  Future<bool> favorite(String gid, String token) async{
    var res = await post(
      "https://e-hentai.org/gallerypopups.php?gid=$gid&t=$token&act=addfav",
      "favcat=0&favnote=&apply=Add+to+Favorites&update=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    );
    return res!=null;
  }

  ///取消收藏
  Future<bool> unfavorite(String gid, String token) async{
    var res = await post(
      "https://e-hentai.org/gallerypopups.php?gid=$gid&t=$token&act=addfav",
      "favcat=favdel&favnote=&apply=Apply+Changes&update=1",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    );
    return res!=null;
  }

  ///发送评论
  Future<bool> comment(String content, String link) async{
    var res = await post(
      link,
      "commenttext_new=${Uri.encodeComponent(content)}",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded"
      }
    );
    if(res == null){
      return false;
    }
    var document = parse(res);
    if(document.querySelector("p.br") != null){
      status = true;
      message = document.querySelector("p.br")!.text;
      return false;
    }
    return true;
  }
}