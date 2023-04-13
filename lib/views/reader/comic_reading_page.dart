import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/keep_screen_on.dart';
import 'package:pica_comic/views/reader/tool_bar.dart';
import 'package:pica_comic/views/widgets/cf_image_widgets.dart';
import 'package:pica_comic/views/widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:pica_comic/tools/save_image.dart';
import '../../tools/key_down_event.dart';
import '../eh_views/eh_widgets/eh_image_provider/eh_cached_image.dart';
import 'touch_control.dart';
import 'reading_logic.dart';
import 'reading_settings.dart';

enum ReadingType { picacg, ehentai }

class ReadingPageData {
  int initialPage;
  var epsWidgets = <Widget>[];
  ListenVolumeController? listenVolume;
  ScrollManager? scrollManager;
  ReadingPageData(this.initialPage);
}

///阅读器, 同时支持picacg和ehentai
class ComicReadingPage extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  ///目标, 对于picacg是漫画id, 对于ehentai是漫画链接
  final String target;

  ///章节信息, 仅picacg,ehentai此数组为空
  final List<String> eps; //注意: eps的第一个是标题, 不是章节

  ///标题
  final String title;

  ///初始章节, 仅picacg
  final int order;

  ///画廊模型, 阅读非画廊此变量为null
  final Gallery? gallery;

  ///阅读类型
  final ReadingType type;

  ///一些会发生变更的信息, 全放logic里面会很乱
  final ReadingPageData data = ReadingPageData(0);

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
            if (logic.controller!.order == 1 && logic.controller!.index == 1) {
              appdata.history.saveReadHistory(target, 0, 0);
            } else if (logic.controller!.order == data.epsWidgets.length - 1 &&
                logic.controller!.index == logic.controller!.length) {
              appdata.history.saveReadHistory(target, 0, 0);
            } else {
              appdata.history
                  .saveReadHistory(target, logic.controller!.order, logic.controller!.index);
            }
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            if (data.listenVolume != null) {
              data.listenVolume!.stop();
            }
            if (appdata.settings[14] == "1") {
              cancelKeepScreenOn();
            }
            appdata.ehUrlsManager.saveData();
          },
          init: ComicReadingPageLogic(order),
          builder: (logic) {
            if (logic.isLoading) {
              //加载信息
              if (type == ReadingType.ehentai) {
                loadGalleryInfo(logic);
              } else {
                loadComicInfo(logic);
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
                data.listenVolume = ListenVolumeController(
                    () => logic.controller.jumpToPage(logic.index - 1),
                    () => logic.controller.jumpToPage(logic.index + 1));
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
                        buildComicView(logic),
                        Positioned(
                          top: 0,
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: GestureDetector(
                            onTapUp: (detail) {
                              if (appdata.settings[0] == "1" &&
                                  appdata.settings[9] != "4" &&
                                  !logic.tools &&
                                  detail.globalPosition.dx >
                                      MediaQuery.of(context).size.width * 0.75) {
                                logic.jumpToNextPage();
                              } else if (appdata.settings[0] == "1" &&
                                  appdata.settings[9] != "4" &&
                                  !logic.tools &&
                                  detail.globalPosition.dx <
                                      MediaQuery.of(context).size.width * 0.25) {
                                logic.jumpToLastPage();
                              } else {
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
                        buildBottomToolBar(logic, context, type == ReadingType.picacg, () {
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
                            var id = target;
                            if(type == ReadingType.ehentai){
                              id = getGalleryId(target);
                            }
                            shareImageFromDisk(downloadManager
                                .getImage(id, logic.order, logic.index - 1)
                                .path);
                          } else {
                            shareImageFromCache(logic.urls[logic.index - 1],
                                eh: type == ReadingType.ehentai);
                          }

                        }, () async {
                          if (logic.downloaded) {
                            var id = target;
                            if(type == ReadingType.ehentai){
                              id = getGalleryId(target);
                            }
                            saveImageFromDisk(downloadManager
                                .getImage(id, logic.order, logic.index - 1)
                                .path);
                          } else {
                            saveImage(logic.urls[logic.index - 1], eh: type == ReadingType.ehentai);
                          }
                        }),

                        ...buildBottoms(logic, context),

                        //顶部工具栏
                        buildTopToolBar(logic, context, title),

                        buildPageInfoText(logic, type == ReadingType.picacg, eps, context),



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

  Widget buildGallery(ComicReadingPageLogic comicReadingPageLogic) {
    return ScrollablePositionedList.builder(
      itemScrollController: comicReadingPageLogic.scrollController,
      itemPositionsListener: comicReadingPageLogic.scrollListener,
      itemCount: comicReadingPageLogic.urls.length,
      addSemanticIndexes: false,
      scrollController: comicReadingPageLogic.cont,
      itemBuilder: (context, index) {
        if (index < comicReadingPageLogic.urls.length - 1 && type == ReadingType.ehentai && !comicReadingPageLogic.downloaded) {
          precacheImage(EhCachedImageProvider(comicReadingPageLogic.urls[index + 1]), context);
        } else if (index < comicReadingPageLogic.urls.length - 1 &&
            !comicReadingPageLogic.downloaded) {
          precacheImage(
              CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index + 1])),
              context);
        } else if (index < comicReadingPageLogic.urls.length - 1 &&
            comicReadingPageLogic.downloaded) {
          var id = target;
          if(type == ReadingType.ehentai){
            id = getGalleryId(target);
          }
          precacheImage(
              FileImage(downloadManager.getImage(id, comicReadingPageLogic.order, index + 1)),
              context);
        }
        if (type == ReadingType.ehentai && ! comicReadingPageLogic.downloaded) {
          final height = Get.width * 1.42;
          return Image(
            image: EhCachedImageProvider(comicReadingPageLogic.urls[index]),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
            frameBuilder: (context, widget, i, b) {
              return SizedBox(
                height: height,
                child: widget,
              );
            },
            loadingBuilder: (context, widget, event) {
              if (event == null) {
                return widget;
              } else {
                return SizedBox(
                  height: height,
                  child: Center(
                      child: event.expectedTotalBytes != null && event.expectedTotalBytes != null
                          ? CircularProgressIndicator(
                              value: event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                              backgroundColor: Colors.white12,
                            )
                          : const CircularProgressIndicator()),
                );
              }
            },
            errorBuilder: (context, s, d) => SizedBox(
              height: height,
              child: const Center(
                child: Icon(
                  Icons.error,
                  color: Colors.white12,
                ),
              ),
            ),
          );
        }
        if (comicReadingPageLogic.downloaded) {
          var id = target;
          if(type == ReadingType.ehentai){
            id = getGalleryId(target);
          }
          return Image.file(
            downloadManager.getImage(id, comicReadingPageLogic.order, index),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
          );
        } else {
          final height = Get.width * 1.42;
          return CfCachedNetworkImage(
            imageUrl: getImageUrl(comicReadingPageLogic.urls[index]),
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fill,
            progressIndicatorBuilder: (context, s, progress) => SizedBox(
              height: height,
              child: Center(
                  child: CircularProgressIndicator(
                value: progress.progress,
                backgroundColor: Colors.white12,
              )),
            ),
            errorWidget: (context, s, d) => SizedBox(
              height: height,
              child: const Center(
                child: Icon(
                  Icons.error,
                  color: Colors.white12,
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget buildComicView(ComicReadingPageLogic comicReadingPageLogic) {
    if (appdata.settings[9] != "4") {
      return Positioned(
          top: 0,
          left: 0,
          bottom: 0,
          right: 0,
          child: AbsorbPointer(
            absorbing: comicReadingPageLogic.tools,
            child: Listener(
              //监听鼠标滚轮
              onPointerSignal: (pointerSignal) {
                if (pointerSignal is PointerScrollEvent) {
                  comicReadingPageLogic.controller.jumpToPage(pointerSignal.scrollDelta.dy > 0
                      ? comicReadingPageLogic.index + 1
                      : comicReadingPageLogic.index - 1);
                }
              },
              child: PhotoViewGallery.builder(
                reverse: appdata.settings[9] == "2",
                scrollDirection: appdata.settings[9] != "3" ? Axis.horizontal : Axis.vertical,
                itemCount: comicReadingPageLogic.urls.length + 2,
                builder: (BuildContext context, int index) {
                  if (index < comicReadingPageLogic.urls.length && type == ReadingType.ehentai && !comicReadingPageLogic.downloaded) {
                    precacheImage(
                        EhCachedImageProvider(comicReadingPageLogic.urls[index]), context);
                  } else if (index < comicReadingPageLogic.urls.length &&
                      !comicReadingPageLogic.downloaded) {
                    precacheImage(
                        CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index])),
                        context);
                  } else if (index < comicReadingPageLogic.urls.length &&
                      comicReadingPageLogic.downloaded) {
                    var id = target;
                    if(type == ReadingType.ehentai){
                      id = getGalleryId(target);
                    }
                    precacheImage(
                        FileImage(
                            downloadManager.getImage(id, comicReadingPageLogic.order, index)),
                        context);
                  }
                  if (index != 0 && index != comicReadingPageLogic.urls.length + 1) {
                    if (type == ReadingType.ehentai && !comicReadingPageLogic.downloaded) {
                      return PhotoViewGalleryPageOptions(
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        imageProvider: EhCachedImageProvider(comicReadingPageLogic.urls[index - 1]),
                        initialScale: PhotoViewComputedScale.contained,
                        heroAttributes: PhotoViewHeroAttributes(
                            tag: "$index/${comicReadingPageLogic.urls.length}"),
                      );
                    } else if (comicReadingPageLogic.downloaded) {
                      var id = target;
                      if(type == ReadingType.ehentai){
                        id = getGalleryId(target);
                      }
                      return PhotoViewGalleryPageOptions(
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        imageProvider: FileImage(downloadManager.getImage(
                            id, comicReadingPageLogic.order, index - 1)),
                        initialScale: PhotoViewComputedScale.contained,
                        heroAttributes: PhotoViewHeroAttributes(
                            tag: "$index/${comicReadingPageLogic.urls.length}"),
                      );
                    } else {
                      return PhotoViewGalleryPageOptions(
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        imageProvider: CachedNetworkImageProvider(
                            getImageUrl(comicReadingPageLogic.urls[index - 1])),
                        initialScale: PhotoViewComputedScale.contained,
                        heroAttributes: PhotoViewHeroAttributes(
                            tag: "$index/${comicReadingPageLogic.urls.length}"),
                      );
                    }
                  } else {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: const AssetImage("images/black.png"),
                    );
                  }
                },
                pageController: comicReadingPageLogic.controller,
                loadingBuilder: (context, event) => DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.black),
                  child: Center(
                    child: SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.white12,
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
                      ),
                    ),
                  ),
                ),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                onPageChanged: (i) {
                  if (i == 0) {
                    if (type == ReadingType.ehentai) {
                      comicReadingPageLogic.controller.jumpToPage(1);
                      showMessage(Get.context, "已经是第一页了");
                      return;
                    }
                    if (comicReadingPageLogic.order != 1) {
                      comicReadingPageLogic.order -= 1;
                      comicReadingPageLogic.urls.clear();
                      comicReadingPageLogic.isLoading = true;
                      comicReadingPageLogic.tools = false;
                      comicReadingPageLogic.update();
                    } else {
                      comicReadingPageLogic.controller.jumpToPage(1);
                      showMessage(Get.context, "已经是第一章了");
                    }
                  } else if (i == comicReadingPageLogic.urls.length + 1) {
                    if (type == ReadingType.ehentai) {
                      comicReadingPageLogic.controller.jumpToPage(i - 1);
                      showMessage(Get.context, "已经是最后一页了");
                      return;
                    }
                    if (comicReadingPageLogic.order != eps.length - 1) {
                      comicReadingPageLogic.order += 1;
                      comicReadingPageLogic.urls.clear();
                      comicReadingPageLogic.isLoading = true;
                      comicReadingPageLogic.tools = false;
                      comicReadingPageLogic.update();
                    } else {
                      comicReadingPageLogic.controller.jumpToPage(i - 1);
                      showMessage(Get.context, "已经是最后一章了");
                    }
                  } else {
                    comicReadingPageLogic.index = i;
                    comicReadingPageLogic.update();
                  }
                },
              ),
            ),
          ));
    } else {
      return Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: AbsorbPointer(
            absorbing: comicReadingPageLogic.tools,
            child: InteractiveViewer(
                transformationController: comicReadingPageLogic.transformationController,
                maxScale: GetPlatform.isDesktop ? 1.0 : 2.5,
                child: AbsorbPointer(
                  absorbing: true, //使用控制器控制滚动
                  child: SizedBox(
                      width: MediaQuery.of(Get.context!).size.width,
                      height: MediaQuery.of(Get.context!).size.height,
                      child: buildGallery(comicReadingPageLogic)),
                )),
          ));
    }
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
                  color: Colors.white70,
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
                  color: Colors.white70,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(Get.context!).size.height / 2 - 10,
              child: Align(
                alignment: Alignment.topCenter,
                child: network.status
                    ? Text(network.message)
                    : const Text(
                        "网络错误",
                        style: TextStyle(
                          color: Colors.white70,
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
    comicReadingPageLogic.downloaded = downloadManager.downloaded.contains(target);
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
      downloadManager.getPicEpLength(target, comicReadingPageLogic.order).then((i) {
        for (int p = 0; p < i; p++) {
          comicReadingPageLogic.urls.add("");
        }
        comicReadingPageLogic.change();
      });
    } else {
      network.getComicContent(target, comicReadingPageLogic.order).then((l) {
        comicReadingPageLogic.urls = l;
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
    await appdata.ehUrlsManager.readData();
    ehNetwork.loadGalleryPages(gallery!).then((b) {
      if (b) {
        logic.urls = gallery!.urls;
      }
      logic.change();
    });
  }
}
