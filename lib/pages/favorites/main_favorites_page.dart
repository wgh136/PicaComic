import "dart:async";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart";
import "package:pica_comic/base.dart";
import "package:pica_comic/comic_source/comic_source.dart";
import 'package:pica_comic/components/components.dart';
import "package:pica_comic/foundation/app.dart";
import "package:pica_comic/foundation/local_favorites.dart";
import "package:pica_comic/foundation/log.dart";
import "package:pica_comic/network/download.dart";
import "package:pica_comic/tools/translations.dart";

import "../../network/net_fav_to_local.dart";
import "../../tools/io_tools.dart";
import "local_favorites.dart";
import "local_search_page.dart";
import "network_favorite_page.dart";

class FavoritesPageController extends StateController {
  String? current;

  bool? isNetwork;

  bool selectingFolder = true;

  FavoriteData? networkData;

  var selectedComics = <FavoriteItem>[];

  var openComicMenuFuncs = <FavoriteItem, Function>{};

  bool get isSelectingComics => selectedComics.isNotEmpty;

  FavoritesPageController() {
    var data = appdata.implicitData[0].split(";");
    selectingFolder = data[0] == "1";
    if (data[1] == "") {
      isNetwork = null;
    } else {
      isNetwork = data[1] == "1";
    }
    if (data.length > 3) {
      current = data.sublist(2).join(";");
    } else {
      current = data[2];
    }
    if (current == "") {
      current = null;
    }
    if (isNetwork ?? false) {
      final folders =
          appdata.settings[68].split(',').map((e) => getFavoriteDataOrNull(e));
      networkData =
          folders.firstWhereOrNull((element) => element?.title == current);
      if (networkData == null) {
        current = null;
        selectingFolder = true;
        isNetwork = null;
      }
    }
  }

  @override
  void update([List<Object>? ids]) {
    if (selectedComics.isEmpty) {
      openComicMenuFuncs.clear();
    }
    super.update(ids);
  }
}

const _kSecondaryTopBarHeight = 48.0;

class FavoritesPage extends StatelessWidget with _LocalFavoritesManager {
  FavoritesPage({super.key});

  final controller = StateController.putIfNotExists<FavoritesPageController>(
      FavoritesPageController());

  @override
  Widget build(BuildContext context) {
    return StateBuilder<FavoritesPageController>(builder: (controller) {
      return buildPage(context);
    });
  }

