import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/file_type.dart';
import 'package:pica_comic/tools/io_extensions.dart';
import 'package:pica_comic/tools/translations.dart';

import '../base.dart';
import 'app_dio.dart';
import 'download.dart';

abstract class DownloadedItem {
  ///漫画源
  DownloadType get type;

  ///漫画名
  String get name;

  ///章节
  List<String> get eps;

  ///已下载的章节
  List<int> get downloadedEps;

  ///标识符
  String get id;

  ///副标题, 通常为作者
  String get subTitle;

  ///大小
  double? get comicSize;

  ///下载的时间
  DateTime? time;

  /// tags
  List<String> get tags;

  Map<String, dynamic> toJson();

  set comicSize(double? value);

  String? directory;
}

enum DownloadType {
  picacg,
  ehentai,
  jm,
  hitomi,
  htmanga,
  nhentai,
  other,
  favorite;

  ComicType toComicType() => switch (this) {
        picacg => ComicType.picacg,
        ehentai => ComicType.ehentai,
        jm => ComicType.jm,
        hitomi => ComicType.hitomi,
        htmanga => ComicType.htManga,
        nhentai => ComicType.nhentai,
        other => ComicType.other,
        favorite => ComicType.other,
      };
}

typedef DownloadProgressCallback = void Function();

typedef DownloadProgressCallbackAsync = Future<void> Function();

abstract class DownloadingItem with _TransferSpeedMixin {
  ///完成时调用
  final DownloadProgressCallback? onFinish;

  ///出现错误时调用
  final DownloadProgressCallback? onError;

  ///更新下载信息
  final DownloadProgressCallbackAsync? updateInfo;

  ///标识符, 对于哔咔和eh, 直接使用其提供的漫画id, 禁漫开头加jm, hitomi开头加hitomi
  final String id;

  ///类型
  DownloadType type;

  /// run function start will cause this increasing by 1
  ///
  /// this is used for preventing running multiple downloading function at the same time
  int _runtimeKey = 0;

  int _retryTimes = 0;

  String? directory;

  String get path {
    var downloadPath = DownloadManager().path!;
    return "$downloadPath/$directory";
  }

  /// headers for downloading cover
  Map<String, String> get headers => {};

  int _downloadedNum = 0;

  int _downloadingEp = 0;

  /// index of downloading episode
  ///
  /// Attention, this is used for array indexing, so it starts with 0
  int get downloadingEp => _downloadingEp;

  int index = 0;

  /// all image urls
  Map<int, List<String>>? links;

  int get allowedLoadingNumber => int.tryParse(appdata.settings[79]) ?? 6;

  DownloadingItem(this.onFinish, this.onError, this.updateInfo, this.id,
      {required this.type});

  Future<void> downloadCover() async {
    var file = File("$path/cover.jpg");
    if (file.existsSync()) {
      return;
    }
    var dio = logDio();
    var res = await dio.get<Uint8List>(cover,
        options: Options(responseType: ResponseType.bytes, headers: headers));
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    file.writeAsBytesSync(res.data!);
  }

  /// retry when error
  Future<void> retry() async {
    _retryTimes++;
    if (_retryTimes > 4) {
      onError?.call();
      _retryTimes = 0;
    } else {
      await Future.delayed(Duration(seconds: 2 << _retryTimes));
      start();
    }
  }

  @mustCallSuper
  FutureOr<void> onStart() {
    if (directory == null) {
      if(DownloadManager().isExists(id)) {
        directory = DownloadManager().getDirectory(id);
      } else {
      directory = findValidDirectoryName(DownloadManager().path!, title);
      Directory(path).createSync(recursive: true);
      }
    }
  }

  final _downloading = <String, _ImageDownloadWrapper>{};

  void _addDownloading(String link, int ep, int index) {
    var downloadTo = '';
    var basename = '';
    if (haveEps) {
      downloadTo = "$path/$ep";
      basename = index.toString();
    } else {
      downloadTo = path;
      basename = index.toString();
    }
    if (_downloading["$ep$index"] == null ||
        _downloading["$ep$index"]!.error != null) {
      _downloading["$ep$index"] = _ImageDownloadWrapper(
        downloadImage(link),
        downloadTo,
        basename,
        onData,
        () {
          updateInfo?.call();
          _scheduleTasks(ep, this.index);
        },
      );
    }
  }

