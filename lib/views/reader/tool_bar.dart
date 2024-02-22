part of pica_reader;

extension ToolBar on ComicReadingPage {
  ///构建底部工具栏
  Widget buildBottomToolBar(
      ComicReadingPageLogic logic, BuildContext context, bool showEps) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: StateBuilder<ComicReadingPageLogic>(
        id: "ToolBar",
        builder: (logic) {
          var text = "E${logic.order} : P${logic.index}";
          if (logic.order == 0) {
            text = "P${logic.index}";
          }

          Widget child = SizedBox(
            height: 105 + MediaQuery.of(context).padding.bottom,
            child: Column(
              children: [
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 8,
                    ),
                    IconButton.filledTonal(
                        onPressed: () => logic.jumpToLastChapter(),
                        icon: const Icon(Icons.first_page)),
                    Expanded(
                      child: buildSlider(logic),
                    ),
                    IconButton.filledTonal(
                        onPressed: () => logic.jumpToNextChapter(),
                        icon: const Icon(Icons.last_page)),
                    const SizedBox(
                      width: 8,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                    ),
                    Container(
                      height: 24,
                      padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(text),
                    ),
                    const Spacer(),
                    if (App.isWindows)
                      Tooltip(
                        message: "${"全屏".tl}(F12)",
                        child: IconButton(
                          icon: const Icon(Icons.fullscreen),
                          onPressed: () {
                            logic.fullscreen();
                          },
                        ),
                      ),
                    if (App.isAndroid && appdata.settings[76] != "1")
                      Tooltip(
                        message: "屏幕方向".tl,
                        child: IconButton(
                          icon: () {
                            if (logic.rotation == null) {
                              return const Icon(Icons.screen_rotation);
                            } else if (logic.rotation == false) {
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
                            } else if (logic.rotation == false) {
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
                      message: "收藏图片".tl,
                      child: IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () async {
                          try {
                            final id =
                                "${logic.data.sourceKey}-${logic.data.id}";
                            var image = await _persistentCurrentImage();
                            if (image != null) {
                              image = image.split("/").last;
                              var otherInfo = <String, dynamic>{};
                              if (logic.data.type == ReadingType.ehentai) {
                                otherInfo["gallery"] =
                                    (logic.data as EhReadingData)
                                        .gallery
                                        .toJson();
                              } else if (logic.data.type ==
                                  ReadingType.hitomi) {
                                otherInfo["hitomi"] =
                                    (readingData as HitomiReadingData)
                                        .images
                                        .map((e) => e.toMap())
                                        .toList();
                                otherInfo["galleryId"] = readingData.id;
                              } else if (logic.data.type == ReadingType.jm) {
                                otherInfo["jmEpNames"] =
                                    readingData.eps!.values.toList();
                                otherInfo["epsId"] = readingData.eps!.keys
                                    .elementAt(logic.index - 1);
                                otherInfo["bookId"] = readingData.id;
                              }
                              if (logic.data.type != ComicType.other) {
                                otherInfo["eps"] =
                                    readingData.eps?.keys.toList() ?? [];
                              } else {
                                otherInfo["eps"] = readingData.eps;
                              }
                              otherInfo["url"] = logic.urls[logic.index - 1];
                              ImageFavoriteManager.add(ImageFavorite(
                                  id,
                                  image,
                                  readingData.title,
                                  logic.order,
                                  logic.index,
                                  otherInfo));
                              showToast(message: "成功收藏图片".tl);
                            }
                          } catch (e) {
                            showToast(message: e.toString());
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
                        onPressed: saveCurrentImage,
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
          );

          child = Material(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
            elevation: 3,
            child: child,
          );

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            reverseDuration: const Duration(milliseconds: 150),
            switchInCurve: Curves.fastOutSlowIn,
            transitionBuilder: (Widget child, Animation<double> animation) {
              var tween = Tween<Offset>(
                  begin: const Offset(0, 1), end: const Offset(0, 0));
              return SlideTransition(
                position: tween.animate(animation),
                child: child,
              );
            },
            child: logic.tools
                ? child
                : const SizedBox(
                    width: 0,
                    height: 0,
                  ),
          );
        },
      ),
    );
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
          if (logic.readingMethod == ReadingMethod.topToBottomContinuously) {
            logic.jumpToPage(i.toInt());
            logic.index = i.toInt();
            logic.update();
          } else if (logic.readingMethod != ReadingMethod.twoPage &&
              logic.readingMethod != ReadingMethod.twoPageReversed) {
            logic.index = i.toInt();
            logic.jumpToPage(i.toInt());
            logic.update();
          } else {
            logic.index = i.toInt() + i.toInt() % 2 - 1;
            logic.jumpToPage((logic.index + 2) ~/ 2);
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

  List<Widget> buildButtons(
      ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
    return ((MediaQuery.of(context).size.width >
                MediaQuery.of(context).size.height &&
            appdata.settings[4] == "1"))
        ? [
            if (appdata.settings[9] != "4" &&
                comicReadingPageLogic.readingMethod !=
                    ReadingMethod.topToBottom)
              Positioned(
                left: 20,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left),
                  onPressed: () {
                    if (appdata.settings[0] == "1") {
                      return;
                    }
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
            if (appdata.settings[9] != "4" &&
                comicReadingPageLogic.readingMethod !=
                    ReadingMethod.topToBottom)
              Positioned(
                right: 20,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right),
                  onPressed: () {
                    if (appdata.settings[0] == "1") {
                      return;
                    }
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
                onPressed: () => App.globalBack(),
              ),
            ),
          ]
        : [];
  }

  ///构建顶部工具栏
  Widget buildTopToolBar(
      ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
    return Positioned(
      top: 0,
      child: StateBuilder<ComicReadingPageLogic>(
        id: "ToolBar",
        builder: (logic) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          reverseDuration: const Duration(milliseconds: 150),
          switchInCurve: Curves.fastOutSlowIn,
          child: comicReadingPageLogic.tools
              ? Material(
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  elevation: 3,
                  shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                          child: Tooltip(
                            message: "返回".tl,
                            child: IconButton(
                              iconSize: 25,
                              icon: const Icon(Icons.arrow_back_outlined),
                              onPressed: () => App.globalBack(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 50,
                            constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width - 75),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                readingData.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 20),
                              ),
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
                  ).paddingTop(MediaQuery.of(context).padding.top),
                )
              : const SizedBox(
                  width: 0,
                  height: 0,
                ),
          transitionBuilder: (Widget child, Animation<double> animation) {
            var tween = Tween<Offset>(
                begin: const Offset(0, -1), end: const Offset(0, 0));
            return SlideTransition(
              position: tween.animate(animation),
              child: child,
            );
          },
        ),
      ),
    );
  }

  ///显示当前的章节和页面位置
  Widget buildPageInfoText(
      ComicReadingPageLogic comicReadingPageLogic, BuildContext context,
      {bool jm = false}) {
    var epName = readingData.eps?.values
            .elementAtOrNull(comicReadingPageLogic.order - 1) ??
        "E1";
    if (epName.length > 8) {
      epName = "${epName.substring(0, 8)}...";
    }
    return Positioned(
        bottom: 13,
        left: 25,
        child: readingData.hasEp
            ? Text(
                "$epName : ${comicReadingPageLogic.index}/${comicReadingPageLogic.urls.length}",
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
