part of comic_source;

class CategoryData {
  /// The title is displayed in the tab bar.
  final String title;

  /// 当使用中文语言时, 英文的分类标签将在构建页面时被翻译为中文
  final List<BaseCategoryPart> categories;

  final bool enableSuggestionPage;

  final bool enableRankingPage;

  final bool enableRandomPage;

  final String recommendPageName;

  final String key;

  /// Data class for building category page.
  const CategoryData(
      {required this.title,
      required this.categories,
      required this.enableSuggestionPage,
      required this.enableRankingPage,
      required this.enableRandomPage,
      required this.key,
      this.recommendPageName = "Recommendation"});
}

abstract class BaseCategoryPart {
  String get title;

  List<String> get categories;

  List<String>? get categoryParams => null;

  bool get enableRandom;

  String get categoryType;

  /// Data class for building a part of category page.
  const BaseCategoryPart();
}

class FixedCategoryPart extends BaseCategoryPart {
  @override
  final List<String> categories;

  @override
  bool get enableRandom => false;

  @override
  final String title;

  @override
  final String categoryType;

  @override
  final List<String>? categoryParams;

  /// A [BaseCategoryPart] that show fixed tags on category page.
  const FixedCategoryPart(this.title, this.categories, this.categoryType,
      [this.categoryParams]);
}

class RandomCategoryPart extends BaseCategoryPart {
  final List<String> tags;

  final int randomNumber;

  @override
  final String title;

  @override
  bool get enableRandom => true;

  @override
  final String categoryType;

  List<String> _categories() {
    if (randomNumber >= tags.length) {
      return tags;
    }
    return tags.sublist(Random().nextInt(tags.length - randomNumber));
  }

  @override
  List<String> get categories => _categories();

  /// A [BaseCategoryPart] that show random tags on category page.
  const RandomCategoryPart(
      this.title, this.tags, this.randomNumber, this.categoryType);
}

class RandomCategoryPartWithRuntimeData extends BaseCategoryPart {
  final List<String> Function() loadTags;

  final int randomNumber;

  @override
  final String title;

  @override
  bool get enableRandom => true;

  @override
  final String categoryType;

  List<String> _categories() {
    var tags = loadTags();
    if (randomNumber >= tags.length) {
      return tags;
    }
    final start = Random().nextInt(tags.length - randomNumber);
    return tags.sublist(start, start + randomNumber);
  }

  @override
  List<String> get categories => _categories();

  /// A [BaseCategoryPart] that show random tags on category page.
  RandomCategoryPartWithRuntimeData(
      this.title, this.loadTags, this.randomNumber, this.categoryType);
}

CategoryData getCategoryDataWithKey(String key) {
  switch (key) {
    case "picacg":
      return picacgCategory;
    case "ehentai":
      return ehCategory;
    case "jm":
      return jmCategory;
    case "htmanga":
      return htCategory;
    case "nhentai":
      return nhCategory;
    default:
      return loadCategoryFromConfig(key);
  }
}

CategoryData loadCategoryFromConfig(String key){
  // TODO
  throw UnimplementedError();
}