import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'picacg_network/models.dart';

class DownloadedComic{
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
}

class DownloadedGallery{
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
}

class DownloadedJmComic{
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