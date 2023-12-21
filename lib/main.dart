import 'dart:async';
import 'dart:io';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/init.dart';
import 'package:pica_comic/tools/block_screenshot.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/mouse_listener.dart';
import 'package:pica_comic/network/http_client.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/app_views/auth_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'network/picacg_network/methods.dart';
import 'network/webdav.dart';

bool notFirstUse = false;

void main(){
  runZonedGuarded(() async{
    WidgetsFlutterBinding.ensureInitialized();
    await init();
    FlutterError.onError = (details) {
      LogManager.addLog(LogLevel.error, "Unhandled Exception",
          "${details.exception}\n${details.stack}");
    };
    notFirstUse = appdata.firstUse[3] == "1";
    network = PicacgNetwork(appdata.token);
    setNetworkProxy();
    runApp(const MyApp());
  }, (error, stack) {
    LogManager.addLog(LogLevel.error, "Unhandled Exception", "$error\n$stack");
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void Function()? updater;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime time = DateTime.fromMillisecondsSinceEpoch(0);

  bool forceRebuild = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (App.isAndroid && appdata.settings[38] == "1") {
      try {
        FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        // ignore
      }
    }
    setNetworkProxy(); //当App从后台进入前台, 代理设置可能发生变更
    if (state == AppLifecycleState.resumed) {
      if (appdata.settings[13] == "1" && appdata.flag && !AuthPage.lock) {
        appdata.flag = false;
        App.to(App.globalContext!, () => const AuthPage());
      }
    } else if (state == AppLifecycleState.paused) {
      appdata.flag = true;
    }

    if (DateTime.now().millisecondsSinceEpoch - time.millisecondsSinceEpoch >
        7200000) {
      JmNetwork().loginFromAppdata();
      Webdav.syncData();
      time = DateTime.now();
    }

    App.onAppLifeCircleChanged?.call();
  }

  @override
  void initState() {
    MyApp.updater = () => setState(() {
          forceRebuild = true;
        });
    time = DateTime.now();
    TagsTranslation.readData();
    if (App.isAndroid && appdata.settings[38] == "1") {
      try {
        FlutterDisplayMode.setHighRefreshRate();
      } catch (e) {
        // ignore
      }
    }
    listenMouseSideButtonToBack();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.addObserver(this);
    notifications.init();
    if (appdata.settings[12] == "1") {
      blockScreenshot();
    }
    super.initState();
  }

  @override
  void didChangePlatformBrightness() {
    final Brightness brightness =
        View.of(context).platformDispatcher.platformBrightness;
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
    if (forceRebuild) {
      forceRebuild = false;
      void rebuild(Element el) {
        el.markNeedsBuild();
        el.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    }

    final Brightness brightness =
        View.of(context).platformDispatcher.platformBrightness;
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
      return MaterialApp(
        title: 'Pica Comic',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: App.messageKey,
        navigatorKey: App.navigatorKey,
        theme: ThemeData(
          colorScheme: (colorScheme ??
              lightColor ??
              ColorScheme.fromSeed(seedColor: Colors.pinkAccent)),
          useMaterial3: true,
          fontFamily: App.isWindows ? "font" : "",
        ),
        darkTheme: ThemeData(
          colorScheme: (colorScheme ??
              darkColor ??
              ColorScheme.fromSeed(
                  seedColor: Colors.pinkAccent, brightness: Brightness.dark)),
          useMaterial3: true,
          fontFamily: App.isWindows ? "font" : "",
        ),
        home: notFirstUse
            ? (appdata.settings[13] == "1"
                ? const AuthPage()
                : const MainPage())
            : const WelcomePage(),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'),
          Locale('zh', 'TW'),
          Locale('en', 'US')
        ],
        builder: (context, widget) {
          if (Platform.isWindows) {
            var channel = const MethodChannel("pica_comic/title_bar");
            channel.invokeMethod(
                "color", Theme.of(context).colorScheme.surface.value);
          }
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
