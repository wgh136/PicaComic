import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_image_provider/cache_manager.dart';

Future<double> getFolderSize(Directory path) async{
  double total = 0;
  for(var f in path.listSync(recursive: true)){
    if(FileSystemEntity.typeSync(f.path)==FileSystemEntityType.file){
      total += File(f.path).lengthSync()/1024/1024;
    }
  }
  return total;
}

Future<bool> exportComic(String id) async{
  try{
    var path = Directory(downloadManager.path! + pathSep + id);
    var encode = ZipFileEncoder();
    encode.create('${downloadManager.path!}$pathSep$id.zip');
    await encode.addDirectory(path);
    encode.close();
    if(GetPlatform.isAndroid) {
      var params = SaveFileDialogParams(sourceFilePath: '${downloadManager.path!}$pathSep$id.zip');
      await FlutterFileDialog.saveFile(params: params);
    }else if(GetPlatform.isWindows){
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        var file = File('${downloadManager.path!}$pathSep$id.zip');
        await file.copy("$directoryPath$pathSep$id.zip");
      }
    }
    Get.back();
    var file = File('${downloadManager.path!}$pathSep$id.zip');
    file.delete();
    return true;
  }
  catch(e){
    return false;
  }
}

Future<double> calculateCacheSize() async{
  if(GetPlatform.isAndroid) {
    var path = await getTemporaryDirectory();
    return compute(getFolderSize, path);
  }else{
    return double.infinity;
  }
}

Future<void> eraseCache() async{
  if(GetPlatform.isAndroid) {
    await DefaultCacheManager().emptyCache();
    await MyCacheManager().clear();
    var path = await getTemporaryDirectory();
    for(var i in path.listSync()){
      await i.delete(recursive: true);
    }
  }
}