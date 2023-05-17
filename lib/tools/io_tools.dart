import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/tools/cache_manager.dart';

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
    var data = ExportComicData(id, downloadManager.path);
    var res = await compute(runningExportComic, data);
    if(! res){
      return false;
    }
    if(GetPlatform.isAndroid) {
      var params = SaveFileDialogParams(sourceFilePath: '${data.path!}$pathSep$id.zip');
      await FlutterFileDialog.saveFile(params: params);
    }else if(GetPlatform.isWindows){
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        var file = File('${data.path!}$pathSep$id.zip');
        await file.copy("$directoryPath$pathSep$id.zip");
      }
    }
    Get.back();
    var file = File('${data.path!}$pathSep$id.zip');
    file.delete();
    return true;
  }
  catch(e){
    return false;
  }
}

class ExportComicData{
  String id;
  String? path;

  ExportComicData(this.id, this.path);
}

Future<bool> runningExportComic(ExportComicData data) async{
  var id = data.id;
  try{
    var path = Directory(data.path! + pathSep + id);
    var encode = ZipFileEncoder();
    encode.create('${data.path!}$pathSep$id.zip');
    await encode.addDirectory(path);
    encode.close();

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
    imageCache.clear();
    await DefaultCacheManager().emptyCache();
    await MyCacheManager().clear();
    var path = await getTemporaryDirectory();
    for(var i in path.listSync()){
      await i.delete(recursive: true);
    }
  }else if(GetPlatform.isWindows){
    imageCache.clear();
    await DefaultCacheManager().emptyCache();
    await MyCacheManager().clear();
  }
}

Future<void> copyDirectory(Directory source, Directory destination) async{
  // 获取源文件夹中的内容（包括文件和子文件夹）
  List<FileSystemEntity> contents = source.listSync();

  // 遍历源文件夹中的每个文件和子文件夹
  for (FileSystemEntity content in contents) {
    String newPath = destination.path + Platform.pathSeparator + content.path.split(Platform.pathSeparator).last;

    if (content is File) {
      // 如果是文件，则复制文件到目标文件夹中
      content.copySync(newPath);
    } else if (content is Directory) {
      // 如果是子文件夹，则递归地调用该函数，复制子文件夹到目标文件夹中
      Directory newDirectory = Directory(newPath);
      newDirectory.createSync();
      copyDirectory(content.absolute, newDirectory.absolute);
    }
  }
}