import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/request.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'models.dart';
import 'download_models.dart';

class DownloadManage{
  String? path; //app数据目录
  List<String> downloaded = []; //已下载的漫画
  var downloading = Queue<DownloadComic>(); //下载队列
  bool isDownloading = false;
  void Function() whenChange = (){}; //用于监听下载队列的变化, 下载页面需要为此函数赋值, 从而实现监听
  void Function() handleError = (){};  //出现错误时调用, 下载页面应当修改此函数, 实现出现错误刷新页面
  bool error = false;
  bool runInit = false;

  Future<void> getPath() async{
    final appPath = await getApplicationSupportDirectory();
    path = "${appPath.path}${pathSep}download";
    var file = Directory(path!);
    if(! await file.exists()){
      await file.create(recursive: true);
    }
  }

  Future<void> getInfo() async{
    var file = File("$path${pathSep}download.json");
    if(await file.exists()) {
      var json = await file.readAsString();
      for(var i in jsonDecode(json)["downloaded"]){
        downloaded.add(i);
      }
      var downloadQueueJson = jsonDecode(json)["downloadQueue"];
      if(downloadQueueJson!=null){
        var downloadQueue = DownloadQueue.fromJson(downloadQueueJson);
        for(var comic in downloadQueue.comics){
          downloading.add(DownloadComic(comic, path!, whenFinish, whenError, saveInfo));
        }
        downloading.first.downloadPages = downloadQueue.downloadPages;
        downloading.first.downloadingEps = downloadQueue.downloadingEps;
        downloading.first.urls = downloadQueue.urls;
        downloading.first.index = downloadQueue.index;
        downloading.first.eps = downloadQueue.eps;
      }
    }else{
      await saveInfo();
    }
  }

  Future<void> init() async{
    //初始化下载管理器
    if(runInit) return;
    runInit = true;
    if(GetPlatform.isWeb){
      return;
    }
    await getPath();
    await getInfo();
  }

  Future<void> saveInfo() async{
    var comics = <ComicItem>[];
    for(var i in downloading){
      comics.add(i.comic);
    }
    String json = "";
    if(comics.isNotEmpty) {
      var downloadQueue = DownloadQueue(
          comics,
          downloading.first.downloadPages,
          downloading.first.index,
          downloading.first.downloadingEps,
          downloading.first.eps,
          downloading.first.urls
      );
      json = jsonEncode({"downloaded": downloaded, "downloadQueue": downloadQueue.toJson()});
    }else{
      json = jsonEncode({"downloaded": downloaded, "downloadQueue": null});
    }
    var file = File("$path${pathSep}download.json");
    if(! await file.exists()){
      await file.create();
    }
    file.writeAsString(json);
  }

  Future<DownloadItem> readComic(int index) async{
    var file = File("$path$pathSep${downloaded[index]}${pathSep}info.json");
    var json = await file.readAsString();
    return DownloadItem.fromJson(jsonDecode(json));
  }

  Future<void> saveComic(DownloadItem comic) async{
    var file = File("$path/${comic.comicItem.id}/info.json");
    var json = jsonEncode(comic.toJson());
    await file.writeAsString(json);
  }

  void addDownload(ComicItem comic){
    var downloadPath = Directory("$path$pathSep${comic.id}");
    downloadPath.create();
    downloading.addLast(DownloadComic(comic, path!, whenFinish, whenError,saveInfo));
    if(!isDownloading){
      downloading.first.start();
      isDownloading = true;
    }
  }

  void whenFinish() async{
    //当一个下载任务完成时, 调用此函数
    var newComic = Directory("$path$pathSep${downloading.first.id}");
    var size = await getFolderSize(newComic);
    await saveComic(DownloadItem(downloading.first.comic, downloading.first.eps,size));
    downloaded.add(downloading.first.id);
    downloading.removeFirst();
    saveInfo();
    if(downloading.isNotEmpty){
      //清除已完成的任务, 开始下一个任务
      downloading.first.start();
    }else{
      //标记状态为未在下载
      isDownloading = false;
      notifications.endProgress() ;
    }
    whenChange();
  }

  void pause(){
    isDownloading = false;
    downloading.first.pause();
  }

  void start(){
    error = false;
    if(isDownloading) return;
    var comic = downloading.first;
    comic.start();
    isDownloading = true;
  }

