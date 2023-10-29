import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/nhentai_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'dart:io';
import '../network/webdav.dart';

class FavoriteItem {
  String name;
  String author;
  ComicType type;
  List<String> tags;
  String target;
  String coverPath;
  String time =
      DateTime.now().toIso8601String().replaceFirst("T", " ").substring(0, 19);

  FavoriteItem.fromPicacg(ComicItemBrief comic)
      : name = comic.title,
        author = comic.author,
        type = ComicType.picacg,
        tags = comic.tags,
        target = comic.id,
        coverPath = comic.path;

  FavoriteItem.fromEhentai(EhGalleryBrief comic)
      : name = comic.title,
        author = comic.uploader,
        type = ComicType.ehentai,
        tags = comic.tags,
        target = comic.link,
        coverPath = comic.coverPath;

  FavoriteItem.fromJmComic(JmComicBrief comic)
      : name = comic.name,
        author = comic.author,
        type = ComicType.jm,
        tags = [],
        target = comic.id,
        coverPath = getJmCoverUrl(comic.id);

  FavoriteItem.fromHitomi(HitomiComicBrief comic)
      : name = comic.name,
        author = comic.artist,
        type = ComicType.hitomi,
        tags =
            List.generate(comic.tags.length, (index) => comic.tags[index].name),
        target = comic.link,
        coverPath = comic.cover;

  FavoriteItem.fromHtcomic(HtComicBrief comic)
      : name = comic.name,
        author = "${comic.pages}Pages",
        type = ComicType.htManga,
        tags = [],
        target = comic.id,
        coverPath = comic.image;

  FavoriteItem.fromNhentai(NhentaiComicBrief comic)
      : name = comic.title,
        author = "",
        type = ComicType.nhentai,
        tags = comic.tags,
        target = comic.id,
        coverPath = comic.cover;

  Map<String, dynamic> toJson() => {
        "name": name,
        "author": author,
        "type": type.index,
        "tags": tags,
        "target": target,
        "coverPath": coverPath,
        "time": time
      };

  FavoriteItem.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        author = json["author"],
        type = ComicType.values[json["type"]],
        tags = List<String>.from(json["tags"]),
        target = json["target"],
        coverPath = json["coverPath"],
        time = json["time"];
}

class FavoriteItemWithFolderInfo {
  FavoriteItem comic;
  String folder;

  FavoriteItemWithFolderInfo(this.comic, this.folder);
}

class LocalFavoritesManager {
  factory LocalFavoritesManager() =>
      cache ?? (cache = LocalFavoritesManager._create());

  LocalFavoritesManager._create();

  static LocalFavoritesManager? cache;

  Map<String, List<FavoriteItem>>? _data;

  bool saving = false;

  Future<List<String>> find(String target) async {
    if (_data == null) {
      await readData();
    }
    var res = <String>[];
    for (var key in _data!.keys.toList()) {
      if (_data![key]!
              .firstWhereOrNull((element) => element.target == target) !=
          null) {
        res.add(key);
      }
    }
    return res;
  }

  Future<void> saveData() async {
    if (_data == null) return;
    while (saving) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    saving = true;
    try {
      var data = <String, List<Map<String, dynamic>>>{};
      for (var key in _data!.keys.toList()) {
        List<Map<String, dynamic>> comics = [];
        for (var comic in _data![key]!) {
          comics.add(comic.toJson());
        }
        data[key] = comics;
      }
      var path = (await getApplicationSupportDirectory()).path;
      path += "${pathSep}localFavorite";
      var file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      file.writeAsStringSync(const JsonEncoder().convert(data));
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    } finally {
      saving = false;
      Webdav.uploadData();
    }
  }

  void close() => _data = null;

  Future<void> readData() async {
    if (_data != null) return;
    _data = {};
    var path = (await getApplicationSupportDirectory()).path;
    path += "${pathSep}localFavorite";
    var file = File(path);
    if (!file.existsSync()) {
      return;
    }
    try {
      var data = (const JsonDecoder().convert(file.readAsStringSync()))
          as Map<String, dynamic>;

      for (var key in data.keys.toList()) {
        List<FavoriteItem> comics = [];
        for (var comic in data[key]!) {
          comics.add(FavoriteItem.fromJson(comic));
        }
        _data![key] = comics;
      }
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    }
  }

