import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/jm_network/jm_download.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/network/picacg_network/picacg_download_model.dart';
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

class DownloadManager{
  static DownloadManager? cache;

  factory DownloadManager() => cache??(cache=DownloadManager._create());

  DownloadManager._create();

  ///下载目录
  String? path;

  ///已下载的picacg漫画
  List<String> downloaded = [];

  ///已下载的e-hentai画廊
  List<String> downloadedGalleries = [];

  ///已下载的禁漫漫画
  List<String> downloadedJmComics = [];

  ///已下载的Hitomi漫画
  List<String> downloadedHitomiComics = [];

  ///下载队列
  var downloading = Queue<DownloadingItem>();

  ///是否正在下载
  bool isDownloading = false;

  ///用于监听下载队列的变化, 下载页面需要为此函数变量赋值, 从而实现监听
  void Function() whenChange = (){};

  ///出现错误时调用, 下载页面应当修改此函数变量, 实现出现错误刷新页面
  void Function() handleError = (){};

  ///是否出现了错误
  bool _error = false;

  ///是否出现了错误
  get error => _error;

  ///是否初始化
  bool _runInit = false;

  ///获取下载目录
  Future<void> _getPath() async{
    final appPath = await getApplicationSupportDirectory();
    path = "${appPath.path}${pathSep}download";
    var file = Directory(path!);
    if(! await file.exists()){
      await file.create(recursive: true);
    }
  }

