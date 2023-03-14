import 'dart:io';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/tools/notification.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/models.dart';

var network = Network();

//定义宽屏设备的临界值
const changePoint = 600;
const changePoint2 = 1300;

//App版本
const appVersion = "1.3.7";

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
  late List<ComicItemBrief> history;
  late String appChannel;
  late List<String> searchHistory;
  bool flag = true; //用于提供一些页面间通讯
  List<String> settings = [
    "1", //点击屏幕左右区域翻页
    "dd", //排序方式
    "1", //启动时检查更新
    "0", //使用转发服务器
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
  ];
  Appdata(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "",null,null,null);
    user = temp;
    history = [];
    appChannel = "3";
    searchHistory = [];
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
    history = [];
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
    await s.setInt("historyLength",history.length);
    for(int i=0;i<history.length;i++){
      var data = [history[i].title,history[i].id,history[i].author,history[i].path,history[i].likes.toString()];
      await s.setStringList("historyData$i", data);
    }
    await s.setString("appChannel",appChannel);
    await s.setStringList("settings", settings);
    await s.setStringList("search", searchHistory);
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
      for(int i=0;i<s.getInt("historyLength")!;i++){
        var data = s.getStringList("historyData$i");
        var c = ComicItemBrief(data![0], data[2], int.parse(data[4]), data[3], data[1]);
        history.add(c);
      }
      appChannel = s.getString("appChannel")!;
      searchHistory = s.getStringList("search")??[];
      return token==""?false:true;
    }
    catch(e){
      return false;
    }
  }
}

var appdata = Appdata();

var notifications = Notifications();