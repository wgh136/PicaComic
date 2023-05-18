import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/downloading_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_comic_page.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../network/eh_network/eh_download_model.dart';
import '../network/jm_network/jm_download.dart';
import '../network/picacg_network/picacg_download_model.dart';

class DownloadPageLogic extends GetxController {
  ///是否正在加载
  bool loading = true;

  ///是否处于选择状态
  bool selecting = false;

  ///已选择的数量
  int selectedNum = 0;

  ///已选择的漫画
  var selected = <bool>[];

  ///已下载的漫画
  var comics = <DownloadedItem>[];

  void change() {
    loading = !loading;
    update();
  }

  void fresh() {
    selecting = false;
    selectedNum = 0;
    selected.clear();
    comics.clear();
    change();
  }
}

class DownloadPage extends StatelessWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadPageLogic>(
        init: DownloadPageLogic(),
        builder: (logic) {
          if (logic.loading) {
            getComics(logic).then((v) {
              for (var i = 0; i < logic.comics.length; i++) {
                logic.selected.add(false);
              }
              logic.change();
            });
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: Text("加载中"),
              ),
            );
          } else {
            return Scaffold(
              appBar: AppBar(
                leading: logic.selecting
                    ? IconButton(
                        onPressed: () {
                          logic.selecting = false;
                          logic.selectedNum = 0;
                          for (int i = 0; i < logic.selected.length; i++) {
                            logic.selected[i] = false;
                          }
                          logic.update();
                        },
                        icon: const Icon(Icons.close))
                    : IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
                backgroundColor:
                    logic.selecting ? Theme.of(context).colorScheme.secondaryContainer : null,
                title: logic.selecting ? Text("已选择${logic.selectedNum}个项目") : const Text("已下载"),
                actions: [
                  if (!logic.selecting)
                    Tooltip(
                      message: "下载管理器",
                      child: IconButton(
                        icon: const Icon(Icons.download_for_offline),
                        onPressed: () {
                          showAdaptiveWidget(context, DownloadingPage(inPopupWidget: MediaQuery.of(context).size.width>600,));
                        },
                      ),
                    )
                  else
                    Tooltip(
                      message: "更多",
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz),
                        onPressed: () {
                          showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                  MediaQuery.of(context).size.width - 60,
                                  50,
                                  MediaQuery.of(context).size.width - 60,
                                  50),
                              items: [
                                PopupMenuItem(
                                  child: const Text("全选"),
                                  onTap: () {
                                    for (int i = 0; i < logic.selected.length; i++) {
                                      logic.selected[i] = true;
                                    }
                                    logic.selectedNum = logic.comics.length;
                                    logic.update();
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Text("导出"),
                                  onTap: () {
                                    if (logic.selectedNum == 0) {
                                      showMessage(context, "请选择漫画");
                                    } else if (logic.selectedNum > 1) {
                                      showMessage(context, "一次只能导出一部漫画");
                                    } else {
                                      Future<void>.delayed(
                                        const Duration(milliseconds: 200),
                                        () => showDialog(
                                          context: context,
                                          barrierColor: Colors.black26,
                                          barrierDismissible: false,
                                          builder: (context) => const SimpleDialog(
                                            children: [
                                              SizedBox(
                                                width: 200,
                                                height: 200,
                                                child: Center(
                                                  child: SizedBox(
                                                    width: 50,
                                                    height: 75,
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        CircularProgressIndicator(),
                                                        SizedBox(
                                                          height: 9,
                                                        ),
                                                        Text("打包中")
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                      Future<void>.delayed(
                                          const Duration(milliseconds: 500), () => export(logic));
                                    }
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Text("查看漫画详情"),
                                  onTap: () => Future.delayed(const Duration(milliseconds: 200),
                                      () => toComicInfoPage(logic)),
                                ),
                              ]);
                        },
                      ),
                    ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                heroTag: UniqueKey(),
                onPressed: () {
                  if (!logic.selecting) {
                    logic.selecting = true;
                    logic.update();
                  } else {
                    if (logic.selectedNum == 0) return;
                    showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return AlertDialog(
                            title: const Text("删除"),
                            content: Text("要删除已选择的${logic.selectedNum}项吗? 此操作无法撤销"),
                            actions: [
                              TextButton(onPressed: () => Get.back(), child: const Text("取消")),
                              TextButton(
                                  onPressed: () async {
                                    Get.back();
                                    var comics = <String>[];
                                    for (int i = 0; i < logic.selected.length; i++) {
                                      if (logic.selected[i]) {
                                        comics.add(logic.comics[i].id);
                                      }
                                    }
                                    await downloadManager.delete(comics);
                                    logic.fresh();
                                  },
                                  child: const Text("确认")),
                            ],
                          );
                        });
                  }
                },
                child: logic.selecting
                    ? const Icon(Icons.delete_forever_outlined)
                    : const Icon(Icons.checklist_outlined),
              ),
              body: CustomScrollView(
                slivers: [
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(childCount: logic.comics.length,
                        (context, index) {
                      return buildItem(context, logic, index);
                    }),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: comicTileMaxWidth,
                      childAspectRatio: comicTileAspectRatio,
                    ),
                  )
                ],
              ),
            );
          }
        });
  }

  Future<void> getComics(DownloadPageLogic logic) async {
    try{
      for (var comic in (downloadManager.downloaded)) {
        logic.comics.add(await downloadManager.getComicFromId(comic));
      }

      for (var gallery in (downloadManager.downloadedGalleries)) {
        logic.comics.add(await downloadManager.getGalleryFormId(gallery));
      }

      for (var comic in (downloadManager.downloadedJmComics)) {
        logic.comics.add(await downloadManager.getJmComicFormId(comic));
      }

      for(var comic in downloadManager.downloadedHitomiComics){
        logic.comics.add(await downloadManager.getHitomiComicFromId(comic));
      }
    }
    catch(e){
      logic.comics.clear();
      await getComics(logic);
    }
  }

  Future<void> export(DownloadPageLogic logic) async {
    for (int i = 0; i < logic.selected.length; i++) {
      if (logic.selected[i]) {
        exportComic(logic.comics[i].id);
      }
    }
  }

  Widget buildItem(BuildContext context, DownloadPageLogic logic, int index) {
    bool selected = logic.selected[index];
    return GestureDetector(
        onSecondaryTapUp: (details) {
          showMenu(
              context: context,
              position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy,
                  details.globalPosition.dx, details.globalPosition.dy),
              items: [
                PopupMenuItem(
                  onTap: () {
                    downloadManager.delete([logic.comics[index].id]);
                    logic.comics.removeAt(index);
                    logic.selected.removeAt(index);
                    logic.update();
                  },
                  child: const Text("删除"),
                ),
                PopupMenuItem(
                  child: const Text("导出"),
                  onTap: () {
                    Future<void>.delayed(
                      const Duration(milliseconds: 200),
                      () => showDialog(
                        context: context,
                        barrierDismissible: false,
                        barrierColor: Colors.black26,
                        builder: (context) => const SimpleDialog(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: SizedBox(
                                  width: 50,
                                  height: 80,
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 10,
                                      ),
                                      CircularProgressIndicator(),
                                      SizedBox(
                                        height: 9,
                                      ),
                                      Text("打包中")
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                    Future<void>.delayed(const Duration(milliseconds: 500), () {
                      exportComic(logic.comics[index].id);
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Text("查看漫画详情"),
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 300), () {
                      switch (logic.comics[index].type.index) {
                        case 0:
                          Get.to(() => ComicPage(
                              (logic.comics[index] as DownloadedComic).comicItem.toBrief()));
                          break;
                        case 1:
                          Get.to(() => EhGalleryPage(
                              (logic.comics[index] as DownloadedGallery).gallery.toBrief()));
                          break;
                        case 2:
                          Get.to(() =>
                              JmComicPage((logic.comics[index] as DownloadedJmComic).comic.id));
                          break;
                        case 3:
                          Get.to(() => HitomiComicPage((logic.comics[index] as DownloadedHitomiComic).toBrief()));
                          break;
                      }
                    });
                  },
                ),
              ]);
        },
        child: Container(
          decoration: BoxDecoration(
              color: selected ? const Color.fromARGB(100, 121, 125, 127) : Colors.transparent),
          child: ComicTile(
            ComicItemBrief(logic.comics[index].name, logic.comics[index].subTitle, 0, "",
                logic.comics[index].id),
            downloaded: true,
            onTap: () async {
              if (logic.selecting) {
                logic.selected[index] = !logic.selected[index];
                logic.selected[index] ? logic.selectedNum++ : logic.selectedNum--;
                if (logic.selectedNum == 0) {
                  logic.selecting = false;
                }
                logic.update();
              } else {
                showInfo(index, logic, context);
              }
            },
            size: () {
              if (logic.comics[index].comicSize != null) {
                return logic.comics[index].comicSize!.toStringAsFixed(2);
              } else {
                return "未知大小";
              }
            }.call(),
            onLongTap: () {
              if (logic.selecting) return;
              logic.selected[index] = true;
              logic.selectedNum++;
              logic.selecting = true;
              logic.update();
            },
          ),
        ));
  }

  void toComicInfoPage(DownloadPageLogic logic) {
    if (logic.selectedNum != 1) {
      showMessage(Get.context, "请选择一个漫画");
    } else {
      for (int i = 0; i < logic.selected.length; i++) {
        if (logic.selected[i]) {
          switch (logic.comics[i].type.index) {
            case 0:
              Get.to(() => ComicPage((logic.comics[i] as DownloadedComic).comicItem.toBrief()));
              break;
            case 1:
              Get.to(() => EhGalleryPage((logic.comics[i] as DownloadedGallery).gallery.toBrief()));
              break;
            case 2:
              Get.to(() => JmComicPage(logic.comics[i].id.substring(2)));
              break;
            case 3:
              Get.to(() => HitomiComicPage((logic.comics[i] as DownloadedHitomiComic).toBrief()));
              break;
          }
        }
      }
    }
  }

  void showInfo(int index, DownloadPageLogic logic, BuildContext context) {
    if (UiMode.m1(context)) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return DownloadedComicInfoView(logic.comics[index], logic);
          });
    } else {
      showSideBar(context, DownloadedComicInfoView(logic.comics[index], logic),
          useSurfaceTintColor: true);
    }
  }
}

