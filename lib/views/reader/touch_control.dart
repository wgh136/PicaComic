import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'dart:math';
import '../../base.dart';

///Flutter并没有提供能够进行放缩的列表, 在InteractiveViewer放入任何可滚动的组件, InteractiveViewer的手势将会失效.
///此类用于处理滚动事件
class ScrollManager{

  ///缓存滑动偏移值
  double offset = 0;

  ///滚动控制器
  ScrollController scrollController;

  ///小于此值的滑动判定为缓慢滑动
  static const slowMove = 2.0;

  final height = Get.height;

  final maxScrollOnce = Get.height/8;

  ///是否正在进行释放缓存的偏移值
  bool runningRelease = false;

  int fingers = 0;

  bool touching = false;

  ScrollManager(this.scrollController);

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
  }

  ///当滑动时调用此函数进行处理
  void addOffset(double value){
    if(value > 40){
      value = 40;
    }else if(value < -40){
      value = -40;
    }
    if(value*offset < 0){
      offset = 0;
    }
    moveScrollView(value);
  }

  ///响应滑动手势
  void moveScrollView(double value){
    //移动ScrollView
    if(!scrollController.hasClients)  return;
    scrollController.jumpTo(scrollController.position.pixels-value);
    if(value*height/400>slowMove||value*height/400<0-slowMove){
      if(offset < 2000) {
        offset += value*( (value > 1 || value < -1) ? log(value>0?value:0-value) : value>0?value:0-value)*height/200;
      }
      if (!runningRelease) {
        releaseOffset();
      }
    }else{
      offset = 0;
    }
  }

  ///异步函数, 释放缓存的滑动偏移值
  void releaseOffset() async{
    runningRelease = true;
    var logic = Get.find<ComicReadingPageLogic>();
    while(offset!=0){
      //当手指离开时进行滚动
      if(logic.currentScale < 1.05){
        offset = 0;
        break;
      }
      if(!scrollController.hasClients){
        offset = 0;
        runningRelease = false;
        return;
      }
      touching = fingers != 0;
      if(fingers==0){
        if(scrollController.position.pixels<scrollController.position.minScrollExtent || scrollController.position.pixels>scrollController.position.maxScrollExtent){
          offset = 0;
          break;
        }
        if(offset < 3 &&offset > -3){
          offset = 0;
          break;
        }
        var p = offset / 400;
        if(p > 4){
          p = 4;
        }else if(p < -4){
          p = -4;
        }
        double value = log(offset>0?offset:0-offset) * p;
        if(value > maxScrollOnce){
          value = maxScrollOnce;
        }else if(value < 0-maxScrollOnce){
          value = 0-maxScrollOnce;
        }
        scrollController.jumpTo(scrollController.position.pixels - value);
        offset -= value;
      }
      await Future.delayed(const Duration(milliseconds: 8));
    }
    runningRelease = false;
  }
}

class TapController{
  static Offset? _tapOffset;

  static DateTime lastScrollTime = DateTime(2023);

  static void onTapDown(PointerDownEvent event){
    var logic = Get.find<ComicReadingPageLogic>();

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

    if(appdata.settings[9] == "4"){
      logic.data.scrollManager!.tapDown(event);
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

