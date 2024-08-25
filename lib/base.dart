import 'dart:convert';
import 'dart:io';

import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/notification.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'foundation/def.dart';
export 'foundation/def.dart';

String get pathSep => Platform.pathSeparator;

var downloadManager = DownloadManager();

class Appdata {
  ///搜索历史
  List<String> searchHistory = [];
  Set<String> favoriteTags = {};

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
    "1111111111", //24 [废弃]分类页面
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
    "012345678", //59 explore page(废弃)
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
    "1", //72 漫画块显示收藏状态
    "0", //73 漫画块显示阅读位置
    "1.0", //74 图片收藏大小
    "", //75 eh profile
    "0", //76 阅读器内固定横屏
    "0,2,3,4,5,6,7,8", //77 探索页面
    "0", //78 已下载的eh漫画优先显示副标题
    "6", //79 下载并行
    "1", //80 启动时检查自定义漫画源的更新
    "0", //81 使用深色背景
    "111111", //82 内置漫画源启用状态,
    "1", //83 完全隐藏屏蔽的作品
  ];

  /// 隐式数据, 用于存储一些不需要用户设置的数据, 此数据通常为某些组件的状态, 此设置不应当被同步
  List<String> implicitData = [
    "1;;", //收藏夹状态
    "0", // 双页模式下第一页显示单页
    "0", // 点击关闭按钮时不显示提示
    webUA, // UA
  ];

  void writeImplicitData() async {
    var s = await SharedPreferences.getInstance();
    await s.setStringList("implicitData", implicitData);
  }

  void readImplicitData() async {
    var s = await SharedPreferences.getInstance();
    var data = s.getStringList("implicitData");
    if (data == null) {
      writeImplicitData();
      return;
    }
    for (int i = 0; i < data.length && i < implicitData.length; i++) {
      implicitData[i] = data[i];
    }
  }

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

  Future<void> readSettings(SharedPreferences s) async {
    var settingsFile = File("${App.dataPath}/settings");
    List<String> st;
    if (settingsFile.existsSync()) {
      var json = jsonDecode(await settingsFile.readAsString());
      if (json is List) {
        st = List.from(json);
      } else {
        st = [];
      }
    } else {
      st = s.getStringList("settings") ?? [];
    }
    for (int i = 0; i < st.length && i < settings.length; i++) {
      settings[i] = st[i];
    }
    if (settings[26].length < 2) {
      settings[26] += "0";
    }
  }

  Future<void> updateSettings([bool syncData = true]) async {
    var settingsFile = File("${App.dataPath}/settings");
    await settingsFile.writeAsString(jsonEncode(settings));
    if (syncData) {
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
    if (sync) {
      Webdav.uploadData();
    }
    var s = await SharedPreferences.getInstance();
    await updateSettings();
    await s.setStringList("blockingKeyword", blockingKeyword);
    await s.setStringList("firstUse", firstUse);
  }

  Future<bool> readData() async {
    var s = await SharedPreferences.getInstance();
    try {
      await readSettings(s);
      searchHistory = s.getStringList("search") ?? [];
      favoriteTags = (s.getStringList("favoriteTags") ?? []).toSet();
      blockingKeyword = s.getStringList("blockingKeyword") ?? [];
      if (s.getStringList("firstUse") != null) {
        var st = s.getStringList("firstUse")!;
        for (int i = 0; i < st.length; i++) {
          firstUse[i] = st[i];
        }
      }
      readImplicitData();
      return firstUse[3] == "1";
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
        "settings": settings,
        "firstUse": firstUse,
        "blockingKeywords": blockingKeyword,
        "favoriteTags": favoriteTags.toList(),
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
      if (json["history"] != null) {
        history.readDataFromJson(json["history"]);
      }
      // merge data
      blockingKeyword = Set<String>.from(
              ((json["blockingKeywords"] ?? []) + blockingKeyword) as List)
          .toList();
      favoriteTags =
          Set.from((json["favoriteTags"] ?? []) + List.from(favoriteTags));
      writeData(false);
      return true;
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "Appdata.readDataFromJson",
          "error reading appdata$e\n$s");
      readData();
      return false;
    }
  }

  final appSettings = _Settings();
}