  void _scheduleTasks(int ep, int index) {
    var urls = links![ep]!;
    int downloading = 0;
    for (int i = index; i < urls.length; i++) {
      var task = _downloading["$ep$i"];
      if (task == null || task.error != null) {
        _addDownloading(urls[i], ep, i);
        downloading++;
      } else if (!task.isFinished) {
        downloading++;
      }
      if (downloading >= allowedLoadingNumber) {
        break;
      }
    }
  }

  /// begin or continue downloading
  void start() async {
    _runtimeKey++;
    var currentKey = _runtimeKey;
    try {
      await onStart();
      if (_runtimeKey != currentKey) return;
      notifications.sendProgressNotification(downloadedPages, totalPages,
          "下载中".tl, "${downloadManager.downloading.length} Tasks");

      // get image links and cover
      links ??= await getLinks();
      await downloadCover();
      runRecorder();

      // download images
      while (_downloadingEp < links!.length && currentKey == _runtimeKey) {
        int ep = links!.keys.elementAt(_downloadingEp);
        var urls = links![ep]!;
        while (index < urls.length && currentKey == _runtimeKey) {
          notifications.sendProgressNotification(downloadedPages, totalPages,
              "下载中".tl, "${downloadManager.downloading.length} Tasks");
          _scheduleTasks(ep, index);
          if (currentKey != _runtimeKey) return;
          var task = _downloading["$ep$index"];
          if (task == null) {
            throw Exception("Task not started");
          }
          await task.wait();
          if (task.error != null) {
            throw task.error!;
          }
          if (!task.isFinished) {
            throw Exception("Task not finished");
          }
          _downloading.remove("$ep$index");
          index++;
          _downloadedNum++;
          await updateInfo?.call();
        }
        if (currentKey != _runtimeKey) return;
        index = 0;
        _downloadingEp++;
        await updateInfo?.call();
      }

      // finish downloading
      if (DownloadManager().downloading.firstOrNull != this) return;
      onFinish?.call();
      _stopAllTasks();
    } catch (e, s) {
      if (currentKey != _runtimeKey) return;
      LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
      retry();
    }
  }

  void _stopAllTasks() {
    var shouldRemove = <String>[];
    for(var entry in _downloading.entries) {
      if(!entry.value.isFinished) {
        entry.value.cancel();
        shouldRemove.add(entry.key);
      }
    }
    for(var key in shouldRemove) {
      _downloading.remove(key);
    }
  }

  /// pause downloading
  void pause() {
    _runtimeKey++;
    stopRecorder();
    notifications.endProgress();
    _stopAllTasks();
    ImageManager.clearTasks();
  }

  /// stop downloading
  void stop() {
    _runtimeKey++;
    stopRecorder();
    _stopAllTasks();
    notifications.endProgress();
    if (downloadManager.isExists(id)) {
      if (links == null) return;
      var comicPath = "$path/";
      for (var ep in links!.keys.toList()) {
        var directory = Directory(comicPath + ep.toString());
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      }
    } else {
      var file = Directory(path);
      if (file.existsSync()) {
        file.delete(recursive: true);
      }
    }
  }

  Map<String, dynamic> toBaseMap() {
    Map<String, List<String>>? convertedData;
    if (links != null) {
      convertedData = {};
      links!.forEach((key, value) {
        convertedData![key.toString()] = value;
      });
    }

    return {
      "id": id,
      "type": type.index,
      "_downloadedNum": _downloadedNum,
      "_downloadingEp": _downloadingEp,
      "index": index,
      "links": convertedData,
      "directory": directory,
      "finishedTasks": _downloading.entries
          .where((element) => element.value.isFinished)
          .map((e) => e.key)
          .toList(),
    };
  }

  Map<String, dynamic> toMap();

