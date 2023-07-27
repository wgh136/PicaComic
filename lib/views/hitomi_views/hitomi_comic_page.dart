import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/hitomi_views/hi_widgets.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../base.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../models/local_favorites.dart';
import 'package:pica_comic/tools/translations.dart';

class HitomiComicPage extends ComicPage<HitomiComic> {
  const HitomiComicPage(this.comic, {super.key});

  final HitomiComicBrief comic;

  @override
  Row? get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: Text("本地".tl),
              avatar: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: false,
                needLoadFolderData: false,
                selectFolderCallback: (folder, page){
                  LocalFavoritesManager().addComic(folder, FavoriteItem.fromHitomi(comic));
                  showMessage(context, "成功添加收藏".tl);
                },
              )),
            ),
          ),
        ],
      );

  @override
  String get cover => comic.cover;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () => downloadComic(data!, context, comic.cover, comic.link),
        child: Text("下载".tl),
      );

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  Future<Res<HitomiComic>> loadData() =>
      HiNetwork().getComicInfo(comic.link, comic.name);

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readHitomiComic(data!, comic.cover),
        child: Text("阅读".tl),
      );

  @override
  SliverGrid? recommendationBuilder(HitomiComic data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(childCount: data.related.length,
            (context, i) {
          return HitomiComicTileDynamicLoading(data.related[i]);
        }),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: comicTileMaxWidth,
          childAspectRatio: comicTileAspectRatio,
        ),
      );

  @override
  String get tag => "Hitomi ComicPage ${comic.link}";

  @override
  Map<String, List<String>>? get tags => {
        "类型".tl: data!.type.toList(),
        "时间".tl: data!.time.toList(),
        "语言".tl: data!.lang.toList(),
        "标签".tl:
            List.generate(data!.tags.length, (index) => data!.tags[index].name)
      };

  @override
  bool get enableTranslationToCN =>
      PlatformDispatcher.instance.locale.languageCode == "zh";

  @override
  void tapOnTags(String tag) =>
      Get.to(() => HitomiSearchPage(tag), preventDuplicates: false);

  @override
  ThumbnailsData? get thumbnailsCreator => null;

  @override
  String? get title => comic.name;

  @override
  Card? get uploaderInfo => null;
}

void downloadComic(
    HitomiComic comic, BuildContext context, String cover, String link) {
  if (downloadManager.downloaded.contains(comic.id)) {
    showMessage(context, "已下载".tl);
    return;
  }
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tl);
      return;
    }
  }
  downloadManager.addHitomiDownload(comic, cover, link);
  showMessage(context, "已加入下载".tl);
}
