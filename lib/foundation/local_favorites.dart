import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/nhentai_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/pages/favorites/main_favorites_page.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import '../network/base_comic.dart';
import '../network/webdav.dart';

String getCurTime() {
  return DateTime.now()
      .toIso8601String()
      .replaceFirst("T", " ")
      .substring(0, 19);
}

final class FavoriteType {
  final int key;

  const FavoriteType(this.key);

  static FavoriteType get picacg => const FavoriteType(0);

  static FavoriteType get ehentai => const FavoriteType(1);

  static FavoriteType get jm => const FavoriteType(2);

  static FavoriteType get hitomi => const FavoriteType(3);

  static FavoriteType get htManga => const FavoriteType(4);

  static FavoriteType get nhentai => const FavoriteType(6);

  ComicType get comicType {
    if (key >= 0 && key <= 6) {
      return ComicType.values[key];
    }
    return ComicType.other;
  }

  ComicSource get comicSource {
    if (key <= 6) {
      var key = comicType.name.toLowerCase();
      return ComicSource.find(key)!;
    }
    return ComicSource.sources
            .firstWhereOrNull((element) => element.intKey == key) ??
        (throw "Comic Source Not Found");
  }

  String get name {
    if (comicType != ComicType.other) {
      return comicType.name;
    } else {
      try {
        return comicSource.name;
      } catch (e) {
        return "**Unknown**";
      }
    }
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteType && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
}

class FavoriteItem {
  String name;
  String author;
  FavoriteType type;
  List<String> tags;
  String target;
  String coverPath;
  String time = getCurTime();

  bool get available {
    if (type.key <= 6 && type.key >= 0) {
      return true;
    }
    return ComicSource.sources
            .firstWhereOrNull((element) => element.intKey == type.key) !=
        null;
  }

  String toDownloadId() {
    try {
      return switch (type.comicType) {
        ComicType.picacg => target,
        ComicType.ehentai => getGalleryId(target),
        ComicType.jm => "jm$target",
        ComicType.hitomi => RegExp(r"\d+(?=\.html)").hasMatch(target)
            ? "hitomi${RegExp(r"\d+(?=\.html)").firstMatch(target)?[0]}"
            : target,
        ComicType.htManga => "ht$target",
        ComicType.nhentai => "nhentai$target",
        _ => DownloadManager().generateId(type.comicSource.key, target)
      };
    } catch (e) {
      return "**Invalid ID**";
    }
  }

  FavoriteItem({
    required this.target,
    required this.name,
    required this.coverPath,
    required this.author,
    required this.type,
    required this.tags,
  });

  FavoriteItem.fromPicacg(ComicItemBrief comic)
      : name = comic.title,
        author = comic.author,
        type = FavoriteType.picacg,
        tags = comic.tags,
        target = comic.id,
        coverPath = comic.path;

  FavoriteItem.fromEhentai(EhGalleryBrief comic)
      : name = comic.title,
        author = comic.uploader,
        type = FavoriteType.ehentai,
        tags = comic.tags,
        target = comic.link,
        coverPath = comic.coverPath;

  FavoriteItem.fromJmComic(JmComicBrief comic)
      : name = comic.name,
        author = comic.author,
        type = FavoriteType.jm,
        tags = [],
        target = comic.id,
        coverPath = getJmCoverUrl(comic.id);

  FavoriteItem.fromHitomi(HitomiComicBrief comic)
      : name = comic.name,
        author = comic.artist,
        type = FavoriteType.hitomi,
        tags = List.generate(
            comic.tagList.length, (index) => comic.tagList[index].name),
        target = comic.link,
        coverPath = comic.cover;

  FavoriteItem.fromHtcomic(HtComicBrief comic)
      : name = comic.name,
        author = "${comic.pages}Pages",
        type = FavoriteType.htManga,
        tags = [],
        target = comic.id,
        coverPath = comic.image;

