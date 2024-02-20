import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/custom_download_model.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/ht_download_model.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/jm_network/jm_download.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/network/nhentai_network/download.dart';
import 'package:pica_comic/network/picacg_network/picacg_download_model.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/download_page.dart';
import 'nhentai_network/models.dart';
import 'picacg_network/models.dart';

/*
关于数据储存:
  目录结构如下:
    [App数据根目录]
      - download/
        - [漫画id]/
          - [章节序号]
          - info.json
        - newDownload.json

 */

typedef DownloadingCallback = void Function();

class DownloadManager{
  static DownloadManager? cache;

  factory DownloadManager() => cache??(cache=DownloadManager._create());

  DownloadManager._create();

  ///下载目录
  String? path;

  ///已下载的漫画
  List<String> downloaded = [];

  /// 获取所有漫画
  List<String> get allComics => downloaded;

  ///下载队列
  var downloading = Queue<DownloadingItem>();

  ///是否正在下载
  bool isDownloading = false;

  ///用于监听下载队列的变化
  DownloadingCallback? _whenChange = (){};

  ///出现错误时调用
  DownloadingCallback? _handleError;

  ///是否出现了错误
  bool _error = false;

  ///是否出现了错误
  get error => _error;

  ///是否初始化
  bool _runInit = false;

  /// 用于下载页面, 监听下载情况
  void addListener(DownloadingCallback whenChange, DownloadingCallback whenError){
    _whenChange = whenChange;
    _handleError = whenError;
  }

  void removeListener(){
    _whenChange = null;
    _handleError = null;
  }

  ///获取下载目录
  Future<void> _getPath() async{
    if(appdata.settings[22] == "") {
      final appPath = await getApplicationSupportDirectory();
      path = "${appPath.path}${pathSep}download";
    }else{
      path = appdata.settings[22];
    }
    var file = Directory(path!);
    if(! await file.exists()){
      await file.create(recursive: true);
    }
  }

  /// delete all download
  void clear() async{
    await init();
    var directory = Directory(path!);
    directory.deleteSync(recursive: true);
    _runInit = false;
    await init();
  }

  ///更换下载目录
  Future<String> updatePath(String newPath, {bool transform = true}) async{
    if(transform) {
      var source = Directory(path!);
      final appPath = await getApplicationSupportDirectory();
      var destination = Directory(newPath==""?"${appPath.path}${pathSep}download":newPath);
      try {
        await copyDirectory(source, destination);
        for(var i in source.listSync()){
          await i.delete(recursive: true);
        }
      }
      catch (e) {
        return e.toString();
      }
    }

    _runInit = false;
    downloaded.clear();
    downloading.clear();
    await init();
    return "ok";
  }

  ///读取数据, 获取未完成的下载和已下载的漫画ID
  ///
  /// 读取数据时将会检查漫画信息文件是否存在
  Future<void> _getInfo() async{
    //读取数据
    var file = File("$path${pathSep}newDownload.json");
    if(! file.existsSync()){
      await _saveInfo();
    }
    try {
      var json = const JsonDecoder().convert(file.readAsStringSync());
      for (var item in json["downloading"]) {
        downloading.add(downloadingItemFromMap(item, _whenFinish, _whenError, _saveInfo));
      }
      for(var entry in Directory(path!).listSync()){
        if(entry is Directory){
          var infoFile = File("${entry.path}/info.json");
          if(infoFile.existsSync()){
            downloaded.add(entry.name);
          }
        }
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "IO", "Failed to read downloaded information\n$e\n$s");
      file.deleteSync();
      await _saveInfo();
    }

    //迁移旧版本的数据
    file = File("$path${pathSep}download.json");
    if(file.existsSync()){
      var json = await file.readAsString();
      for(var i in jsonDecode(json)["downloaded"]){
        downloaded.add(i);
      }
      await file.delete();
    }
    await _saveInfo();
  }

  ///初始化下载管理器
  Future<void> init() async{
    if(_runInit) return;
    _runInit = true;
    await _getPath();
    await _getInfo();
  }

  ///储存当前的下载队列信息, 每完成一张图片的下载调用一次
  Future<void> _saveInfo() async{
    var data = <String, dynamic>{};
    data["downloading"] = <Map<String, dynamic>>[];
    for(var item in downloading){
      data["downloading"].add(item.toMap());
    }
    var file = File("$path${pathSep}newDownload.json");
    if(! file.existsSync()){
      await file.create();
    }else{
     await file.delete();
     await file.create();
    }
    await file.writeAsString(const JsonEncoder().convert(data));
  }

  ///通过downloaded数组的序号得到漫画信息
  Future<DownloadedComic> getDownloadedComicInfo(int index) async{
    var file = File("$path$pathSep${downloaded[index]}${pathSep}info.json");
    var json = await file.readAsString();
    return DownloadedComic.fromJson(jsonDecode(json));
  }

  /// move comic to first
  void moveToFirst(DownloadingItem item){
    if(downloading.first == item){
      return;
    }
    pause();
    downloading.remove(item);
    downloading.addFirst(item);
    start();
  }

