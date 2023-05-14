import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'picacg_network/models.dart';

abstract class DownloadedItem{
  ///漫画源
  DownloadType get type;
  ///漫画名
  String get name;
  ///章节
  List<String> get eps;
  ///已下载的章节
  List<int> get downloadedEps;
  ///标识符, 禁漫必须在前加jm
  String get id;
  ///副标题, 通常为作者
  String get subTitle;
  ///大小
  double? get comicSize;
}

class DownloadedComic extends DownloadedItem{
  ComicItem comicItem;
  List<String> chapters;
  List<int> downloadedChapters;
  double? size;
  DownloadedComic(this.comicItem,this.chapters,this.size,this.downloadedChapters);
  Map<String,dynamic> toJson()=>{
    "comicItem": comicItem.toJson(),
    "chapters": chapters,
    "size": size,
    "downloadedChapters": downloadedChapters
  };
  DownloadedComic.fromJson(Map<String,dynamic> json):
        comicItem = ComicItem.fromJson(json["comicItem"]),
        chapters = json["chapters"].cast<String>(),
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
  List<String> get eps => chapters.sublist(1);

  @override
  String get name => comicItem.title;

  @override
  String get id => comicItem.id;

  @override
  String get subTitle => comicItem.author;

  @override
  double? get comicSize => size;
}

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

class DownloadedJmComic extends DownloadedItem{
  JmComicInfo comic;
  double? size;
  List<int> downloadedChapters;
  DownloadedJmComic(this.comic, this.size, this.downloadedChapters);
  Map<String, dynamic> toMap()=>{
    "comic": comic.toJson(),
    "size": size,
    "downloadedChapters": downloadedChapters
  };
  DownloadedJmComic.fromMap(Map<String, dynamic> map):
      comic = JmComicInfo.fromMap(map["comic"]),
      size = map["size"],
      downloadedChapters = []{
    if(map["downloadedChapters"] == null){
      //旧版本中的数据不包含这一项
      for(int i=0;i<comic.series.length;i++) {
        downloadedChapters.add(i);
      }
      if(downloadedChapters.isEmpty){
        downloadedChapters.add(0);
      }
    }else{
      downloadedChapters = List<int>.from(map["downloadedChapters"]);
    }
  }

  @override
  DownloadType get type => DownloadType.jm;

  @override
  List<int> get downloadedEps => downloadedChapters;

  @override
  List<String> get eps => List<String>.generate(comic.series.isEmpty?1:comic.series.length, (index) => "第${index+1}章");

  @override
  String get name => comic.name;

  @override
  String get id => "jm${comic.id}";

  @override
  String get subTitle => comic.author[0];

  @override
  double? get comicSize => size;
}

enum DownloadType{picacg, ehentai, jm}

abstract class DownloadingItem{
  ///完成时调用
  final void Function()? whenFinish;
  ///更新ui, 用于下载管理器页面
  void Function()? updateUi;
  ///出现错误时调用
  final void Function()? whenError;
  ///更新下载信息
  final Future<void> Function()? updateInfo;
  ///标识符
  final String id;
  DownloadType type;

  DownloadingItem(this.whenFinish,this.whenError,this.updateInfo,this.id, {required this.type});


  ///开始或者继续暂停的下载
  void start();

  ///暂停下载
  void pause();

  ///停止下载
  void stop();

  Map<String, dynamic> toMap();

  ///获取封面链接
  String get cover;

  ///总共的图片数量
  int get totalPages;

  ///已下载的图片数量
  int get downloadedPages;

  ///标题
  String get title;

}