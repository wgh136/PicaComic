import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/nhentai/comic_tile.dart';
import 'package:pica_comic/views/nhentai/nhentai_category.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../../foundation/history.dart';
import '../../network/download.dart';
import '../main_page.dart';
import '../../foundation/local_favorites.dart';
import '../widgets/grid_view_delegate.dart';
import '../widgets/show_message.dart';
import 'comments.dart';

class NhentaiComicPage extends ComicPage<NhentaiComic> {
  const NhentaiComicPage(this._id, {super.key, this.comicCover});

  final String _id;

  final String? comicCover;

  @override
  String get url => "https://nhentai.net/g/$_id/";

  @override
  String get id => (data?.id) ?? _id;

  @override
  ActionFunc? get searchSimilar => () {
        String? subTitle = data!.subTitle;
        if (subTitle == "") {
          subTitle = null;
        }
        var title = subTitle ?? data!.title;
        title = title
            .replaceAll(RegExp(r"\[.*?\]"), "")
            .replaceAll(RegExp(r"\(.*?\)"), "");
        MainPage.to(() => NhentaiSearchPage("\"$title\"".trim()));
      };

  @override
  void openFavoritePanel() {
    favoriteComic(FavoriteComicWidget(
      havePlatformFavorite: NhentaiNetwork().logged,
      needLoadFolderData: false,
      favoriteOnPlatform: data!.favorite,
      initialFolder: "0",
      target: id,
      setFavorite: (b) {
        if (favorite != b) {
          favorite = b;
          update();
        }
      },
      folders: const {"0": "Nhentai"},
      selectFolderCallback: (folder, page) async {
        if (page == 0) {
          showMessage(context, "正在添加收藏".tl);
          var res =
          await NhentaiNetwork().favoriteComic(id, data!.token);
          if (res.error) {
            showMessage(App.globalContext, res.errorMessageWithoutNull);
            return;
          }
          data!.favorite = true;
          showMessage(App.globalContext, "成功添加收藏".tl);
        } else {
          LocalFavoritesManager().addComic(
              folder,
              FavoriteItem.fromNhentai(NhentaiComicBrief(
                  data!.title,
                  data!.cover,
                  id,
                  "Unknown",
                  data!.tags["Tags"] ?? const <String>[])));
          showMessage(App.globalContext, "成功添加收藏".tl);
        }
      },
      cancelPlatformFavorite: () async {
        showMessage(context, "正在取消收藏".tl);
        var res =
        await NhentaiNetwork().unfavoriteComic(id, data!.token);
        showMessage(
            App.globalContext, !res.error ? "成功取消收藏".tl : "网络错误".tl);
        data!.favorite = false;
      },
    ));
  }

  @override
  ActionFunc? get openComments => (){
    showComments(context, id);
  };

  @override
  String? get cover => comicCover ?? data?.cover;

  @override
  void download() {
    final id = "nhentai${data!.id}";
    if (DownloadManager().downloaded.contains(id)) {
      showMessage(context, "已下载".tl);
      return;
    }
    for (var i in DownloadManager().downloading) {
      if (i.id == id) {
        showMessage(context, "下载中".tl);
        return;
      }
    }
    DownloadManager().addNhentaiDownload(data!);
    showMessage(context, "已加入下载队列".tl);
  }

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  bool get enableTranslationToCN => App.locale.languageCode == "zh";

  @override
  Future<Res<NhentaiComic>> loadData() => NhentaiNetwork().getComicInfo(_id);

  @override
  int? get pages => int.tryParse(data?.tags["Pages"]?.elementAtOrNull(0) ?? "");

  @override
  String? get subTitle => data?.subTitle;

  @override
  void read(History? history) {
    readNhentai(data!, history?.page ?? 0);
  }

  @override
  void onThumbnailTapped(int index) {
    readNhentai(data!, index + 1);
  }

  @override
  Future<bool> loadFavorite(NhentaiComic data) async {
    return data.favorite ||
        (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }

  @override
  SliverGrid? recommendationBuilder(NhentaiComic data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(
            childCount: data.recommendations.length, (context, i) {
          return NhentaiComicTile(data.recommendations[i]);
        }),
        gridDelegate: SliverGridDelegateWithComics(),
      );

  @override
  String get tag => "Nhentai $_id";

  Map<String, List<String>> generateTags() {
    var tags = Map<String, List<String>>.from(data!.tags);
    tags.remove("Pages");
    tags.removeWhere((key, value) => value.isEmpty);
    return tags;
  }

  @override
  Map<String, List<String>>? get tags => generateTags();

  @override
  void tapOnTag(String tag, String key) {
    if (tag.contains(" ")) {
      tag = tag.replaceAll(' ', '-');
    }
    String? category = switch(key) {
      "Parodies" => "/parody/$tag",
      "Character" => "/character/$tag",
      "Tags" => "/tag/$tag",
      "Artists" => "/artist/$tag",
      "Groups" => "/group/$tag",
      "Languages" => "/language/$tag",
      "Categories" => "/category/$tag",
      _ => null
    };

    if(category == null) {
      MainPage.to(() => NhentaiSearchPage(tag));
    } else {
      MainPage.to(() => NhentaiCategory(category));
    }
  }

  @override
  ThumbnailsData? get thumbnailsCreator =>
      ThumbnailsData(data!.thumbnails, (page) async => const Res([]), 1);

  @override
  String? get title => data?.title;

  @override
  Card? get uploaderInfo => null;

  @override
  String get source => "Nhentai";

  @override
  FavoriteItem toLocalFavoriteItem() => FavoriteItem.fromNhentai(NhentaiComicBrief(
      data!.title,
      data!.cover,
      id,
      "Unknown",
      data!.tags["Tags"] ?? const <String>[]));

  @override
  String get downloadedId => "nhentai${data!.id}";
}
