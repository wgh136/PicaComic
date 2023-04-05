import 'dart:convert';
import 'dart:io';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/tools/notification.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'eh_network/eh_main_network.dart';
import 'network/models.dart';

var network = Network();
var ehNetwork = EhNetwork();

//定义宽屏设备的临界值
const changePoint = 600;
const changePoint2 = 1300;

//App版本
const appVersion = "1.4.0";

//路径分隔符
var pathSep = Platform.pathSeparator;

//ComicTile的最大宽度
const double comicTileMaxWidth = 600.0;
//ComicTile的宽高比
const double comicTileAspectRatio = 3.0;

var hotSearch = <String>[];
var downloadManager = DownloadManage();

class Appdata{
  late String token;
  late Profile user;
  late String appChannel;
  late String imageQuality;
  late List<HistoryItem> history;
  late List<String> searchHistory;
  bool flag = true; //用于提供一些页面间通讯
  List<String> settings = [
    "1", //点击屏幕左右区域翻页
    "dd", //排序方式
    "1", //启动时检查更新
    "0", //Api请求地址, 为0时表示使用哔咔官方Api, 为1表示使用转发服务器
    "1", //宽屏时显示前进后退关闭按钮
    "1", //是否显示头像框
    "1", //启动时签到
    "1", //使用音量键翻页
    "0", //代理设置, 0代表使用系统代理
    "1", //翻页方式: 1从左向右,2从右向左,3从上至下,4从上至下(连续)
    "0", //是否第一次使用
    "0", //收藏夹浏览方式, 0为正常浏览, 1为分页浏览
    "0", //阻止屏幕截图
    "0", //需要生物识别
    "1", //阅读器中保持屏幕常亮
    "1", //Cloudflare IP, //为1表示使用哔咔官方提供的Ip, 为0表示禁用, 其他值表示使用自定义的Ip
  ];
  List<String> blockingKeyword = [];
  List<String> firstUse = [
    "1",//屏蔽关键词1
    "1",//屏蔽关键词2
    "1",//漫画详情页
  ];
  Appdata(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "",null,null,null);
    user = temp;
    history = [];
    appChannel = "3";
    searchHistory = [];
    imageQuality = "original";
  }

  void setQuality(int i){
    switch(i){
      case 1: imageQuality="low";break;
      case 2: imageQuality="middle";break;
      case 3: imageQuality="high";break;
      case 4: imageQuality="original";break;
    }
    writeData();
  }

  int getQuality(){
    switch(imageQuality){
      case "low": return 1;
      case "middle": return 2;
      case "high": return 3;
      case "original": return 4;
      default: return 4;
    }
  }

  int getSearchMod(){
    var modes = ["dd","da","ld","vd"];
    return modes.indexOf(settings[1]);
  }

  void saveSearchMode(int mode) async{
    var modes = ["dd","da","ld","vd"];
    settings[1] = modes[mode];
    var s = await SharedPreferences.getInstance();
    await s.setStringList("settings", settings);
  }

  void clear(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "",null,null,null);
    user = temp;
    writeData();
  }

  Future<void> writeData() async{
    var s = await SharedPreferences.getInstance();
    await s.setString("token", token);
    await s.setString("userName", user.name);
    await s.setString("userAvatar", user.avatarUrl);
    await s.setString("userId", user.id);
    await s.setString("userEmail", user.email);
    await s.setInt("userLevel",user.level);
    await s.setInt("userExp",user.exp);
    await s.setString("userTitle", user.title);
    await s.setString("appChannel",appChannel);
    await s.setStringList("settings", settings);
    await s.setStringList("search", searchHistory);
    await s.setStringList("blockingKeyword", blockingKeyword);
    await s.setStringList("firstUse", firstUse);
    await s.setString("image", imageQuality);
  }
  Future<bool> readData() async{
    var s = await SharedPreferences.getInstance();
    try{
      token = (s.getString("token"))!;
      user.name = s.getString("userName")!;
      user.title = s.getString("userTitle")!;
      user.level = s.getInt("userLevel")!;
      user.email = s.getString("userEmail")!;
      user.avatarUrl = s.getString("userAvatar")!;
      user.id = s.getString("userId")!;
      user.exp = s.getInt("userExp")!;
      if(s.getStringList("settings")!=null) {
        var st = s.getStringList("settings")!;
        for(int i=0;i<st.length;i++){
          settings[i] = st[i];
        }
      }
      appChannel = s.getString("appChannel")!;
      searchHistory = s.getStringList("search")??[];
      blockingKeyword = s.getStringList("blockingKeyword")??[];
      if(s.getStringList("firstUse")!=null) {
        var st = s.getStringList("firstUse")!;
        for(int i=0;i<st.length;i++){
          firstUse[i] = st[i];
        }
      }
      imageQuality = s.getString("image")??"original";
      return token==""?false:true;
    }
    catch(e){
      return false;
    }
  }

  Future<void> saveHistory() async{
    var data = const JsonEncoder().convert(List.generate(history.length, (index) => history[index].toMap()));
    var s = await SharedPreferences.getInstance();
    await s.setString("newHistory", data);
  }

  Future<void> readHistory() async{
    var s = await SharedPreferences.getInstance();
    var data = const JsonDecoder().convert(s.getString("newHistory")??"[]");
    for(var c in data){
      history.add(HistoryItem.fromMap(c));
    }
  }

  Future<HistoryItem> addHistory(ComicItemBrief item) async{
    await readHistory();
    var ep = 0;
    var page = 0;
    var newHistory = <HistoryItem>[];
    for(var comic in history){
      if(comic.id==item.id){
        ep = comic.ep;
        page = comic.page;
      }else{
        newHistory.add(comic);
      }
    }
    newHistory.add(HistoryItem(item.id,item.title,item.author,item.path,DateTime.now(),ep,page));
    history = newHistory;
    await saveHistory();
    history.clear();
    return HistoryItem(item.id,item.title,item.author,item.path,DateTime.now(),ep,page);
  }

  void saveReadInfo(int ep, int page, String id) async{
    await readHistory();
    for(int i=history.length-1;i>=0;i--){
      if(history[i].id==id){
        history[i].ep = ep;
        history[i].page = page;
        history[i].time = DateTime.now();
        var comic = history[i];
        history.add(comic);
        history.removeAt(i);
      }
    }
    await saveHistory();
    history.clear();
  }
}

var appdata = Appdata();

var notifications = Notifications();