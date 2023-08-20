import 'dart:async';
import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/error_report.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/background_service.dart';
import 'package:pica_comic/tools/block_screenshot.dart';
import 'package:pica_comic/tools/cache_auto_clear.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/mouse_listener.dart';
import 'package:pica_comic/network/proxy.dart';
import 'package:pica_comic/views/auth_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:workmanager/workmanager.dart';
import 'network/picacg_network/methods.dart';

bool notFirstUse = false;

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    startClearCache();
    FlutterError.onError = (details) {
      sendLog(details.exceptionAsString(), details.stack.toString());
      LogManager.addLog(LogLevel.error, "Unhandled Exception",
          "${details.exception}\n${details.stack}");
    };
    appdata.readData().then((b) async {
      if (GetPlatform.isMobile) {
        Workmanager().initialize(
          onStart,
        );
      }
      await checkDownloadPath();
      notFirstUse = appdata.firstUse[3] == "1";
      if (b) {
        network = PicacgNetwork(appdata.token);
      }
      setNetworkProxy(); //设置代理
      runApp(const MyApp());
    });
  }, (error, stack) {
    sendLog(error.toString(), stack.toString());
    LogManager.addLog(LogLevel.error, "Unhandled Exception", "$error\n$stack");
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(GetPlatform.isAndroid && appdata.settings[38] == "1"){
      try {
        FlutterDisplayMode.setHighRefreshRate();
      }
      catch(e){
        // ignore
      }
    }
    setNetworkProxy(); //当App从后台进入前台, 代理设置可能发生变更
    if (state == AppLifecycleState.resumed) {
      if (appdata.settings[13] == "1" && appdata.flag) {
        appdata.flag = false;
        Get.to(() => const AuthPage());
      }
    } else if (state == AppLifecycleState.paused) {
      appdata.flag = true;
    }
    //禁漫的登录有效期较短, 部分系统对后台的限制弱, 且本app占用资源少, 可能导致长期挂在后台的情况
    //因此从后台进入前台时, 尝试重新登录
    jmNetwork.loginFromAppdata();
  }



  @override
  void initState() {
    if(GetPlatform.isAndroid && appdata.settings[38] == "1"){
      try {
        FlutterDisplayMode.setHighRefreshRate();
      }
      catch(e){
        // ignore
      }
    }
    listenMouseSideButtonToBack();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(this);
    downloadManager.init(); //初始化下载管理器
    notifications.init(); //初始化通知管理器
    NhentaiNetwork().init();
    if (appdata.settings[12] == "1") {
      blockScreenshot();
    }
    super.initState();
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness = View.of(context).platformDispatcher.platformBrightness;
    if (brightness == Brightness.light) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false));
    } else {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = View.of(context).platformDispatcher.platformBrightness;
    if (brightness == Brightness.light) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false));
    } else {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarContrastEnforced: false));
    }
    return DynamicColorBuilder(builder: (light, dark) {
      ColorScheme? lightColor;
      ColorScheme? darkColor;
      if (int.parse(appdata.settings[27]) != 0) {
        lightColor = ColorScheme.fromSeed(
            seedColor: Color(colors[int.parse(appdata.settings[27]) - 1]),
            brightness: Brightness.light);
        darkColor = ColorScheme.fromSeed(
            seedColor: Color(colors[int.parse(appdata.settings[27]) - 1]),
            brightness: Brightness.dark);
      } else {
        lightColor = light;
        darkColor = dark;
      }
      ColorScheme? colorScheme;
      if (appdata.settings[32] == "1") {
        colorScheme =
            lightColor ?? ColorScheme.fromSeed(seedColor: Colors.pinkAccent);
      } else if (appdata.settings[32] == "2") {
        colorScheme = darkColor ??
            ColorScheme.fromSeed(
                seedColor: Colors.pinkAccent, brightness: Brightness.dark);
      }
      return GetMaterialApp(
        title: 'Pica Comic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: (colorScheme ??
              lightColor ??
              ColorScheme.fromSeed(seedColor: Colors.pinkAccent)),
          useMaterial3: true,
          fontFamily: GetPlatform.isWindows ? "font" : "",
        ),
        darkTheme: ThemeData(
          colorScheme: (colorScheme ??
              darkColor ??
              ColorScheme.fromSeed(
                  seedColor: Colors.pinkAccent, brightness: Brightness.dark)),
          useMaterial3: true,
          fontFamily: GetPlatform.isWindows ? "font" : "",
        ),
        home: notFirstUse ? const MainPage() : const WelcomePage(),
        fallbackLocale: const Locale('zh', 'CN'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('zh', 'CN'), Locale('zh', 'TW')],
        logWriterCallback: (String s, {bool? isError}) {
          LogManager.addLog(
              (isError ?? false) ? LogLevel.warning : LogLevel.info,
              "App Status",
              s);
        },
        builder: (context, widget) {
          ErrorWidget.builder = (details) {
            LogManager.addLog(LogLevel.error, "Unhandled Exception",
                "${details.exception}\n${details.stack}");
            return Center(
              child: Text(details.exception.toString()),
            );
          };
          if (widget != null) return widget;
          throw ('widget is null');
        },
      );
    });
  }
}
