import 'package:flutter/cupertino.dart';

@immutable
class NhentaiComicBrief{
  final String title;
  final String cover;
  final String id;

  const NhentaiComicBrief(this.title, this.cover, this.id);
}

class NhentaiHomePageData{
  final List<NhentaiComicBrief> popular;
  List<NhentaiComicBrief> latest;
  int page = 1;

  NhentaiHomePageData(this.popular, this.latest);
}

class NhentaiComic{
  String id;
  String title;
  String subTitle;
  String cover;
  Map<String, List<String>> tags;
  bool favorite;
  List<String> thumbnails;
  List<NhentaiComicBrief> recommendations;
  String token;

  NhentaiComic(this.id, this.title, this.subTitle, this.cover, this.tags, this.favorite,
      this.thumbnails, this.recommendations, this.token);
}

class NhentaiComment{
  String userName;
  String avatar;
  String content;
  int date;

  NhentaiComment(this.userName, this.avatar, this.content, this.date);
}