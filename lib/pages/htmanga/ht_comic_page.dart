import 'package:pica_comic/comic_source/built_in/ht_manga.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

class HtComicPage extends BaseComicPage<HtComicInfo> {
  const HtComicPage(this.id, {super.key, this.comicCover});

  @override
  final String id;

  final String? comicCover;

  @override
  void openFavoritePanel() {
    favoriteComic(FavoriteComicWidget(
      havePlatformFavorite: htManga.isLogin,
      needLoadFolderData: true,
      foldersLoader: () => HtmangaNetwork().getFolders(),
      target: data!.id,
      setFavorite: (b) {},
      selectFolderCallback: (folder, page) async {
        if (page == 0) {
          showToast(message: "正在添加收藏".tl);
          var res = await HtmangaNetwork().addFavorite(data!.id, folder);
          if (res.error) {
            showToast(message: res.errorMessageWithoutNull);
          } else {
            showToast(message: "成功添加收藏".tl);
          }
        } else {
          LocalFavoritesManager()
              .addComic(folder, FavoriteItem.fromHtcomic(data!.toBrief()));
          showToast(message: "成功添加收藏".tl);
        }
      },
    ));
  }

  @override
  String? get cover => data?.cover ?? comicCover;

  @override
  void download() {
    final id = "Ht${data!.id}";
    if (DownloadManager().downloaded.contains(id)) {
      showToast(message: "已下载".tl);
      return;
    }
    for (var i in DownloadManager().downloading) {
      if (i.id == id) {
        showToast(message: "下载中".tl);
        return;
      }
    }
    DownloadManager().addHtDownload(data!);
    showToast(message: "已加入下载队列".tl);
  }

  @override
  void onThumbnailTapped(int index) async {
    await History.findOrCreate(data!);
    App.globalTo(
      () => ComicReadingPage.htmanga(
        data!.target,
        data!.title,
        initialPage: index + 1,
      ),
    );
  }

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => data!.description;

  @override
  Future<Res<HtComicInfo>> loadData() => HtmangaNetwork().getComicInfo(id);

  @override
  int? get pages => null;

  @override
  void read(History? history) async {
    history = await History.createIfNull(history, data!);
    App.globalTo(
      () => ComicReadingPage.htmanga(
        data!.target,
        data!.title,
        initialPage: history!.page,
      ),
    );
  }

  @override
  SliverGrid? recommendationBuilder(HtComicInfo data) => null;

  @override
  String get tag => "Ht ComicPage $id";

  @override
  Map<String, List<String>>? get tags =>
      {"分类".tl: data!.category.toList(), "标签".tl: data!.tags.keys.toList()};

  @override
  void tapOnTag(String tag, String key) => context.to(() => SearchResultPage(
        keyword: tag,
        sourceKey: sourceKey,
      ));

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData(
      data!.thumbnails,
      (page) => HtmangaNetwork().getThumbnails(data!.id, page),
      (data!.pages / 12).ceil());

  @override
  String? get title => data?.name.removeAllBlank;

  @override
  Card? get uploaderInfo => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.inversePrimary,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                flex: 0,
                child: Avatar(
                  size: 50,
                  avatarUrl: data!.avatar,
                  couldBeShown: false,
                  name: data!.uploader,
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data!.uploader,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text("投稿作品${data!.uploadNum}部")
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Future<bool> loadFavorite(HtComicInfo data) => Future.value(false);

  @override
  String get source => "绅士漫画".tl;

  @override
  FavoriteItem toLocalFavoriteItem() =>
      FavoriteItem.fromHtcomic(data!.toBrief());

  @override
  String get downloadedId => "Ht${data!.id}";

  @override
  String get sourceKey => 'htmanga';
}

class HtComicPageLogic extends StateController {
  bool loading = true;
  HtComicInfo? comic;
  String? message;
  ScrollController controller = ScrollController();
  bool showAppbarTitle = false;
  List<String> images = [];

  void get(String id) async {
    var res = await HtmangaNetwork().getComicInfo(id);
    message = res.errorMessage;
    comic = res.dataOrNull;
    if (res.subData != null) {
      images.addAll(res.subData);
    }
    loading = false;
    update();
  }

  void refresh_() {
    comic = null;
    message = null;
    loading = true;
    update();
  }

  void getImages() async {
    var nextPage = images.length ~/ 12 + 1;
    var res = await HtmangaNetwork().getThumbnails(comic!.id, nextPage);
    if (!res.error) {
      images.addAll(res.data);
      update();
    }
  }
}
