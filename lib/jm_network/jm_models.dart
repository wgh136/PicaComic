class HomePageData{
  List<HomePageItem> items;

  HomePageData(this.items);
}

class HomePageItem{
  String name;
  String id;
  bool category;
  List<JmComicBrief> comics;

  HomePageItem(this.name, this.id, this.comics, this.category);
}

class JmComicBrief{
  String id;
  String author;
  String name;
  String description;
  List<ComicCategoryInfo> categories;

  JmComicBrief(this.id, this.author, this.name, this.description, this.categories);
}

class ComicCategoryInfo{
  String id;
  String name;

  ComicCategoryInfo(this.id, this.name);
}

class PromoteList{
  String id;
  List<JmComicBrief> comics;
  int loaded=0;
  int total=1;
  int page = 0;

  PromoteList(this.id, this.comics);
}

class SearchRes{
  String keyword;
  int loaded;
  int total;
  int loadedPage = 1;
  List<JmComicBrief> comics;

  SearchRes(this.keyword, this.loaded, this.total, this.comics);
}

class Category{
  String name;
  String slug;
  List<SubCategory> subCategories;

  Category(this.name, this.slug, this.subCategories){
    if(slug == ""){
      slug = "0";
    }
  }
}

class SubCategory{
  String cid;
  String name;
  String slug;

  SubCategory(this.cid, this.name, this.slug);
}

class CategoryComicsRes{
  String category;
  String sort;
  int loaded;
  int total;
  int loadedPage = 1;
  List<JmComicBrief> comics;

  CategoryComicsRes(
      this.category, this.sort, this.loaded, this.total, this.loadedPage, this.comics);
}

class JmComicInfo{
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

  JmComicInfo(this.name, this.id, this.author, this.description, this.likes, this.views,
      this.series, this.tags, this.relatedComics, this.liked, this.favorite, this.comments);
  
  static Map<String, String> seriesToJsonMap(Map<int, String> map){
    var res = <String, String>{};
    for(var i in map.entries){
      res[i.key.toString()] = i.value;
    }
    return res;
  }
  
  static Map<int, String> jsonMapToSeries(Map<String, dynamic> map){
    var res = <int, String>{};
    for(var i in map.entries){
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
    };
  }

  JmComicInfo.fromMap(Map<String, dynamic> map):
    name = map["name"],
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
    comments = 0;
}

class FavoriteFolder{
  String id;
  List<JmComicBrief> comics;
  int loadedPage = 1;
  int total;
  int loadedComics;

  FavoriteFolder(this.id, this.comics, this.loadedPage, this.total, this.loadedComics);
}

class Comment{
  String id;
  String avatar;
  String name;
  String time;
  String content;
  List<Comment> reply;

  Comment(this.id, this.avatar, this.name, this.time, this.content, this.reply);
}