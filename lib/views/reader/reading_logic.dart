import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../base.dart';
import '../widgets/scrollable_list/src/item_positions_listener.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';

class ComicReadingPageLogic extends GetxController{
  ///控制页面, 用于非从上至下(连续)阅读方式
  final controller = PageController(initialPage: 1);
  ///用于非从上至下(连续)阅读方式, 跳转至指定项目
  final scrollController = ItemScrollController();
  ///用于非从上至下(连续)阅读方式, 获取当前滚动到的元素的序号
  var scrollListener = ItemPositionsListener.create();
  ///用于非从上至下(连续)阅读方式, 控制滚动
  var cont = ScrollController(keepScrollOffset: false);
  ///用于非从上至下(连续)阅读方式, 获取放缩大小
  var transformationController = TransformationController();

  ComicReadingPageLogic(this.order);

  bool isLoading = true;

  ///当前的页面, 0和最后一个为空白页, 用于进行章节跳转
  int index = 1;
  ///当前的章节位置
  int order;
  ///工具栏是否打开
  bool tools = false;
  ///是否显示设置窗口
  bool showSettings = false;
  ///所有的图片链接
  var urls = <String>[];
  ///章节部件
  var epsWidgets = <Widget>[];
  ///是否是已下载的漫画
  bool downloaded = false;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void jumpToNextPage(){
    if(appdata.settings[9]!="4") {
      controller.jumpToPage(index+1);
    }else{
      scrollController.jumpTo(index: index);
    }
  }

  void jumpToLastPage(){
    if(appdata.settings[9]!="4") {
      controller.jumpToPage(index-1);
    }else{
      scrollController.jumpTo(index: index-2);
    }
  }

  void jumpToPage(int i){
    if(appdata.settings[9]!="4") {
      controller.jumpToPage(i);
    }else{
      scrollController.jumpTo(index: i-1);
    }
  }

  int get length => urls.length;
}