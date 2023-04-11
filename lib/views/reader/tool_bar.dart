import 'package:flutter/material.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:get/get.dart';

import '../../base.dart';

///构建顶部工具栏
Widget buildTopToolBar(ComicReadingPageLogic comicReadingPageLogic, BuildContext context, String title){
  return Positioned(
    top: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      child: comicReadingPageLogic.tools?Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          //borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10),bottomLeft: Radius.circular(10))
        ),
        width: MediaQuery.of(context).size.width+MediaQuery.of(context).padding.top,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: Row(
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),child: Tooltip(
                message: "返回",
                child: IconButton(
                  iconSize: 25,
                  icon: const Icon(Icons.arrow_back_outlined),
                  onPressed: ()=>Get.back(),
                ),
              ),),
              Container(
                width: MediaQuery.of(context).size.width-125,
                height: 50,
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width-75),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(title,overflow: TextOverflow.ellipsis,style: const TextStyle(fontSize: 20),),
                )
                ,),
              //const Spacer(),
              Padding(padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),child: Tooltip(
                message: "阅读设置",
                child: IconButton(
                  iconSize: 25,
                  icon: const Icon(Icons.settings),
                  onPressed: (){
                    comicReadingPageLogic.showSettings = !comicReadingPageLogic.showSettings;
                    comicReadingPageLogic.update();
                  },
                ),
              ),),
            ],
          ),
        ),
      ):const SizedBox(width: 0,height: 0,),
      transitionBuilder: (Widget child, Animation<double> animation) {
        var tween = Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0));
        return SlideTransition(
          position: tween.animate(animation),
          child: child,
        );
      },
    ),);
}

///构建底部工具栏
Widget buildBottomToolBar(
    ComicReadingPageLogic comicReadingPageLogic,
    BuildContext context,
    bool showEps,
    void Function() openEpsDrawer,
    void Function() share,
    void Function() downloadCurrentImage){

  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        var tween = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0));
        return SlideTransition(
          position: tween.animate(animation),
          child: child,
        );
      },
      child: comicReadingPageLogic.tools?Container(
        height: 105+Get.bottomBarHeight/2,
        decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
            color: Theme.of(context).colorScheme.surface
        ),
        child: Column(
          children: [
            const SizedBox(height: 8,),
            buildSlider(comicReadingPageLogic),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if(showEps)
                  Tooltip(
                    message: "章节",
                    child: IconButton(
                      icon: const Icon(Icons.library_books),
                      onPressed: openEpsDrawer,
                    ),
                  ),
                Tooltip(
                  message: "保存图片",
                  child: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: downloadCurrentImage,
                  ),
                ),
                Tooltip(
                  message: "分享",
                  child: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: share,
                  ),
                ),
                const SizedBox(width: 5,)
              ],
            )
          ],
        ),
      ):const SizedBox(width: 0,height: 0,),
    ),
  );
}

///显示当前的章节和页面位置
Widget buildPageInfoText(
    ComicReadingPageLogic comicReadingPageLogic,
    bool showEps,
    List<String> eps,
    BuildContext context){

  if(!comicReadingPageLogic.tools) {
    return Positioned(
        bottom: 13,
        left: 25,
        child: appdata.settings[9]=="4"?ValueListenableBuilder(
          valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
          builder: (context, value, child){
            try{
              comicReadingPageLogic.index = value.first.index + 1;
            }
            catch(e){
              comicReadingPageLogic.index = 0;
            }
            return showEps?
            Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),):
            Text("${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),);
          },
        ):showEps?
        Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),):
        Text("${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),)
    );
  } else {
    return Positioned(
        bottom: 13+Get.bottomBarHeight/2,
        left: 25,
        child: appdata.settings[9]=="4"?ValueListenableBuilder(
          valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
          builder: (context, value, child){
            try{
              comicReadingPageLogic.index = value.first.index + 1;
            }
            catch(e){
              if(appdata.settings[9]=="4") {
                comicReadingPageLogic.index = 0;
              }
            }
            return showEps?
            Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),):
            Text("${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),);
          },
        ):showEps?
        Text("${eps[comicReadingPageLogic.order]}: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),):
        Text("${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",style: TextStyle(color: comicReadingPageLogic.tools?Theme.of(context).colorScheme.onSurface:Colors.white),)
    );
  }
}

