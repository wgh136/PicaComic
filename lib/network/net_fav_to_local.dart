import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/favorites.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/favorites/network_to_local.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

typedef GetFavoriteFunc<T extends Object> = Future<Res<List<T>>> Function(
    int page);

typedef ComicToLocalFavoriteFunc<T extends Object> = FavoriteItem Function(T);

Future<List<T>> getFavorites<T extends Object>(BuildContext context,
    GetFavoriteFunc<T> getFavoriteFunc, Duration? interval, int? total) async {
  var comics = <T>[];

  Stream<(int, int?)> load() async* {
    yield (0, null);
    int current = 0;
    int? temTotal = total;
    while (temTotal == null || current < temTotal) {
      var res = await getFavoriteFunc(current + 1);
      if (res.error) {
        throw res.errorMessageWithoutNull;
      }
      if (res.data.isEmpty) {
        yield (current, current);
        return;
      }
      comics.addAll(res.data);
      temTotal ??= res.subData;
      if (interval != null) {
        await Future.delayed(interval);
      }
      current++;
      yield (current, temTotal);
      if (current > 5) {
        var random = Random().nextInt(500) + 500;
        await Future.delayed(Duration(milliseconds: random));
      }
    }
  }

  await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => SimpleDialog(
            title: const Text("Loading..."),
            children: [
              const SizedBox(
                width: 400,
              ),
              const Center(
                child: CircularProgressIndicator(),
              ),
              StreamBuilder<(int, int?)>(
                  stream: load(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      Future.microtask(() {
                        App.back(context);
                        if (kDebugMode) {
                          print(snapshot.error);
                          print(snapshot.stackTrace);
                        }
                        showMessage(
                            App.globalContext!, snapshot.error.toString());
                      });
                    }
                    if (snapshot.hasData &&
                        snapshot.data?.$1 == snapshot.data?.$2) {
                      Future.delayed(const Duration(milliseconds: 200),
                          () => App.back(context));
                    }
                    return Center(
                      child: Text(
                          "${snapshot.data?.$1}/${snapshot.data?.$2 ?? "?"}"),
                    );
                  }),
              Center(
                child: TextButton(
                  child: Text("取消".tl),
                  onPressed: () {
                    App.back(context);
                  },
                ),
              )
            ],
          ));
  return comics;
}

void startConvert<T extends Object>(
    GetFavoriteFunc<T> getFavoriteFunc,
    Duration? interval,
    BuildContext context,
    String folderName,
    ComicToLocalFavoriteFunc<T> toLocalFavoriteFunc,
    String key,
    bool agreeSync,
    Object syncData) async {
  List<T> comics = await getFavorites(context, getFavoriteFunc, interval, null);
  var name = folderName;
  int i = 0;
  while (LocalFavoritesManager().folderNames.contains(name)) {
    name = folderName + i.toString();
    i++;
  }

  LocalFavoritesManager().createFolder(name);
  // 是否同步网络收藏
  if(agreeSync){
    LocalFavoritesManager()
      .insertFolderSync(FolderSync(name, key, jsonEncode(syncData)));
  }
  for (var comic in comics) {
    LocalFavoritesManager().addComic(name, toLocalFavoriteFunc(comic));
  }
}

void startFolderSync<T extends Object>(BuildContext context,
    FolderSync folderSync) async {
  final key = folderSync.key;
  final folderName = folderSync.folderName;
  final syncDataObj = folderSync.syncDataObj;

  final curAllComics = LocalFavoritesManager().getAllComics(folderName);
  final minValue = LocalFavoritesManager().minValue(folderName);
  final maxValue = LocalFavoritesManager().maxValue(folderName);
  int addValue = 0;
  final loadComicObj = LoadComicClass();
  final fData = getFavoriteData(key);
  final total = int.parse(appdata.settings[71]);
  List<BaseComic> comics = await getFavorites(
      context,
      (page) => loadComicObj.loadComic(fData, page, syncDataObj["folderId"]),
      null,
      total);
  final range = comics.length;
  String direction = '1'; // 顺序是放到最前还是最后, 为了保证顺序和网络收藏一致, 默认最前从新到旧, 不过有些网络收藏(绅士漫画)是从旧到新
  final comicsWithRange = comics.getRange(0, range).toList().reversed.toList(); // 翻转一下, 保证插入顺序最终和网络收藏一致
  for (var comic in comicsWithRange) {
    final temComic = FavoriteItem.fromBaseComic(comic);
    final index =
        curAllComics.indexWhere((element) => element.target == temComic.target);
    if (index == -1) {
      if (direction == "0") {
        addValue += 1;
      } else {
        addValue -= 1;
      }
      LocalFavoritesManager().addComic(folderName, temComic,
          direction == "0" ? maxValue + addValue : minValue + addValue);
    }
  }
  showMessage(
      App.globalContext,
      "本次更新数: ".tl +
          addValue.abs().toString() +
          ", 上次更新时间: ".tl +
          folderSync.time, time: 3);
  folderSync.time = getCurTime();
  LocalFavoritesManager().updateFolderSyncTime(folderSync);
}
