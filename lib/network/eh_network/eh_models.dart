import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/base_comic.dart';

class EhGalleryBrief extends BaseComic{
  @override
  String title;
  String type;
  String time;
  String uploader;
  double stars; //0-5
  String coverPath;
  String link;
  @override
  List<String> tags;
  int? pages;

  EhGalleryBrief(this.title,this.type,this.time,this.uploader,this.coverPath,this.stars,this.link,this.tags, {bool ignoreExamination=false, this.pages}){
    if(ignoreExamination) return;
    bool block = false;
    for(var key in appdata.blockingKeyword){
      block = block || title.contains(key) || uploader==key || type==key;
    }
    for(var key in appdata.blockingKeyword){
      for(var tag in tags){
        block = block || tag.split(":").contains(key);
      }
    }
    if(block){
      throw Error();
    }
  }

  @override
  String get cover => coverPath;

  @override
  String get description => time;

  @override
  String get id => link;

  @override
  String get subTitle => uploader;
}

class Galleries{
  List<EhGalleryBrief> galleries = [];
  String? next;//下一页的链接
  EhGalleryBrief operator[](int index)=>galleries[index];
  int get length => galleries.length;
}

class Comment{
  String name;
  String content;
  String time;

  Comment(this.name, this.content, this.time);
}

class Gallery{
  String title;
  String? subTitle;
  String type;
  String time;
  String uploader;
  double stars;
  String? rating;
  String coverPath;
  Map<String,List<String>> tags;
  List<Comment> comments = [];
  /// api身份验证信息
  Map<String,String>? auth;
  bool favorite;
  String link;
  String maxPage;
  List<String> thumbnails;

  List<String> _generateTags(){
    var res = <String>[];
    tags.forEach((key, value) {
      for(var element in value) {
        res.add("$key:$element");
      }
    });
    return res;
  }

  EhGalleryBrief toBrief() => EhGalleryBrief(
      title,
      type,
      time,
      uploader,
      coverPath,
      stars,
      link,
      _generateTags()
  );

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "subTitle": subTitle,
      "type": type,
      "time": time,
      "uploader": uploader,
      "stars": stars,
      "rating": rating,
      "coverPath": coverPath,
      "tags": tags,
      "favorite": favorite,
      "link": link,
      "maxPage": maxPage,
      "auth": auth
    };
  }

  Gallery.fromJson(Map<String, dynamic> json):
    title = json["title"],
    type = json["type"],
    time = json["time"],
    uploader = json["uploader"],
    subTitle = json["subTitle"],
    stars = json["stars"],
    rating = json["rating"],
    coverPath = json["coverPath"],
    tags = {},
    favorite = json["favorite"],
    link = json["link"],
    maxPage = json["maxPage"],
    thumbnails = [],
    auth = json["auth"] == null ? null : Map<String,String>.from(json["auth"]),
    comments = []{
    for(var key in (json["tags"] as Map<String, dynamic>).keys){
      tags["key"] = List<String>.from(json["tags"][key]);
    }
  }

  Gallery(
      this.title,
      this.type,
      this.time,
      this.uploader,
      this.stars,
      this.rating,
      this.coverPath,
      this.tags,
      this.comments,
      this.auth,
      this.favorite,
      this.link,
      this.maxPage,
      this.thumbnails, // unused field
      this.subTitle);
}

enum EhLeaderboardType{
  yesterday(15),
  month(13),
  year(12),
  all(11);

  final int value;

  const EhLeaderboardType(this.value);
}

class EhLeaderboard{
  EhLeaderboardType type;
  List<EhGalleryBrief> galleries;
  int loaded;
  static const int max = 199;

  EhLeaderboard(this.type,this.galleries,this.loaded);
}

class EhImageLimit{
  final int current;
  final int max;
  final int resetCost;
  final int kGP;
  final int credits;

  const EhImageLimit(this.current, this.max, this.resetCost, this.kGP, this.credits);
}

class ArchiveDownloadInfo{
  final String originSize;
  final String resampleSize;
  final String originCost;
  final String resampleCost;
  final String? cancelUnlockUrl;

  const ArchiveDownloadInfo(this.originSize,
      this.resampleSize, this.originCost, this.resampleCost,
      this.cancelUnlockUrl);
}
