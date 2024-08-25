import 'package:flutter/widgets.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/def.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/htmanga/ht_comic_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import '../comic_source.dart';

final htManga = ComicSource.named(
  name: '紳士漫畫',
  key: 'htmanga',
  filePath: 'built-in',
  favoriteData: FavoriteData(
    key: "htmanga",
    title: "绅士漫画",
    multiFolder: true,
    loadComic: (i, [folder]) =>
        HtmangaNetwork().getFavoriteFolderComics(folder!, i),
    loadFolders: ([String? comicId]) => HtmangaNetwork().getFolders(),
    allFavoritesId: "0",
    deleteFolder: (id) async {
      var res = await HtmangaNetwork().deleteFolder(id);
      return res
          ? const Res(true)
          : const Res(false, errorMessage: "Network Error");
    },
    addFolder: (name) async {
      var res = await HtmangaNetwork().createFolder(name);
      return res
          ? const Res(true)
          : const Res(false, errorMessage: "Network Error");
    },
    addOrDelFavorite: (id, folder, isAdding) async {
      if (isAdding) return const Res.error("invalid");
      var res = await HtmangaNetwork().delFavorite(id);
      return res;
    },
  ),
  categoryData: const CategoryData(
    title: "绅士漫画",
    key: "htmanga",
    categories: [
      FixedCategoryPart(
        "最新",
        ["最新漫画"],
        "category",
        ["/albums.html"],
      ),
      FixedCategoryPart(
        "同人志",
        [
          "同人志",
          "同人志-汉化",
          "同人志-日语",
          "同人志-English",
          "同人志-CG画集",
          "同人志-3D漫画",
          "同人志-Cosplay"
        ],
        "category",
        [
          "/albums-index-cate-5.html",
          "/albums-index-cate-1.html",
          "/albums-index-cate-12.html",
          "/albums-index-cate-16.html",
          "/albums-index-cate-2.html",
          "/albums-index-cate-22.html",
          "/albums-index-cate-3.html",
        ],
      ),
      FixedCategoryPart(
        "单行本",
        ["单行本", "单行本-汉化", "单行本-日语", "单行本-English"],
        "category",
        [
          "/albums-index-cate-6.html",
          "/albums-index-cate-9.html",
          "/albums-index-cate-13.html",
          "/albums-index-cate-17.html",
        ],
      ),
      FixedCategoryPart(
        "杂志&短篇",
        ["杂志&短篇", "杂志&短篇-汉化", "杂志&短篇-日语", "杂志&短篇-English"],
        "category",
        [
          "/albums-index-cate-7.html",
          "/albums-index-cate-10.html",
          "/albums-index-cate-14.html",
          "/albums-index-cate-18.html",
        ],
      ),
      FixedCategoryPart(
        "韩漫",
        ["韩漫", "韩漫-汉化", "韩漫-其它"],
        "category",
        [
          "/albums-index-cate-19.html",
          "/albums-index-cate-20.html",
          "/albums-index-cate-21.html",
        ],
      ),
    ],
    enableRankingPage: false,
  ),
  categoryComicsData: CategoryComicsData.named(
    load: (category, param, options, page) async {
      return HtmangaNetwork().getComicList(
        HtmangaNetwork.baseUrl + param!,
        page,
      );
    },
  ),
  account: AccountConfig.named(
    registerWebsite: "https://www.wnacg.com/albums.html",
    login: (account, pwd) async {
      var htManga = ComicSource.find('htmanga')!;
      var res = await HtmangaNetwork().login(account, pwd);
      if (!res.error) {
        htManga.data['name'] = account;
      }
      return res;
    },
    logout: () {
      ComicSource.find('htmanga')!.data['name'] = null;
      HtmangaNetwork().logout();
    },
  ),
  comicTileBuilderOverride: (context, comic, options) {
    return _HtComicTile(
      comic: comic as HtComicBrief,
      addonMenuOptions: options,
    );
  },
  explorePages: [
    ExplorePageData.named(
      title: "绅士漫画",
      type: ExplorePageType.singlePageWithMultiPart,
      loadMultiPart: () async {
        var homepage = await HtmangaNetwork().getHomePage();
        if (homepage.error) {
          return Res.fromErrorRes(homepage);
        }
        var res = <ExplorePagePart>[];
        for (int i = 0; i < homepage.data.comics.length; i++) {
          var name = homepage.data.links.keys.elementAt(i);
          res.add(
            ExplorePagePart(
              name,
              homepage.data.comics[i],
              "category:$name@${homepage.data.links[name]}",
            ),
          );
        }
        return Res(res);
      },
    ),
  ],
  searchPageData: SearchPageData.named(
    loadPage: (keyword, page, options) {
      return HtmangaNetwork().search(keyword, page);
    },
  ),
  comicPageBuilder: (context, id, cover) {
    return HtComicPage(
      id,
      comicCover: cover,
    );
  },
);

class _HtComicTile extends ComicTile {
  const _HtComicTile({required this.comic, this.addonMenuOptions});

  final HtComicBrief comic;

  @override
  String get description => comic.time.trim();

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(
          comic.image,
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
    App.mainNavigatorKey!.currentContext!.to(() => ComicPage(
          sourceKey: 'htmanga',
          id: comic.id,
          cover: comic.cover,
        ));
  }

  @override
  String get subTitle => "${comic.pages} Pages";

  @override
  ActionFunc? get read => () async {
        bool cancel = false;
        var dialog = showLoadingDialog(App.globalContext!,
            onCancel: () => cancel = true);
        var res = await HtmangaNetwork().getComicInfo(comic.id);
        if (cancel) {
          return;
        }
        dialog.close();
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          var history = await History.findOrCreate(res.data);
          App.globalTo(
            () => ComicReadingPage.htmanga(
              res.data.id,
              comic.name,
              initialPage: history.page,
            ),
          );
        }
      };

  @override
  String get title => comic.name.trim();

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.fromHtcomic(comic);

  @override
  String get comicID => comic.id;

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;
}
