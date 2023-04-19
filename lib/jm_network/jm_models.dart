class HomePageData{
  List<HomePageItem> items;

  HomePageData(this.items);
}

class HomePageItem{
  String name;
  String id;
  List<JmComicBrief> comics;

  HomePageItem(this.name, this.id, this.comics);
}

class JmComicBrief{
  String id;
  String author;
  String name;
  String description;
  List<Category> categories;

  JmComicBrief(this.id, this.author, this.name, this.description, this.categories);
}

class Category{
  String id;
  String name;

  Category(this.id, this.name);
}

class PromoteList{
  String id;
  List<JmComicBrief> comics;
  int loaded=0;
  int total=1;
  int page = 0;

  PromoteList(this.id, this.comics);
}