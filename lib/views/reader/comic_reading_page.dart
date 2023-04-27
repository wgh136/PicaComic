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
import '../../tools/key_down_event.dart';
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

  ///picacg和禁漫有效
  final int order;

  ///画廊模型, 阅读非画廊此变量为null
  final Gallery? gallery;

  ///阅读类型
  final ReadingType type;

  ///一些会发生变更的信息, 全放logic里面会很乱
  late final ReadingPageData data = ReadingPageData(0, target);

  ComicReadingPage.picacg(this.target, this.order, this.eps, this.title,
      {super.key, int initialPage = 0})
      : gallery = null,
        type = ReadingType.picacg {
    data.initialPage = initialPage;
  }

  ComicReadingPage.ehentai(this.target, this.gallery, {super.key, int initialPage = 0})
      : eps = [],
        title = gallery!.title,
        order = 0,
        type = ReadingType.ehentai {
    data.initialPage = initialPage;
  }

  ComicReadingPage.jmComic(this.target, this.title, this.eps, this.order, {super.key, int initialPage = 0})
    : type = ReadingType.jm,
      gallery = null {
    data.initialPage = initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      endDrawerEnableOpenDragGesture: false,
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: ListView(
          children: data.epsWidgets,
        ),
      ),
      body: GetBuilder<ComicReadingPageLogic>(
          initState: (logic) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
            if (appdata.settings[14] == "1") {
              setKeepScreenOn();
            }
          },
          dispose: (logic) {
            if(type != ReadingType.jm) {
              if (logic.controller!.order == 1 && logic.controller!.index == 1) {
                appdata.history.saveReadHistory(data.target, 0, 0);
              } else {
                if (logic.controller!.order == data.epsWidgets.length - 1 &&
                    logic.controller!.index == logic.controller!.length) {
                  appdata.history.saveReadHistory(data.target, 0, 0);
                } else {
                  appdata.history
                      .saveReadHistory(data.target, logic.controller!.order, logic.controller!.index);
                }
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
          init: ComicReadingPageLogic(order, data),
          builder: (logic) {
            if (logic.isLoading) {
              //加载信息
              if (type == ReadingType.ehentai) {
                loadGalleryInfo(logic);
              } else if(type == ReadingType.picacg){
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
                Future.delayed(
                    const Duration(milliseconds: 300), () => logic.jumpToPage(i));
                //重置为0, 避免切换章节时再次跳转
                data.initialPage = 0;
              }

              //监听音量键
              if (appdata.settings[7] == "1") {
                if(appdata.settings[9] != "4"){
                  data.listenVolume = ListenVolumeController(
                      () => logic.controller.jumpToPage(logic.index - 1),
                      () => logic.controller.jumpToPage(logic.index + 1));
                }else{
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
                        buildComicView(logic, type, data.target, eps),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTapUp: (detail) {
                              bool flag = false;
                              bool flag2 = false;
                              if(appdata.settings[0] == "1" && appdata.settings[9] != "4" && !logic.tools){
                                switch(appdata.settings[9]){
                                  case "1":
                                    detail.globalPosition.dx > MediaQuery.of(context).size.width * 0.75?logic.jumpToNextPage():flag=true;
                                    detail.globalPosition.dx < MediaQuery.of(context).size.width * 0.25?logic.jumpToLastPage():flag2=true;
                                    break;
                                  case "2":
                                    detail.globalPosition.dx > MediaQuery.of(context).size.width * 0.75?logic.jumpToLastPage():flag=true;
                                    detail.globalPosition.dx < MediaQuery.of(context).size.width * 0.25?logic.jumpToNextPage():flag2=true;
                                    break;
                                  case "3":
                                    detail.globalPosition.dy > MediaQuery.of(context).size.height * 0.75?logic.jumpToNextPage():flag=true;
                                    detail.globalPosition.dy < MediaQuery.of(context).size.height * 0.25?logic.jumpToLastPage():flag2=true;
                                    break;
                                }
                              }else{
                                flag = flag2 = true;
                              }
                              if(flag&&flag2){
                                if (logic.showSettings) {
                                  logic.showSettings = false;
                                  logic.update();
                                  return;
                                }
                                logic.tools = !logic.tools;
                                logic.update();
                                if (logic.tools) {
                                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                                } else {
                                  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
                                }
                              }
                            },
                          ),
                        ),
                        //底部工具栏
                        buildBottomToolBar(logic, context, type != ReadingType.ehentai, () {
                          if (MediaQuery.of(context).size.width > 600) {
                            _scaffoldKey.currentState!.openEndDrawer();
                          } else {
                            showModalBottomSheet(
                                context: context,
                                useSafeArea: true,
                                builder: (context) {
                                  return ListView(
                                    children: data.epsWidgets,
                                  );
                                });
                          }
                        }, () async {
                          if (logic.downloaded) {
                            var id = data.target;
                            if(type == ReadingType.ehentai){
                              id = getGalleryId(data.target);
                            }
                            shareImageFromDisk(downloadManager
                                .getImage(id, logic.order, logic.index - 1)
                                .path);
                          } else {
                            shareImageFromCache(logic.urls[logic.index - 1],data.target,
                                eh: type == ReadingType.ehentai,
                                jm: type == ReadingType.jm);
                          }

                        }, () async {
                          if (logic.downloaded) {
                            var id = data.target;
                            if(type == ReadingType.ehentai){
                              id = getGalleryId(data.target);
                            }
                            saveImageFromDisk(downloadManager
                                .getImage(id, logic.order, logic.index - 1)
                                .path);
                          } else {
                            saveImage(logic.urls[logic.index - 1],data.target,
                                eh: type == ReadingType.ehentai,
                                jm: type == ReadingType.jm
                            );
                          }
                        }),

                        ...buildButtons(logic, context),

                        //顶部工具栏
                        buildTopToolBar(logic, context, title),

                        buildPageInfoText(logic, type != ReadingType.ehentai, eps, context, jm: type == ReadingType.jm),

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
                  data.message??"网络错误",
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
      downloadManager.getPicEpLength(data.target, comicReadingPageLogic.order).then((i) {
        for (int p = 0; p < i; p++) {
          comicReadingPageLogic.urls.add("");
        }
        comicReadingPageLogic.change();
      });
    } else {
      network.getComicContent(data.target, comicReadingPageLogic.order).then((l) {
        comicReadingPageLogic.urls = l;
        if(l.isEmpty){
          data.message = network.status?network.message:"网络错误";
        }
        comicReadingPageLogic.change();
      });
    }
  }

  void loadGalleryInfo(ComicReadingPageLogic logic) async {
    if(downloadManager.downloadedGalleries.contains(getGalleryId(gallery!.link))){
      logic.downloaded = true;
      for(int i = 0;i<await downloadManager.getEhPages(getGalleryId(gallery!.link));i++){
        logic.urls.add("");
      }
      logic.change();
      return;
    }
    await EhImageUrlsManager().readData();
    ehNetwork.loadGalleryPages(gallery!).then((b) {
      if (b) {
        logic.urls = gallery!.urls;
      }else{
        data.message = ehNetwork.status?ehNetwork.message:"网络错误";
      }
      logic.change();
    });
  }

  void loadJmComicInfo(ComicReadingPageLogic comicReadingPageLogic) async{
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
      for (int i = 0; i < eps.length; i++) {
        data.epsWidgets.add(ListTile(
          title: Text("第${i+1}章${(eps[i] == data.target)?"(当前)":""}"),
          onTap: () {
            if (eps[i] != data.target) {
              comicReadingPageLogic.order = i;
              data.target = eps[i];
              comicReadingPageLogic.urls.clear();
              comicReadingPageLogic.change();
            }
            Navigator.pop(Get.context!);
          },
        ));
      }
    }
    var res = await jmNetwork.getChapter(data.target);
    if(res.error){
      data.message = res.errorMessage??"网络错误";
    }else{
      comicReadingPageLogic.urls = res.data;
    }
    comicReadingPageLogic.isLoading = false;
    comicReadingPageLogic.update();
  }
}
