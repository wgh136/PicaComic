import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/network/base_comic.dart';

class Tag {
  String name;
  String link;

  Tag(this.name, this.link);
}

class HitomiComicBrief extends BaseComic {
  String name;
  String type;
  String lang;
  List<Tag> tagList;
  String time;
  String artist;
  String link;
  @override
  String cover;

  HitomiComicBrief(
    this.name,
    this.type,
    this.lang,
    this.tagList,
    this.time,
    this.artist,
    this.link,
    this.cover,
  );

  @override
  String get description => lang;

  @override
  String get id => link;

  @override
  String get subTitle => artist;

  @override
  List<String> get tags => tagList.map((e) => e.name).toList();

  @override
  String get title => name;
}

class ComicList {
  ///数据源
  String url;

  ///要获取的开始位置
  int toLoad = 0;

  ///总共的byte数量
  int total = 100;

  List<int> comicIds = [];

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

  HitomiFile(this.name, this.hash, this.hasWebp, this.hasAvif, this.height,
      this.width, this.galleryId);

  Map<String, dynamic> toMap() => {
        "name": name,
        "hash": hash,
        "hasWebp": hasWebp,
        "hasAvif": hasAvif,
        "height": height,
        "width": width,
        "galleryId": galleryId
      };

  HitomiFile.fromMap(Map<String, dynamic> map)
      : name = map["name"],
        hash = map["hash"],
        hasWebp = map["hasWebp"],
        hasAvif = map["hasAvif"],
        height = map["height"],
        width = map["width"],
        galleryId = map["galleryId"];
}

class HitomiComic with HistoryMixin {
  String id;
  String name;
  List<int> related;
  String type;
  List<String>? artists;
  String lang;
  List<Tag> tags;
  String time;
  List<HitomiFile> files;
  List<String> group;

  HitomiComic(
    this.id,
    this.name,
    this.related,
    this.type,
    this.artists,
    this.lang,
    this.tags,
    this.time,
    this.files,
    this.group,
    this.cover,
  ) {
    if (group.isEmpty) {
      group.add("N/A");
    }
    if (artists == null || artists!.isEmpty) {
      artists = ["N/A"];
    }
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "type": type,
        "artists": artists,
        "lang": lang,
        "time": time,
        "files": List<Map<String, dynamic>>.generate(
            files.length, (index) => files[index].toMap())
      };

  HitomiComic.fromMap(Map<String, dynamic> map)
      : id = map["id"],
        name = map["name"],
        type = map["type"],
        artists = List<String>.from(map["artists"]),
        lang = map["lang"],
        time = map["time"],
        tags = [],
        related = [],
        group = [],
        cover = '',
        files = List.generate(map["files"].length,
            (index) => HitomiFile.fromMap(map["files"][index]));

  HitomiComicBrief toBrief(String link, String cover) => HitomiComicBrief(
      name,
      type,
      lang,
      tags,
      time,
      (artists ?? ["未知"]).isEmpty ? "未知" : (artists ?? ["未知"])[0],
      link,
      cover);

  @override
  final String cover;

  @override
  HistoryType get historyType => HistoryType.hitomi;

  @override
  String get subTitle => artists?.firstOrNull ?? '';

  @override
  String get target => id;

  @override
  String get title => name;
}
