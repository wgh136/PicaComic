import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/network/download_model.dart';

import '../tools/io_tools.dart';
import 'download.dart';

class CustomDownloadedItem extends DownloadedItem {
  @override
  double? comicSize;

  @override
  final List<int> downloadedEps;

  final Map<String, String>? chapters;

  @override
  List<String> get eps => chapters?.values.toList() ?? ["EP 1"];

  final String comicId;

  @override
  final String id;

  @override
  final String name;

  @override
  final String subTitle;

  @override
  final List<String> tags;

  @override
  DownloadType get type => DownloadType.other;

  final String sourceKey;

  final String sourceName;

  final String cover;

  CustomDownloadedItem(
      this.comicSize,
      this.downloadedEps,
      this.chapters,
      this.id,
      this.name,
      this.subTitle,
      this.tags,
      this.sourceKey,
      this.sourceName,
      this.cover,
      this.comicId);

  @override
  Map<String, dynamic> toJson() => {
        "comicSize": comicSize,
        "downloadedEps": downloadedEps,
        "chapters": chapters,
        "id": id,
        "name": name,
        "subTitle": subTitle,
        "tags": tags,
        "sourceKey": sourceKey,
        "sourceName": sourceName,
        "cover": cover,
        "comicId": comicId
      };

  CustomDownloadedItem.fromJson(Map<String, dynamic> json)
      : comicSize = json["comicSize"],
        downloadedEps = List<int>.from(json["downloadedEps"]),
        chapters = Map<String, String>.from(json["chapters"]),
        id = json["id"],
        name = json["name"],
        subTitle = json["subTitle"],
        tags = List<String>.from(json["tags"]),
        sourceKey = json["sourceKey"],
        sourceName = json["sourceName"],
        cover = json["cover"],
        comicId = json["comicId"];
}

class CustomDownloadingItem extends DownloadingItem {
  CustomDownloadingItem(this.comic, this._downloadEps,
      super.whenFinish, super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.other})
      : source = ComicSource.find(comic.sourceKey)!;

  final ComicInfoData comic;

  final List<int> _downloadEps;

  late final ComicSource source;

  @override
  String get cover => comic.cover;

  @override
  bool get haveEps => comic.chapters != null;

  Stream<DownloadProgress> _getImage(String url){
    if(source.getImageLoadingConfig != null) {
      int ep = links!.keys.elementAt(downloadingEp);
      var config = source.getImageLoadingConfig!(url, comic.comicId,
          comic.chapters?.keys.elementAtOrNull(ep-1) ?? comic.comicId);
      return ImageManager().getImage(config["url"] ?? url,
          Map.from(config['headers'] ?? {}));
    }
    return ImageManager().getImage(url);
  }

  @override
  Future<(Uint8List, String)> getImage(String link) async{
    await for(var s in _getImage(link)){
      if(s.finished){
        var file = s.getFile();
        var data = await file.readAsBytes();
        await file.delete();
        return (data, s.ext ?? "jpg");
      }
    }
    throw Exception("Fail to download Image");
  }

  @override
  Map<String, String> get headers => {
    "User-Agent": webUA,
  };

  Future<void> getOneEp(int i, Map<int, List<String>> links) async{
    if(links[i+1] != null) return;

    int retry = 0;

    while (retry < 3) {
      try {
        links[i+1] = (await source.loadComicPages!(comic.comicId, comic.chapters!.keys.elementAt(i))).data;
        return;
      } catch (e) {
        await Future.delayed(const Duration(seconds: 3));
        retry++;
      }
    }

    throw Exception("Failed to get chapters");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async{
    var links = <int, List<String>>{};
    if(comic.chapters != null){
      var futures = <Future>[];
      for(var i in _downloadEps){
        futures.add(getOneEp(i, links));
        await Future.delayed(const Duration(milliseconds:200));
        if(futures.length % 5 == 0){
          await Future.wait(futures);
          futures.clear();
        }
      }
      await Future.wait(futures);
    } else {
      var res = await source.loadComicPages!(comic.comicId, null);
      links[0] = res.data;
    }
    return links;
  }

  @override
  void loadImageToCache(String link) {
    addStreamSubscription(_getImage(link).listen((event) {}));
  }

  @override
  Future<void> saveInfo() async {
    var file = File("$path/$id/info.json");
    var previous = <int>[];
    if (DownloadManager().downloaded.contains(id)) {
      var comic = await DownloadManager().getComicOrNull(id);
      previous = comic!.downloadedEps;
    }
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync();
    var downloaded = (_downloadEps + previous).toSet().toList();
    downloaded.sort();
    var tags = <String>[];
    comic.tags.forEach((key, value) => tags.addAll(value));
    var downloadedItem = CustomDownloadedItem(
        await getFolderSize(Directory("$path/$id")),
        downloaded,
        comic.chapters,
        id,
        comic.title,
        comic.subTitle ?? "",
        tags,
        comic.sourceKey,
        source.name,
        comic.cover,
        comic.comicId);
    var json = jsonEncode(downloadedItem.toJson());
    await file.writeAsString(json);
  }

  @override
  String get title => comic.title;

  @override
  Map<String, dynamic> toMap() => {
        "comic": comic.toJson(),
        "_downloadEps": _downloadEps,
        ...super.toBaseMap()
      };

  CustomDownloadingItem.fromMap(Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id):
      comic = ComicInfoData.fromJson(map["comic"]),
      _downloadEps = List<int>.from(map["_downloadEps"]),
      super.fromMap(map, whenFinish, whenError, updateInfo){
    source = ComicSource.find(comic.sourceKey)!;
  }
}
