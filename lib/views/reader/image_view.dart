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

extension ScrollExtension on ScrollController{
  static double? futurePosition;

  void smoothTo(double value){
    futurePosition ??= position.pixels;
    futurePosition = futurePosition! + value*1.2;
    futurePosition = futurePosition!.clamp(position.minScrollExtent, position.maxScrollExtent);
    animateTo(futurePosition!, duration: const Duration(milliseconds: 200), curve: Curves.linear);
  }
}

/// create a image provider with the provided image and comic source.
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
  } else if (type == ReadingType.htManga &&
      !logic.downloaded) {
    image = CachedImageProvider(logic.urls[index]);
  } else if (type == ReadingType.nhentai &&
      !logic.downloaded) {
    image = CachedImageProvider(logic.urls[index], headers: {
      "User-Agent": webUA,
    });
  }else {
    var id = target;
    if (type == ReadingType.ehentai) {
      id = getGalleryId(target);
    } else if (type == ReadingType.hitomi) {
      id = "hitomi$target";
    } else if (type == ReadingType.htManga) {
      id = "Ht$target";
    } else if(type == ReadingType.nhentai){
      id = "nhentai$target";
    }
    image = FileImage(
        downloadManager.getImage(id, logic.order, index));
  }

  return image;
}

/// check current location of [PageView], update location when it is out of range.
bool updateLocation(BuildContext context, PhotoViewController controller){
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  if(width / height < 1.2){
    return false;
  }
  final currentLocation = controller.position;
  final scale = controller.scale ?? 1;
  final imageWidth = height/1.2;
  final showWidth = width / scale;
  if(showWidth >= imageWidth && currentLocation.dx != 0){
    controller.updateMultiple(position: Offset(controller.initial.position.dx, currentLocation.dy));
    return true;
  }
  if(showWidth < imageWidth){
    final lEdge = (width - imageWidth) / 2;
    final rEdge = width - lEdge;
    final showLEdge = (0 - currentLocation.dx) / scale - showWidth / 2 + width / 2;
    final showREdge = (0 - currentLocation.dx) / scale + showWidth / 2 + width / 2;
    final updateValue = (width / 2 - (rEdge - showWidth / 2)) * scale;
    if(lEdge > showLEdge){
      controller.updateMultiple(position: Offset(0 - updateValue, currentLocation.dy));
      return true;
    }else if(rEdge < showREdge){
      controller.updateMultiple(position: Offset(updateValue , currentLocation.dy));
      return true;
    }
  }
  return false;
}

