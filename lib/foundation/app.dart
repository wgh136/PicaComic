import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/foundation/app_page_route.dart';
import 'package:pica_comic/foundation/log.dart';
import '../base.dart';

export 'state_controller.dart';

class App{
  // platform
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static BuildContext? get globalContext => navigatorKey.currentContext;

  static final messageKey = GlobalKey<ScaffoldMessengerState>();

  static final navigatorKey = GlobalKey<NavigatorState>();

  /// get ui mode
  static UiModes uiMode(BuildContext context){
    if(MediaQuery.of(context).size.shortestSide<600){
      return UiModes.m1;
    } else if(!(MediaQuery.of(context).size.shortestSide<600)&&!(MediaQuery.of(context).size.width>1300)){
      return UiModes.m2;
    } else {
      return UiModes.m3;
    }
  }

  /// Path to store app cache.
  ///
  /// **Warning: The end of String is not '/'**
  static late final String cachePath;

  /// Path to store app data.
  ///
  /// **Warning: The end of String is not '/'**
  static late final String dataPath;

  static init() async{
    cachePath = (await getApplicationCacheDirectory()).path;
    dataPath = (await getApplicationSupportDirectory()).path;
  }

  //ComicTile的最大宽度
  static double get comicTileMaxWidth =>
      [680.0, 200.0, 150.0, 720.0][int.parse(appdata.settings[44])];
  //ComicTile的宽高比
  static double get comicTileAspectRatio =>
      [3.0, 0.68, 0.68, 2.5][int.parse(appdata.settings[44])];

  static back(BuildContext context){
    if(Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  static globalBack(){
    if(Navigator.canPop(globalContext!)) {
      Navigator.of(globalContext!).pop();
    }
  }

  static off(BuildContext context, Widget Function() page){
    LogManager.addLog(LogLevel.info, "App Status", "Going to Page /${page.runtimeType.toString().replaceFirst("() => ", "")}");
    Navigator.of(context).pushReplacement(AppPageRoute(page));
  }

  static globalOff(Widget Function() page){
    LogManager.addLog(LogLevel.info, "App Status", "Going to Page /${page.runtimeType.toString().replaceFirst("() => ", "")}");
    Navigator.of(globalContext!).pushReplacement(AppPageRoute(page));
  }

  static offAll(Widget Function() page){
    Navigator.of(globalContext!).pushAndRemoveUntil(AppPageRoute(page), (route) => false);
  }

  static to(BuildContext context, Widget Function() page){
    LogManager.addLog(LogLevel.info, "App Status", "Going to Page /${page.runtimeType.toString().replaceFirst("() => ", "")}");
    Navigator.of(context).push(AppPageRoute(page));
  }

  static globalTo(Widget Function() page, {bool preventDuplicates = false}){
    Navigator.of(globalContext!).push(AppPageRoute(page));
  }

  static bool get enablePopGesture => true;

  static String? _currentRoute(){
    return ModalRoute.of(globalContext!)?.toString();
  }

  static String? get currentRoute => _currentRoute();

  static bool get canPop => Navigator.of(globalContext!).canPop();
}

enum UiModes{
  /// The screen have a short width. Usually the device is phone.
  m1,
  /// The screen's width is medium size. Usually the device is tablet.
  m2,
  /// The screen's width is long. Usually the device is PC.
  m3
}