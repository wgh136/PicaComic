import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/models/history.dart';
import '../../base.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../network/jm_network/jm_image.dart';
import '../../network/jm_network/jm_models.dart';
import 'comic_reading_page.dart';
import 'package:flutter/material.dart';

Future<void> addPicacgHistory(ComicItem comic) async{
  var history = NewHistory(
      HistoryType.picacg,
      DateTime.now(),
      comic.title,
      comic.author,
      comic.thumbUrl,
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
}

Future<void> addEhHistory(Gallery gallery) async{
  var history = NewHistory(
      HistoryType.ehentai,
      DateTime.now(),
      gallery.title,
      gallery.uploader,
      gallery.coverPath,
      0,
      0,
      gallery.link
  );
  await appdata.history.addHistory(history);
}

Future<void> addJmHistory(JmComicInfo comic) async{
  var history = NewHistory(
      HistoryType.jmComic,
      DateTime.now(),
      comic.name,
      comic.author[0],
      getJmCoverUrl(comic.id),
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
}

Future<void> addHitomiHistory(HitomiComic comic, String cover) async{
  var history = NewHistory(
      HistoryType.hitomi,
      DateTime.now(),
      comic.name,
      (comic.artists??["未知"])[0],
      cover,
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
}

void readPicacgComic(ComicItem comic, List<String> epsStr) async{
  await addPicacgHistory(comic);
  var history = await appdata.history.find(comic.id);
  var id = comic.id;
  var name = comic.title;

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.ep}章第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, history.ep, epsStr, name, initialPage: history.page,), preventDuplicates: false);
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
  }
}

void readEhGallery(Gallery gallery) async{
  addEhHistory(gallery);
  var target = gallery.link;
  var history = await appdata.history.find(target);

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.ehentai(target, gallery), preventDuplicates: false);
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.ehentai(target, gallery, initialPage: history.page), preventDuplicates: false);
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.ehentai(target, gallery), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.ehentai(target, gallery), preventDuplicates: false);
  }
}

void readJmComic(JmComicInfo comic, List<String> eps) async{
  await addJmHistory(comic);
  var id = comic.id;
  var name = comic.name;
  var history = await appdata.history.find(id);

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.ep}章第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1), preventDuplicates: false);
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.jmComic(id, name, eps, history.ep, initialPage: history.page,), preventDuplicates: false);
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1), preventDuplicates: false);
  }
}

void readHitomiComic(HitomiComic comic, String cover) async{
  await addHitomiHistory(comic, cover);
  var history = await appdata.history.find(comic.id);
  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: const Text("继续阅读"),
        content: Text("上次阅读到第${history.page}页, 是否继续阅读?"),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files), preventDuplicates: false);
          }, child: const Text("从头开始")),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files, initialPage: history.page,), preventDuplicates: false);
          }, child: const Text("继续阅读")),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files,), preventDuplicates: false);
    }
  } else {
    HistoryManager().addHistory(NewHistory.fromHitomiComic(comic, cover, DateTime.now(), 0, 1));
    Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files,), preventDuplicates: false);
  }
}