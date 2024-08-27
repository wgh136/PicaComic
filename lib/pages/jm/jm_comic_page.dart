import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/built_in/jm.dart';
import 'package:pica_comic/components/select_download_eps.dart';
import 'package:pica_comic/network/jm_network/jm_download.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../../foundation/app.dart';
import '../../foundation/history.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/jm_network/jm_models.dart';
import '../../foundation/ui_mode.dart';
import '../../network/download.dart';
import '../../foundation/local_favorites.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';
import 'jm_comments_page.dart';

class JmComicPage extends BaseComicPage<JmComicInfo> {
  const JmComicPage(this.id, {super.key});

  @override
  final String id;

  @override
  ActionFunc? get onLike => () {
        if (!data!.liked) {
          jmNetwork.likeComic(data!.id);
        }
        data!.liked = true;
        update();
      };

  @override
  bool get isLiked => data!.liked;

  @override
  String? get likeCount => data!.likes.toString().replaceLast("000", "K");

  @override
  void openFavoritePanel() {
    favoriteComic(FavoriteComicWidget(
      havePlatformFavorite: jm.isLogin,
      needLoadFolderData: true,
      setFavorite: (b) {
        if (favorite != b) {
          favorite = b;
          update();
        }
      },
      foldersLoader: () async {
        var res = await jmNetwork.getFolders();
        if (res.error) {
          return res;
        } else {
          var resData = <String, String>{"0": "全部收藏".tl};
          resData.addAll(res.data);
          return Res(resData);
        }
      },
      localFavoriteItem: toLocalFavoriteItem(),
      favoriteOnPlatform: data!.favorite,
      selectFolderCallback: (folder, page) async {
        if (page == 0) {
          var res = await jmNetwork.favorite(id, folder);
          if (res.success) {
            data!.favorite = true;
          }
          return res;
        } else {
          LocalFavoritesManager().addComic(
            folder,
            toLocalFavoriteItem(),
          );
          return const Res(true);
        }
      },
      cancelPlatformFavorite: () async {
        var res = await jmNetwork.favorite(id, null);
        if(res.success) {
          data!.favorite = false;
        }
        return res;
      },
    ));
  }

  @override
  ActionFunc? get openComments => () {
        showComments(App.globalContext!, id, data!.comments);
      };

  @override
  String get cover => getJmCoverUrl(id);

  @override
  void download() => downloadComic(data!, App.globalContext!);

  String _getEpName(int index) {
    final epName = data!.epNames.elementAtOrNull(index);
    if (epName != null) {
      return epName;
    }
    var name = "第 @c 章".tlParams({"c": (index + 1).toString()});
    return name;
  }

  @override
  EpsData? get eps {
    return EpsData(
      List<String>.generate(
          data!.series.values.length, (index) => _getEpName(index)),
      (i) async {
        await History.findOrCreate(data!);
        App.globalTo(() => ComicReadingPage.jmComic(data!, i + 1));
      },
    );
  }

  @override
  String? get introduction => data!.description;

  @override
  Future<Res<JmComicInfo>> loadData() => JmNetwork().getComicInfo(id);

  @override
  int? get pages => null;

  @override
  Future<bool> loadFavorite(JmComicInfo data) async {
    return data.favorite ||
        (await LocalFavoritesManager().findWithModel(toLocalFavoriteItem())).isNotEmpty;
  }

  @override
  void read(History? history) async {
    history = await History.createIfNull(history, data!);
    App.globalTo(
      () => ComicReadingPage.jmComic(
        data!,
        history!.ep,
        initialPage: history.page,
      ),
    );
  }

  @override
  Widget recommendationBuilder(JmComicInfo data) =>
      SliverGridComics(comics: data.relatedComics, sourceKey: 'jm');

  @override
  String get tag => "Jm ComicPage $id";

  @override
  Map<String, List<String>>? get tags => {
        "作者".tl: (data!.author.isEmpty) ? "未知".tl.toList() : data!.author,
        "ID": "JM${data!.id}".toList(),
        "标签".tl: data!.tags
      };

  @override
  void tapOnTag(String tag, String key) => context.to(() => SearchResultPage(
        keyword: tag,
        sourceKey: "jm",
      ));

  @override
  ThumbnailsData? get thumbnailsCreator => null;

  @override
  String? get title => data?.name;

  @override
  Card? get uploaderInfo => null;

  @override
  String get source => "禁漫天堂".tl;

  @override
  FavoriteItem toLocalFavoriteItem() => FavoriteItem.fromJmComic(JmComicBrief(
      id,
      data!.author.elementAtOrNull(0) ?? "",
      data!.name,
      data!.description,
      [],
      []));

  @override
  String get downloadedId => "jm${data!.id}";

  @override
  String get sourceKey => "jm";
}

void downloadComic(JmComicInfo comic, BuildContext context) async {
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showToast(message: "下载中".tl);
      return;
    }
  }

  List<String> eps = [];
  if (comic.series.isEmpty) {
    eps.add("第1章".tl);
  } else {
    eps = List<String>.generate(comic.series.length,
        (index) => "第 @c 章".tlParams({"c": (index + 1).toString()}));
  }

  var downloaded = <int>[];
  if (DownloadManager().isExists("jm${comic.id}")) {
    var downloadedComic =
        (await DownloadManager().getComicOrNull("jm${comic.id}"))!
        as DownloadedJmComic;
    downloaded.addAll(downloadedComic.downloadedEps);
  }

  if (UiMode.m1(App.globalContext!)) {
    showModalBottomSheet(
        context: App.globalContext!,
        builder: (context) {
          return SelectDownloadChapter(eps, (selectedEps) {
            downloadManager.addJmDownload(comic, selectedEps);
            App.globalBack();
            showToast(message: "已加入下载".tl);
          }, downloaded);
        });
  } else {
    showSideBar(
        App.globalContext!,
        SelectDownloadChapter(eps, (selectedEps) {
          downloadManager.addJmDownload(comic, selectedEps);
          App.globalBack();
          showToast(message: "已加入下载".tl);
        }, downloaded),
        useSurfaceTintColor: true);
  }
}
