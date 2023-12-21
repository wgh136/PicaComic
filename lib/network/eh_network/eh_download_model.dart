import 'dart:convert';
import 'dart:typed_data';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'dart:io';
import '../../tools/io_tools.dart';
import '../cache_network.dart';
import 'eh_main_network.dart';
import 'get_gallery_id.dart';

class DownloadedGallery extends DownloadedItem{
  Gallery gallery;
  double? size;
  DownloadedGallery(this.gallery,this.size);

  @override
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
  List<String> get eps => ["EP 1"];

  @override
  String get name => gallery.title;

  @override
  String get id => getGalleryId(gallery.link);

  @override
  String get subTitle => gallery.uploader;

  @override
  double? get comicSize => size;

  @override
  set comicSize(double? value) {}

  List<String> _getTags(){
    var res = <String>[];
    gallery.tags.forEach((key, value) => value.forEach((element) => res.add(element)));
    return res;
  }

  @override
  List<String> get tags => _getTags();
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
    "User-Agent": webUA,
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
    await for(var s in ImageManager().getEhImageNew(gallery, int.parse(link))){
      if(s.finished){
        return s.getFile().readAsBytesSync();
      }
    }
    throw Exception("Failed to download Image");
  }

  @override
  Future<Map<int, List<String>>> getLinks() async{
    return {
      0: List.generate((int.parse(gallery.maxPage)), (index) => (index+1).toString())
    };
  }

  @override
  void loadImageToCache(String link) {
    addStreamSubscription(ImageManager().getEhImageNew(gallery, int.parse(link)).listen((event) {}));
  }

  @override
  Map<String, dynamic> toMap() => {
    "gallery": gallery.toJson(),
    ...super.toBaseMap()
  };

  @override
  void onStart() async{
    // clear showKey and imageKey
    // imageKey is saved through the network cache mechanism
    print("*****pass*****");
    gallery.auth?.remove("showKey");
    await CachedNetwork.clearCache();
  }

  EhDownloadingItem.fromMap(
      Map<String, dynamic> map,
      DownloadProgressCallback whenFinish,
      DownloadProgressCallback whenError,
      DownloadProgressCallbackAsync updateInfo,
      String id
      ):gallery=Gallery.fromJson(map["gallery"]),
        super.fromMap(map, whenFinish, whenError, updateInfo);
}

