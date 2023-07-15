import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/tools/keep_screen_on.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import 'package:pica_comic/views/reader/tool_bar.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../tools/key_down_event.dart';
import 'eps_view.dart';
import 'image_view.dart';
import 'touch_control.dart';
import 'reading_logic.dart';
import 'reading_settings.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

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
  ReadingPageData(this.initialPage, this.target, this.type, this.eps);
}

///阅读器
class ComicReadingPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ///目标, 对于picacg,jm,hitomi,绅士漫画是漫画id, 对于ehentai是漫画链接
  final String target;

  ///章节信息, picacg为各章节名称 ,ehentai, hitomi此数组为空, jm为各章节id
  final List<String> eps; //注意: eps的第一个是标题, 不是章节

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

  ///一些会发生变更的信息, 全放logic里面会很乱
  late final ReadingPageData data = ReadingPageData(
      0,
      (type == ReadingType.jm && eps.isNotEmpty)
          ? eps.elementAtOrNull(order - 1) ?? eps[0]
          : target,
      type,
      eps);

  ///阅读Hitomi画廊时使用的图片数据
  ///
  /// 仅Hitomi有效, 其它都为null
  final List<HitomiFile>? images;

  ComicReadingPage.picacg(this.target, this.order, this.eps, this.title,
      {super.key, int initialPage = 0})
      : gallery = null,
        type = ReadingType.picacg,
        images = null {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.ehentai(this.target, this.gallery, {super.key, int initialPage = 0})
      : eps = [],
        title = gallery!.title,
        order = 0,
        type = ReadingType.ehentai,
        images = null {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.jmComic(this.target, this.title, this.eps, this.order,
      {super.key, int initialPage = 0})
      : type = ReadingType.jm,
        gallery = null,
        images = null {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.hitomi(this.target, this.title, this.images, {super.key, int initialPage = 0})
      : eps = [],
        order = 0,
        type = ReadingType.hitomi,
        gallery = null {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.htmanga(this.target, this.title, {super.key, int initialPage = 0})
      : eps = [],
        order = 0,
        gallery = null,
        type = ReadingType.htmanga,
        images = null {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ComicReadingPageLogic>(
        initState: (logic) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          if (appdata.settings[14] == "1") {
            setKeepScreenOn();
          }
          //进入阅读器时清除内存中的缓存, 并且增大限制
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024;
        },
        dispose: (logic) {
          //清除缓存并减小最大缓存
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.maximumSizeBytes = 100 * 1024 * 1024;
          //保存历史记录
          if (type.hasEps) {
            if (logic.controller!.order == 1 && logic.controller!.index == 1) {
              appdata.history.saveReadHistory(target, 0, 0);
            } else {
              if (logic.controller!.order == data.epsWidgets.length - 1 &&
                  logic.controller!.index == logic.controller!.length) {
                appdata.history.saveReadHistory(target, 0, 0);
              } else {
                appdata.history
                    .saveReadHistory(target, logic.controller!.order, logic.controller!.index);
              }
            }
          } else {
            if (logic.controller!.index == 1 ||
                logic.controller!.index == logic.controller!.length) {
              appdata.history.saveReadHistory(target, 0, 0);
            } else {
              appdata.history.saveReadHistory(target, 1, logic.controller!.index);
            }
          }

          SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          SystemChrome.setPreferredOrientations(DeviceOrientation.values);
          if (data.listenVolume != null) {
            data.listenVolume!.stop();
          }
          if (appdata.settings[14] == "1") {
            cancelKeepScreenOn();
          }
          MyCacheManager().saveData();
        },
        builder: (logic) {
          return Scaffold(
              backgroundColor: Colors.black,
              endDrawerEnableOpenDragGesture: false,
              key: _scaffoldKey,
              endDrawer: Drawer(
                child: buildEpsView(),
              ),
              floatingActionButton: () {
                if(!type.hasEps)  return null;
                switch (logic.showFloatingButtonValue) {
                  case -1:
                    return FloatingActionButton(
                      onPressed: () => logic.jumpToLastChapter(),
                      child: const Icon(Icons.arrow_back_ios_outlined),
                    );
                  case 0:
                    return null;
                  case 1:
                    return FloatingActionButton(
                      onPressed: () => logic.jumpToNextChapter(),
                      child: const Icon(Icons.arrow_forward_ios_outlined),
                    );
                }
              }.call(),
              body: GetBuilder<ComicReadingPageLogic>(builder: (logic) {
                if (logic.isLoading) {
                  //加载信息
                  if (type == ReadingType.ehentai) {
                    var ehLoadingInfo = EhLoadingInfo();
                    ehLoadingInfo.total = int.parse(gallery!.maxPage);
                    loadGalleryInfo(logic, ehLoadingInfo);
                    return DecoratedBox(
                      decoration: const BoxDecoration(color: Colors.black),
                      child: Center(
                        child: SizedBox(
                          height: 100,
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(
                                height: 5,
                              ),
                              ValueListenableBuilder<int>(
                                  valueListenable: ehLoadingInfo.current,
                                  builder: (context, current, widget) {
                                    return Text(
                                      "$current/${ehLoadingInfo.total}",
                                      style: const TextStyle(color: Colors.white),
                                    );
                                  }),
                              const SizedBox(
                                height: 5,
                              ),
                              FilledButton(onPressed: () => Get.back(), child: Text("退出".tr))
                            ],
                          ),
                        ),
                      ),
                    );
                  } else if (type == ReadingType.picacg) {
                    loadComicInfo(logic);
                  } else if (type == ReadingType.jm) {
                    loadJmComicInfo(logic);
                  } else if(type == ReadingType.hitomi){
                    loadHitomiData(logic);
                  }else{
                    loadHtmangaData(logic);
                  }
                  return const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (logic.urls.isNotEmpty) {
                  //检查传入的初始页面值, 并进行跳转
                  if (data.initialPage != 0) {
                    int i = data.initialPage;
                    Future.delayed(const Duration(milliseconds: 300), () => logic.jumpToPage(i));
                    //重置为0, 避免切换章节时再次跳转
                    data.initialPage = 0;
                  }

                  //监听音量键
                  if (appdata.settings[7] == "1") {
                    if (appdata.settings[9] != "4") {
                      data.listenVolume = ListenVolumeController(
                          () => logic.jumpToLastPage(), () => logic.jumpToNextPage());
                    } else {
                      data.listenVolume = ListenVolumeController(
                          () => logic.cont.jumpTo(logic.cont.position.pixels - 400),
                          () => logic.cont.jumpTo(logic.cont.position.pixels + 400));
                    }
                    data.listenVolume!.listenVolumeChange();
                  } else if (data.listenVolume != null) {
                    data.listenVolume!.stop();
                    data.listenVolume = null;
                  }

                  //当使用自上而下(连续)方式阅读时, 使用ScrollManager管理滑动
                  if (appdata.settings[9] == "4") {
                    //logic.cont = ScrollController();
                    data.scrollManager = ScrollManager(logic.cont);
                  }
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
                      child: Listener(
                        onPointerMove: (details) {
                          if (logic.currentScale < 1.05) return;
                          if (appdata.settings[9] == "4" && data.scrollManager!.fingers != 2) {
                            data.scrollManager!.addOffset(details.delta.dy /
                                logic.transformationController.value.getMaxScaleOnAxis());
                          }
                        },
                        onPointerUp: appdata.settings[9] == "4"
                            ? (details) => data.scrollManager!.tapUp(details)
                            : null,
                        onPointerDown: appdata.settings[9] == "4"
                            ? (details) => data.scrollManager!.tapDown(details)
                            : null,
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
                            if (Get.isDarkMode && appdata.settings[18] == "1")
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
                            buildTapDownListener(logic, context),
                            //底部工具栏
                            buildBottomToolBar(logic, context,
                                type.hasEps, () {
                              if (MediaQuery.of(context).size.width > 600) {
                                showSideBar(context, buildEpsView(),
                                    title: null, useSurfaceTintColor: true, width: 400);
                              } else {
                                showModalBottomSheet(
                                    context: context,
                                    useSafeArea: false,
                                    builder: (context) {
                                      return buildEpsView();
                                    });
                              }
                            }, () async {
                              if (logic.downloaded) {
                                var id = data.target;
                                if (type == ReadingType.ehentai) {
                                  id = getGalleryId(data.target);
                                }
                                if (type == ReadingType.jm) {
                                  id = "jm$target";
                                } else if (type == ReadingType.hitomi) {
                                  id = "hitomi$target";
                                } else if(type == ReadingType.htmanga){
                                  id = "Ht$target";
                                }
                                shareImageFromDisk(downloadManager
                                    .getImage(id, logic.order, logic.index - 1)
                                    .path);
                              } else {
                                shareImageFromCache(
                                    type == ReadingType.hitomi
                                        ? logic.images[logic.index - 1].hash
                                        : logic.urls[logic.index - 1],
                                    data.target,
                                    true);
                              }
                            }, () async {
                              if (logic.downloaded) {
                                var id = data.target;
                                if (type == ReadingType.ehentai) {
                                  id = getGalleryId(data.target);
                                }
                                if (type == ReadingType.jm) {
                                  id = "jm$target";
                                } else if (type == ReadingType.hitomi) {
                                  id = "hitomi$target";
                                } else if(type == ReadingType.htmanga){
                                  id = "Ht$target";
                                }
                                saveImageFromDisk(downloadManager
                                    .getImage(id, logic.order, logic.index - 1)
                                    .path);
                              } else {
                                saveImage(
                                    type == ReadingType.hitomi
                                        ? logic.images[logic.index - 1].hash
                                        : logic.urls[logic.index - 1],
                                    data.target,reading: true);
                              }
                            }),

                            ...buildButtons(logic, context),

                            //顶部工具栏
                            buildTopToolBar(logic, context, title),

                            buildPageInfoText(
                                logic,
                                type.hasEps,
                                eps,
                                context,
                                jm: type == ReadingType.jm),

                            //设置
                            buildSettingWindow(logic, context),
                          ],
                        ),
                      ));
                } else {
                  return buildErrorView(logic, context);
                }
              }),
            );
        });
  }

  Widget buildErrorView(ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
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
                onPressed: () => Get.back(),
              ),
            ),
            Positioned(
              top: MediaQuery.of(Get.context!).size.height / 2 - 80,
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
              top: MediaQuery.of(Get.context!).size.height / 2 - 10,
              child: Align(
                alignment: Alignment.topCenter,
                child: Text(
                  data.message ?? "未知错误".tr,
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(Get.context!).size.height / 2 + 30,
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
                            child: Text("重试".tr),
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                            child: FilledButton(
                          onPressed: () {
                            if (!type.hasEps) {
                              showMessage(context, "没有其它章节".tr);
                              return;
                            }
                            if (MediaQuery.of(context).size.width > 600) {
                              showSideBar(context, buildEpsView(),
                                  title: null, useSurfaceTintColor: true, width: 400);
                            } else {
                              showModalBottomSheet(
                                  context: context,
                                  useSafeArea: false,
                                  builder: (context) {
                                    return buildEpsView();
                                  });
                            }
                          },
                          child: Text("切换章节".tr),
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
        if (downloadedItem.downloadedChapters.contains(comicReadingPageLogic.order - 1)) {
          comicReadingPageLogic.downloaded = true;
          epLength = await downloadManager.getEpLength(data.target, comicReadingPageLogic.order);
        } else {
          comicReadingPageLogic.downloaded = false;
        }
      } else {
        comicReadingPageLogic.downloaded = false;
      }
    } catch (e) {
      showMessage(Get.context, "数据丢失, 将从网络获取漫画");
      comicReadingPageLogic.downloaded = false;
    }
    comicReadingPageLogic.index = 1;
    comicReadingPageLogic.tools = false;
    if (data.epsWidgets.isEmpty) {
      data.epsWidgets.add(
        ListTile(
          leading: Icon(
            Icons.library_books,
            color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
          ),
          title: Text("章节".tr),
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
            Navigator.pop(Get.context!);
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
      network.getComicContent(data.target, comicReadingPageLogic.order).then((l) {
        if (l.error) {
          data.message = l.errorMessageWithoutNull;
        } else {
          comicReadingPageLogic.urls = List.generate(l.data.length, (index) => getImageUrl(l.data[index]));
        }
        comicReadingPageLogic.change();
      });
    }
  }

  void loadGalleryInfo(ComicReadingPageLogic logic, EhLoadingInfo info) async {
    try {
      if (downloadManager.downloadedGalleries.contains(getGalleryId(gallery!.link))) {
        logic.downloaded = true;
        for (int i = 0;
            i < await downloadManager.getComicLength(getGalleryId(gallery!.link));
            i++) {
          logic.urls.add("");
        }
        logic.change();
        return;
      }
    } catch (e) {
      showMessage(Get.context, "数据丢失, 将从网络获取漫画");
      logic.downloaded = false;
    }
    info.current.value++;
    await for (var i in EhNetwork().loadGalleryPages(gallery!)) {
      if (i == -1) {
        logic.urls = gallery!.urls;
        logic.change();
        return;
      } else if (i == 0) {
        data.message = "网络错误".tr;
        logic.change();
        return;
      } else {
        info.current.value = i;
      }
    }
  }

  void loadJmComicInfo(ComicReadingPageLogic comicReadingPageLogic) async {
    int? epLength;
    try {
      if (downloadManager.downloadedJmComics.contains("jm$target")) {
        var downloadedItem = await downloadManager.getJmComicFormId("jm$target");
        if (downloadedItem.downloadedChapters.contains(comicReadingPageLogic.order - 1)) {
          comicReadingPageLogic.downloaded = true;
          data.downloadedEps = downloadedItem.downloadedChapters;
          epLength = await downloadManager.getEpLength("jm$target", comicReadingPageLogic.order);
        } else {
          comicReadingPageLogic.downloaded = false;
        }
      } else {
        comicReadingPageLogic.downloaded = false;
      }
    } catch (e) {
      showMessage(Get.context, "数据丢失, 将从网络获取漫画");
      comicReadingPageLogic.downloaded = false;
    }
    comicReadingPageLogic.index = 1;
    comicReadingPageLogic.tools = false;
    if (data.epsWidgets.isEmpty) {
      data.epsWidgets.add(
        ListTile(
          leading: Icon(
            Icons.library_books,
            color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
          ),
          title: Text(
            "章节".tr,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }
    if (data.epsWidgets.length == 1) {
      for (int i = 0; i < eps.length; i++) {
        data.epsWidgets.add(ListTile(
          title: Text("${"第 @c 章".trParams({
                "c": (i + 1).toString()
              })}${(comicReadingPageLogic.order == i + 1) ? "(当前)".tr : ""}"),
          onTap: () {
            if (comicReadingPageLogic.order != i + 1) {
              comicReadingPageLogic.order = i + 1;
              data.target = eps[i];
              data.epsWidgets.clear();
              comicReadingPageLogic.urls.clear();
              comicReadingPageLogic.change();
            }
            Navigator.pop(Get.context!);
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
      data.message = res.errorMessage ?? "网络错误".tr;
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
      showMessage(Get.context, "数据丢失, 将从网络获取漫画");
      logic.downloaded = false;
    }
    var res = await HtmangaNetwork().getImages(target);
    if(res.error){
      data.message = res.errorMessage;
    }else{
      logic.urls = res.data;
    }
    logic.isLoading = false;
    logic.update();
  }

  Widget buildEpsView() {
    return EpsView(type, eps, data);
  }
}

class EhLoadingInfo {
  int total = 1;
  var current = ValueNotifier<int>(0);
}

