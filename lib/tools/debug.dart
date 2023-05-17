import 'dart:io';
import 'package:path_provider/path_provider.dart';

///用于测试函数
void debug() async{
  print(await getTemporaryDirectory());
}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s) async{
  var file = File("D://debug.json");
  file.writeAsStringSync(s);
}