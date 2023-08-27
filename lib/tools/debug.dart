import 'dart:io';
import 'package:html/parser.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/nhentai_network/tags.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/tags_translation.dart';

///用于测试函数
void debug() async{
  var idToName = "";
  var enToCN = "";
  for(int i = 1; i < 3; i++){
    var res = await NhentaiNetwork().get("https://nhentai.net/characters/popular?page=$i");
    if(res.error){
      await Future.delayed(const Duration(milliseconds: 500));
      res = await NhentaiNetwork().get("https://nhentai.net/characters/popular??page=$i");
    }
    var document = parse(res.data);
    var elements = document.querySelectorAll("div#tag-container > a");
    for(var e in elements){
      var name = e.querySelector("span.name")!.text;
      var id = e.className.nums;
      if(nhentaiTags[id] == null) {
        idToName += "\"$id\":\"$name\",\n";
      }
      if(name.translateTagsToCN == name){
        enToCN += "\"$name\": \"\",\n";
      }
    }
  }
  saveDebugData(idToName);
  saveDebugData(enToCN, "D://debug2.txt");
}

///保存网络请求数据, 用于Debug
///
/// 由于较长, 不直接打印在终端
void saveDebugData(String s, [String path = "D://debug.txt"]) async{
  var file = File(path);
  file.writeAsStringSync(s);
}