  FavoriteItem.fromNhentai(NhentaiComicBrief comic)
      : name = comic.title,
        author = "",
        type = FavoriteType.nhentai,
        tags = comic.tags,
        target = comic.id,
        coverPath = comic.cover;

  FavoriteItem.custom(CustomComic comic)
      : name = comic.title,
        author = comic.subTitle,
        type = FavoriteType(comic.sourceKey.hashCode),
        tags = comic.tags,
        target = comic.id,
        coverPath = comic.cover;

  Map<String, dynamic> toJson() => {
        "name": name,
        "author": author,
        "type": type.key,
        "tags": tags,
        "target": target,
        "coverPath": coverPath,
        "time": time
      };

  FavoriteItem.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        author = json["author"],
        type = FavoriteType(json["type"]),
        tags = List<String>.from(json["tags"]),
        target = json["target"],
        coverPath = json["coverPath"],
        time = json["time"];

  FavoriteItem.fromRow(Row row)
      : name = row["name"],
        author = row["author"],
        type = FavoriteType(row["type"]),
        tags = (row["tags"] as String).split(","),
        target = row["target"],
        coverPath = row["cover_path"],
        time = row["time"] {
    tags.remove("");
  }

  factory FavoriteItem.fromBaseComic(BaseComic comic) {
    if (comic is ComicItemBrief) {
      return FavoriteItem.fromPicacg(comic);
    } else if (comic is EhGalleryBrief) {
      return FavoriteItem.fromEhentai(comic);
    } else if (comic is JmComicBrief) {
      return FavoriteItem.fromJmComic(comic);
    } else if (comic is HtComicBrief) {
      return FavoriteItem.fromHtcomic(comic);
    } else if (comic is NhentaiComicBrief) {
      return FavoriteItem.fromNhentai(comic);
    } else if (comic is CustomComic) {
      return FavoriteItem.custom(comic);
    }
    throw UnimplementedError();
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteItem && other.target == target && other.type == type;
  }

  @override
  int get hashCode => target.hashCode ^ type.hashCode;

  @override
  String toString() {
    var s = "FavoriteItem: $name $author $coverPath $hashCode $tags";
    if(s.length > 100) {
      return s.substring(0, 100);
    }
    return s;
  }
}

class FavoriteItemWithFolderInfo {
  FavoriteItem comic;
  String folder;

  FavoriteItemWithFolderInfo(this.comic, this.folder);

  @override
  bool operator ==(Object other) {
    return other is FavoriteItemWithFolderInfo &&
        other.comic == comic &&
        other.folder == folder;
  }

  @override
  int get hashCode => comic.hashCode ^ folder.hashCode;
}

class FolderSync {
  String folderName;
  String time = getCurTime();
  String key;
  String syncData; // 内容是 json, 存一下选中的文件夹 folderId
  FolderSync(this.folderName, this.key, this.syncData);

  Map<String, dynamic> get syncDataObj => jsonDecode(syncData);
}

extension SQL on String {
  String get toParam => replaceAll('\'', "''").replaceAll('"', "\"\"");
}

class LocalFavoritesManager {
  factory LocalFavoritesManager() =>
      cache ?? (cache = LocalFavoritesManager._create());

  LocalFavoritesManager._create();

  static LocalFavoritesManager? cache;

  late Database _db;

  Future<void> init() async {
    _db = sqlite3.open("${App.dataPath}/local_favorite.db");
    _checkAndCreate();
    await readData();
  }

