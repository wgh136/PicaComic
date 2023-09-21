import 'dart:io';
import 'package:flutter/services.dart';
///用于测试函数
void debug() async{
  var channel = const MethodChannel("pica_comic/title_bar");
  channel.invokeMethod("color", 0x00FF00);
}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s, [String path = "D://debug.json"]) async{
  var file = File(path);
  file.writeAsStringSync(s);
}