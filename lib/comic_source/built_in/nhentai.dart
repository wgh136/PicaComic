import 'dart:async';
import 'dart:collection';

import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/network/nhentai_network/login.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/nhentai_network/tags.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/nhentai/comic_page.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import '../../base.dart';
import '../../foundation/history.dart';
import '../../pages/reader/comic_reading_page.dart';

final nhentai = ComicSource.named(
  name: 'nhentai',
  key: 'nhentai',
  filePath: 'built-in',
  favoriteData: FavoriteData(
    key: "nhentai",
    title: "nhentai",
    multiFolder: false,
    loadComic: (i, [folder]) => NhentaiNetwork().getFavorites(i),
    loadFolders: null,
  ),
  categoryData: CategoryData(
    title: "nhentai",
    key: "nhentai",
    categories: [
      const FixedCategoryPart("language", ["chinese", "japanese", "english"],
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "Tags", () => nhentaiTags.values.toList(), 50, "search"),
    ],
    enableRankingPage: false,
    buttons: [
      CategoryButtonData(
        label: "推荐",
        onTap: () => App.mainNavigatorKey?.currentContext?.to(
          () => const ComicPage(sourceKey: "nhentai", id: ""),
        ),
      ),
    ],
  ),
  categoryComicsData: CategoryComicsData.named(
    load: (category, param, options, page) async {
      var [_, type, name] = category.split('/');
      return NhentaiNetwork().getCategoryComics("/$type/$name", page, NhentaiSort.fromValue(options[0]));
    },
    options: [
      CategoryComicsOptions.named(
        options: LinkedHashMap.of({
          "": "Recent",
          "&sort=popular-today": "Popular-Today",
          "&sort=popular-week": "Popular-Week",
          "&sort=popular-month": "Popular-Month",
          "&sort=popular": "Popular-All",
        }),
        notShowWhen: ["random", "latest"],
      ),
    ],
  ),
  account: AccountConfig.named(
    onLogin: () async {
      var future = Completer<void>();
      nhLogin(() {
        future.complete();
      });
      await future.future;
      if (NhentaiNetwork().logged) {
        var source = ComicSource.find('nhentai')!;
        source.data["account"] = 'ok';
        source.saveData();
      }
    },
    logout: () {
      NhentaiNetwork().logged = false;
      NhentaiNetwork().logout();
      var source = ComicSource.find('nhentai')!;
      source.data["account"] = null;
      source.saveData();
    },
    allowReLogin: false,
  ),
  comicTileBuilderOverride: (context, comic, options) {
    return _NhentaiComicTile(
      comic as NhentaiComicBrief,
      addonMenuOptions: options,
    );
  },
  explorePages: [
    ExplorePageData.named(
      title: "nhentai",
      type: ExplorePageType.mixed,
      loadMixed: (index) async {
        var res = await NhentaiNetwork().getHomePage(index);
        if (res.error) {
          return Res.fromErrorRes(res);
        }
        if (index == 1) {
          return Res(<Object>[
            ExplorePagePart(
              "Popular",
              res.data.popular,
              null,
            ),
            res.data.latest,
          ], subData: 20000);
        } else {
          return Res([res.data.latest], subData: 20000);
        }
      },
    ),
  ],
  idMatcher: RegExp(r"^(\d+|nh\d+|nhentai\d+)$"),
  searchPageData: SearchPageData.named(
    loadPage: (keyword, page, options) {
      return NhentaiNetwork().search(keyword, page);
    },
    enableLanguageFilter: true,
    enableTagsSuggestions: true,
  ),
  comicPageBuilder: (context, id, cover) {
    return NhentaiComicPage(
      id,
      comicCover: cover,
    );
  },
);

class _NhentaiComicTile extends ComicTile {
  final NhentaiComicBrief comic;

  const _NhentaiComicTile(this.comic, {this.addonMenuOptions});

  @override
  String get description => comic.lang;

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(
          comic.cover,
          headers: {
            "User-Agent": webUA,
          },
        ),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        filterQuality: FilterQuality.medium,
      );

  @override
  void onTap_() {
    App.mainNavigatorKey!.currentContext!.to(
      () => ComicPage(
        sourceKey: 'nhentai',
        id: comic.id,
        cover: comic.cover,
      ),
    );
  }

  @override
  String get subTitle => "ID: ${comic.id}";

  @override
  String get title => comic.title;

  List<String> _generateTags(List<String> tags) {
    if (App.locale.languageCode != "zh") {
      return tags;
    }
    var res = <String>[];
    for (var tag in tags) {
      res.add(tag.translateTagsToCN);
    }
    return res;
  }

  @override
  List<String>? get tags => _generateTags(comic.tags);

  @override
  ActionFunc? get read => () async {
        bool cancel = false;
        var dialog = showLoadingDialog(
          App.globalContext!,
          onCancel: () => cancel = true,
        );
        var res = await NhentaiNetwork().getComicInfo(comic.id);
        if (cancel) {
          return;
        }
        dialog.close();
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          var history = await History.findOrCreate(res.data);
          App.globalTo(
            () => ComicReadingPage.nhentai(
              res.data.id,
              res.data.title,
              initialPage: history.page,
            ),
          );
        }
      };

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromNhentai(comic);

  @override
  String get comicID => comic.id;

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;
}