/// build comic image
Widget buildComicView(ComicReadingPageLogic logic,
    ReadingType type, String target, List<String> eps, BuildContext context) {
  ScrollExtension.futurePosition = null;

  Widget buildType4() {
    PhotoView.onCtrlKey = ()=>logic.update();
    PhotoViewGallery.onCtrlKey = ()=>logic.update();
    return ScrollablePositionedList.builder(
      itemScrollController: logic.itemScrollController,
      itemPositionsListener: logic.itemScrollListener,
      itemCount: logic.urls.length,
      addSemanticIndexes: false,
      scrollController: logic.scrollController,
      physics: (logic.noScroll ||
          logic.currentScale > 1.05 || PhotoView.isCtrlPressed || logic.mouseScroll)
          ? const NeverScrollableScrollPhysics()
          : const ClampingScrollPhysics(),
      itemBuilder: (context, index) {
        double width = MediaQuery.of(context).size.width;
        double height = MediaQuery.of(context).size.height;

        double imageWidth = width;

        if (height / width < 1.2) {
          imageWidth = height / 1.2;
        }

        precacheComicImage(
            logic, type, context, index + 1, target);

        ImageProvider image = createImageProvider(type, logic, index, target);

        return ComicImage(
          filterQuality: FilterQuality.medium,
          image: image,
          width: imageWidth,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget buildType123(){
    return PhotoViewGallery.builder(
      key: Key(logic.readingMethod.index.toString() + appdata.settings[41]),
      reverse: appdata.settings[9] == "2",
      scrollDirection:
      appdata.settings[9] != "3" ? Axis.horizontal : Axis.vertical,
      itemCount: logic.urls.length + 2,
      builder: (BuildContext context, int index) {
        ImageProvider? imageProvider;
        if (index != 0 && index != logic.urls.length + 1) {
          imageProvider = createImageProvider(type, logic, index-1, target);
        } else {
          return PhotoViewGalleryPageOptions.customChild(
            scaleStateController: PhotoViewScaleStateController(),
            child: const ColoredBox(color: Colors.black,)
          );
        }

        precacheComicImage(logic, type, context, index, target);

        BoxFit getFit(){
          switch(appdata.settings[41]){
            case "1": return BoxFit.fitWidth;
            case "2": return BoxFit.fitHeight;
            default: return BoxFit.contain;
          }
        }

        return PhotoViewGalleryPageOptions(
          filterQuality: FilterQuality.medium,
          imageProvider: imageProvider,
          fit: getFit(),
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
          heroAttributes: PhotoViewHeroAttributes(
              tag: "$index/${logic.urls.length}"),
        );
      },
      pageController: logic.pageController,
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
          if (type == ReadingType.ehentai || type == ReadingType.hitomi || type == ReadingType.nhentai) {
            logic.pageController.jumpToPage(1);
            showMessage(Get.context, "已经是第一页了".tl);
            return;
          }
          logic.jumpToLastChapter();
        } else if (i == logic.urls.length + 1) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi || type == ReadingType.nhentai) {
            logic.pageController.jumpToPage(i - 1);
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
  }

  Widget buildType56(){
    return PhotoViewGallery.builder(
      key: Key(logic.readingMethod.index.toString()),
      itemCount: (logic.urls.length / 2).ceil() + 2,
      reverse: logic.readingMethod == ReadingMethod.twoPageReversed,
      builder: (BuildContext context, int index) {
        if(index == 0 || index == (logic.urls.length / 2).ceil() + 1){
          return PhotoViewGalleryPageOptions.customChild(
              child: const SizedBox()
          );
        }
        precacheComicImage(logic, type, context, index*2+1, target);
        return PhotoViewGalleryPageOptions.customChild(
            child: Row(
              children: logic.readingMethod == ReadingMethod.twoPage ?
              [
                Expanded(
                  child: ComicImage(
                    image: createImageProvider(type, logic, index*2-2, target),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
                ),
                Expanded(
                  child: index*2-1 < logic.urls.length ? ComicImage(
                    image: createImageProvider(type, logic, index*2-1, target),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ):const SizedBox(),
                ),] : [
                Expanded(
                  child: index*2-1 < logic.urls.length ? ComicImage(
                    image: createImageProvider(type, logic, index*2-1, target),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ):const SizedBox(),
                ),
                Expanded(
                  child: ComicImage(
                    image: createImageProvider(type, logic, index*2-2, target),
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ],
            )
        );
      },
      pageController: logic.pageController,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onPageChanged: (i) {
        if (i == 0) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi || type == ReadingType.nhentai) {
            logic.pageController.jumpToPage(1);
            showMessage(Get.context, "已经是第一页了".tl);
            return;
          }
          logic.jumpToLastChapter();
        } else if (i == (logic.urls.length / 2).ceil() + 1) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi || type == ReadingType.nhentai) {
            logic.pageController.jumpToPage(i-1);
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

  Widget body;

  if (["1","2","3"].contains(appdata.settings[9])) {
    body = buildType123();
  } else if(appdata.settings[9] == "4"){
    body = PhotoView.customChild(
        key: Key(logic.order.toString()),
        maxScale: 2.5,
        minScale: 1.0,
        strictScale: true,
        controller: logic.photoViewController,
        onScaleEnd: (context, detail, value){
          var prev = logic.currentScale;
          logic.currentScale = value.scale ?? 1.0;
          if((prev <= 1.05 && logic.currentScale > 1.05) || (prev > 1.05 && logic.currentScale <= 1.05)){
            logic.update();
          }
          return updateLocation(context, logic.photoViewController);
        },
        child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: buildType4()));
  } else {
    body = buildType56();
  }

  void onPointerSignal(PointerSignalEvent pointerSignal){
    logic.mouseScroll = true;
    if (pointerSignal is PointerScrollEvent && !PhotoView.isCtrlPressed) {
      if(logic.readingMethod != ReadingMethod.topToBottomContinuously){
        pointerSignal.scrollDelta.dy > 0
            ? logic.jumpToNextPage()
            : logic.jumpToLastPage();
      } else {
        if((logic.scrollController.position.pixels == logic.scrollController.position.minScrollExtent && pointerSignal.scrollDelta.dy < 0) ||
            (logic.scrollController.position.pixels == logic.scrollController.position.maxScrollExtent && pointerSignal.scrollDelta.dy > 0)) {
          logic.photoViewController.updateMultiple(position: logic.photoViewController.position - Offset(0,pointerSignal.scrollDelta.dy));
        }else{
          logic.scrollController.smoothTo(pointerSignal.scrollDelta.dy);
        }
      }
    }
  }

  return Positioned.fill(
    child: Listener(
      onPointerSignal: onPointerSignal,
      onPointerDown: (details) => logic.mouseScroll = false,
      child: NotificationListener<ScrollUpdateNotification>(
        child: body,
        onNotification: (notification) {
          var length = logic.data.eps.length;
          if (!logic.scrollController.hasClients) return false;
          if (logic.scrollController.position.pixels -
              logic.scrollController.position.minScrollExtent <=
              0 &&
              logic.order != 0) {
            logic.showFloatingButton(-1);
          } else if (logic.scrollController.position.pixels -
              logic.scrollController.position.maxScrollExtent >=
              0 &&
              logic.order < length) {
            logic.showFloatingButton(1);
          } else {
            logic.showFloatingButton(0);
          }
          return true;
        },
      ),
    ),
  );
}

/// preload image
void precacheComicImage(ComicReadingPageLogic comicReadingPageLogic,
    ReadingType type, BuildContext context, int index, String target) {
  if(comicReadingPageLogic.readingMethod == ReadingMethod.topToBottomContinuously){
    return;
  }
  int precacheNum = int.parse(appdata.settings[28]) + index;
  for (; index < precacheNum; index++) {
    if(index >= comicReadingPageLogic.urls.length) return;
    precacheImage(createImageProvider(type, comicReadingPageLogic, index, target),
        context);
  }
}
