import 'dart:io';

import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';

///用于测试函数
void debug() async{
  for(int i=0;i<10;i++){
    await HtmangaNetwork().addFavorite("210817", "826960");
  }
}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s) async{
  var file = File("D://debug.json");
  file.writeAsStringSync(s);
}