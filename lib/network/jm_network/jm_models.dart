import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';

class HomePageData {
  List<HomePageItem> items;

  HomePageData(this.items);
}

class HomePageItem {
  String name;
  String id;
  bool category;
  List<JmComicBrief> comics;

  HomePageItem(this.name, this.id, this.comics, this.category);
}

class JmComicBrief extends BaseComic {
  @override
  String id;
  String author;
  String name;
  @override
  String description;
  List<ComicCategoryInfo> categories;
  @override
  List<String> tags;

  JmComicBrief(
    this.id,
    this.author,
    this.name,
    this.description,
    this.categories,
    this.tags,
  );

  @override
  String get cover => getJmCoverUrl(id);

  @override
  String get subTitle => author;

  @override
  String get title => name;
}

class ComicCategoryInfo {
  String id;
  String name;

  ComicCategoryInfo(this.id, this.name);
}

class PromoteList {
  String id;
  List<JmComicBrief> comics;
  int loaded = 0;
  int total = 1;
  int page = 0;

  PromoteList(this.id, this.comics);
}

class SearchRes {
  String keyword;
  int loaded;
  int total;
  int loadedPage = 1;
  List<JmComicBrief> comics;

  SearchRes(this.keyword, this.loaded, this.total, this.comics);
}

class Category {
  String name;
  String slug;
  List<SubCategory> subCategories;

  Category(this.name, this.slug, this.subCategories) {
    if (slug == "") {
      slug = "0";
    }
  }
}

class SubCategory {
  String cid;
  String name;
  String slug;

  SubCategory(this.cid, this.name, this.slug);
}

class JmComicInfo with HistoryMixin {
  String name;
  String id;
  List<String> author;
  String description;
  int likes;
  int views;
  int comments;

  ///章节信息, 键为章节序号, 值为漫画ID
  Map<int, String> series;
  List<String> tags;
  List<JmComicBrief> relatedComics;
  bool liked;
  bool favorite;
  List<String> epNames;

  JmComicInfo(
      this.name,
      this.id,
      this.author,
      this.description,
      this.likes,
      this.views,
      this.series,
      this.tags,
      this.relatedComics,
      this.liked,
      this.favorite,
      this.comments,
      this.epNames);

  static Map<String, String> seriesToJsonMap(Map<int, String> map) {
    var res = <String, String>{};
    for (var i in map.entries) {
      res[i.key.toString()] = i.value;
    }
    return res;
  }

  static Map<int, String> jsonMapToSeries(Map<String, dynamic> map) {
    var res = <int, String>{};
    for (var i in map.entries) {
      res[int.parse(i.key)] = i.value;
    }
    return res;
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "id": id,
      "author": author,
      "description": description,
      "likes": "",
      "views": "",
      "series": seriesToJsonMap(series),
      "tags": tags,
      "relatedComics": [],
      "liked": "",
      "favorite": "",
      "epNames": epNames
    };
  }

  JmComicInfo.fromMap(Map<String, dynamic> map)
      : name = map["name"],
        id = map["id"],
        author = List<String>.from(map["author"]),
        description = map["description"],
        likes = 0,
        views = 0,
        series = jsonMapToSeries(map["series"]),
        tags = List<String>.from(map["tags"]),
        relatedComics = [],
        liked = false,
        favorite = false,
        comments = 0,
        epNames = List.from(map["epNames"] ?? []);

  JmComicBrief toBrief() =>
      JmComicBrief(id, author.firstOrNull ?? "", name, description, [], tags);

  @override
  String get cover => getJmCoverUrl(id);

  @override
  HistoryType get historyType => HistoryType.jmComic;

  @override
  String get subTitle => author.firstOrNull ?? '';

  @override
  String get target => id;

  @override
  String get title => name;
}

class Comment {
  String id;
  String avatar;
  String name;
  String time;
  String content;
  List<Comment> reply;

  Comment(this.id, this.avatar, this.name, this.time, this.content, this.reply);
}
