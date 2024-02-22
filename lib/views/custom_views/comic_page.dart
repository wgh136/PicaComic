import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/general_interface/search.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../../foundation/app.dart';
import '../../foundation/ui_mode.dart';
import '../../network/base_comic.dart';
import '../widgets/select_download_eps.dart';
import '../widgets/side_bar.dart';
import 'custom_comic_tile.dart';

class CustomComicPage extends ComicPage<ComicInfoData> {
  const CustomComicPage({required this.sourceKey, required this.id, super.key});

  final String sourceKey;

  @override
  final String id;

  @override
  Row? get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: !favorite ? Text("收藏".tl) : Text("已收藏".tl),
              avatar: !favorite
                  ? const Icon(Icons.bookmark_add_outlined)
                  : const Icon(Icons.bookmark_add),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: comicSource!.favoriteData != null && comicSource!.isLogin,
                needLoadFolderData: comicSource!.favoriteData?.multiFolder ?? false,
                folders: {
                  if(!(comicSource!.favoriteData?.multiFolder ?? false))
                    '0': comicSource!.name
                },
                initialFolder: (comicSource!.favoriteData?.multiFolder ?? false) ? null : '0',
                target: id,
                setFavorite: (b) {
                  if (favorite != b) {
                    favorite = b;
                    update();
                  }
                },
                selectFolderCallback: (folder, type) {
                  if(type == 1){
                    LocalFavoritesManager().addComic(
                        folder,
                        toLocalFavoriteItem());
                    showMessage(context, "成功添加收藏".tl);
                  } else {
                    showMessage(context, "正在添加收藏".tl);
                    comicSource!.favoriteData!.addOrDelFavorite!(id, folder, true).then((value) {
                      hideMessage(context);
                      if (value.error) {
                        showMessage(context, "添加收藏失败".tl);
                      } else {
                        showMessage(context, "成功添加收藏".tl);
                      }
                    });
                  }
                },
                cancelPlatformFavorite: () {
                  showMessage(context, "正在取消收藏".tl);
                  comicSource!.favoriteData!.addOrDelFavorite!(id, '0', false).then((value) {
                    hideMessage(context);
                    if (value.error) {
                      showMessage(context, "取消收藏失败".tl);
                    } else {
                      showMessage(context, "成功取消收藏".tl);
                    }
                  });
                },
              )),
            ),
          ),
        ],
      );

  @override
  void continueRead(History history) {
    readWithKey(sourceKey, id, history.ep, history.page, data!.title,
        {"eps": data!.chapters, "cover": data!.cover});
  }

  @override
  String get cover => data!.cover;

  void downloadComic() async {
    final downloadId = DownloadManager().generateId(sourceKey, id);
    final eps = data!.chapters?.values.toList();
    for (var i in DownloadManager().downloading) {
      if (i.id == downloadId) {
        showToast(message: "下载中".tl);
        return;
      }
    }
    var downloaded = <int>[];
    if (DownloadManager().downloaded.contains(downloadId)) {
      if (eps == null) {
        showToast(message: "已下载".tl);
        return;
      }
      var downloadedComic = await DownloadManager().getComicOrNull(downloadId);
      downloaded.addAll(downloadedComic!.downloadedEps);
    } else {
      if (eps == null) {
        DownloadManager().addCustomDownload(data!, [0]);
        App.globalBack();
        showToast(message: "已加入下载".tl);
        return;
      }
    }
    if (UiMode.m1(App.globalContext!)) {
      showModalBottomSheet(
          context: App.globalContext!,
          builder: (context) {
            return SelectDownloadChapter(eps, (selectedEps) {
              DownloadManager().addCustomDownload(data!, selectedEps);
              App.globalBack();
              showToast(message: "已加入下载".tl);
            }, downloaded);
          });
    } else {
      showSideBar(
          App.globalContext!,
          SelectDownloadChapter(eps, (selectedEps) {
            DownloadManager().addCustomDownload(data!, selectedEps);
            App.globalBack();
            showToast(message: "已加入下载".tl);
          }, downloaded),
          useSurfaceTintColor: true);
    }
  }

  @override
  FilledButton get downloadButton =>
      FilledButton(onPressed: downloadComic, child: Text("下载".tl));

  @override
  EpsData? get eps => data!.chapters != null
      ? EpsData(data!.chapters!.values.toList(), (ep) {
          readWithKey(sourceKey, id, ep+1, 1, data!.title,
              {"eps": data!.chapters, "cover": data!.cover});
        })
      : null;

  @override
  String? get introduction => data!.description;

  ComicSource? get comicSource => ComicSource.find(sourceKey);

  @override
  Future<Res<ComicInfoData>> loadData() {
    if (comicSource == null) throw "Comic Source Not Found";
    return comicSource!.loadComicInfo!(id);
  }

  @override
  Future<bool> loadFavorite(ComicInfoData data) async {
    return false;
  }

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
      onPressed: () {
        readWithKey(sourceKey, id, 1, 1, data!.title,
            {"eps": data!.chapters, "cover": data!.cover});
      },
      child: Text("从头开始".tl));

  @override
  SliverGrid? recommendationBuilder(ComicInfoData data) {
    if (data.suggestions == null) return null;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            CustomComicTile(data.suggestions![index] as CustomComic),
        childCount: data.suggestions!.length,
      ),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }

  @override
  String get source => comicSource!.name;

  @override
  String get tag => "$key comic page with id: $id";

  @override
  Map<String, List<String>>? get tags => data!.tags;

  @override
  void tapOnTags(String tag) {
    toSearchPage(comicSource!.key, tag);
  }

  @override
  ThumbnailsData? get thumbnailsCreator {
    if (data!.thumbnails == null && data!.thumbnailLoader == null) return null;

    return ThumbnailsData(
        data!.thumbnails ?? [],
        (page) =>
            data!.thumbnailLoader?.call(id, page) ??
            Future.value(const Res.error("")),
        data!.thumbnailMaxPage);
  }

  @override
  String? get title => data!.title;

  @override
  FavoriteItem toLocalFavoriteItem() {
    var tags = <String>[];
    data!.tags.forEach((key, value) => tags.addAll(value));
    return FavoriteItem.fromBaseComic(CustomComic(
        data!.title,
        data!.subTitle ?? "",
        data!.cover,
        id,
        tags,
        "",
        sourceKey));
  }

  @override
  Card? get uploaderInfo => null;
}
