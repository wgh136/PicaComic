import 'package:flutter/services.dart';

void setKeepScreenOn() async{
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/keepScreenOn");
  await channel.invokeMethod("set");
}

void cancelKeepScreenOn() async{
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/keepScreenOn");
  await channel.invokeMethod("cancel");
}