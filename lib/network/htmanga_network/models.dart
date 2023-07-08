import 'package:flutter/cupertino.dart';

import '../../base.dart';

@immutable
class HtHomePageData {
  final List<List<HtComicBrief>> comics;
  final Map<String, String> links;

  /// 主页
  const HtHomePageData(this.comics, this.links);
}

@immutable
class HtComicBrief {
  final String name;
  final String time;
  final String image;
  final int pages;
  final String id;
  final String? favoriteId;

  /// 漫画简略信息
  HtComicBrief(this.name, this.time, this.image, this.id, this.pages,
      {bool ignoreExamination = false, this.favoriteId}) {
    if (ignoreExamination) return;
    for (var key in appdata.blockingKeyword) {
      if (name.contains(key)) {
        throw Exception();
      }
    }
  }
}

@immutable
class HtComicInfo {
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

  const HtComicInfo(this.id, this.coverPath, this.name, this.category, this.pages, this.tags,
      this.description, this.uploader, this.avatar, this.uploadNum);
}
