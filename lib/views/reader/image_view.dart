import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/views/hitomi_views/image_loader/hitomi_cached_image_provider.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:flutter/material.dart';
import '../../base.dart';
import '../../foundation/image_loader/cached_image.dart';
import '../../network/eh_network/get_gallery_id.dart';
import '../../network/picacg_network/methods.dart';
import '../eh_views/eh_widgets/eh_image_provider/eh_cached_image.dart';
import '../jm_views/jm_image_provider/jm_cached_image.dart';
import '../widgets/image.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:get/get.dart';
import 'reading_type.dart';
import 'package:pica_comic/tools/translations.dart';

Map<int, PhotoViewController> _controllers = {};

ImageProvider createImageProvider(ReadingType type, ComicReadingPageLogic logic,
    int index, String target){
  ImageProvider image;

  if (type == ReadingType.ehentai && !logic.downloaded) {
    image = EhCachedImageProvider(logic.urls[index]);
  } else if (type == ReadingType.hitomi &&
      !logic.downloaded) {
    image = HitomiCachedImageProvider(
        logic.images[index], target);
  } else if (type == ReadingType.picacg &&
      !logic.downloaded) {
    image =
        CachedImageProvider(getImageUrl(logic.urls[index]));
  } else if (type == ReadingType.jm && !logic.downloaded) {
    image =
        JmCachedImageProvider(logic.urls[index], target);
  } else if (type == ReadingType.htmanga &&
      !logic.downloaded) {
    image = CachedImageProvider(logic.urls[index]);
  } else {
    var id = target;
    if (type == ReadingType.ehentai) {
      id = getGalleryId(target);
    } else if (type == ReadingType.hitomi) {
      id = "hitomi$target";
    } else if (type == ReadingType.htmanga) {
      id = "Ht$target";
    }
    image = FileImage(
        downloadManager.getImage(id, logic.order, index));
  }

  return image;
}

///构建从上至下(连续)阅读方式
Widget buildGallery(ComicReadingPageLogic comicReadingPageLogic,
    ReadingType type, String target) {
  return ScrollablePositionedList.builder(
    itemScrollController: comicReadingPageLogic.scrollController,
    itemPositionsListener: comicReadingPageLogic.scrollListener,
    itemCount: comicReadingPageLogic.urls.length,
    addSemanticIndexes: false,
    scrollController: comicReadingPageLogic.cont,
    physics: (comicReadingPageLogic.noScroll ||
            comicReadingPageLogic.currentScale > 1.05)
        ? const NeverScrollableScrollPhysics()
        : const BouncingScrollPhysics(),
    itemBuilder: (context, index) {
      double width = MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;

      double imageWidth = width;

      if (height / width < 1.2) {
        imageWidth = height / 1.2;
      }

      precacheComicImage(
          comicReadingPageLogic, type, context, index + 1, target);

      ImageProvider image = createImageProvider(type, comicReadingPageLogic, index, target);

      return ComicImage(
        filterQuality: FilterQuality.medium,
        image: image,
        width: imageWidth,
        fit: BoxFit.cover,
      );
    },
  );
}

