import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import '../../base.dart';
import '../download.dart';
import 'methods.dart';
import 'models.dart';
import 'dart:io';

class DownloadedComic extends DownloadedItem{
  ComicItem comicItem;
  List<String> chapters;
  List<int> downloadedChapters;
  double? size;
  DownloadedComic(this.comicItem,this.chapters,this.size,this.downloadedChapters);

  @override
  Map<String,dynamic> toJson()=>{
    "comicItem": comicItem.toJson(),
    "chapters": chapters,
    "size": size,
    "downloadedChapters": downloadedChapters
  };

  DownloadedComic.fromJson(Map<String,dynamic> json):
        comicItem = ComicItem.fromJson(json["comicItem"]),
        chapters = List<String>.from(json["chapters"]),
        size = json["size"],
        downloadedChapters = []{
    if(json["downloadedChapters"] == null){
      //旧版本中的数据不包含这一项
      for(int i=0;i<chapters.length;i++) {
        downloadedChapters.add(i);
      }
    }else{
      downloadedChapters = List<int>.from(json["downloadedChapters"]);
    }
  }

  @override
  DownloadType get type => DownloadType.picacg;

  @override
  List<int> get downloadedEps => downloadedChapters;

  @override
  List<String> get eps => chapters.getNoBlankList();

  @override
  String get name => comicItem.title;

  @override
  String get id => comicItem.id;

  @override
  String get subTitle => comicItem.author;

  @override
  double? get comicSize => size;

  @override
  set comicSize(double? value) => size = value;

  @override
  List<String> get tags => comicItem.tags;
}

///picacg的下载进程模型
class PicDownloadingItem extends DownloadingItem {
  PicDownloadingItem(
      this.comic,
      super.path,
      this._downloadEps,
      super.whenFinish,
      super.whenError,
      super.updateInfo,
      super.id,
      {super.type = DownloadType.picacg}
  );

  ///漫画模型
  final ComicItem comic;

  ///章节名称
  var _eps = <String>[];

  ///要下载的章节序号
  final List<int> _downloadEps;

  ///获取各章节名称
  List<String> get eps => _eps;

  @override
  Future<void> saveInfo() async{
    var file = File("$path/$id/info.json");
    var previous = <int>[];
    if(DownloadManager().downloaded.contains(id)){
      var comic = await DownloadManager().getComicFromId(id);
      previous = comic.downloadedEps;
    }
    if(file.existsSync()){
      file.deleteSync();
    }
    file.createSync();
    var downloaded = (_downloadEps+previous).toSet().toList();
    downloaded.sort();
    var downloadedItem = DownloadedComic(comic, eps, await getFolderSize(Directory("$path$pathSep$id")),downloaded);
    var json = jsonEncode(downloadedItem.toJson());
    await file.writeAsString(json);
  }


  @override
  get cover => getImageUrl(comic.thumbUrl);

  @override
  String get title => comic.title;

  @override
  Future<Uint8List> getImage(String link) async{
    await for(var s in ImageManager().getImage(getImageUrl(link))){
      if(s.finished){
        var file = s.getFile();
        var data = await file.readAsBytes();
        await file.delete();
        return data;
      }
    }
    throw Exception("Fail to download Image");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async{
    var res = <int, List<String>>{};
    _eps = (await network.getEps(id)).data;
    for(var i in _downloadEps) {
      res[i+1] = (await network.getComicContent(id, i+1)).data;
    }
    return res;
  }

  @override
  void loadImageToCache(String link) {
    addStreamSubscription(ImageManager().getImage(getImageUrl(link)).listen((event) {}));
  }

  @override
  Map<String, dynamic> toMap() => {
    "comic": comic.toJson(),
    "_eps": _eps,
    "_downloadEps": _downloadEps,
    ...super.toBaseMap()
  };

  PicDownloadingItem.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id):
      comic = ComicItem.fromJson(map["comic"]),
      _eps = List<String>.from(map["_eps"]),
      _downloadEps = List<int>.from(map["_downloadEps"]),
      super.fromMap(map, whenFinish, whenError, updateInfo);
}
