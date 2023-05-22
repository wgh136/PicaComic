import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/cache_manager.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

///保存图片
void saveImage(String urlOrHash, String id, {bool eh=false, bool jmOrHitomi=false}) async{
  if(GetPlatform.isWeb){
    //Web端使用下载图片的方式
    showMessage(Get.context, "下载中".tr);
    int i;
    for (i = urlOrHash.length - 1; i >= 0; i--) {
      if (urlOrHash[i] == '/') {
        break;
      }
    }
    launchUrlString("https://api.kokoiro.xyz/storage/download/$urlOrHash");
  }
  else if(GetPlatform.isAndroid) {
      var url_ = "";
      if(jmOrHitomi){
        url_ = urlOrHash;
      }else{
        url_ = getImageUrl(urlOrHash);
      }
      var b = await saveImageFormCache(url_, id, eh: eh, jmOrHitomi: jmOrHitomi);
      if(b) {
        showMessage(Get.context, "成功保存于Picture中".tr);
      }
      else {
        showMessage(Get.context, "保存失败".tr);
      }
  }else if(GetPlatform.isWindows){
    try {
      File? file;
      if(eh || jmOrHitomi){
        file = await MyCacheManager().getFile(urlOrHash);
      } else {
        var f = await DefaultCacheManager().getFileFromCache(getImageUrl(urlOrHash));
        file = f!.file;
      }
      var f = file!;
      var basename = file.path;
      var bytes = await f.readAsBytes();
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

Future<bool> saveImageFormCache(String urlOrHash, String id, {bool eh = false, bool jmOrHitomi = false}) async{
  try {
    File? file;
    if(eh || jmOrHitomi){
      file = await MyCacheManager().getFile(urlOrHash);
    }else {
      var f = await DefaultCacheManager().getFileFromCache(urlOrHash);
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
    if(jmOrHitomi){
      var bytes = await f.readAsBytes();
      data = bytes;
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
    showMessage(Get.context, "成功保存到Picture中".tr);
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

void shareImageFromCache(String urlOrHash, String id, {bool eh=false, bool jmOrHitomi=false}) async{
  try{
    if(eh || jmOrHitomi){
      var file = await MyCacheManager().getFile(urlOrHash);
      var bytes = await file!.readAsBytes();
      Share.shareXFiles([XFile.fromData(bytes, mimeType: 'image/jpeg', name: "share.jpg")]);
    } else {
      var file = await DefaultCacheManager().getFileFromCache(getImageUrl(urlOrHash));
      Share.shareXFiles([XFile(file!.file.path)]);
    }
  }
  catch(e){
    if (kDebugMode) {
      print(e);
    }
    showMessage(Get.context, "分享失败".tr);
  }
}

void shareImageFromDisk(String path) async{
  try{
    Share.shareXFiles([XFile(path)]);
  }
  catch(e){
    showMessage(Get.context, "分享失败".tr);
  }
}