///构建漫画图片
Widget buildComicView(ComicReadingPageLogic logic,
    ReadingType type, String target, List<String> eps, BuildContext context) {
  Widget body;

  if (["1","2","3"].contains(appdata.settings[9])) {
    body = PhotoViewGallery.builder(
      key: Key(logic.readingMethod.index.toString()),
      reverse: appdata.settings[9] == "2",
      scrollDirection:
          appdata.settings[9] != "3" ? Axis.horizontal : Axis.vertical,
      itemCount: logic.urls.length + 2,
      builder: (BuildContext context, int index) {
        ImageProvider? imageProvider;
        if (index != 0 && index != logic.urls.length + 1) {
          imageProvider = createImageProvider(type, logic, index-1, target);
        } else {
          _controllers[index] = PhotoViewController();
          return PhotoViewGalleryPageOptions(
            controller: _controllers[index],
            scaleStateController: PhotoViewScaleStateController(),
            imageProvider: const AssetImage("images/black.png"),
          );
        }

        precacheComicImage(logic, type, context, index, target);

        _controllers[index] = PhotoViewController();
        return PhotoViewGalleryPageOptions(
          filterQuality: FilterQuality.medium,
          controller: _controllers[index],
          minScale: PhotoViewComputedScale.contained * 0.9,
          imageProvider: imageProvider,
          errorBuilder: (w, o, s) {
            return Center(
              child: SizedBox(
                height: 80,
                width: 300,
                child: Column(
                  children: [
                    const Icon(
                      Icons.error,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      o.toString(),
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            );
          },
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(
              tag: "$index/${logic.urls.length}"),
        );
      },
      pageController: logic.controller,
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
                  : event.cumulativeBytesLoaded /
                      (event.expectedTotalBytes ?? 1000000000000),
            ),
          ),
        ),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onPageChanged: (i) {
        if (i == 0) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi) {
            logic.controller.jumpToPage(1);
            showMessage(Get.context, "已经是第一页了".tl);
            return;
          }
          logic.jumpToLastChapter();
        } else if (i == logic.urls.length + 1) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi) {
            logic.controller.jumpToPage(i - 1);
            showMessage(Get.context, "已经是最后一页了".tl);
            return;
          }
          logic.jumpToNextChapter();
        } else {
          logic.index = i;
          logic.update();
        }
      },
    );
  } else if(appdata.settings[9] == "4"){
    body = InteractiveViewer(
        transformationController:
            logic.transformationController,
        scaleEnabled: GetPlatform.isWindows ? false : true,
        maxScale: 2.5,
        minScale: 1,
        onInteractionEnd: (details) {
          logic.currentScale = logic
              .transformationController.value
              .getMaxScaleOnAxis();
        },
        child: SizedBox(
            width: MediaQuery.of(Get.context!).size.width,
            height: MediaQuery.of(Get.context!).size.height,
            child: buildGallery(logic, type, target)));
  } else {
    body = PhotoViewGallery.builder(
      key: Key(logic.readingMethod.index.toString()),
      itemCount: (logic.urls.length / 2).ceil() + 2,
      builder: (BuildContext context, int index) {
        if(index == 0 || index == (logic.urls.length / 2).ceil() + 1){
          return PhotoViewGalleryPageOptions.customChild(
              controller: _controllers[index],
              child: const SizedBox()
          );
        }
        precacheComicImage(logic, type, context, index*2+1, target);
        _controllers[index] = PhotoViewController();
        return PhotoViewGalleryPageOptions.customChild(
          controller: _controllers[index],
          child: Row(
            children: [
              Expanded(
                child: ComicImage(
                  image: createImageProvider(type, logic, index*2-2, target),
                  fit: BoxFit.fitWidth,
                ),
              ),
              Expanded(
                child: index*2-1 < logic.urls.length ? ComicImage(
                  image: createImageProvider(type, logic, index*2-1, target),
                  fit: BoxFit.fitWidth,
                ):const SizedBox(),
              ),
            ],
          )
        );
      },
      pageController: logic.controller,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onPageChanged: (i) {
        if (i == 0) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi) {
            logic.controller.jumpToPage(1);
            showMessage(Get.context, "已经是第一页了".tl);
            return;
          }
          logic.jumpToLastChapter();
        } else if (i == (logic.urls.length / 2).ceil() + 1) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi) {
            logic.controller.jumpToPage(i-1);
            showMessage(Get.context, "已经是最后一页了".tl);
            return;
          }
          logic.jumpToNextChapter();
        } else {
          logic.index = i*2-1;
          logic.update();
        }
      },
    );
  }

  return Positioned(
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    child: RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: (event){
        logic.ctrlPressed = event.isControlPressed;
      },
      child: Listener(
        //监听鼠标滚轮
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            if (logic.ctrlPressed) {
              final controller = _controllers[logic.index];
              if (appdata.settings[9] != "4") {
                final width = MediaQuery.of(Get.context!).size.width;
                final height = MediaQuery.of(Get.context!).size.height;
                var offset = Offset(width / 2 - pointerSignal.position.dx,
                    height / 2 - pointerSignal.position.dy);
                if (pointerSignal.scrollDelta.dy > 0) {
                  offset = Offset(0 - offset.dx, 0 - offset.dy);
                }
                var updatedOffset = Offset(
                    controller!.position.dx > offset.dx
                        ? controller.position.dx - 10
                        : controller.position.dx + 10,
                    controller.position.dy > offset.dy
                        ? controller.position.dy - 10
                        : controller.position.dy + 10);
                double abs(double a) => a > 0 ? a : 0 - a;
                updatedOffset = Offset(
                  abs(controller.position.dx - offset.dx) < 10
                      ? offset.dx
                      : updatedOffset.dx,
                  abs(controller.position.dy - offset.dy) < 10
                      ? offset.dy
                      : updatedOffset.dy,
                );
                controller.updateMultiple(
                    position: updatedOffset,
                    scale: controller.scale! -
                        pointerSignal.scrollDelta.dy / 2000);
              }
            } else if(logic.readingMethod != ReadingMethod.topToBottomContinuously){
              pointerSignal.scrollDelta.dy > 0
                  ? logic.jumpToNextPage()
                  : logic.jumpToLastPage();
            } else {
              logic.cont.animateTo(
                  logic.cont.position.pixels +
                      pointerSignal.scrollDelta.dy,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.bounceIn);
            }
          }
        },
        child: NotificationListener<ScrollUpdateNotification>(
          child: body,
          onNotification: (notification) {
            var length = logic.data.eps.length;
            if (type == ReadingType.picacg) length--;
            if (!logic.cont.hasClients) return false;
            if (logic.cont.position.pixels -
                        logic.cont.position.minScrollExtent <=
                    0 &&
                logic.order != 0) {
              logic.showFloatingButton(-1);
            } else if (logic.cont.position.pixels -
                        logic.cont.position.maxScrollExtent >=
                    0 &&
                logic.order < length) {
              logic.showFloatingButton(1);
            } else {
              logic.showFloatingButton(0);
            }
            return false;
          },
        ),
      ),
    ),
  );
}

///预加载图片
void precacheComicImage(ComicReadingPageLogic comicReadingPageLogic,
    ReadingType type, BuildContext context, int index, String target) {
  int precacheNum = int.parse(appdata.settings[28]) + index;
  for (; index < precacheNum; index++) {
    if(index >= comicReadingPageLogic.urls.length) return;
    precacheImage(createImageProvider(type, comicReadingPageLogic, index, target),
        context);
  }
}
