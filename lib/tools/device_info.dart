import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';

Future<String> getDeviceInfo() async{
  //获取cpu架构
  if(App.isWindows) return "windows";
  if(App.isIOS) return "iOS";
  if(!App.isAndroid)  return "Unknown";
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/device");
  return await channel.invokeMethod("get");
}