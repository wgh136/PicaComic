import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/login_page.dart';
import 'package:pica_comic/views/test_network_page.dart';
import 'network/methods.dart';

bool isLogged = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appdata.readData().then((b){
    isLogged = b;
    if(b){
      network = Network(appdata.token);
    }
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return GetMaterialApp(
        title: 'Pica Comic',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: lightColorScheme??ColorScheme.fromSeed(seedColor: Colors.cyanAccent),
          useMaterial3: true,
          fontFamily: 'NotoSansSc'
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme??ColorScheme.fromSeed(seedColor: Colors.black,brightness: Brightness.dark),
          useMaterial3: true,
          fontFamily: GetPlatform.isWindows?'NotoSansSc':null //使用自定义字体解决windows端中文显示糟糕的问题
        ),
        home: isLogged?const TestNetworkPage():const LoginPage(),
      );
    });
  }
}
