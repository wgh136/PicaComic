import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:share_plus/share_plus.dart';
import '../../foundation/ui_mode.dart';
import '../show_image_page.dart';
import '../widgets/avatar.dart';
import '../widgets/loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/show_error.dart';
import '../widgets/show_message.dart';

class HtComicPageLogic extends GetxController {
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

class HtComicPage extends StatelessWidget {
  const HtComicPage(this.comic, {super.key});
  final HtComicBrief comic;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: GetBuilder<HtComicPageLogic>(
        init: HtComicPageLogic(),
        tag: comic.id,
        builder: (logic) {
          if (logic.loading) {
            logic.get(comic.id);
            return showLoading(context);
          } else if (logic.comic == null) {
            return showNetworkError(
                logic.message ?? "网络错误", logic.refresh_, context);
          } else {
            logic.controller = ScrollController();
            logic.controller.addListener(() {
              //检测当前滚动位置, 决定是否显示Appbar的标题
              bool temp = logic.showAppbarTitle;
              if (!logic.controller.hasClients) {
                return;
              }
              logic.showAppbarTitle = logic.controller.position.pixels >
                  boundingTextSize(
                              logic.comic!.name, const TextStyle(fontSize: 22),
                              maxWidth: width)
                          .height +
                      50;
              if (temp != logic.showAppbarTitle) {
                logic.update();
              }
            });
            return CustomScrollView(
              controller: logic.controller,
              slivers: [
                SliverAppBar(
                  surfaceTintColor:
                      logic.showAppbarTitle ? null : Colors.transparent,
                  shadowColor: Colors.transparent,
                  title: AnimatedOpacity(
                    opacity: logic.showAppbarTitle ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(logic.comic!.name),
                  ),
                  pinned: true,
                  actions: [
                    Tooltip(
                      message: "分享".tr,
                      child: IconButton(
                        icon: const Icon(
                          Icons.share,
                        ),
                        onPressed: () {
                          Share.share(logic.comic!.name);
                        },
                      ),
                    ),
                    Tooltip(
                      message: "复制".tr,
                      child: IconButton(
                        icon: const Icon(
                          Icons.copy,
                        ),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: logic.comic!.name));
                        },
                      ),
                    ),
                  ],
                ),

                //标题
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 20, 10, 15),
                    child: SizedBox(
                      width: double.infinity,
                      child: SelectableTextCN(
                        text: logic.comic!.name,
                        style: const TextStyle(fontSize: 28),
                        withAddToBlockKeywordButton: true,
                      ),
                    ),
                  ),
                ),

                buildComicInfo(logic.comic!, context),

