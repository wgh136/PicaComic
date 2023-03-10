import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/block_screenshot.dart';
import 'package:pica_comic/tools/proxy.dart';
import 'package:pica_comic/views/auth_page.dart';
import 'package:pica_comic/views/test_network_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'network/methods.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
bool isLogged = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appdata.readData().then((b) async {
    isLogged = b;
    if(b){
      network = Network(appdata.token);
    }
    setImageProxy(); //设置图片加载代理
    await SentryFlutter.init(
          (options) {
        options.dsn = 'https://89c7cb794fd946dfbb95cf210a4051e8@o4504661097119744.ingest.sentry.io/4504661099675648';
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
      },
      appRunner: () async{
        runApp(MyApp());
      },
    );
  });

}

class MyApp extends StatelessWidget with WidgetsBindingObserver{
  MyApp({super.key});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if(appdata.settings[13]=="1"&&appdata.flag){
        appdata.flag = false;
        Get.to(()=>const AuthPage());
      }
    } else if(state == AppLifecycleState.paused){
      appdata.flag = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);
    downloadManager.init(); //初始化下载管理器
    notifications.init(); //初始化通知管理器
    if(appdata.settings[12]=="1") {
      blockScreenshot();
    }
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return GetMaterialApp(
        title: 'Pica Comic',
        scrollBehavior: const MaterialScrollBehavior().copyWith(
            scrollbars: true,
            dragDevices: _kTouchLikeDeviceTypes
        ),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: lightColorScheme??ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          useMaterial3: true,
          fontFamily: 'font'
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme??ColorScheme.fromSeed(seedColor: Colors.pinkAccent,brightness: Brightness.dark),
          useMaterial3: true,
          fontFamily: 'font'
        ),
        home: isLogged?const TestNetworkPage():const WelcomePage(),
      );
    });
  }
}

const Set<PointerDeviceKind> _kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.mouse,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown
};