  Widget buildPage(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constrains) => Stack(
              children: [
                Positioned(
                  top: _kSecondaryTopBarHeight,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: buildContent(context),
                ),
                AnimatedPositioned(
                  key: const Key("folders"),
                  duration: const Duration(milliseconds: 180),
                  left: 0,
                  right: 0,
                  bottom: controller.selectingFolder
                      ? 0
                      : constrains.maxHeight - _kSecondaryTopBarHeight,
                  child: buildFoldersList(
                      context, constrains.maxHeight - _kSecondaryTopBarHeight),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: buildTopBar(context),
                ),
              ],
            ));
  }

  void multiSelectedMenu() {
    final size = MediaQuery.of(App.globalContext!).size;
    showMenu(
        context: App.globalContext!,
        position: RelativeRect.fromLTRB(size.width, 0, 0, size.height),
        items: [
          PopupMenuItem(
            child: Text("删除".tl),
            onTap: () {
              for (var comic in controller.selectedComics) {
                LocalFavoritesManager().deleteComic(controller.current!, comic);
              }
              controller.selectedComics.clear();
              controller.update();
            },
          ),
          PopupMenuItem(
            child: Text("复制到".tl),
            onTap: () {
              Future.delayed(
                const Duration(milliseconds: 200),
                () => copyAllTo(controller.current!, controller.selectedComics),
              );
            },
          ),
          PopupMenuItem(
            child: Text("下载".tl),
            onTap: () {
              Future.delayed(
                const Duration(milliseconds: 200),
                () {
                  var comics = controller.selectedComics;
                  for (var comic in comics) {
                    DownloadManager().addFavoriteDownload(comic);
                  }
                  showToast(message: "已添加下载任务".tl);
                },
              );
            },
          ),
          PopupMenuItem(
            child: Text("更新漫画信息".tl),
            onTap: () {
              Future.delayed(
                const Duration(milliseconds: 200),
                () {
                  var comics = controller.selectedComics;
                  UpdateFavoritesInfoDialog.show(comics, controller.current!);
                },
              );
            },
          ),
        ]);
  }

  Widget buildTopBar(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;

    if (controller.isSelectingComics) {
      return Material(
        elevation: 1,
        child: SizedBox(
          height: _kSecondaryTopBarHeight,
          child: Row(children: [
            Icon(
              Icons.local_activity,
              color: iconColor,
            ),
            const SizedBox(
              width: 8,
            ),
            Text(
              "已选择 @num 个项目".tlParams(
                  {"num": controller.selectedComics.length.toString()}),
              style: const TextStyle(fontSize: 16),
            ).paddingBottom(3),
            const Spacer(),
            Tooltip(
              message: "全选".tl,
              child: IconButton(
                icon: const Icon(Icons.select_all),
                onPressed: () {
                  controller.selectedComics = LocalFavoritesManager()
                      .getAllComics(controller.current!)
                      .toList();
                  controller.update();
                },
              ),
            ),
            Tooltip(
              message: "取消".tl,
              child: IconButton(
                icon: const Icon(Icons.deselect),
                onPressed: () {
                  controller.selectedComics.clear();
                  controller.update();
                },
              ),
            ),
            Tooltip(
              message: "菜单".tl,
              child: IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {
                  if (controller.selectedComics.length == 1) {
                    controller.openComicMenuFuncs[controller.selectedComics[0]]
                        ?.call();
                  } else {
                    multiSelectedMenu();
                  }
                },
              ),
            ),
          ]).paddingHorizontal(16),
        ),
      );
    }

    return Material(
      elevation: 1,
      child: InkWell(
        hoverColor: Colors.transparent,
        onTap: () {
          if (controller.selectingFolder) {
            if (controller.current == null) {
              showToast(message: "选择收藏夹".tl);
              return;
            }
            controller.selectingFolder = false;
            controller.update();
          } else {
            controller.selectingFolder = true;
            controller.update();
            appdata.implicitData[0] = "1;;";
            appdata.writeImplicitData();
          }
        },
        child: SizedBox(
          height: _kSecondaryTopBarHeight,
          child: Row(children: [
            if (controller.isNetwork == null)
              Icon(
                Icons.folder,
                color: iconColor,
              )
            else if (controller.isNetwork!)
              Icon(
                Icons.folder_special,
                color: iconColor,
              )
            else
              Icon(
                Icons.local_activity,
                color: iconColor,
              ),
            const SizedBox(
              width: 8,
            ),
            Text(
              controller.current ?? "未选择".tl,
              style: const TextStyle(fontSize: 16),
            ).paddingBottom(3),
            const Spacer(),
            if (controller.selectingFolder)
              const Icon(Icons.keyboard_arrow_up)
            else
              const Icon(Icons.keyboard_arrow_down),
          ]).paddingHorizontal(16),
        ),
      ),
    );
  }

  Widget buildFoldersList(BuildContext context, double height) {
    return Material(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: SmoothCustomScrollView(
          slivers: [
            buildTitle("网络".tl)
                .sliverPadding(const EdgeInsets.fromLTRB(12, 8, 12, 0)),
            buildNetwork().sliverPaddingHorizontal(12),
            const SliverToBoxAdapter(child: Divider())
                .sliverPaddingHorizontal(12),
            buildTitle("本地".tl).sliverPaddingHorizontal(12),
            buildUtils(context),
            buildLocal().sliverPaddingHorizontal(12),
          ],
        ),
      ),
    );
  }

  Widget buildTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(title, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget buildNetwork() {
    var folders = appdata.appSettings.networkFavorites
        .map((e) => getFavoriteDataOrNull(e));
    folders = folders.whereType<FavoriteData>();
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedHeight(
        maxCrossAxisExtent: 240,
        itemHeight: 48,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final data = folders.elementAt(index);
        return InkWell(
          onTap: () {
            controller.current = data?.title;
            controller.isNetwork = true;
            controller.selectingFolder = false;
            controller.networkData = data;
            controller.update();
            appdata.implicitData[0] = "0;1;${data?.title ?? ""}";
            appdata.writeImplicitData();
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.folder_special,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              Text(data?.title ?? "Unknown"),
            ],
          ),
        );
      }, childCount: folders.length),
    );
  }

  Widget buildLocal() {
    final folders = LocalFavoritesManager().folderNames;
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedHeight(
        maxCrossAxisExtent: 260,
        itemHeight: 48,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        final data = folders.elementAt(index);
        return GestureDetector(
          onLongPressStart: (details) =>
              _showMenu(data, details.globalPosition),
          child: InkWell(
            onTap: () {
              controller.current = data;
              controller.isNetwork = false;
              controller.selectingFolder = false;
              controller.update();
              appdata.implicitData[0] = "0;0;$data";
              appdata.writeImplicitData();
            },
            onSecondaryTapUp: (details) =>
                _showDesktopMenu(data, details.globalPosition),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(
                  Icons.local_activity,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    LocalFavoritesManager().count(data).toString(),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      }, childCount: folders.length),
    );
  }

  Widget buildUtils(BuildContext context) {
    Widget buildItem(String title, IconData icon, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: SizedBox(
          height: 72,
          width: 64,
          child: Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              )
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Wrap(
        children: [
          buildItem("新建".tl, Icons.add, () {
            showDialog(
                    context: context,
                    builder: (context) => const CreateFolderDialog())
                .then((value) => controller.update());
          }),
          buildItem("搜索".tl, Icons.search,
              () => App.to(context, () => const LocalSearchPage())),
          buildItem("排序".tl, Icons.reorder, () {
            context.to(() => const _FoldersReorderPage());
          })
        ],
      ).paddingHorizontal(12),
    );
  }

  Widget buildContent(BuildContext context) {
    if (controller.current == null) {
      return const SizedBox();
    } else if (controller.isNetwork!) {
      return NetworkFavoritePage(
        controller.networkData!,
        key: Key(controller.current ?? ""),
      );
    } else {
      var count = LocalFavoritesManager().count(controller.current!);
      return ComicsPageView(
        key: Key(controller.current! + count.toString()),
        folder: controller.current!,
        selectedComics: controller.selectedComics,
        onClick: (key) {
          if (controller.isSelectingComics) {
            if (controller.selectedComics.contains(key)) {
              controller.selectedComics.remove(key);
            } else {
              controller.selectedComics.add(key);
            }
            controller.update();
            return true;
          }
          return false;
        },
        onLongPressed: (key) {
          if (controller.selectedComics.contains(key)) {
            controller.selectedComics.remove(key);
          } else {
            controller.selectedComics.add(key);
          }
          controller.update();
        },
      );
    }
  }

  void _showMenu(String folder, Offset location) {
    showMenu(
        context: App.globalContext!,
        position: RelativeRect.fromLTRB(
            location.dx, location.dy, location.dx, location.dy),
        items: [
          PopupMenuItem(
            child: Text("删除".tl),
            onTap: () {
              App.globalBack();
              deleteFolder(folder);
            },
          ),
          PopupMenuItem(
            child: Text("排序".tl),
            onTap: () {
              App.globalBack();
              App.globalTo(() => LocalFavoritesFolder(folder))
                  .then((value) => controller.update());
            },
          ),
          PopupMenuItem(
            child: Text("重命名".tl),
            onTap: () {
              App.globalBack();
              rename(folder);
            },
          ),
          PopupMenuItem(
            child: Text("检查漫画存活".tl),
            onTap: () {
              App.globalBack();
              checkFolder(folder).then((value) {
                controller.update();
              });
            },
          ),
          PopupMenuItem(
            child: Text("导出".tl),
            onTap: () {
              App.globalBack();
              export(folder);
            },
          ),
          PopupMenuItem(
            child: Text("下载全部".tl),
            onTap: () {
              App.globalBack();
              addDownload(folder);
            },
          ),
          PopupMenuItem(
            child: Text("更新漫画信息".tl),
            onTap: () {
              App.globalBack();
              var comics = LocalFavoritesManager().getAllComics(folder);
              UpdateFavoritesInfoDialog.show(comics, folder);
            },
          ),
        ]);
  }

  void _showDesktopMenu(String folder, Offset location) {
    showDesktopMenu(App.globalContext!, location, [
      DesktopMenuEntry(
          text: "删除".tl,
          onClick: () {
            deleteFolder(folder);
          }),
      DesktopMenuEntry(
          text: "排序".tl,
          onClick: () {
            App.globalTo(() => LocalFavoritesFolder(folder))
                .then((value) => controller.update());
          }),
      DesktopMenuEntry(
          text: "重命名".tl,
          onClick: () {
            rename(folder);
          }),
      DesktopMenuEntry(
          text: "检查漫画存活".tl,
          onClick: () {
            checkFolder(folder).then((value) {
              controller.update();
            });
          }),
      DesktopMenuEntry(
          text: "导出".tl,
          onClick: () {
            export(folder);
          }),
      DesktopMenuEntry(
          text: "下载全部".tl,
          onClick: () {
            addDownload(folder);
          }),
      DesktopMenuEntry(
          text: "更新漫画信息".tl,
          onClick: () {
            var comics = LocalFavoritesManager().getAllComics(folder);
            UpdateFavoritesInfoDialog.show(comics, folder);
          }),
    ]);
  }
}

