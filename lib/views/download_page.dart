import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/custom_download_model.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_download_model.dart';
import 'package:pica_comic/network/download_model.dart';
import 'package:pica_comic/network/htmanga_network/ht_download_model.dart';
import 'package:pica_comic/network/nhentai_network/download.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/pdf.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/custom_views/comic_page.dart';
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
import 'package:pica_comic/views/widgets/desktop_menu.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/select.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/stateful_switch.dart';
import '../foundation/app.dart';
import '../foundation/local_favorites.dart';
import '../network/eh_network/eh_download_model.dart';
import '../network/jm_network/jm_download.dart';
import '../network/picacg_network/picacg_download_model.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'dart:io';
import 'package:pica_comic/tools/translations.dart';
import 'main_page.dart';

extension ReadComic on DownloadedItem{
  void read(){
    final comic = this;
    if (comic.type == DownloadType.picacg) {
      readPicacgComic((comic as DownloadedComic).comicItem, [...comic.eps]);
    } else if (comic.type == DownloadType.ehentai) {
      readEhGallery((comic as DownloadedGallery).gallery);
    } else if (comic.type == DownloadType.jm) {
      readJmComic((comic as DownloadedJmComic).comic,
          (comic).comic.series.values.toList());
    } else if (comic.type == DownloadType.hitomi) {
      readHitomiComic((comic as DownloadedHitomiComic).comic,
          (comic).cover, comic.link);
    } else if (comic.type == DownloadType.htmanga) {
      readHtmangaComic((comic as DownloadedHtComic).comic);
    } else if (comic.type == DownloadType.nhentai){
      readNhentai(NhentaiComic(comic.id.replaceFirst("nhentai", ""), comic.name, comic.subTitle,
          (comic as NhentaiDownloadedComic).cover, {}, false, [], [], ""));
    } else if (comic.type == DownloadType.other){
      var comic_ = (comic as CustomDownloadedItem);
      readWithKey(comic_.sourceKey, comic_.comicId, 1, 1, comic_.name, {
        "eps": comic_.chapters,
        "cover": comic_.cover
      });
    }
  }
}

class DownloadPageLogic extends StateController {
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

  var baseComics = <DownloadedItem>[];

  bool searchMode = false;

  String keyword = "";
  String keyword_ = "";

  void change() {
    loading = !loading;
    try {
      update();
    } catch (e) {
      //忽视
    }
  }

  void find(){
    if(keyword == keyword_){
      return;
    }
    keyword_ = keyword;
    comics.clear();
    if(keyword == ""){
      comics.addAll(baseComics);
    }else{
      for (var element in baseComics) {
        if(element.name.toLowerCase().contains(keyword)
            || element.subTitle.toLowerCase().contains(keyword)){
          comics.add(element);
        }
      }
    }
    resetSelected(comics.length);
  }

  void fresh() {
    searchMode = false;
    selecting = false;
    selectedNum = 0;
    selected.clear();
    comics.clear();
    change();
  }

  void resetSelected(int length){
    selected = List.generate(length, (index) => false);
    selectedNum = 0;
  }
}

