import 'dart:async';
import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/block_screenshot.dart';
import 'package:pica_comic/tools/cache_auto_clear.dart';
import 'package:pica_comic/tools/log.dart';
import 'package:pica_comic/tools/mouse_listener.dart';
import 'package:pica_comic/tools/proxy.dart';
import 'package:pica_comic/views/auth_page.dart';
import 'package:pica_comic/views/language.dart';
import 'package:pica_comic/views/test_network_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'network/picacg_network/methods.dart';

bool isLogged = false;

void main() {
  runZonedGuarded(
          (){
        WidgetsFlutterBinding.ensureInitialized();
        startClearCache();
        FlutterError.onError = (details){
          LogManager.addLog(LogLevel.error, "Unhandled Exception", "${details.exception}\n${details.stack}");
        };
        appdata.readData().then((b) async {
          isLogged = b;
          if (b) {
            network = PicacgNetwork(appdata.token);
          }
          setNetworkProxy(); //设置代理
          runApp(MyApp());
        });
      },
          (error, stack){
        LogManager.addLog(LogLevel.error, "Unhandled Exception", "$error\n$stack");
      }
  );
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  MyApp({super.key});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
  Widget build(BuildContext context) {
    listenMouseSideButtonToBack();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarContrastEnforced: false
        ));
    WidgetsBinding.instance.addObserver(this);
    downloadManager.init(); //初始化下载管理器
    notifications.init(); //初始化通知管理器
    if (appdata.settings[12] == "1") {
      blockScreenshot();
    }
    return DynamicColorBuilder(builder: (light, dark) {
      lightColorScheme = light;
      dartColorScheme = dark;
      ColorScheme? lightColor;
      ColorScheme? darkColor;
      if(int.parse(appdata.settings[27]) != 0) {
        lightColor = ColorScheme.fromSeed(seedColor: Color(colors[int.parse(appdata.settings[27])-1]), brightness: Brightness.light);
        darkColor = ColorScheme.fromSeed(seedColor: Color(colors[int.parse(appdata.settings[27])-1]), brightness: Brightness.dark);
      }else{
        lightColor = light;
        darkColor = dark;
      }
      return GetMaterialApp(
        title: 'Pica Comic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: lightColor ?? ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
            useMaterial3: true,
            fontFamily: "font"
        ),
        darkTheme: ThemeData(
            colorScheme: darkColor ??
                ColorScheme.fromSeed(seedColor: Colors.pinkAccent, brightness: Brightness.dark),
            useMaterial3: true,
            fontFamily: "font"
        ),
        home: isLogged ? const TestNetworkPage() : const WelcomePage(),
        translations: Translation(),
        locale: PlatformDispatcher.instance.locale,
        fallbackLocale: const Locale('zh','CN'),
        logWriterCallback: (String s, {bool? isError}){
          LogManager.addLog((isError??false)?LogLevel.warning:LogLevel.info, "App Status", s);
        },
        builder: (context, widget){
          ErrorWidget.builder = (details){
            LogManager.addLog(LogLevel.error, "Unhandled Exception", "${details.exception}\n${details.stack}");
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
