import 'dart:ui';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/block_screenshot.dart';
import 'package:pica_comic/tools/proxy.dart';
import 'package:pica_comic/views/auth_page.dart';
import 'package:pica_comic/views/test_network_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'network/methods.dart';
bool isLogged = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appdata.readData().then((b) async {
    isLogged = b;
    if(b){
      network = Network(appdata.token);
    }
    setNetworkProxy(); //设置代理
    runApp(MyApp());
  });

}

class MyApp extends StatelessWidget with WidgetsBindingObserver{
  MyApp({super.key});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    setNetworkProxy();//当App从后台进入前台, 代理设置可能发生变更
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(this);
    downloadManager.init(); //初始化下载管理器
    notifications.init();   //初始化通知管理器
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
          fontFamily: "font"
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme??ColorScheme.fromSeed(seedColor: Colors.pinkAccent,brightness: Brightness.dark),
          useMaterial3: true,
          fontFamily: "font"
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
