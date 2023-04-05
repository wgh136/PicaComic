import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import '../base.dart';
import '../tools/proxy.dart';
import 'package:html/parser.dart';
import 'package:get/get.dart';
import '../views/pre_search_page.dart';

class EhNetwork{
  final ehBaseUrl = "https://e-hentai.org";
  bool status = false;  //给出当前请求的状态
  String message = "";  //输出错误信息

  Future<String?> request(String url) async{
    status = false; //重置
    await setNetworkProxy();//更新代理

    var options = BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36"
      }
    );

    var dio =  Dio(options)
      ..interceptors.add(LogInterceptor());
    try {
      var data = (await dio.get(url)).data;
      if(kDebugMode){
        print(data);
      }

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

  Future<void> login() async{
    //var dio = await request();
    //TODO
  }

  double getStarsFromPosition(String position){
    var p = "";
    int l = 0;
    for(;l<position.length;l++){
      if(position[l]==':')  break;
    }
    for(int i = l;i<position.length;i++){
      if(position[i]=='p'){
        p = position.substring(l+1,i);
        break;
      }
    }
    return (int.parse(p)+144)/16/2;
  }

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
        var uploader = items[i].children[3+t].children[0].children[0].text;
        var tags = <String>[];
        for(var node in items[i].children[2+t].children[0].children[1].children){
          tags.add(node.attributes["title"]!);
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

  Future<void> getNextPageGalleries(Galleries galleries) async{
    if(galleries.next==null)  return;
    var next = await getGalleries(galleries.next!);
    galleries.galleries.addAll(next!.galleries);
    galleries.next = next.next;
  }

  Future<Gallery?> getGalleryInfo(EhGalleryBrief brief) async{
    //从漫画详情页链接中获取漫画详细信息
    var res = await request(brief.link);
    if(res==null) return null;
    var document = parse(res);
    var tags = <String, List<String>>{};
    var tagLists = document.querySelectorAll("div#taglist > table > tbody > tr");
    for(var tr in tagLists){
      var list = <String>[];
      for(var div in tr.children[1].children){
        list.add(div.children[0].text);
      }
      tags[tr.children[0].text.substring(0,tr.children[0].text.length-1)] = list;
    }
    var urls = <String>[];
    var links = document.querySelectorAll("div#gdt > div.gdtm > div > a");
    for(var link in links){
      urls.add(link.attributes["href"]!);
    }
    String? comment;
    if(document.getElementsByClassName("c4")!=[]){
      comment = document.querySelectorAll("div.gm > div.c1 > div.c6")[0].text;
    }
    return Gallery(brief, tags, urls, comment);
  }

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

  Future<EhLeaderboard?> getLeaderboard(EhLeaderboardType type) async{
    var res = await getGalleries("$ehBaseUrl/toplist.php?tl=${type.value}",leaderboard: true);
    if(res == null) return null;
    return EhLeaderboard(type, res.galleries, 0);
  }

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
}