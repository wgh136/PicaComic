import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/login_page.dart';
import 'package:pica_comic/views/test_network_page.dart';
import 'network/methods.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:http/http.dart';

bool isLogged = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  appdata.readData().then((b) async {
    isLogged = b;
    if(b){
      network = Network(appdata.token);
    }
    await SentryFlutter.init(
          (options) {
        options.dsn = 'https://89c7cb794fd946dfbb95cf210a4051e8@o4504661097119744.ingest.sentry.io/4504661099675648';
        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0;
      },
      appRunner: () => runApp(MyApp()),
    );
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
