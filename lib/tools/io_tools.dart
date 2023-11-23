import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pica_comic/base.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/io_extensions.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import '../foundation/app.dart';

Future<double> getFolderSize(Directory path) async{
  double total = 0;
  for(var f in path.listSync(recursive: true)){
    if(FileSystemEntity.typeSync(f.path)==FileSystemEntityType.file){
      total += File(f.path).lengthSync()/1024/1024;
    }
  }
  return total;
}

Future<bool> exportComic(String id, String name, [List<String>? epNames]) async{
  try{
    name = sanitizeFileName(name);
    var data = ExportComicData(id, downloadManager.path, name, epNames);
    var res = await compute(runningExportComic, data);
    if(! res){
      return false;
    }
    if(App.isAndroid || App.isIOS) {
      var params = SaveFileDialogParams(sourceFilePath: '${data.path!}$pathSep$name.zip');
      await FlutterFileDialog.saveFile(params: params);
    }else if(App.isWindows){
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        var file = File('${data.path!}$pathSep$name.zip');
        await file.copy("$directoryPath$pathSep$name.zip");
      }
    }
    var file = File('${data.path!}$pathSep$name.zip');
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
  String name;
  List<String>? epNames;

  ExportComicData(this.id, this.path, this.name, this.epNames);
}

Future<bool> runningExportComic(ExportComicData data) async{
  var id = data.id;
  try{
    final path = Directory(data.path! + pathSep + id);
    bool isModifiedNames = false;
    if(Directory("${path.path}${pathSep}1").existsSync() && data.epNames != null){
      for(var entry in path.listSync()){
        if(entry is Directory){
          isModifiedNames = true;
          var index = int.parse(entry.name) - 1;
          if(index < data.epNames!.length) {
            entry.renameX(data.epNames![index]);
          }
        }
      }
    }
    var encode = ZipFileEncoder();
    encode.create('${data.path!}$pathSep${data.name}.zip');
    await encode.addDirectory(path);
    encode.close();
    if(isModifiedNames) {
      for (var entry in path.listSync()) {
        if (entry is Directory) {
          var index = data.epNames!.indexOf(entry.name) + 1;
          if (index > 0) {
            entry.renameX(index.toString());
          }
        }
      }
    }
    return true;
  }
  catch(e, s){
    LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    return false;
  }
}

Future<double> calculateCacheSize() async{
  if(App.isAndroid || App.isIOS) {
    var path = await getTemporaryDirectory();
    return compute(getFolderSize, path);
  }else if(App.isWindows){
    var path = "${(await getTemporaryDirectory()).path}${pathSep}imageCache";
    var directory = Directory(path);
    if(directory.existsSync()){
      return directory.getMBSizeSync();
    }else{
      return 0;
    }
  }else{
    return double.infinity;
  }
}

