library pica_reader;

import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/image_loader/file_image_loader.dart';
import 'package:pica_comic/foundation/image_loader/stream_image_provider.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/keep_screen_on.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/views/widgets/window_frame.dart';
import '../../foundation/app.dart';
import '../../foundation/ui_mode.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../tools/key_down_event.dart';
import '../jm_views/jm_comments_page.dart';
import '../widgets/custom_slider.dart';
import '../widgets/scrollable_list/src/item_positions_listener.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';
import '../widgets/select.dart';

part 'eps_view.dart';
part 'image_view.dart';
part 'image.dart';
part 'touch_control.dart';
part 'reading_logic.dart';
part 'tool_bar.dart';
part 'reading_type.dart';
part 'reading_settings.dart';
part 'reading_data.dart';

///阅读器
class ComicReadingPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final ReadingData readingData;

  late final History? history = HistoryManager().findSync(readingData.id);

  final int initialPage;

  final int initialEp;

  ReadingType get type => readingData.type;

  ComicReadingPage(this.readingData, this.initialPage, this.initialEp,
      {super.key}) {
    StateController.put(ComicReadingPageLogic(
        initialEp,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  ComicReadingPage.picacg(
      String target, this.initialEp, List<String> eps, String title,
      {super.key, this.initialPage = 1})
      : readingData = PicacgReadingData(title, target, eps) {
    StateController.put(ComicReadingPageLogic(
        initialEp,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  ComicReadingPage.ehentai(String target, Gallery gallery,
      {super.key, this.initialPage = 1})
      : initialEp = 1,
        readingData = EhReadingData(gallery) {
    StateController.put(ComicReadingPageLogic(
        1,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  ComicReadingPage.jmComic(String target, String title, List<String> epIds,
      this.initialEp, List<String> epNames,
      {super.key, this.initialPage = 1})
      : readingData = JmReadingData(title, target, epIds, epNames) {
    StateController.put(ComicReadingPageLogic(
        initialEp,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  ComicReadingPage.hitomi(String target, String title, List<HitomiFile> images,
      {super.key, this.initialPage = 1})
      : initialEp = 1,
        readingData = HitomiReadingData(title, target, images) {
    StateController.put(ComicReadingPageLogic(
        initialEp,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  ComicReadingPage.htmanga(String target, String title,
      {super.key, this.initialPage = 1})
      : initialEp = 1,
        readingData = HtReadingData(title, target) {
    StateController.put(ComicReadingPageLogic(
        initialEp,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  ComicReadingPage.nhentai(String target, String title,
      {super.key, this.initialPage = 1})
      : initialEp = 1,
        readingData = NhentaiReadingData(title, target) {
    StateController.put(ComicReadingPageLogic(
        initialEp,
        readingData,
        initialPage,
        () => _updateHistory(
            StateController.find<ComicReadingPageLogic>(), false)));
  }

  _updateHistory(ComicReadingPageLogic? logic, bool updateMePage) {
    if (readingData.hasEp) {
      if (logic!.order == 1 && logic.index == 1) {
        history?.ep = 0;
        history?.page = 0;
      } else {
        if (logic.order == readingData.eps?.length &&
            logic.index == logic.length) {
          history?.ep = 0;
          history?.page = 0;
        } else {
          history?.ep = logic.order;
          history?.page = logic.index;
        }
      }
    } else {
      if (logic!.index == 1) {
        history?.ep = 0;
        history?.page = 0;
      } else {
        history?.ep = 1;
        history?.page = logic.index;
      }
    }
    history!.maxPage = logic.length;
    HistoryManager().saveReadHistory(history!, updateMePage);
  }

  @override
  Widget build(BuildContext context) {
    return StateBuilder<ComicReadingPageLogic>(initState: (logic) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      if (appdata.settings[14] == "1") {
        setKeepScreenOn();
      }
      if (appdata.settings[76] == "1") {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
      }
      //进入阅读器时清除内存中的缓存, 并且增大限制
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024;
      logic.openEpsView = openEpsDrawer;
      Future.microtask(() =>
          StateController.findOrNull<WindowFrameController>()?.setDarkTheme());
    }, dispose: (logic) {
      //清除缓存并减小最大缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
      logic.clearPhotoViewControllers();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      if (logic.listenVolume != null) {
        logic.listenVolume!.stop();
      }
      if (appdata.settings[14] == "1") {
        cancelKeepScreenOn();
      }
      ImageManager().saveData();
      logic.runningAutoPageTurning = false;
      ComicImage.clear();
      StateController.remove<ComicReadingPageLogic>();
      // 更新本地收藏
      LocalFavoritesManager().onReadEnd(readingData.id);
      // 保存历史记录
      if (history != null) {
        _updateHistory(logic, true);
      }
      // 退出全屏
      if (logic.isFullScreen) {
        logic.fullscreen();
      }
      if(!DownloadManager().isDownloading){
        ImageManager.clearTasks();
      }
      // 更新漫画详情页面
      Future.microtask(() {
        if (ComicPage.tagsStack.isNotEmpty) {
          ComicPage.tagsStack.last.updateHistory(history);
        }
      });
      if (appdata.settings[76] == "1") {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
      Future.microtask(() =>
          StateController.findOrNull<WindowFrameController>()?.resetTheme());
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
            loadInfo(logic);
            return const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (logic.urls.isNotEmpty) {
            if (logic.readingMethod == ReadingMethod.topToBottomContinuously &&
                !logic.haveUsedInitialPage && initialPage != 0) {
              Future.microtask(() {
                logic.jumpToPage(initialPage);
                logic.haveUsedInitialPage = true;
              });
            }
            //监听音量键
            if (appdata.settings[7] == "1") {
              if (appdata.settings[9] != "4") {
                logic.listenVolume = ListenVolumeController(
                    () => logic.jumpToLastPage(), () => logic.jumpToNextPage());
              } else {
                logic.listenVolume = ListenVolumeController(
                    () => logic.scrollController
                        .jumpTo(logic.scrollController.position.pixels - 400),
                    () => logic.scrollController
                        .jumpTo(logic.scrollController.position.pixels + 400));
              }
              logic.listenVolume!.listenVolumeChange();
            } else if (logic.listenVolume != null) {
              logic.listenVolume!.stop();
              logic.listenVolume = null;
            }

            if (appdata.settings[9] == "4") {
              logic.scrollManager ??= ScrollManager(logic);
            }

            var body = Listener(
              onPointerMove: TapController.onPointerMove,
              onPointerUp: TapController.onTapUp,
              onPointerDown: TapController.onTapDown,
              behavior: HitTestBehavior.translucent,
              onPointerCancel: TapController.onTapCancel,
              child: Stack(
                children: [
                  buildComicView(
                    logic,
                    context,
                    readingData.id,
                  ),
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

                  if (appdata.settings[57] == "1")
                    buildPageInfoText(logic, context),

                  //底部工具栏
                  buildBottomToolBar(logic, context, readingData.hasEp),

                  ...buildButtons(logic, context),

                  //顶部工具栏
                  buildTopToolBar(logic, context),
                ],
              ),
            );

            return KeyboardListener(
              focusNode: logic.focusNode,
              autofocus: true,
              onKeyEvent: logic.handleKeyboard,
              child: body,
            );
          } else {
            return buildErrorView(logic, context);
          }
        }),
      );
    });
  }

  Widget buildErrorView(ComicReadingPageLogic logic, BuildContext context) {
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
                  logic.errorMessage ?? "未知错误".tl,
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
                              logic.change();
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
                            if (!readingData.hasEp) {
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

  void loadInfo(ComicReadingPageLogic logic) async {
    logic.urls = [];
    var res = await readingData.loadEp(logic.order);
    if (res.error) {
      logic.errorMessage = res.errorMessage;
    } else {
      logic.urls = res.data;
    }
    logic.isLoading = false;
    logic.update();
  }

  Widget buildEpsView() {
    return EpsView(readingData);
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
      return "${readingData.id}${index + 1}";
    }
    return type == ReadingType.hitomi
        ? (readingData as HitomiReadingData).images[index].hash
        : logic.urls[index];
  }

  Future<File> _getFileFromStream(Stream<DownloadProgress> stream) async {
    await for (var event in stream) {
      if (event.finished) {
        return event.getFile();
      }
    }
    throw "failed";
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

    var file = await _getFileFromStream(
        readingData.loadImage(logic.order, index, logic.urls[index]));

    shareImage(file);
  }

  Future<String?> _persistentCurrentImage() async {
    var logic = StateController.find<ComicReadingPageLogic>();
    int? index = logic.index - 1;
    if (logic.readingMethod == ReadingMethod.topToBottomContinuously) {
      index = await selectImage();
    }
    if (index == null) {
      return null;
    }

    var file = await _getFileFromStream(
        readingData.loadImage(logic.order, index, logic.urls[index]));

    return persistentCurrentImage(file);
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

    var file = await _getFileFromStream(
        readingData.loadImage(logic.order, index, logic.urls[index]));

    saveImage(file);
  }

  Widget? buildEpChangeButton(ComicReadingPageLogic logic) {
    if (!readingData.hasEp) return null;
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
