import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/nhentai_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/foundation/history.dart';
import '../../base.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../network/jm_network/jm_image.dart';
import '../../network/jm_network/jm_models.dart';
import 'comic_reading_page.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';

Future<void> addPicacgHistory(ComicItem comic) async{
  var history = History(
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
  var history = History(
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
  var history = History(
      HistoryType.jmComic,
      DateTime.now(),
      comic.name,
      comic.author.elementAtOrNull(0)??"未知".tl,
      getJmCoverUrl(comic.id),
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
}

Future<void> addHitomiHistory(HitomiComic comic, String cover) async{
  var history = History(
      HistoryType.hitomi,
      DateTime.now(),
      comic.name,
      (comic.artists??["未知".tl]).elementAtOrNull(0)??"未知".tl,
      cover,
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
}

Future<void> addHtmangaHistory(HtComicInfo comic) async{
  var history = History(
      HistoryType.htmanga,
      DateTime.now(),
      comic.name,
      comic.uploader,
      comic.coverPath,
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
}

Future<void> addNhentaiHistory(NhentaiComic comic) async{
  var history = History(
      HistoryType.nhentai,
      DateTime.now(),
      comic.title,
      "",
      comic.cover,
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
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @ep 章第 @page 页, 是否继续阅读?".tlParams({
          "ep": history.ep.toString(),
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, history.ep, epsStr, name, initialPage: history.page,), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
  }
}

void readPicacgComic2(ComicItemBrief comic, List<String> epsStr) async{
  History? history = History(
      HistoryType.picacg,
      DateTime.now(),
      comic.title,
      comic.author,
      comic.path,
      0,
      0,
      comic.id
  );
  await appdata.history.addHistory(history);
  history = await appdata.history.find(comic.id);
  var id = comic.id;
  var name = comic.title;

  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @ep 章第 @page 页, 是否继续阅读?".tlParams({
          "ep": history!.ep.toString(),
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.picacg(id, history!.ep, epsStr, name, initialPage: history.page,), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.picacg(id, 1, epsStr,name), preventDuplicates: false);
  }
}

void readEhGallery(Gallery gallery, [int? page]) async{
  addEhHistory(gallery);
  var target = gallery.link;
  var history = await appdata.history.find(target);
  if(page != null){
    Get.to(()=>ComicReadingPage.ehentai(target, gallery, initialPage: page,), preventDuplicates: false);
    return;
  }
  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @page 页, 是否继续阅读?".tlParams({
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.ehentai(target, gallery), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.ehentai(target, gallery, initialPage: history.page), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
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
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @ep 章第 @page 页, 是否继续阅读?".tlParams({
          "ep": history.ep.toString(),
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.jmComic(id, name, eps, history.ep, initialPage: history.page,), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.jmComic(id, name, eps, 1), preventDuplicates: false);
  }
}

void readHitomiComic(HitomiComic comic, String cover, [int? page]) async{
  await addHitomiHistory(comic, cover);
  var history = await appdata.history.find(comic.id);
  if(page != null){
    Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files, initialPage: page,), preventDuplicates: false);
    return;
  }
  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @ep 章第 @page 页, 是否继续阅读?".tlParams({
          "ep": history.ep.toString(),
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files, initialPage: history.page,), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files,), preventDuplicates: false);
    }
  } else {
    Get.to(()=>ComicReadingPage.hitomi(comic.id, comic.name, comic.files,), preventDuplicates: false);
  }
}

void readHtmangaComic(HtComicInfo comic, [int? page]) async{
  await addHtmangaHistory(comic);
  var history = await appdata.history.find(comic.id);
  if(page != null){
    Get.to(()=>ComicReadingPage.htmanga(comic.id, comic.name, initialPage: page,), preventDuplicates: false);
    return;
  }
  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @page 页, 是否继续阅读?".tlParams({
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.htmanga(comic.id, comic.name), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.htmanga(comic.id, comic.name, initialPage: history.page), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.htmanga(comic.id, comic.name), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.htmanga(comic.id, comic.name), preventDuplicates: false);
  }
}

void readNhentai(NhentaiComic comic, [int? page]) async{
  await addNhentaiHistory(comic);
  var history = await appdata.history.find(comic.id);
  if(page != null){
    Get.to(()=>ComicReadingPage.nhentai(comic.id, comic.title, initialPage: page,), preventDuplicates: false);
    return;
  }
  if(history!=null){
    if(history.ep!=0){
      showDialog(context: Get.context!, builder: (dialogContext)=>AlertDialog(
        title: Text("继续阅读".tl),
        content: Text("上次阅读到第 @page 页, 是否继续阅读?".tlParams({
          "page": history.page.toString()
        })),
        actions: [
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.nhentai(comic.id, comic.title), preventDuplicates: false);
          }, child: Text("从头开始".tl)),
          TextButton(onPressed: (){
            Get.back();
            Get.to(()=>ComicReadingPage.nhentai(comic.id, comic.title, initialPage: history.page), preventDuplicates: false);
          }, child: Text("继续阅读".tl)),
        ],
      ));
    }else{
      Get.to(()=>ComicReadingPage.nhentai(comic.id, comic.title), preventDuplicates: false);
    }
  }else {
    Get.to(()=>ComicReadingPage.nhentai(comic.id, comic.title), preventDuplicates: false);
  }
}