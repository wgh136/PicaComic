import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/tools/cache_manager.dart';
import '../../base.dart';
import '../../tools/io_tools.dart';
import '../new_download.dart';
import 'hitomi_models.dart';
import 'dart:io';

class DownloadedHitomiComic extends DownloadedItem {
  HitomiComic comic;
  double? size;
  String cover;
  String link;

  DownloadedHitomiComic(this.comic, this.size, this.link, this.cover);

  Map<String, dynamic> toMap() =>
      {"comic": comic.toMap(), "size": size, "link": link, "cover": cover};

  DownloadedHitomiComic.fromMap(Map<String, dynamic> map)
      : comic = HitomiComic.fromMap(map["comic"]),
        size = map["size"],
        link = map["link"],
        cover = map["cover"];

  @override
  double? get comicSize => size;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["第一章"];

  @override
  String get id => "hitomi${comic.id}";

  @override
  String get name => comic.name;

  @override
  String get subTitle => (comic.artists ?? ["未知"]).isEmpty ? "未知" : (comic.artists ?? ["未知"])[0];

  @override
  DownloadType get type => DownloadType.hitomi;

  HitomiComicBrief toBrief() => comic.toBrief(link, cover);
}

class HitomiDownloadingItem extends DownloadingItem {
  HitomiDownloadingItem(this.comic, this.path, this._coverPath, this.link, super.whenFinish,
      super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.hitomi}) {
    _totalPages = comic.files.length;
  }

  final String _coverPath;

  ///漫画模型
  final HitomiComic comic;

  ///储存路径
  final String path;

  ///画廊链接
  final String link;

  ///已下载的页数
  int _downloadedPages = 0;

  ///总共的页面数
  int _totalPages = 0;

  ///是否处于暂停状态
  bool _pauseFlag = false;

  int _runtimeKey = 0;

  int _retryTimes = 0;

  late final headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "Referer": "https://hitomi.la/reader/${id.substring(6)}.html"
  };

  ///是否已经下载了封面
  bool _downloadedCover = false;

  void _retry() {
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

  Future<void> _downloadCover() async {
    try {
      if (_downloadedCover) return;
      var dio = Dio();
      var res = await dio.get(
        _coverPath,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
      var file = File("$path$pathSep$id${pathSep}cover.jpg");
      if (!await file.exists()) await file.create();
      await file.writeAsBytes(Uint8List.fromList(res.data));
      _downloadedCover = true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  String get cover => _coverPath;

  @override
  int get downloadedPages => _downloadedPages;

  @override
  void pause() {
    notifications.endProgress();
    _pauseFlag = true;
  }

  @override
  void start() async {
    _runtimeKey++;
    int currentKey = _runtimeKey;
    _pauseFlag = false;
    notifications.sendProgressNotification(
        _downloadedPages, totalPages, "下载中", "共${downloadManager.downloading.length}项任务");
    try {
      if (_pauseFlag) return;
      await _downloadCover();
      while (_downloadedPages < _totalPages) {
        if (_runtimeKey != currentKey) return;
        if (_pauseFlag) return;
        var bytes = <int>[];
        await for(var progress in MyCacheManager().getHitomiImage(comic.files[_downloadedPages], id.substring(6))){
          if(progress.expectedBytes == progress.currentBytes){
            bytes = progress.getFile().readAsBytesSync();
          }
        }
        var file = File("$path$pathSep$id$pathSep$downloadedPages.jpg");
        if (!await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(bytes));
        _downloadedPages++;
        super.updateUi?.call();
        await super.updateInfo?.call();
        if (!_pauseFlag) {
          notifications.sendProgressNotification(
              _downloadedPages, totalPages, "下载中", "共${downloadManager.downloading.length}项任务");
        } else {
          notifications.endProgress();
        }
      }
    } catch (e) {
      _retry();
      return;
    }
    await _saveInfo();
    if(currentKey == _runtimeKey) {
      super.whenFinish?.call();
    }
  }

  ///储存漫画信息
  Future<void> _saveInfo() async {
    var file = File("$path/$id/info.json");
    var item = DownloadedHitomiComic(
        comic, await getFolderSize(Directory("$path$pathSep$id")), link, _coverPath);
    var json = jsonEncode(item.toMap());
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
        "comic": comic.toMap(),
        "path": path,
        "_downloadedPages": _downloadedPages,
        "id": id,
        "_totalPages": _totalPages,
        "_downloadedCover": _downloadedCover,
        "_coverPath": _coverPath,
        "link": link
      };

  HitomiDownloadingItem.fromMap(
      Map<String, dynamic> map, super.whenFinish, super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.hitomi})
      : comic = HitomiComic.fromMap(map["comic"]),
        path = map["path"],
        _downloadedPages = map["_downloadedPages"],
        _totalPages = map["_totalPages"],
        _downloadedCover = map["_downloadedCover"],
        _coverPath = map["_coverPath"],
        link = map["link"];

  @override
  int get totalPages => _totalPages;
}
