import 'package:get/get.dart';
import 'package:flutter/services.dart';

///监听鼠标侧键, 若为下键, 则调用返回
void listenMouseSideButtonToBack() async{
  if(! GetPlatform.isWindows){
    return;
  }
  const channel = EventChannel("kokoiro.xyz.pica_comic/mouse");
  await for(var res in channel.receiveBroadcastStream()){
    if(res == 0){
      Get.back();
    }
  }
}