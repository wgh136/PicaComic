import 'dart:ui';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_comic_page.dart';
import 'package:pica_comic/views/ht_views/ht_comic_page.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'dart:io';
import '../foundation/app.dart';
import '../foundation/ui_mode.dart';
import '../network/eh_network/eh_main_network.dart';
import '../network/hitomi_network/hitomi_main_network.dart';
import '../network/hitomi_network/hitomi_models.dart';
import '../network/htmanga_network/htmanga_main_network.dart';
import '../network/jm_network/jm_main_network.dart';
import '../network/nhentai_network/nhentai_main_network.dart';
import '../network/picacg_network/methods.dart';
import 'main_page.dart';


class LocalFavoritesPage extends StatefulWidget {
  const LocalFavoritesPage({super.key});

  @override
  State<LocalFavoritesPage> createState() => _LocalFavoritesPageState();
}

class _LocalFavoritesPageState extends State<LocalFavoritesPage> {
  @override
  void dispose() {
    LocalFavoritesManager().saveData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (LocalFavoritesManager().folderNames == null) {
      LocalFavoritesManager().readData().then((v) => setState(() => {}));
      return Center(
        child: Text("加载中".tl),
      );
    } else {
      var names = LocalFavoritesManager().folderNames!;
      return CustomScrollView(
        slivers: [
          SliverGrid(
            delegate: SliverChildBuilderDelegate(childCount: names.length + 1,
                (context, i) {
              if(i == 0){
                return Material(
                  child: InkWell(
                    onTap: () => MainPage.to(() => const AllLocalFavorites()),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 2.5,
                          ),
                          Expanded(
                            flex: 1,
                            child: Icon(
                              Icons.folder,
                              size: 35,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          const SizedBox(
                            width: 2.5,
                          ),
                          Expanded(
                            flex: 4,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "全部".tl,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => MainPage.to(() => const AllLocalFavorites()),
                            icon: const Icon(Icons.open_in_new)),
                          const SizedBox(
                            width: 5,
                          )
                        ],
                      ),
                    ),
                  ),
                );
              }else {
                i--;
                return FolderTile(
                    name: names[i], onDelete: () => setState(() {}));
              }
            }),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 500,
              childAspectRatio: 5,
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              width: double.infinity,
              child: Center(
                child: TextButton(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("创建收藏夹".tl),
                      const Icon(
                        Icons.add,
                        size: 18,
                      ),
                    ],
                  ),
                  onPressed: () async {
                    await showDialog(
                        context: context,
                        builder: (context) {
                          return const CreateFolderDialog();
                        });
                    setState(() {});
                  },
                ),
              ),
            ),
          )
        ],
      );
    }
  }
}

class FolderTile extends StatelessWidget {
  const FolderTile({required this.name, required this.onDelete, super.key});

  final String name;

  final void Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () => MainPage.to(() => LocalFavoritesFolder(name)),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              const SizedBox(
                width: 2.5,
              ),
              Expanded(
                flex: 1,
                child: Icon(
                  Icons.folder,
                  size: 35,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              const SizedBox(
                width: 2.5,
              ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever_outlined),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("确认删除".tl),
                          content: Text("要删除这个收藏夹吗".tl),
                          actions: [
                            TextButton(
                                onPressed: () => Get.back(),
                                child: Text("取消".tl)),
                            TextButton(
                                onPressed: () async {
                                  LocalFavoritesManager().deleteFolder(name);
                                  onDelete();
                                  Get.back();
                                },
                                child: Text("确认".tl)),
                          ],
                        );
                      });
                },
              ),
              const SizedBox(
                width: 5,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({Key? key}) : super(key: key);

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  var controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("创建收藏夹".tl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            onEditingComplete: () {
              try {
                LocalFavoritesManager().createFolder(controller.text);
                Get.back();
              } catch (e) {
                showMessage(context, "e");
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "名称".tl,
            ),
          ),
        ),
        const SizedBox(
          width: 200,
          height: 10,
        ),
        SizedBox(
            height: 35,
            child: Center(
              child: TextButton(
                  onPressed: () {
                    try {
                      LocalFavoritesManager().createFolder(controller.text);
                      Get.back();
                    } catch (e) {
                      showMessage(context, "e");
                    }
                  },
                  child: Text("提交".tl)),
            ))
      ],
    );
  }
}

class LocalFavoriteTile extends ComicTile {
  const LocalFavoriteTile(this.comic, this.folderName, this.onDelete, this._enableLongPressed,
      {this.showFolderInfo = false, super.key});

