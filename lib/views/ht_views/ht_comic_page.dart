import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../base.dart';
import '../../foundation/history.dart';
import '../main_page.dart';
import '../../foundation/local_favorites.dart';
import '../page_template/comic_page.dart';
import '../widgets/avatar.dart';
import '../widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class HtComicPage extends ComicPage<HtComicInfo> {
  const HtComicPage(this.comic, {super.key});

  final HtComicBrief comic;

  Widget get buildButtons => SegmentedButton<int>(
        segments: [
          ButtonSegment(
            icon: Icon(
              Icons.bookmark_add_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text("收藏".tl),
            value: 1,
          ),
          ButtonSegment(
            icon: Icon(
              Icons.pages,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: Text("页数: ${data!.pages}"),
            value: 2,
          ),
        ],
        onSelectionChanged: (set) {
          void func1() {
            favoriteComic(FavoriteComicWidget(
              havePlatformFavorite: appdata.htName != "",
              needLoadFolderData: true,
              foldersLoader: () => HtmangaNetwork().getFolders(),
              target: comic.id,
              setFavorite: (b) {},
              selectFolderCallback: (folder, page) async {
                if (page == 0) {
                  showMessage(context, "正在添加收藏".tl);
                  var res =
                      await HtmangaNetwork().addFavorite(comic.id, folder);
                  if (res.error) {
                    showMessage(App.globalContext, res.errorMessageWithoutNull);
                  } else {
                    showMessage(App.globalContext, "成功添加收藏".tl);
                  }
                } else {
                  LocalFavoritesManager()
                      .addComic(folder, FavoriteItem.fromHtcomic(comic));
                  showMessage(App.globalContext, "成功添加收藏".tl);
                }
              },
            ));
          }

          switch (set.first) {
            case 1:
              func1();
              break;
          }
        },
        selected: const {},
        emptySelectionAllowed: true,
      );

  @override
  Row? get actions => Row(
        children: [
          const SizedBox(
            width: 16,
          ),
          Expanded(
            child: buildButtons,
          ),
          const SizedBox(
            width: 16,
          ),
        ],
      );

  @override
  String get cover => comic.image;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () {
          final id = "Ht${data!.id}";
          if (DownloadManager().downloadedHtComics.contains(id)) {
            showMessage(context, "已下载".tl);
            return;
          }
          for (var i in DownloadManager().downloading) {
            if (i.id == id) {
              showMessage(context, "下载中".tl);
              return;
            }
          }
          DownloadManager().addHtDownload(data!);
          showMessage(context, "已加入下载队列".tl);
        },
        child: DownloadManager().downloadedHtComics.contains("Ht${data!.id}")
            ? Text("已下载".tl)
            : Text("下载".tl),
      );

  @override
  void onThumbnailTapped(int index) {
    readHtmangaComic(data!, index + 1);
  }

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => data!.description;

  @override
  Future<Res<HtComicInfo>> loadData() =>
      HtmangaNetwork().getComicInfo(comic.id);

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readHtmangaComic(data!, 1),
        child: Text("从头开始".tl),
      );

  @override
  void continueRead(History history) {
    readHtmangaComic(data!, history.page);
  }

  @override
  SliverGrid? recommendationBuilder(HtComicInfo data) => null;

  @override
  String get tag => "Ht ComicPage ${comic.id}";

  @override
  Map<String, List<String>>? get tags =>
      {"分类".tl: data!.category.toList(), "标签".tl: data!.tags.keys.toList()};

  @override
  void tapOnTags(String tag) => MainPage.to(() => HtSearchPage(tag));

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData(
      data!.thumbnails,
      (page) => HtmangaNetwork().getThumbnails(data!.id, page),
      (data!.pages / 12).ceil());

  @override
  String? get title => comic.name.removeAllBlank;

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
  String get id => comic.id;

  @override
  String get source => "绅士漫画".tl;

  @override
  FavoriteItem toLocalFavoriteItem() => FavoriteItem.fromHtcomic(comic);
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
