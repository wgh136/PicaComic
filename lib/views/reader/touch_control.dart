import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
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

  final maxScrollOnce = Get.height/7;

  ///是否正在进行释放缓存的偏移值
  bool runningRelease = false;

  int fingers = 0;

  bool touching = false;

  ScrollManager(this.scrollController);

  ///当滑动时调用此函数进行处理
  void addOffset(double value){
    if(value > 30){
      value = 30;
    }else if(value < -30){
      value = -30;
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
        offset += value*( (value > 1 || value < -1) ? log(value>0?value:0-value) : value>0?value:0-value)*height/150;
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
    while(offset!=0){
      //当手指离开时进行滚动
      if(!scrollController.hasClients){
        offset = 0;
        runningRelease = false;
        return;
      }
      if(touching && fingers==0){
        if(scrollController.position.pixels-scrollController.position.maxScrollExtent > 300){
          showMessage(
              Get.context,
              "要切换下一章节吗",
              action: TextButton(
                  onPressed: (){
                    Get.closeCurrentSnackbar();
                    Get.find<ComicReadingPageLogic>().jumpToNextChapter();
                  },
                  child: Text("切换".tr)
              )
          );
        }else if(scrollController.position.pixels-scrollController.position.minScrollExtent < -300){
          showMessage(
              Get.context,
              "要切换上一章节吗",
              action: TextButton(
                  onPressed: (){
                    Get.closeCurrentSnackbar();
                    Get.find<ComicReadingPageLogic>().jumpToLastChapter();
                  },
                  child: Text("切换".tr)
              )
          );
        }
      }
      touching = fingers != 0;
      if(fingers==0){
        if(scrollController.position.pixels<scrollController.position.minScrollExtent || scrollController.position.pixels>scrollController.position.maxScrollExtent){
          offset = 0;
          break;
        }
        if(offset < 2 &&offset > -2){
          offset = 0;
          break;
        }
        var p = offset / 200;
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
      await Future.delayed(const Duration(milliseconds: 12));
    }
    runningRelease = false;
  }
}

Widget buildTapDownListener(ComicReadingPageLogic logic, BuildContext context){
  return Positioned(
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    child: GestureDetector(
      onDoubleTap: (){
        if(appdata.settings[9] == "4"){
          if (logic.showSettings) {
            logic.showSettings = false;
            logic.update();
            return;
          }
          if (!logic.tools) {
            logic.tools = true;
            logic.update();
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            return;
          }else{
            logic.tools = false;
            logic.update();
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          }
        }
      },
      onTapUp: (detail) {
        bool flag = false;
        bool flag2 = false;
        if (appdata.settings[0] == "1" &&
            appdata.settings[9] != "4" &&
            !logic.tools) {
          switch (appdata.settings[9]) {
            case "1":
              detail.globalPosition.dx >
                  MediaQuery.of(context).size.width * 0.75
                  ? logic.jumpToNextPage()
                  : flag = true;
              detail.globalPosition.dx <
                  MediaQuery.of(context).size.width * 0.25
                  ? logic.jumpToLastPage()
                  : flag2 = true;
              break;
            case "2":
              detail.globalPosition.dx >
                  MediaQuery.of(context).size.width * 0.75
                  ? logic.jumpToLastPage()
                  : flag = true;
              detail.globalPosition.dx <
                  MediaQuery.of(context).size.width * 0.25
                  ? logic.jumpToNextPage()
                  : flag2 = true;
              break;
            case "3":
              detail.globalPosition.dy >
                  MediaQuery.of(context).size.height * 0.75
                  ? logic.jumpToNextPage()
                  : flag = true;
              detail.globalPosition.dy <
                  MediaQuery.of(context).size.height * 0.25
                  ? logic.jumpToLastPage()
                  : flag2 = true;
              break;
          }
        } else {
          flag = flag2 = true;
        }
        if (flag && flag2) {
          if(!logic.tools && appdata.settings[9] == "4"){
            return;
          }
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
      },
    ),
  );
}