  final FavoriteItem comic;

  final String folderName;

  final void Function() onDelete;

  final bool _enableLongPressed;

  final bool showFolderInfo;

  static Map<String, File> cache = {};

  @override
  String? get badge => showFolderInfo ? folderName : null;

  @override
  bool get enableLongPressed => _enableLongPressed;

  @override
  String get description => comic.time;

  @override
  Widget get image => cache[comic.target] == null ? FutureBuilder<File>(
        future: LocalFavoritesManager().getCover(comic.coverPath),
        builder: (context, file) {
          if (file.data == null) {
            return ColoredBox(
                color: Theme.of(context).colorScheme.secondaryContainer);
          } else {
            cache[comic.target] = file.data!;
            return Image.file(
              file.data!,
              fit: BoxFit.cover,
              height: double.infinity,
              filterQuality: FilterQuality.medium,
            );
          }
        },
      ) : Image.file(
        cache[comic.target]!,
        fit: BoxFit.cover,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
      );

  @override
  void onTap_() {
    switch (comic.type) {
      case ComicType.picacg:
        MainPage.to(() => PicacgComicPage(ComicItemBrief(
            comic.name, comic.author, 0, comic.coverPath, comic.target, [],
            ignoreExamination: true)));
      case ComicType.ehentai:
        MainPage.to(() => EhGalleryPage(EhGalleryBrief(comic.name, "", "",
            comic.author, comic.coverPath, 0, comic.target, comic.tags,
            ignoreExamination: true)));
      case ComicType.jm:
        MainPage.to(() => JmComicPage(comic.target));
      case ComicType.hitomi:
        MainPage.to(() => HitomiComicPage(HitomiComicBrief(
              comic.name,
              "",
              "",
              List.generate(
                  comic.tags.length, (index) => Tag(comic.tags[index], "")),
              "",
              comic.author,
              comic.target,
              comic.coverPath,
            )));
      case ComicType.htManga:
        MainPage.to(() => HtComicPage(HtComicBrief(comic.name, "", comic.coverPath,
            comic.target, int.parse(comic.author.replaceFirst("Pages", "")),
            ignoreExamination: true)));
      case ComicType.nhentai:
        MainPage.to(() => NhentaiComicPage(comic.target));
      case ComicType.htFavorite:
        throw UnimplementedError();
    }
  }

  @override
  String get subTitle => comic.author;

  @override
  String get title => comic.name;

  List<String> _generateTags(List<String> tags) {
    if (PlatformDispatcher.instance.locale.languageCode != "zh") {
      return tags;
    }
    List<String> res = [];
    List<String> res2 = [];
    for (var tag in tags) {
      if (tag.contains(":")) {
        var splits = tag.split(":");
        var lowLevelKey = ["character", "artist", "cosplayer", "group"];
        if (lowLevelKey.contains(splits[0])) {
          res2.add(splits[1].translateTagsToCN);
        } else {
          res.add(splits[1].translateTagsToCN);
        }
      } else {
        var name = tag;
        if (name.contains('♀')) {
          name = "${name.replaceFirst(" ♀", "").translateTagsToCN}♀";
        } else if (name.contains('♂')) {
          name = "${name.replaceFirst(" ♂", "").translateTagsToCN}♂";
        } else {
          name = name.translateTagsToCN;
        }
        res.add(name);
      }
    }
    return res + res2;
  }

  @override
  List<String>? get tags => _generateTags(comic.tags);

  //@override
  //bool get enableLongPressed => false;