Future<void> eraseCache() async{
  if(App.isAndroid || App.isIOS) {
    imageCache.clear();
    await DefaultCacheManager().emptyCache();
    await ImageManager().clear();
    await CachedNetwork.clearCache();
  }else if(App.isWindows){
    imageCache.clear();
    await DefaultCacheManager().emptyCache();
    await ImageManager().clear();
    await CachedNetwork.clearCache();
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

String sanitizeFileName(String fileName) {
  const maxLength = 255;
  // 定义不允许出现的特殊字符
  final invalidChars = RegExp(r'[<>:"/\\|?*]');

  // 替换特殊字符为空格
  final sanitizedFileName = fileName.replaceAll(invalidChars, ' ');

  // 移除字符串前后的空格
  var trimmedFileName = sanitizedFileName.trim();

  // 检查文件名长度是否为零
  if (trimmedFileName.isEmpty) {
    throw Exception('文件名无效');
  }

  //确保长度适当
  while(true){
    final bytes = utf8.encode(trimmedFileName);
    if (bytes.length > maxLength) {
      trimmedFileName = trimmedFileName.substring(0, trimmedFileName.length-1);
    }else{
      break;
    }
  }
  return trimmedFileName;
}

///检查下载目录是否可用, 不可用则重置
Future<void> checkDownloadPath() async{
  var path = appdata.settings[22];
  if(path != ""){
    var directory = Directory(path);
    if(! directory.existsSync()){
      appdata.settings[22] = "";
      appdata.updateSettings();
    }
  }
}

Future<String?> exportData(String path, String appdataString, String? downloadPath) async{
  try {
    var filePath = "$path${pathSep}appdata";
    var file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync();
    file.writeAsStringSync(appdataString);
    var encode = ZipFileEncoder();
    encode.create("$path${pathSep}userData.picadata");
    await encode.addFile(file);
    var localFavorite = File("$path${pathSep}localFavorite");
    if(! localFavorite.existsSync()){
      localFavorite.createSync();
    }
    await encode.addFile(localFavorite);
    if(downloadPath != null) {
      var download = Directory(downloadPath);
      await encode.addDirectory(download);
    }
    encode.close();
    return null;
  }
  catch(e){
    return e.toString();
  }
}

Future<String> exportDataToFile(bool includeDownload) async{
  var path = (await getApplicationSupportDirectory()).path;
  try {
    if (DownloadManager().path == null) {
      DownloadManager().init();
    }
    if(HistoryManager().history == null){
      await HistoryManager().readData();
    }
    var appdataString = const JsonEncoder().convert(appdata.toJson());
    var downloadPath = includeDownload?DownloadManager().path:null;
    var res = await compute<List<String?>, String?>((message) =>
        exportData(message[0]!, message[1]!, message[2]), [path, appdataString, downloadPath]);

    if (res != null) {
      throw Exception(res);
    }
  }
  catch(e, s){
    LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    rethrow;
  }
  return "$path${pathSep}userData.picadata";
}

Future<bool> runExportData(bool includeDownload) async{
  try {
    var path = (await getApplicationSupportDirectory()).path;
    await exportDataToFile(includeDownload);
    if (App.isAndroid || App.isIOS) {
      var params = SaveFileDialogParams(
          sourceFilePath: "$path${pathSep}userData.picadata");
      await FlutterFileDialog.saveFile(params: params);
    } else if (App.isWindows) {
      final String? directoryPath = await getDirectoryPath();
      if (directoryPath != null) {
        var file = File("$path${pathSep}userData.picadata");
        await file.copy("$directoryPath${pathSep}userData.picadata");
      }
    }
    var file = File("$path${pathSep}userData.picadata");
    file.delete();
  }
  catch(e, s){
    LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    return false;
  }
  return true;
}

/// import data, filePath is used for webdav
Future<bool> importData([String? filePath]) async{
  final enableCheck = filePath != null;
  var path = (await getApplicationSupportDirectory()).path;
  if(filePath == null) {
    if (App.isMobile) {
      var params = const OpenFileDialogParams();
      filePath = await FlutterFileDialog.pickFile(params: params);
    } else if (App.isWindows) {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'data',
        extensions: <String>['picadata'],
      );
      final XFile? file = await openFile(
          acceptedTypeGroups: <XTypeGroup>[
            typeGroup
          ]);
      filePath = file?.path;
    }
    if (filePath == null) {
      return false;
    }
  }
  if (DownloadManager().path == null) {
    DownloadManager().init();
  }
  var data = await compute<List<String>, String?>((data) async{
    try {
      var decode = ZipDecoder();
      final inputStream = InputFileStream(data[1]);
      var archive = decode.decodeBuffer(inputStream);
      extractArchiveToDisk(archive, "$path${pathSep}dataTemp");
      var downloadPath = Directory(data[2]);
      List<FileSystemEntity> contents = Directory("$path${pathSep}dataTemp")
          .listSync();
      for (FileSystemEntity item in contents) {
        if (item is Directory) {
          item.renameSync('$path${pathSep}dataTemp${pathSep}download');
        }
      }
      var downloadData = Directory("$path${pathSep}dataTemp${pathSep}download");
      if(downloadData.existsSync()) {
        downloadPath.deleteSync(recursive: true);
        downloadPath.createSync();
      }
      var localFavorite = File('$path${pathSep}dataTemp${pathSep}localFavorite');
      localFavorite.copySync('$path${pathSep}localFavorite');
      if(downloadData.existsSync()) {
        await copyDirectory(
          Directory("$path${pathSep}dataTemp${pathSep}download"), downloadPath);
      }
      var json = File("$path${pathSep}dataTemp${pathSep}appdata")
          .readAsStringSync();
      try {
        Directory("$path${pathSep}dataTemp").deleteSync(recursive: true);
      }
      catch(e){
        //忽略
      }
      return json;
    }
    catch(e){
      return null;
    }
  }, [path, filePath, DownloadManager().path!]);
  if(data == null){
    return false;
  }
  var json = const JsonDecoder().convert(data);
  int fileVersion = int.parse((json["settings"] as List).elementAtOrNull(46) ?? "1");
  int appVersion = int.parse(appdata.settings[46]);
  if(fileVersion <= appVersion && enableCheck){
    LogManager.addLog(LogLevel.info, "Appdata",
        "The data file version is $fileVersion, while the app data version is "
            "$appVersion\nStop importing data");
    return true;
  }
  var prevAccounts = [appdata.picacgAccount, appdata.jmEmail, appdata.htName];
  var dataReadRes = appdata.readDataFromJson(json);
  if(!dataReadRes){
    return false;
  }
  if(appdata.picacgAccount != prevAccounts[0]) {
    await network.loginFromAppdata();
  }
  if(appdata.jmEmail != prevAccounts[1]) {
    await JmNetwork().loginFromAppdata();
  }
  if(appdata.htName != prevAccounts[2]) {
    await HtmangaNetwork().loginFromAppdata();
  }
  LocalFavoritesManager().close();
  await LocalFavoritesManager().readData();
  LocalFavoritesManager().updateUI();
  return true;
}

void saveLog(String log) async{
  var path = (await getTemporaryDirectory()).path;
  var file = File("$path${pathSep}logs.txt");
  file.writeAsStringSync(log);
  if (App.isAndroid || App.isIOS) {
    var params = SaveFileDialogParams(
        sourceFilePath: "$path${pathSep}logs.txt");
    await FlutterFileDialog.saveFile(params: params);
  } else if (App.isWindows) {
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      await file.copy("$directoryPath${pathSep}logs.txt");
    }
  }
}

Future<void> exportStringDataAsFile(String data, String fileName) async{
  var cachePath = (await getApplicationCacheDirectory()).path;
  var file = File("$cachePath$pathSep$fileName");
  if(!file.existsSync()){
    file.createSync();
  }
  file.writeAsStringSync(data);
  if(App.isAndroid || App.isIOS) {
    var params = SaveFileDialogParams(sourceFilePath: file.path);
    await FlutterFileDialog.saveFile(params: params);
  }else if(App.isWindows){
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      await file.copy("$directoryPath$pathSep$fileName");
    }
  }
}

Future<String?> getDataFromUserSelectedFile(List<String> extensions) async{
  String? filePath;
  if (App.isMobile) {
    var params = const OpenFileDialogParams();
    filePath = await FlutterFileDialog.pickFile(params: params);
  } else if (App.isWindows) {
    XTypeGroup typeGroup = XTypeGroup(
      label: 'data',
      extensions: extensions,
    );
    final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[
          typeGroup
        ]);
    filePath = file?.path;
  }
  if(filePath == null){
    return null;
  }
  return File(filePath).readAsStringSync();
}