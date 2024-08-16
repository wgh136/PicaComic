import 'package:flutter/material.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/pages/comic_page.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/foundation/history.dart';
import '../base.dart';
import '../foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';

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
      body: SmoothCustomScrollView(
        slivers: [
          SliverAppbar(
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
                EdgeInsets.only(top: MediaQuery.of(context).padding.bottom),
          )
        ],
      ),
    );
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
        );
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
            toComicPageWithHistory(context, comics_[i]);
          },
        );
      }),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }
}

void toComicPageWithHistory(BuildContext context, History history) {
  var source = history.type.comicSource;
  if (source == null) {
    showToast(message: "Comic Source Not Found");
    return;
  }
  context.to(
    () => ComicPage(
      sourceKey: source.key,
      id: history.target,
      cover: history.cover,
    ),
  );
}
