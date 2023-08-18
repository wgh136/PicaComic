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