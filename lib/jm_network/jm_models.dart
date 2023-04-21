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