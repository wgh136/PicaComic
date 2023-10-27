import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';


void setKeepScreenOn() async{
  if(App.isWindows)  return;
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/keepScreenOn");
  await channel.invokeMethod("set");
}

void cancelKeepScreenOn() async{
  if(App.isWindows)  return;
  var channel = const MethodChannel("com.kokoiro.xyz.pica_comic/keepScreenOn");
  await channel.invokeMethod("cancel");
}