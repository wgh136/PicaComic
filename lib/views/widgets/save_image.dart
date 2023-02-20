import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:get/get.dart';
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
    var b = GallerySaver.saveImage(getImageUrl(url));
    b.then((b) {
      if (b == true) {
        showMessage(context, "保存成功");
      } else {
        showMessage(context, "保存失败");
      }
    });
  }else if(GetPlatform.isWindows){
    url = getImageUrl(url);
    String name = "";
    int i;
    for (i = url.length - 1; i >= 0; i--) {
      if (url[i] == '/') {
        break;
      }
    }
    name = url.substring(i + 1);
    final String? path = await getSavePath(suggestedName: name);
    if (path != null) {
      Uint8List bytes = (await NetworkAssetBundle(Uri.parse(url))
        .load(url))
        .buffer
        .asUint8List();
      const String mimeType = 'image/jpeg';
      final XFile file = XFile.fromData(bytes, mimeType: mimeType, name: name);
      await file.saveTo(path);
    }
  }
}