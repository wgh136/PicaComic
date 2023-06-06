import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pica_comic/views/hitomi_views/image_loader/hitomi_cached_image_provider.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:flutter/material.dart';
import '../../base.dart';
import '../../network/eh_network/get_gallery_id.dart';
import '../../network/picacg_network/methods.dart';
import '../eh_views/eh_widgets/eh_image_provider/eh_cached_image.dart';
import '../jm_views/jm_image_provider/jm_cached_image.dart';
import '../widgets/scrollable_list/src/scrollable_positioned_list.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:get/get.dart';
import 'reading_type.dart';

Map<int, PhotoViewController> _controllers = {};

///构建从上至下(连续)阅读方式
Widget buildGallery(ComicReadingPageLogic comicReadingPageLogic, ReadingType type, String target) {
  return ScrollablePositionedList.builder(
    itemScrollController: comicReadingPageLogic.scrollController,
    itemPositionsListener: comicReadingPageLogic.scrollListener,
    itemCount: comicReadingPageLogic.urls.length,
    addSemanticIndexes: false,
    scrollController: comicReadingPageLogic.cont,
    itemBuilder: (context, index) {

      double width =  MediaQuery.of(context).size.width;
      double height = MediaQuery.of(context).size.height;

      double imageWidth = width;

      if(height / width < 1.2){
        imageWidth = height / 1.2;
      }

      precacheComicImage(comicReadingPageLogic, type, context, index+1, target);

      ImageProvider image;

      if (type == ReadingType.ehentai && ! comicReadingPageLogic.downloaded){
        image = EhCachedImageProvider(comicReadingPageLogic.urls[index]);
      }else if(type == ReadingType.hitomi && !comicReadingPageLogic.downloaded){
        image = HitomiCachedImageProvider(comicReadingPageLogic.images[index], target);
      }else if(type == ReadingType.picacg && !comicReadingPageLogic.downloaded){
        image = CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index]));
      }else if(type == ReadingType.jm && !comicReadingPageLogic.downloaded){
        image = JmCachedImageProvider(comicReadingPageLogic.urls[index], target);
      }else{
        var id = target;
        if(type == ReadingType.ehentai){
          id = getGalleryId(target);
        }else if(type == ReadingType.hitomi){
          id = "hitomi$target";
        }
        image = FileImage(downloadManager.getImage(id, comicReadingPageLogic.order, index));
      }

      return Image(
        filterQuality: FilterQuality.medium,
        image: image,
        width: imageWidth,
        fit: BoxFit.cover,
        frameBuilder: (context, widget, i, b) {
          return Padding(
            padding: EdgeInsets.fromLTRB((width-imageWidth)/2, 0, (width-imageWidth)/2, 0),
            child: ConstrainedBox(constraints: const BoxConstraints(minHeight: 250), child: Align(
              alignment: Alignment.topCenter,
              child: widget,
              ),),
          );
        },
        loadingBuilder: (context, widget, event) {
          if (event == null) {
            return widget;
          } else {
            return SizedBox(
              height: 250,
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
        errorBuilder: (context, s, d){
          return SizedBox(
            height: 250,
            child: Center(
              child: SizedBox(
                height: 100,
                width: 300,
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.white,size: 30,),
                    const SizedBox(height: 10,),
                    Text(s.toString(), style: const TextStyle(color: Colors.white),textAlign: TextAlign.center,)
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

///构建漫画图片
Widget buildComicView(ComicReadingPageLogic comicReadingPageLogic, ReadingType type, String target, List<String> eps) {
  Widget body;

  if (appdata.settings[9] != "4") {
    body =  PhotoViewGallery.builder(
      reverse: appdata.settings[9] == "2",
      scrollDirection: appdata.settings[9] != "3" ? Axis.horizontal : Axis.vertical,
      itemCount: comicReadingPageLogic.urls.length + 2,
      builder: (BuildContext context, int index) {
        ImageProvider? imageProvider;
        if (index != 0 && index != comicReadingPageLogic.urls.length + 1){
          if (type == ReadingType.ehentai && !comicReadingPageLogic.downloaded){
            imageProvider = EhCachedImageProvider(comicReadingPageLogic.urls[index - 1]);
          }else if (comicReadingPageLogic.downloaded){
            var id = target;
            if(type == ReadingType.ehentai){
              id = getGalleryId(target);
            }else if(type == ReadingType.hitomi){
              id = "hitomi$target";
            }
            imageProvider = FileImage(downloadManager.getImage(
                id, comicReadingPageLogic.order, index - 1));
          }else if(type == ReadingType.picacg){
            imageProvider = CachedNetworkImageProvider(
                getImageUrl(comicReadingPageLogic.urls[index - 1]));
          }else if(type == ReadingType.jm){
            imageProvider = JmCachedImageProvider(comicReadingPageLogic.urls[index - 1], target);
          }else{
            imageProvider = HitomiCachedImageProvider(comicReadingPageLogic.images[index-1], target);
          }
        } else {
          _controllers[index] = PhotoViewController();
          return PhotoViewGalleryPageOptions(
            controller: _controllers[index],
            scaleStateController: PhotoViewScaleStateController(),
            imageProvider: const AssetImage("images/black.png"),
          );
        }

        precacheComicImage(comicReadingPageLogic, type, context, index, target);

        _controllers[index] = PhotoViewController();
        return PhotoViewGalleryPageOptions(
          filterQuality: FilterQuality.medium,
          controller: _controllers[index],
          minScale: PhotoViewComputedScale.contained * 0.9,
          imageProvider: imageProvider,
          errorBuilder: (w,o,s){
            return Center(
              child: SizedBox(
                height: 80,
                width: 300,
                child: Column(
                  children: [
                    const Icon(Icons.error, color: Colors.white,size: 30,),
                    const SizedBox(height: 10,),
                    Text(o.toString(), style: const TextStyle(color: Colors.white),textAlign: TextAlign.center,)
                  ],
                ),
              ),
            );
          },
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(
              tag: "$index/${comicReadingPageLogic.urls.length}"),
        );
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
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes??1000000000000),
            ),
          ),
        ),
      ),
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onPageChanged: (i) {
        if (i == 0) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi) {
            comicReadingPageLogic.controller.jumpToPage(1);
            showMessage(Get.context, "已经是第一页了".tr);
            return;
          }
          comicReadingPageLogic.jumpToLastChapter();
        } else if (i == comicReadingPageLogic.urls.length + 1) {
          if (type == ReadingType.ehentai || type == ReadingType.hitomi) {
            comicReadingPageLogic.controller.jumpToPage(i - 1);
            showMessage(Get.context, "已经是最后一页了".tr);
            return;
          }
          comicReadingPageLogic.jumpToNextChapter();
        } else {
          comicReadingPageLogic.index = i;
          comicReadingPageLogic.update();
        }
      },
    );
  } else {
    body = InteractiveViewer(
        transformationController: comicReadingPageLogic.transformationController,
        scaleEnabled: GetPlatform.isWindows?false:true,
        maxScale: 2.5,
        minScale: 1,
        child: AbsorbPointer(
          absorbing: true, //使用控制器控制滚动
          child: SizedBox(
              width: MediaQuery.of(Get.context!).size.width,
              height: MediaQuery.of(Get.context!).size.height,
              child: buildGallery(comicReadingPageLogic, type, target)),
        ));
  }

  return Positioned(
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    child: Listener(
      //监听鼠标滚轮
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final controller = _controllers[comicReadingPageLogic.index];
          if(appdata.settings[9] != "4"){
            final width = MediaQuery.of(Get.context!).size.width;
            final height = MediaQuery.of(Get.context!).size.height;
            var offset = Offset(
                width/2 - pointerSignal.position.dx,
                height/2 - pointerSignal.position.dy
            );
            if(pointerSignal.scrollDelta.dy > 0){
              offset = Offset(
                  0 - offset.dx,
                  0 - offset.dy
              );
            }
            final updatedOffset = Offset(
              controller!.position.dx > offset.dx ? controller.position.dx - 20 : controller.position.dx + 20,
              controller.position.dy > offset.dy ? controller.position.dy - 20 : controller.position.dy + 20
            );
            controller.updateMultiple(position: updatedOffset, scale: controller.scale! - pointerSignal.scrollDelta.dy/4000);
          }else{
            comicReadingPageLogic.cont.jumpTo(comicReadingPageLogic.cont.position.pixels+pointerSignal.scrollDelta.dy);
          }
        }
      },
      child: body,
    ),
  );
}