  DownloadingItem.fromMap(
      Map<String, dynamic> map, this.onFinish, this.onError, this.updateInfo)
      : id = map["id"],
        type = DownloadType.values[map["type"]],
        _downloadedNum = map["_downloadedNum"],
        _downloadingEp = map["_downloadingEp"],
        index = map["index"],
        links = null {
    var data = map["links"] as Map<String, dynamic>?;
    if (data != null) {
      links = {};
      data.forEach((key, value) {
        links![int.parse(key)] = List<String>.from(value);
      });
    }
    directory = map["directory"];
    if(map["finishedTasks"] != null) {
      var finishedTasks = List<String>.from(map["finishedTasks"]);
      for (var task in finishedTasks) {
        _downloading[task] = _ImageDownloadWrapper.finished();
      }
    }
  }

  /// get all image links
  ///
  /// key - episode number(starts with 1), value - image links in this episode
  ///
  /// if platform don't have episode, this only have one key: 0.
  Future<Map<int, List<String>>> getLinks();

  /// whether this platform have episode
  bool get haveEps =>
      type != DownloadType.ehentai &&
      type != DownloadType.hitomi &&
      type != DownloadType.htmanga &&
      type != DownloadType.nhentai;

  Stream<DownloadProgress> downloadImage(String link);

  ///获取封面链接
  String get cover;

  ///总共的图片数量
  int get totalPages => links?.totalLength ?? 0;

  ///已下载的图片数量
  int get downloadedPages => _downloadedNum;

  ///标题
  String get title;

  @override
  bool operator ==(Object other) {
    if (other is DownloadingItem) {
      return id == other.id;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => id.hashCode;

  FutureOr<DownloadedItem> toDownloadedItem();

  @override
  String toString() {
    return "$id: $downloadedPages/$totalPages";
  }
}

class _ImageDownloadWrapper {
  final Stream<DownloadProgress> stream;

  final String path;

  final String fileBaseName;

  final void Function(int length)? onReceiveData;

  final void Function()? onFinished;

  Object? error;

  bool isFinished = false;

  bool _canceled = false;

  void cancel() {
    _canceled = true;
  }

  _ImageDownloadWrapper(
    this.stream,
    this.path,
    this.fileBaseName,
    this.onReceiveData,
    this.onFinished,
  ) {
    listen();
  }

  _ImageDownloadWrapper.finished():
    stream = const Stream.empty(),
    path = "",
    fileBaseName = "",
    onReceiveData = null,
    onFinished = null,
    isFinished = true;

  void listen() async {
    try {
      var last = 0;
      await for (var progress in stream) {
        if(_canceled) {
          for (var c in completers) {
            c.complete(this);
          }
          return;
        }
        onReceiveData?.call(progress.currentBytes - last);
        last = progress.currentBytes;
        if (progress.finished) {
          var data = progress.data ?? await progress.getFile().readAsBytes();
          var type = detectFileType(data);
          var file = File("$path/$fileBaseName${type.ext}");
          if (!await file.exists()) {
            await file.create(recursive: true);
          }
          await file.writeAsBytes(data);
          isFinished = true;
        }
      }
    } catch (e) {
      error = e;
    }
    if (!isFinished && error == null) {
      error = Exception("Failed to download image");
    }
    onFinished?.call();
    for (var c in completers) {
      c.complete(this);
    }
  }

  var completers = <Completer<_ImageDownloadWrapper>>[];

  Future<_ImageDownloadWrapper> wait() {
    if (isFinished) {
      return Future.value(this);
    }
    var completer = Completer<_ImageDownloadWrapper>();
    completers.add(completer);
    return completer.future;
  }
}

abstract mixin class _TransferSpeedMixin {
  int _bytesSinceLastSecond = 0;

  int _currentSpeed = 0;

  int get currentSpeed => _currentSpeed;

  Timer? timer;

  void onData(int length) {
    if (timer == null) return;
    _bytesSinceLastSecond += length;
  }

  void onNextSecond(Timer t) {
    _currentSpeed = _bytesSinceLastSecond;
    _bytesSinceLastSecond = 0;
    DownloadManager().notifyListeners();
  }

  void runRecorder() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(const Duration(seconds: 1), onNextSecond);
  }

  void stopRecorder() {
    timer?.cancel();
    timer = null;
  }
}