  @override
  void onSecondaryTap_(TapDownDetails details) {
    showMenu(
        context: Get.context!,
        position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy),
        items: [
          PopupMenuItem(
              onTap: () => Future.delayed(
                  const Duration(milliseconds: 200), () => onTap_()),
              child: Text("查看".tl)),
          PopupMenuItem(
            child: Text("取消收藏".tl),
            onTap: () {
              LocalFavoritesManager().deleteComic(folderName, comic);
              onDelete();
            },
          ),
          PopupMenuItem(
            onTap: read,
            child: Text("阅读".tl),
          ),
        ]);
  }

  @override
  void onLongTap_() {
    showDialog(
        context: Get.context!,
        builder: (context) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        title.replaceAll("\n", ""),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.article),
                      title: Text("查看详情".tl),
                      onTap: onTap_,
                    ),
                    ListTile(
                      leading: const Icon(Icons.bookmark_remove),
                      title: Text("取消收藏".tl),
                      onTap: () {
                        Get.back();
                        LocalFavoritesManager().deleteComic(folderName, comic);
                        onDelete();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chrome_reader_mode_rounded),
                      title: Text("阅读".tl),
                      onTap: (){
                        Get.back();
                        read();
                      },
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
            ));
  }

  @override
  ActionFunc get read => () async{
    switch (comic.type) {
      case ComicType.picacg:
        {
          bool cancel = false;
          showLoadingDialog(Get.context!, ()=>cancel=true);
          var res = await network.getEps(comic.target);
          if(cancel){
            return;
          }
          if(res.error){
            Get.back();
            showMessage(Get.context, res.errorMessageWithoutNull);
          }else{
            Get.back();
            readPicacgComic2(ComicItemBrief(
                comic.name, comic.author, 0, comic.coverPath, comic.target, [],
                ignoreExamination: true), res.data);
          }
        }
      case ComicType.ehentai:
        {
          bool cancel = false;
          showLoadingDialog(Get.context!, ()=>cancel=true);
          var res = await EhNetwork().getGalleryInfo(comic.target);
          if(cancel){
            return;
          }
          if(res.error){
            Get.back();
            showMessage(Get.context, res.errorMessageWithoutNull);
          }else{
            Get.back();
            readEhGallery(res.data);
          }
        }
      case ComicType.jm:
        {
          bool cancel = false;
          showLoadingDialog(Get.context!, ()=>cancel=true);
          var res = await JmNetwork().getComicInfo(comic.target);
          if(cancel){
            return;
          }
          if(res.error){
            Get.back();
            showMessage(Get.context, res.errorMessageWithoutNull);
          }else{
            Get.back();
            readJmComic(res.data, res.data.series.values.toList());
          }
        }
      case ComicType.hitomi:
        {
          bool cancel = false;
          showLoadingDialog(Get.context!, ()=>cancel=true);
          var res = await HiNetwork().getComicInfo(comic.target);
          if(cancel){
            return;
          }
          if(res.error){
            Get.back();
            showMessage(Get.context, res.errorMessageWithoutNull);
          }else{
            Get.back();
            readHitomiComic(res.data, comic.coverPath);
          }
        }
      case ComicType.htManga:
        {
          bool cancel = false;
          showLoadingDialog(Get.context!, ()=>cancel=true);
          var res = await HtmangaNetwork().getComicInfo(comic.target);
          if(cancel){
            return;
          }
          if(res.error){
            Get.back();
            showMessage(Get.context, res.errorMessageWithoutNull);
          }else{
            Get.back();
            readHtmangaComic(res.data);
          }
        }
      case ComicType.nhentai:
        {
          bool cancel = false;
          showLoadingDialog(Get.context!, ()=>cancel=true);
          var res = await NhentaiNetwork().getComicInfo(comic.target);
          if(cancel){
            return;
          }
          if(res.error){
            Get.back();
            showMessage(Get.context, res.errorMessageWithoutNull);
          }else{
            Get.back();
            readNhentai(res.data);
          }
        }
      case ComicType.htFavorite:
        throw UnimplementedError();
    }
  };
}

class AllLocalFavorites extends StatefulWidget {
  const AllLocalFavorites({super.key});

  @override
  State<AllLocalFavorites> createState() => _AllLocalFavoritesState();
}

class _AllLocalFavoritesState extends State<AllLocalFavorites> {
  late final comics = LocalFavoritesManager().allComics();
  bool searchMode = false;
  String keyword = "";
  var results = <FavoriteItemWithFolderInfo>[];

  Widget buildTitle(){
    if(searchMode){
      return Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top / 2),
        child: Center(
          child: Container(
            height: 42,
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 6),
            child: TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "搜索".tl
              ),
              onChanged: (s){
                setState(() {
                  keyword = s.toLowerCase();
                });
              },
            ),
          ),
        ),
      );
    }else{
      return const Text("ALL");
    }
  }

  void find(){
    results.clear();
    if(keyword == ""){
      results.addAll(comics);
    }else{
      bool findTag(FavoriteItemWithFolderInfo comic){
        for(var element in comic.comic.tags){
          if(element.contains(':')){
            element = element.split(':').elementAtOrNull(1) ?? element;
          }
          if(element.contains(keyword) || element.translateTagsToCN.contains(keyword)){
            return true;
          }
        }
        return false;
      }
      for (var element in comics) {
        if(element.comic.name.toLowerCase().contains(keyword)
            || element.comic.author.toLowerCase().contains(keyword)
            || element.folder.toLowerCase() == keyword
            || findTag(element)){
          results.add(element);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if(searchMode){
      find();
    }
    return Scaffold(
      body: Column(
        children: [
          CustomAppbar(title: buildTitle(),actions: [
            Tooltip(
              message: "搜索".tl,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    searchMode = !searchMode;
                    if(!searchMode){
                      keyword = "";
                    }
                  });
                },
              ),
            )
          ],),
          if(searchMode)
            buildComics(results)
          else
            buildComics(comics)
        ],
      ),
    );
  }

  Widget buildComics(List<FavoriteItemWithFolderInfo> comics){
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: App.comicTileMaxWidth,
          childAspectRatio: App.comicTileAspectRatio,
        ),
        itemCount: comics.length,
        itemBuilder: (BuildContext context, int index) {
          return LocalFavoriteTile(comics[index].comic, comics[index].folder, () {
            comics.clear();
            setState(() {
              comics = LocalFavoritesManager().allComics();
            });
          }, true, showFolderInfo: true,);
        },
      ),
    );
  }
}


