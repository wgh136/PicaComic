import 'package:flutter/services.dart';

void blockScreenshot(){
  const MethodChannel("com.kokoiro.xyz.pica_comic/screenshot").invokeMethod("blockScreenshot");
}