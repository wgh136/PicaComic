import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/download_model.dart';
import '../../base.dart';
import '../../foundation/image_manager.dart';
import '../../tools/io_tools.dart';

class DownloadedHtComic extends DownloadedItem {
  DownloadedHtComic(this.comic, this.size);

  HtComicInfo comic;

  double? size;

  @override
  double? get comicSize => size;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["EP 1"];

  @override
  String get id => "Ht${comic.id}";

  @override
  String get name => comic.name;

  @override
  String get subTitle => comic.uploader;

  @override
  DownloadType get type => DownloadType.htmanga;

  @override
  Map<String, dynamic> toJson() => {"comic": comic.toJson(), "size": size};

  DownloadedHtComic.fromJson(Map<String, dynamic> json)
      : comic = HtComicInfo.fromJson(json["comic"]),
        size = json["size"];

  @override
  set comicSize(double? value) => size = value;

  @override
  List<String> get tags => comic.tags.keys.toList();
}

class DownloadingHtComic extends DownloadingItem {
  DownloadingHtComic(
      this.comic, super.whenFinish, super.whenError, super.updateInfo, super.id,
      {super.type = DownloadType.htmanga});

  final HtComicInfo comic;

  String _getCover() {
    var uri = comic.coverPath;
    if (uri.contains("https:") && !uri.contains("https://")) {
      uri = uri.replaceFirst("https:", "https://");
    }
    return uri;
  }

  @override
  String get cover => _getCover();

  @override
  String get title => comic.name;

  @override
  Future<Map<int, List<String>>> getLinks() async {
    var res = await HtmangaNetwork().getImages(comic.id);
    return {0: res.data};
  }

  @override
  Stream<DownloadProgress> downloadImage(String link) {
    return ImageManager().getImage(link);
  }

  @override
  Map<String, dynamic> toMap() =>
      {"comic": comic.toJson(), ...super.toBaseMap()};

  DownloadingHtComic.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id)
      : comic = HtComicInfo.fromJson(map["comic"]),
        super.fromMap(map, whenFinish, whenError, updateInfo);

  @override
  FutureOr<DownloadedItem> toDownloadedItem() async {
    return DownloadedHtComic(
      comic,
      await getFolderSize(Directory(path)),
    );
  }
}
