import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';

void saveImage(String url ,BuildContext context) async{
  if(GetPlatform.isWeb){
    showMessage(context, "下载中");
    String name = "";
    int i;
    for (i = url.length - 1; i >= 0; i--) {
      if (url[i] == '/') {
        break;
      }
    }
    name = url.substring(i + 1);
    launchUrlString("https://api.kokoiro.xyz/storage/download/$url");
  }
  else if(GetPlatform.isAndroid) {
      var b = await saveImageFormCache(getImageUrl(url));
      if(b)  showMessage(context, "保存成功");
      else  showMessage(context, "保存失败");
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
    final result = await ImageGallerySaver.saveImage(
        await f.readAsBytes(),
        quality: 100,
        name: f.basename);
    return true;
  }
  catch(e){
    return false;
  }
}