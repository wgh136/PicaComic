import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import '../../base.dart';

/// Control scroll when readingMethod is [ReadingMethod.topToBottomContinuously]
/// and the image has been enlarge
class ScrollManager{

  PhotoViewController controller;

  int fingers = 0;

  ScrollManager(this.controller);

  Offset? tapLocation;

  void tapDown(PointerDownEvent details){
    fingers++;
    var logic = Get.find<ComicReadingPageLogic>();
    var temp = logic.noScroll;
    logic.noScroll = fingers >= 2;
    if(temp != logic.noScroll){
      logic.update();
    }
  }

  void tapUp(PointerUpEvent details){
    fingers--;
    if(fingers < 0){
      fingers = 0;
    }
    var logic = Get.find<ComicReadingPageLogic>();
    var temp = logic.noScroll;
    logic.noScroll = fingers >= 2;
    if(temp != logic.noScroll){
      logic.update();
    }
    tapLocation = null;
  }

  ///当滑动时调用此函数进行处理
  void addOffset(Offset value){
    controller.updateMultiple(
      position: controller.position + value
    );
    return;
  }
}

class TapController{
  static Offset? _tapOffset;

  static DateTime lastScrollTime = DateTime(2023);

  static void onTapDown(PointerDownEvent event){
    var logic = Get.find<ComicReadingPageLogic>();

    if(appdata.settings[9] == "4"){
      logic.data.scrollManager!.tapDown(event);
    }

    if(logic.tools && (event.position.dy < MediaQuery.of(Get.context!).padding.top  + 50
        || MediaQuery.of(Get.context!).size.height - event.position.dy < 105 + MediaQuery.of(Get.context!).padding.bottom)){
      return;
    }

    if(event.buttons == kSecondaryMouseButton){
      if (logic.showSettings) {
        logic.showSettings = false;
        logic.update();
        return;
      }
      logic.tools = !logic.tools;
      logic.update();
      if (logic.tools) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
      return;
    }

    if(!logic.scrollController.hasClients){
      _tapOffset = event.position;
    }
    else if(logic.scrollController.hasClients && (DateTime.now() - lastScrollTime).inMilliseconds > 50){
      _tapOffset = event.position;
    }
  }

  static void onTapUp(PointerUpEvent detail){
    var logic = Get.find<ComicReadingPageLogic>();

    if(appdata.settings[9] == "4"){
      logic.data.scrollManager!.tapUp(detail);
    }

    var context = Get.context!;
    if(_tapOffset != null){
      var distance = detail.position.dy - _tapOffset!.dy;
      if(distance > 0.1 || distance < -0.1){
        return;
      }
      _tapOffset = null;
    }else{
      return;
    }
    bool flag = false;
    bool flag2 = false;
    final range = int.parse(appdata.settings[40]) / 100;
    if (appdata.settings[0] == "1" &&
        !logic.tools) {
      switch (appdata.settings[9]) {
        case "1":
        case "5":
          detail.position.dx >
              MediaQuery.of(context).size.width * (1 - range)
              ? logic.jumpToNextPage()
              : flag = true;
          detail.position.dx <
              MediaQuery.of(context).size.width * range
              ? logic.jumpToLastPage()
              : flag2 = true;
          break;
        case "2":
        case "6":
          detail.position.dx >
              MediaQuery.of(context).size.width * (1 - range)
              ? logic.jumpToLastPage()
              : flag = true;
          detail.position.dx <
              MediaQuery.of(context).size.width * range
              ? logic.jumpToNextPage()
              : flag2 = true;
          break;
        case "3":
          detail.position.dy >
              MediaQuery.of(context).size.height * (1 - range)
              ? logic.jumpToNextPage()
              : flag = true;
          detail.position.dy <
              MediaQuery.of(context).size.height * range
              ? logic.jumpToLastPage()
              : flag2 = true;
          break;
        case "4":
          detail.position.dy >
              MediaQuery.of(context).size.height * (1 - range)
              ? logic.jumpToNextPage()
              : flag = true;
          detail.position.dy <
              MediaQuery.of(context).size.height * range
              ? logic.jumpToLastPage()
              : flag2 = true;
          break;
      }
    } else {
      flag = flag2 = true;
    }
    if (flag && flag2) {
      if (logic.showSettings) {
        logic.showSettings = false;
        logic.update();
        return;
      }
      logic.tools = !logic.tools;
      logic.update();
      if (logic.tools) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    }
  }
}