mixin class _LocalFavoritesManager {
  void deleteFolder(String folder) {
    showConfirmDialog(App.globalContext!, "确认删除".tl, "此操作无法撤销, 是否继续?", () {
      App.globalBack();
      LocalFavoritesManager().deleteFolder(folder);
      final controller = StateController.find<FavoritesPageController>();
      if (controller.current == folder && !controller.isNetwork!) {
        controller.current = null;
        controller.isNetwork = null;
      }
      controller.update();
    });
  }

  void rename(String folder) async {
    await showDialog(
        context: App.globalContext!,
        builder: (context) => RenameFolderDialog(folder));
    StateController.find<FavoritesPageController>().update();
  }

  void export(String folder) async {
    var controller = showLoadingDialog(
      App.globalContext!,
      onCancel: () {},
      message: "正在导出".tl,
    );
    try {
      await exportStringDataAsFile(
          LocalFavoritesManager().folderToJsonString(folder), "$folder.json");
      controller.close();
    } catch (e, s) {
      controller.close();
      showToast(message: e.toString());
      log("$e\n$s", "IO", LogLevel.error);
    }
  }

  void addDownload(String folder) {
    for (var comic in LocalFavoritesManager().getAllComics(folder)) {
      comic.addDownload();
    }
    showToast(message: "已添加下载任务".tl);
  }
}

