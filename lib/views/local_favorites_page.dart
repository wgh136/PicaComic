import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:flutter/material.dart';
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
import 'package:pica_comic/views/widgets/comic_tile.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'dart:io';
import '../foundation/app.dart';
import '../network/eh_network/eh_main_network.dart';
import '../network/hitomi_network/hitomi_main_network.dart';
import '../network/hitomi_network/hitomi_models.dart';
import '../network/htmanga_network/htmanga_main_network.dart';
import '../network/jm_network/jm_main_network.dart';
import '../network/nhentai_network/nhentai_main_network.dart';
import '../network/picacg_network/methods.dart';
import 'main_page.dart';


class CreateFolderDialog extends StatelessWidget {
  const CreateFolderDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
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
                App.globalBack();
              } catch (e) {
                showMessage(context, e.toString());
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
                      App.globalBack();
                    } catch (e) {
                      showMessage(context, e.toString());
                    }
                  },
                  child: Text("提交".tl)),
            ))
      ],
    );
  }
}

class RenameFolderDialog extends StatelessWidget {
  const RenameFolderDialog(this.before, {Key? key}) : super(key: key);

  final String before;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();
    return SimpleDialog(
      title: Text("重命名".tl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            onEditingComplete: () {
              try {
                LocalFavoritesManager().rename(before, controller.text);
                App.globalBack();
              } catch (e) {
                showMessage(context, e.toString());
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
                      LocalFavoritesManager().rename(before, controller.text);
                      App.globalBack();
                    } catch (e) {
                      showMessage(context, e.toString());
                    }
                  },
                  child: Text("提交".tl)),
            ))
      ],
    );
  }
}

class LocalFavoriteTile extends ComicTile {
  const LocalFavoriteTile(
      this.comic, this.folderName, this.onDelete, this._enableLongPressed,
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
  String get description => "${comic.time} | ${comic.type.name}";

  @override
  Widget get image => cache[comic.target] == null
      ? FutureBuilder<File>(
          future: LocalFavoritesManager().getCover(comic),
          builder: (context, file) {
            if (file.hasError) {
              return ColoredBox(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Center(child: Icon(Icons.error)));
            }
            if (file.data == null) {
              return ColoredBox(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                  ));
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
        )
      : Image.file(
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
        MainPage.to(() => HtComicPage(HtComicBrief(
            comic.name,
            "",
            comic.coverPath,
            comic.target,
            int.parse(comic.author.replaceFirst("Pages", "")),
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
    if (App.locale.languageCode != "zh") {
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
        context: App.globalContext!,
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
        context: App.globalContext!,
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
                        App.globalBack();
                        LocalFavoritesManager().deleteComic(folderName, comic);
                        onDelete();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.chrome_reader_mode_rounded),
                      title: Text("阅读".tl),
                      onTap: () {
                        App.globalBack();
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
  ActionFunc get read => () async {
        switch (comic.type) {
          case ComicType.picacg:
            {
              bool cancel = false;
              showLoadingDialog(App.globalContext!, () => cancel = true);
              var res = await network.getEps(comic.target);
              if (cancel) {
                return;
              }
              if (res.error) {
                App.globalBack();
                showMessage(App.globalContext, res.errorMessageWithoutNull);
              } else {
                App.globalBack();
                readPicacgComic2(
                    ComicItemBrief(comic.name, comic.author, 0, comic.coverPath,
                        comic.target, [],
                        ignoreExamination: true),
                    res.data);
              }
            }
          case ComicType.ehentai:
            {
              bool cancel = false;
              showLoadingDialog(App.globalContext!, () => cancel = true);
              var res = await EhNetwork().getGalleryInfo(comic.target);
              if (cancel) {
                return;
              }
              if (res.error) {
                App.globalBack();
                showMessage(App.globalContext, res.errorMessageWithoutNull);
              } else {
                App.globalBack();
                readEhGallery(res.data);
              }
            }
          case ComicType.jm:
            {
              bool cancel = false;
              showLoadingDialog(App.globalContext!, () => cancel = true);
              var res = await JmNetwork().getComicInfo(comic.target);
              if (cancel) {
                return;
              }
              if (res.error) {
                App.globalBack();
                showMessage(App.globalContext, res.errorMessageWithoutNull);
              } else {
                App.globalBack();
                readJmComic(res.data, res.data.series.values.toList());
              }
            }
          case ComicType.hitomi:
            {
              bool cancel = false;
              showLoadingDialog(App.globalContext!, () => cancel = true);
              var res = await HiNetwork().getComicInfo(comic.target);
              if (cancel) {
                return;
              }
              if (res.error) {
                App.globalBack();
                showMessage(App.globalContext, res.errorMessageWithoutNull);
              } else {
                App.globalBack();
                readHitomiComic(res.data, comic.coverPath);
              }
            }
          case ComicType.htManga:
            {
              bool cancel = false;
              showLoadingDialog(App.globalContext!, () => cancel = true);
              var res = await HtmangaNetwork().getComicInfo(comic.target);
              if (cancel) {
                return;
              }
              if (res.error) {
                App.globalBack();
                showMessage(App.globalContext, res.errorMessageWithoutNull);
              } else {
                App.globalBack();
                readHtmangaComic(res.data);
              }
            }
          case ComicType.nhentai:
            {
              bool cancel = false;
              showLoadingDialog(App.globalContext!, () => cancel = true);
              var res = await NhentaiNetwork().getComicInfo(comic.target);
              if (cancel) {
                return;
              }
              if (res.error) {
                App.globalBack();
                showMessage(App.globalContext, res.errorMessageWithoutNull);
              } else {
                App.globalBack();
                readNhentai(res.data);
              }
            }
          case ComicType.htFavorite:
            throw UnimplementedError();
        }
      };
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

  Color lightenColor(Color color, double lightenValue) {
    int red = (color.red + ((255 - color.red) * lightenValue)).round();
    int green = (color.green + ((255 - color.green) * lightenValue)).round();
    int blue = (color.blue + ((255 - color.blue) * lightenValue)).round();

    return Color.fromARGB(color.alpha, red, green, blue);
  }

  @override
  void initState() {
    width = MediaQuery.of(App.globalContext!).size.width;
    super.initState();
  }

  @override
  void dispose() {
    if (changed) {
      LocalFavoritesManager().saveData();
    }
    LocalFavoriteTile.cache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tiles = List.generate(
        comics!.length,
        (index) => LocalFavoriteTile(
              comics![index],
              widget.name,
              () {
                changed = true;
                setState(() {
                  comics = LocalFavoritesManager().getAllComics(widget.name);
                });
              },
              false,
              key: Key(comics![index].target),
            ));
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(
        children: [
          Expanded(
            child: ReorderableBuilder(
              key: reorderWidgetKey,
              scrollController: _scrollController,
              longPressDelay: App.isDesktop
                  ? const Duration(milliseconds: 100)
                  : const Duration(milliseconds: 500),
              onReorder: (reorderFunc) {
                changed = true;
                setState(() {
                  comics = reorderFunc(comics!) as List<FavoriteItem>;
                });
                LocalFavoritesManager().reorder(comics!, widget.name);
              },
              dragChildBoxDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: lightenColor(
                      Theme.of(context).splashColor.withOpacity(1), 0.2)),
              builder: (children) {
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