class LocalFavoritesFolder extends StatefulWidget {
  const LocalFavoritesFolder(this.name, {super.key});

  final String name;

  @override
  State<LocalFavoritesFolder> createState() => _LocalFavoritesFolderState();
}

class _LocalFavoritesFolderState extends State<LocalFavoritesFolder> {
  final _key = GlobalKey();
  var reorderWidgetKey = UniqueKey();
  final _scrollController = ScrollController();
  late var comics = LocalFavoritesManager().getAllComics(widget.name);
  double? width;
  bool changed = false;
  bool enableSort = false;

  Color lightenColor(Color color, double lightenValue) {
    int red = (color.red + ((255 - color.red) * lightenValue)).round();
    int green = (color.green + ((255 - color.green) * lightenValue)).round();
    int blue = (color.blue + ((255 - color.blue) * lightenValue)).round();

    return Color.fromARGB(color.alpha, red, green, blue);
  }

  @override
  void initState() {
    width = MediaQuery.of(Get.context!).size.width;
    super.initState();
  }

  @override
  void dispose() {
    if(changed){
      LocalFavoritesManager().reorder(comics!, widget.name);
    }
    LocalFavoriteTile.cache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tiles = List.generate(comics!.length, (index) => LocalFavoriteTile(
        comics![index], widget.name, () {
          setState(() {
            comics = LocalFavoritesManager().getAllComics(widget.name);
          });
    }, !enableSort, key: Key(comics![index].target),));
    return Scaffold(
      appBar: UiMode.m1(context) ? AppBar(
        title: Text(widget.name), actions: [
        SizedBox(
          width: 90,
          height: 56,
          child: Row(
            children: [
              Text("排序".tl),
              Transform.scale(
                scale: 0.6,
                child: Switch(value: enableSort, onChanged: (value) {
                  var currentWidth = MediaQuery.of(context).size.width;
                  if(currentWidth != width){
                    width = currentWidth;
                    reorderWidgetKey = UniqueKey();
                  }
                  setState(() => enableSort = value);
                }),
              )
            ],
          ),
        )
      ]
      ) : null,
      body: Column(
        children: [
          if(!UiMode.m1(context))
            CustomAppbar(title: Text(widget.name), actions: [
              SizedBox(
                width: 90,
                height: 56,
                child: Row(
                  children: [
                    Text("排序".tl),
                    Transform.scale(
                      scale: 0.6,
                      child: Switch(value: enableSort, onChanged: (value) {
                        var currentWidth = MediaQuery.of(context).size.width;
                        if(currentWidth != width){
                          width = currentWidth;
                          reorderWidgetKey = UniqueKey();
                        }
                        setState(() => enableSort = value);
                      }),
                    )
                  ],
                ),
              )
            ],),
          Expanded(
            child: ReorderableBuilder(
              key: reorderWidgetKey,
              scrollController: _scrollController,
              enableDraggable: enableSort,
              longPressDelay: GetPlatform.isDesktop ? const Duration(milliseconds: 100) : const Duration(milliseconds: 500),
              onReorder: (reorderFunc){
                changed = true;
                setState(() {
                  comics = reorderFunc(comics!) as List<FavoriteItem>;
                });
              },
              dragChildBoxDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: lightenColor(Theme.of(context).splashColor.withOpacity(1), 0.2)
              ),
              builder: (children){
                return GridView(
                  key: _key,
                  controller: _scrollController,
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: App.comicTileMaxWidth,
                    childAspectRatio: App.comicTileAspectRatio,
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
