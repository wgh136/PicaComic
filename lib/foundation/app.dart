import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

import '../base.dart';

class App{
  // platform
  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;
  static bool get isWindows => Platform.isWindows;

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
  static double get comicTileMaxWidth =>  [630.0, 200.0, 150.0][int.parse(appdata.settings[44])];
  //ComicTile的宽高比
  static double get comicTileAspectRatio => [3.0, 0.68, 0.68][int.parse(appdata.settings[44])];
}

enum UiModes{
  /// The screen have a short width. Usually the device is phone.
  m1,
  /// The screen's width is medium size. Usually the device is tablet.
  m2,
  /// The screen's width is long. Usually the device is PC.
  m3
}