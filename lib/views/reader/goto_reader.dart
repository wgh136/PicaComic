import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/nhentai_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/foundation/history.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../../network/hitomi_network/hitomi_models.dart';
import '../../network/jm_network/jm_image.dart';
import '../../network/jm_network/jm_models.dart';
import 'comic_reading_page.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';

Future<void> addPicacgHistory(ComicItem comic) async {
  var history = History(HistoryType.picacg, DateTime.now(), comic.title,
      comic.author, comic.thumbUrl, 0, 0, comic.id);
  await appdata.history.addHistory(history);
}

Future<void> addEhHistory(Gallery gallery) async {
  var history = History(HistoryType.ehentai, DateTime.now(), gallery.title,
      gallery.uploader, gallery.coverPath, 0, 0, gallery.link);
  await appdata.history.addHistory(history);
}

Future<void> addJmHistory(JmComicInfo comic) async {
  var history = History(
      HistoryType.jmComic,
      DateTime.now(),
      comic.name,
      comic.author.elementAtOrNull(0) ?? "未知".tl,
      getJmCoverUrl(comic.id),
      0,
      0,
      comic.id);
  await appdata.history.addHistory(history);
}

Future<void> addHitomiHistory(HitomiComic comic, String cover) async {
  var history = History(
      HistoryType.hitomi,
      DateTime.now(),
      comic.name,
      (comic.artists ?? ["未知".tl]).elementAtOrNull(0) ?? "未知".tl,
      cover,
      0,
      0,
      comic.id);
  await appdata.history.addHistory(history);
}

Future<void> addHtmangaHistory(HtComicInfo comic) async {
  var history = History(HistoryType.htmanga, DateTime.now(), comic.name,
      comic.uploader, comic.coverPath, 0, 0, comic.id);
  await appdata.history.addHistory(history);
}

Future<void> addNhentaiHistory(NhentaiComic comic) async {
  var history = History(HistoryType.nhentai, DateTime.now(), comic.title, "",
      comic.cover, 0, 0, comic.id);
  await appdata.history.addHistory(history);
}

void readPicacgComic(ComicItem comic, List<String> epsStr,
    [bool? continueRead]) async {
  await addPicacgHistory(comic);
  var history = await appdata.history.find(comic.id);
  var id = comic.id;
  var name = comic.title;

  void readFromBeginning() {
    App.globalTo(() => ComicReadingPage.picacg(id, 1, epsStr, name),
        preventDuplicates: false);
  }

  void readFromHistory() {
    App.globalTo(
        () => ComicReadingPage.picacg(
              id,
              history!.ep,
              epsStr,
              name,
              initialPage: history.page,
            ),
        preventDuplicates: false);
  }

  if (continueRead == true) {
    readFromHistory();
  } else if (continueRead == false) {
    readFromBeginning();
  } else {
    if (history == null || history.ep == 0) {
      readFromBeginning();
    } else {
      showDialog(
          context: App.globalContext!,
          builder: (dialogContext) => AlertDialog(
                title: Text("继续阅读".tl),
                content: Text("上次阅读到第 @ep 章第 @page 页, 是否继续阅读?".tlParams({
                  "ep": history.ep.toString(),
                  "page": history.page.toString()
                })),
                actions: [
                  TextButton(
                      onPressed: () {
                        App.globalBack();
                        readFromBeginning();
                      },
                      child: Text("从头开始".tl)),
                  TextButton(
                      onPressed: () {
                        App.globalBack();
                        readFromHistory();
                      },
                      child: Text("继续阅读".tl)),
                ],
              ));
    }
  }
}

void readPicacgComic2(ComicItemBrief comic, List<String> epsStr,
    [bool? continueRead]) async {
  History? history = History(HistoryType.picacg, DateTime.now(), comic.title,
      comic.author, comic.path, 0, 0, comic.id);
  await appdata.history.addHistory(history);
  history = await appdata.history.find(comic.id);
  var id = comic.id;
  var name = comic.title;

  void readFromBeginning() {
    App.globalTo(() => ComicReadingPage.picacg(id, 1, epsStr, name),
        preventDuplicates: false);
  }

  void readFromHistory() {
    App.globalTo(
        () => ComicReadingPage.picacg(
              id,
              history!.ep,
              epsStr,
              name,
              initialPage: history.page,
            ),
        preventDuplicates: false);
  }

  if (continueRead == true && history != null && history.ep != 0) {
    readFromHistory();
  } else if (continueRead == false || history == null || history.ep == 0) {
    readFromBeginning();
  } else {
    showDialog(
        context: App.globalContext!,
        builder: (dialogContext) => AlertDialog(
              title: Text("继续阅读".tl),
              content: Text("上次阅读到第 @ep 章第 @page 页, 是否继续阅读?".tlParams({
                "ep": history!.ep.toString(),
                "page": history.page.toString()
              })),
              actions: [
                TextButton(
                    onPressed: () {
                      App.globalBack();
                      readFromBeginning();
                    },
                    child: Text("从头开始".tl)),
                TextButton(
                    onPressed: () {
                      App.globalBack();
                      readFromHistory();
                    },
                    child: Text("继续阅读".tl)),
              ],
            ));
  }
}

