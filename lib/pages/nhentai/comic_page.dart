import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/category_comics_page.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../../foundation/history.dart';
import '../../network/download.dart';
import '../../foundation/local_favorites.dart';
import 'comments.dart';

class NhentaiComicPage extends BaseComicPage<NhentaiComic> {
  const NhentaiComicPage(String id, {super.key, this.comicCover}) : _id = id;

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
        context.to(
          () => SearchResultPage(
            keyword: "\"$title\"".trim(),
            sourceKey: sourceKey,
          ),
        );
      };

  @override
  void openFavoritePanel() {
    favoriteComic(FavoriteComicWidget(
      havePlatformFavorite: NhentaiNetwork().logged,
      needLoadFolderData: false,
      favoriteOnPlatform: data!.favorite,
      initialFolder: "0",
      localFavoriteItem: toLocalFavoriteItem(),
      setFavorite: (b) {
        if (favorite != b) {
          favorite = b;
          update();
        }
      },
      folders: const {"0": "Nhentai"},
      selectFolderCallback: (folder, page) async {
        if (page == 0) {
          var res = await NhentaiNetwork().favoriteComic(id, data!.token);
          if (res.success) {
            data!.favorite = true;
          }
          return res;
        } else {
          LocalFavoritesManager().addComic(
            folder,
            FavoriteItem.fromNhentai(
              NhentaiComicBrief(
                data!.title,
                data!.cover,
                id,
                "Unknown",
                data!.tags["Tags"] ?? const <String>[],
              ),
            ),
          );
          return const Res(true);
        }
      },
      cancelPlatformFavorite: () async {
        var res = await NhentaiNetwork().unfavoriteComic(id, data!.token);
        if(res.success) {
          data!.favorite = false;
        }
        return res;
      },
    ));
  }

  @override
  ActionFunc? get openComments => () {
        showComments(context, id);
      };

  @override
  String? get cover => comicCover ?? data?.cover;

  @override
  void download() {
    final id = "nhentai${data!.id}";
    if (DownloadManager().isExists(id)) {
      showToast(message: "已下载".tl);
      return;
    }
    for (var i in DownloadManager().downloading) {
      if (i.id == id) {
        showToast(message: "下载中".tl);
        return;
      }
    }
    DownloadManager().addNhentaiDownload(data!);
    showToast(message: "已加入下载队列".tl);
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
  void read(History? history) async {
    history = await History.createIfNull(history, data!);
    App.globalTo(() => ComicReadingPage.nhentai(data!.id, data!.title));
  }

  @override
  void onThumbnailTapped(int index) async {
    await History.findOrCreate(data!);
    App.globalTo(
      () => ComicReadingPage.nhentai(
        data!.id,
        data!.title,
        initialPage: index + 1,
      ),
    );
  }

  @override
  Future<bool> loadFavorite(NhentaiComic data) async {
    return data.favorite ||
        (await LocalFavoritesManager().findWithModel(toLocalFavoriteItem())).isNotEmpty;
  }

  @override
  Widget? recommendationBuilder(NhentaiComic data) =>
      SliverGridComics(comics: data.recommendations, sourceKey: sourceKey);

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
    if (tag.contains(" | ")) {
      tag = tag.replaceAll(' | ', '-');
    }
    if (tag.contains(" ")) {
      tag = tag.replaceAll(' ', '-');
    }
    String? categoryParam = switch (key) {
      "Parodies" => "/parody/$tag",
      "Character" => "/character/$tag",
      "Tags" => "/tag/$tag",
      "Artists" => "/artist/$tag",
      "Groups" => "/group/$tag",
      "Languages" => "/language/$tag",
      "Categories" => "/category/$tag",
      _ => null
    };

    if (categoryParam == null) {
      context.to(
        () => SearchResultPage(
          keyword: tag,
          sourceKey: sourceKey,
        ),
      );
    } else {
      context.to(
        () => CategoryComicsPage(
          category: tag,
          categoryKey: ComicSource.find(sourceKey)!.categoryData!.key,
          param: categoryParam,
        ),
      );
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
  FavoriteItem toLocalFavoriteItem() =>
      FavoriteItem.fromNhentai(NhentaiComicBrief(data!.title, data!.cover, id,
          "Unknown", data!.tags["Tags"] ?? const <String>[]));

  @override
  String get downloadedId => "nhentai${data!.id}";

  @override
  String get sourceKey => 'nhentai';
}
