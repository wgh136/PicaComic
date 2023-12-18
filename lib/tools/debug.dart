import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/views/widgets/loading.dart';

///用于测试函数
void debug() async {
  var controller = showLoadingDialog(App.globalContext!, () { });
  showDialog(context: App.globalContext!, builder: (context) => const Dialog(child: SizedBox(width: 400, height: 400,),));
  await Future.delayed(const Duration(milliseconds: 400));
  controller.close();
}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s, [String path = "D://debug.json"]) async {
  var file = File(path);
  file.writeAsStringSync(s);
}

void log(String message) async {
  await Dio().post("https://api.kokoiro.xyz/logs", data: message);
}
