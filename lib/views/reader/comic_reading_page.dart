import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/eh_network/get_gallery_id.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/keep_screen_on.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_image_provider/cache_manager.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_image_provider/find_eh_image_real_url.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import 'package:pica_comic/views/reader/tool_bar.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import '../../tools/key_down_event.dart';
import 'eps_view.dart';
import 'image_view.dart';
import 'touch_control.dart';
import 'reading_logic.dart';
import 'reading_settings.dart';

class ReadingPageData {
  int initialPage;
  var epsWidgets = <Widget>[];
  ListenVolumeController? listenVolume;
  ScrollManager? scrollManager;
  String? message;
  String target;
  ReadingPageData(this.initialPage, this.target);
}

///阅读器, 同时支持picacg和ehentai
class ComicReadingPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ///目标, 对于picacg和jm是漫画id, 对于ehentai是漫画链接
  final String target;

  ///章节信息, picacg为各章节名称 ,ehentai此数组为空, jm为各章节id
  final List<String> eps; //注意: eps的第一个是标题, 不是章节

  ///标题
  final String title;

  ///picacg和禁漫有效, e-hentai为0
  ///
  /// 这里是初始值, 变量在logic中
  ///
  /// 注意: **从1开始**
  ///
  /// 当访问下载相关的api时, 务必注意对于禁漫需要加1
  final int order;

  ///画廊模型, 阅读非画廊此变量为null
  final Gallery? gallery;

  ///阅读类型
  final ReadingType type;

  ///一些会发生变更的信息, 全放logic里面会很乱
  late final ReadingPageData data = ReadingPageData(0, (type==ReadingType.jm&&eps.isNotEmpty)?eps[order-1]:target);

  ComicReadingPage.picacg(this.target, this.order, this.eps, this.title,
      {super.key, int initialPage = 0})
      : gallery = null,
        type = ReadingType.picacg {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.ehentai(this.target, this.gallery, {super.key, int initialPage = 0})
      : eps = [],
        title = gallery!.title,
        order = 0,
        type = ReadingType.ehentai {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  ComicReadingPage.jmComic(this.target, this.title, this.eps, this.order,
      {super.key, int initialPage = 0})
      : type = ReadingType.jm,
        gallery = null {
    data.initialPage = initialPage;
    Get.put(ComicReadingPageLogic(order, data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      endDrawerEnableOpenDragGesture: false,
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: buildEpsView(),
      ),
      body: GetBuilder<ComicReadingPageLogic>(
          initState: (logic) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
            if (appdata.settings[14] == "1") {
              setKeepScreenOn();
            }
          },
          dispose: (logic) {
            //保存历史记录
            if(type != ReadingType.ehentai) {
              if (logic.controller!.order == 1 && logic.controller!.index == 1) {
                appdata.history.saveReadHistory(target, 0, 0);
              } else {
                if (logic.controller!.order == data.epsWidgets.length - 1 &&
                    logic.controller!.index == logic.controller!.length) {
                  appdata.history.saveReadHistory(target, 0, 0);
                } else {
                  appdata.history.saveReadHistory(
                      target, logic.controller!.order, logic.controller!.index);
                }
              }
            }else{
              if(logic.controller!.index == 1 || logic.controller!.index == logic.controller!.length){
                appdata.history.saveReadHistory(target, 0, 0);
              }else{
                appdata.history.saveReadHistory(
                    target, 1, logic.controller!.index);
              }
            }

            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            if (data.listenVolume != null) {
              data.listenVolume!.stop();
            }
            if (appdata.settings[14] == "1") {
              cancelKeepScreenOn();
            }
            EhImageUrlsManager().saveData();
            MyCacheManager().saveData();
          },
          builder: (logic) {
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
                          const SizedBox(height: 5,),
                          ValueListenableBuilder<int>(
                            valueListenable: ehLoadingInfo.current,
                            builder: (context,current,widget){
                              return Text("已加载$current/${ehLoadingInfo.total}", style: const TextStyle(color: Colors.white),);
                            }
                          ),
                          const SizedBox(height: 5,),
                          FilledButton(onPressed: ()=>Get.back(), child: const Text("退出"))
                        ],
                      ),
                    ),
                  ),
                );
              } else if (type == ReadingType.picacg) {
                loadComicInfo(logic);
              } else {
                loadJmComicInfo(logic);
              }
              return const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (logic.urls.isNotEmpty || logic.downloaded) {
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
                      () => logic.jumpToLastPage(),
                      () => logic.jumpToNextPage());
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
                      if (appdata.settings[9] == "4" && data.scrollManager!.fingers != 2) {
                        data.scrollManager!.addOffset(details.delta.dy /
                            logic.transformationController.value.getMaxScaleOnAxis());
                      }
                    },
                    onPointerUp: appdata.settings[9] == "4"
                        ? (details) => data.scrollManager!.fingers--
                        : null,
                    onPointerDown: appdata.settings[9] == "4"
                        ? (details) => data.scrollManager!.fingers++
                        : null,
                    child: Stack(
                      children: [
                        buildComicView(logic, type, (logic.downloaded&&type==ReadingType.jm)?"jm$target":data.target, eps),
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
                        buildBottomToolBar(logic, context, type != ReadingType.ehentai, () {
                          if (MediaQuery.of(context).size.width > 600) {
                            showSideBar(context, buildEpsView(), title: null, useSurfaceTintColor: true, width: 400);
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
                            if(type == ReadingType.jm){
                              id = "jm$target";
                            }
                            shareImageFromDisk(
                                downloadManager.getImage(id, logic.order, logic.index - 1).path);
                          } else {
                            shareImageFromCache(logic.urls[logic.index - 1], data.target,
                                eh: type == ReadingType.ehentai, jm: type == ReadingType.jm);
                          }
                        }, () async {
                          if (logic.downloaded) {
                            var id = data.target;
                            if (type == ReadingType.ehentai) {
                              id = getGalleryId(data.target);
                            }
                            if(type == ReadingType.jm){
                              id = "jm$target";
                            }
                            saveImageFromDisk(
                                downloadManager.getImage(id, logic.order, logic.index - 1).path);
                          } else {
                            saveImage(logic.urls[logic.index - 1], data.target,
                                eh: type == ReadingType.ehentai, jm: type == ReadingType.jm);
                          }
                        }),

                        ...buildButtons(logic, context),

                        //顶部工具栏
                        buildTopToolBar(logic, context, title),

                        buildPageInfoText(logic, type != ReadingType.ehentai, eps, context,
                            jm: type == ReadingType.jm),

                        //设置
                        buildSettingWindow(logic, context),
                      ],
                    ),
                  ));
            } else {
              return buildErrorView(logic);
            }
          }),
    );
  }

  Widget buildErrorView(ComicReadingPageLogic comicReadingPageLogic) {
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
                  data.message ?? "网络错误",
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
                    width: 100,
                    height: 40,
                    child: FilledButton(
                      onPressed: () {
                        data.epsWidgets.clear();
                        comicReadingPageLogic.change();
                      },
                      child: const Text("重试"),
                    ),
                  )),
            ),
          ],
        )));
  }

  void loadComicInfo(ComicReadingPageLogic comicReadingPageLogic) {
    comicReadingPageLogic.downloaded = downloadManager.downloaded.contains(data.target);
    comicReadingPageLogic.index = 1;
    comicReadingPageLogic.tools = false;
    if (data.epsWidgets.isEmpty) {
      data.epsWidgets.add(
        ListTile(
          leading: Icon(
            Icons.library_books,
            color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
          ),
          title: const Text("章节"),
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
    if (comicReadingPageLogic.downloaded) {
      downloadManager.getEpLength(data.target, comicReadingPageLogic.order).then((i) {
        for (int p = 0; p < i; p++) {
          comicReadingPageLogic.urls.add("");
        }
        comicReadingPageLogic.change();
      });
    } else {
      network.getComicContent(data.target, comicReadingPageLogic.order).then((l) {
        comicReadingPageLogic.urls = l;
        if (l.isEmpty) {
          data.message = network.status ? network.message : "网络错误";
        }
        comicReadingPageLogic.change();
      });
    }
  }

  void loadGalleryInfo(ComicReadingPageLogic logic, EhLoadingInfo info) async {
    if (downloadManager.downloadedGalleries.contains(getGalleryId(gallery!.link))) {
      logic.downloaded = true;
      for (int i = 0; i < await downloadManager.getEhPages(getGalleryId(gallery!.link)); i++) {
        logic.urls.add("");
      }
      logic.change();
      return;
    }
    await EhImageUrlsManager().readData();
    await for (var i in ehNetwork.loadGalleryPages(gallery!)){
      if(i == 1){
        logic.urls = gallery!.urls;
        logic.change();
      }else if(i == 0){
        data.message = ehNetwork.status ? ehNetwork.message : "网络错误";
        logic.change();
      }else{
        info.current.value++;
      }
    }
  }

  void loadJmComicInfo(ComicReadingPageLogic comicReadingPageLogic) async {
    comicReadingPageLogic.downloaded = downloadManager.downloadedJmComics.contains("jm$target");
    comicReadingPageLogic.index = 1;
    comicReadingPageLogic.tools = false;
    if (data.epsWidgets.isEmpty) {
      data.epsWidgets.add(
        ListTile(
          leading: Icon(
            Icons.library_books,
            color: Theme.of(Get.context!).colorScheme.onSecondaryContainer,
          ),
          title: const Text("章节", style: TextStyle(fontSize: 18),),
        ),
      );
    }
    if (data.epsWidgets.length == 1) {
      for (int i = 0; i < eps.length; i++) {
        data.epsWidgets.add(ListTile(
          title: Text("第${i + 1}章${(comicReadingPageLogic.order == i+1) ? "(当前)" : ""}"),
          onTap: () {
            if (comicReadingPageLogic.order != i+1) {
              comicReadingPageLogic.order = i+1;
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
    if (comicReadingPageLogic.downloaded) {
      downloadManager.getEpLength("jm$target", comicReadingPageLogic.order).then((i) {
        for (int p = 0; p < i; p++) {
          comicReadingPageLogic.urls.add("");
        }
        comicReadingPageLogic.change();
      });
      return;
    }
    var res = await jmNetwork.getChapter(data.target);
    if (res.error) {
      data.message = res.errorMessage ?? "网络错误";
    } else {
      comicReadingPageLogic.urls = res.data;
    }
    comicReadingPageLogic.isLoading = false;
    comicReadingPageLogic.update();
  }

  Widget buildEpsView(){
    return EpsView(type, eps, data);
  }
}

class EhLoadingInfo{
  int total = 1;
  var current = ValueNotifier<int>(0);
}