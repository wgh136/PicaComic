import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/network/htmanga_network/ht_download_model.dart';
import 'package:pica_comic/network/nhentai_network/download.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/views/downloading_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_comic_page.dart';
import 'package:pica_comic/views/ht_views/ht_comic_page.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/select.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/stateful_switch.dart';
import '../network/eh_network/eh_download_model.dart';
import '../network/jm_network/jm_download.dart';
import '../network/picacg_network/picacg_download_model.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'dart:io';
import 'package:pica_comic/tools/translations.dart';
import 'main_page.dart';


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
    try {
      update();
    } catch (e) {
      //忽视
    }
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
              body: Center(
                child: Text("加载中".tl),
              ),
            );
          } else {
            return Scaffold(
              floatingActionButton: buildFAB(context, logic),
              body: CustomScrollView(
                slivers: [
                  buildAppbar(context, logic),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        childCount: logic.comics.length, (context, index) {
                      return buildItem(context, logic, index);
                    }),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
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
    try {
      for (var comic in (downloadManager.downloaded)) {
        logic.comics.add(await downloadManager.getComicFromId(comic));
      }

      for (var gallery in (downloadManager.downloadedGalleries)) {
        logic.comics.add(await downloadManager.getGalleryFormId(gallery));
      }

      for (var comic in (downloadManager.downloadedJmComics)) {
        logic.comics.add(await downloadManager.getJmComicFormId(comic));
      }

      for (var comic in downloadManager.downloadedHitomiComics) {
        logic.comics.add(await downloadManager.getHitomiComicFromId(comic));
      }

      for (var comic in downloadManager.downloadedHtComics) {
        logic.comics.add(await downloadManager.getHtComicFromId(comic));
      }

      for(var comic in downloadManager.downloadedNhentaiComics){
        logic.comics.add(await downloadManager.getNhentaiComic(comic));
      }
    } catch (e) {
      logic.comics.clear();
      await getComics(logic);
    }
    logic.comics.sort((a, b) {
      int res;
      switch (appdata.settings[26][0]) {
        case "0":
          res = (a.time ?? DateTime.now()).compareTo(b.time ?? DateTime.now());
        case "1":
          res = a.name.compareTo(b.name);
        case "2":
          res = a.subTitle.compareTo(b.subTitle);
        case "3":
          res = (a.comicSize ?? 0).compareTo(b.comicSize ?? 0);
        default:
          throw UnimplementedError();
      }
      if(appdata.settings[26][1] == "1"){
        res = 0 - res;
      }
      return res;
    });
  }

  Future<void> export(DownloadPageLogic logic) async {
    for (int i = 0; i < logic.selected.length; i++) {
      if (logic.selected[i]) {
        var res = await exportComic(logic.comics[i].id, logic.comics[i].name);
        Get.back();
        if (res) {
          //忽视
        } else {
          showMessage(Get.context, "导出失败");
        }
      }
    }
  }

  Widget buildItem(BuildContext context, DownloadPageLogic logic, int index) {
    bool selected = logic.selected[index];
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surfaceVariant
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(16))),
        child: DownloadedComicTile(
          name: logic.comics[index].name,
          author: logic.comics[index].subTitle,
          imagePath: downloadManager.getCover(logic.comics[index].id),
          type: logic.comics[index].type.name,
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
              return "未知大小".tl;
            }
          }.call(),
          onLongTap: () {
            if (logic.selecting) return;
            logic.selected[index] = true;
            logic.selectedNum++;
            logic.selecting = true;
            logic.update();
          },
          onSecondaryTap: (details) {
            showMenu(
                context: Get.context!,
                position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy),
                items: [
                  PopupMenuItem(
                    onTap: () {
                      downloadManager.delete([logic.comics[index].id]);
                      logic.comics.removeAt(index);
                      logic.selected.removeAt(index);
                      logic.update();
                    },
                    child: Text("删除".tl),
                  ),
                  PopupMenuItem(
                    child: Text("导出".tl),
                    onTap: () {
                      Future<void>.delayed(
                        const Duration(milliseconds: 200),
                        () => showDialog(
                          context: context,
                          barrierDismissible: false,
                          barrierColor: Colors.black26,
                          builder: (context) => SimpleDialog(
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
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        const CircularProgressIndicator(),
                                        const SizedBox(
                                          height: 9,
                                        ),
                                        Text("打包中".tl)
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                      Future<void>.delayed(const Duration(milliseconds: 500),
                          () async {
                        var res = await exportComic(
                            logic.comics[index].id, logic.comics[index].name);
                        Get.back();
                        if (res) {
                          //忽视
                        } else {
                          showMessage(Get.context, "导出失败");
                        }
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Text("查看漫画详情".tl),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 300), () {
                        toComicInfoPage(logic.comics[index]);
                      });
                    },
                  ),
                ]);
          },
        ),
      ),
    );
  }

  void toComicInfoPage(DownloadedItem comic){
    switch (comic.type.index) {
      case 0:
        MainPage.to(() => PicacgComicPage(
            (comic as DownloadedComic)
                .comicItem
                .toBrief()));
        break;
      case 1:
        MainPage.to(() => EhGalleryPage(
            (comic as DownloadedGallery)
                .gallery
                .toBrief()));
        break;
      case 2:
        MainPage.to(() => JmComicPage(
            (comic as DownloadedJmComic)
                .comic
                .id));
        break;
      case 3:
        MainPage.to(() => HitomiComicPage(
            (comic as DownloadedHitomiComic)
                .toBrief()));
        break;
      case 4:
        MainPage.to(() => HtComicPage(
            (comic as DownloadedHtComic)
                .comic.toBrief()));
      case 5:
        MainPage.to(() => NhentaiComicPage(
            (comic as NhentaiDownloadedComic)
                .id.replaceFirst("nhentai", "")));
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
      showSideBar(Get.context!, DownloadedComicInfoView(logic.comics[index], logic),
          useSurfaceTintColor: true);
    }
  }

  Widget buildFAB(BuildContext context, DownloadPageLogic logic)
    => FloatingActionButton(
    enableFeedback: true,
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
                title: Text("删除".tl),
                content: Text("要删除已选择的项目吗? 此操作无法撤销".tl),
                actions: [
                  TextButton(
                      onPressed: () => Get.back(),
                      child: const Text("取消")),
                  TextButton(
                      onPressed: () async {
                        Get.back();
                        var comics = <String>[];
                        for (int i = 0;
                        i < logic.selected.length;
                        i++) {
                          if (logic.selected[i]) {
                            comics.add(logic.comics[i].id);
                          }
                        }
                        await downloadManager.delete(comics);
                        logic.fresh();
                      },
                      child: Text("确认".tl)),
                ],
              );
            });
      }
    },
    child: logic.selecting
        ? const Icon(Icons.delete_forever_outlined)
        : const Icon(Icons.checklist_outlined),
  );

  Widget buildAppbar(BuildContext context, DownloadPageLogic logic)
    => CustomSmallSliverAppbar(
      leading: logic.selecting
          ? IconButton(
              onPressed: () {
                logic.selecting = false;
                logic.selectedNum = 0;
                for (int i = 0;
                i < logic.selected.length;
                i++) {
                  logic.selected[i] = false;
                }
                logic.update();
              },
              icon: const Icon(Icons.close))
          : IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
      backgroundColor: logic.selecting
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      title: logic.selecting
          ? Text("已选择 @num 个项目"
          .tlParams({"num": logic.selectedNum.toString()}))
          : Text("已下载".tl),
      actions: [
        if (!logic.selecting)
          Tooltip(
            message: "排序".tl,
            child: IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () async{
                bool changed = false;
                await showDialog(context: context, builder: (context) => SimpleDialog(
                  title: Text("漫画排序模式".tl),
                  children: [
                    SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          ListTile(
                            title: Text("漫画排序模式".tl),
                            trailing: Select(
                              initialValue: int.parse(appdata.settings[26][0]),
                              whenChange: (i){
                                appdata.settings[26] = appdata.settings[26].setValueAt(i.toString(), 0);
                                appdata.updateSettings();
                                changed = true;
                              },
                              values: const ["时间", "漫画名", "作者名", "大小"],
                              inPopUpWidget: false,
                            ),
                          ),
                          ListTile(
                            title: Text("倒序".tl),
                            trailing: StatefulSwitch(
                              initialValue: appdata.settings[26][1] == "1",
                              onChanged: (b){
                                if(b){
                                  appdata.settings[26] = appdata.settings[26].setValueAt("1", 1);
                                }else{
                                  appdata.settings[26] = appdata.settings[26].setValueAt("0", 1);
                                }
                                appdata.updateSettings();
                                changed = true;
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ));
                if(changed){
                  logic.fresh();
                }
              },
            ),
          ),
        if (!logic.selecting)
          Tooltip(
            message: "下载管理器".tl,
            child: IconButton(
              icon: const Icon(Icons.download_for_offline),
              onPressed: () {
                showAdaptiveWidget(
                    Get.context!,
                    DownloadingPage(
                      inPopupWidget:
                      MediaQuery.of(Get.context!).size.width >
                          600,
                    ));
              },
            ),
          )
        else
          Tooltip(
            message: "更多".tl,
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
                        child: Text("全选".tl),
                        onTap: () {
                          for (int i = 0;
                          i < logic.selected.length;
                          i++) {
                            logic.selected[i] = true;
                          }
                          logic.selectedNum =
                              logic.comics.length;
                          logic.update();
                        },
                      ),
                      PopupMenuItem(
                        child: Text("导出".tl),
                        onTap: () {
                          if (logic.selectedNum == 0) {
                            showMessage(context, "请选择漫画".tl);
                          } else if (logic.selectedNum > 1) {
                            showMessage(
                                context, "一次只能导出一部漫画".tl);
                          } else {
                            Future<void>.delayed(
                              const Duration(milliseconds: 200),
                                  () => showDialog(
                                context: context,
                                barrierColor: Colors.black26,
                                barrierDismissible: false,
                                builder: (context) =>
                                const SimpleDialog(
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
                                const Duration(
                                    milliseconds: 500),
                                    () => export(logic));
                          }
                        },
                      ),
                      PopupMenuItem(
                        child: Text("查看漫画详情".tl),
                        onTap: () => Future.delayed(
                            const Duration(milliseconds: 200),
                                () {
                              if (logic.selectedNum != 1) {
                                showMessage(Get.context, "请选择一个漫画".tl);
                              } else {
                                for (int i = 0; i < logic.selected.length; i++) {
                                  if (logic.selected[i]) {
                                    toComicInfoPage(logic.comics[i]);
                                  }
                                }
                              }
                            }),
                      ),
                    ]);
              },
            ),
          ),
      ],
    );
}

