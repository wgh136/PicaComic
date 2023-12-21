import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../base.dart';
import '../../foundation/image_manager.dart';
import '../../tools/io_tools.dart';
import '../download_model.dart';

class NhentaiDownloadedComic extends DownloadedItem{
  NhentaiDownloadedComic(this.comicID, this.title, this.size, this.cover, this.tags);

  final String comicID;

  final String title;

  final double? size;

  final String cover;

  @override
  double? get comicSize => size;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["第一章".tl];

  @override
  String get id => comicID;

  @override
  String get name => title;

  @override
  String get subTitle => "";

  @override
  DownloadType get type => DownloadType.nhentai;

  @override
  Map<String, dynamic> toJson() => {
    'comicID': comicID,
    'title': title,
    'size': size,
    'cover': cover
  };

  NhentaiDownloadedComic.fromJson(Map<String, dynamic> json):
      comicID = json["comicID"],
      title = json["title"],
      size = json["size"],
      tags = List.from(json["tags"] ?? []),
      cover = json["cover"];

  @override
  set comicSize(double? value){}

  @override
  List<String> tags;
}

class NhentaiDownloadingItem extends DownloadingItem{
  NhentaiDownloadingItem(this.comic, super.path, super.whenFinish, super.whenError, super.updateInfo, super.id, {super.type = DownloadType.nhentai});

  final NhentaiComic comic;

  @override
  String get cover => comic.cover;

  @override
  Future<Uint8List> getImage(String link) async{
    await for(var s in ImageManager().getImage(link)){
      if(s.finished){
        return s.getFile().readAsBytesSync();
      }
    }
    throw Exception("Failed to download image");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async{
    var res = await NhentaiNetwork().getImages(comic.id);
    return {0: res.data};
  }

  @override
  void loadImageToCache(String link) {
    addStreamSubscription(ImageManager().getImage(link).listen((event) {}));
  }

  @override
  Future<void> saveInfo() async{
    var file = File("$path/$id/info.json");
    var item = NhentaiDownloadedComic(id, title, await getFolderSize(Directory("$path$pathSep$id")), comic.cover, comic.tags["tags"] ?? []);
    var json = jsonEncode(item.toJson());
    await file.writeAsString(json);
  }

  @override
  String get title => comic.title;

  @override
  Map<String, dynamic> toMap() => {
    "comic": comic.toMap(),
    ...super.toBaseMap()
  };

  NhentaiDownloadingItem.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id):
        comic = NhentaiComic.fromMap(map["comic"]),
        super.fromMap(map, whenFinish, whenError, updateInfo);

}