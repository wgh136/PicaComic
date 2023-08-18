import 'dart:convert';
import 'dart:typed_data';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'dart:io';
import '../../tools/io_tools.dart';
import 'eh_main_network.dart';
import 'get_gallery_id.dart';

class DownloadedGallery extends DownloadedItem{
  Gallery gallery;
  double? size;
  DownloadedGallery(this.gallery,this.size);
  Map<String, dynamic> toJson()=>{
    "gallery": gallery.toJson(),
    "size": size
  };
  DownloadedGallery.fromJson(Map<String, dynamic> map):
        gallery = Gallery.fromJson(map["gallery"]),
        size = map["size"];

  @override
  DownloadType get type => DownloadType.ehentai;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["第一章"];

  @override
  String get name => gallery.title;

  @override
  String get id => getGalleryId(gallery.link);

  @override
  String get subTitle => gallery.uploader;

  @override
  double? get comicSize => size;
}

///e-hentai的下载进程模型
class EhDownloadingItem extends DownloadingItem{
  EhDownloadingItem(
      this.gallery,
      super.path,
      super.whenFinish,
      super.whenError,
      super.updateInfo,
      super.id,
      {super.type = DownloadType.ehentai}
  );

  ///画廊模型
  final Gallery gallery;

  @override
  Map<String, String> get headers => {
    "Cookie": EhNetwork().cookiesStr,
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
    "Referer": EhNetwork().ehBaseUrl,
  };

  @override
  String get cover => gallery.coverPath;

  ///储存画廊信息
  @override
  Future<void> saveInfo() async{
    var file = File("$path/$id/info.json");
    var item = DownloadedGallery(gallery, await getFolderSize(Directory("$path$pathSep$id")));
    var json = jsonEncode(item.toJson());
    await file.writeAsString(json);
  }

  @override
  String get title => gallery.title;

  @override
  Future<Uint8List> getImage(String link) async{
    await for(var s in MyCacheManager().getEhImage(link)){
      if(s.finished){
        return s.getFile().readAsBytesSync();
      }
    }
    throw Exception("Failed to download Image");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async{
    await for(var s in EhNetwork().loadGalleryPages(gallery)){
      if(s == 0){
        throw Exception("Failed to get image urls");
      }
    }
    return {
      0: gallery.urls
    };
  }

  @override
  void loadImageToCache(String link) {
    addStreamSubscription(MyCacheManager().getEhImage(link).listen((event) {}));
  }

  @override
  Map<String, dynamic> toMap() => {
    "gallery": gallery.toJson(),
    ...super.toBaseMap()
  };

  EhDownloadingItem.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id
      ):gallery=Gallery.fromJson(map["gallery"]),
        super.fromMap(map, whenFinish, whenError, updateInfo);
}

