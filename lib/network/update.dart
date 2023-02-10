import 'package:device_info/device_info.dart';
import 'package:dio/dio.dart';

Future<bool?> checkUpdate() async{
  try {
    var version = "1.1.5";
    var dio = Dio();
    var res = await dio.get("https://api.kokoiro.xyz/version");
    var s = res.data;
    return version == s ? false : true; //有更新返回true
  }
  catch(e){
    return null;
  }
}

Future<String> getDeviceInfo() async{
  var deviceInfo = DeviceInfoPlugin();
  var platform = await deviceInfo.androidInfo;
  return platform.supportedAbis[0];
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
  }
  return "https://api.kokoiro.xyz/download/${appName[device]}";
}