class DownloadedComicInfoView extends StatefulWidget {
  const DownloadedComicInfoView(this.item, this.logic, {Key? key})
      : super(key: key);
  final DownloadedItem item;
  final DownloadPageLogic logic;

  @override
  State<DownloadedComicInfoView> createState() =>
      _DownloadedComicInfoViewState();
}

class _DownloadedComicInfoViewState extends State<DownloadedComicInfoView> {
  String name = "";
  List<String> eps = [];
  List<int> downloadedEps = [];
  late final comic = widget.item;

  deleteEpisode(int i){
    showConfirmDialog(context, "确认删除", "要删除这个章节吗", () async{
      var message = await DownloadManager().deleteEpisode(comic, i);
      if(message == null) {
        setState(() {});
      }else{
        showMessage(Get.context, message);
      }
    });
  }

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
                maxCrossAxisExtent: 300,
                childAspectRatio: 4,
              ),
              itemBuilder: (BuildContext context, int i) {
                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        color: downloadedEps.contains(i)
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceVariant,
                      ),
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
                          if (downloadedEps.contains(i))
                            const Icon(Icons.download_done),
                          const SizedBox(
                            width: 16,
                          ),
                        ],
                      ),
                    ),
                    onTap: () => readSpecifiedEps(i),
                    onLongPress: (){
                      deleteEpisode(i);
                    },
                    onSecondaryTapDown: (details){
                      deleteEpisode(i);
                    },
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
                          Get.back();
                          if (widget.item is DownloadedComic) {
                            MainPage.to(() => PicacgComicPage(
                                (widget.item as DownloadedComic)
                                    .comicItem
                                    .toBrief()));
                          } else if (widget.item is DownloadedGallery) {
                            MainPage.to(() => EhGalleryPage(
                                (widget.item as DownloadedGallery)
                                    .gallery
                                    .toBrief()));
                          } else if (widget.item is DownloadedJmComic) {
                            MainPage.to(() => JmComicPage(
                                (widget.item as DownloadedJmComic).comic.id));
                          } else if (widget.item is DownloadedHitomiComic) {
                            MainPage.to(() => HitomiComicPage(
                                (widget.item as DownloadedHitomiComic)
                                    .toBrief()));
                          } else if (widget.item is DownloadedHtComic) {
                            MainPage.to(() => HtComicPage(
                                (widget.item as DownloadedHtComic)
                                    .comic
                                    .toBrief()));
                          } else if(widget.item is NhentaiDownloadedComic){
                            MainPage.to(() => NhentaiComicPage(
                                (widget.item as NhentaiDownloadedComic)
                                    .id.replaceFirst("nhentai", "")));
                          }
                        },
                        child: Text("查看详情".tl)),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: FilledButton(
                        onPressed: () => read(), child: Text("阅读".tl)),
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
      readPicacgComic((comic as DownloadedComic).comicItem, [...comic.eps]);
    } else if (comic.type == DownloadType.ehentai) {
      readEhGallery((comic as DownloadedGallery).gallery);
    } else if (comic.type == DownloadType.jm) {
      readJmComic((comic as DownloadedJmComic).comic,
          (comic as DownloadedJmComic).comic.series.values.toList());
    } else if (comic.type == DownloadType.hitomi) {
      readHitomiComic((comic as DownloadedHitomiComic).comic,
          (comic as DownloadedHitomiComic).cover);
    } else if (comic.type == DownloadType.htmanga) {
      readHtmangaComic((comic as DownloadedHtComic).comic);
    } else if (comic.type == DownloadType.nhentai){
      readNhentai(NhentaiComic(comic.id.replaceFirst("nhentai", ""), comic.name, comic.subTitle,
          (comic as NhentaiDownloadedComic).cover, {}, false, [], [], ""));
    }
  }

  void readSpecifiedEps(int i) {
    if (comic.type == DownloadType.picacg) {
      addPicacgHistory((comic as DownloadedComic).comicItem);
      Get.to(() => ComicReadingPage.picacg(
          (comic as DownloadedComic).comicItem.id,
          i + 1,
          (comic as DownloadedComic).eps,
          (comic as DownloadedComic).comicItem.title));
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
      readHitomiComic((comic as DownloadedHitomiComic).comic,
          (comic as DownloadedHitomiComic).cover);
    } else if (comic.type == DownloadType.htmanga) {
      readHtmangaComic((comic as DownloadedHtComic).comic);
    } else if (comic.type == DownloadType.nhentai){
      readNhentai(NhentaiComic(comic.id.replaceFirst("nhentai", ""), comic.name, comic.subTitle,
          (comic as NhentaiDownloadedComic).cover, {}, false, [], [], ""));
    }
  }
}

class DownloadedComicTile extends ComicTile {
  final String size;
  final File imagePath;
  final String author;
  final String name;
  final String type;
  final void Function() onTap;
  final void Function() onLongTap;
  final void Function(TapDownDetails details) onSecondaryTap;

  @override
  String get description => "${size}MB";

  @override
  Widget get image => Image.file(
        imagePath,
        fit: BoxFit.cover,
        height: double.infinity,
      );

  @override
  void onTap_() => onTap();

  @override
  String get subTitle => author;

  @override
  String get title => name;

  @override
  void onLongTap_() => onLongTap();

  @override
  void onSecondaryTap_(details) => onSecondaryTap(details);

  @override
  String? get badge => type;

  const DownloadedComicTile(
      {required this.size,
      required this.imagePath,
      required this.author,
      required this.name,
      required this.onTap,
      required this.onLongTap,
      required this.onSecondaryTap,
      required this.type,
      super.key});
}
