import 'package:pica_comic/network/models.dart';

class DownloadItem{
  ComicItem comicItem;
  List<String> chapters;
  double? size;
  DownloadItem(this.comicItem,this.chapters,this.size);
  Map<String,dynamic> toJson()=>{
    "comicItem": comicItem.toJson(),
    "chapters": chapters,
    "size": size
  };
  DownloadItem.fromJson(Map<String,dynamic> json):
    comicItem = ComicItem.fromJson(json["comicItem"]),
    chapters = json["chapters"].cast<String>(),
    size = json["size"];
}

class DownloadQueue{
  List<ComicItem> comics;
  int downloadingEps;
  int index;
  List<String> urls;
  List<String> eps;
  int downloadPages;
  DownloadQueue(this.comics,this.downloadPages,this.index,this.downloadingEps,this.eps,this.urls);
  DownloadQueue.fromJson(Map<String,dynamic> json):
      comics = [],
      downloadingEps = json["downloadingEps"],
      index = json["index"],
      urls = json["urls"].cast<String>(),
      eps = json["eps"].cast<String>(),
      downloadPages = json["downloadPages"]{
    for(var comic in json["comics"]){
      comics.add(ComicItem.fromJson(comic));
    }
  }
  Map<String,dynamic> toJson(){
    var temp = {"comics":[]};
    for(var comic in comics){
      temp["comics"]!.add(comic.toJson());
    }
    return {
      "comics": temp["comics"],
      "downloadingEps": downloadingEps,
      "index": index,
      "urls": urls,
      "eps": eps,
      "downloadPages": downloadPages,
    };
  }
}