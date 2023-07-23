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

class HitomiComicPage extends ComicPage<HitomiComic> {
  const HitomiComicPage(this.comic, {super.key});

  final HitomiComicBrief comic;

  @override
  Row? get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: Text("本地".tr),
              avatar: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => LocalFavoriteComicDialog(comic)),
            ),
          ),
        ],
      );

  @override
  String get cover => comic.cover;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () => downloadComic(data!, context, comic.cover, comic.link),
        child: Text("下载".tr),
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
        child: Text("阅读".tr),
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
        "类型".tr: data!.type.toList(),
        "时间".tr: data!.time.toList(),
        "语言".tr: data!.lang.toList(),
        "标签".tr:
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
    showMessage(context, "已下载".tr);
    return;
  }
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tr);
      return;
    }
  }
  downloadManager.addHitomiDownload(comic, cover, link);
  showMessage(context, "已加入下载".tr);
}

class LocalFavoriteComicDialog extends StatefulWidget {
  const LocalFavoriteComicDialog(this.comic, {Key? key}) : super(key: key);
  final HitomiComicBrief comic;

  @override
  State<LocalFavoriteComicDialog> createState() =>
      _LocalFavoriteComicDialogState();
}

class _LocalFavoriteComicDialogState extends State<LocalFavoriteComicDialog> {
  String? message;
  String folderName = "";
  bool addedFavorite = false;

  @override
  Widget build(BuildContext context) {
    var folders = LocalFavoritesManager().folderNames;
    if (folders == null) {
      LocalFavoritesManager().readData().then((value) => setState(() {}));
      return const SizedBox(
        width: 300,
        height: 150,
      );
    }
    return SimpleDialog(
      title: Text("收藏漫画".tr),
      children: [
        SizedBox(
          key: const Key("2"),
          width: 300,
          height: 150,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(5),
                width: 300,
                height: 50,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.all(Radius.circular(16))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("  选择收藏夹:  ".tr),
                    Text(folderName),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_drop_down_sharp),
                      onPressed: () {
                        showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                                MediaQuery.of(context).size.width / 2 + 150,
                                MediaQuery.of(context).size.height / 2,
                                MediaQuery.of(context).size.width / 2 - 150,
                                MediaQuery.of(context).size.height / 2),
                            items: [
                              for (var folder in folders)
                                PopupMenuItem(
                                  child: Text(folder),
                                  onTap: () {
                                    setState(() {
                                      folderName = folder;
                                    });
                                  },
                                )
                            ]);
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              FilledButton(
                  onPressed: () async {
                    if (folderName == "") {
                      showMessage(Get.context, "请选择收藏夹");
                      return;
                    }
                    LocalFavoritesManager().addComic(
                        folderName, FavoriteItem.fromHitomi(widget.comic));
                    Get.back();
                  },
                  child: Text("提交".tr))
            ],
          ),
        )
      ],
    );
  }
}
