import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/def.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/jm/jm_comic_page.dart';
import 'package:pica_comic/pages/jm/week_recommendation_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';

final jm = ComicSource.named(
  name: '禁漫天堂',
  key: 'jm',
  filePath: 'built-in',
  favoriteData: FavoriteData(
    key: "jm",
    title: "禁漫天堂",
    multiFolder: true,
    loadComic: (i, [folder]) => JmNetwork().getFolderComicsPage(folder!, i),
    loadFolders: ([String? comicId]) => JmNetwork().getFolders(),
    deleteFolder: (id) => JmNetwork().deleteFolder(id),
    addFolder: (name) => JmNetwork().createFolder(name),
    allFavoritesId: "0",
    addOrDelFavorite: (id, folder, isAdding) async {
      if (isAdding) return const Res.error("invalid");
      var res = await JmNetwork().favorite(id, folder);
      return res;
    },
  ),
  categoryData: CategoryData(
    title: "禁漫天堂",
    key: "jm",
    categories: [
      const FixedCategoryPart(
        "成人A漫",
        ["最新A漫", "同人", "單本", "短篇", "其他類", "韓漫", "美漫", "Cosplay", "3D", "禁漫漢化組"],
        "category",
        [
          "0",
          "doujin",
          "single",
          "short",
          "another",
          "hanman",
          "meiman",
          "another_cosplay",
          "3D",
          "禁漫漢化組"
        ],
      ),
      const FixedCategoryPart(
        "主題A漫",
        [
          '無修正',
          '劇情向',
          '青年漫',
          '校服',
          '純愛',
          '人妻',
          '教師',
          '百合',
          'Yaoi',
          '性轉',
          'NTR',
          '女裝',
          '癡女',
          '全彩',
          '女性向',
          '完結',
          '純愛',
          '禁漫漢化組'
        ],
        "search",
      ),
      const FixedCategoryPart(
        "角色扮演",
        [
          '御姐',
          '熟女',
          '巨乳',
          '貧乳',
          '女性支配',
          '教師',
          '女僕',
          '護士',
          '泳裝',
          '眼鏡',
          '連褲襪',
          '其他制服',
          '兔女郎'
        ],
        "search",
      ),
      const FixedCategoryPart(
        "特殊PLAY",
        [
          '群交',
          '足交',
          '束縛',
          '肛交',
          '阿黑顏',
          '藥物',
          '扶他',
          '調教',
          '野外露出',
          '催眠',
          '自慰',
          '觸手',
          '獸交',
          '亞人',
          '怪物女孩',
          '皮物',
          'ryona',
          '騎大車'
        ],
        "search",
      ),
      const FixedCategoryPart(
        "其它",
        ['CG', '重口', '獵奇', '非H', '血腥暴力', '站長推薦'],
        "search",
      ),
    ],
    enableRankingPage: true,
    buttons: [
      CategoryButtonData(
        label: "每周推荐",
        onTap: () => App.mainNavigatorKey?.currentContext?.to(
              () => JmWeekRecommendationPage(),
        ),
      ),
    ],
  ),
  categoryComicsData: CategoryComicsData.named(
    load: (category, param, options, page) async {
      return JmNetwork().getCategoryComics(
        param ?? category,
        ComicsOrder.fromValue(options[0]),
        page,
      );
    },
    options: [
      CategoryComicsOptions.named(
        options: LinkedHashMap.of({
          "mr": "最新",
          "mv": "总排行",
          "mv_m": "月排行",
          "mv_w": "周排行",
          "mv_t": "日排行",
          "mp": "最多图片",
          "tf": "最多喜欢",
        }),
      ),
    ],
    rankingData: RankingData.named(
      options: {
        "mv": "总排行",
        "mv_m": "月排行",
        "mv_w": "周排行",
        "mv_t": "日排行",
      },
      load: (option, page) {
        return JmNetwork()
            .getCategoryComics('0', ComicsOrder.fromValue(option), page);
      },
    ),
  ),
  account: AccountConfig.named(
    registerWebsite: "https://18comic.vip/signup",
    login: (account, pwd) async {
      var res = await jmNetwork.login(account, pwd);
      var a = <String>[account, pwd];
      var source = ComicSource.find('jm')!;
      source.data['account'] = a;
      source.saveData();
      return res;
    },
    logout: () {
      jmNetwork.logout();
    },
    infoItems: [
      AccountInfoItem(
        title: "用户名",
        data: () => ComicSource.find('jm')!.data['name'] ?? '',
      ),
    ],
  ),
  comicTileBuilderOverride: (context, comic, options) {
    return _JmComicTile(
      comic as JmComicBrief,
      addonMenuOptions: options,
    );
  },
  explorePages: [
    ExplorePageData.named(
      title: "禁漫主页",
      type: ExplorePageType.singlePageWithMultiPart,
      loadMultiPart: () async {
        var homePageData = await JmNetwork().getHomePage();
        if (homePageData.error) {
          return Res.fromErrorRes(homePageData);
        }
        var res = <ExplorePagePart>[];
        for (var part in homePageData.data.items) {
          res.add(ExplorePagePart(
            part.name,
            part.comics,
            'category:${part.name}@${part.id}',
          ));
        }
        return Res(res);
      },
    ),
    ExplorePageData.named(
      title: "禁漫最新",
      type: ExplorePageType.multiPageComicList,
      loadPage: (page) => JmNetwork().getLatest(page),
    ),
  ],
  idMatcher: RegExp(r"^(\d+|jm\d+)$"),
  searchPageData: SearchPageData.named(
    loadPage: (keyword, page, options) {
      return JmNetwork().searchNew(
        keyword,
        page,
        ComicsOrder.fromValue(options[0]),
      );
    },
    searchOptions: [
      SearchOptions.named(
        label: "排序",
        options: LinkedHashMap.of({
          "mr": "最新",
          "mv": "总排行",
          "mv_m": "月排行",
          "mv_w": "周排行",
          "mv_t": "日排行",
          "mp": "最多图片",
          "tf": "最多喜欢",
        }),
      ),
    ],
  ),
  comicPageBuilder: (context, id, cover) {
    return JmComicPage(id);
  },
);

class _JmComicTile extends ComicTile {
  final JmComicBrief comic;

  const _JmComicTile(this.comic, {this.addonMenuOptions});

  @override
  String get description => () {
        var categories = "";
        for (final category in comic.categories) {
          categories += "${category.name} ";
        }
        return categories;
      }.call();

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(
          getJmCoverUrl(comic.id),
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
      () => ComicPage(sourceKey: 'jm', id: comic.id, cover: comic.cover),
    );
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.name;

  @override
  ActionFunc? get read => () async {
        bool cancel = false;
        var dialog = showLoadingDialog(
          App.globalContext!,
          onCancel: () => cancel = true,
        );
        var res = await JmNetwork().getComicInfo(comic.id);
        if (cancel) {
          return;
        }
        dialog.close();
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          var history = await History.findOrCreate(res.data);
          App.globalTo(
                () => ComicReadingPage.jmComic(
              res.data,
              history.ep,
              initialPage: history.page,
            ),
          );
        }
      };

  @override
  List<String>? get tags => comic.tags;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromJmComic(comic);

  @override
  String get comicID => comic.id;

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;
}
