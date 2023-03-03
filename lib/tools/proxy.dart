import 'package:flutter/services.dart';

Future<String?> getWindowsProxy() async{
  const channel = MethodChannel("kokoiro.xyz.pica_comic/proxy");
  var res = await channel.invokeMethod("getProxy");
  return res;
}