class DownloadedComicInfoView extends StatefulWidget {
  const DownloadedComicInfoView(this.item, this.logic, {Key? key}) : super(key: key);
  final DownloadedItem item;
  final DownloadPageLogic logic;

  @override
  State<DownloadedComicInfoView> createState() => _DownloadedComicInfoViewState();
}

class _DownloadedComicInfoViewState extends State<DownloadedComicInfoView> {
  String name = "";
  List<String> eps = [];
  List<int> downloadedEps = [];
  late final comic = widget.item;

  @override
  Widget build(BuildContext context) {
    getInfo();
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
            child: Text(
              name,
              style: const TextStyle(fontSize: 22),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 250,
                childAspectRatio: 4,
              ),
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: AnimatedContainer(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        color: downloadedEps.contains(i)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      duration: const Duration(milliseconds: 200),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                          ),
                          Expanded(
                            child: Text(
                              eps[i],
                            ),
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          if (downloadedEps.contains(i)) const Icon(Icons.download_done),
                          const SizedBox(
                            width: 16,
                          ),
                        ],
                      ),
                    ),
                    onTap: () => readSpecifiedEps(i),
                  ),
                );
              },
              itemCount: eps.length,
            ),
          ),
          SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton(
                        onPressed: () {
                          if (widget.item is DownloadedComic) {
                            Get.to(() =>
                                ComicPage((widget.item as DownloadedComic).comicItem.toBrief()));
                          } else if (widget.item is DownloadedJmComic) {
                            Get.to(() => EhGalleryPage(
                                (widget.item as DownloadedGallery).gallery.toBrief()));
                          } else if (widget.item is DownloadedJmComic) {
                            Get.to(() => JmComicPage((widget.item as DownloadedJmComic).comic.id));
                          } else if (widget.item is DownloadedHitomiComic) {
                            Get.to(() => HitomiComicPage((widget.item as DownloadedHitomiComic).toBrief()));
                          }
                        },
                        child: const Text("查看详情")),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: FilledButton(onPressed: () => read(), child: const Text("阅读")),
                  ),
                ],
              )),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          )
        ],
      ),
    );
  }

  void getInfo() {
    name = comic.name;
    eps = comic.eps;
    downloadedEps = comic.downloadedEps;
  }

  void read() {
    if (comic.type == DownloadType.picacg) {
      readPicacgComic((comic as DownloadedComic).comicItem, ["", ...comic.eps]);
    } else if (comic.type == DownloadType.ehentai) {
      readEhGallery((comic as DownloadedGallery).gallery);
    } else if (comic.type == DownloadType.jm) {
      readJmComic((comic as DownloadedJmComic).comic,
          (comic as DownloadedJmComic).comic.series.values.toList());
    } else if (comic.type == DownloadType.hitomi) {
      readHitomiComic((comic as DownloadedHitomiComic).comic, (comic as DownloadedHitomiComic).cover);
    }
  }

  void readSpecifiedEps(int i) {
    if (comic.type == DownloadType.picacg) {
      addPicacgHistory((comic as DownloadedComic).comicItem);
      Get.to(() => ComicReadingPage.picacg((comic as DownloadedComic).comicItem.id, i + 1,
          (comic as DownloadedComic).chapters, (comic as DownloadedComic).comicItem.title));
    } else if (comic.type == DownloadType.jm) {
      addJmHistory((comic as DownloadedJmComic).comic);
      Get.to(() => ComicReadingPage.jmComic(
          (comic as DownloadedJmComic).comic.id,
          (comic as DownloadedJmComic).comic.name,
          (comic as DownloadedJmComic).comic.series.values.toList(),
          i + 1));
    } else if (comic.type == DownloadType.ehentai) {
      readEhGallery((comic as DownloadedGallery).gallery);
    } else if (comic.type == DownloadType.hitomi) {
      readHitomiComic((comic as DownloadedHitomiComic).comic, (comic as DownloadedHitomiComic).cover);
    }
  }
}
