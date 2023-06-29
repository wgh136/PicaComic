import 'package:flutter/cupertino.dart';

class UiMode{
  static bool m1(BuildContext context){
    //显示底部导航栏
    return MediaQuery.of(context).size.shortestSide<600;
  }

  static bool m2(BuildContext context){
    //显示左侧按钮
    return !(MediaQuery.of(context).size.shortestSide<600)&&!(MediaQuery.of(context).size.width>1300);
  }

  static bool m3(BuildContext context){
    //显示左侧导航栏
    return !(MediaQuery.of(context).size.shortestSide<600)&&(MediaQuery.of(context).size.width>1300);
  }
}