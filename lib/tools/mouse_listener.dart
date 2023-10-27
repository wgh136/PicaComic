import 'package:flutter/services.dart';
import 'package:pica_comic/views/main_page.dart';
import '../foundation/app.dart';

void mouseSideButtonCallback(){
  if(App.canPop){
    App.globalBack();
  }else{
    MainPage.back();
  }
}

///监听鼠标侧键, 若为下键, 则调用返回
void listenMouseSideButtonToBack() async{
  if(!App.isWindows){
    return;
  }
  const channel = EventChannel("kokoiro.xyz.pica_comic/mouse");
  await for(var res in channel.receiveBroadcastStream()){
    if(res == 0){
      mouseSideButtonCallback();
    }
  }
}