import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/jm_views/jm_comments_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_widgets.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../foundation/app.dart';
import '../../foundation/history.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/jm_network/jm_models.dart';
import '../../foundation/ui_mode.dart';
import '../../network/download.dart';
import '../main_page.dart';
import '../../foundation/local_favorites.dart';
import '../widgets/grid_view_delegate.dart';
import '../widgets/select_download_eps.dart';
import '../widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class JmComicPage extends ComicPage<JmComicInfo> {
  const JmComicPage(this.id, {super.key});
  @override
  final String id;

  @override
  ActionFunc? get onLike => (){
    if(!data!.liked){
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
      havePlatformFavorite: appdata.jmName != "",
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
      target: id,
      favoriteOnPlatform: data!.favorite,
      selectFolderCallback: (folder, page) async {
        if (page == 0) {
          showMessage(context, "正在添加收藏".tl);
          var res = await jmNetwork.favorite(id, folder);
          if (res.error) {
            showMessage(App.globalContext, res.errorMessageWithoutNull);
            return;
          }
          data!.favorite = true;
          showMessage(App.globalContext, "成功添加收藏".tl);
        } else {
          LocalFavoritesManager().addComic(
              folder,
              FavoriteItem.fromJmComic(JmComicBrief(
                  id,
                  data!.author.elementAtOrNull(0) ?? "",
                  data!.name,
                  data!.description,
                  [],
                  [],
                  ignoreExamination: true)));
          showMessage(App.globalContext, "成功添加收藏".tl);
        }
      },
      cancelPlatformFavorite: () async {
        showMessage(context, "正在取消收藏".tl);
        var res = await jmNetwork.favorite(id, null);
        showMessage(
            App.globalContext, !res.error ? "成功取消收藏".tl : "网络错误".tl);
        data!.favorite = false;
      },
    ));
  }

  @override
  ActionFunc? get openComments => (){
    showComments(context, id, data!.comments);
  };

  @override
  String get cover => getJmCoverUrl(id);

  @override
  void download() => downloadComic(data!, context);

  String _getEpName(int index){
    final epName = data!.epNames.elementAtOrNull(index);
    if(epName != null){
      return epName;
    }
    var name = "第 @c 章".tlParams({"c": (index + 1).toString()});
    return name;
  }

  @override
  EpsData? get eps => EpsData(
          List<String>.generate(data!.series.values.length,
              (index) => _getEpName(index)),
          (i) async {
        await addJmHistory(data!);
        App.globalTo(() => ComicReadingPage.jmComic(
            data!.id, data!.name, data!.series.values.toList(), i + 1, data!.epNames));
      });

  @override
  String? get introduction => data!.description;

  @override
  Future<Res<JmComicInfo>> loadData() => JmNetwork().getComicInfo(id);

  @override
  int? get pages => null;

  @override
  Future<bool> loadFavorite(JmComicInfo data) async {
    return data.favorite ||
        (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }

  @override
  void read(History? history) {
    readJmComic(data!, data!.series.values.toList(), history != null);
  }

  @override
  SliverGrid recommendationBuilder(JmComicInfo data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(
            childCount: data.relatedComics.length, (context, i) {
          return JmComicTile(data.relatedComics[i]);
        }),
        gridDelegate: SliverGridDelegateWithComics(),
      );

  @override
  String get tag => "Jm ComicPage $id";

  @override
  Map<String, List<String>>? get tags => {
        "作者".tl: (data!.author.isEmpty) ? "未知".tl.toList() : data!.author,
        "ID": "JM${data!.id}".toList(),
        "标签".tl: data!.tags
      };

  @override
  void tapOnTags(String tag) => MainPage.to(() => JmSearchPage(tag));

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
      [],
      ignoreExamination: true));
}

void downloadComic(JmComicInfo comic, BuildContext context) async {
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tl);
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
  if (DownloadManager().downloaded.contains("jm${comic.id}")) {
    var downloadedComic =
        await DownloadManager().getJmComicFormId("jm${comic.id}");
    downloaded.addAll(downloadedComic.downloadedEps);
  }

  if (UiMode.m1(App.globalContext!)) {
    showModalBottomSheet(
        context: App.globalContext!,
        builder: (context) {
          return SelectDownloadChapter(eps, (selectedEps) {
            downloadManager.addJmDownload(comic, selectedEps);
            App.globalBack();
            showMessage(context, "已加入下载".tl);
          }, downloaded);
        });
  } else {
    showSideBar(
        App.globalContext!,
        SelectDownloadChapter(eps, (selectedEps) {
          downloadManager.addJmDownload(comic, selectedEps);
          App.globalBack();
          showMessage(context, "已加入下载".tl);
        }, downloaded),
        useSurfaceTintColor: true);
  }
}
