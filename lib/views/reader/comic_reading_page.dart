import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/keep_screen_on.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import 'package:pica_comic/views/reader/tool_bar.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../../foundation/app.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../tools/key_down_event.dart';
import '../widgets/image.dart';
import 'eps_view.dart';
import 'image_view.dart';
import 'touch_control.dart';
import 'reading_logic.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

class ReadingPageData {
  int initialPage;
  var epsWidgets = <Widget>[];
  ListenVolumeController? listenVolume;
  ScrollManager? scrollManager;
  String? message;
  String target;
  List<int> downloadedEps = [];
  ReadingType type;
  List<String> eps;
  Gallery? gallery;
  ReadingPageData(
      this.initialPage, this.target, this.type, this.eps, this.gallery);
}

///阅读器
class ComicReadingPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ///目标, 对于picacg,jm,hitomi,绅士漫画是漫画id, 对于ehentai是漫画链接
  final String target;

  ///章节信息, picacg为各章节名称 ,ehentai, hitomi此数组为空, jm为各章节id
  final List<String> eps;

  ///标题
  final String title;

  ///章节
  ///
  ///picacg和禁漫有效, e-hentai,绅士漫画为0
  ///
  /// 这里是初始值, 变量在logic中
  ///
  /// 注意: **从1开始**
  final int order;

  ///eh画廊模型, 阅读非画廊此变量为null
  final Gallery? gallery;

  ///阅读类型
  final ReadingType type;

  late final History? history = HistoryManager().findSync(target);

  ///一些会发生变更的信息, 全放logic里面会很乱
  late final ReadingPageData data = ReadingPageData(
      0,
      (type == ReadingType.jm && eps.isNotEmpty)
          ? eps.elementAtOrNull(order - 1) ?? eps[0]
          : target,
      type,
      eps,
      gallery);

  ///阅读Hitomi画廊时使用的图片数据
  ///
  /// 仅Hitomi有效, 其它都为null
  final List<HitomiFile>? images;

  ComicReadingPage.picacg(this.target, this.order, this.eps, this.title,
      {super.key, int initialPage = 1})
      : gallery = null,
        type = ReadingType.picacg,
        images = null {
    data.initialPage = initialPage;
    StateController.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.ehentai(this.target, this.gallery,
      {super.key, int initialPage = 1})
      : eps = [],
        title = gallery!.title,
        order = 0,
        type = ReadingType.ehentai,
        images = null {
    data.initialPage = initialPage;
    StateController.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.jmComic(this.target, this.title, this.eps, this.order,
      {super.key, int initialPage = 1})
      : type = ReadingType.jm,
        gallery = null,
        images = null {
    data.initialPage = initialPage;
    StateController.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.hitomi(this.target, this.title, this.images,
      {super.key, int initialPage = 1})
      : eps = [],
        order = 0,
        type = ReadingType.hitomi,
        gallery = null {
    data.initialPage = initialPage;
    StateController.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.htmanga(this.target, this.title,
      {super.key, int initialPage = 1})
      : eps = [],
        order = 0,
        gallery = null,
        type = ReadingType.htManga,
        images = null {
    data.initialPage = initialPage;
    StateController.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.nhentai(this.target, this.title,
      {super.key, int initialPage = 1})
      : eps = [],
        order = 0,
        gallery = null,
        type = ReadingType.nhentai,
        images = null {
    data.initialPage = initialPage;
    StateController.put(ComicReadingPageLogic(order, data));
  }

  _updateHistory(ComicReadingPageLogic? logic) {
    if (type.hasEps) {
      if (logic!.order == 1 && logic.index == 1) {
        history?.ep = 0;
        history?.page = 0;
      } else {
        if (logic.order == data.epsWidgets.length - 1 &&
            logic.index == logic.length) {
          history?.ep = 0;
          history?.page = 0;
        } else {
          history?.ep = logic.order;
          history?.page = logic.index;
        }
      }
    } else {
      if (logic!.index == 1 || logic.index == logic.length) {
        history?.ep = 0;
        history?.page = 0;
      } else {
        history?.ep = 1;
        history?.page = logic.index;
      }
    }
    HistoryManager().saveData();
  }

  @override
  Widget build(BuildContext context) {
    return StateBuilder<ComicReadingPageLogic>(initState: (logic) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      if (appdata.settings[14] == "1") {
        setKeepScreenOn();
      }
      //进入阅读器时清除内存中的缓存, 并且增大限制
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024;
    }, dispose: (logic) {
      //清除缓存并减小最大缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
      //保存历史记录
      _updateHistory(logic);

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      if (data.listenVolume != null) {
        data.listenVolume!.stop();
      }
      if (appdata.settings[14] == "1") {
        cancelKeepScreenOn();
      }
      ImageManager().saveData();
      logic.runningAutoPageTurning = false;
      ComicImage.clear();
      StateController.remove<ComicReadingPageLogic>();
      Future.microtask(() {
        if (ComicPage.tagsStack.isNotEmpty) {
          ComicPage.tagsStack.last.updateHistory(history);
        }
      });
    }, builder: (logic) {
      return Scaffold(
        backgroundColor: Colors.black,
        endDrawerEnableOpenDragGesture: false,
        key: _scaffoldKey,
        endDrawer: Drawer(
          child: buildEpsView(),
        ),
        floatingActionButton: buildEpChangeButton(logic),
        body: StateBuilder<ComicReadingPageLogic>(builder: (logic) {
          if (logic.isLoading) {
            history?.readEpisode.add(logic.order);
            //加载信息
            if (type == ReadingType.ehentai) {
              loadGalleryInfo(logic);
            } else if (type == ReadingType.picacg) {
              loadComicInfo(logic);
            } else if (type == ReadingType.jm) {
              loadJmComicInfo(logic);
            } else if (type == ReadingType.hitomi) {
              loadHitomiData(logic);
            } else if (type == ReadingType.htManga) {
              loadHtmangaData(logic);
            } else {
              loadNhentaiData(logic);
            }
            return const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (logic.urls.isNotEmpty) {
            if (logic.readingMethod == ReadingMethod.topToBottomContinuously &&
                data.initialPage != 1) {
              Future.delayed(const Duration(milliseconds: 300), () {
                logic.jumpToPage(data.initialPage);
                data.initialPage = 1;
              });
            }
            //监听音量键
            if (appdata.settings[7] == "1") {
              if (appdata.settings[9] != "4") {
                data.listenVolume = ListenVolumeController(
                    () => logic.jumpToLastPage(), () => logic.jumpToNextPage());
              } else {
                data.listenVolume = ListenVolumeController(
                    () => logic.scrollController
                        .jumpTo(logic.scrollController.position.pixels - 400),
                    () => logic.scrollController
                        .jumpTo(logic.scrollController.position.pixels + 400));
              }
              data.listenVolume!.listenVolumeChange();
            } else if (data.listenVolume != null) {
              data.listenVolume!.stop();
              data.listenVolume = null;
            }

            if (appdata.settings[9] == "4") {
              data.scrollManager ??= ScrollManager(logic);
            }

            var body = Listener(
              onPointerMove: (details) {
                if (appdata.settings[9] == "4" &&
                    data.scrollManager!.fingers != 2) {
                  data.scrollManager!.addOffset(details.delta);
                }
              },
              onPointerUp: TapController.onTapUp,
              onPointerDown: TapController.onTapDown,
              behavior: HitTestBehavior.translucent,
              child: Stack(
                children: [
                  buildComicView(
                      logic,
                      type,
                      (logic.downloaded && type == ReadingType.jm)
                          ? "jm$target"
                          : data.target,
                      eps,
                      context),
                  if (MediaQuery.of(context).platformBrightness ==
                          Brightness.dark &&
                      appdata.settings[18] == "1")
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                    ),

                  buildPageInfoText(logic, type.hasEps, eps, context,
                      jm: type == ReadingType.jm),

                  //底部工具栏
                  buildBottomToolBar(logic, context, type.hasEps, openEpsDrawer,
                      share, saveCurrentImage),

                  ...buildButtons(logic, context),

                  //顶部工具栏
                  buildTopToolBar(logic, context, title),
                ],
              ),
            );

            // WillPopScope has a problem on IOS which is not been solved currently.
            // See https://github.com/flutter/flutter/issues/14203
            if (App.isIOS) {
              return body;
            } else {
              return WillPopScope(
                  onWillPop: () async {
                    if (logic.tools) {
                      return true;
                    } else {
                      logic.tools = true;
                      logic.update();
                      return false;
                    }
                  },
                  child: body);
            }
          } else {
            return buildErrorView(logic, context);
          }
        }),
      );
    });
  }

  Widget buildErrorView(
      ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
    return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: SafeArea(
            child: Stack(
          children: [
            Positioned(
              left: 8,
              top: 12,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
                onPressed: () => App.globalBack(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(App.globalContext!).size.height / 2 - 80,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(App.globalContext!).size.height / 2 - 10,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  data.message ?? "未知错误".tl,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(App.globalContext!).size.height / 2 + 30,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: 250,
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              data.epsWidgets.clear();
                              comicReadingPageLogic.change();
                            },
                            child: Text("重试".tl),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                            child: FilledButton(
                          onPressed: () {
                            if (!type.hasEps) {
                              showMessage(context, "没有其它章节".tl);
                              return;
                            }
                            if (MediaQuery.of(context).size.width > 600) {
                              showSideBar(context, buildEpsView(),
                                  title: null,
                                  useSurfaceTintColor: true,
                                  addTopPadding: true,
                                  width: 400);
                            } else {
                              showModalBottomSheet(
                                  context: context,
                                  useSafeArea: false,
                                  builder: (context) {
                                    return buildEpsView();
                                  });
                            }
                          },
                          child: Text("切换章节".tl),
                        )),
                      ],
                    ),
                  )),
            ),
          ],
        )));
  }

  void loadComicInfo(ComicReadingPageLogic comicReadingPageLogic) async {
    int? epLength;
    try {
      if (downloadManager.downloaded.contains(data.target)) {
        var downloadedItem = await downloadManager.getComicFromId(data.target);
        data.downloadedEps = downloadedItem.downloadedChapters;
        if (downloadedItem.downloadedChapters
            .contains(comicReadingPageLogic.order - 1)) {
          comicReadingPageLogic.downloaded = true;
          epLength = await downloadManager.getEpLength(
              data.target, comicReadingPageLogic.order);
        } else {
          comicReadingPageLogic.downloaded = false;
        }
      } else {
        comicReadingPageLogic.downloaded = false;
      }
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
      showMessage(App.globalContext, "数据丢失, 将从网络获取漫画".tl);
      comicReadingPageLogic.downloaded = false;
    }
    comicReadingPageLogic.tools = false;
    if (data.epsWidgets.isEmpty) {
      data.epsWidgets.add(
        ListTile(
          leading: Icon(
            Icons.library_books,
            color:
                Theme.of(App.globalContext!).colorScheme.onSecondaryContainer,
          ),
          title: Text("章节".tl),
        ),
      );
    }
    if (data.epsWidgets.length == 1) {
      for (int i = 1; i < eps.length; i++) {
        data.epsWidgets.add(ListTile(
          title: Text(eps[i]),
          onTap: () {
            if (i != comicReadingPageLogic.order) {
              comicReadingPageLogic.order = i;
              comicReadingPageLogic.urls = [];
              comicReadingPageLogic.change();
            }
            Navigator.pop(App.globalContext!);
          },
        ));
      }
    }
    if (comicReadingPageLogic.downloaded && epLength != null) {
      for (int p = 0; p < epLength; p++) {
        comicReadingPageLogic.urls.add("");
      }
      comicReadingPageLogic.change();
    } else {
      network
          .getComicContent(data.target, comicReadingPageLogic.order)
          .then((l) {
        if (l.error) {
          data.message = l.errorMessageWithoutNull;
        } else {
          comicReadingPageLogic.urls = List.generate(
              l.data.length, (index) => getImageUrl(l.data[index]));
        }
        comicReadingPageLogic.change();
      });
    }
  }

  void loadGalleryInfo(ComicReadingPageLogic logic) async {
    try {
      if (downloadManager.downloadedGalleries
          .contains(getGalleryId(gallery!.link))) {
        logic.downloaded = true;
        for (int i = 0;
            i <
                await downloadManager
                    .getComicLength(getGalleryId(gallery!.link));
            i++) {
          logic.urls.add("");
        }
        logic.change();
        return;
      }
    } catch (e) {
      showMessage(App.globalContext, "数据丢失, 将从网络获取漫画".tl);
      logic.downloaded = false;
    }
    var maxPage = int.parse(gallery!.maxPage);
    logic.urls.addAll(List.generate(maxPage, (index) => ""));
    await Future.delayed(const Duration(milliseconds: 200));
    logic.change();
  }

  void loadJmComicInfo(ComicReadingPageLogic comicReadingPageLogic) async {
    int? epLength;
    try {
      if (downloadManager.downloadedJmComics.contains("jm$target")) {
        var downloadedItem =
            await downloadManager.getJmComicFormId("jm$target");
        if (downloadedItem.downloadedChapters
            .contains(comicReadingPageLogic.order - 1)) {
          comicReadingPageLogic.downloaded = true;
          data.downloadedEps = downloadedItem.downloadedChapters;
          epLength = await downloadManager.getEpLength(
              "jm$target", comicReadingPageLogic.order);
        } else {
          comicReadingPageLogic.downloaded = false;
        }
      } else {
        comicReadingPageLogic.downloaded = false;
      }
    } catch (e) {
      showMessage(App.globalContext, "数据丢失, 将从网络获取漫画");
      comicReadingPageLogic.downloaded = false;
    }
    comicReadingPageLogic.tools = false;
    if (data.epsWidgets.isEmpty) {
      data.epsWidgets.add(
        ListTile(
          leading: Icon(
            Icons.library_books,
            color:
                Theme.of(App.globalContext!).colorScheme.onSecondaryContainer,
          ),
          title: Text(
            "章节".tl,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    if (data.epsWidgets.length == 1) {
      for (int i = 0; i < eps.length; i++) {
        data.epsWidgets.add(ListTile(
          title: Text("${"第 @c 章".tlParams({
                "c": (i + 1).toString()
              })}${(comicReadingPageLogic.order == i + 1) ? "(当前)".tl : ""}"),
          onTap: () {
            if (comicReadingPageLogic.order != i + 1) {
              comicReadingPageLogic.order = i + 1;
              data.target = eps[i];
              data.epsWidgets.clear();
              comicReadingPageLogic.urls.clear();
              comicReadingPageLogic.change();
            }
            Navigator.pop(App.globalContext!);
          },
        ));
      }
    }
    if (comicReadingPageLogic.downloaded && epLength != null) {
      for (int p = 0; p < epLength; p++) {
        comicReadingPageLogic.urls.add("");
      }
      comicReadingPageLogic.change();
      return;
    }
    var res = await jmNetwork.getChapter(data.target);
    if (res.error) {
      data.message = res.errorMessage ?? "网络错误".tl;
    } else {
      comicReadingPageLogic.urls = res.data;
    }
    comicReadingPageLogic.isLoading = false;
    comicReadingPageLogic.update();
  }

  void loadHitomiData(ComicReadingPageLogic logic) async {
    logic.images = images!;
    logic.urls = images!.map<String>((e) => "").toList();
    if (downloadManager.downloadedHitomiComics.contains("hitomi$target")) {
      logic.downloaded = true;
    }
    await Future.delayed(const Duration(milliseconds: 200));
    logic.isLoading = false;
    logic.update();
  }

  void loadHtmangaData(ComicReadingPageLogic logic) async {
    try {
      if (downloadManager.downloadedHtComics.contains("Ht$target")) {
        logic.downloaded = true;
        for (int i = 0;
            i < await downloadManager.getComicLength("Ht$target");
            i++) {
          logic.urls.add("");
        }
        logic.change();
        return;
      }
    } catch (e) {
      showMessage(App.globalContext, "数据丢失, 将从网络获取漫画");
      logic.downloaded = false;
    }
    var res = await HtmangaNetwork().getImages(target);
    if (res.error) {
      data.message = res.errorMessage;
    } else {
      logic.urls = res.data;
    }
    logic.isLoading = false;
    logic.update();
  }

  void loadNhentaiData(ComicReadingPageLogic logic) async {
    try {
      if (downloadManager.downloadedNhentaiComics.contains("nhentai$target")) {
        logic.downloaded = true;
        for (int i = 0;
            i < await downloadManager.getComicLength("nhentai$target");
            i++) {
          logic.urls.add("");
        }
        logic.change();
        return;
      }
    } catch (e) {
      showMessage(App.globalContext, "数据丢失, 将从网络获取漫画");
      logic.downloaded = false;
    }
    var res = await NhentaiNetwork().getImages(target);
    if (res.error) {
      data.message = res.errorMessage;
    } else {
      logic.urls = res.data;
    }
    logic.isLoading = false;
    logic.update();
  }

  Widget buildEpsView() {
    return EpsView(type, eps, data);
  }

  void openEpsDrawer() {
    var context = App.globalContext!;
    if (MediaQuery.of(context).size.width > 600) {
      showSideBar(context, buildEpsView(),
          title: null,
          useSurfaceTintColor: true,
          width: 400,
          addTopPadding: true);
    } else {
      showModalBottomSheet(
          context: context,
          useSafeArea: false,
          builder: (context) {
            return buildEpsView();
          });
    }
  }

  /// Used when [ComicReadingPageLogic.readingMethod] is [ReadingMethod.topToBottomContinuously].
  ///
  /// Select a image form screen, to share or download
  Future<int?> selectImage() async {
    var logic = StateController.find<ComicReadingPageLogic>();
    var items = logic.itemScrollListener.itemPositions.value.toList();
    if (items.length == 1) {
      return items[0].index;
    }
    int? res;
    await showDialog(
        context: App.globalContext!,
        builder: (context) {
          return SimpleDialog(
            title: Text("选择屏幕上的图片".tl),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Column(
                  children: [
                    for (var item in items)
                      ListTile(
                        title: Text((item.index + 1).toString()),
                        onTap: () {
                          res = item.index;
                          App.globalBack();
                        },
                        trailing: const Icon(Icons.arrow_right),
                      )
                  ],
                ),
              )
            ],
          );
        });
    return res;
  }

  String getImageKey(int index) {
    var logic = StateController.find<ComicReadingPageLogic>();
    if (type == ComicType.ehentai) {
      return "${gallery!.link}${index + 1}";
    }
    return type == ReadingType.hitomi
        ? logic.images[index].hash
        : logic.urls[index];
  }

  void share() async {
    var logic = StateController.find<ComicReadingPageLogic>();
    int? index = logic.index - 1;
    if (logic.readingMethod == ReadingMethod.topToBottomContinuously) {
      index = await selectImage();
    }
    if (index == null) {
      return;
    }
    if (logic.downloaded) {
      var id = data.target;
      if (type == ReadingType.ehentai) {
        id = getGalleryId(data.target);
      }
      if (type == ReadingType.jm) {
        id = "jm$target";
      } else if (type == ReadingType.hitomi) {
        id = "hitomi$target";
      } else if (type == ReadingType.htManga) {
        id = "Ht$target";
      } else if (type == ReadingType.nhentai) {
        id = "nhentai$target";
      }
      shareImageFromDisk(downloadManager.getImage(id, logic.order, index).path);
    } else {
      shareImageFromCache(getImageKey(index), data.target, true);
    }
  }

  void saveCurrentImage() async {
    var logic = StateController.find<ComicReadingPageLogic>();
    int? index = logic.index - 1;
    if (logic.readingMethod == ReadingMethod.topToBottomContinuously) {
      index = await selectImage();
    }
    if (index == null) {
      return;
    }
    if (logic.downloaded) {
      var id = data.target;
      if (type == ReadingType.ehentai) {
        id = getGalleryId(data.target);
      }
      if (type == ReadingType.jm) {
        id = "jm$target";
      } else if (type == ReadingType.hitomi) {
        id = "hitomi$target";
      } else if (type == ReadingType.htManga) {
        id = "Ht$target";
      } else if (type == ReadingType.nhentai) {
        id = "nhentai$target";
      }
      saveImageFromDisk(downloadManager.getImage(id, logic.order, index).path);
    } else {
      saveImage(getImageKey(index), data.target, reading: true);
    }
  }

  Widget? buildEpChangeButton(ComicReadingPageLogic logic) {
    if (!type.hasEps) return null;
    switch (logic.showFloatingButtonValue) {
      case -1:
        return FloatingActionButton(
          onPressed: () => logic.jumpToLastChapter(),
          child: const Icon(Icons.arrow_back_ios_outlined),
        );
      case 0:
        return null;
      case 1:
        return Hero(
            tag: "FAB",
            child: StateBuilder<ComicReadingPageLogic>(
              id: "FAB",
              builder: (logic) {
                return Container(
                  width: 58,
                  height: 58,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                      color: Theme.of(App.globalContext!)
                          .colorScheme
                          .primaryContainer,
                      borderRadius: BorderRadius.circular(16)),
                  child: Stack(
                    children: [
                      Positioned.fill(
                          child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => logic.jumpToNextChapter(),
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                              child: Icon(
                            Icons.arrow_forward_ios,
                            size: 24,
                            color: Theme.of(App.globalContext!)
                                .colorScheme
                                .onPrimaryContainer,
                          )),
                        ),
                      )),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: logic.fABValue,
                        child: ColoredBox(
                          color: Theme.of(App.globalContext!)
                              .colorScheme
                              .surfaceTint
                              .withOpacity(0.2),
                          child: const SizedBox.expand(),
                        ),
                      )
                    ],
                  ),
                );
              },
            ));
    }
    return null;
  }
}
