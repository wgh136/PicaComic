import 'package:get/get.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import '../../base.dart';
import 'comic_reading_page.dart';
import 'package:flutter/material.dart';

void readPicacgComic(String id, String name, List<String> epsStr) async{
  var history = await appdata.history.find(id);

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.ep}章第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name));
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, history.ep, epsStr, name, initialPage: history.page,));
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name));
    }
  }else {
    Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name));
  }
}

void readEhGallery(String target, Gallery gallery) async{
  var history = await appdata.history.find(target);

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.ehentai(target, gallery));
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.ehentai(target, gallery, initialPage: history.page));
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.ehentai(target, gallery));
    }
  }else {
    Get.to(()=>ComicReadingPage.ehentai(target, gallery));
  }
}

void readJmComic(String id, String name, List<String> eps) async{
  var history = await appdata.history.find(id);

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.ep}章第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1));
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1, initialPage: history.page,));
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1));
    }
  }else {
    Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1));
  }
}