List<Widget> buildBottoms(ComicReadingPageLogic comicReadingPageLogic, BuildContext context){
  return ((MediaQuery.of(context).size.width > MediaQuery.of(context).size.height &&
      appdata.settings[9] != "4" && appdata.settings[4] == "1"))?[
      Positioned(
        left: 20,
        top: MediaQuery.of(context).size.height / 2 - 25,
        child: IconButton(
          icon: const Icon(Icons.arrow_circle_left),
          onPressed: () {
            final value = appdata.settings[9] == "2"
                ? comicReadingPageLogic.index + 1
                : comicReadingPageLogic.index - 1;
            comicReadingPageLogic.jumpToPage(value);
          },
          iconSize: 50,
        ),
      ),
      Positioned(
        right: 20,
        top: MediaQuery.of(context).size.height / 2 - 25,
        child: IconButton(
          icon: const Icon(Icons.arrow_circle_right),
          onPressed: () {
            final value = appdata.settings[9] != "2"
                ? comicReadingPageLogic.index + 1
                : comicReadingPageLogic.index - 1;
            comicReadingPageLogic.jumpToPage(value);
          },
          iconSize: 50,
        ),
      ),
      Positioned(
        left: 5,
        top: 5,
        child: IconButton(
          iconSize: 30,
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
  ]:[];
}

Widget buildSlider(ComicReadingPageLogic comicReadingPageLogic) {
  if (comicReadingPageLogic.tools &&
      comicReadingPageLogic.index != 0 &&
      comicReadingPageLogic.index != comicReadingPageLogic.urls.length + 1) {
    if (appdata.settings[9] != "2" && appdata.settings[9] != "4") {
      return Slider(
        value: comicReadingPageLogic.index.toDouble(),
        min: 1,
        max: comicReadingPageLogic.urls.length.toDouble(),
        divisions: comicReadingPageLogic.urls.length,
        onChanged: (i) {
          comicReadingPageLogic.index = i.toInt();
          comicReadingPageLogic.jumpToPage(i.toInt());
          comicReadingPageLogic.update();
        },
      );
    } else {
      if (appdata.settings[9] == "4") {
        return ValueListenableBuilder(
          valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
          builder: (context, value, child) {
            try {
              comicReadingPageLogic.index = value.first.index + 1;
            } catch (e) {
              comicReadingPageLogic.index = 0;
            }
            return Slider(
              value: comicReadingPageLogic.index.toDouble(),
              min: 1,
              max: comicReadingPageLogic.urls.length.toDouble(),
              divisions: comicReadingPageLogic.urls.length,
              onChanged: (i) {
                comicReadingPageLogic.index = i.toInt();
                comicReadingPageLogic.jumpToPage(i.toInt());
                comicReadingPageLogic.update();
              },
            );
          },
        );
      } else {
        return Slider(
          value: comicReadingPageLogic.urls.length.toDouble() -
              comicReadingPageLogic.index.toDouble() +
              1,
          min: 1,
          max: comicReadingPageLogic.urls.length.toDouble(),
          divisions: comicReadingPageLogic.urls.length,
          activeColor: Theme.of(Get.context!).colorScheme.surfaceVariant,
          inactiveColor: Theme.of(Get.context!).colorScheme.primary,
          thumbColor: Theme.of(Get.context!).colorScheme.secondary,
          onChanged: (i) {
            comicReadingPageLogic.controller
                .jumpToPage(comicReadingPageLogic.urls.length - (i.toInt() - 1));
          },
        );
      }
    }
  } else {
    return const SizedBox(
      height: 0,
    );
  }
}