                const SliverPadding(padding: EdgeInsets.all(5)),
                const SliverToBoxAdapter(
                  child: Divider(),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                          ),
                          Icon(Icons.insert_drive_file,
                              color: Theme.of(context).colorScheme.secondary),
                          const SizedBox(
                            width: 20,
                          ),
                          const Text(
                            "简介",
                            style: TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 16),
                          )
                        ],
                      )),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 0, 0),
                    child: SelectableTextCN(text: logic.comic!.description),
                  ),
                ),

                ...buildThumbnails(context, logic),
                const SliverPadding(padding: EdgeInsets.only(bottom: 50))
              ],
            );
          }
        },
      ),
    );
  }

  Size boundingTextSize(String text, TextStyle style,
      {int maxLines = 2 ^ 31, double maxWidth = double.infinity}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style),
        maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    return textPainter.size;
  }

  Widget buildComicInfo(HtComicInfo comic, BuildContext context) {
    if (UiMode.m1(context)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: SizedBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                //封面
                buildCover(context, 350, MediaQuery.of(context).size.width,
                    comic.coverPath),
                const SizedBox(
                  height: 20,
                ),
                ...buildInfoCards(comic, context),
              ],
            ),
          ),
        ),
      );
    } else {
      return SliverToBoxAdapter(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          child: Row(
            children: [
              //封面
              SizedBox(
                child: Column(
                  children: [
                    buildCover(context, 450,
                        MediaQuery.of(context).size.width / 2, comic.coverPath),
                  ],
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...buildInfoCards(comic, context),
                  ],
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  Widget buildCover(
      BuildContext context, double height, double width, String image) {
    return GestureDetector(
      onTap: () => Get.to(() => ShowImagePage(
            image,
          )),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
          child: CachedNetworkImage(
            width: width - 50,
            height: height,
            imageUrl: image,
            fit: BoxFit.contain,
            errorWidget: (context, url, error) => const Icon(Icons.error),
          )),
    );
  }

  List<Widget> buildInfoCards(HtComicInfo comic, BuildContext context) {
    var res = <Widget>[];
    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      child: Text("分类".tr),
    ));
    res.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
        child: Wrap(
          children: [buildInfoCard(comic.category, context)],
        )));
    res.add(const Padding(
      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
      child: Text("tags"),
    ));
    res.add(Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
        child: Wrap(
          children: List.generate(
              comic.tags.length,
              (index) =>
                  buildInfoCard(comic.tags.keys.elementAt(index), context)),
        )));
    res.add(Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 20, 5),
      child: Card(
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
                  avatarUrl: comic.avatar,
                  couldBeShown: false,
                  name: comic.uploader,
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
                        comic.uploader,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text("投稿作品${comic.uploadNum}部")
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
    List<Widget> res2 = [];
    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(0, 15, 20, 5),
      child: Row(
        children: [
          SizedBox.fromSize(
            size: const Size(10, 1),
          ),
          Expanded(
            child: ActionChip(
                label: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
                  child: Text("收藏".tr),
                ),
                avatar: const Icon(Icons.bookmark_outline),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return FavoriteComicDialog(comic.id);
                      });
                }),
          ),
          SizedBox.fromSize(
            size: const Size(10, 1),
          ),
          Expanded(
            child: ActionChip(
              label: Text("页数: ${comic.pages}"),
              avatar: const Icon(Icons.pages),
              onPressed: () {},
            ),
          )
        ],
      ),
    ));
    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () {
                final id = "Ht${comic.id}";
                if (DownloadManager().downloadedHtComics.contains(id)) {
                  showMessage(context, "已下载".tr);
                  return;
                }
                for (var i in DownloadManager().downloading) {
                  if (i.id == id) {
                    showMessage(context, "下载中".tr);
                    return;
                  }
                }
                DownloadManager().addHtDownload(comic);
                showMessage(context, "已加入下载队列".tr);
              },
              child:
                  DownloadManager().downloadedHtComics.contains("Ht${comic.id}")
                      ? Text("已下载".tr)
                      : Text("下载".tr),
            ),
          ),
          SizedBox.fromSize(
            size: const Size(10, 1),
          ),
          Expanded(
            child: FilledButton(
              onPressed: () => readHtmangaComic(comic),
              child: Text("阅读".tr),
            ),
          ),
        ],
      ),
    ));
    return !UiMode.m1(context) ? res + res2 : res2 + res;
  }

  Widget buildInfoCard(String title, BuildContext context,
      {bool allowSearch = true}) {
    return GestureDetector(
      onLongPressStart: (details) {
        showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: Text("复制".tr),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: (title)));
                  showMessage(context, "已复制".tr);
                },
              ),
            ]);
      },
      child: Card(
        margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
        elevation: 0,
        color: Theme.of(context).colorScheme.primaryContainer,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: allowSearch
              ? () =>
                  Get.to(() => HtSearchPage(title), preventDuplicates: false)
              : () {},
          onSecondaryTapUp: (details) {
            showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy),
                items: [
                  PopupMenuItem(
                    child: Text("复制".tr),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: (title)));
                      showMessage(context, "已复制");
                    },
                  ),
                ]);
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  List<Widget> buildThumbnails(BuildContext context, HtComicPageLogic logic){
    return [
      const SliverPadding(padding: EdgeInsets.all(5)),
      const SliverToBoxAdapter(
        child: Divider(),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
            width: 100,
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                ),
                Icon(Icons.remove_red_eye,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(
                  width: 20,
                ),
                const Text(
                  "预览",
                  style: TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16),
                )
              ],
            )),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                childCount: logic.images.length, (context, index) {
              if (index == logic.images.length - 1 &&
                  logic.images.length < logic.comic!.pages) {
                logic.getImages();
              }
              return Padding(
                padding: UiMode.m1(context)
                    ? const EdgeInsets.all(3)
                    : const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: logic.images[index],
                      fit: BoxFit.fill,
                      placeholder: (context, s) => ColoredBox(
                          color: Theme.of(context).colorScheme.surfaceVariant),
                      errorWidget: (context, s, d) => const Icon(Icons.error),
                    ),
                  ),
                ),
              );
            }),
            gridDelegate:
            const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.75,
            )),
      ),
      if(logic.images.length < logic.comic!.pages)
        const SliverToBoxAdapter(
          child: ListLoadingIndicator(),
        )
    ];
  }
}

class FavoriteComicDialog extends StatefulWidget {
  const FavoriteComicDialog(this.id, {Key? key}) : super(key: key);
  final String id;

  @override
  State<FavoriteComicDialog> createState() => _FavoriteComicDialogState();
}

class _FavoriteComicDialogState extends State<FavoriteComicDialog> {
  bool loading = true;
  Map<String, String> folders = {};
  String? message;
  String folderName = "选择收藏夹".tr;
  String folderId = "";
  bool loading2 = false;
  bool addedFavorite = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      get();
    }
    return SimpleDialog(
      title: Text("收藏漫画".tr),
      children: [
        if (loading)
          const SizedBox(
            key: Key("0"),
            width: 300,
            height: 150,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (message != null)
          const SizedBox(
            key: Key("1"),
            width: 300,
            height: 150,
            child: Center(
              child: Text("网络错误"),
            ),
          )
        else
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
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16))),
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
                          if (loading) {
                            showMessage(context, "加载中".tr);
                            return;
                          }
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
                                    child: Text(folder.value),
                                    onTap: () {
                                      setState(() {
                                        folderName = folder.value;
                                      });
                                      folderId = folder.key;
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
                if (!loading2)
                  FilledButton(
                      onPressed: () async {
                        if (folderId == "") {
                          return;
                        }
                        setState(() {
                          loading2 = true;
                        });
                        var res = await HtmangaNetwork()
                            .addFavorite(widget.id, folderId);
                        if (res.error) {
                          showMessage(Get.context, res.errorMessage!);
                          setState(() {
                            loading2 = false;
                          });
                        } else {
                          Get.back();
                          showMessage(Get.context, "添加成功".tr);
                        }
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

  void get() async {
    var r = await HtmangaNetwork().getFolders();
    if (r.error) {
      message = r.errorMessage;
    } else {
      folders = r.data;
    }
    try {
      setState(() {
        loading = false;
      });
    } catch (e) {
      //可能退出了弹窗后网络请求返回
    }
  }
}
