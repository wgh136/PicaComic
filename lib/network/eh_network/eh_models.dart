import 'package:pica_comic/base.dart';

class EhGalleryBrief{
  String title;
  String type;
  String time;
  String uploader;
  double stars; //0-5
  String coverPath;
  String link;
  List<String> tags;

  EhGalleryBrief(this.title,this.type,this.time,this.uploader,this.coverPath,this.stars,this.link,this.tags, {bool ignoreExamination=false}){
    if(ignoreExamination) return;
    bool block = false;
    for(var key in appdata.blockingKeyword){
      block = block || title.contains(key) || uploader==key || type==key || tags.contains(key);
    }
    if(block){
      throw Error();
    }
  }
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
  late String title;
  late String type;
  late String time;
  late String uploader;
  late double stars;
  String? rating;
  late String coverPath;
  Map<String,List<String>> tags;
  List<String> urls;  //图片链接
  List<Comment> comments = [];
  Map<String,String>? auth;//api身份验证信息
  bool favorite;
  late String link;
  String maxPage;
  List<String> imgUrls;

  Gallery(EhGalleryBrief brief,this.tags,this.urls,this.favorite,this.maxPage,
      {this.imgUrls=const <String>[]}){
    title = brief.title;
    type = brief.type;
    time = brief.time;
    uploader = brief.uploader;
    stars = brief.stars;
    uploader = brief.uploader;
    coverPath = brief.coverPath;
    link = brief.link;
  }

  EhGalleryBrief toBrief() => EhGalleryBrief(
      title,
      type,
      time,
      uploader,
      coverPath,
      stars,
      link,
      []
  );

  Map<String, dynamic> toJson() {
    return {
      "title": title,
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
    };
  }

  Gallery.fromJson(Map<String, dynamic> json):
    title = json["title"],
    type = json["type"],
    time = json["time"],
    uploader = json["uploader"],
    stars = json["stars"],
    rating = json["rating"],
    coverPath = json["coverPath"],
    tags = {},
    favorite = json["favorite"],
    link = json["link"],
    maxPage = json["maxPage"],
    comments = [],
    imgUrls = [],
    urls = []{
    for(var key in (json["tags"] as Map<String, dynamic>).keys){
      tags["key"] = List<String>.from(json["tags"][key]);
    }
  }

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