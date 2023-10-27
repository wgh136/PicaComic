import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart'
  show ReadingPageData;
import 'package:pica_comic/views/reader/reading_type.dart';
import '../../base.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../widgets/scrollable_list/src/item_positions_listener.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class ComicReadingPageLogic extends StateController{
  ///控制页面, 用于非从上至下(连续)阅读方式
  PageController pageController;
  ///用于从上至下(连续)阅读方式, 跳转至指定项目
  var itemScrollController = ItemScrollController();
  ///用于从上至下(连续)阅读方式, 获取当前滚动到的元素的序号
  var itemScrollListener = ItemPositionsListener.create();
  ///用于从上至下(连续)阅读方式, 控制滚动
  var scrollController = ScrollController(keepScrollOffset: true);
  ///用于从上至下(连续)阅读方式, 获取放缩大小
  var photoViewController = PhotoViewController();

  bool noScroll = false;

  bool mouseScroll = App.isDesktop;

  double currentScale = 1.0;

  bool isCtrlPressed = false;

  static int _getIndex(int initPage){
   if(appdata.settings[9] == "5" || appdata.settings[9] == "6"){
     return initPage % 2 == 1 ? initPage : initPage-1;
   }else{
     return initPage;
   }
  }

  static int _getPage(int initPage){
    if(appdata.settings[9] == "5" || appdata.settings[9] == "6"){
      return (initPage + 2) ~/ 2;
    }else{
      return initPage;
    }
  }

  ComicReadingPageLogic(this.order, this.data):
     pageController = PageController(initialPage: _getPage(data.initialPage)),
     index = _getIndex(data.initialPage);

  ReadingPageData data;

  bool isLoading = true;

  ///旋转方向: null-跟随系统, false-竖向, true-横向
  bool? rotation;

  ///是否应该显示悬浮按钮, 为-1表示显示上一章, 为0表示不显示, 为1表示显示下一章
  int showFloatingButtonValue = 0;

  void showFloatingButton(int value){
    if(value == 0) {
      if(showFloatingButtonValue != 0){
        showFloatingButtonValue = 0;
        update();
      }
    }
    if(value == 1 && showFloatingButtonValue == 0){
      showFloatingButtonValue = 1;
      update();
    }else if(value == -1 && showFloatingButtonValue == 0 && order!=1){
      showFloatingButtonValue = -1;
      update();
    }
  }

  ///当前的页面, 0和最后一个为空白页, 用于进行章节跳转
  int index;
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

  void reload(){
    index = 1;
    data.initialPage = 1;
    pageController = PageController(initialPage: 1);
    isLoading = true;
    update();
  }

  void change(){
    isLoading = !isLoading;
    update();
  }

  ReadingMethod get readingMethod => ReadingMethod.values[int.parse(appdata.settings[9])-1];

  void jumpToNextPage(){
    if(appdata.settings[36] == "1") {
      if (readingMethod.index < 3) {
        pageController.animateToPage(
            index + 1, duration: const Duration(milliseconds: 300),
            curve: Curves.ease);
      } else if(readingMethod == ReadingMethod.topToBottomContinuously){
        scrollController.animateTo(scrollController.position.pixels + 600,
            duration: const Duration(milliseconds: 200), curve: Curves.ease);
      } else {
        pageController.animateToPage(
            (index + 2) ~/ 2 + 1, duration: const Duration(milliseconds: 300),
            curve: Curves.ease);
      }
    }else{
      if (readingMethod.index < 3) {
        pageController.jumpToPage(index + 1);
      } else if(readingMethod == ReadingMethod.topToBottomContinuously) {
        scrollController.jumpTo(scrollController.position.pixels + 600);
      } else {
        pageController.jumpToPage((index+1) ~/ 2 + 1);
      }
    }
  }

  void jumpToLastPage(){
    if(appdata.settings[36] == "1") {
      if (readingMethod.index < 3) {
        pageController.animateToPage(
            index - 1, duration: const Duration(milliseconds: 300),
            curve: Curves.ease);
      } else if(readingMethod == ReadingMethod.topToBottomContinuously){
        scrollController.animateTo(scrollController.position.pixels - 600,
            duration: const Duration(milliseconds: 200), curve: Curves.ease);
      } else {
        pageController.animateToPage(
            index ~/ 2, duration: const Duration(milliseconds: 300),
            curve: Curves.ease);
      }
    }else{
      if (readingMethod.index < 3) {
        pageController.jumpToPage(index - 1);
      } else if(readingMethod == ReadingMethod.topToBottomContinuously) {
        scrollController.jumpTo(scrollController.position.pixels - 600);
      } else {
        pageController.jumpToPage(index ~/ 2);
      }
    }
  }

  void jumpToPage(int i){
    if(appdata.settings[9]!="4") {
      pageController.jumpToPage(i);
    }else{
      itemScrollController.jumpTo(index: i-1);
    }
  }

  void jumpToNextChapter(){
    data.initialPage = 1;
    var type = data.type;
    var eps = data.eps;
    eps.remove("");
    showFloatingButtonValue = 0;
    if(eps.isEmpty || order == eps.length){
      if(readingMethod.index < 3) {
        pageController.jumpToPage(urls.length);
      }else if(readingMethod == ReadingMethod.twoPage){
        pageController.jumpToPage((urls.length % 2 + urls.length) ~/ 2);
      }
      showMessage(App.globalContext, "已经是最后一章了".tl);
      return;
    }else if(!type.hasEps){
      showMessage(App.globalContext, "已经是最后一章了".tl);
      return;
    }
    order += 1;
    urls.clear();
    isLoading = true;
    tools = false;
    if(type == ReadingType.jm){
      data.target = eps[order-1];
    }
    index = 1;
    pageController = PageController(initialPage: 1);
    photoViewController = PhotoViewController();
    update();
  }

  void jumpToLastChapter(){
    data.initialPage = 1;
    var type = data.type;
    var eps = data.eps;
    showFloatingButtonValue = 0;
    if(order == 1 && type == ReadingType.picacg){
      if(appdata.settings[9] != "4") {
        pageController.jumpToPage(1);
      }
      showMessage(App.globalContext, "已经是第一章了".tl);
      return;
    }else if(order == 1 && type == ReadingType.jm){
      if(appdata.settings[9] != "4") {
        pageController.jumpToPage(1);
      }
      showMessage(App.globalContext, "已经是第一章了".tl);
      return;
    }else if(!type.hasEps){
      showMessage(App.globalContext, "已经是第一章了".tl);
      return;
    }

    order -= 1;
    urls.clear();
    isLoading = true;
    tools = false;
    if(type == ReadingType.jm){
      data.target = eps[order-1];
    }
    pageController = PageController(initialPage: 1);
    index = 1;
    photoViewController = PhotoViewController();
    update();
  }

  ///当前章节的长度
  int get length => urls.length;

  /// 是否处于自动翻页状态
  bool runningAutoPageTurning = false;

  /// 自动翻页
  void autoPageTurning() async{
    if(index == urls.length-1){
      runningAutoPageTurning = false;
      update();
      return;
    }
    int sec = int.parse(appdata.settings[33]);
    for(int i = 0; i<sec*10; i++){
      await Future.delayed(const Duration(milliseconds: 100));
      if(! runningAutoPageTurning){
        return;
      }
    }
    jumpToNextPage();
    autoPageTurning();
  }

  void refresh_(){
    pageController = PageController(initialPage: 1);
    itemScrollController = ItemScrollController();
    itemScrollListener = ItemPositionsListener.create();
    scrollController = ScrollController(keepScrollOffset: true);
    photoViewController = PhotoViewController();
    noScroll = false;
    currentScale = 1.0;
    showFloatingButtonValue = 0;
    index = 1;
    urls.clear();
    isLoading = true;
    tools = false;
    showSettings = false;
    update();
  }

  void handleKeyboard(RawKeyEvent event){
    isCtrlPressed = event.isControlPressed;
    switch(event.logicalKey){
      case LogicalKeyboardKey.arrowDown:
        if(!event.isKeyPressed(LogicalKeyboardKey.arrowDown) || event.repeat) {
          jumpToNextPage();
        }
        break;
      case LogicalKeyboardKey.arrowRight:
        if(!event.isKeyPressed(LogicalKeyboardKey.arrowRight) || event.repeat) {
          jumpToNextPage();
        }
        break;
      case LogicalKeyboardKey.arrowUp:
        if(!event.isKeyPressed(LogicalKeyboardKey.arrowUp) || event.repeat) {
          jumpToLastPage();
        }
        break;
      case LogicalKeyboardKey.arrowLeft:
        if(!event.isKeyPressed(LogicalKeyboardKey.arrowLeft) || event.repeat) {
          jumpToLastPage();
        }
        break;
    }
  }
}