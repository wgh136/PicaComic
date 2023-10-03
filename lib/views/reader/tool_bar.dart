import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/views/reader/reading_logic.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/reader/reading_settings.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import 'package:pica_comic/views/widgets/custom_slider.dart';
import '../../base.dart';
import 'package:pica_comic/tools/translations.dart';

///构建顶部工具栏
Widget buildTopToolBar(ComicReadingPageLogic comicReadingPageLogic,
    BuildContext context, String title) {
  return Positioned(
    top: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      child: comicReadingPageLogic.tools
          ? Container(
              decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.95)),
              width: MediaQuery.of(context).size.width +
                  MediaQuery.of(context).padding.top,
              child: Padding(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Tooltip(
                        message: "返回".tl,
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
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 75),
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
                        message: "阅读设置".tl,
                        child: IconButton(
                          iconSize: 25,
                          icon: const Icon(Icons.settings),
                          onPressed: () => showSettings(context),
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
        var tween =
            Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0));
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
    ComicReadingPageLogic logic,
    BuildContext context,
    bool showEps,
    void Function() openEpsDrawer,
    void Function() share,
    void Function() downloadCurrentImage) {
  var text = "EP${logic.order} : P${logic.index}";
  if (logic.order == 0) {
    text = "P${logic.index}";
  }

  return Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      transitionBuilder: (Widget child, Animation<double> animation) {
        var tween =
            Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0));
        return SlideTransition(
          position: tween.animate(animation),
          child: child,
        );
      },
      child: logic.tools
          ? Container(
              height: 105 + MediaQuery.of(context).padding.bottom,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)),
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.95),
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 8,
                  ),
                  buildSlider(logic),
                  Row(
                    children: [
                      const SizedBox(
                        width: 16,
                      ),
                      Container(
                        width: 56,
                        height: 24,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(text),
                        ),
                      ),
                      const Spacer(),
                      if (GetPlatform.isAndroid)
                        Tooltip(
                          message: "屏幕方向".tl,
                          child: IconButton(
                            icon: () {
                              if (logic.rotation == null) {
                                return const Icon(Icons.screen_rotation);
                              } else if (logic.rotation ==
                                  false) {
                                return const Icon(Icons.screen_lock_portrait);
                              } else {
                                return const Icon(Icons.screen_lock_landscape);
                              }
                            }.call(),
                            onPressed: () {
                              if (logic.rotation == null) {
                                logic.rotation = false;
                                logic.update();
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                ]);
                              } else if (logic.rotation ==
                                  false) {
                                logic.rotation = true;
                                logic.update();
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.landscapeLeft,
                                  DeviceOrientation.landscapeRight
                                ]);
                              } else {
                                logic.rotation = null;
                                logic.update();
                                SystemChrome.setPreferredOrientations(
                                    DeviceOrientation.values);
                              }
                            },
                          ),
                        ),
                      Tooltip(
                        message: "自动翻页".tl,
                        child: IconButton(
                          icon: logic.runningAutoPageTurning
                              ? const Icon(Icons.timer)
                              : const Icon(Icons.timer_sharp),
                          onPressed: () {
                            logic.runningAutoPageTurning =
                                !logic.runningAutoPageTurning;
                            logic.update();
                            logic.autoPageTurning();
                          },
                        ),
                      ),
                      if (showEps)
                        Tooltip(
                          message: "章节".tl,
                          child: IconButton(
                            icon: const Icon(Icons.library_books),
                            onPressed: openEpsDrawer,
                          ),
                        ),
                      Tooltip(
                        message: "保存图片".tl,
                        child: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: downloadCurrentImage,
                        ),
                      ),
                      Tooltip(
                        message: "分享".tl,
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
Widget buildPageInfoText(ComicReadingPageLogic comicReadingPageLogic,
    bool showEps, List<String> eps, BuildContext context,
    {bool jm = false}) {
  var epsText = "";
  if (eps.isNotEmpty && !jm) {
    epsText = eps.elementAtOrNull(comicReadingPageLogic.order - 1) ?? "";
  }
  if (jm) {
    epsText = "第 @c 章".trParams({"c": comicReadingPageLogic.order.toString()});
  }

  return Positioned(
      bottom: 13,
      left: 25,
      child: showEps
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

List<Widget> buildButtons(
    ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
  return ((MediaQuery.of(context).size.width >
              MediaQuery.of(context).size.height &&
          appdata.settings[4] == "1"))
      ? [
          if (appdata.settings[9] != "4")
            Positioned(
              left: 20,
              top: MediaQuery.of(context).size.height / 2 - 25,
              child: IconButton(
                icon: const Icon(Icons.keyboard_arrow_left),
                onPressed: () {
                  switch (comicReadingPageLogic.readingMethod) {
                    case ReadingMethod.rightToLeft:
                    case ReadingMethod.twoPageReversed:
                      comicReadingPageLogic.jumpToNextPage();
                    default:
                      comicReadingPageLogic.jumpToLastPage();
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
                  switch (comicReadingPageLogic.readingMethod) {
                    case ReadingMethod.rightToLeft:
                    case ReadingMethod.twoPageReversed:
                      comicReadingPageLogic.jumpToLastPage();
                    default:
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

Widget buildSlider(ComicReadingPageLogic logic) {
  if (logic.tools &&
      logic.index != 0 &&
      logic.index != logic.urls.length + 1) {
    return CustomSlider(
      value: logic.index.toDouble(),
      min: 1,
      reversed: appdata.settings[9] == "2" || appdata.settings[9] == "6",
      max: logic.urls.length.toDouble(),
      divisions: logic.urls.length - 1,
      onChanged: (i) {
        if(logic.readingMethod == ReadingMethod.topToBottomContinuously) {
          logic.jumpToPage(i.toInt());
          logic.index = i.toInt();
          logic.update();
        } else if (logic.readingMethod != ReadingMethod.twoPage &&
            logic.readingMethod !=
                ReadingMethod.twoPageReversed) {
          logic.index = i.toInt();
          logic.jumpToPage(i.toInt());
          logic.update();
        } else {
          logic.index = i.toInt() + i.toInt() % 2 - 1;
          logic
              .jumpToPage((logic.index + 2) ~/ 2);
          logic.update();
        }
      },
    );
  } else {
    return const SizedBox(
      height: 0,
    );
  }
}