  List<String>? get folderNames => _data?.keys.toList();

  List<FavoriteItem>? getAllComics(String folder) => _data?[folder];

  List<FavoriteItemWithFolderInfo> allComics() {
    var res = <FavoriteItemWithFolderInfo>[];
    if (_data != null) {
      _data!.forEach((key, value) => value.forEach(
          (element) => res.add(FavoriteItemWithFolderInfo(element, key))));
    }
    return res;
  }

  /// create a folder
  void createFolder(String name) {
    if (_data![name] != null) {
      throw Exception("Folder is existing");
    }
    _data![name] = [];
    saveData();
  }

  /// add comic to a folder
  ///
  /// This method will download cover to local, to avoid problems like changing url
  void addComic(String folder, FavoriteItem comic) async {
    if (_data![folder] == null) {
      throw Exception("Folder does not exists");
    }
    for (var c in _data![folder]!) {
      if (c.target == comic.target) {
        return;
      }
    }
    _data![folder]!.add(comic);
    saveData();
    try {
      var file = await DefaultCacheManager().getSingleFile(comic.coverPath);
      var path =
          "${(await getApplicationSupportDirectory()).path}${pathSep}favoritesCover";
      var directory = Directory(path);
      if (!directory.existsSync()) {
        directory.createSync();
      }
      var hash =
          md5.convert(const Utf8Encoder().convert(comic.coverPath)).toString();
      file.copySync("$path$pathSep$hash.jpg");
    } catch (e) {
      //忽略
    }
  }

  /// get comic cover
  Future<File> getCover(FavoriteItem item) async {
    var path = "${appdataPath!}${pathSep}favoritesCover";
    var hash =
        md5.convert(const Utf8Encoder().convert(item.coverPath)).toString();
    var file = File("$path$pathSep$hash.jpg");
    if (file.existsSync()) {
      return file;
    } else {
      var dio = Dio(BaseOptions(headers: {
        if (item.type == ComicType.ehentai) "cookie": EhNetwork().cookiesStr,
        if (item.type == ComicType.ehentai || item.type == ComicType.hitomi)
          "User-Agent": webUA,
        if (item.type == ComicType.hitomi) "Referer": "https://hitomi.la/"
      }, responseType: ResponseType.bytes));
      var res = await dio.get<Uint8List>(item.coverPath);
      file.createSync();
      file.writeAsBytesSync(res.data!);
      return file;
    }
  }

  /// delete a folder
  void deleteFolder(String name) {
    _data!.remove(name);
    saveData();
  }

  void checkAndDeleteCover(FavoriteItem item) async {
    for (var key in _data!.keys.toList()) {
      var comics = _data![key]!;
      for (var comic in comics) {
        if (comic.coverPath == item.coverPath) {
          return;
        }
      }
    }
    (await getCover(item)).deleteSync();
  }

  void deleteComic(String folder, FavoriteItem comic) {
    _data![folder]!.removeWhere((element) => element.target == comic.target);
    checkAndDeleteCover(comic);
  }

  void deleteComicWithTarget(String folder, String target) {
    var comic =
        _data![folder]!.firstWhere((element) => element.target == target);
    deleteComic(folder, comic);
  }

  Future<void> clearAll() async {
    _data = {};
    await saveData();
  }

  void reorder(List<FavoriteItem> newFolder, String folder) async {
    if (_data == null) {
      await readData();
    }
    if (_data?[folder] == null) {
      throw Exception("Failed to reorder: folder not found");
    }
    _data![folder] = newFolder;
    await saveData();
  }

  void rename(String before, String after) {
    if (_data![after] != null) {
      throw "收藏夹名称被占用";
    }
    _data![after] = _data![before]!;
    _data!.remove(before);
    saveData();
  }
}