  void _checkAndCreate() async {
    final tables = _getTablesWithDB();
    if (!tables.contains('folder_sync')) {
      _db.execute("""
      create table folder_sync (
        folder_name text primary key,
        time TEXT,
        key TEXT,
        sync_data TEXT
      );
    """);
    }
    if (!tables.contains('folder_order')) {
      _db.execute("""
      create table folder_order (
        folder_name text primary key,
        order_value int
      );
    """);
    }
    tables.remove('folder_sync');
    tables.remove('folder_order');
    if(tables.isEmpty)  return;
    var testTable = tables.first;
    // 检查type是否是主键
    var res = _db.select("""
      PRAGMA table_info("$testTable");
    """);
    bool shouldUpdate = false;
    for (var row in res) {
      if (row["name"] == "type" && row["pk"] == 0) {
        shouldUpdate = true;
        break;
      }
    }
    if (shouldUpdate) {
      for (var table in tables) {
        var tempName = "${table}_dw5d8g2_temp";
        _db.execute("""
          CREATE TABLE "$tempName" AS SELECT * FROM "$table";
          DROP TABLE "$table";
          CREATE TABLE "$table" (
            target text,
            name TEXT,
            author TEXT,
            type int,
            tags TEXT,
            cover_path TEXT,
            time TEXT,
            display_order int,
            primary key (target, type)
          );
          INSERT INTO "$table" SELECT * FROM "$tempName";
          DROP TABLE "$tempName";
        """);
      }
    }
  }

  void updateUI() {
    Future.microtask(
        () => StateController.findOrNull(tag: "me page")?.update());
    Future.microtask(
        () => StateController.findOrNull<FavoritesPageController>()?.update());
  }

  Future<List<String>> find(String target, FavoriteType type) async {
    var res = <String>[];
    for (var folder in folderNames) {
      var rows = _db.select("""
        select * from "$folder"
        where target == ? and type == ?;
      """, [target, type.key]);
      if (rows.isNotEmpty) {
        res.add(folder);
      }
    }
    return res;
  }

  Future<List<String>> findWithModel(FavoriteItem item) async {
    var res = <String>[];
    for (var folder in folderNames) {
      var rows = _db.select("""
        select * from "$folder"
        where target == ? and type == ?;
      """, [item.target, item.type.key]);
      if (rows.isNotEmpty) {
        res.add(folder);
      }
    }
    return res;
  }

  Future<void> saveData() async {
    Webdav.uploadData();
  }

  /// read data from json file or temp db.
  ///
  /// This function will delete current database, then create a new one, finally
  /// import data.
  Future<void> readData() async {
    var file = File("${App.dataPath}/localFavorite");
    if (file.existsSync()) {
      Map<String, List<FavoriteItem>> allComics = {};
      try {
        var data = (const JsonDecoder().convert(file.readAsStringSync()))
            as Map<String, dynamic>;

        for (var key in data.keys.toList()) {
          Set<FavoriteItem> comics = {};
          for (var comic in data[key]!) {
            comics.add(FavoriteItem.fromJson(comic));
          }
          if (allComics.containsKey(key)) {
            comics.addAll(allComics[key]!);
          }
          allComics[key] = comics.toList();
        }

        await clearAll();

        for (var folder in allComics.keys) {
          createFolder(folder, true);
          var comics = allComics[folder]!;
          for (int i = 0; i < comics.length; i++) {
            addComic(folder, comics[i]);
          }
        }
      } catch (e, s) {
        LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
      } finally {
        file.deleteSync();
      }
    } else if ((file = File("${App.dataPath}/local_favorite_temp.db"))
        .existsSync()) {
      var tmp_db = sqlite3.open(file.path);

      final folders = tmp_db
          .select("SELECT name FROM sqlite_master WHERE type='table';")
          .map((element) => element["name"] as String)
          .toList();
      folders.remove('folder_sync');
      folders.remove('folder_order');
      LogManager.addLog(LogLevel.info, "LocalFavoritesManager.readData",
          "read folders from local database $folders");
      var folderToOrder = <String, int>{};
      for (var folder in folders) {
        var res = tmp_db.select("""
        select * from folder_order
        where folder_name == ?;
      """, [folder]);
        if (res.isNotEmpty) {
          folderToOrder[folder] = res.first["order_value"];
        } else {
          folderToOrder[folder] = 0;
        }
      }
      folders.sort((a, b) {
        return folderToOrder[a]! - folderToOrder[b]!;
      });
      var res = <FavoriteItemWithFolderInfo>[];
      for (final folder in folders) {
        var comics = tmp_db.select("""
        select * from "$folder";
      """);
        LogManager.addLog(LogLevel.info, "LocalFavoritesManager.readData",
            "read $folder gets ${comics.length} comics");
        res.addAll(comics.map((element) =>
            FavoriteItemWithFolderInfo(FavoriteItem.fromRow(element), folder)));
      }
      var skips = 0;
      for (var comic in res) {
        if (!folderNames.contains(comic.folder)) {
          createFolder(comic.folder);
        }
        if (!comicExists(comic.folder, comic.comic.target, comic.comic.type.key)) {
          addComic(comic.folder, comic.comic);
          LogManager.addLog(LogLevel.info, "LocalFavoritesManager",
              "add comic ${comic.comic.target} to ${comic.folder}");
        } else {
          skips++;
        }
      }
      LogManager.addLog(LogLevel.info, "LocalFavoritesManager",
          "skipped $skips comics, total ${res.length}");
      tmp_db.dispose();
      file.deleteSync();
    } else {
      LogManager.addLog(LogLevel.info, "LocalFavoritesManager",
          "no local favorites db file found");
    }
  }

