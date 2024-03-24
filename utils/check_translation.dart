import 'dart:convert';
import 'dart:io';

Map<String, dynamic>? translation;

var keys = <String>[];

void main() async{
  var file = File("assets/translation.json");
  var data = await file.readAsString();
  translation = jsonDecode(data);
  find(Directory('lib'));
  file = File("assets/translation.json");
  translation!.forEach((key, value) {
    var shouldRemove = <String>[];
    for (var element in (value as Map<String, dynamic>).keys) {
      if(!keys.contains(element)){
        shouldRemove.add(element);
      }
    }
    for (var element in shouldRemove) {
      value.remove(element);
    }
  });
  file.writeAsString(const JsonEncoder.withIndent("  ").convert(translation));
}

String realText(String text){
  text = text.replaceAll(".tl", "");
  var char = text[text.length-1];
  int index = text.length-2;
  while(true){
    if(text[index] == char){
      if(index > 0 && text[index-1] == '\\'){
        index--;
        continue;
      }
      break;
    }
    index--;
  }
  return text.substring(index+1, text.length-1);
}

void find(Directory directory){
  for(var entity in directory.listSync()){
    if(entity is File){
      var code = entity.readAsStringSync();
      for(var match in RegExp(r'".*?"\.tl').allMatches(code)){
        var text = match.group(0);
        text = realText(text!);
        if(text.isEmpty)  continue;
        keys.add(text);
        if(translation!["zh_TW"][text] == null){
          translation!["zh_TW"][text] = "";
        }
        if(translation!["en_US"][text] == null){
          translation!["en_US"][text] = "";
        }
      }
      for(var match in RegExp(r"'.*?'\.tl").allMatches(code)){
        var text = match.group(0);
        text = realText(text!);
        if(text.isEmpty)  continue;
        keys.add(text);
        if(translation!["zh_TW"][text] == null){
          translation!["zh_TW"][text] = "";
        }
        if(translation!["en_US"][text] == null){
          translation!["en_US"][text] = "";
        }
      }
    } else if (entity is Directory){
      find(entity);
    }
  }
}