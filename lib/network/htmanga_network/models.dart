import 'package:flutter/cupertino.dart';

import '../../base.dart';

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
  HtComicBrief(this.name, this.time, this.image, this.link, this.pages, {bool ignoreExamination=false}){
    if(ignoreExamination) return;
    for(var key in appdata.blockingKeyword){
      if(name.contains(key)){
        throw Exception();
      }
    }
  }
}