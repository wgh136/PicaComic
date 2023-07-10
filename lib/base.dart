import 'dart:io';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/tools/notification.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/picacg_network/models.dart';

//定义宽屏设备的临界值
const changePoint = 600;
const changePoint2 = 1300;

const List<int> colors = [0X42A5F5, 0X29B6F6, 0X5C6BC0, 0XAB47BC,
  0XEC407A, 0X26C6DA, 0X26A69A, 0XFFEE58, 0X8D6E63];

//App版本
const appVersion = "1.6.17";

//路径分隔符
var pathSep = Platform.pathSeparator;

//ComicTile的最大宽度
const double comicTileMaxWidth = 630.0;
//ComicTile的宽高比
const double comicTileAspectRatio = 2.5;

var hotSearch = <String>[];
var downloadManager = DownloadManager();

class Appdata{
  //哔咔相关信息
  late String token;
  late Profile user;
  late String appChannel;
  late String imageQuality;

  ///搜索历史
  late List<String> searchHistory;

  ///用于身份认证页面判断当前状态
  bool flag = true;

  ///历史记录管理器, 可以通过factory构造函数访问, 也可以通过这里访问
  var history = HistoryManager();

  ///设置
  List<String> settings = [
    "1", //0 点击屏幕左右区域翻页
    "dd", //1 排序方式
    "1", //2 启动时检查更新
    "0", //3 Api请求地址, 为0时表示使用哔咔官方Api, 为1表示使用转发服务器
    "1", //4 宽屏时显示前进后退关闭按钮
    "1", //5 是否显示头像框
    "1", //6 启动时签到
    "1", //7 使用音量键翻页
    "0", //8 代理设置, 0代表使用系统代理
    "1", //9 翻页方式: 1从左向右,2从右向左,3从上至下,4从上至下(连续)
    "0", //10 是否第一次使用
    "0", //11 收藏夹浏览方式, 0为正常浏览, 1为分页浏览
    "0", //12 阻止屏幕截图
    "0", //13 需要生物识别
    "1", //14 阅读器中保持屏幕常亮
    "0", //15 Cloudflare IP, //为1表示使用哔咔官方提供的Ip, 为0表示禁用, 其他值表示使用自定义的Ip(废弃)
    "0", //16 Jm分类漫画排序模式, 值为 ComicsOrder 的索引
    "0", //17 Jm分流
    "0", //18 夜间模式降低图片亮度
    "0", //19 Jm搜索漫画排序模式, 值为 ComicsOrder 的索引
    "0", //20 Eh画廊站点, 1表示e-hentai, 2表示exhentai
    "111111", //21 启用的漫画源
    "", //22 下载目录, 仅Windows端, 为空表示使用App数据目录
    "0", //23 初始页面,
    "1111111111", //24 分类页面
    "0", //25 漫画列表显示模式
    "0", //26 已下载页面排序模式: 时间, 漫画名, 作者名, 大小
    "0", //27 颜色
    "2", //28 预加载页数
    "0", //29 eh优先加载原图
    "1", //30 picacg收藏夹新到旧
    "https://www.wnacg.com", //31 绅士漫画域名
  ];

  ///屏蔽的关键词
  List<String> blockingKeyword = [];

  ///是否第一次使用的判定, 用于显示提示
  List<String> firstUse = [
    "1",//屏蔽关键词1
    "1",//屏蔽关键词2(已废弃)
    "1",//漫画详情页
    "0",//是否进入过app
  ];

  //哔咔
  String picacgAccount = "";
  String picacgPassword = "";

  //eh相关信息
  String ehId = "";
  String ehPassHash = "";
  String ehAccount = "";
  String igneous = "";

  //jm相关信息
  String jmName = "";
  String jmEmail = "";
  String jmPwd = "";

  //绅士漫画
  String htName = "";
  String htPwd = "";

  Appdata(){
    token = "";
    var temp = Profile("", defaultAvatarUrl, "", 0, 0, "", "",null,null,null);
    user = temp;
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

  int getSearchMode(){
    var modes = ["dd","da","ld","vd"];
    return modes.indexOf(settings[1]);
  }

  void setSearchMode(int mode) async{
    var modes = ["dd","da","ld","vd"];
    settings[1] = modes[mode];
    var s = await SharedPreferences.getInstance();
    await s.setStringList("settings", settings);
  }

  void updateSettings() async{
    var s = await SharedPreferences.getInstance();
    await s.setStringList("settings", settings);
  }

  void clear(){
    token = "";
    var temp = Profile("", "", "", 0, 0, "", "",null,null,null);
    user = temp;
    writeData();
  }

  void writeFirstUse() async{
    var s = await SharedPreferences.getInstance();
    await s.setStringList("firstUse", firstUse);
  }

  void writeHistory() async{
    var s = await SharedPreferences.getInstance();
    await s.setStringList("search", searchHistory);
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
    await s.setStringList("blockingKeyword", blockingKeyword);
    await s.setStringList("firstUse", firstUse);
    await s.setString("image", imageQuality);
    await s.setString("ehId", ehId);
    await s.setString("ehAccount", ehAccount);
    await s.setString("ehPassHash", ehPassHash);
    await s.setString("jmName", jmName);
    await s.setString("jmEmail", jmEmail);
    await s.setString("jmPwd", jmPwd);
    await s.setString("ehIgneous", igneous);
    await s.setString("picacgAccount", picacgAccount);
    await s.setString("picacgPassword", picacgPassword);
    await s.setString("htName", htName);
    await s.setString("htPwd", htPwd);
  }
  Future<bool> readData() async{
    var s = await SharedPreferences.getInstance();
    try{
      token = (s.getString("token"))??"";
      user.name = s.getString("userName")??"";
      user.title = s.getString("userTitle")??"";
      user.level = s.getInt("userLevel")??0;
      user.email = s.getString("userEmail")??"";
      user.avatarUrl = s.getString("userAvatar")??defaultAvatarUrl;
      user.id = s.getString("userId")??"";
      user.exp = s.getInt("userExp")??0;
      if(s.getStringList("settings")!=null) {
        var st = s.getStringList("settings")!;
        for(int i=0;i<st.length;i++){
          settings[i] = st[i];
        }
      }
      while(settings[24].length < 10){
        settings[24] += "1";
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
      ehId = s.getString("ehId")??"";
      ehAccount = s.getString("ehAccount")??"";
      ehPassHash = s.getString("ehPassHash")??"";
      igneous = s.getString("ehIgneous")??"";
      jmName = s.getString("jmName")??"";
      jmEmail = s.getString("jmEmail")??"";
      jmPwd = s.getString("jmPwd")??"";
      picacgAccount = s.getString("picacgAccount")??"";
      picacgPassword = s.getString("picacgPassword")??"";
      htName = s.getString("htName")??"";
      htPwd = s.getString("htPwd")??"";
      return firstUse[3]=="1"||token!="";
    }
    catch(e){
      return false;
    }
  }
}

var appdata = Appdata();
var notifications = Notifications();