import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/eh_views/eh_comments_page.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/stars.dart';
import '../../network/eh_network/get_gallery_id.dart';
import '../models/local_favorites.dart';
import '../page_template/comic_page.dart';
import '../reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class EhGalleryPage extends ComicPage<Gallery> {
  const EhGalleryPage(this.brief, {super.key});
  final EhGalleryBrief brief;

  @override
  Row get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: Text("评分".tr),
              avatar: const Icon(Icons.star),
              onPressed: () => starRating(context, data!.auth!),
            ),
          ),
          Expanded(
            child: ActionChip(
                label: Text("收藏".tr),
                avatar: data!.favorite
                    ? const Icon(Icons.bookmark)
                    : const Icon(Icons.bookmark_outline),
                onPressed: () {
                  if (!data!.favorite) {
                    showDialog(
                        context: context,
                        builder: (context) => FavoriteComicDialog(data!));
                  } else {
                    showMessage(context, "正在取消收藏".tr);
                    EhNetwork()
                        .unfavorite(data!.auth!["gid"]!, data!.auth!["token"]!)
                        .then((b) {
                      if (b) {
                        showMessage(Get.context, "取消收藏成功".tr);
                        data!.favorite = false;
                        update();
                      } else {
                        showMessage(Get.context, "取消收藏失败".tr);
                      }
                    });
                  }
                }),
          ),
          Expanded(
            child: ActionChip(
              label: Text("本地".tr),
              avatar: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => LocalFavoriteComicDialog(brief)),
            ),
          ),
          Expanded(
            child: ActionChip(
                label: const Text("评论"),
                avatar: const Icon(Icons.comment_outlined),
                onPressed: () =>
                    showComments(context, brief.link, data!.uploader)),
          ),
        ],
      );

  @override
  String get cover => brief.coverPath;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () {
          final id = getGalleryId(data!.link);
          if (downloadManager.downloadedGalleries.contains(id)) {
            showMessage(context, "已下载".tr);
            return;
          }
          for (var i in downloadManager.downloading) {
            if (i.id == id) {
              showMessage(context, "下载中".tr);
              return;
            }
          }
          downloadManager.addEhDownload(data!);
          showMessage(context, "已加入下载队列".tr);
        },
        child: (downloadManager.downloadedGalleries
                .contains(getGalleryId(data!.link)))
            ? const Text("已下载")
            : const Text("下载"),
      );

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  Future<Res<Gallery>> loadData() => EhNetwork().getGalleryInfo(brief);

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readEhGallery(data!),
        child: Text("阅读".tr),
      );

  @override
  SliverGrid? recommendationBuilder(Gallery data) => null;

  @override
  String get tag => "Eh ComicPage ${brief.link}";

  @override
  Map<String, List<String>>? get tags => {
        "类型".tr: data!.type.toList(),
        "时间".tr: data!.time.toList(),
        ...data!.tags
      };

  @override
  bool get enableTranslationToCN =>
      PlatformDispatcher.instance.locale.languageCode == "zh";

  @override
  void tapOnTags(String tag) =>
      Get.to(() => EhSearchPage(tag), preventDuplicates: false);

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData(
      data!.thumbnailUrls,
      (page) => EhNetwork().getThumbnailUrls(brief.link, page),
      int.parse(data!.maxPage));

  @override
  String? get title => brief.title;

  @override
  Card? get uploaderInfo => null;

  void starRating(BuildContext context, Map<String, String> auth) {
    if (appdata.ehId == "") {
      showMessage(context, "未登录".tr);
      return;
    }
    showDialog(
        context: context,
        builder: (dialogContext) => GetBuilder<RatingLogic>(
            init: RatingLogic(),
            builder: (logic) => SimpleDialog(
                  title: const Text("评分"),
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: SizedBox(
                          width: 210,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              RatingWidget(
                                padding: 2,
                                onRatingUpdate: (value) => logic.rating = value,
                                value: 0,
                                selectAble: true,
                                size: 40,
                              ),
                              const Spacer(),
                              if (!logic.running)
                                FilledButton(
                                    onPressed: () {
                                      logic.running = true;
                                      logic.update();
                                      EhNetwork()
                                          .rateGallery(
                                              auth, logic.rating.toInt())
                                          .then((b) {
                                        if (b) {
                                          Get.back();
                                          showMessage(context, "评分成功".tr);
                                        } else {
                                          logic.running = false;
                                          logic.update();
                                          showMessage(dialogContext, "网络错误");
                                        }
                                      });
                                    },
                                    child: Text("提交".tr))
                              else
                                const CircularProgressIndicator()
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )));
  }

  @override
  Widget get buildMoreInfo => SizedBox(
        height: 30,
        child: Row(
          children: [
            for (int i = 0; i < (data!.stars ~/ 0.5) ~/ 2; i++)
              Icon(
                Icons.star,
                size: 30,
                color: Theme.of(context).colorScheme.secondary,
              ),
            if ((data!.stars ~/ 0.5) % 2 == 1)
              Icon(
                Icons.star_half,
                size: 30,
                color: Theme.of(context).colorScheme.secondary,
              ),
            for (int i = 0;
                i < (5 - (data!.stars ~/ 0.5) ~/ 2 - (data!.stars ~/ 0.5) % 2);
                i++)
              const Icon(
                Icons.star_border,
                size: 30,
              ),
            const SizedBox(
              width: 5,
            ),
            if (data!.rating != null) Text(data!.rating!)
          ],
        ),
      );
}

class RatingLogic extends GetxController {
  double rating = 0;
  bool running = false;
}

class CommentLogic extends GetxController {
  final controller = TextEditingController();
  bool sending = false;
}

class FavoriteComicDialog extends StatefulWidget {
  const FavoriteComicDialog(this.comic, {Key? key}) : super(key: key);
  final Gallery comic;

  @override
  State<FavoriteComicDialog> createState() => _FavoriteComicDialogState();
}

class _FavoriteComicDialogState extends State<FavoriteComicDialog> {
  bool loading = false;
  Map<String, String> folders = Map<String, String>.fromIterables(
      EhNetwork().folderNames,
      List<String>.generate(10, (index) => index.toString()));
  String? message;
  String folderId = "0";
  late String folderName = folders.keys.first;

  @override
  Widget build(BuildContext context) {
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
                              for (var folder in folders.entries)
                                PopupMenuItem(
                                  child: Text(folder.key),
                                  onTap: () {
                                    setState(() {
                                      folderName = folder.key;
                                    });
                                    folderId = folder.value;
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
              if (!loading)
                FilledButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });
                      var res = await EhNetwork().favorite(
                          widget.comic.auth!["gid"]!,
                          widget.comic.auth!["token"]!,
                          id: folderId);
                      if (!res) {
                        showMessage(Get.context, "网络错误");
                        setState(() {
                          loading = false;
                        });
                        return;
                      }
                      Get.back();
                      widget.comic.favorite = true;
                      Get.find<ComicPageLogic<Gallery>>(
                              tag: "Eh ComicPage ${widget.comic.link}")
                          .update();
                      showMessage(Get.context, "添加成功".tr);
                    },
                    child: Text("提交".tr))
              else
                const Center(
                  child: CircularProgressIndicator(),
                )
            ],
          ),
        )
      ],
    );
  }
}

class LocalFavoriteComicDialog extends StatefulWidget {
  const LocalFavoriteComicDialog(this.comic, {Key? key}) : super(key: key);
  final EhGalleryBrief comic;

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
                        folderName, FavoriteItem.fromEhentai(widget.comic));
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
