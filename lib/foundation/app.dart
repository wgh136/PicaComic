import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/foundation/app_page_route.dart';
import 'package:pica_comic/foundation/log.dart';
import '../base.dart';

export 'state_controller.dart';
export 'widget_utils.dart';

class App {
  // platform
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;
  static bool get isLinux => Platform.isLinux;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;

  static BuildContext? get globalContext => navigatorKey.currentContext;

  static final messageKey = GlobalKey<ScaffoldMessengerState>();

  static final navigatorKey = GlobalKey<NavigatorState>();

  /// get ui mode
  static UiModes uiMode([BuildContext? context]) {
    context ??= globalContext;
    if (MediaQuery.of(context!).size.shortestSide < 600) {
      return UiModes.m1;
    } else if (!(MediaQuery.of(context).size.shortestSide < 600) &&
        !(MediaQuery.of(context).size.width > 1400)) {
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

  static Future<void> init() async {
    cachePath = (await getApplicationCacheDirectory()).path;
    dataPath = (await getApplicationSupportDirectory()).path;
  }

  static back(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  static globalBack() {
    if (Navigator.canPop(globalContext!)) {
      Navigator.of(globalContext!).pop();
    }
  }

  static off(BuildContext context, Widget Function() page) {
    LogManager.addLog(LogLevel.info, "App Status",
        "Going to Page /${page.runtimeType.toString().replaceFirst("() => ", "")}");
    Navigator.of(context).pushReplacement(AppPageRoute(page));
  }

  static globalOff(Widget Function() page) {
    LogManager.addLog(LogLevel.info, "App Status",
        "Going to Page /${page.runtimeType.toString().replaceFirst("() => ", "")}");
    Navigator.of(globalContext!).pushReplacement(AppPageRoute(page));
  }

  static offAll(Widget Function() page) {
    Navigator.of(globalContext!)
        .pushAndRemoveUntil(AppPageRoute(page), (route) => false);
  }

  static Future<T?> to<T extends Object?>(BuildContext context, Widget Function() page,
      [bool enableIOSGesture = true]) {
    LogManager.addLog(LogLevel.info, "App Status",
        "Going to Page /${page.runtimeType.toString().replaceFirst("() => ", "")}");
    return Navigator.of(context).push<T>(AppPageRoute(page, enableIOSGesture));
  }

  static Future<T?> globalTo<T extends Object?>(Widget Function() page, {bool preventDuplicates = false}) {
    return Navigator.of(globalContext!).push<T>(AppPageRoute(page));
  }

  static bool get enablePopGesture => isIOS;

  static String? _currentRoute() {
    return ModalRoute.of(globalContext!)?.toString();
  }

  static String? get currentRoute => _currentRoute();

  static bool get canPop => Navigator.of(globalContext!).canPop();

  static bool temporaryDisablePopGesture = false;

  static Locale get locale => () {
        return switch (appdata.settings[50]) {
          "cn" => const Locale("zh", "CN"),
          "tw" => const Locale("zh", "TW"),
          "en" => const Locale("en", "US"),
          _ => PlatformDispatcher.instance.locale,
        };
      }.call();


  /// size of screen
  static Size screenSize(BuildContext context) => MediaQuery.of(context).size;

  static ColorScheme colors(BuildContext context) => Theme.of(context).colorScheme;
}

enum UiModes {
  /// The screen have a short width. Usually the device is phone.
  m1,

  /// The screen's width is medium size. Usually the device is tablet.
  m2,

  /// The screen's width is long. Usually the device is PC.
  m3
}
