import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import '../../foundation/log.dart';
import 'jm_image.dart';
import 'jm_models.dart';
import 'package:pica_comic/network/download_model.dart';
import 'dart:io';
import 'package:pica_comic/tools/io_tools.dart';
import 'jm_main_network.dart';

class DownloadedJmComic extends DownloadedItem{
  JmComicInfo comic;
  double? size;
  List<int> downloadedChapters;
  DownloadedJmComic(this.comic, this.size, this.downloadedChapters);
  Map<String, dynamic> toMap()=>{
    "comic": comic.toJson(),
    "size": size,
    "downloadedChapters": downloadedChapters
  };
  DownloadedJmComic.fromMap(Map<String, dynamic> map):
        comic = JmComicInfo.fromMap(map["comic"]),
        size = map["size"],
        downloadedChapters = []{
    if(map["downloadedChapters"] == null){
      //旧版本中的数据不包含这一项
      for(int i=0;i<comic.series.length;i++) {
        downloadedChapters.add(i);
      }
      if(downloadedChapters.isEmpty){
        downloadedChapters.add(0);
      }
    }else{
      downloadedChapters = List<int>.from(map["downloadedChapters"]);
    }
  }

  @override
  DownloadType get type => DownloadType.jm;

  @override
  List<int> get downloadedEps => downloadedChapters;

  @override
  List<String> get eps => List<String>.generate(comic.series.isEmpty?1:comic.series.length, (index) => "第${index+1}章");

  @override
  String get name => comic.name;

  @override
  String get id => "jm${comic.id}";

  @override
  String get subTitle => comic.author.elementAtOrNull(0)??"";

  @override
  double? get comicSize => size;
}

