import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:get/get.dart';
import '../../base.dart';

///构建顶部工具栏
Widget buildTopToolBar(
    ComicReadingPageLogic comicReadingPageLogic, BuildContext context, String title) {
  return Positioned(
    top: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      child: comicReadingPageLogic.tools
          ? Container(
              decoration: BoxDecoration(

                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.95),
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8),bottomLeft: Radius.circular(8))
              ),
              width: MediaQuery.of(context).size.width + MediaQuery.of(context).padding.top,
              child: Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Tooltip(
                        message: "返回".tr,
                        child: IconButton(
                          iconSize: 25,
                          icon: const Icon(Icons.arrow_back_outlined),
                          onPressed: () => Get.back(),
                        ),
                      ),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width - 125,
                      height: 50,
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 75),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    //const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Tooltip(
                        message: "阅读设置".tr,
                        child: IconButton(
                          iconSize: 25,
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            comicReadingPageLogic.showSettings =
                                !comicReadingPageLogic.showSettings;
                            comicReadingPageLogic.update();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(
              width: 0,
              height: 0,
            ),
      transitionBuilder: (Widget child, Animation<double> animation) {
        var tween = Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0));
        return SlideTransition(
          position: tween.animate(animation),
          child: child,
        );
      },
    ),
  );
}

Matrix4 composeMatrix({
  double scale = 1,
  double rotation = 0,
  double translateX = 0,
  double translateY = 0,
  double anchorX = 0,
  double anchorY = 0,
}) {
  final double c = cos(rotation) * scale;
  final double s = sin(rotation) * scale;
  final double dx = translateX - c * anchorX + s * anchorY;
  final double dy = translateY - s * anchorX - c * anchorY;

  //  ..[0]  = c       # x scale
  //  ..[1]  = s       # y skew
  //  ..[4]  = -s      # x skew
  //  ..[5]  = c       # y scale
  //  ..[10] = 1       # diagonal "one"
  //  ..[12] = dx      # x translation
  //  ..[13] = dy      # y translation
  //  ..[15] = 1       # diagonal "one"
  return Matrix4(c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, dx, dy, 0, 1);
}

Matrix4 composeMatrixFromOffsets({
  double scale = 1,
  double rotation = 0,
  Offset translate = Offset.zero,
  Offset anchor = Offset.zero,
}) =>
    composeMatrix(
      scale: scale,
      rotation: rotation,
      translateX: translate.dx,
      translateY: translate.dy,
      anchorX: anchor.dx,
      anchorY: anchor.dy,
    );

///构建底部工具栏
Widget buildBottomToolBar(
    ComicReadingPageLogic comicReadingPageLogic,
    BuildContext context,
    bool showEps,
    void Function() openEpsDrawer,
    void Function() share,
    void Function() downloadCurrentImage) {
  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        var tween = Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0));
        return SlideTransition(
          position: tween.animate(animation),
          child: child,
        );
      },
      child: comicReadingPageLogic.tools
          ? Container(
              height: 105 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.95),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  buildSlider(comicReadingPageLogic),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (appdata.settings[9] == "4" && GetPlatform.isWindows)
                        Tooltip(
                          message: "放大".tr,
                          child: IconButton(
                            icon: const Icon(Icons.zoom_in),
                            onPressed: () {
                              var value = comicReadingPageLogic.transformationController.value
                                  .getMaxScaleOnAxis();
                              final center = MediaQuery.of(context).size.center(Offset.zero);
                              final anchor =
                                  comicReadingPageLogic.transformationController.toScene(center);
                              comicReadingPageLogic.transformationController.value =
                                  composeMatrixFromOffsets(
                                scale: value + 0.2,
                                anchor: anchor,
                                translate: center,
                              );
                            },
                          ),
                        ),
                      if (appdata.settings[9] == "4" && GetPlatform.isWindows)
                        Tooltip(
                          message: "缩小".tr,
                          child: IconButton(
                            icon: const Icon(Icons.zoom_out),
                            onPressed: () {
                              var value = comicReadingPageLogic.transformationController.value
                                  .getMaxScaleOnAxis();
                              if (value == 1) return;
                              final center = MediaQuery.of(context).size.center(Offset.zero);
                              final anchor =
                                  comicReadingPageLogic.transformationController.toScene(center);
                              comicReadingPageLogic.transformationController.value =
                                  composeMatrixFromOffsets(
                                scale: value - 0.2 < 1 ? 1 : value - 0.2,
                                anchor: anchor,
                                translate: center,
                              );
                            },
                          ),
                        ),
                      if (showEps)
                        Tooltip(
                          message: "章节".tr,
                          child: IconButton(
                            icon: const Icon(Icons.library_books),
                            onPressed: openEpsDrawer,
                          ),
                        ),
                      Tooltip(
                        message: "保存图片".tr,
                        child: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: downloadCurrentImage,
                        ),
                      ),
                      Tooltip(
                        message: "分享".tr,
                        child: IconButton(
                          icon: const Icon(Icons.share),
                          onPressed: share,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      )
                    ],
                  )
                ],
              ),
            )
          : const SizedBox(
              width: 0,
              height: 0,
            ),
    ),
  );
}

