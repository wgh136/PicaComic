import "package:pica_comic/base.dart";
import "package:pica_comic/foundation/history.dart";
import "package:pica_comic/network/base_comic.dart";

class Profile {
  String id;
  String title;
  String email;
  String name;
  int level;
  int exp;
  String avatarUrl;
  String? frameUrl;
  bool? isPunched;
  String? slogan;

  Profile(this.id, this.avatarUrl, this.email, this.exp, this.level, this.name, this.title, this.isPunched, this.slogan, this.frameUrl);

  Map<String,dynamic> toJson()=>{
    "id": id,
    "title": title,
    "email": email,
    "name": name,
    "level": level,
    "exp": exp,
    "avatarUrl": avatarUrl,
    "frameUrl": frameUrl,
    "isPunched": isPunched,
    "slogan": slogan
  };

  Profile.fromJson(Map<String,dynamic> json):
    id = json["id"],
    title = json["title"],
    email = json["email"],
    name = json["name"],
    level = json["level"],
    exp = json["exp"],
    avatarUrl = json["avatarUrl"],
    frameUrl = json["frameUrl"],
    isPunched = json["isPunched"],
    slogan = json["slogan"];
}

class CategoryItem {
  String title;
  String path;
  CategoryItem(this.title, this.path);
}

class InitData {
  String imageServer;
  String fileServer;
  var categories = <CategoryItem>[];
  InitData(this.imageServer, this.fileServer);
}

class ComicItemBrief extends BaseComic{
  @override
  String title;
  String author;
  int likes;
  String path;
  @override
  String id;
  @override
  List<String> tags;
  int? pages;

  ComicItemBrief(this.title, this.author, this.likes, this.path, this.id, this.tags, {this.pages});

  @override
  String get cover => path;

  @override
  String get description => "$likes pages";

  @override
  String get subTitle => author;
}

class ComicItem with HistoryMixin{
  String id;
  Profile creator;
  @override
  String title;
  String description;
  String thumbUrl;
  String author;
  String chineseTeam;
  List<String> categories;
  List<String> tags;
  int likes;
  int comments;
  bool isLiked;
  bool isFavourite;
  int epsCount;
  int pagesCount;
  String time;
  List<String> eps;
  List<ComicItemBrief> recommendation;
  ComicItem(
      this.creator,
      this.title,
      this.description,
      this.thumbUrl,
      this.author,
      this.chineseTeam,
      this.categories,
      this.tags,
      this.likes,
      this.comments,
      this.isFavourite,
      this.isLiked,
      this.epsCount,
      this.id,
      this.pagesCount,
      this.time,
      this.eps,
      this.recommendation
      );
  ComicItemBrief toBrief(){
    return ComicItemBrief(title, author, likes, thumbUrl, id, []);
  }

  Map<String,dynamic> toJson()=>{
    "creator": creator.toJson(),
    "id": id,
    "title": title,
    "description": description,
    "thumbUrl": thumbUrl,
    "author": author,
    "chineseTeam": chineseTeam,
    "categories": categories,
    "tags": tags,
    "likes": likes,
    "comments": comments,
    "isLiked": isLiked,
    "isFavourite": isFavourite,
    "epsCount": epsCount,
    "time": time,
    "pagesCount": pagesCount
  };

  ComicItem.fromJson(Map<String,dynamic> json):
    creator = Profile.fromJson(json["creator"]),
    id = json["id"],
    title = json["title"],
    description = json["description"],
    thumbUrl = json["thumbUrl"],
    author = json["author"],
    chineseTeam = json["chineseTeam"],
    categories = json["categories"].cast<String>(),
    tags = json["tags"].cast<String>(),
    likes = json["likes"],
    comments = json["comments"],
    isLiked = json["isLiked"],
    isFavourite = json["isFavourite"],
    epsCount = json["epsCount"],
    time = json["time"],
    pagesCount = json["pagesCount"],
    eps = [],
    recommendation = [];

  @override
  String get cover => thumbUrl;

  @override
  HistoryType get historyType => HistoryType.picacg;

  @override
  String get subTitle => author;

  @override
  String get target => id;
}

class Comment {
  String name;
  String avatarUrl;
  String userId;
  int level;
  String text;
  int reply;
  String id;
  bool isLiked;
  int likes;
  String? frame;
  String? slogan;
  String time;

  @override
  String toString()=>"$name:$text";

  Comment(
      this.name,
      this.avatarUrl,
      this.userId,
      this.level,
      this.text,
      this.reply,
      this.id,
      this.isLiked,
      this.likes,
      this.frame,
      this.slogan,
      this.time
      );
}

class Comments {
  List<Comment> comments;
  String id;
  int pages;
  int loaded;

  Comments(this.comments, this.id, this.pages, this.loaded);
}

class Favorites {
  List<ComicItemBrief> comics;
  int pages;
  int loaded;

  Favorites(this.comics, this.pages, this.loaded);
}

class SearchResult{
  String keyWord;
  String sort;
  int pages;
  int loaded;
  List<ComicItemBrief> comics;
  SearchResult(this.keyWord,this.sort,this.comics,this.pages,this.loaded);
}

class Reply{
  String id;
  int loaded;
  int total;
  List<Comment> comments;
  Reply(this.id,this.loaded,this.total,this.comments);
}

class GameItemBrief{
  String id;
  String iconUrl;
  String name;
  String publisher;
  bool adult;
  GameItemBrief(this.id,this.name,this.adult,this.iconUrl,this.publisher);
}

class Games{
  List<GameItemBrief> games;
  int total;
  int loaded;
  Games(this.games,this.loaded,this.total);
}

class GameInfo{
  String id;
  String name;
  String description;
  String icon;
  String publisher;
  List<String> screenshots;
  String link;
  bool isLiked;
  int likes;
  int comments;
  GameInfo(this.id,this.name,this.description,this.icon,this.publisher,this.screenshots,this.link,this.isLiked,this.likes,this.comments);
}