  ///添加哔咔漫画下载
  void addPicDownload(ComicItem comic, List<int> downloadEps){
    var downloadPath = Directory("$path$pathSep${comic.id}");
    downloadPath.create(recursive: true);
    downloading.addLast(PicDownloadingItem(comic, path!, downloadEps, _whenFinish, _whenError, _saveInfo, comic.id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加E-Hentai下载
  void addEhDownload(Gallery gallery){
    final id = getGalleryId(gallery.link);
    var downloadPath = Directory("$path$pathSep$id");
    downloadPath.create(recursive: true);
    downloading.addLast(EhDownloadingItem(gallery, path!, _whenFinish, _whenError, _saveInfo, id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加禁漫下载
  void addJmDownload(JmComicInfo comic, List<int> downloadEps){
    var downloadPath = Directory("$path$pathSep${"jm"}${comic.id}");
    downloadPath.create(recursive: true);
    downloading.addLast(JmDownloadingItem(comic, path!, downloadEps, _whenFinish, _whenError, _saveInfo, "jm${comic.id}"));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加Hitomi下载
  void addHitomiDownload(HitomiComic comic, String cover, String link){
    final id = "hitomi${comic.id}";
    var downloadPath = Directory("$path$pathSep$id");
    downloadPath.create(recursive: true);
    downloading.addLast(HitomiDownloadingItem(comic, path!, cover, link, _whenFinish, _whenError, _saveInfo, id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加绅士漫画下载
  void addHtDownload(HtComicInfo comic){
    final id = "Ht${comic.id}";
    var downloadPath = Directory("$path$pathSep$id");
    downloadPath.create(recursive: true);
    downloading.addLast(DownloadingHtComic(comic, path!, _whenFinish, _whenError, _saveInfo, id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  void addNhentaiDownload(NhentaiComic comic){
    final id = "nhentai${comic.id}";
    var downloadPath = Directory("$path$pathSep$id");
    downloadPath.create(recursive: true);
    downloading.addLast(NhentaiDownloadingItem(comic, path!, _whenFinish, _whenError, _saveInfo, id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  String generateId(String source, String id){
    var comicSource = ComicSource.find(source)!;
    if(comicSource.matchBriefIdReg != null){
      id = RegExp(comicSource.matchBriefIdReg!).firstMatch(id)!.group(1)!;
    }
    id = "$source-$id";
    return id;
  }

  void addCustomDownload(ComicInfoData comic, List<int> downloadEps) {
    var id = generateId(comic.sourceKey, comic.comicId);
    var downloadPath = Directory("$path$pathSep$id");
    downloadPath.create(recursive: true);
    downloading.addLast(CustomDownloadingItem(comic, downloadEps, path!, _whenFinish, _whenError, _saveInfo, id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///当一个下载任务完成时, 调用此函数
  void _whenFinish() async{
    if(!downloaded.contains(downloading.first.id)) {
      downloaded.add(downloading.first.id);
    }
    downloading.removeFirst();
    await _saveInfo();
    try{
      StateController.find<DownloadPageLogic>().fresh();
    }
    catch(e){
      // ignore
    }
    if(downloading.isNotEmpty){
      //清除已完成的任务, 开始下一个任务
      downloading.first.start();
    }else{
      //标记状态为未在下载
      isDownloading = false;
      notifications.endProgress();
    }
    _whenChange?.call();
  }

  ///暂停下载
  void pause(){
    isDownloading = false;
    downloading.first.pause();
  }

  ///出现错误时调用此函数
  void _whenError(){
    pause();
    _error = true;
    notifications.sendNotification("下载出错".tl, "点击查看详情".tl);
    _handleError?.call();
  }

  ///开始或继续下载
  void start(){
    _error = false;
    if(isDownloading) return;
    downloading.first.start();
    isDownloading = true;
  }

  ///取消指定的下载
  void cancel(String id){
    var index = 0;
    for(var i in downloading){
      if(i.id == id)  break;
      index++;
    }

    if(index == 0){
      _error = false;
      downloading.first.stop();
      downloading.removeFirst();
    }else{
      downloading.removeWhere((element) => element.id==id);
    }

    _whenChange?.call();

    if(downloading.isEmpty){
      isDownloading = false;
      notifications.endProgress();
    }else{
      downloading.first.start();
    }
    _saveInfo();
  }

  Future<DownloadedItem?> getComicOrNull(String id) async{
    var file = File("$path$pathSep$id${pathSep}info.json");
    if(!file.existsSync()){
      LogManager.addLog(LogLevel.error, "IO", "Failed to get a downloaded comic info: "
          "\nFile Not Found\nId is $id");
      return null;
    }
    var json = await file.readAsString();
    DownloadedItem comic;
    try {
      if(id.contains('-')){
        comic = CustomDownloadedItem.fromJson(jsonDecode(json));
      } else if (id.startsWith("jm")) {
        comic = DownloadedJmComic.fromMap(jsonDecode(json));
      } else if (id.startsWith("hitomi")) {
        comic = DownloadedHitomiComic.fromMap(jsonDecode(json));
      } else if (id.startsWith("nhentai")) {
        comic = NhentaiDownloadedComic.fromJson(jsonDecode(json));
      } else if (id.startsWith("Ht")) {
        comic = DownloadedHtComic.fromJson(jsonDecode(json));
      } else if (id.isNum) {
        comic = DownloadedGallery.fromJson(jsonDecode(json));
      } else {
        comic = DownloadedComic.fromJson(jsonDecode(json));
      }
      try {
        var time = file.lastModifiedSync();
        comic.time = time;
      }
      catch(e){/**/}
      return comic;
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "IO", "Failed to get a downloaded comic info:\n$e\n$s");
      return null;
    }
  }

  ///通过漫画id获取漫画信息
  Future<DownloadedComic> getComicFromId(String id) async{
    var file = File("$path$pathSep$id${pathSep}info.json");
    var json = await file.readAsString();
    var res =  DownloadedComic.fromJson(jsonDecode(json));
    try {
      var time = file.lastModifiedSync();
      res.time = time;
    }
    catch(e){
      //忽视
    }
    return res;
  }

  ///通过禁漫id获取漫画信息
  Future<DownloadedJmComic> getJmComicFormId(String id) async{
    var file = File("$path$pathSep$id${pathSep}info.json");
    var json = await file.readAsString();
    var res =  DownloadedJmComic.fromMap(jsonDecode(json));
    try {
      var time = file.lastModifiedSync();
      res.time = time;
    }
    catch(e){
      //忽视
    }
    return res;
  }

  ///删除已下载的漫画
  Future<void> delete(List<String> ids) async{
    for (var id in ids) {
      downloaded.remove(id);
      var comic = Directory("$path$pathSep$id");
      try {
        comic.delete(recursive: true);
      }
      catch(e){
        if(e is PathNotFoundException){
          //忽略
        }else{
          rethrow;
        }
      }
    }
    await _saveInfo();
  }

  /// return error message when error, or null if success.
  Future<String?> deleteEpisode(DownloadedItem comic, int ep) async{
    try {
      if (comic.downloadedEps.length == 1) {
        return "Delete Error: only one downloaded episode";
      }
      if(Directory("$path$pathSep${comic.id}$pathSep${ep+1}").existsSync()) {
        Directory("$path$pathSep${comic.id}$pathSep${ep+1}").deleteSync(recursive: true);
      }
      var size = Directory("$path$pathSep${comic.id}").getMBSizeSync();
      comic.downloadedEps.remove(ep);
      comic.comicSize = size;
      var json = const JsonEncoder().convert(comic.toJson());
      var file = File("$path$pathSep${comic.id}${pathSep}info.json");
      file.writeAsStringSync(json);
      return null;
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "IO", "$e/n$s");
      return e.toString();
    }
  }

  /// 获取漫画章节的长度, 适用于有章节的漫画
  Future<int> getEpLength(String id, int ep) async{
    var directory = Directory("$path$pathSep$id$pathSep$ep");
    var files = directory.list();
    return files.length;
  }

  /// 获取漫画的长度, 适用于无章节的漫画
  Future<int> getComicLength(String id) async{
    var directory = Directory("$path$pathSep$id");
    var files = directory.list();
    return await files.length - 2;
  }

  ///获取图片, 对于无章节的漫画, ep参数为0
  File getImage(String id, int ep, int index){
    String downloadPath;
    if(ep == 0){
      downloadPath = "$path/$id/";
    }else{
      downloadPath = "$path/$id/$ep/";
    }
    for(var file in Directory(downloadPath).listSync()){
      if(file.uri.pathSegments.last.replaceFirst(RegExp(r"\..+"), "") == index.toString()){
        return file as File;
      }
    }
    throw Exception("File not found");
  }

  Future<File> getImageAsync(String id, int ep, int index) async{
    String downloadPath;
    if(ep == 0){
      downloadPath = "$path/$id/";
    }else{
      downloadPath = "$path/$id/$ep/";
    }
    await for(var file in Directory(downloadPath).list()){
      if(file.uri.pathSegments.last.replaceFirst(RegExp(r"\..+"), "") == index.toString()){
        return file as File;
      }
    }
    throw Exception("File not found");
  }

  ///获取封面, 所有漫画源通用
  File getCover(String id){
    return File("$path$pathSep$id${pathSep}cover.jpg");
  }
}

DownloadingItem downloadingItemFromMap(
    Map<String, dynamic> map,
    void Function() whenFinish,
    void Function() whenError,
    Future<void> Function() updateInfo){
  switch(map["type"]){
    case 0: return PicDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 1: return EhDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 2: return JmDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 3: return HitomiDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 4: return DownloadingHtComic.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 5: return NhentaiDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 6: return CustomDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    default: throw UnimplementedError();
  }
}