library comic_source;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/update.dart';
import 'package:pica_comic/tools/extensions.dart';

import '../foundation/def.dart';
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

typedef LoadComicPagesFunc = Future<Res<List<String>>> Function(String id, String? ep);

typedef CommentsLoader = Future<Res<List<Comment>>>
    Function(String id, String? subId, int page, String? replyTo);

typedef SendCommentFunc = Future<Res<bool>>
    Function(String id, String? subId, String content, String? replyTo);

class ComicSource {
  static List<ComicSource> sources = [];

  static ComicSource? find(String key) =>
      sources.firstWhereOrNull((element) => element.key == key);

  static ComicSource? fromIntKey(int key) =>
      sources.firstWhereOrNull((element) => element.key.hashCode == key);

  static Future<void> init() async {
    final path = "${App.dataPath}/comic_source";
    if(! (await Directory(path).exists())){
      Directory(path).create();
      return;
    }
    await for (var entity in Directory(path).list()) {
      if (entity is File && entity.path.endsWith(".js")) {
        try {
          var source = await ComicSourceParser().parse(
              await entity.readAsString(), entity.absolute.path);
          sources.add(source);
        }
        catch(e, s){
          log("$e\n$s", "ComicSource", LogLevel.error);
        }
      }
    }
  }

  static reload() async{
    sources.clear();
    JsEngine().runCode("ComicSource.sources = {};");
    await init();
  }

  /// Name of this source.
  final String name;

  /// Identifier of this source.
  final String key;

  int get intKey{
    return key.hashCode;
  }

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
  final LoadComicPagesFunc? loadComicPages;

  /// Load image. The imageKey usually is the url of image.
  ///
  /// Default is send a http get request to [imageKey].
  final Future<Uint8List>? Function(String imageKey)? loadImage;

  final String? matchBriefIdReg;

  var data = <String, dynamic>{};

  bool get isLogin => data["account"] != null;

  final String filePath;

  final String url;

  final String version;

  final CommentsLoader? commentsLoader;

  final SendCommentFunc? sendCommentFunc;

  Future<void> loadData() async {
    var file = File("${App.dataPath}/comic_source/$key.data");
    if (await file.exists()) {
      data = Map.from(jsonDecode(await file.readAsString()));
    }
  }

  bool _isSaving = false;
  bool _haveWaitingTask = false;

  Future<void> saveData() async {
    if(_haveWaitingTask)  return;
    while(_isSaving) {
      _haveWaitingTask = true;
      await Future.delayed(const Duration(milliseconds: 20));
      _haveWaitingTask = false;
    }
    _isSaving = true;
    var file = File("${App.dataPath}/comic_source/$key.data");
    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(data));
    _isSaving = false;
  }

  Future<bool> reLogin() async{
    if(data["account"] == null){
      return false;
    }
    final List accountData = data["account"];
    var res = await account!.login!(accountData[0], accountData[1]);
    if (res.error) {
      return false;
    } else {
      return true;
    }
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
      this.loadImage,
      this.matchBriefIdReg,
      this.filePath,
      this.url,
      this.version,
      this.commentsLoader,
      this.sendCommentFunc);

  ComicSource.unknown(this.key):
        name = "Unknown",
        account = null,
        categoryData = null,
        categoryComicsData = null,
        favoriteData = null,
        explorePages = [],
        searchPageData = null,
        settings = [],
        loadComicInfo = null,
        loadComicPages = null,
        loadImage = null,
        matchBriefIdReg = null,
        filePath = "",
        url = "",
        version = "",
        commentsLoader = null,
        sendCommentFunc = null;
}

class AccountConfig {
  final LoginFunction? login;

  final String? loginWebsite;

  final String? registerWebsite;

  final void Function() logout;

  const AccountConfig(this.login, this.loginWebsite, this.registerWebsite,
      this.logout);
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

  final String sourceKey;

  final String comicId;

  final bool? isFavorite;

  final String? subId;

  const ComicInfoData(this.title, this.subTitle, this.cover, this.description, this.tags,
      this.chapters, this.thumbnails, this.thumbnailLoader, this.thumbnailMaxPage,
      this.suggestions, this.sourceKey, this.comicId, {this.isFavorite, this.subId});

  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "subTitle": subTitle,
      "cover": cover,
      "description": description,
      "tags": tags,
      "chapters": chapters,
      "sourceKey": sourceKey,
      "comicId": comicId,
      "isFavorite": isFavorite,
      "subId": subId,
    };
  }

  static Map<String, List<String>> _generateMap(Map<String, dynamic> map){
    var res = <String, List<String>>{};
    map.forEach((key, value) {
      res[key] = List<String>.from(value);
    });
    return res;
  }

  ComicInfoData.fromJson(Map<String, dynamic> json):
        title = json["title"],
        subTitle = json["subTitle"],
        cover = json["cover"],
        description = json["description"],
        tags = _generateMap(json["tags"]),
        chapters = Map<String, String>.from(json["chapters"]),
        sourceKey = json["sourceKey"],
        comicId = json["comicId"],
        thumbnails = null,
        thumbnailLoader = null,
        thumbnailMaxPage = 0,
        suggestions = null,
        isFavorite = json["isFavorite"],
        subId = json["subId"];
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

  final List<String>? showWhen;

  const CategoryComicsOptions(this.options, this.notShowWhen, this.showWhen);
}

class Comment{
  final String userName;
  final String? avatar;
  final String content;
  final String? time;
  final int? replyCount;
  final String? id;

  const Comment(this.userName, this.avatar, this.content, this.time, this.replyCount, this.id);
}