  List<String> _getTablesWithDB() {
    final tables = _db
        .select("SELECT name FROM sqlite_master WHERE type='table';")
        .map((element) => element["name"] as String)
        .toList();
    return tables;
  }

  List<String> _getFolderNamesWithDB() {
    final folders = _getTablesWithDB();
    folders.remove('folder_sync');
    folders.remove('folder_order');
    var folderToOrder = <String, int>{};
    for (var folder in folders) {
      var res = _db.select("""
        select * from folder_order
        where folder_name == ?;
      """, [folder]);
      if (res.isNotEmpty) {
        folderToOrder[folder] = res.first["order_value"];
      } else {
        folderToOrder[folder] = 0;
      }
    }
    folders.sort((a, b) {
      return folderToOrder[a]! - folderToOrder[b]!;
    });
    return folders;
  }

  void updateOrder(Map<String, int> order) {
    for (var folder in order.keys) {
      _db.execute("""
        insert or replace into folder_order (folder_name, order_value)
        values (?, ?);
      """, [folder, order[folder]]);
    }
  }

  List<FolderSync> _getFolderSyncWithDB() {
    return _db
        .select("SELECT * FROM folder_sync")
        .map((element) => FolderSync(
            element['folder_name'], element['key'], element['sync_data']))
        .toList();
  }

  void updateFolderSyncTime(FolderSync folderSync) {
    _db.execute("""
      update folder_sync
      set time = ?
      where folder_name == ?
    """, [folderSync.time, folderSync.folderName]);
  }

  void insertFolderSync(FolderSync folderSync) {
    // 注意 syncData 不能用 toParam, 否则会没法 jsonDecode
    _db.execute("""
        insert into folder_sync (folder_name, time, key, sync_data)
        values ('${folderSync.folderName.toParam}', '${folderSync.time.toParam}', '${folderSync.key.toParam}', 
          '${folderSync.syncData}');
      """);
  }

  int count(String folderName) {
    return _db.select("""
      select count(*) as c
      from "$folderName"
    """).first["c"];
  }

  List<String> get folderNames => _getFolderNamesWithDB();

  List<FolderSync> get folderSync => _getFolderSyncWithDB();

  int maxValue(String folder) {
    return _db.select("""
        SELECT MAX(display_order) AS max_value
        FROM "$folder";
      """).firstOrNull?["max_value"] ?? 0;
  }

  int minValue(String folder) {
    return _db.select("""
        SELECT MIN(display_order) AS min_value
        FROM "$folder";
      """).firstOrNull?["min_value"] ?? 0;
  }

