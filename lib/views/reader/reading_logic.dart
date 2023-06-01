import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart'
  show ReadingPageData;
import 'package:pica_comic/views/reader/reading_type.dart';
import '../../base.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../widgets/scrollable_list/src/item_positions_listener.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class ComicReadingPageLogic extends GetxController{
  ///控制页面, 用于非从上至下(连续)阅读方式
  final controller = PageController(initialPage: 1);
  ///用于从上至下(连续)阅读方式, 跳转至指定项目
  final scrollController = ItemScrollController();
  ///用于从上至下(连续)阅读方式, 获取当前滚动到的元素的序号
  var scrollListener = ItemPositionsListener.create();
  ///用于非从上至下(连续)阅读方式, 控制滚动
  var cont = ScrollController(keepScrollOffset: false);
  ///用于从上至下(连续)阅读方式, 获取放缩大小
  var transformationController = TransformationController();

  ComicReadingPageLogic(this.order, this.data);

  ReadingPageData data;

  bool isLoading = true;

  ///当前的页面, 0和最后一个为空白页, 用于进行章节跳转
  int index = 1;
  ///当前的章节位置, 从1开始
  int order;
  ///工具栏是否打开
  bool tools = false;
  ///是否显示设置窗口
  bool showSettings = false;
  ///所有的图片链接
  var urls = <String>[];
  ///hitomi阅读使用的图片数据
  var images = <HitomiFile>[];
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
      controller.animateToPage(index+1, duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }else{
      scrollController.jumpTo(index: index);
    }
  }

  void jumpToLastPage(){
    if(appdata.settings[9]!="4") {
      controller.animateToPage(index-1, duration: const Duration(milliseconds: 300), curve: Curves.ease);
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

  void jumpToNextChapter(){
    var type = data.type;
    var eps = data.eps;
    if((order == eps.length - 1 && type == ReadingType.picacg) || eps.isEmpty || (type==ReadingType.jm) && order == eps.length){
      controller.jumpToPage(urls.length);
      showMessage(Get.context, "已经是最后一章了".tr);
      return;
    }else if(type == ReadingType.ehentai || type == ReadingType.hitomi){
      showMessage(Get.context, "已经是最后一章了".tr);
      return;
    }
    order += 1;
    urls.clear();
    isLoading = true;
    tools = false;
    if(type == ReadingType.jm){
      data.target = eps[order-1];
    }
    update();
  }

  void jumpToLastChapter(){
    var type = data.type;
    var eps = data.eps;
    if(order == 1 && type == ReadingType.picacg){
      controller.jumpToPage(1);
      showMessage(Get.context, "已经是第一章了".tr);
      return;
    }else if(order == 1 && type == ReadingType.jm){
      controller.jumpToPage(1);
      showMessage(Get.context, "已经是第一章了".tr);
      return;
    }else if(type == ReadingType.ehentai || type == ReadingType.hitomi){
      showMessage(Get.context, "已经是第一章了".tr);
      return;
    }

    order -= 1;
    urls.clear();
    isLoading = true;
    tools = false;
    if(type == ReadingType.jm){
      data.target = eps[order-1];
    }
    update();
  }

  ///当前章节的长度
  int get length => urls.length;
}