import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_comic_page.dart';
import 'package:pica_comic/views/ht_views/ht_comic_page.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/normal_comic_tile.dart';
import '../base.dart';
import '../foundation/app.dart';
import '../network/jm_network/jm_image.dart';
import 'package:pica_comic/tools/translations.dart';
import 'main_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final comics = HistoryManager().getAll();
  bool searchMode = false;
  String keyword = "";
  var results = <History>[];
  bool isModified = false;

  @override
  void dispose() {
    if (isModified) {
      appdata.history.saveData();
    }
    super.dispose();
  }

  Widget buildTitle() {
    if (searchMode) {
      return Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top / 2),
        child: Center(
          child: Container(
            height: 42,
            padding: const EdgeInsets.fromLTRB(0, 0, 8, 6),
            child: TextField(
              decoration:
                  InputDecoration(border: InputBorder.none, hintText: "搜索".tl),
              onChanged: (s) {
                setState(() {
                  keyword = s.toLowerCase();
                });
              },
            ),
          ),
        ),
      );
    } else {
      return Text("${"历史记录".tl}(${comics.length})");
    }
  }

  void find() {
    results.clear();
    if (keyword == "") {
      results.addAll(comics);
    } else {
      for (var element in comics) {
        if (element.title.toLowerCase().contains(keyword) ||
            element.subtitle.toLowerCase().contains(keyword)) {
          results.add(element);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (searchMode) {
      find();
    }
    return Scaffold(
        body: CustomScrollView(
      slivers: [
        CustomSmallSliverAppbar(
          title: buildTitle(),
          actions: [
            Tooltip(
              message: "清除".tl,
              child: IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () => showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                          title: Text("清除记录".tl),
                          content: Text("要清除历史记录吗?".tl),
                          actions: [
                            TextButton(
                                onPressed: () => App.globalBack(),
                                child: Text("取消".tl)),
                            TextButton(
                                onPressed: () {
                                  appdata.history.clearHistory();
                                  setState(() => comics.clear());
                                  isModified = true;
                                  App.globalBack();
                                },
                                child: Text("清除".tl)),
                          ],
                        )),
              ),
            ),
            Tooltip(
              message: "搜索".tl,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    searchMode = !searchMode;
                    if (!searchMode) {
                      keyword = "";
                    }
                  });
                },
              ),
            )
          ],
        ),
        if (!searchMode) buildComics(comics) else buildComics(results),
        SliverPadding(
            padding:
                EdgeInsets.only(top: MediaQuery.of(context).padding.bottom))
      ],
    ));
  }

  Widget buildComics(List<History> comics_) {
    return SliverGrid(
      delegate:
          SliverChildBuilderDelegate(childCount: comics_.length, (context, i) {
        final comic = ComicItemBrief(
            comics_[i].title,
            comics_[i].subtitle,
            0,
            comics_[i].cover != ""
                ? comics_[i].cover
                : getJmCoverUrl(comics_[i].target),
            comics_[i].target,
            [],
            ignoreExamination: true);
        return NormalComicTile(
          key: Key(comics_[i].target),
          onLongTap: () {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("删除".tl),
                    content: Text("要删除这条历史记录吗".tl),
                    actions: [
                      TextButton(
                          onPressed: () => App.globalBack(),
                          child: Text("取消".tl)),
                      TextButton(
                          onPressed: () {
                            appdata.history.remove(comics_[i].target);
                            setState(() {
                              isModified = true;
                              comics.removeWhere((element) =>
                                  element.target == comics_[i].target);
                            });
                            App.globalBack();
                          },
                          child: Text("删除".tl)),
                    ],
                  );
                });
          },
          description_: timeToString(comics_[i].time),
          coverPath: comic.path,
          name: comic.title,
          subTitle_: comic.author,
          badgeName: comics_[i].type.name,
          headers: {
            if (comics_[i].type == HistoryType.ehentai)
              "cookie": EhNetwork().cookiesStr,
            if (comics_[i].type == HistoryType.ehentai ||
                comics_[i].type == HistoryType.hitomi)
              "User-Agent": webUA,
            if (comics_[i].type == HistoryType.hitomi)
              "Referer": "https://hitomi.la/"
          },
          onTap: () {
            if (comics_[i].type == HistoryType.picacg) {
              MainPage.to(() => PicacgComicPage(comic));
            } else if (comics_[i].type == HistoryType.ehentai) {
              MainPage.to(() => EhGalleryPage(EhGalleryBrief(
                  comics_[i].title,
                  "",
                  "",
                  comics_[i].subtitle,
                  comics_[i].cover,
                  0.0,
                  comics_[i].target, [])));
            } else if (comics_[i].type == HistoryType.jmComic) {
              MainPage.to(() => JmComicPage(comics_[i].target));
            } else if (comics_[i].type == HistoryType.hitomi) {
              MainPage.to(() => HitomiComicPage(HitomiComicBrief(
                  comics_[i].title,
                  "",
                  "",
                  [],
                  "",
                  "",
                  comics_[i].target,
                  comics_[i].cover)));
            } else if (comics_[i].type == HistoryType.htmanga) {
              MainPage.to(() => HtComicPage(HtComicBrief(comics_[i].title, "",
                  comics_[i].cover, comics_[i].target, 0)));
            } else {
              MainPage.to(() => NhentaiComicPage(comics_[i].target));
            }
          },
        );
      }),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }
}
