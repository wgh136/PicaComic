import 'package:flutter/services.dart';
import 'package:get/get.dart';

void setKeepScreenOn() async{
  if(GetPlatform.isWeb||GetPlatform.isWindows)  return;
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/keepScreenOn");
  await channel.invokeMethod("set");
}

void cancelKeepScreenOn() async{
  if(GetPlatform.isWeb||GetPlatform.isWindows)  return;
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/keepScreenOn");
  await channel.invokeMethod("cancel");
}