///预加载图片
void precacheComicImage(ComicReadingPageLogic comicReadingPageLogic,ReadingType type,BuildContext context, int index, String target){
  if (index < comicReadingPageLogic.urls.length && type == ReadingType.ehentai && !comicReadingPageLogic.downloaded) {
    precacheImage(
        EhCachedImageProvider(comicReadingPageLogic.urls[index]), context);
  } else if (index < comicReadingPageLogic.urls.length && type == ReadingType.picacg &&
      !comicReadingPageLogic.downloaded) {
    precacheImage(
        CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index])),
        context);
  } else if(index < comicReadingPageLogic.urls.length && type == ReadingType.jm &&
      !comicReadingPageLogic.downloaded){
    precacheImage(JmCachedImageProvider(comicReadingPageLogic.urls[index], target), context);
  }else if(index < comicReadingPageLogic.urls.length && type == ReadingType.hitomi &&
      !comicReadingPageLogic.downloaded){
    precacheImage(HitomiCachedImageProvider(comicReadingPageLogic.images[index], target), context);
  }else if (index < comicReadingPageLogic.urls.length &&
      comicReadingPageLogic.downloaded) {
    var id = target;
    if(type == ReadingType.ehentai){
      id = getGalleryId(target);
    }else if(type == ReadingType.hitomi){
      id = "hitomi$target";
    }
    precacheImage(
        FileImage(
            downloadManager.getImage(id, comicReadingPageLogic.order, index)),
        context);
  }

  index -= 2;

  if(index < 0) return;

  if (index < comicReadingPageLogic.urls.length && type == ReadingType.ehentai && !comicReadingPageLogic.downloaded) {
    precacheImage(
        EhCachedImageProvider(comicReadingPageLogic.urls[index]), context);
  } else if (index < comicReadingPageLogic.urls.length && type == ReadingType.picacg &&
      !comicReadingPageLogic.downloaded) {
    precacheImage(
        CachedNetworkImageProvider(getImageUrl(comicReadingPageLogic.urls[index])),
        context);
  } else if(index < comicReadingPageLogic.urls.length && type == ReadingType.jm &&
      !comicReadingPageLogic.downloaded){
    precacheImage(JmCachedImageProvider(comicReadingPageLogic.urls[index], target), context);
  }else if(index < comicReadingPageLogic.urls.length && type == ReadingType.hitomi &&
      !comicReadingPageLogic.downloaded){
    precacheImage(HitomiCachedImageProvider(comicReadingPageLogic.images[index], target), context);
  }else if (index < comicReadingPageLogic.urls.length &&
      comicReadingPageLogic.downloaded) {
    var id = target;
    if(type == ReadingType.ehentai){
      id = getGalleryId(target);
    }else if(type == ReadingType.hitomi){
      id = "hitomi$target";
    }
    precacheImage(
        FileImage(
            downloadManager.getImage(id, comicReadingPageLogic.order, index)),
        context);
  }
}