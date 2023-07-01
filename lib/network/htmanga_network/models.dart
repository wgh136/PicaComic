import 'package:flutter/cupertino.dart';

@immutable
class HtHomePageData{
  final List<List<HtComicBrief>> comics;
  final Map<String, String> links;

  /// 主页
  const HtHomePageData(this.comics, this.links);
}

@immutable
class HtComicBrief{
  final String name;
  final String time;
  final String image;
  final int pages;
  final String link;

  /// 漫画简略信息
  const HtComicBrief(this.name, this.time, this.image, this.link, this.pages);
}