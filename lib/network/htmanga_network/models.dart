import 'package:flutter/cupertino.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/network/base_comic.dart';

@immutable
class HtHomePageData {
  final List<List<HtComicBrief>> comics;
  final Map<String, String> links;

  /// 主页
  const HtHomePageData(this.comics, this.links);
}

@immutable
class HtComicBrief extends BaseComic{
  final String name;
  final String time;
  final String image;
  final int pages;
  @override
  final String id;
  final String? favoriteId;

  /// 漫画简略信息
  const HtComicBrief(this.name, this.time, this.image, this.id, this.pages,
      {this.favoriteId});

  @override
  String get cover => image;

  @override
  String get description => time;

  @override
  String get subTitle => id;

  @override
  List<String> get tags => const [];

  @override
  String get title => name;
}

@immutable
class HtComicInfo with HistoryMixin {
  final String id;
  final String coverPath;
  final String name;
  final String category;
  final int pages;
  final Map<String, String> tags;
  final String description;
  final String uploader;
  final String avatar;
  final int uploadNum;
  final List<String> thumbnails;

  const HtComicInfo(this.id, this.coverPath, this.name, this.category, this.pages, this.tags,
      this.description, this.uploader, this.avatar, this.uploadNum, this.thumbnails);

  HtComicBrief toBrief() => HtComicBrief(name, "", coverPath, id, pages);

  Map<String, dynamic> toJson() => {
    "id": id,
    "coverPath": coverPath,
    "name": name,
    "category": category,
    "pages": pages,
    "tags": tags,
    "description": description,
    "uploader": uploader,
    "avatar": avatar,
    "uploadNum": uploadNum
  };

  HtComicInfo.fromJson(Map<String, dynamic> json):
      id = json["id"],
      coverPath = json["coverPath"],
      name = json["name"],
      category = json["category"],
      pages = json["pages"],
      tags = Map<String, String>.from(json["tags"]),
      description = json["description"],
      uploader = json["uploader"],
      avatar = json["avatar"],
      uploadNum = json["uploadNum"],
      thumbnails = [];

  @override
  String get cover => coverPath;

  @override
  HistoryType get historyType => HistoryType.htmanga;

  @override
  String get subTitle => uploader;

  @override
  String get target => id;

  @override
  String get title => name;
}
