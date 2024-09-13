import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/custom_download_model.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/network/eh_network/eh_download_model.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/favorite_download.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/ht_download_model.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/jm_network/jm_download.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/nhentai_network/download.dart';
import 'package:pica_comic/network/picacg_network/picacg_download_model.dart';
import 'package:pica_comic/pages/download_page.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:sqlite3/sqlite3.dart';

import 'nhentai_network/models.dart';
import 'picacg_network/models.dart';

typedef DownloadingCallback = void Function();

class DownloadManager with _DownloadDb implements Listenable {
  static DownloadManager? cache;

  factory DownloadManager() => cache ?? (cache = DownloadManager._create());

  DownloadManager._create();

  ///下载目录
  String? path;

  ///下载队列
  var downloading = Queue<DownloadingItem>();

  ///是否正在下载
  bool isDownloading = false;

  ///是否出现了错误
  bool _error = false;

  ///是否出现了错误
  bool get error => _error;

  ///是否初始化
  bool _runInit = false;

  @override
  Database? _db;

  final List<VoidCallback> _listeners = [];

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  ///获取下载目录
  Future<void> _getPath() async {
    if (appdata.settings[22] == "") {
      final appPath = await getApplicationSupportDirectory();
      path = "${appPath.path}/download";
    } else {
      path = appdata.settings[22];
    }
    if (App.isIOS) {
      if (path!.startsWith('/var/mobile/Containers/Data/Application/')) {
        if (!Directory(path!).existsSync()) {
          final appPath = await getApplicationSupportDirectory();
          path = "${appPath.path}/download";
        }
      }
    }
    var dir = Directory(path!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    if (App.isAndroid) {
      var file = File("$path/.nomedia");
      if (!file.existsSync()) {
        await file.create();
      }
    }
  }

  ///更换下载目录
  Future<String> updatePath(String newPath, {bool transform = true}) async {
    if (transform) {
      var source = Directory(path!);
      final appPath = await getApplicationSupportDirectory();
      var destination = Directory(
        newPath == "" ? "${appPath.path}${pathSep}download" : newPath,
      );
      try {
        await copyDirectory(source, destination);
        for (var i in source.listSync()) {
          await i.delete(recursive: true);
        }
      } catch (e) {
        return e.toString();
      }
    }

    _runInit = false;
    _db!.dispose();
    downloading.clear();
    await init();
    return "ok";
  }

  ///读取数据, 获取未完成的下载和已下载的漫画ID
  Future<void> _getInfo() async {
    //读取数据
    var file = File("$path${pathSep}newDownload.json");
    if (!file.existsSync()) {
      await _saveInfo();
    } else {
      try {
        var json = const JsonDecoder().convert(file.readAsStringSync());
        for (var item in json["downloading"]) {
          downloading.add(
              downloadingItemFromMap(item, _onFinish, _onError, _saveInfo));
        }
      } catch (e, s) {
        LogManager.addLog(LogLevel.error, "IO",
            "Failed to read downloaded information\n$e\n$s");
        file.deleteSync();
        await _saveInfo();
      }
    }
  }

  Future<void> _initDb() async {
    var oldData = <String, DownloadedItem>{};
    if (!File("$path/download.db").existsSync()) {
      for (var entry in Directory(path!).listSync()) {
        if (entry is Directory) {
          var infoFile = File("${entry.path}/info.json");
          if (infoFile.existsSync()) {
            var id = entry.name;
            var json = infoFile.readAsStringSync();
            var time = infoFile.lastModifiedSync();
            var comic = _getComicFromJson(id, json, time);
            if (comic != null) {
              infoFile.delete();
              var directory = comic.name;
              int i = -1;
              while (entry is Directory) {
                try {
                  entry = entry.renameX(directory);
                  break;
                } catch (e) {
                  i++;
                  if(i > 20) {
                    // it seems that the error is unrelated to the directory name
                    Log.error("IO", "Failed to rename directory: Trying rename ${entry.name} to ${comic.name}\n$e");
                    break;
                  }
                  directory = comic.name + i.toString();
                }
              }
              oldData[entry.name] = comic;
            }
          }
        }
      }
    }
    _db = sqlite3.open("$path/download.db");
    _createTable();
    for (var entry in oldData.entries) {
      _addToDb(entry.value, entry.key);
    }
  }

  void dispose() {
    _runInit = false;
    downloading.forEach((e) => e.stop());
    downloading.clear();
    _db?.dispose();
    _db = null;
  }

  ///初始化下载管理器
  Future<void> init() async {
    if (_runInit) return;
    _runInit = true;
    await _getPath();
    await _getInfo();
    await _initDb();
  }

  ///储存当前的下载队列信息, 每完成一张图片的下载调用一次
  Future<void> _saveInfo() async {
    notifyListeners();
    var data = <String, dynamic>{};
    data["downloading"] = <Map<String, dynamic>>[];
    for (var item in downloading) {
      data["downloading"].add(item.toMap());
    }
    var file = File("$path${pathSep}newDownload.json");
    await file.writeAsString(const JsonEncoder().convert(data));
  }

  /// move comic to first
  void moveToFirst(DownloadingItem item) {
    if (downloading.first == item) {
      return;
    }
    pause();
    downloading.remove(item);
    downloading.addFirst(item);
    start();
  }

  String generateId(String source, String id) {
    var comicSource = ComicSource.find(source)!;
    if (comicSource.matchBriefIdReg != null) {
      id = RegExp(comicSource.matchBriefIdReg!).firstMatch(id)!.group(1)!;
    }
    id = "$source-$id";
    return id;
  }

  ///当一个下载任务完成时, 调用此函数
  void _onFinish() async {
    var task = downloading.removeFirst();
    _addToDb(await task.toDownloadedItem(), task.directory!);
    await _saveInfo();
    StateController.findOrNull<DownloadPageLogic>()?.refresh();
    if (downloading.isNotEmpty) {
      //清除已完成的任务, 开始下一个任务
      downloading.first.start();
    } else {
      //标记状态为未在下载
      isDownloading = false;
      notifications.endProgress();
    }
  }

  ///暂停下载
  void pause() {
    isDownloading = false;
    downloading.first.pause();
  }

  ///出现错误时调用此函数
  void _onError() {
    pause();
    _error = true;
    notifications.sendNotification("下载出错".tl, "点击查看详情".tl);
    notifyListeners();
  }

  ///开始或继续下载
  void start() {
    _error = false;
    if (isDownloading) return;
    downloading.first.start();
    isDownloading = true;
  }

  ///取消指定的下载
  void cancel(String id) {
    var index = 0;
    for (var i in downloading) {
      if (i.id == id) break;
      index++;
    }

    if (index == 0) {
      _error = false;
      downloading.first.stop();
      downloading.removeFirst();
    } else {
      downloading.removeWhere((element) => element.id == id);
    }

    notifyListeners();

    if (downloading.isEmpty) {
      isDownloading = false;
      notifications.endProgress();
    } else {
      downloading.first.start();
    }
    _saveInfo();
  }

  Future<DownloadedItem?> getComicOrNull(String id) async {
    return _getComicWithDb(id);
  }

  ///删除已下载的漫画
  Future<void> delete(List<String> ids) async {
    for (var id in ids) {
      _deleteFromDb(id);
      var comic = Directory("$path/${getDirectory(id)}");
      try {
        comic.delete(recursive: true);
      } catch (e) {
        if (e is PathNotFoundException) {
          //忽略
        } else {
          rethrow;
        }
      }
    }
  }

  /// return error message when error, or null if success.
  Future<String?> deleteEpisode(DownloadedItem comic, int ep) async {
    try {
      if (comic.downloadedEps.length == 1) {
        return "Delete Error: only one downloaded episode";
      }
      if (Directory("$path/${getDirectory(comic.id)}/${ep + 1}").existsSync()) {
        Directory("$path/${getDirectory(comic.id)}/${ep + 1}")
            .deleteSync(recursive: true);
      }
      var size = Directory("$path/${getDirectory(comic.id)}").getMBSizeSync();
      comic.downloadedEps.remove(ep);
      comic.comicSize = size;
      _addToDb(comic, comic.directory ?? getDirectory(comic.id));
      return null;
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "IO", "$e/n$s");
      return e.toString();
    }
  }

