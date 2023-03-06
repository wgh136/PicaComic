import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';

void saveImage(String url) async{
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
      var b = await saveImageFormCache(getImageUrl(url));
      if(b) {
        showMessage(Get.context, "保存成功");
      } else {
        showMessage(Get.context, "保存失败");
      }
  }else if(GetPlatform.isWindows){
    try {
      var file = await DefaultCacheManager().getFileFromCache(url);
      var f = file!.file;
      final String? path = await getSavePath(suggestedName: f.basename);
      if (path != null) {
        const String mimeType = 'image/jpeg';
        final XFile file = XFile.fromData(
            await f.readAsBytes(), mimeType: mimeType, name: f.basename);
        await file.saveTo(path);
      }
    }
    catch(e){
      //忽视
    }
  }
}

Future<bool> saveImageFormCache(String url) async{
  try {
    var file = await DefaultCacheManager().getFileFromCache(url);
    var f = file!.file;
    await ImageGallerySaver.saveImage(
        await f.readAsBytes(),
        quality: 100,
        name: f.basename);
    return true;
  }
  catch(e){
    return false;
  }
}

void saveImageFromDisk(String image) async{
  if(GetPlatform.isAndroid) {
    await ImageGallerySaver.saveFile(image);
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