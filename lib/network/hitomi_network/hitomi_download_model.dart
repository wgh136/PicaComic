import 'dart:convert';
import 'dart:typed_data';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import '../../base.dart';
import '../../tools/io_tools.dart';
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
  HitomiDownloadingItem(this.comic, super.path, this._coverPath, this.link, super.whenFinish,
      super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.hitomi});

  final String _coverPath;

  ///漫画模型
  final HitomiComic comic;

  ///画廊链接
  final String link;


  late final _headers = {
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36",
    "Referer": "https://hitomi.la/reader/${id.substring(6)}.html"
  };

  @override
  Map<String, String> get headers => _headers;

  @override
  String get cover => _coverPath;

  ///储存漫画信息
  @override
  Future<void> saveInfo() async {
    var file = File("$path/$id/info.json");
    var item = DownloadedHitomiComic(
        comic, await getFolderSize(Directory("$path$pathSep$id")), link, _coverPath);
    var json = jsonEncode(item.toMap());
    await file.writeAsString(json);
  }

  @override
  String get title => comic.name;

  @override
  Future<Uint8List> getImage(String link) async{
    await for(var s in MyCacheManager().getHitomiImage(HitomiFile.fromMap(
        const JsonDecoder().convert(link)), id.replaceFirst("hitomi", ""))){
      if(s.finished){
        return s.getFile().readAsBytesSync();
      }
    }
    throw Exception("Fail to download image");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async{
    return {0: List<String>.generate(comic.files.length,
            (index) => const JsonEncoder().convert(comic.files[index].toMap()))};
  }

  @override
  void loadImageToCache(String link) {
    addStreamSubscription(MyCacheManager().getHitomiImage(HitomiFile.fromMap(
        const JsonDecoder().convert(link)), id.replaceFirst("hitomi", ""))
        .listen((event) {}));
  }

  @override
  String? get imageExtension => ".webp";

  @override
  Map<String, dynamic> toMap() => {
    "comic": comic.toMap(),
    "_coverPath": _coverPath,
    "link": link,
    ...super.toBaseMap()
  };

  HitomiDownloadingItem.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id
      ):comic=HitomiComic.fromMap(map["comic"]),
        _coverPath = map["_coverPath"],
        link = map["link"],
        super.fromMap(map, whenFinish, whenError, updateInfo);
}