class ComicsPageView extends StatefulWidget {
  const ComicsPageView(
      {required this.folder,
      required this.onClick,
      required this.selectedComics,
      required this.onLongPressed,
      super.key});

  final String folder;

  /// return true to disable default action
  final bool Function(FavoriteItem item) onClick;

  final void Function(FavoriteItem item) onLongPressed;

  final List<FavoriteItem> selectedComics;

  @override
  State<ComicsPageView> createState() => _ComicsPageViewState();
}

class _ComicsPageViewState extends StateWithController<ComicsPageView> {
  late ScrollController scrollController;
  bool showFB = true;
  double location = 0;

  String get folder => widget.folder;

  FolderSync? folderSync() {
    final folderSyncArr = LocalFavoritesManager()
        .folderSync
        .where((element) => element.folderName == folder)
        .toList();
    if (folderSyncArr.isEmpty) return null;
    return folderSyncArr[0];
  }

  late List<FavoriteItem> comics;

  @override
  void initState() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      var current = scrollController.offset;

      if ((current > location && current != 0) && showFB) {
        setState(() {
          showFB = false;
        });
      } else if ((current < location || current == 0) && !showFB) {
        setState(() {
          showFB = true;
        });
      }

      location = current;
    });
    comics = LocalFavoritesManager().getAllComics(folder);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return buildFolderComics(folder);
  }

  void rebuild() {
    setState(() {
      comics = LocalFavoritesManager().getAllComics(folder);
    });
  }

  Future<void> onRefresh(context) async {
    return startFolderSync(context, folderSync()!);
  }

  Widget buildFolderComics(String folder) {
    if (comics.isEmpty) {
      return buildEmptyView();
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removePadding(
        key: Key(folder),
        removeTop: true,
        context: context,
        child: RefreshIndicator(
          notificationPredicate: (notify) {
            return folderSync() != null;
          },
          onRefresh: () => onRefresh(context),
          child: Scrollbar(
            controller: scrollController,
            interactive: true,
            thickness: App.isMobile ? 12 : null,
            radius: const Radius.circular(8),
            child: ScrollConfiguration(
              behavior: const ScrollBehavior().copyWith(scrollbars: false),
              child: SmoothScrollProvider(
                controller: scrollController,
                builder: (context, controller, physic) {
                  return GridView.builder(
                    key: Key(folder),
                    primary: false,
                    controller: controller,
                    gridDelegate: SliverGridDelegateWithComics(),
                    itemCount: comics.length,
                    padding: EdgeInsets.zero,
                    physics: physic,
                    itemBuilder: (BuildContext context, int index) {
                      var comic = comics[index];
                      var tile = LocalFavoriteTile(
                        key: ValueKey(comic.toString()),
                        comic,
                        folder,
                        () {
                          rebuild();
                          if(widget.selectedComics.contains(comic)) {
                            var c = StateController.find<FavoritesPageController>();
                            c.selectedComics.remove(comic);
                            c.update();
                          }
                        },
                        true,
                        onTap: () => widget.onClick(comic),
                        onLongPressed: () => widget.onLongPressed(comic),
                        showFolderInfo: true,
                      );
                      StateController.find<FavoritesPageController>()
                          .openComicMenuFuncs[comic] = tile.showMenu;

                      Color? color;

                      if (widget.selectedComics.contains(comic)) {
                        color = Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest;
                      }
                      return AnimatedContainer(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 4),
                        duration: const Duration(milliseconds: 160),
                        child: tile,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 150),
        child: showFB && folderSync() != null ? buildFAB() : const SizedBox(),
        transitionBuilder: (widget, animation) {
          var tween =
              Tween<Offset>(begin: const Offset(0, 1), end: const Offset(0, 0));
          return SlideTransition(
            position: tween.animate(animation),
            child: widget,
          );
        },
      ),
    );
  }

  Widget buildFAB() => Material(
        color: Colors.transparent,
        child: FloatingActionButton(
          key: const Key("FAB"),
          onPressed: () => onRefresh(context),
          child: const Icon(Icons.refresh),
        ),
      );

  Widget buildEmptyView() {
    return Padding(
      padding: const EdgeInsets.only(top: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("这里什么都没有".tl),
          const SizedBox(
            height: 8,
          ),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '前往'.tl,
                ),
                TextSpan(
                  text: '探索页面'.tl,
                ),
                TextSpan(
                  text: '寻找漫画'.tl,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Object? get tag => "ComicsPageView $folder";

  @override
  refresh() {
    comics = LocalFavoritesManager().getAllComics(folder);
    update();
  }
}

class _FoldersReorderPage extends StatefulWidget {
  const _FoldersReorderPage();

  @override
  State<_FoldersReorderPage> createState() => _FoldersReorderPageState();
}

class _FoldersReorderPageState extends State<_FoldersReorderPage> {
  var folders = LocalFavoritesManager().folderNames;
  var changed = false;

  final reorderKey = UniqueKey();
  final _scrollController = ScrollController();
  final _key = GlobalKey();

  Color lightenColor(Color color, double lightenValue) {
    int red = (color.red + ((255 - color.red) * lightenValue)).round();
    int green = (color.green + ((255 - color.green) * lightenValue)).round();
    int blue = (color.blue + ((255 - color.blue) * lightenValue)).round();

    return Color.fromARGB(color.alpha, red, green, blue);
  }

  @override
  void dispose() {
    if (changed) {
      LocalFavoritesManager().updateOrder(Map<String, int>.fromEntries(
          folders.mapIndexed((index, element) => MapEntry(element, index))));
      scheduleMicrotask(() {
        StateController.find<FavoritesPageController>().update();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tiles = List.generate(
        folders.length,
        (index) => MouseRegion(
              key: ValueKey(folders[index]),
              cursor: SystemMouseCursors.click,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.local_activity,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      folders[index],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ));

    return Scaffold(
      appBar: AppBar(title: Text("排序".tl)),
      body: Column(
        children: [
          Expanded(
            child: ReorderableBuilder(
              key: reorderKey,
              scrollController: _scrollController,
              longPressDelay: App.isDesktop
                  ? const Duration(milliseconds: 100)
                  : const Duration(milliseconds: 500),
              onReorder: (reorderFunc) {
                changed = true;
                setState(() {
                  folders = reorderFunc(folders) as List<String>;
                });
              },
              dragChildBoxDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: lightenColor(
                      Theme.of(context).splashColor.withOpacity(1), 0.2)),
              builder: (children) {
                return GridView(
                  key: _key,
                  controller: _scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedHeight(
                    maxCrossAxisExtent: 260,
                    itemHeight: 56,
                  ),
                  children: children,
                );
              },
              children: tiles,
            ),
          )
        ],
      ),
    );
  }
}
