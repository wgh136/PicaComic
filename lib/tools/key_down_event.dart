import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ListenVolumeController{
  void Function() whenUp;
  void Function() whenDown;
  static const channel = EventChannel("com.kokoiro.xyz.pica_comic/volume");
  StreamSubscription? _streamSubscription;

  ListenVolumeController(this.whenUp,this.whenDown);

  void listenVolumeChange(){
    if(GetPlatform.isWeb||GetPlatform.isWindows)  return;
    _streamSubscription = channel.receiveBroadcastStream().listen((event) {
      if(event == 1){
        whenUp();
      }else if(event==2){
        whenDown();
      }
    });
  }

  void stop(){
    if(GetPlatform.isWeb||GetPlatform.isWindows)  return;
    _streamSubscription?.cancel();
  }
}

