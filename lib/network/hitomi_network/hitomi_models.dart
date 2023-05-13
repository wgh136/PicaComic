class Tag {
  String name;
  String link;

  Tag(this.name, this.link);
}

class HitomiComicBrief {
  String name;
  String type;
  String lang;
  List<Tag> tags;
  String time;
  String artist;
  String link;
  String cover;

  HitomiComicBrief(
      this.name, this.type, this.lang, this.tags, this.time, this.artist, this.link, this.cover);
}

class ComicList {
  ///数据源
  String url;

  ///要获取的开始位置
  int toLoad = 0;

  ///总共的byte数量
  int total = 100;

  var comics = <HitomiComicBrief>[];

  ComicList(this.url);
}

class HitomiFile {
  String name;
  String hash;
  bool hasWebp;
  bool hasAvif;
  int height;
  int width;
  String galleryId;

  HitomiFile(this.name, this.hash, this.hasWebp, this.hasAvif, this.height, this.width, this.galleryId);
}

class HitomiComic {
  String id;
  String name;
  List<int> related;
  String type;
  List<String>? artists;
  String lang;
  List<Tag> tags;
  String time;
  List<HitomiFile> files;

  HitomiComic(this.id, this.name, this.related, this.type, this.artists, this.lang, this.tags,
      this.time, this.files);
}
