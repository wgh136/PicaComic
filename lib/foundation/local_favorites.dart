import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
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

class FavoriteItem {
  String name;
  String author;
  ComicType type;
  List<String> tags;
  String target;
  String coverPath;
  String time = getCurTime();

  String toDownloadId() {
    return switch (type) {
      ComicType.picacg => target,
      ComicType.ehentai => getGalleryId(target),
      ComicType.jm => "jm$target",
      ComicType.hitomi => RegExp(r"\d+(?=\.html)").hasMatch(target)
          ? "hitomi${RegExp(r"\d+(?=\.html)").firstMatch(target)?[0]}"
          : target,
      ComicType.htManga => "ht$target",
      ComicType.nhentai => "nhentai$target",
      _ => throw UnimplementedError()
    };
  }

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

  FavoriteItem.fromRow(Row row)
      : name = row["name"],
        author = row["author"],
        type = ComicType.values[row["type"]],
        tags = (row["tags"] as String).split(","),
        target = row["target"],
        coverPath = row["cover_path"],
        time = row["time"] {
    tags.remove("");
  }

  factory FavoriteItem.fromBaseComic(BaseComic comic){
    if(comic is ComicItemBrief){
      return FavoriteItem.fromPicacg(comic);
    } else if(comic is EhGalleryBrief){
      return FavoriteItem.fromEhentai(comic);
    } else if(comic is JmComicBrief){
      return FavoriteItem.fromJmComic(comic);
    } else if(comic is HtComicBrief){
      return FavoriteItem.fromHtcomic(comic);
    } else if(comic is NhentaiComicBrief){
      return FavoriteItem.fromNhentai(comic);
    }
    // TODO: implement custom comic source
    throw UnimplementedError();
  }

  FavoriteItem(this.name, this.author, this.type, this.tags, this.target, this.coverPath);
}

class FavoriteItemWithFolderInfo {
  FavoriteItem comic;
  String folder;

  FavoriteItemWithFolderInfo(this.comic, this.folder);
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
  }

  void updateUI() {
    Future.microtask(
        () => StateController.findOrNull(tag: "me page")?.update());
  }

  Future<List<String>> find(String target) async {
    var res = <String>[];
    for (var folder in folderNames) {
      var rows = _db.select("""
        select * from "$folder"
        where target == '${target.toParam}';
      """);
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
          List<FavoriteItem> comics = [];
          for (var comic in data[key]!) {
            comics.add(FavoriteItem.fromJson(comic));
          }
          allComics[key] = comics;
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
      _db.dispose();
      await Future.delayed(const Duration(milliseconds: 100));
      var newPath = "${App.dataPath}/local_favorite.db";
      file = file.renameSync(newPath);
      init();
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
    return folders;
  }

  List<FolderSync> _getFolderSyncWithDB() {
    return _db
        .select("SELECT * FROM folder_sync")
        .map((element) => FolderSync(
            element['folder_name'], element['key'], element['sync_data']))
        .toList();
  }

  void updateFolderSyncTime(FolderSync folderSync){
    _db.execute("""
      update folder_sync
      set time = '${folderSync.time}'
      where folder_name == '${folderSync.folderName}'
    """);
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
  void createFolder(String name, [bool renameWhenInvalidName = false]) {
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
        int i = 0;
        while (folderNames.contains(i.toString())) {
          i++;
        }
        name = i.toString();
      } else {
        throw Exception("Folder is existing");
      }
    }
    _db.execute("""
      create table "$name"(
        target text primary key,
        name TEXT,
        author TEXT,
        type int,
        tags TEXT,
        cover_path TEXT,
        time TEXT,
        display_order int
      );
    """);
    saveData();
  }

  /// add comic to a folder
  ///
  /// This method will download cover to local, to avoid problems like changing url
  void addComic(String folder, FavoriteItem comic, [int? order]) async {
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
        values ('${comic.target.toParam}', '${comic.name.toParam}', '${comic.author.toParam}', ${comic.type.index}, 
          '${comic.tags.join(',').toParam}', '${comic.coverPath.toParam}', '${comic.time.toParam}', $order);
      """);
    } else if (appdata.settings[53] == "0") {
      _db.execute("""
        insert into "$folder" (target, name, author, type, tags, cover_path, time, display_order)
        values ('${comic.target.toParam}', '${comic.name.toParam}', '${comic.author.toParam}', ${comic.type.index}, 
          '${comic.tags.join(',').toParam}', '${comic.coverPath.toParam}', '${comic.time.toParam}', ${maxValue(folder) + 1});
      """);
    } else {
      _db.execute("""
        insert into "$folder" (target, name, author, type, tags, cover_path, time, display_order)
        values ('${comic.target.toParam}', '${comic.name.toParam}', '${comic.author.toParam}', ${comic.type.index}, 
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
        if (item.type == ComicType.ehentai) "cookie": EhNetwork().cookiesStr,
        if (item.type == ComicType.ehentai || item.type == ComicType.hitomi)
          "User-Agent": webUA,
        if (item.type == ComicType.hitomi) "Referer": "https://hitomi.la/"
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
    _db.execute("""
      delete from folder_sync where folder_name == '$name';
    """);
    _db.execute("""
      drop table "$name";
    """);    
  }

  void checkAndDeleteCover(FavoriteItem item) async {
    if ((await find(item.target)).isEmpty) {
      (await getCover(item)).deleteSync();
    }
  }

  void deleteComic(String folder, FavoriteItem comic) {
    deleteComicWithTarget(folder, comic.target);
    checkAndDeleteCover(comic);
  }

  void deleteComicWithTarget(String folder, String target) {
    _db.execute("""
      delete from "$folder"
      where target == '${target.toParam}';
    """);
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
    _db.execute("""
      ALTER TABLE "$before"
      RENAME TO "$after";
    """);
    if (folderSync.isNotEmpty) {
      _db.execute("""
      UPDATE folder_sync
      set folder_name = '$after'
      where folder_name == '$before'
    """);
    }
    saveData();
  }

  void onReadEnd(String target) async {
    bool isModified = false;
    for (final folder in folderNames) {
      var rows = _db.select("""
        select * from "$folder"
        where target == '${target.toParam}';
      """);
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
    var resComics = <FavoriteItemWithFolderInfo>[];
    for (var table in folderNames) {
      var res = _db.select("""
        SELECT * FROM "$table" 
        WHERE name LIKE '%$keyword%' OR author LIKE '%$keyword%' OR tags LIKE '%$keyword%';
      """);
      for (var comic in res) {
        resComics.add(
            FavoriteItemWithFolderInfo(FavoriteItem.fromRow(comic), table));
      }
      if (resComics.length > 200) {
        break;
      }
    }
    return resComics;
  }
}
