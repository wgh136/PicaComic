import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../foundation/def.dart';

typedef GetFavoriteFunc<T extends Object> = Future<Res<List<T>>> Function(
    int page);

typedef ComicToLocalFavoriteFunc<T extends Object> = FavoriteItem Function(T);

Set getFavorites<T extends Object>(
    GetFavoriteFunc<T> getFavoriteFunc, int? total) {
  var comics = <T>[];

  Stream<(int, int)> load() async* {
    yield (0, total ?? 1);
    int current = 0;
    while (current < (total ?? 1)) {
      var res = await getFavoriteFunc(current + 1);
      if (res.error) {
        throw res.errorMessageWithoutNull;
      }
      comics.addAll(res.data);
      if(res.subData != null){
        total = res.subData;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      current++;
      yield (current, total ?? 1);
      if (current > 5) {
        var random = Random().nextInt(500) + 500;
        await Future.delayed(Duration(milliseconds: random));
      }
    }
  }

  return {load, comics};
}

void startConvert<T extends Object>(
    ComicType type, String folderName, Object syncData) async {
  var name = folderName;
  int i = 0;
  while (LocalFavoritesManager().folderNames.contains(name)) {
    name = folderName + i.toString();
    i++;
  }

  LocalFavoritesManager().createFolder(name);
  LocalFavoritesManager()
      .insertFolderSync(FolderSync(folderName, type, jsonEncode(syncData)));
  showMessage(App.globalContext, "同步网络收藏到本地成功".tl);
}

class FolderSyncParam {
  int from;
  int to;
  // 顺序是放到最前还是最后
  String direction;
  FolderSyncParam(this.from, this.to, this.direction);
}

void startFolderSync<T extends Object>(BuildContext context,
    FolderSync folderSync, FolderSyncParam folderSyncParam) async {
  final type = folderSync.type;
  final folderName = folderSync.folderName;
  final syncDataObj = folderSync.syncDataObj;
  int from = folderSyncParam.from;
  int to = folderSyncParam.to;
  String direction = folderSyncParam.direction;
  Function? toLocalFavoriteFunc;
  dynamic getFavoriteFunc;
  int totalPage = 1;
  if (ComicType.ehentai == type) {
    totalPage = (to / 50).ceil();
    toLocalFavoriteFunc = (comic) => FavoriteItem.fromEhentai(comic);
    getFavoriteFunc = (page) => EhFavoritePageFolder(
            name: folderName, folderId: syncDataObj["folderId"])
        .getComics(page);
  }
  if (ComicType.nhentai == type) {
    totalPage = (to / 25).ceil();
    toLocalFavoriteFunc = (comic) => FavoriteItem.fromNhentai(comic);
    getFavoriteFunc = (page) => NhentaiNetwork().getFavorites(page);
  }
  final temFavorite = getFavorites(getFavoriteFunc, totalPage);
  Stream<(int, int)> Function() load = temFavorite.first;
  List<dynamic> comics = temFavorite.last;
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
              StreamBuilder<(int, int)>(
                  stream: load(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      Future.microtask(() {
                        App.back(context);
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
  final curAllComics = LocalFavoritesManager().getAllComics(folderName);
  final minValue = LocalFavoritesManager().minValue(folderName);
  final maxValue = LocalFavoritesManager().maxValue(folderName);
  int addValue = 0;
  final comicsWithRange = comics.getRange(0, from - to);
  for (var comic in comicsWithRange) {
    final temComic = toLocalFavoriteFunc!(comic);
    final index =
        curAllComics.indexWhere((element) => element.target == temComic.target);
    if (index == -1) {
      if (direction == "0") {
        addValue += 1;
      } else {
        addValue -= 1;
      }
      LocalFavoritesManager().addComic(
          folderName,
          temComic,
          direction == "0"
              ? maxValue + addValue
              : minValue + addValue);
    }
  }
  showMessage(
      App.globalContext,
      "本次共拉取到的漫画数为".tl +
          addValue.abs().toString() +
          ", 上次更新时间为".tl +
          folderSync.time);
  folderSync.time = getCurTime();
  LocalFavoritesManager().insertFolderSync(folderSync);
}