class JmDownloadingItem extends DownloadingItem {
  JmDownloadingItem(
      this.comic, this.path, this._downloadEps, super.whenFinish, super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.jm});

  JmComicInfo comic;
  final String path;
  int _downloadedPages = 0;
  bool _pauseFlag = true;
  int _totalPages = 0;
  int _retryTimes = 0;
  ///当前正在下载的章节
  int _index = 0;
  ///当前正在下载的页面
  int _currentPage = 0;
  bool _downloadedCover = false;
  ///要下载的章节
  List<int> _downloadEps;

  ///用于判断是否已经启动了另一个下载线程, 避免重复
  int _runtimeKey = 0;

  void retry() {
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

  ///图片链接
  List<List<String>> urls = [];

  ///获取所有的图片链接
  Future<bool> getInfo() async {
    if(comic.series.isEmpty){
      if(urls.isNotEmpty) return true;
      var res = await jmNetwork.getChapter(comic.id);
      if (res.error) {
        retry();
        return false;
      } else {
        urls.add(res.data);
        _totalPages += res.data.length;
      }
      return true;
    }
    for (int i = urls.length; i < comic.series.length; i++) {
      if(!_downloadEps.contains(i)){
        urls.add([]);
        continue;
      }
      var res = await jmNetwork.getChapter(comic.series.values.elementAt(i));
      if (res.error) {
        retry();
        return false;
      } else {
        urls.add(res.data);
        _totalPages += res.data.length;
      }
    }
    return true;
  }

  @override
  String get cover => getJmCoverUrl(comic.id);

  @override
  int get downloadedPages => _downloadedPages;

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
        _downloadedPages, _totalPages==0?1:_totalPages, "下载中", "共${downloadManager.downloading.length}项任务");
    if(! _downloadedCover){
      try {
        var dio = Dio();
        var res = await dio.get(cover,
            options: Options(responseType: ResponseType.bytes));
        var file = File("$path$pathSep$id${pathSep}cover.jpg");
        if (!await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(res.data));
        _downloadedCover = true;
      }
      catch(e, s){
        LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
        if (_pauseFlag) return;
        //下载出错重试
        retry();
        return;
      }
    }
    if(! await getInfo()){
      retry();
      return;
    }
    while(_downloadedPages < _totalPages && _index<comic.series.length){
      if(_pauseFlag)  return;
      if(_runtimeKey != currentKey) return;
      if(!_downloadEps.contains(_index)){
        _index++;
        continue;
      }
      try{
        var chapId = comic.id;
        if(comic.series.isNotEmpty){
          chapId = comic.series.values.elementAt(_index);
        }
        var url = urls[_index][_currentPage];
        for(int j=0;j<5&&_currentPage+j<urls[_index].length;j++){
          var url = urls[_index][_currentPage+j];
          var bookId = "";
          for(int i = url.length-1;i>=0;i--){
            if(url[i] == '/'){
              bookId = url.substring(i+1,url.length-5);
              break;
            }
          }
          JmDownloads.addDownload(url, chapId, bookId);
        }
        var bytes = <int>[];
        var file = File("$path$pathSep$id$pathSep${_index+1}$pathSep$_currentPage.jpg");
        if(! file.existsSync()){
          file.createSync(recursive: true);
        }

        bytes = (await JmDownloads.getFile(url)).readAsBytesSync();
        if(bytes.isEmpty){
          throw(StateError("下载图片失败"));
        }
        await file.writeAsBytes(bytes);
        await MyCacheManager().delete(url);
        _currentPage++;
        if(_currentPage >= urls[_index].length){
          _currentPage = 0;
          _index++;
        }
        _downloadedPages++;
        super.updateUi?.call();
        await super.updateInfo?.call();
        if (!_pauseFlag) {
          notifications.sendProgressNotification(_downloadedPages, totalPages, "下载中",
              "共${downloadManager.downloading.length}项任务");
        }
      }
      catch(e, s){
        LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
        if (_pauseFlag) return;
        //下载出错重试
        retry();
        return;
      }
    }
    await MyCacheManager().saveData();
    if(DownloadManager().downloading.elementAtOrNull(0) != this) return;
    saveInfo();
    super.whenFinish?.call();
  }

  void saveInfo() async{
    var file = File("$path/$id/info.json");
    var previous = <int>[];
    if(DownloadManager().downloadedJmComics.contains(id)){
      var comic = await DownloadManager().getJmComicFormId(id);
      previous = comic.downloadedEps;
    }
    if(file.existsSync()){
      file.deleteSync();
    }
    file.createSync();
    var downloadEps = (_downloadEps + previous).toSet().toList();
    downloadEps.sort();
    var downloadedItem = DownloadedJmComic(comic, await getFolderSize(Directory("$path$pathSep$id")),
      downloadEps
    );
    var json = jsonEncode(downloadedItem.toMap());
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
    "path": path,
    "_index": _index,
    "urls": urls,
    "_downloadedPages": _downloadedPages,
    "_currentPage": _currentPage,
    "id": id,
    "_downloadedCover": _downloadedCover,
    "_totalPages": _totalPages,
    "_downloadEps": _downloadEps
  };
  
  static List<List<String>> array2dFromJson(List<dynamic> json){
    var res = <List<String>>[];
    for(var list in json){
      res.add(List<String>.from(list));
    }
    return res;
  }

  JmDownloadingItem.fromMap(
    Map<String, dynamic> map,
    super.whenFinish,
    super.whenError,
    super.updateInfo,
    super.id,
    {super.type = DownloadType.jm}):
    comic = JmComicInfo.fromMap(map["comic"]),
    path = map["path"],
    _downloadedPages = map["_downloadedPages"],
    _index = map["_index"],
    urls = array2dFromJson(map["urls"]),
    _currentPage = map["_currentPage"],
    _downloadedCover = map["_downloadedCover"],
    _totalPages = map["_totalPages"],
    _downloadEps = []{
    if(map["_downloadEps"] == null){
      _downloadEps = List<int>.generate(comic.series.length, (index) => index);
      if(comic.series.isEmpty){
        _downloadEps.add(0);
      }
    }else{
      _downloadEps = List<int>.from(map["_downloadEps"]);
    }
  }

  @override
  int get totalPages => _totalPages;
}

///用于实现同时下载多张禁漫图片
class JmDownloads{
  static Map<String, DownloadingStatus> downloading = {};

  static Future<void> addDownload(String path, String chapId, String bookId) async{
    if(downloading[path] != null){
      if(downloading[path]!.message != null){
        downloading.remove(path);
      }else {
        return;
      }
    }
    downloading[path] = DownloadingStatus(null, null, false);
    try {
      await for(var progress in MyCacheManager().getJmImage(path, {}, epsId: chapId, scrambleId: "220980", bookId: bookId, )){
        if(progress.currentBytes == progress.expectedBytes){
          var res = progress.getFile();
          downloading[path]!.file = res;
          downloading[path]!.finish = true;
        }
      }
      if(downloading[path]!.file == null) {
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