  void cancel(String id){
    var index = 0;
    for(var i in downloading){
      if(i.id == id)  break;
      index++;
    }

    if(index == 0){
      error = false;
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
    saveInfo();
  }

  void whenError(){
    pause();
    error = true;
    handleError();
  }

  Future<DownloadItem> getComic(int index) async{
    final id = downloaded[index];
    var file = File("$path$pathSep$id${pathSep}info.json");
    var json = await file.readAsString();
    return DownloadItem.fromJson(jsonDecode(json));
  }

  Future<DownloadItem> getComicFromId(String id) async{
    var file = File("$path$pathSep$id${pathSep}info.json");
    var json = await file.readAsString();
    return DownloadItem.fromJson(jsonDecode(json));
  }

  Future<void> delete(List<String> ids) async{
    for (var id in ids) {
      downloaded.remove(id);
      var comic = Directory("$path$pathSep$id");
      comic.delete(recursive: true);
    }
    saveInfo();
  }

  Future<int> getEpLength(String id, int ep) async{
    var directory = Directory("$path$pathSep$id$pathSep$ep");
    var files = directory.list();
    return files.length;
  }

  File getImage(String id, int ep, int index){
    return File("$path$pathSep$id$pathSep$ep$pathSep$index.jpg");
  }

  File getCover(String id){
    return File("$path$pathSep$id${pathSep}cover.jpg");
  }
}

class DownloadComic{
  /*
  管理一个下载进程
  需要提供id,章节数量,app数据目录
   */
  DownloadComic(this.comic, this.path, this.whenFinish, this.whenError, this.updateInfo);
  late String id = comic.id;
  ComicItem comic;
  String path;
  late int totalEps = comic.epsCount;
  int downloadingEps = 0;
  int index = 0;
  List<String> urls = [];
  bool pauseFlag = false;
  var eps = <String>[];
  int downloadPages = 0;
  void Function() whenFinish;
  void Function() updateUi = (){}; //创建downloadingTile时修改这个值
  void Function() whenError;
  void Function() updateInfo;


  Future<void> getEps() async{
    eps = await network.getEps(id);
  }

  Future<void> getUrls() async{
    urls = await network.getComicContent(id, downloadingEps);
  }

  Future<void> start() async{
    notifications.sendProgressNotification(downloadPages, comic.pagesCount, "下载中", "共${downloadManager.downloading.length}项任务");
    pauseFlag = false;
    if(eps.isEmpty){
      await getEps();
    }
    if(pauseFlag) return;
    if(eps.isEmpty){
      whenError(); //未能获取到章节信息调用处理错误函数
      return;
    }
    if(downloadingEps==0){
      try {
        var dio = await request();
        var res = await dio.get(comic.thumbUrl, options: Options(responseType: ResponseType.bytes));
        var file = File("$path$pathSep$id${pathSep}cover.jpg");
        if(! await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(res.data));
      }
      catch(e){
        if (kDebugMode) {
          print(e);
        }
        if(pauseFlag) return;
        //下载出错停止
        whenError();
        return;
      }
      downloadingEps++;
    }
    while(downloadingEps<=totalEps){
      if(index == urls.length) {
        index = 0;
      }
      if(pauseFlag) return;
      await getUrls();
      if(urls.isEmpty){
        whenError(); //未能获取到内容调用错误处理函数
        return;
      }
      var epPath = Directory("$path$pathSep$id$pathSep$downloadingEps");
      await epPath.create();
      while(index<urls.length){
        if(pauseFlag) return;
        try {
          var dio = await request();
          var res = await dio.get(urls[index], options: Options(responseType: ResponseType.bytes));
          var file = File("$path$pathSep$id$pathSep$downloadingEps$pathSep$index.jpg");
          if(! await file.exists()) await file.create();
          await file.writeAsBytes(Uint8List.fromList(res.data));
          index++;
          downloadPages++;
          updateUi();
          updateInfo();
          if(!pauseFlag) {
            notifications.sendProgressNotification(downloadPages, comic.pagesCount, "下载中", "共${downloadManager.downloading.length}项任务");
          }
        }
        catch(e){
          if (kDebugMode) {
            print(e);
          }
          if(pauseFlag) return;
          //下载出错停止
          whenError();
        }
      }
      downloadingEps++;
    }
    whenFinish();
  }

  void pause(){
    notifications.endProgress();
    pauseFlag = true;
  }

  void stop(){
    pauseFlag = true;
    var file = Directory("$path$pathSep$id");
    file.delete(recursive: true);
  }
}