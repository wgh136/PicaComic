import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';

String timeToString(DateTime time){
  var current = DateTime.now();
  if(current.millisecondsSinceEpoch < time.millisecondsSinceEpoch){
    return "Error";
  }
  if(current.difference(time).inDays > 360){
    return "@year 年前".tlParams({"year": (current.difference(time).inDays ~/ 360).toString()});
  }else if(current.difference(time).inDays > 30){
    return "@month 个月前".trParams({"month": (current.difference(time).inDays ~/ 30).toString()});
  }else if(current.difference(time).inHours > 24){
    return "@day 天前".tlParams({"day": (current.difference(time).inDays).toString()});
  }else if(current.difference(time).inMinutes > 60){
    return "@hour 小时前".tlParams({"hour": (current.difference(time).inHours).toString()});
  }else if(current.difference(time).inSeconds > 60){
    return "@minute 分钟前".tlParams({"minute": (current.difference(time).inMinutes).toString()});
  }else{
    return "刚刚".tl;
  }
}

extension TimeExtension on DateTime{
  Duration operator-(DateTime other){
    return Duration(microseconds: microsecondsSinceEpoch - other.microsecondsSinceEpoch);
  }
}