import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_image_provider/cache_manager.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_image_provider/find_eh_image_real_url.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../views/jm_views/jm_image_provider/image_recombine.dart';

void saveImage(String url, String id, {bool eh=false, bool jm=false}) async{
  if(GetPlatform.isWeb){
    //Web端使用下载图片的方式
    showMessage(Get.context, "下载中");
    int i;
    for (i = url.length - 1; i >= 0; i--) {
      if (url[i] == '/') {
        break;
      }
    }
    launchUrlString("https://api.kokoiro.xyz/storage/download/$url");
  }
  else if(GetPlatform.isAndroid) {
      var url_ = "";
      if(eh){
        url_ = await EhImageUrlsManager.getUrl(url);
      }else if(jm){
        url_ = url;
      }else{
        url_ = getImageUrl(url);
      }
      var b = await saveImageFormCache(url_, id, eh: eh, jm: jm);
      if(b) {
        showMessage(Get.context, "成功保存于Picture中");
      }
      else {
        showMessage(Get.context, "保存失败");
      }
  }else if(GetPlatform.isWindows){
    try {
      File? file;
      if(eh){
        file = await MyCacheManager().getFile(await EhImageUrlsManager.getUrl(url));
      }else if(jm){
        file = await MyCacheManager().getFile(url);
      }
      else {
        var f = await DefaultCacheManager().getFileFromCache(getImageUrl(url));
        file = f!.file;
      }
      var f = file!;
      var basename = file.path;
      var bytes = await f.readAsBytes();
      var bookId = "";
      for(int i = url.length-1;i>=0;i--){
        if(url[i] == '/'){
          bookId = url.substring(i+1,url.length-5);
          break;
        }
      }
      bytes = segmentationPicture(bytes, id, "220980", bookId);
      for(var i = basename.length-1;i>=0;i--){
        if(basename[i] == '/'||basename[i]=='\\'){
          basename = basename.substring(i+1);
          break;
        }
      }
      final String? path = await getSavePath(suggestedName: basename);
      if (path != null) {
        const String mimeType = 'image/jpeg';
        final XFile file = XFile.fromData(
            bytes, mimeType: mimeType, name: basename);
        await file.saveTo(path);
      }
    }
    catch(e){
      if (kDebugMode) {
        print(e);
      }
    }
  }
}

Future<bool> saveImageFormCache(String url, String id, {bool eh = false, bool jm = false}) async{
  try {
    File? file;
    if(eh || jm){
      file = await MyCacheManager().getFile(url);
    }else {
      var f = await DefaultCacheManager().getFileFromCache(url);
      file = f!.file;
    }
    var f = file!;
    var name = file.path;
    for(var i = name.length-1;i>=0;i--){
      if(name[i] == '/'){
        name = name.substring(i+1);
        break;
      }
    }
    Uint8List data;
    if(jm){
      var bytes = await f.readAsBytes();
      var bookId = "";
      for(int i = url.length-1;i>=0;i--){
        if(url[i] == '/'){
          bookId = url.substring(i+1,url.length-5);
          break;
        }
      }
      data = segmentationPicture(bytes, id, "220980", bookId);
    }else{
      data = await f.readAsBytes();
    }
    await ImageGallerySaver.saveImage(
        data,
        quality: 100,
        name: name);
    return true;
  }
  catch(e){
    return false;
  }
}

void saveImageFromDisk(String image) async{
  if(GetPlatform.isAndroid) {
    await ImageGallerySaver.saveFile(image);
    showMessage(Get.context, "成功保存到Picture中");
  }else if(GetPlatform.isWindows){
    var f = File(image);
    String name;
    int i;
    for(i=image.length-1;i>=0;i--){
      if(image[i]==pathSep){
        break;
      }
    }
    name = image.substring(i+1);
    final String? path = await getSavePath(suggestedName: name);
    if (path != null) {
      const String mimeType = 'image/jpeg';
      final XFile file = XFile.fromData(
          await f.readAsBytes(), mimeType: mimeType, name: name);
      await file.saveTo(path);
    }
  }
}

void shareImageFromCache(String url, String id, {bool eh=false, bool jm=false}) async{
  try{
    if(eh){
      var file = await MyCacheManager().getFile(await EhImageUrlsManager.getUrl(url));
      Share.shareXFiles([XFile(file!.path)]);
    }else if(jm){
      var file = await MyCacheManager().getFile(url);
      var bytes = await file!.readAsBytes();
      var bookId = "";
      for(int i = url.length-1;i>=0;i--){
        if(url[i] == '/'){
          bookId = url.substring(i+1,url.length-5);
          break;
        }
      }
      bytes = segmentationPicture(bytes, id, "220980", bookId);
      Share.shareXFiles([XFile.fromData(bytes, mimeType: 'image/jpeg', name: "share.jpg")]);
    }
    else {
      var file = await DefaultCacheManager().getFileFromCache(getImageUrl(url));
      Share.shareXFiles([XFile(file!.file.path)]);
    }
  }
  catch(e){
    if (kDebugMode) {
      print(e);
    }
    showMessage(Get.context, "分享失败");
  }
}

void shareImageFromDisk(String path) async{
  try{
    Share.shareXFiles([XFile(path)]);
  }
  catch(e){
    showMessage(Get.context, "分享失败");
  }
}