  ///读取数据, 获取未完成的下载和已下载的漫画ID
  Future<void> _getInfo() async{
    //读取数据
    var file = File("$path${pathSep}newDownload.json");
    if(! file.existsSync()){
      await _saveInfo();
    }
    var json = const JsonDecoder().convert(file.readAsStringSync());
    for(var s in json["downloaded"]){
      downloaded.add(s);
    }
    for(var s in json["downloadedGalleries"]){
      downloadedGalleries.add(s);
    }
    for(var s in json["downloadedJmComics"]??[]){
      downloadedJmComics.add(s);
    }
    for(var s in json["downloadedHitomiComics"]??[]){
      downloadedHitomiComics.add(s);
    }
    for(var item in json["downloading"]){
      downloading.add(downloadingItemFromMap(item, _whenFinish, _whenError, _saveInfo)!);
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
    if(GetPlatform.isWeb){
      return;
    }
    await _getPath();
    await _getInfo();
  }

  ///储存当前的下载队列信息, 每完成一张图片的下载调用一次
  Future<void> _saveInfo() async{
    var data = <String, dynamic>{};
    data["downloaded"] = downloaded;
    data["downloadedGalleries"] = downloadedGalleries;
    data["downloadedJmComics"] = downloadedJmComics;
    data["downloadedHitomiComics"] = downloadedHitomiComics;
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

  ///添加哔咔漫画下载
  void addPicDownload(ComicItem comic, List<int> downloadEps){
    var downloadPath = Directory("$path$pathSep${comic.id}");
    downloadPath.create();
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
    downloadPath.create();
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
    downloadPath.create();
    downloading.addLast(JmDownloadingItem(comic, path!, downloadEps, _whenFinish, _whenError, _saveInfo, "jm${comic.id}"));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  void addHitomiDownload(HitomiComic comic, String cover, String link){
    final id = "hitomi${comic.id}";
    var downloadPath = Directory("$path$pathSep$id");
    downloadPath.create();
    downloading.addLast(HitomiDownloadingItem(comic, path!, cover, link, _whenFinish, _whenError, _saveInfo, id));
    _saveInfo();
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///当一个下载任务完成时, 调用此函数
  void _whenFinish() async{
    if(downloading.first.type == DownloadType.picacg) {
      downloaded.add(downloading.first.id);
    }else if(downloading.first.type == DownloadType.ehentai){
      downloadedGalleries.add(downloading.first.id);
    }else if(downloading.first.type == DownloadType.jm){
      downloadedJmComics.add(downloading.first.id);
    }else if(downloading.first.type == DownloadType.hitomi){
      downloadedHitomiComics.add(downloading.first.id);
    }
    downloading.removeFirst();
    await _saveInfo();
    if(downloading.isNotEmpty){
      //清除已完成的任务, 开始下一个任务
      downloading.first.start();
    }else{
      //标记状态为未在下载
      isDownloading = false;
      notifications.endProgress();
    }
    whenChange();
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
    notifications.sendNotification("下载出错", "点击查看详情");
    handleError();
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
      downloading.remove(index);
    }

    if(downloading.isEmpty){
      isDownloading = false;
      notifications.endProgress();
    }else{
      downloading.first.start();
    }
    _saveInfo();
  }

  ///通过漫画id获取漫画信息
  Future<DownloadedComic> getComicFromId(String id) async{
    try {
      var file = File("$path$pathSep$id${pathSep}info.json");
      var json = await file.readAsString();
      return DownloadedComic.fromJson(jsonDecode(json));
    }
    catch(e){
      downloaded.remove(id);
      _saveInfo();
      rethrow;
    }
  }

  ///通过画廊id获取画廊信息
  Future<DownloadedGallery> getGalleryFormId(String id) async{
    try {
      var file = File("$path$pathSep$id${pathSep}info.json");
      var json = await file.readAsString();
      return DownloadedGallery.fromJson(jsonDecode(json));
    }
    catch(e){
      downloadedGalleries.remove(id);
      _saveInfo();
      rethrow;
    }
  }

  ///通过禁漫id获取漫画信息
  Future<DownloadedJmComic> getJmComicFormId(String id) async{
    try {
      var file = File("$path$pathSep$id${pathSep}info.json");
      var json = await file.readAsString();
      return DownloadedJmComic.fromMap(jsonDecode(json));
    }
    catch(e){
      downloadedJmComics.remove(id);
      _saveInfo();
      rethrow;
    }
  }

  Future<DownloadedHitomiComic> getHitomiComicFromId(String id) async{
    try {
      var file = File("$path$pathSep$id${pathSep}info.json");
      var json = await file.readAsString();
      return DownloadedHitomiComic.fromMap(jsonDecode(json));
    }
    catch(e){
      downloadedHitomiComics.remove(id);
      _saveInfo();
      rethrow;
    }
  }

  ///删除已下载的漫画
  Future<void> delete(List<String> ids) async{
    for (var id in ids) {
      downloaded.remove(id);
      downloadedGalleries.remove(id);
      downloadedJmComics.remove(id);
      downloadedHitomiComics.remove(id);
      var comic = Directory("$path$pathSep$id");
      comic.delete(recursive: true);
    }
    await _saveInfo();
  }

  ///获取漫画章节的长度, 适用于picacg和禁漫
  Future<int> getEpLength(String id, int ep) async{
    var directory = Directory("$path$pathSep$id$pathSep$ep");
    var files = directory.list();
    return files.length;
  }

  ///获取eh或hitomi画廊长度
  Future<int> getEhOrHitomiPages(String id) async{
    var directory = Directory("$path$pathSep$id");
    var files = directory.list();
    return await files.length - 2;
  }

  ///获取图片, 对于 eh 和 hitomi , ep参数为0
  File getImage(String id, int ep, int index){
    if(ep == 0){
      return File("$path$pathSep$id$pathSep$index.jpg");
    }
    return File("$path$pathSep$id$pathSep$ep$pathSep$index.jpg");
  }

  ///获取封面, 所有漫画源通用
  File getCover(String id){
    return File("$path$pathSep$id${pathSep}cover.jpg");
  }
}

DownloadingItem? downloadingItemFromMap(
    Map<String, dynamic> map,
    void Function() whenFinish,
    void Function() whenError,
    Future<void> Function() updateInfo){
  switch(map["type"]){
    case 0: return PicDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 1: return EhDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 2: return JmDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    case 3: return HitomiDownloadingItem.fromMap(map, whenFinish, whenError, updateInfo, map["id"]);
    default: return null;
  }
}