  List<FavoriteItem> getAllComics(String folder) {
    var rows = _db.select("""
        select * from "$folder"
        ORDER BY display_order;
      """);
    return rows.map((element) => FavoriteItem.fromRow(element)).toList();
  }

  void addTagTo(String folder, String target, String tag) {
    _db.execute("""
      update "$folder"
      set tags = '$tag,' || tags
      where target == '${target.toParam}'
    """);
    saveData();
  }

  List<FavoriteItemWithFolderInfo> allComics() {
    var res = <FavoriteItemWithFolderInfo>[];
    for (final folder in folderNames) {
      var comics = _db.select("""
        select * from "$folder";
      """);
      res.addAll(comics.map((element) =>
          FavoriteItemWithFolderInfo(FavoriteItem.fromRow(element), folder)));
    }
    return res;
  }

  /// create a folder
  String createFolder(String name, [bool renameWhenInvalidName = false]) {
    if (name.isEmpty) {
      if (renameWhenInvalidName) {
        int i = 0;
        while (folderNames.contains(i.toString())) {
          i++;
        }
        name = i.toString();
      } else {
        throw "name is empty!";
      }
    }
    if (folderNames.contains(name)) {
      if (renameWhenInvalidName) {
        var prevName = name;
        int i = 0;
        while (folderNames.contains(i.toString())) {
          i++;
        }
        name = prevName + i.toString();
      } else {
        throw Exception("Folder is existing");
      }
    }
    _db.execute("""
      create table "$name"(
        target text,
        name TEXT,
        author TEXT,
        type int,
        tags TEXT,
        cover_path TEXT,
        time TEXT,
        display_order int,
        primary key (target, type)
      );
    """);
    saveData();
    return name;
  }

  bool comicExists(String folder, String target, int type) {
    var res = _db.select("""
      select * from "$folder"
      where target == ? and type == ?;
    """, [target, type]);
    return res.isNotEmpty;
  }

  FavoriteItem getComic(String folder, String target, FavoriteType type) {
    var res = _db.select("""
      select * from "$folder"
      where target == ? and type == ?;
    """, [target, type.key]);
    if (res.isEmpty) {
      throw Exception("Comic not found");
    }
    return FavoriteItem.fromRow(res.first);
  }

