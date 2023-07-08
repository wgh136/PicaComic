import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/download_model.dart';
import '../../base.dart';
import '../../foundation/cache_manager.dart';
import '../../foundation/log.dart';
import '../../tools/io_tools.dart';
import '../download.dart';

class DownloadedHtComic extends DownloadedItem{
  DownloadedHtComic(this.comic, this.size);

  HtComicInfo comic;

  double? size;

  @override
  double? get comicSize => size;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["第一章"];

  @override
  String get id => "Ht${comic.id}";

  @override
  String get name => comic.name;

  @override
  String get subTitle => comic.uploader;

  @override
  DownloadType get type => DownloadType.htmanga;

  Map<String, dynamic> toJson() => {
    "comic": comic.toJson(),
    "size": size
  };

  DownloadedHtComic.fromJson(Map<String, dynamic> json):
      comic = HtComicInfo.fromJson(json["comic"]),
      size = json["size"];
}

class DownloadingHtComic extends DownloadingItem{
  DownloadingHtComic(this.comic, this.path,
      super.whenFinish, super.whenError, super.updateInfo, super.id,
      {super.type=DownloadType.htmanga});

  final HtComicInfo comic;

  ///储存路径
  final String path;

  ///已下载的页数
  int _downloadedPages = 0;

  ///是否处于暂停状态
  bool _pauseFlag = false;

  ///图片链接
  List<String>? _urls;

  ///是否已经下载了封面
  bool _downloadedCover = false;

  int _runtimeKey = 0;

  @override
  String get cover => comic.coverPath;

  @override
  int get downloadedPages => _downloadedPages;

  Future<void> _getUrls() async{
    try{
      if(_urls != null) return;
      var res = await HtmangaNetwork().getImages(comic.id);
      if(res.error){
        throw Exception("Error when fetching image urls");
      }
      _urls = res.data;
    }
    catch(e){
      rethrow;
    }
  }

  int _retryTimes = 0;

  void _retry() {
    //允许重试两次
    if(DownloadManager().downloading.elementAtOrNull(0) != this) return;
    if (_retryTimes > 2) {
      super.whenError?.call();
      _retryTimes = 0;
    } else {
      _retryTimes++;
      start();
    }
  }

  Future<void> _downloadCover() async{
    try{
      if (_downloadedCover) return;
      var dio = Dio();
      var res =
      await dio.get(
        comic.coverPath,
        options: Options(
            responseType: ResponseType.bytes,
        ),
      );
      var file = File("$path$pathSep$id${pathSep}cover.jpg");
      if (!await file.exists()) await file.create();
      await file.writeAsBytes(Uint8List.fromList(res.data));
      _downloadedCover = true;
    }
    catch(e){
      rethrow;
    }
  }

  @override
  void pause() {
    notifications.endProgress();
    _pauseFlag = true;
  }

  @override
  void start() async{
    _runtimeKey++;
    int currentKey = _runtimeKey;
    _pauseFlag = false;
    notifications.sendProgressNotification(
        _downloadedPages, totalPages, "下载中", "共${downloadManager.downloading.length}项任务");
    try{
      if (_pauseFlag) return;
      await _getUrls();
      await _downloadCover();
      while (_downloadedPages < totalPages) {
        if(_runtimeKey != currentKey) return;
        if (_pauseFlag) return;
        for(int i=0;i<5&&_downloadedPages+i < totalPages;i++){
          HtDownloads.addDownload(_urls![_downloadedPages+i]);
        }
        var bytes = (await HtDownloads.getFile(_urls![_downloadedPages])).readAsBytesSync();
        var file = File("$path$pathSep$id$pathSep$downloadedPages.jpg");
        if (!await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(bytes));
        _downloadedPages++;
        super.updateUi?.call();
        await super.updateInfo?.call();
        if (!_pauseFlag) {
          notifications.sendProgressNotification(_downloadedPages, totalPages, "下载中",
              "共${downloadManager.downloading.length}项任务");
        } else {
          notifications.endProgress();
        }
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
      _retry();
      return;
    }
    await MyCacheManager().saveData();
    if(DownloadManager().downloading.elementAtOrNull(0) != this) return;
    await _saveInfo();
    super.whenFinish?.call();
  }

  ///储存漫画信息
  Future<void> _saveInfo() async{
    var file = File("$path/$id/info.json");
    var item = DownloadedHtComic(comic, await getFolderSize(Directory("$path$pathSep$id")));
    var json = jsonEncode(item.toJson());
    await file.writeAsString(json);
  }

  @override
  void stop() {
    _pauseFlag = true;
    var file = Directory("$path$pathSep$id");
    if(file.existsSync()) {
      file.delete(recursive: true);
    }
  }

  @override
  String get title => comic.name;

  @override
  Map<String, dynamic> toMap() => {
    "type": type.index,
    "comic": comic.toJson(),
    "_downloadedPages": _downloadedPages,
    "_urls": _urls,
    "path": path
  };

  DownloadingHtComic.fromMap(
      Map<String, dynamic> map,
      super.whenFinish,
      super.whenError,
      super.updateInfo,
      super.id,{super.type=DownloadType.htmanga}):
      comic = HtComicInfo.fromJson(map["comic"]),
      path = map["path"]{
    _downloadedPages = map["_downloadedPages"];
    _urls = map["_urls"];
  }

  @override
  int get totalPages => comic.pages;

}

///用于实现同时下载多张Ht图片
class HtDownloads{
  static Map<String, DownloadingStatus> downloading = {};

  static Future<void> addDownload(String path) async{
    if(downloading[path] != null){
      if(downloading[path]!.message != null){
        downloading.remove(path);
      }else {
        return;
      }
    }
    downloading[path] = DownloadingStatus(null, null, false);
    try {
      await for (var progress in MyCacheManager().getImage(path)){
        if(progress.expectedBytes == progress.currentBytes) {
          var res = progress.getFile();
          downloading[path]!.file = res;
          downloading[path]!.finish = true;
        }
      }
      if(downloading[path]!.file == null){
        throw Error();
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
      downloading[path]!.message = e.toString();
    }
  }

  static Future<File> getFile(String path) async{
    if(downloading[path] == null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    while(!downloading[path]!.finish){
      await Future.delayed(const Duration(milliseconds: 100));
      if(downloading[path]!.message != null){
        throw Exception(downloading[path]!.message);
      }
    }
    var res = downloading[path]!.file!;
    downloading.remove(path);
    return res;
  }
}

class DownloadingStatus{
  File? file;
  String? message;
  bool finish;

  DownloadingStatus(this.file, this.message, this.finish);
}