library comic_source;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:toml/toml.dart';

import '../foundation/js_engine.dart';
import '../network/base_comic.dart';
import '../network/res.dart';
import 'app_build_in_category.dart';
import 'app_build_in_favorites.dart';

part 'category.dart';
part 'favorites.dart';
part 'parser.dart';

/// build comic list, [Res.subData] should be maxPage or null if there is no limit.
typedef ComicListBuilder = Future<Res<List<BaseComic>>> Function(int page);

typedef LoginFunction = Future<Res<bool>> Function(String, String);

typedef LoadComicFunc = Future<Res<ComicInfoData>> Function(String id);

class ComicSource {
  static List<ComicSource> sources = [];

  static ComicSource? find(String key) =>
      sources.firstWhereOrNull((element) => element.key == key);

  static Future<void> init() async {
    final path = "${App.dataPath}/comic_source";
    await for (var entity in Directory(path).list()) {
      if (entity is File && entity.path.endsWith(".toml")) {
        var source =
            await ComicSourceParser().parse(await entity.readAsString());
        await source.loadData();
        sources.add(source);
      }
    }
  }

  /// Name of this source.
  final String name;

  /// Identifier of this source.
  final String key;

  /// Account config.
  final AccountConfig? account;

  /// Category data used to build a static category tags page.
  final CategoryData? categoryData;

  /// Category comics data used to build a comics page with a category tag.
  final CategoryComicsData? categoryComicsData;

  /// Favorite data used to build favorite page.
  final FavoriteData? favoriteData;

  /// Explore pages.
  final List<ExplorePageData> explorePages;

  /// Search page.
  final SearchPageData? searchPageData;

  /// Settings.
  final List<SettingItem> settings;

  /// Load comic info.
  final LoadComicFunc? loadComicInfo;

  /// Load comic pages.
  final Future<List<String>> Function(String id, String? ep)? loadComicPages;

  /// Load image. The imageKey usually is the url of image.
  ///
  /// Default is send a http get request to [imageKey].
  final Future<Uint8List>? Function(String imageKey)? loadImage;

  var data = <String, dynamic>{};

  Future<void> loadData() async {
    var file = File("${App.dataPath}/comic_source/$key.data");
    if (await file.exists()) {
      data = Map.from(jsonDecode(await file.readAsString()));
    }
  }

  Future<void> saveData() async {
    var file = File("${App.dataPath}/comic_source/$key.data");
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(data));
  }

  ComicSource(
      this.name,
      this.key,
      this.account,
      this.categoryData,
      this.categoryComicsData,
      this.favoriteData,
      this.explorePages,
      this.searchPageData,
      this.settings,
      this.loadComicInfo,
      this.loadComicPages,
      this.loadImage);
}

class AccountConfig {
  final LoginFunction? login;

  final String? loginWebsite;

  final String? registerWebsite;

  final List<String> logoutDeleteCookies;

  final List<String> logoutDeleteData;

  const AccountConfig(this.login, this.loginWebsite, this.registerWebsite,
      this.logoutDeleteCookies, this.logoutDeleteData);
}

class LoadImageRequest {
  String url;

  Map<String, String> headers;

  LoadImageRequest(this.url, this.headers);
}

class ExplorePageData {
  final String title;

  final ExplorePageType type;

  final ComicListBuilder? loadPage;

  final Future<Res<List<ExplorePagePart>>> Function()? loadMultiPart;

  ExplorePageData(this.title, this.type, this.loadPage, this.loadMultiPart);
}

class ExplorePagePart {
  final String title;

  final List<BaseComic> comics;

  /// If this is not null, the [ExplorePagePart] will show a button to jump to new page.
  ///
  /// Value of this field should match the following format:
  ///   - search:keyword
  ///   - category:categoryName
  final String? viewMore;

  const ExplorePagePart(this.title, this.comics, this.viewMore);
}

enum ExplorePageType {
  multiPageComicList,
  singlePageWithMultiPart,
}

typedef SearchFunction = Future<Res<List<BaseComic>>> Function(
    String keyword, int page, List<String> searchOption);

class SearchPageData {
  /// If this is not null, the default value of search options will be first element.
  final List<SearchOptions>? searchOptions;

  final SearchFunction? loadPage;

  const SearchPageData(this.searchOptions, this.loadPage);
}

class SearchOptions{
  final LinkedHashMap<String, String> options;

  final String label;

  const SearchOptions(this.options, this.label);
}

class SettingItem {
  final String name;
  final String iconName;
  final SettingType type;
  final List<String>? options;

  const SettingItem(this.name, this.iconName, this.type, this.options);
}

enum SettingType {
  switcher,
  selector,
  input,
}

class ComicInfoData {
  final String title;

  final String? subTitle;

  final String cover;

  final String? description;

  final Map<String, List<String>> tags;

  /// id-name
  final Map<String, String>? chapters;

  final List<String>? thumbnails;

  final Future<Res<List<String>>> Function(String id, int page)? thumbnailLoader;

  final int thumbnailMaxPage;

  final List<BaseComic>? suggestions;

  const ComicInfoData(this.title, this.subTitle, this.cover, this.description, this.tags,
      this.chapters, this.thumbnails, this.thumbnailLoader, this.thumbnailMaxPage, this.suggestions);
}

typedef CategoryComicsLoader = Future<Res<List<BaseComic>>> Function(
    String category, String? param, List<String> options, int page);

class CategoryComicsData {
  /// options
  final List<CategoryComicsOptions> options;

  /// [category] is the one clicked by the user on the category page.

  /// if [BaseCategoryPart.categoryParams] is not null, [param] will be not null.
  ///
  /// [Res.subData] should be maxPage or null if there is no limit.
  final CategoryComicsLoader load;

  const CategoryComicsData(this.options, this.load);
}

class CategoryComicsOptions{
  /// Use a [LinkedHashMap] to describe an option list.
  /// key is for loading comics, value is the name displayed on screen.
  /// Default value will be the first of the Map.
  final LinkedHashMap<String, String> options;

  /// If [notShowWhen] contains category's name, the option will not be shown.
  final List<String> notShowWhen;

  const CategoryComicsOptions(this.options, this.notShowWhen);
}
