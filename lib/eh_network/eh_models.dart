class EhGalleryBrief{
  String title;
  String type;
  String time;
  String uploader;
  double stars; //0-5
  String coverPath;
  String link;
  List<String> tags;

  EhGalleryBrief(this.title,this.type,this.time,this.uploader,this.coverPath,this.stars,this.link,this.tags);
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
  late String coverPath;
  Map<String,List<String>> tags;
  List<String> urls;  //图片链接
  List<Comment> comments = [];
  Map<String,String>? auth;//api身份验证信息
  Gallery(EhGalleryBrief brief,this.tags,this.urls){
    title = brief.title;
    type = brief.type;
    time = brief.time;
    uploader = brief.uploader;
    stars = brief.stars;
    uploader = brief.uploader;
    coverPath = brief.coverPath;
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