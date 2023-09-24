import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/network/nhentai_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'dart:io';
import 'def.dart';


class FavoriteItem{
  String name;
  String author;
  ComicType type;
  List<String> tags;
  String target;
  String coverPath;
  String time = DateTime.now().toIso8601String().replaceFirst("T", " ").substring(0, 19);

  FavoriteItem.fromPicacg(ComicItemBrief comic):
      name = comic.title,
      author = comic.author,
      type = ComicType.picacg,
      tags = comic.tags,
      target = comic.id,
      coverPath = comic.path;

  FavoriteItem.fromEhentai(EhGalleryBrief comic):
      name = comic.title,
      author = comic.uploader,
      type = ComicType.ehentai,
      tags = comic.tags,
      target = comic.link,
      coverPath = comic.coverPath;

  FavoriteItem.fromJmComic(JmComicBrief comic):
      name = comic.name,
      author = comic.author,
      type = ComicType.jm,
      tags = [],
      target = comic.id,
      coverPath = getJmCoverUrl(comic.id);

  FavoriteItem.fromHitomi(HitomiComicBrief comic):
      name = comic.name,
      author = comic.artist,
      type = ComicType.hitomi,
      tags = List.generate(comic.tags.length, (index) => comic.tags[index].name),
      target = comic.link,
      coverPath = comic.cover;

  FavoriteItem.fromHtcomic(HtComicBrief comic):
      name = comic.name,
      author = "${comic.pages}Pages",
      type = ComicType.htManga,
      tags = [],
      target = comic.id,
      coverPath = comic.image;

  FavoriteItem.fromNhentai(NhentaiComicBrief comic):
      name = comic.title,
      author = "",
      type = ComicType.nhentai,
      tags = [],
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

  FavoriteItem.fromJson(Map<String, dynamic> json):
      name = json["name"],
      author = json["author"],
      type = ComicType.values[json["type"]],
      tags = List<String>.from(json["tags"]),
      target = json["target"],
      coverPath = json["coverPath"],
      time = json["time"];
}

class LocalFavoritesManager{
  factory LocalFavoritesManager() => cache??(cache = LocalFavoritesManager._create());

  LocalFavoritesManager._create();

  static LocalFavoritesManager? cache;

  Map<String, List<FavoriteItem>>? _data;

  bool saving = false;

  Future<List<String>> find(String target) async{
    if(_data == null){
      await readData();
    }
    var res = <String>[];
    for(var key in _data!.keys.toList()){
      if(_data![key]!.firstWhereOrNull((element) => element.target == target) != null){
        res.add(key);
      }
    }
    return res;
  }

  Future<void> saveData() async{
    if(_data == null) return;
    while(saving){
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
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    }
    finally{
      saving = false;
    }
  }

  void close() => _data = null;

  Future<void> readData() async{
    if(_data != null) return;
    _data = {};
    var path = (await getApplicationSupportDirectory()).path;
    path += "${pathSep}localFavorite";
    var file = File(path);
    if(!file.existsSync()){
      return;
    }
    try {
      var data = (const JsonDecoder().convert(file.readAsStringSync())) as Map<
          String,
          dynamic>;

      for (var key in data.keys.toList()) {
        List<FavoriteItem> comics = [];
        for (var comic in data[key]!) {
          comics.add(FavoriteItem.fromJson(comic));
        }
        _data![key] = comics;
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
    }
  }

  List<String>? get folderNames => _data?.keys.toList();

  List<FavoriteItem>? getAllComics(String folder) => _data?[folder];

  /// create a folder
  void createFolder(String name){
    if(_data![name] != null){
      throw Exception("Folder is existing");
    }
    _data![name] = [];
    saveData();
  }

  /// add comic to a folder
  ///
  /// This method will download cover to local, to avoid problems like changing url
  void addComic(String folder, FavoriteItem comic) async{
    if(_data![folder] == null){
      throw Exception("Folder does not exists");
    }
    for(var c in _data![folder]!){
      if(c.target == comic.target){
        return;
      }
    }
    _data![folder]!.add(comic);
    saveData();
    try{
      var file = await DefaultCacheManager().getSingleFile(comic.coverPath);
      var path = "${(await getApplicationSupportDirectory()).path}${pathSep}favoritesCover";
      var directory = Directory(path);
      if(!directory.existsSync()){
        directory.createSync();
      }
      var hash = md5.convert(const Utf8Encoder().convert(comic.coverPath)).toString();
      file.copySync("$path$pathSep$hash.jpg");
    }
    catch(e){
      //忽略
    }
  }

  /// get comic cover
  Future<File> getCover(String coverPath) async{
    var path = "${appdataPath!}${pathSep}favoritesCover";
    var hash = md5.convert(const Utf8Encoder().convert(coverPath)).toString();
    var file = File("$path$pathSep$hash.jpg");
    if(file.existsSync()) {
      return file;
    } else {
      return DefaultCacheManager().getSingleFile(coverPath);
    }
  }

  /// delete a folder
  void deleteFolder(String name){
    _data!.remove(name);
    saveData();
  }

  void checkAndDeleteCover(String coverPath) async{
    for(var key in _data!.keys.toList()){
      var comics = _data![key]!;
      for(var comic in comics){
        if(comic.coverPath == coverPath){
          return;
        }
      }
    }
    (await getCover(coverPath)).deleteSync();
  }

  void deleteComic(String folder, FavoriteItem comic){
    _data![folder]!.removeWhere((element) => element.target==comic.target);
    checkAndDeleteCover(comic.coverPath);
  }

  void deleteComicWithTarget(String folder, String target){
    var comic = _data![folder]!.firstWhere((element) => element.target==target);
    deleteComic(folder, comic);
  }

  Future<void> clearAll() async{
    _data = {};
    await saveData();
  }

  void reorder(List<FavoriteItem> newFolder, String folder) async{
    if(_data == null){
      await readData();
    }
    if(_data?[folder] == null){
      throw Exception("Failed to reorder: folder not found");
    }
    _data![folder] = newFolder;
    await saveData();
  }
}