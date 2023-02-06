import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/login_page.dart';
import 'network/methods.dart';
import 'views/main_page.dart';

bool isLogged = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appdata.readData().then((b){
    isLogged = b;
    if(b){
      network = Network(appdata.token);
      network.getProfile().then((p){
        if(p!=null) {
          appdata.user = p;
          appdata.writeData();
        }
        runApp(const MyApp());
      });
    }else{
      runApp(const MyApp());
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return GetMaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: lightColorScheme,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: darkColorScheme,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.light,
        home: isLogged?const MainPage():const LoginPage(),
      );
    });
  }
}
