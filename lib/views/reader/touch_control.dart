import 'package:flutter/cupertino.dart';

///Flutter并没有提供能够进行放缩的列表, 在InteractiveViewer放入任何可滚动的组件, InteractiveViewer的手势将会失效.
///此类用于处理滚动事件
class ScrollManager{

  ///缓存滑动偏移值
  double offset = 0;

  ///滚动控制器
  ScrollController scrollController;

  ///小于此值的滑动判定为缓慢滑动
  static const slowMove = 2.0;

  ///是否正在进行释放缓存的偏移值
  bool runningRelease = false;

  int fingers = 0;

  ScrollManager(this.scrollController);

  ///当滑动时调用此函数进行处理
  void addOffset(double value){
    moveScrollView(value);
  }

  ///响应滑动手势
  void moveScrollView(double value){
    //移动ScrollView
    scrollController.jumpTo(scrollController.position.pixels-value);
    if(value>slowMove||value<0-slowMove){
      offset += value*value*(value~/1)/10;//(((offset ~/200)>0?(offset ~/200):(0 - offset ~/200)) + 4);
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
      if(fingers==0){
        if(scrollController.position.pixels<scrollController.position.minScrollExtent || scrollController.position.pixels>scrollController.position.maxScrollExtent){
          offset = 0;
          break;
        }
        if(offset < 0.5&&offset > -0.5){
          moveScrollView(offset);
          offset = 0;
          break;
        }
        var value = offset / 20;
        if(value > 60){
          value = 60;
        }else if(value < -60){
          value = -60;
        }
        scrollController.jumpTo(scrollController.position.pixels - value);
        offset -= value;
      }
      await Future.delayed(const Duration(milliseconds: 8));
    }
    runningRelease = false;
  }
}