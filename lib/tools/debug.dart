import 'dart:io';
import 'package:dio/dio.dart';
///用于测试函数
void debug() async{

}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s, [String path = "D://debug.json"]) async{
  var file = File(path);
  file.writeAsStringSync(s);
}

void log(String message) async{
  await Dio().post("https://api.kokoiro.xyz/logs", data: message);
}