  /// 获取漫画章节的长度, 适用于有章节的漫画
  Future<int> getEpLength(String id, int ep) async {
    var directory = Directory("$path/${getDirectory(id)}/$ep");
    var files = directory.list();
    return files.length;
  }

  /// 获取漫画的长度, 适用于无章节的漫画
  Future<int> getComicLength(String id) async {
    var directory = Directory("$path/${getDirectory(id)}");
    var files = directory.list();
    return await files.length - 1;
  }

  ///获取图片, 对于无章节的漫画, ep参数为0
  File getImage(String id, int ep, int index) {
    String downloadPath;
    if (ep == 0) {
      downloadPath = "$path/${getDirectory(id)}/";
    } else {
      downloadPath = "$path/${getDirectory(id)}/$ep/";
    }
    for (var file in Directory(downloadPath).listSync()) {
      if (file.uri.pathSegments.last.replaceFirst(RegExp(r"\..+"), "") ==
          index.toString()) {
        return file as File;
      }
    }
    throw Exception("File not found");
  }

  Future<File> getImageAsync(String id, int ep, int index) async {
    String downloadPath;
    if (ep == 0) {
      downloadPath = "$path/${getDirectory(id)}/";
    } else {
      downloadPath = "$path/${getDirectory(id)}/$ep/";
    }
    var fileName  = _downloadedFileName["$id$ep$index"];
    if(fileName != null) {
      return File(downloadPath + fileName);
    }
    await for (var file in Directory(downloadPath).list()) {
      var i = file.uri.pathSegments.last.replaceFirst(RegExp(r"\..+"), "");
      if(i.isNum) {
        if(_downloadedFileName.length > 2000) {
          _downloadedFileName.remove(_downloadedFileName.keys.first);
        }
        _downloadedFileName["$id$ep$i"] = file.name;
      }
    }
    if(_downloadedFileName["$id$ep$index"] == null) {
      throw Exception("File not found");
    }
    return File(downloadPath + _downloadedFileName["$id$ep$index"]!);
  }

