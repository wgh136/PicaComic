import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/notification.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'network/picacg_network/models.dart';
export 'foundation/def.dart';

//路径分隔符
const pathSep = '/';

var downloadManager = DownloadManager();

class Appdata {
  //哔咔相关信息
  late String token;
  late Profile user;
  late String appChannel;
  late String imageQuality;

  ///搜索历史
  late List<String> searchHistory;
  Set<String> favoriteTags = {};

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
    "00", //26 已下载页面排序模式: 时间, 漫画名, 作者名, 大小
    "0", //27 颜色
    "2", //28 预加载页数
    "0", //29 eh优先加载原图
    "1", //30 picacg收藏夹新到旧
    "https://www.wnacg.com", //31 绅士漫画域名
    "0", //32  深色模式: 0-跟随系统, 1-禁用, 2-启用
    "5", //33 自动翻页时间
    "1000", //34 缓存数量限制
    "500", //35 缓存大小限制
    "1", //36 翻页动画
    "0", //37 禁漫图片分流
    "0", //38 高刷新率
    "0", //39 nhentai搜索排序
    "25", //40 点按翻页识别范围(0-50),
    "0", //41 阅读器图片布局方式, 0-contain, 1-fitWidth, 2-fitHeight
    "0", //42 禁漫收藏夹排序模式, 0-最新收藏, 1-最新更新
    "1", //43 限制图片宽度
    "0,1.0", //44 comic display type
    "", //45 webdav
    "0", //46 webdav version
    "0", //47 eh warning
    "https://nhentai.net", //48 nhentai domain
    "1", //49 阅读器中双击放缩
    "", //50 language, empty=system
    "", //51 默认收藏夹
    "1", //52 favorites
    "0", //53 本地收藏添加位置(尾/首)
    "0", //54 阅读后移动本地收藏(否/尾/首)
    "1", //55 长按缩放
    "https://18comic.vip", //56 jm domain
    "1", //57 show page info in reader
    "0", //58 hosts
    "012345678", //59 explore page
    "0", //60 action when local favorite is tapped
    "0", //61 check link in clipboard
    "10000", //62 漫画信息页面工具栏: "快速收藏".tl, "复制标题".tl, "复制链接".tl, "分享".tl, "搜索相似".tl
    "0", //63 初始搜索目标
    "0", //64 启用侧边翻页
    "0", //65 本地收藏显示数量
    "0", //66 缩略图布局: 覆盖, 容纳
    "picacg,ehentai,jm,htmanga,nhentai", //67 分类页面
    "picacg,ehentai,jm,htmanga,nhentai", //68 收藏页面
    "0", //69 自动添加语言筛选
    "0", //70 反转点按识别
    "1", // 71 关联网络收藏夹后每次刷新拉取几页
  ];

  ///屏蔽的关键词
  List<String> blockingKeyword = [];

  ///是否第一次使用的判定, 用于显示提示
  List<String> firstUse = [
    "1", //屏蔽关键词1
    "1", //屏蔽关键词2(已废弃)
    "1", //漫画详情页
    "0", //是否进入过app
    "1", //显示本地收藏夹的管理提示
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
  String jmPwd = "";

  //绅士漫画
  String htName = "";
  String htPwd = "";

  Appdata() {
    token = "";
    var temp =
        Profile("", defaultAvatarUrl, "", 0, 0, "", "", null, null, null);
    user = temp;
    appChannel = "3";
    searchHistory = [];
    imageQuality = "original";
  }

  void setQuality(int i) {
    switch (i) {
      case 1:
        imageQuality = "low";
        break;
      case 2:
        imageQuality = "middle";
        break;
      case 3:
        imageQuality = "high";
        break;
      case 4:
        imageQuality = "original";
        break;
    }
    writeData();
  }

  int getQuality() {
    switch (imageQuality) {
      case "low":
        return 1;
      case "middle":
        return 2;
      case "high":
        return 3;
      case "original":
        return 4;
      default:
        return 4;
    }
  }

  var nhentaiData = <String>[
    "Pica Comic", // ua
  ];

  void updateNhentai() async {
    var s = await SharedPreferences.getInstance();
    await s.setStringList("nhentaiData", nhentaiData);
  }

  int getSearchMode() {
    var modes = ["dd", "da", "ld", "vd"];
    return modes.indexOf(settings[1]);
  }

  void setSearchMode(int mode) async {
    var modes = ["dd", "da", "ld", "vd"];
    settings[1] = modes[mode];
    var s = await SharedPreferences.getInstance();
    await s.setStringList("settings", settings);
  }

  void updateSettings([bool syncData = true]) async {
    var s = await SharedPreferences.getInstance();
    await s.setStringList("settings", settings);
    if(syncData) {
      Webdav.uploadData();
    }
  }

  void writeFirstUse() async {
    var s = await SharedPreferences.getInstance();
    await s.setStringList("firstUse", firstUse);
  }

  void writeHistory() async {
    var s = await SharedPreferences.getInstance();
    await s.setStringList("search", searchHistory);
    await s.setStringList("favoriteTags", favoriteTags.toList());
  }

  Future<void> writeData([bool sync = true]) async {
    if(sync) {
      Webdav.uploadData();
    }
    var s = await SharedPreferences.getInstance();
    await s.setString("token", token);
    await s.setString("userName", user.name);
    await s.setString("userAvatar", user.avatarUrl);
    await s.setString("userId", user.id);
    await s.setString("userEmail", user.email);
    await s.setInt("userLevel", user.level);
    await s.setInt("userExp", user.exp);
    await s.setString("userTitle", user.title);
    await s.setString("appChannel", appChannel);
    await s.setStringList("settings", settings);
    await s.setStringList("blockingKeyword", blockingKeyword);
    await s.setStringList("firstUse", firstUse);
    await s.setString("image", imageQuality);
    await s.setString("ehId", ehId);
    await s.setString("ehAccount", ehAccount);
    await s.setString("ehPassHash", ehPassHash);
    await s.setString("jmName", jmName);
    await s.setString("jmPwd", jmPwd);
    await s.setString("ehIgneous", igneous);
    await s.setString("picacgAccount", picacgAccount);
    await s.setString("picacgPassword", picacgPassword);
    await s.setString("htName", htName);
    await s.setString("htPwd", htPwd);
  }

  Future<bool> readData() async {
    var s = await SharedPreferences.getInstance();
    try {
      token = (s.getString("token")) ?? "";
      user.name = s.getString("userName") ?? "";
      user.title = s.getString("userTitle") ?? "";
      user.level = s.getInt("userLevel") ?? 0;
      user.email = s.getString("userEmail") ?? "";
      user.avatarUrl = s.getString("userAvatar") ?? defaultAvatarUrl;
      user.id = s.getString("userId") ?? "";
      user.exp = s.getInt("userExp") ?? 0;
      if (s.getStringList("settings") != null) {
        var st = s.getStringList("settings")!;
        for (int i = 0; i < st.length && i < settings.length; i++) {
          settings[i] = st[i];
        }
      }
      while (settings[24].length < 10) {
        settings[24] += "1";
      }
      if (settings[26].length < 2) {
        settings[26] += "0";
      }
      appChannel = s.getString("appChannel") ?? "3";
      searchHistory = s.getStringList("search") ?? [];
      favoriteTags = (s.getStringList("favoriteTags") ?? []).toSet();
      blockingKeyword = s.getStringList("blockingKeyword") ?? [];
      if (s.getStringList("firstUse") != null) {
        var st = s.getStringList("firstUse")!;
        for (int i = 0; i < st.length; i++) {
          firstUse[i] = st[i];
        }
      }
      imageQuality = s.getString("image") ?? "original";
      ehId = s.getString("ehId") ?? "";
      ehAccount = s.getString("ehAccount") ?? "";
      ehPassHash = s.getString("ehPassHash") ?? "";
      igneous = s.getString("ehIgneous") ?? "";
      jmName = s.getString("jmName") ?? "";
      jmPwd = s.getString("jmPwd") ?? "";
      picacgAccount = s.getString("picacgAccount") ?? "";
      picacgPassword = s.getString("picacgPassword") ?? "";
      htName = s.getString("htName") ?? "";
      htPwd = s.getString("htPwd") ?? "";
      nhentaiData = s.getStringList("nhentaiData") ?? nhentaiData;
      return firstUse[3] == "1" || token != "";
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        "settings": settings,
        "firstUse": firstUse,
        "picacgAccount": picacgAccount,
        "picacgPassword": picacgPassword,
        "token": token,
        "ehId": ehId,
        "ehPassHash": ehPassHash,
        "ehAccount": ehAccount,
        "igneous": igneous,
        "jmName": jmName,
        "jmPwd": jmPwd,
        "htName": htName,
        "htPwd": htPwd,
        "blockingKeywords": blockingKeyword,
        "favoriteTags": favoriteTags.toList()
      };

  bool readDataFromJson(Map<String, dynamic> json) {
    try {
      var newSettings = List<String>.from(json["settings"]);
      var downloadPath = settings[22];
      for (var i = 0; i < settings.length && i < newSettings.length; i++) {
        settings[i] = newSettings[i];
      }
      settings[22] = downloadPath;
      var newFirstUse = List<String>.from(json["firstUse"]);
      for (var i = 0; i < firstUse.length && i < newFirstUse.length; i++) {
        firstUse[i] = newFirstUse[i];
      }
      picacgAccount = json["picacgAccount"];
      picacgPassword = json["picacgPassword"];
      token = json["token"];
      ehId = json["ehId"];
      ehPassHash = json["ehPassHash"];
      ehAccount = json["ehAccount"];
      igneous = json["igneous"];
      jmName = json["jmName"];
      jmPwd = json["jmPwd"];
      htName = json["htName"];
      htPwd = json["htPwd"];
      if(json["history"] != null) {
        history.readDataFromJson(json["history"]);
      }
      blockingKeyword = List.from(json["blockingKeywords"] ?? blockingKeyword);
      favoriteTags = Set.from(json["favoriteTags"] ?? favoriteTags);
      writeData(false);
      return true;
    } catch (e) {
      readData();
      return false;
    }
  }
}

var appdata = Appdata();
var notifications = Notifications();

/// clear all data
Future<void> clearAppdata() async {
  var s = await SharedPreferences.getInstance();
  await s.clear();
  appdata.history.clearHistory();
  appdata = Appdata();
  await appdata.readData();
  await eraseCache();
  network.token = "";
  EhNetwork().folderNames = List.generate(10, (index) => "Favorite $index");
  await JmNetwork().cookieJar?.deleteAll();
  await HtmangaNetwork().cookieJar.deleteAll();
  await LocalFavoritesManager().clearAll();
}