  /// add comic to a folder
  ///
  /// This method will download cover to local, to avoid problems like changing url
  void addComic(String folder, FavoriteItem comic, [int? order]) async {
    _modifiedAfterLastCache = true;
    if (!folderNames.contains(folder)) {
      throw Exception("Folder does not exists");
    }
    var res = _db.select("""
      select * from "$folder"
      where target == '${comic.target}';
    """);
    if (res.isNotEmpty) {
      return;
    }
    if (order != null) {
      _db.execute("""
        insert into "$folder" (target, name, author, type, tags, cover_path, time, display_order)
        values ('${comic.target.toParam}', '${comic.name.toParam}', '${comic.author.toParam}', ${comic.type.key}, 
          '${comic.tags.join(',').toParam}', '${comic.coverPath.toParam}', '${comic.time.toParam}', $order);
      """);
    } else if (appdata.settings[53] == "0") {
      _db.execute("""
        insert into "$folder" (target, name, author, type, tags, cover_path, time, display_order)
        values ('${comic.target.toParam}', '${comic.name.toParam}', '${comic.author.toParam}', ${comic.type.key}, 
          '${comic.tags.join(',').toParam}', '${comic.coverPath.toParam}', '${comic.time.toParam}', ${maxValue(folder) + 1});
      """);
    } else {
      _db.execute("""
        insert into "$folder" (target, name, author, type, tags, cover_path, time, display_order)
        values ('${comic.target.toParam}', '${comic.name.toParam}', '${comic.author.toParam}', ${comic.type.key}, 
          '${comic.tags.join(',').toParam}', '${comic.coverPath.toParam}', '${comic.time.toParam}', ${minValue(folder) - 1});
      """);
    }
    updateUI();
    saveData();
    try {
      var file =
          (await (ImageManager().getImage(comic.coverPath)).last).getFile();
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
    var path = "${App.dataPath}/favoritesCover";
    var hash =
        md5.convert(const Utf8Encoder().convert(item.coverPath)).toString();
    var file = File("$path/$hash.jpg");
    if (file.existsSync()) {
      return file;
    }
    if (item.coverPath.startsWith("file://")) {
      var data = DownloadManager()
          .getCover(item.coverPath.replaceFirst("file://", ""));
      file.createSync(recursive: true);
      file.writeAsBytesSync(data.readAsBytesSync());
      return file;
    }
    try {
      if (EhNetwork().cookiesStr == "") {
        await EhNetwork().getCookies(false);
      }
      var res = await (ImageManager().getImage(item.coverPath, {
        if (item.type == FavoriteType.ehentai) "cookie": EhNetwork().cookiesStr,
        if (item.type == FavoriteType.hitomi) "Referer": "https://hitomi.la/"
      }).last);
      file.createSync(recursive: true);
      file.writeAsBytesSync(res.getFile().readAsBytesSync());
      return file;
    } catch (e) {
      await Future.delayed(const Duration(seconds: 5));
      rethrow;
    }
  }

  /// delete a folder
  void deleteFolder(String name) {
    _modifiedAfterLastCache = true;
    _db.execute("""
      delete from folder_sync where folder_name == ?;
    """, [name]);
    _db.execute("""
      drop table "$name";
    """);
  }

  void checkAndDeleteCover(FavoriteItem item) async {
    if ((await find(item.target, item.type)).isEmpty) {
      (await getCover(item)).deleteSync();
    }
  }

  void deleteComic(String folder, FavoriteItem comic) {
    _modifiedAfterLastCache = true;
    deleteComicWithTarget(folder, comic.target, comic.type);
    checkAndDeleteCover(comic);
  }

  void deleteComicWithTarget(String folder, String target, FavoriteType type) {
    _modifiedAfterLastCache = true;
    _db.execute("""
      delete from "$folder"
      where target == ? and type == ?;
    """, [target, type.key]);
    saveData();
  }

  Future<void> clearAll() async {
    _db.dispose();
    File("${App.dataPath}/local_favorite.db").deleteSync();
    await init();
    saveData();
  }

  void reorder(List<FavoriteItem> newFolder, String folder) async {
    if (!folderNames.contains(folder)) {
      throw Exception("Failed to reorder: folder not found");
    }
    deleteFolder(folder);
    createFolder(folder);
    for (int i = 0; i < newFolder.length; i++) {
      addComic(folder, newFolder[i], i);
    }
    updateUI();
  }

  void rename(String before, String after) {
    if (folderNames.contains(after)) {
      throw "Name already exists!";
    }
    if (after.contains('"')) {
      throw "Invalid name";
    }
    _db.execute("""
      ALTER TABLE "$before"
      RENAME TO "$after";
    """);
    if (folderSync.isNotEmpty) {
      _db.execute("""
      UPDATE folder_sync
      set folder_name = ?
      where folder_name == ?
    """, [after, before]);
    }
    saveData();
  }

  void onReadEnd(String target, FavoriteType type) async {
    _modifiedAfterLastCache = true;
    bool isModified = false;
    for (final folder in folderNames) {
      var rows = _db.select("""
        select * from "$folder"
        where target == ? and type == ?;
      """, [target, type.key]);
      if (rows.isNotEmpty) {
        isModified = true;
        var newTime = DateTime.now()
            .toIso8601String()
            .replaceFirst("T", " ")
            .substring(0, 19);
        String updateLocationSql = "";
        if (appdata.settings[54] == "1") {
          int maxValue = _db.select("""
            SELECT MAX(display_order) AS max_value
            FROM "$folder";
          """).firstOrNull?["max_value"] ?? 0;
          updateLocationSql = "display_order = ${maxValue + 1},";
        } else if (appdata.settings[54] == "2") {
          int minValue = _db.select("""
            SELECT MIN(display_order) AS min_value
            FROM "$folder";
          """).firstOrNull?["min_value"] ?? 0;
          updateLocationSql = "display_order = ${minValue - 1},";
        }
        _db.execute("""
            UPDATE "$folder"
            SET 
              $updateLocationSql
              time = '$newTime'
            WHERE target == '${target.toParam}';
          """);
      }
    }
    if (isModified) {
      updateUI();
    }
    saveData();
  }

  String folderToJsonString(String folderName) {
    var data = <String, dynamic>{};
    data["info"] = "Generated by PicaComic.";
    data["website"] = "https://github.com/wgh136/PicaComic";
    data["name"] = folderName;
    var comics = _db
        .select("select * from \"$folderName\";")
        .map((element) => FavoriteItem.fromRow(element).toJson())
        .toList();
    data["comics"] = comics;
    return const JsonEncoder().convert(data);
  }

  (bool, String) loadFolderData(String dataString) {
    try {
      var data =
          const JsonDecoder().convert(dataString) as Map<String, dynamic>;
      final name_ = data["name"] as String;
      var name = name_;
      int i = 0;
      while (folderNames.contains(name)) {
        name = name_ + i.toString();
        i++;
      }
      createFolder(name);
      for (var json in data["comics"]) {
        addComic(name, FavoriteItem.fromJson(json));
      }
      return (false, "");
    } catch (e, s) {
      LogManager.addLog(LogLevel.error, "IO", "Failed to load data.\n$e\n$s");
      return (true, e.toString());
    }
  }

  List<FavoriteItemWithFolderInfo> search(String keyword) {
    var keywordList = keyword.split(" ");
    keyword = keywordList.first;
    var comics = <FavoriteItemWithFolderInfo>[];
    for (var table in folderNames) {
      keyword = "%$keyword%";
      var res = _db.select("""
        SELECT * FROM "$table" 
        WHERE name LIKE ? OR author LIKE ? OR tags LIKE ?;
      """, [keyword, keyword, keyword]);
      for (var comic in res) {
        comics.add(
            FavoriteItemWithFolderInfo(FavoriteItem.fromRow(comic), table));
      }
      if (comics.length > 200) {
        break;
      }
    }

    bool test(FavoriteItemWithFolderInfo comic, String keyword) {
      if (comic.comic.name.contains(keyword)) {
        return true;
      } else if (comic.comic.author.contains(keyword)) {
        return true;
      } else if (comic.comic.tags.any((element) => element.contains(keyword))) {
        return true;
      }
      return false;
    }

    for (var i = 1; i < keywordList.length; i++) {
      comics =
          comics.where((element) => test(element, keywordList[i])).toList();
    }

    return comics;
  }

  void editTags(String target, String folder, List<String> tags) {
    _db.execute("""
        update "$folder"
        set tags = '${tags.join(",")}'
        where target == '${target.toParam}';
      """);
  }

  final _cachedFavoritedTargets = <String, bool>{};

  bool isExist(String target) {
    if (_modifiedAfterLastCache) {
      _cacheFavoritedTargets();
    }
    return _cachedFavoritedTargets.containsKey(target);
  }

  bool _modifiedAfterLastCache = true;

  void _cacheFavoritedTargets() {
    _modifiedAfterLastCache = false;
    _cachedFavoritedTargets.clear();
    for (var folder in folderNames) {
      var res = _db.select("""
        select target from "$folder";
      """);
      for (var row in res) {
        _cachedFavoritedTargets[row["target"]] = true;
      }
    }
  }

  void updateInfo(String folder, FavoriteItem comic) {
    _db.execute("""
      update "$folder"
      set name = ?, author = ?, cover_path = ?, tags = ?
      where target == ? and type == ?;
    """, [comic.name, comic.author, comic.coverPath, comic.tags.join(","), comic.target, comic.type.key]);
  }
}