var appdata = Appdata();
var notifications = Notifications();

/// clear all data
Future<void> clearAppdata() async {
  var s = await SharedPreferences.getInstance();
  await s.clear();
  var settingsFile = File("${App.dataPath}/settings");
  if (await settingsFile.exists()) {
    await settingsFile.delete();
  }
  appdata.history.clearHistory();
  appdata = Appdata();
  await appdata.readData();
  await eraseCache();
  await JmNetwork().cookieJar.deleteAll();
  await LocalFavoritesManager().clearAll();
}

class _Settings {
  List<String> get _settings => appdata.settings;

  /// Theme color, index of [colors] (lib/foundation/def.dart)
  int get theme => int.parse(_settings[27]);

  set theme(int value) {
    appdata.settings[27] = value.toString();
  }

  /// Dark Mode, 0/1/2 (system/disabled/enable)
  int get darkMode => int.parse(appdata.settings[32]);

  set darkMode(int value) {
    appdata.settings[32] = value.toString();
  }

  /// 0/1 (detailed/brief)
  int get comicTileDisplayType =>
      int.parse(appdata.settings[44].split(',').first);

  set comicTileDisplayType(int v) {
    var values = appdata.settings[44].split(',');
    if (values.length != 2) {
      values = ['0', '1.0'];
    }
    values[0] = v.toString();
    appdata.settings[44] = values.join(',');
  }

  /// 0/1 (Continuous mode/Paging mode)
  int get comicsListDisplayType => int.parse(appdata.settings[25]);

  set comicsListDisplayType(int value) {
    appdata.settings[25] = value.toString();
  }

  /// build-in comic sources
  bool isComicSourceEnabled(String key) {
    var index = builtInSources.indexOf(key);
    if (index == -1) {
      throw "Not Found";
    }
    return appdata.settings[82][index] == '1';
  }

  void setComicSourceEnabled(String key, bool enabled) {
    var index = builtInSources.indexOf(key);
    if (index == -1) {
      throw "Not Found";
    }
    appdata.settings[82] =
        appdata.settings[82].setValueAt(enabled ? '1' : '0', index);
  }

  List<String> get explorePages => appdata.settings[77].split(',');

  set explorePages(List<String> pages) {
    appdata.settings[77] = pages.join(',');
  }

  List<String> get categoryPages => appdata.settings[67].split(',');

  set categoryPages(List<String> pages) {
    appdata.settings[67] = pages.join(',');
  }

  String get initialSearchTarget => appdata.settings[63];

  set initialSearchTarget(String value) {
    appdata.settings[63] = value;
  }

  bool get reduceBrightnessInDarkMode => appdata.settings[18] == "1";

  set reduceBrightnessInDarkMode(bool value) {
    appdata.settings[18] = value ? "1" : "0";
  }

  bool get showPageInfoInReader => appdata.settings[57] == "1";

  set showPageInfoInReader(bool value) {
    appdata.settings[57] = value ? "1" : "0";
  }

  bool get showButtonsInReader => appdata.settings[4] == "1";

  set showButtonsInReader(bool value) {
    appdata.settings[4] = value ? "1" : "0";
  }

  bool get flipPageWithClick => appdata.settings[0] == "1";

  set flipPageWithClick(bool value) {
    appdata.settings[0] = value ? "1" : "0";
  }

  bool get useDarkBackground => appdata.settings[81] == "1";

  set useDarkBackground(bool value) {
    appdata.settings[81] = value ? "1" : "0";
  }

  bool get fullyHideBlockedWorks => appdata.settings[83] == "1";

  set fullyHideBlockedWorks(bool value) {
    appdata.settings[83] = value ? "1" : "0";
  }

  /// cache size limit in MB
  int get cacheLimit => int.tryParse(appdata.settings[35]) ?? 500;

  set cacheLimit(int value) {
    appdata.settings[35] = value.toString();
  }

  List<String> get networkFavorites => appdata.settings[68].split(',');

  set networkFavorites(List<String> pages) {
    appdata.settings[68] = pages.join(',');
  }
}
