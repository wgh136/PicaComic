import 'dart:io';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';


///用于测试函数
void debug() async{
  var res = await HiNetwork().search("blue", 1);
  print(res.subData);
}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s) async{
  var file = File("D://debug.json");
  file.writeAsStringSync(s);
}