///显示当前的章节和页面位置
Widget buildPageInfoText(ComicReadingPageLogic comicReadingPageLogic, bool showEps,
    List<String> eps, BuildContext context,
    {bool jm = false}) {
  var epsText = "";
  if (eps.isNotEmpty && !jm) {
    epsText = eps.elementAtOrNull(comicReadingPageLogic.order) ?? "";
  }
  if (jm) {
    epsText = "第 @c 章".trParams({"c": comicReadingPageLogic.order.toString()});
  }

  if (!comicReadingPageLogic.tools) {
    return Positioned(
        bottom: 13,
        left: 25,
        child: appdata.settings[9] == "4"
            ? ValueListenableBuilder(
                valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
                builder: (context, value, child) {
                  try {
                    comicReadingPageLogic.index = value.first.index + 1;
                  } catch (e) {
                    comicReadingPageLogic.index = 0;
                  }
                  return showEps
                      ? Text(
                          "$epsText: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                          style: TextStyle(
                              color: comicReadingPageLogic.tools
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white),
                        )
                      : Text(
                          "${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                          style: TextStyle(
                              color: comicReadingPageLogic.tools
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white),
                        );
                },
              )
            : showEps
                ? Text(
                    "$epsText: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                    style: TextStyle(
                        color: comicReadingPageLogic.tools
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white),
                  )
                : Text(
                    "${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                    style: TextStyle(
                        color: comicReadingPageLogic.tools
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white),
                  ));
  } else {
    return Positioned(
        bottom: 13 + MediaQuery.of(context).padding.bottom,
        left: 25,
        child: appdata.settings[9] == "4"
            ? ValueListenableBuilder(
                valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
                builder: (context, value, child) {
                  try {
                    comicReadingPageLogic.index = value.first.index + 1;
                  } catch (e) {
                    if (appdata.settings[9] == "4") {
                      comicReadingPageLogic.index = 0;
                    }
                  }
                  return showEps
                      ? Text(
                          "$epsText: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                          style: TextStyle(
                              color: comicReadingPageLogic.tools
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white),
                        )
                      : Text(
                          "${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                          style: TextStyle(
                              color: comicReadingPageLogic.tools
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.white),
                        );
                },
              )
            : showEps
                ? Text(
                    "$epsText: ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                    style: TextStyle(
                        color: comicReadingPageLogic.tools
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white),
                  )
                : Text(
                    "${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
                    style: TextStyle(
                        color: comicReadingPageLogic.tools
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white),
                  ));
  }
}

List<Widget> buildButtons(ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
  return ((MediaQuery.of(context).size.width > MediaQuery.of(context).size.height &&
          appdata.settings[4] == "1"))
      ? [
          if (appdata.settings[9] != "4")
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_left),
                onPressed: () {
                  if (appdata.settings[9] == "1") {
                    comicReadingPageLogic.jumpToLastPage();
                  } else if (appdata.settings[9] == "2") {
                    comicReadingPageLogic.jumpToNextPage();
                  }
                },
                iconSize: 50,
              ),
            ),
          if (appdata.settings[9] != "4")
            Positioned(
              right: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_right),
                onPressed: () {
                  if (appdata.settings[9] == "2") {
                    comicReadingPageLogic.jumpToLastPage();
                  } else if (appdata.settings[9] == "1") {
                    comicReadingPageLogic.jumpToNextPage();
                  }
                },
                iconSize: 50,
              ),
            ),
          Positioned(
            left: 5,
            top: 5,
            child: IconButton(
              iconSize: 30,
              icon: const Icon(Icons.close),
              onPressed: () => Get.back(),
            ),
          ),
        ]
      : [];
}

Widget buildSlider(ComicReadingPageLogic comicReadingPageLogic) {
  if (comicReadingPageLogic.tools &&
      comicReadingPageLogic.index != 0 &&
      comicReadingPageLogic.index != comicReadingPageLogic.urls.length + 1) {
    if (appdata.settings[9] != "2" && appdata.settings[9] != "4") {
      return Slider(
        value: comicReadingPageLogic.index.toDouble(),
        min: 1,
        max: comicReadingPageLogic.urls.length.toDouble(),
        divisions: comicReadingPageLogic.urls.length,
        onChanged: (i) {
          comicReadingPageLogic.index = i.toInt();
          comicReadingPageLogic.jumpToPage(i.toInt());
          comicReadingPageLogic.update();
        },
      );
    } else {
      if (appdata.settings[9] == "4") {
        return ValueListenableBuilder(
          valueListenable: comicReadingPageLogic.scrollListener.itemPositions,
          builder: (context, value, child) {
            try {
              comicReadingPageLogic.index = value.first.index + 1;
            } catch (e) {
              comicReadingPageLogic.index = 0;
            }
            return Slider(
              value: comicReadingPageLogic.index.toDouble(),
              min: 1,
              max: comicReadingPageLogic.urls.length.toDouble(),
              divisions: comicReadingPageLogic.urls.length,
              onChanged: (i) {
                comicReadingPageLogic.index = i.toInt();
                comicReadingPageLogic.jumpToPage(i.toInt());
                comicReadingPageLogic.update();
              },
            );
          },
        );
      } else {
        return Slider(
          value: comicReadingPageLogic.urls.length.toDouble() -
              comicReadingPageLogic.index.toDouble() +
              1,
          min: 1,
          max: comicReadingPageLogic.urls.length.toDouble(),
          divisions: comicReadingPageLogic.urls.length,
          activeColor: Theme.of(Get.context!).colorScheme.surfaceVariant,
          inactiveColor: Theme.of(Get.context!).colorScheme.primary,
          thumbColor: Theme.of(Get.context!).colorScheme.secondary,
          onChanged: (i) {
            comicReadingPageLogic.controller
                .jumpToPage(comicReadingPageLogic.urls.length - (i.toInt() - 1));
          },
        );
      }
    }
  } else {
    return const SizedBox(
      height: 0,
    );
  }
}