class DownloadPage extends StatelessWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<DownloadPageLogic>(
        init: DownloadPageLogic(),
        builder: (logic) {
          if (logic.loading) {
            Future.wait([getComics(logic), Future.delayed(const Duration(milliseconds: 300))]).then((v) {
              logic.resetSelected(logic.comics.length);
              logic.change();
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else {
            return Scaffold(
              floatingActionButton: buildFAB(context, logic),
              body: CustomScrollView(
                slivers: [
                  buildAppbar(context, logic),
                  buildComics(context, logic)
                ],
              ),
            );
          }
        });
  }

  Widget buildComics(BuildContext context, DownloadPageLogic logic){
    logic.find();
    final comics = logic.comics;
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
          childCount: comics.length, (context, index) {
        return buildItem(context, logic, index);
      }),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }

  Future<void> getComics(DownloadPageLogic logic) async {
    for (var comic in (downloadManager.allComics)) {
      logic.comics.addIfNotNull(await downloadManager.getComicOrNull(comic));
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
    logic.baseComics = logic.comics.toList();
  }

  Future<void> export(DownloadPageLogic logic) async {
    var comics = <DownloadedItem>[];
    for (int i = 0; i < logic.selected.length; i++) {
      if (logic.selected[i]) {
        comics.add(logic.comics[i]);
      }
    }
    if(comics.isEmpty) {
      return;
    }
    bool res;
    if(comics.length > 1){
      res = await exportComics(comics);
    } else {
      res = await exportComic(comics.first.id, comics.first.name, 
        comics.first.eps);
    }
    App.globalBack();
    if (!res) {
      showToast(message: "导出失败".tl);
    }
  }
  
  void downloadFont() async{
    bool canceled = false;
    var cancelToken = CancelToken();
    var controller = showLoadingDialog(
        App.globalContext!, () {
          canceled = true;
          cancelToken.cancel();
    }, false, true, "Downloading");
    var dio = logDio();
    try {
      await dio.download(
        "https://raw.githubusercontent.com/wgh136/PicaComic/dev/fonts/NotoSansSC-Regular.ttf",
        "${App.dataPath}/font.ttf",
        cancelToken: cancelToken,
      );
    }
    catch(e){
      showToast(message: "下载失败".tl);
      controller.close();
      return;
    }
    if(!canceled) {
      controller.close();
      showToast(message: "下载完成".tl);
    }
  }

  void exportAsPdf(DownloadedItem? comic, DownloadPageLogic logic) async{
    if(comic == null){
      for (int i = 0; i < logic.selected.length; i++) {
        if (logic.selected[i]) {
          comic = logic.comics[i];
        }
      }
    }
    if(comic == null){
      showMessage(App.globalContext, "请选择一个漫画".tl);
      return;
    }
    var file = File("${App.dataPath}/font.ttf");
    if(!App.isWindows && !await file.exists()){
      showConfirmDialog(App.globalContext!, "缺少字体".tl, 
          "需要下载字体文件(10.1MB), 是否继续?", downloadFont);
    } else {
      bool canceled = false;
      var controller = showLoadingDialog(
          App.globalContext!, () => canceled = true, false);
      var fileName = "${comic.name}.pdf";
      fileName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
      await createPdfFromComicWithIsolate(
          title: comic.name,
          comicPath: "${downloadManager.path}/${comic.id}",
          savePath: "${App.cachePath}/$fileName",
          chapters: comic.eps,
          chapterIndexes: comic.downloadedEps
      );
      if(!canceled) {
        controller.close();
        await exportPdf("${App.cachePath}/$fileName");
        File("${App.cachePath}/$fileName").deleteSync();
      }
    }
  }

  Widget buildItem(BuildContext context, DownloadPageLogic logic, int index) {
    bool selected = logic.selected[index];
    var type = logic.comics[index].type.name;
    if(logic.comics[index].type == DownloadType.other){
      type = (logic.comics[index] as CustomDownloadedItem).sourceName;
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(16))),
        child: DownloadedComicTile(
          name: logic.comics[index].name,
          author: logic.comics[index].subTitle,
          imagePath: downloadManager.getCover(logic.comics[index].id),
          type: type,
          tag: logic.comics[index].tags,
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
            showDesktopMenu(App.globalContext!,
                Offset(details.globalPosition.dx, details.globalPosition.dy), [
                  DesktopMenuEntry(
                    text: "删除".tl,
                    onClick: () {
                      showConfirmDialog(context, "确认删除".tl, "此操作无法撤销, 是否继续?".tl, () {
                        downloadManager.delete([logic.comics[index].id]);
                        logic.comics.removeAt(index);
                        logic.selected.removeAt(index);
                        logic.update();
                      });
                    },
                  ),
                  DesktopMenuEntry(
                    text: "导出".tl,
                    onClick: () =>
                        Future.delayed(const Duration(milliseconds: 200), () {
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
                                    logic.comics[index].id, logic.comics[index].name, logic.comics[index].eps);
                                App.globalBack();
                                if (res) {
                                  //忽视
                                } else {
                                  showMessage(App.globalContext, "导出失败");
                                }
                              });
                        }),
                  ),
                  DesktopMenuEntry(
                    text: "导出为pdf".tl,
                    onClick: () {
                      exportAsPdf(logic.comics[index], logic);
                    },
                  ),
                  DesktopMenuEntry(
                    text: "查看漫画详情".tl,
                    onClick: () {
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

  void toComicInfoPage(DownloadedItem comic) => _toComicInfoPage(comic);

  void showInfo(int index, DownloadPageLogic logic, BuildContext context) {
    if (UiMode.m1(context)) {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return DownloadedComicInfoView(logic.comics[index], logic);
          });
    } else {
      showSideBar(App.globalContext!, DownloadedComicInfoView(logic.comics[index], logic),
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
                      onPressed: () => App.globalBack(),
                      child: Text("取消".tl)),
                  TextButton(
                      onPressed: () async {
                        App.globalBack();
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

  Widget buildTitle(BuildContext context, DownloadPageLogic logic){
    if(logic.searchMode && !logic.selecting){
      return Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top / 2),
        child: Center(
          child: Container(
            height: 42,
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 6),
            child: TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "搜索".tl
              ),
              onChanged: (s){
                logic.keyword = s.toLowerCase();
                logic.update();
              },
            ),
          ),
        ),
      );
    }else{
      return logic.selecting
          ? Text("已选择 @num 个项目"
          .tlParams({"num": logic.selectedNum.toString()}))
          : Text("已下载".tl);
    }
  }

  Widget buildAppbar(BuildContext context, DownloadPageLogic logic)
    => MySliverAppBar(
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
      title: buildTitle(context, logic),
      actions: [
        if (!logic.selecting && !logic.searchMode)
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
                              onChange: (i){
                                appdata.settings[26] = appdata.settings[26].setValueAt(i.toString(), 0);
                                appdata.updateSettings();
                                changed = true;
                              },
                              values: ["时间", "漫画名", "作者名", "大小"].tl,
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
        if (!logic.selecting && !logic.searchMode)
          Tooltip(
            message: "下载管理器".tl,
            child: IconButton(
              icon: const Icon(Icons.download_for_offline),
              onPressed: () {
                showAdaptiveWidget(
                    App.globalContext!,
                    DownloadingPage(
                      inPopupWidget:
                      MediaQuery.of(App.globalContext!).size.width >
                          600,
                    ));
              },
            ),
          )
        else if(logic.selecting)
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
                        onTap: () => exportSelectedComic(context, logic),
                      ),
                      PopupMenuItem(
                        child: Text("导出为pdf".tl),
                        onTap: () => exportAsPdf(null, logic),
                      ),
                      PopupMenuItem(
                        child: Text("查看漫画详情".tl),
                        onTap: () => Future.delayed(
                            const Duration(milliseconds: 200),
                                () {
                              if (logic.selectedNum != 1) {
                                showMessage(App.globalContext, "请选择一个漫画".tl);
                              } else {
                                for (int i = 0; i < logic.selected.length; i++) {
                                  if (logic.selected[i]) {
                                    toComicInfoPage(logic.comics[i]);
                                  }
                                }
                              }
                            }),
                      ),
                      PopupMenuItem(
                        child: Text("添加至本地收藏".tl),
                        onTap: () => Future.delayed(
                            const Duration(milliseconds: 200),
                            () => addToLocalFavoriteFolder(context, logic)
                        ),
                      ),
                    ]);
              },
            ),
          ),
        if (!logic.selecting)
          Tooltip(
            message: "搜索".tl,
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                logic.searchMode = !logic.searchMode;
                if(!logic.searchMode){
                  logic.keyword = "";
                }
                logic.update();
              },
            ),
          )
      ],
    );

  void exportSelectedComic(BuildContext context, DownloadPageLogic logic){
    if (logic.selectedNum == 0) {
      showMessage(context, "请选择漫画".tl);
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
  }

  void addToLocalFavoriteFolder(BuildContext context, DownloadPageLogic logic){
    String? folder;
    showDialog(
        context: App.globalContext!,
        builder: (context) => SimpleDialog(
          title: const Text("复制到..."),
          children: [
            SizedBox(
              width: 400,
              height: 132,
              child: Column(
                children: [
                  ListTile(
                    title: Text("收藏夹".tl),
                    trailing: Select(
                      width: 156,
                      values: LocalFavoritesManager().folderNames,
                      initialValue: null,
                      onChange: (i) =>
                      folder = LocalFavoritesManager().folderNames[i],
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: FilledButton(
                      child: const Text("确认"),
                      onPressed: () {
                        if(folder == null){
                          return;
                        }
                        for (int i = 0; i < logic.selected.length; i++) {
                          if (logic.selected[i]) {
                            var comic = logic.comics[i];
                            LocalFavoritesManager().addComic(folder!, switch(comic.type){
                              DownloadType.picacg =>
                                  FavoriteItem.fromPicacg((comic as DownloadedComic).comicItem.toBrief()),
                              DownloadType.ehentai =>
                                  FavoriteItem.fromEhentai((comic as DownloadedGallery).gallery.toBrief()),
                              DownloadType.jm =>
                                  FavoriteItem.fromJmComic((comic as DownloadedJmComic).comic.toBrief()),
                              DownloadType.nhentai =>
                                  FavoriteItem.fromNhentai(NhentaiComicBrief(comic.name,
                                      (comic as NhentaiDownloadedComic).cover, comic.id, "", const [])),
                              DownloadType.hitomi =>
                                  FavoriteItem.fromHitomi((comic as DownloadedHitomiComic).comic.toBrief(comic.link, comic.cover)),
                              DownloadType.htmanga =>
                                  FavoriteItem.fromHtcomic((comic as DownloadedHtComic).comic.toBrief()),
                              DownloadType.other => (){
                                var c = (comic as CustomDownloadedItem);
                                return FavoriteItem.custom(CustomComic(
                                  c.name,
                                  c.subTitle,
                                  c.cover,
                                  c.comicId,
                                  c.tags,
                                  "",
                                  c.sourceKey
                                ));
                              }(),
                              DownloadType.favorite => throw UnimplementedError(),
                            });
                          }
                        }
                        App.globalBack();
                      },
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                ],
              ),
            )
          ],
        ));
  }
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
    showConfirmDialog(context, "确认删除".tl, "要删除这个章节吗".tl, () async{
      var message = await DownloadManager().deleteEpisode(comic, i);
      if(message == null) {
        setState(() {});
      }else{
        showMessage(App.globalContext, message);
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
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
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
                          App.globalBack();
                          _toComicInfoPage(widget.item);
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
    comic.read();
  }

  void readSpecifiedEps(int i) {
    if (comic.type == DownloadType.picacg) {
      addPicacgHistory((comic as DownloadedComic).comicItem);
      App.globalTo(() => ComicReadingPage.picacg(
          (comic as DownloadedComic).comicItem.id,
          i + 1,
          (comic as DownloadedComic).eps,
          (comic as DownloadedComic).comicItem.title));
    } else if (comic.type == DownloadType.jm) {
      addJmHistory((comic as DownloadedJmComic).comic);
      App.globalTo(() => ComicReadingPage.jmComic(
          (comic as DownloadedJmComic).comic.id,
          (comic as DownloadedJmComic).comic.name,
          (comic as DownloadedJmComic).comic.series.values.toList(),
          i + 1,
          (comic as DownloadedJmComic).comic.epNames));
    } else if (comic.type == DownloadType.ehentai) {
      readEhGallery((comic as DownloadedGallery).gallery);
    } else if (comic.type == DownloadType.hitomi) {
      readHitomiComic((comic as DownloadedHitomiComic).comic,
          (comic as DownloadedHitomiComic).cover,
          (comic as DownloadedHitomiComic).link);
    } else if (comic.type == DownloadType.htmanga) {
      readHtmangaComic((comic as DownloadedHtComic).comic);
    } else if (comic.type == DownloadType.nhentai){
      readNhentai(NhentaiComic(comic.id.replaceFirst("nhentai", ""), comic.name, comic.subTitle,
          (comic as NhentaiDownloadedComic).cover, {}, false, [], [], ""));
    } else if (comic.type == DownloadType.other){
      var comic_ = (comic as CustomDownloadedItem);
      readWithKey(comic_.sourceKey, comic_.comicId, i + 1, 1, comic_.name, {
        "eps": comic_.chapters,
        "cover": comic_.cover
      });
    }
  }
}

class DownloadedComicTile extends ComicTile {
  final String size;
  final File imagePath;
  final String author;
  final String name;
  final String type;
  final List<String> tag;
  final void Function() onTap;
  final void Function() onLongTap;
  final void Function(TapDownDetails details) onSecondaryTap;

  @override
  List<String>? get tags => tag.map((e) => e.translateTagsToCN).toList();

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
      required this.tag,
      super.key});
}

void _toComicInfoPage(DownloadedItem comic){
  if (comic is DownloadedComic) {
    MainPage.to(() => PicacgComicPage(
        (comic)
            .comicItem
            .toBrief()));
  } else if (comic is DownloadedGallery) {
    MainPage.to(() => EhGalleryPage(
        (comic)
            .gallery
            .toBrief()));
  } else if (comic is DownloadedJmComic) {
    MainPage.to(() => JmComicPage(
        (comic).comic.id));
  } else if (comic is DownloadedHitomiComic) {
    MainPage.to(() => HitomiComicPage(
        comic
            .toBrief()));
  } else if (comic is DownloadedHtComic) {
    MainPage.to(() => HtComicPage(
        comic
            .comic
            .toBrief()));
  } else if(comic is NhentaiDownloadedComic){
    MainPage.to(() => NhentaiComicPage(
        comic
            .id.replaceFirst("nhentai", "")));
  } else if(comic is CustomDownloadedItem){
    MainPage.to(() => CustomComicPage(sourceKey: comic.sourceKey, id: comic.comicId));
  }
}
