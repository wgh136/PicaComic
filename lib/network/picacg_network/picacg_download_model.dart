import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/network/picacg_network/request.dart';
import 'package:pica_comic/tools/io_tools.dart';
import '../../base.dart';
import '../new_download.dart';
import 'methods.dart';
import 'models.dart';
import 'dart:io';

class DownloadedComic extends DownloadedItem{
  ComicItem comicItem;
  List<String> chapters;
  List<int> downloadedChapters;
  double? size;
  DownloadedComic(this.comicItem,this.chapters,this.size,this.downloadedChapters);
  Map<String,dynamic> toJson()=>{
    "comicItem": comicItem.toJson(),
    "chapters": chapters,
    "size": size,
    "downloadedChapters": downloadedChapters
  };
  DownloadedComic.fromJson(Map<String,dynamic> json):
        comicItem = ComicItem.fromJson(json["comicItem"]),
        chapters = json["chapters"].cast<String>(),
        size = json["size"],
        downloadedChapters = []{
    if(json["downloadedChapters"] == null){
      //旧版本中的数据不包含这一项
      for(int i=0;i<chapters.length;i++) {
        downloadedChapters.add(i);
      }
    }else{
      downloadedChapters = List<int>.from(json["downloadedChapters"]);
    }
  }

  @override
  DownloadType get type => DownloadType.picacg;

  @override
  List<int> get downloadedEps => downloadedChapters;

  @override
  List<String> get eps => chapters.sublist(1);

  @override
  String get name => comicItem.title;

  @override
  String get id => comicItem.id;

  @override
  String get subTitle => comicItem.author;

  @override
  double? get comicSize => size;
}

///picacg的下载进程模型
class PicDownloadingItem extends DownloadingItem {
  PicDownloadingItem(
      this.comic,
      this.path,
      this._downloadEps,
      super.whenFinish,
      super.whenError,
      super.updateInfo,
      super.id,
      {super.type = DownloadType.picacg}
  );

  ///漫画模型
  final ComicItem comic;
  ///储存路径
  final String path;
  ///总共的章节数
  late final int _totalEps = comic.epsCount;
  ///正在下载的章节, 0表示正在获取信息, 章节从1开始编号
  int _downloadingEps = 0;
  ///正在下载的页面
  int _index = 0;
  ///图片链接
  List<String> _urls = [];
  ///是否处于暂停状态
  bool _pauseFlag = false;
  ///章节名称
  var _eps = <String>[];
  ///已下载的页面数
  int _downloadPages = 0;
  ///重试次数
  int _retryTimes = 0;

  int _runtimeKey = 0;



  ///要下载的章节序号
  List<int> _downloadEps;

  @override
  Map<String, dynamic> toMap()=>{
    "type": type.index,
    "comic": comic.toJson(),
    "path": path,
    "_downloadingEps": _downloadingEps,
    "_index": _index,
    "_urls": _urls,
    "_eps": _eps,
    "_downloadPages": _downloadPages,
    "id": id,
    "downloadEps": _downloadEps
  };

  PicDownloadingItem.fromMap(
    Map<String,dynamic> map,
    super.whenFinish,
    super.whenError,
    super.updateInfo,
    super.id,
    {super.type = DownloadType.picacg}):
    comic = ComicItem.fromJson(map["comic"]),
    path = map["path"],
    _downloadingEps = map["_downloadingEps"],
    _index = map["_index"],
    _urls = List<String>.from(map["_urls"]),
    _eps = List<String>.from(map["_eps"]),
    _downloadPages = map["_downloadPages"],
    _downloadEps = []{
    if(map["downloadEps"] == null){
      _downloadEps = List<int>.generate(eps.length, (index) => index);
    }else{
      _downloadEps = List<int>.from(map["downloadEps"]);
    }
  }


  ///获取各章节名称
  List<String> get eps => _eps;

  Future<void> getEps() async {
    _eps = await network.getEps(id);
  }

  Future<void> getUrls() async {
    _urls = await network.getComicContent(id, _downloadingEps);
  }

  void retry() {
    //允许重试两次
    if(this != DownloadManager().downloading.first){
      return;
    }
    if (_retryTimes > 2) {
      super.whenError?.call();
      _retryTimes = 0;
    } else {
      _retryTimes++;
      start();
    }
  }

  @override
  void pause() {
    notifications.endProgress();
    _pauseFlag = true;
  }

  @override
  void start() async {
    _runtimeKey++;
    int currentKey = _runtimeKey;
    notifications.sendProgressNotification(
        _downloadPages, comic.pagesCount, "下载中", "共${downloadManager.downloading.length}项任务");
    _pauseFlag = false;
    if (_eps.isEmpty) {
      await getEps();
    }
    if (_pauseFlag) return;
    if (_eps.isEmpty) {
      retry();
      return;
    }
    if (_downloadingEps == 0) {
      try {
        var dio = await request();
        var res = await dio.get(getImageUrl(comic.thumbUrl),
            options: Options(responseType: ResponseType.bytes));
        var file = File("$path$pathSep$id${pathSep}cover.jpg");
        if (!await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(res.data));
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        if (_pauseFlag) return;
        //下载出错重试
        retry();
        return;
      }
      _downloadingEps++;
    }
    while (_downloadingEps <= _totalEps) {
      if(!_downloadEps.contains(_downloadingEps-1)){
        _downloadingEps++;
        continue;
      }
      if (_index == _urls.length) {
        _index = 0;
      }
      if (_pauseFlag) return;
      await getUrls();
      if (_urls.isEmpty) {
        retry();
        return;
      }
      var epPath = Directory("$path$pathSep$id$pathSep$_downloadingEps");
      await epPath.create();
      while (_index < _urls.length) {
        if(_runtimeKey != currentKey) return;
        if (_pauseFlag) return;
        try {
          var res = await DefaultCacheManager().getSingleFile(getImageUrl(_urls[_index]));
          var file = File("$path$pathSep$id$pathSep$_downloadingEps$pathSep$_index.jpg");
          if (!await file.exists()) await file.create();
          await file.writeAsBytes(Uint8List.fromList(res.readAsBytesSync()));
          _index++;
          _downloadPages++;
          super.updateUi?.call();
          await super.updateInfo?.call();
          if (!_pauseFlag) {
            notifications.sendProgressNotification(_downloadPages, comic.pagesCount, "下载中",
                "共${downloadManager.downloading.length}项任务");
          }
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
          if (_pauseFlag) return;
          //下载出错重试
          retry();
          return;
        }
      }
      _downloadingEps++;
    }
    saveInfo();
    super.whenFinish?.call();
  }

  @override
  void stop() {
    _pauseFlag = true;
    var file = Directory("$path$pathSep$id");
    file.delete(recursive: true);
  }

  ///储存漫画信息
  Future<void> saveInfo() async{
    var file = File("$path/$id/info.json");
    var downloadedItem = DownloadedComic(comic, eps, await getFolderSize(Directory("$path$pathSep$id")),_downloadEps);
    var json = jsonEncode(downloadedItem.toJson());
    await file.writeAsString(json);
  }

  @override
  get totalPages => comic.pagesCount;

  @override
  get downloadedPages => _downloadPages;

  @override
  get cover => comic.thumbUrl;

  @override
  String get title => comic.title;
}
