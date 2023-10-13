import 'dart:convert';
import 'dart:io';

/// Download tags from https://github.com/EhTagTranslation/DatabaseReleases.git
void main() async{
  await Process.run("git", ["clone", "https://github.com/EhTagTranslation/DatabaseReleases.git"]);
  var file = File("DatabaseReleases/db.text.json");
  var db = const JsonDecoder().convert(file.readAsStringSync());
  Map<String, Map<String, String>> res = {};
  for(var category in db["data"]){
    Map<String, String> items = {};
    for(var entry in (category["data"] as Map).entries){
      items[entry.key] = entry.value["name"];
    }
    res[category["namespace"]] = items;
  }
  var output = const JsonEncoder().convert(res);
  File("assets/tags.json").writeAsStringSync(output);
  Directory("DatabaseReleases").deleteSync(recursive: true);
}