void readEhGallery(Gallery gallery, [int? page]) async {
  addEhHistory(gallery);
  var target = gallery.link;
  var history = await appdata.history.find(target);
  if (page != null) {
    App.globalTo(
        () => ComicReadingPage.ehentai(
              target,
              gallery,
              initialPage: page,
            ),
        preventDuplicates: false);
    return;
  }
  if (history != null && history.ep != 0) {
    App.globalTo(
        () => ComicReadingPage.ehentai(target, gallery,
            initialPage: history.page),
        preventDuplicates: false);
  } else {
    App.globalTo(() => ComicReadingPage.ehentai(target, gallery),
        preventDuplicates: false);
  }
}

void readJmComic(JmComicInfo comic, List<String> eps,
    [bool? continueRead]) async {
  await addJmHistory(comic);
  var id = comic.id;
  var name = comic.name;
  var history = await appdata.history.find(id);

  void readFromBeginning() {
    App.globalTo(
        () => ComicReadingPage.jmComic(id, name, eps, 1, comic.epNames),
        preventDuplicates: false);
  }

  void readFromHistory() {
    App.globalTo(
        () => ComicReadingPage.jmComic(
              id,
              name,
              eps,
              history!.ep,
              comic.epNames,
              initialPage: history.page,
            ),
        preventDuplicates: false);
  }

  if (continueRead == true) {
    readFromHistory();
  } else if (continueRead == false) {
    readFromBeginning();
  } else {
    if (history == null || history.ep == 0) {
      readFromBeginning();
    } else {
      readFromHistory();
    }
  }
}

void readHitomiComic(HitomiComic comic, String cover, [int? page]) async {
  await addHitomiHistory(comic, cover);
  var history = await appdata.history.find(comic.id);
  if (page != null) {
    App.globalTo(
        () => ComicReadingPage.hitomi(
              comic.id,
              comic.name,
              comic.files,
              initialPage: page,
            ),
        preventDuplicates: false);
    return;
  }
  if (history != null && history.ep != 0) {
    App.globalTo(
        () => ComicReadingPage.hitomi(
              comic.id,
              comic.name,
              comic.files,
              initialPage: history.page,
            ),
        preventDuplicates: false);
  } else {
    App.globalTo(
        () => ComicReadingPage.hitomi(
              comic.id,
              comic.name,
              comic.files,
            ),
        preventDuplicates: false);
  }
}

void readHtmangaComic(HtComicInfo comic, [int? page]) async {
  await addHtmangaHistory(comic);
  var history = await appdata.history.find(comic.id);
  if (page != null) {
    App.globalTo(
        () => ComicReadingPage.htmanga(
              comic.id,
              comic.name,
              initialPage: page,
            ),
        preventDuplicates: false);
    return;
  }
  if (history != null && history.ep != 0) {
    App.globalTo(
        () => ComicReadingPage.htmanga(comic.id, comic.name,
            initialPage: history.page),
        preventDuplicates: false);
  } else {
    App.globalTo(() => ComicReadingPage.htmanga(comic.id, comic.name),
        preventDuplicates: false);
  }
}

void readNhentai(NhentaiComic comic, [int? page]) async {
  await addNhentaiHistory(comic);
  var history = await appdata.history.find(comic.id);
  if (page != null) {
    App.globalTo(
        () => ComicReadingPage.nhentai(
              comic.id,
              comic.title,
              initialPage: page,
            ),
        preventDuplicates: false);
    return;
  }
  if (history != null && history.ep != 0) {
    App.globalTo(
        () => ComicReadingPage.nhentai(comic.id, comic.title,
            initialPage: history.page),
        preventDuplicates: false);
  } else {
    App.globalTo(() => ComicReadingPage.nhentai(comic.id, comic.title),
        preventDuplicates: false);
  }
}

void readWithKey(String key, String target, int ep, int page, String title,
    Map<String, dynamic> otherInfo) async {
  switch (key) {
    case "picacg":
      App.globalTo(() => ComicReadingPage.picacg(
          target, ep, List.from(otherInfo["eps"]), title,
          initialPage: page));
    case "ehentai":
      App.globalTo(() => ComicReadingPage.ehentai(
          target, Gallery.fromJson(otherInfo["gallery"]),
          initialPage: page));
    case "jm":
      App.globalTo(() => ComicReadingPage.jmComic(
          target, title, List.from(otherInfo["eps"]), ep, List.from(otherInfo["jmEpNames"]),
          initialPage: page));
    case "hitomi":
      App.globalTo(() => ComicReadingPage.hitomi(
          target,
          title,
          (otherInfo["hitomi"] as List)
              .map((e) => HitomiFile.fromMap(e))
              .toList(),
          initialPage: page));
    case "htManga":
      App.globalTo(() => ComicReadingPage.htmanga(target, title,
          initialPage: page));
    case "nhentai":
      App.globalTo(() => ComicReadingPage.nhentai(target, title,
          initialPage: page));
    default:
      throw UnimplementedError();
  }
}