  static final _downloadedFileName = <String, String>{};

  ///获取封面, 所有漫画源通用
  File getCover(String id) {
    return File("$path/${getDirectory(id)}/cover.jpg");
  }
}

DownloadingItem downloadingItemFromMap(
    Map<String, dynamic> map,
    void Function() whenFinish,
    void Function() whenError,
    Future<void> Function() updateInfo) {
  switch (map["type"]) {
    case 0:
      return PicDownloadingItem.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 1:
      return EhDownloadingItem.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 2:
      return JmDownloadingItem.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 3:
      return HitomiDownloadingItem.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 4:
      return DownloadingHtComic.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 5:
      return NhentaiDownloadingItem.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 6:
      return CustomDownloadingItem.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    case 7:
      return FavoriteDownloading.fromMap(
          map, whenFinish, whenError, updateInfo, map["id"]);
    default:
      throw UnimplementedError();
  }
}

extension AddDownloadExt on DownloadManager {
  ///添加哔咔漫画下载
  void addPicDownload(ComicItem comic, List<int> downloadEps) {
    downloading.addLast(PicDownloadingItem(
        comic, downloadEps, _onFinish, _onError, _saveInfo, comic.id));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加E-Hentai下载
  void addEhDownload(Gallery gallery, [int type = 0]) {
    final id = getGalleryId(gallery.link);
    downloading.addLast(
        EhDownloadingItem(gallery, _onFinish, _onError, _saveInfo, id, type));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加禁漫下载
  void addJmDownload(JmComicInfo comic, List<int> downloadEps) {
    downloading.addLast(JmDownloadingItem(
        comic, downloadEps, _onFinish, _onError, _saveInfo, "jm${comic.id}"));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加Hitomi下载
  void addHitomiDownload(HitomiComic comic, String cover, String link) {
    final id = "hitomi${comic.id}";
    downloading.addLast(HitomiDownloadingItem(
        comic, cover, link, _onFinish, _onError, _saveInfo, id));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  ///添加绅士漫画下载
  void addHtDownload(HtComicInfo comic) {
    final id = "Ht${comic.id}";
    downloading
        .addLast(DownloadingHtComic(comic, _onFinish, _onError, _saveInfo, id));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  void addNhentaiDownload(NhentaiComic comic) {
    final id = "nhentai${comic.id}";
    downloading.addLast(
        NhentaiDownloadingItem(comic, _onFinish, _onError, _saveInfo, id));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  void addCustomDownload(ComicInfoData comic, List<int> downloadEps) {
    var id = generateId(comic.sourceKey, comic.comicId);
    downloading.addLast(CustomDownloadingItem(
        comic, downloadEps, _onFinish, _onError, _saveInfo, id));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }

  void addFavoriteDownload(FavoriteItem comic) {
    var id = switch (comic.type.key) {
      0 => comic.target,
      1 => getGalleryId(comic.target),
      2 => "jm${comic.target}",
      3 => "hitomi${RegExp(r"\d+(?=\.html)").firstMatch(comic.target)![0]!}",
      4 => "Ht${comic.target}",
      6 => "nhentai${comic.target}",
      _ => generateId(comic.type.comicSource.key, comic.target)
    };
    downloading.addLast(
        FavoriteDownloading(comic, _onFinish, _onError, _saveInfo, id));
    _saveInfo();
    if (!isDownloading) {
      downloading.first.start();
      isDownloading = true;
    }
  }
}

DownloadedItem? _getComicFromJson(String id, String json, DateTime time, [String? directory]) {
  DownloadedItem comic;
  try {
    if (id.contains('-')) {
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
    comic.time = time;
    comic.directory = directory;
    return comic;
  } catch (e, s) {
    LogManager.addLog(
        LogLevel.error, "IO", "Failed to get a downloaded comic info:\n$e\n$s");
    return null;
  }
}

abstract mixin class _DownloadDb {
  Database? get _db;

  void _createTable() {
    _db!.execute('''
      create table if not exists download (
        id text primary key,
        title text,
        subtitle text,
        time int,
        directory text,
        size int,
        json text
      )
    ''');
  }

  void _addToDb(DownloadedItem item, String directory, [DateTime? time]) {
    _db!.execute('''
      insert or replace into download
      values (?,?,?,?,?,?,?)
    ''', [
      item.id,
      item.name,
      item.subTitle,
      (time ?? DateTime.now()).millisecondsSinceEpoch,
      directory,
      item.comicSize,
      jsonEncode(item.toJson()),
    ]);
  }

  bool isExists(String id) {
    var result = _db!.select('''
      select id from download
      where id = ?
    ''', [id]);
    return result.isNotEmpty;
  }

  void _deleteFromDb(String id) {
    _db!.execute('''
      delete from download
      where id = ?
    ''', [id]);
  }

  DownloadedItem? _getComicWithDb(String id) {
    var result = _db!.select('''
      select * from download
      where id = ?
    ''', [id]);
    if (result.isEmpty) return null;
    var data = result.first;
    return _getComicFromJson(
      data['id'],
      data['json'],
      DateTime.fromMillisecondsSinceEpoch(data['time']),
      data['directory'],
    );
  }

  int get total {
    var result = _db!.select('''
      select count(*) from download
    ''');
    return result.first['count(*)'];
  }

  /// order: time, title, subtitle, size
  List<DownloadedItem> getAll(
      [String order = 'time', String direction = 'desc']) {
    var result = _db!.select('''
      select * from download
      order by $order $direction
    ''');
    return result
        .map(
          (e) => _getComicFromJson(
            e['id'],
            e['json'],
            DateTime.fromMillisecondsSinceEpoch(e['time']),
            e['directory']
          )!,
        )
        .toList();
  }

  static final _cache = <String, String>{};

  String getDirectory(String id) {
    var directory = _cache[id];
    if(directory == null) {
      var result = _db!.select('''
      select directory from download
      where id = ?
    ''', [id]);
      directory = result.first['directory'];
      directory = _findAccurateDirectory(directory!);
      if(_cache.length > 50) {
        _cache.remove(_cache.keys.first);
      }
      _cache[id] = directory;
    }
    return directory;
  }

  String _findAccurateDirectory(String directory) {
    return sanitizeFileName(directory);
  }
}
