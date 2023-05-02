import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/jm_network/jm_image.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/views/jm_views/jm_image_provider/image_recombine.dart';
import 'dart:io';
import '../tools/io_tools.dart';

class JmDownloadingItem extends DownloadingItem {
  JmDownloadingItem(
      this.comic, this.path, super.whenFinish, super.whenError, super.updateInfo, super.id,
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

  void retry() {
    //允许重试两次
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
    _pauseFlag = false;
    notifications.sendProgressNotification(
        _downloadedPages, _totalPages==0?1:_totalPages, "下载中", "共${downloadManager.downloading.length}项任务");
    if(! _downloadedCover){
      var dio = Dio();
      var res = await dio.get(cover,
          options: Options(responseType: ResponseType.bytes));
      var file = File("$path$pathSep$id${pathSep}cover.jpg");
      if (!await file.exists()) await file.create();
      await file.writeAsBytes(Uint8List.fromList(res.data));
      _downloadedCover = true;
    }
    if(! await getInfo()){
      retry();
      return;
    }
    while(_downloadedPages < _totalPages){
      if(_pauseFlag)  return;
      try{
        var dio = Dio();
        var res = await dio.get(urls[_index][_currentPage],
            options: Options(responseType: ResponseType.bytes));
        var chapId = comic.id;
        if(comic.series.isNotEmpty){
          chapId = comic.series.values.elementAt(_index);
        }
        var url = urls[_index][_currentPage];
        var bookId = "";
        for(int i = url.length-1;i>=0;i--){
          if(url[i] == '/'){
            bookId = url.substring(i+1,url.length-5);
            break;
          }
        }
        var bytes = await startRecombineImage(Uint8List.fromList(res.data), chapId, "220980", bookId);
        var file = File("$path$pathSep$id$pathSep${_index+1}$pathSep$_currentPage.jpg");
        if(! file.existsSync()){
          file.createSync(recursive: true);
        }
        await file.writeAsBytes(bytes);
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
      catch(e){
        if (kDebugMode) {
          print(e);
        }
        if (_pauseFlag) return;
        //下载出错重试
        retry();
        return;
      }
    }
    saveInfo();
    super.whenFinish?.call();
  }

  void saveInfo() async{
    var file = File("$path/$id/info.json");
    var downloadedItem = DownloadedJmComic(comic, await getFolderSize(Directory("$path$pathSep$id")));
    var json = jsonEncode(downloadedItem.toMap());
    await file.writeAsString(json);
  }

  @override
  void stop() {
    _pauseFlag = true;
    var file = Directory("$path$pathSep$id");
    file.delete(recursive: true);
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
    "_totalPages": _totalPages
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
    _totalPages = map["_totalPages"];

  @override
  int get totalPages => _totalPages;
}
