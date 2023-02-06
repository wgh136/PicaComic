import 'package:flutter/foundation.dart';

class Profile {
  String id;
  String title;
  String email;
  String name;
  int level;
  int exp;
  String avatarUrl;
  Profile(this.id, this.avatarUrl, this.email, this.exp, this.level, this.name, this.title);
}

class KeyWords {
  var keyWords = <String>[];
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

class ComicItemBrief {
  String title;
  String author;
  int likes;
  String path;
  String id;
  ComicItemBrief(this.title, this.author, this.likes, this.path, this.id){
    if(title.length>50) {
      title = "${title.substring(0,48)}...";
    }
    if(author.length>50) {
      author = "${author.substring(0,48)}...";
    }
  }
}

class ComicItem {
  String id;
  Profile creator;
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
      this.id
      );
  ComicItemBrief toBrief(){
    return ComicItemBrief(title, author, likes, thumbUrl, id);
  }
}

class Commend {
  String name;
  String avatarUrl;
  String id;
  int level;
  String text;

  Commend(this.name, this.avatarUrl, this.id, this.level, this.text);
}

class Commends {
  List<Commend> commends;
  String id;
  int pages;
  int loaded;

  Commends(this.commends, this.id, this.pages, this.loaded);
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
