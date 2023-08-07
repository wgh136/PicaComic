import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'jm_image.dart';
import 'jm_models.dart';
import 'package:pica_comic/network/download_model.dart';
import 'dart:io';
import 'package:pica_comic/tools/io_tools.dart';
import 'jm_main_network.dart';

class DownloadedJmComic extends DownloadedItem {
  JmComicInfo comic;
  double? size;
  List<int> downloadedChapters;
  DownloadedJmComic(this.comic, this.size, this.downloadedChapters);
  Map<String, dynamic> toMap() => {
        "comic": comic.toJson(),
        "size": size,
        "downloadedChapters": downloadedChapters
      };
  DownloadedJmComic.fromMap(Map<String, dynamic> map)
      : comic = JmComicInfo.fromMap(map["comic"]),
        size = map["size"],
        downloadedChapters = [] {
    if (map["downloadedChapters"] == null) {
      //旧版本中的数据不包含这一项
      for (int i = 0; i < comic.series.length; i++) {
        downloadedChapters.add(i);
      }
      if (downloadedChapters.isEmpty) {
        downloadedChapters.add(0);
      }
    } else {
      downloadedChapters = List<int>.from(map["downloadedChapters"]);
    }
  }

  @override
  DownloadType get type => DownloadType.jm;

  @override
  List<int> get downloadedEps => downloadedChapters;

  @override
  List<String> get eps => List<String>.generate(
      comic.series.isEmpty ? 1 : comic.series.length,
      (index) => "第${index + 1}章");

  @override
  String get name => comic.name;

  @override
  String get id => "jm${comic.id}";

  @override
  String get subTitle => comic.author.elementAtOrNull(0) ?? "";

  @override
  double? get comicSize => size;
}

class JmDownloadingItem extends DownloadingItem {
  JmDownloadingItem(this.comic, super.path, this._downloadEps, super.whenFinish,
      super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.jm});

  JmComicInfo comic;

  ///要下载的章节
  final List<int> _downloadEps;

  @override
  String get cover => getJmCoverUrl(comic.id);

  @override
  Future<void> saveInfo() async {
    var file = File("$path/$id/info.json");
    var previous = <int>[];
    if (DownloadManager().downloadedJmComics.contains(id)) {
      var comic = await DownloadManager().getJmComicFormId(id);
      previous = comic.downloadedEps;
    }
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync();
    var downloadEps = (_downloadEps + previous).toSet().toList();
    downloadEps.sort();
    var downloadedItem = DownloadedJmComic(
        comic, await getFolderSize(Directory("$path$pathSep$id")), downloadEps);
    var json = jsonEncode(downloadedItem.toMap());
    await file.writeAsString(json);
  }

  @override
  String get title => comic.name;

  @override
  Future<Uint8List> getImage(String link) async{
    var bookId = "";
    for (int i = link.length - 1; i >= 0; i--) {
      if (link[i] == '/') {
        bookId = link.substring(i + 1, link.length - 5);
        break;
      }
    }
    await for(var s in MyCacheManager()
        .getJmImage(link, {},
        epsId: comic.series[links!.keys.toList()[downloadingEp]]!,
        scrambleId: "220980",
        bookId: bookId)){
      if(s.finished){
        return s.getFile().readAsBytesSync();
      }
    }
    throw Exception("Failed to download image");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async {
    if (comic.series.isEmpty) {
      comic.series[1] = id.replaceFirst("jm", "");
    }
    var res = <int, List<String>>{};
    for (var key in comic.series.keys.toList()) {
      if (!_downloadEps.contains(key-1)) continue;
      res[key] = (await JmNetwork().getChapter(comic.series[key]!)).data;
    }
    return res;
  }

  @override
  void loadImageToCache(String link) {
    var bookId = "";
    for (int i = link.length - 1; i >= 0; i--) {
      if (link[i] == '/') {
        bookId = link.substring(i + 1, link.length - 5);
        break;
      }
    }
    addStreamSubscription(MyCacheManager()
        .getJmImage(link, {},
          epsId: comic.series[links!.keys.toList()[downloadingEp]]!,
          scrambleId: "220980",
          bookId: bookId)
        .listen((event) {}));
  }

  @override
  Map<String, dynamic> toMap() => {
    "comic": comic.toJson(),
    "_downloadEps": _downloadEps,
    ...super.toBaseMap()
  };

  JmDownloadingItem.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id):
        comic = JmComicInfo.fromMap(map["comic"]),
        _downloadEps = List<int>.from(map["_downloadEps"]),
        super.fromMap(map, whenFinish, whenError, updateInfo);
}
