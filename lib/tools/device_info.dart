import 'package:flutter/services.dart';
import 'package:get/get.dart';

Future<String> getDeviceInfo() async{
  //获取cpu架构
  if(GetPlatform.isWindows) return "windows";
  if(GetPlatform.isWeb) return "web";
  if(GetPlatform.isIOS) return "iOS";
  if(!GetPlatform.isAndroid)  return "Unknown";
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/device");
  return await channel.invokeMethod("get");
}