import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';

import '../tools/device_info.dart';

Future<bool?> checkUpdate() async{
  try {
    var version = appVersion;
    var dio = Dio();
    var res = await dio.get("$serverDomain/version");
    var s = res.data;
    return compareSemVer(s, version); //有更新返回true
  }
  catch(e){
    return null;
  }
}

bool compareSemVer(String ver1, String ver2) {
  List<String> v1 = ver1.split('.'); // 将版本号字符串按照 "." 分割成列表
  List<String> v2 = ver2.split('.');

  for (int i = 0; i < v1.length || i < v2.length; i++) {
    int num1 = i < v1.length ? int.parse(v1[i]) : 0; // 如果已经到达某个版本号结尾，则默认该版本号对应数字为 0
    int num2 = i < v2.length ? int.parse(v2[i]) : 0;

    if (num1 > num2) {
      return true;
    } else if (num1 < num2) {
      return false;
    }
  }

  return false; // 两个版本号相同
}

Future<String?> getUpdatesInfo() async{
  try {
    var dio = Dio();
    var res = await dio.get("$serverDomain/updates");
    var s = res.data;
    return s;
  }
  catch(e){
    return null;
  }
}

Future<String> getDownloadUrl() async{
  var platform = await getDeviceInfo();
  var appName = [
    "app-arm64-v8a-release.apk",
    "app-armeabi-v7a-release.apk",
    "app-universal-release.apk",
    "app-x86-release.apk",
    "app-x86_64-release.apk"
  ];
  int device = 2;
  if(platform == "arm64-v8a"){
    device = 0;
  }else if(platform == "armeabi-v7a"){
    device = 1;
  }else if(platform == "x86_64"){
    device = 3;
  }else if(platform == "x86"){
    device = 4;
  }else if(platform == "Linux" || platform == "iOS" || platform == "windows"){
    return "https://github.com/wgh136/PicaComic/releases";
  }
  return "$serverDomain/download/${appName[device]}";
}