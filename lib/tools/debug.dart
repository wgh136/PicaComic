import 'dart:io';
import 'package:pica_comic/jm_network/jm_main_network.dart';

///用于测试函数
void debug() async{
  var network = JmNetwork();
  network.getLatest(1);
}

///保存网络请求数据, 用于Debug
///
/// 由于内存较长, 不直接打印在终端
void saveDebugData(String s) async{
  var file = File("D://debug.txt");
  file.writeAsStringSync(s);
}