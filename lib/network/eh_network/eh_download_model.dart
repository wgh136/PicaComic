import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/tools/cache_manager.dart';
import 'dart:io';
import '../../tools/io_tools.dart';
import '../../tools/log.dart';
import '../new_download.dart';
import 'eh_main_network.dart';
import 'get_gallery_id.dart';

class DownloadedGallery extends DownloadedItem{
  Gallery gallery;
  double? size;
  DownloadedGallery(this.gallery,this.size);
  Map<String, dynamic> toJson()=>{
    "gallery": gallery.toJson(),
    "size": size
  };
  DownloadedGallery.fromJson(Map<String, dynamic> map):
        gallery = Gallery.fromJson(map["gallery"]),
        size = map["size"];

  @override
  DownloadType get type => DownloadType.ehentai;

  @override
  List<int> get downloadedEps => [0];

  @override
  List<String> get eps => ["第一章"];

  @override
  String get name => gallery.title;

  @override
  String get id => getGalleryId(gallery.link);

  @override
  String get subTitle => gallery.uploader;

  @override
  double? get comicSize => size;
}

///e-hentai的下载进程模型
class EhDownloadingItem extends DownloadingItem{
  EhDownloadingItem(
      this.gallery,
      this.path,
      super.whenFinish,
      super.whenError,
      super.updateInfo,
      super.id,
      {super.type = DownloadType.ehentai}
  );

  ///画廊模型
  final Gallery gallery;

  ///储存路径
  final String path;

  ///已下载的页数
  int _downloadedPages = 0;

  ///总共的页面数
  int _totalPages = 0;

  ///是否处于暂停状态
  bool _pauseFlag = false;

  ///图片链接
  List<String> _urls = [];

  ///是否已经获取了全部url
  bool _gotUrls = false;

  int _runtimeKey = 0;

  Future<void> _getUrls() async{
    try{
      if (_gotUrls) return;
      await for(var i in EhNetwork().loadGalleryPages(gallery)) {
        if(i == 0){
          throw StateError("加载漫画信息出错");
        }
      }
      _urls = gallery.urls;
      _totalPages = _urls.length;
      _gotUrls = true;
    }
    catch(e){
      rethrow;
    }
  }

  int _retryTimes = 0;

  void _retry() {
    //允许重试两次
    if(DownloadManager().downloading.elementAtOrNull(0) != this) return;
    if (_retryTimes > 2) {
      super.whenError?.call();
      _retryTimes = 0;
    } else {
      _retryTimes++;
      start();
    }
  }

  ///是否已经下载了封面
  bool _downloadedCover = false;

  Future<void> _downloadCover() async{
    try{
      if (_downloadedCover) return;
      var dio = Dio();
      var res =
          await dio.get(
            gallery.coverPath,
            options: Options(
              responseType: ResponseType.bytes,
              headers: {
                "cookie": await EhNetwork().getCookies()
              }
            ),
          );
      var file = File("$path$pathSep$id${pathSep}cover.jpg");
      if (!await file.exists()) await file.create();
      await file.writeAsBytes(Uint8List.fromList(res.data));
      _downloadedCover = true;
    }
    catch(e){
      rethrow;
    }
  }

  @override
  String get cover => gallery.coverPath;

  @override
  int get downloadedPages => _downloadedPages;

  @override
  void pause() {
    notifications.endProgress();
    _pauseFlag = true;
  }

  @override
  void start() async{
    _runtimeKey++;
    int currentKey = _runtimeKey;
    _pauseFlag = false;
    notifications.sendProgressNotification(
        _downloadedPages, totalPages, "下载中", "共${downloadManager.downloading.length}项任务");
    try{
      if (_pauseFlag) return;
      await _getUrls();
      await _downloadCover();
      while (_downloadedPages < _totalPages) {
        if(_runtimeKey != currentKey) return;
        if (_pauseFlag) return;
        for(int i=0;i<5&&_downloadedPages+i < _totalPages;i++){
          EhDownloads.addDownload(_urls[_downloadedPages+i]);
        }
        var bytes = (await EhDownloads.getFile(_urls[_downloadedPages])).readAsBytesSync();
        var file = File("$path$pathSep$id$pathSep$downloadedPages.jpg");
        if (!await file.exists()) await file.create();
        await file.writeAsBytes(Uint8List.fromList(bytes));
        _downloadedPages++;
        super.updateUi?.call();
        await super.updateInfo?.call();
        if (!_pauseFlag) {
          notifications.sendProgressNotification(_downloadedPages, totalPages, "下载中",
              "共${downloadManager.downloading.length}项任务");
        }else{
          notifications.endProgress();
        }
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
      _retry();
      return;
    }
    await MyCacheManager().saveData();
    if(DownloadManager().downloading.elementAtOrNull(0) != this) return;
    await _saveInfo();
    super.whenFinish?.call();
  }

  ///储存画廊信息
  Future<void> _saveInfo() async{
    var file = File("$path/$id/info.json");
    var item = DownloadedGallery(gallery, await getFolderSize(Directory("$path$pathSep$id")));
    var json = jsonEncode(item.toJson());
    await file.writeAsString(json);
  }

  @override
  void stop() {
    _pauseFlag = true;
    var file = Directory("$path$pathSep$id");
    if(file.existsSync()) {
      file.delete(recursive: true);
    }
  }

  @override
  String get title => gallery.title;

  @override
  Map<String, dynamic> toMap() =>{
    "type": type.index,
    "gallery": gallery.toJson(),
    "path": path,
    "_urls": _urls,
    "_downloadedPages": _downloadedPages,
    "id": id,
    "_totalPages": _totalPages,
    "_gotUrls": _gotUrls,
    "_downloadedCover": _downloadedCover
  };

  EhDownloadingItem.fromMap(
    Map<String,dynamic> map,
    super.whenFinish,
    super.whenError,
    super.updateInfo,
    super.id,
    {super.type = DownloadType.ehentai}):
    gallery = Gallery.fromJson(map["gallery"]),
    path = map["path"],
    _urls = List<String>.from(map["_urls"]),
    _downloadedPages = map["_downloadedPages"],
    _totalPages = map["_totalPages"],
    _gotUrls = map["_gotUrls"],
    _downloadedCover = map["_downloadedCover"];

  @override
  int get totalPages => _totalPages;

}

///用于实现同时下载多张Eh图片
class EhDownloads{
  static Map<String, DownloadingStatus> downloading = {};

  static Future<void> addDownload(String path) async{
    if(downloading[path] != null){
      if(downloading[path]!.message != null){
        downloading.remove(path);
      }else {
        return;
      }
    }
    downloading[path] = DownloadingStatus(null, null, false);
    try {
      await for (var progress in MyCacheManager().getEhImage(path)){
        if(progress.expectedBytes == progress.currentBytes) {
          var res = progress.getFile();
          downloading[path]!.file = res;
          downloading[path]!.finish = true;
        }
      }
      if(downloading[path]!.file == null){
        throw Error();
      }
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Download", "$e\n$s");
      downloading[path]!.message = e.toString();
    }
  }

  static Future<File> getFile(String path) async{
    if(downloading[path] == null){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    while(!downloading[path]!.finish){
      await Future.delayed(const Duration(milliseconds: 100));
      if(downloading[path]!.message != null){
        throw Exception(downloading[path]!.message);
      }
    }
    var res = downloading[path]!.file!;
    downloading.remove(path);
    return res;
  }
}

class DownloadingStatus{
  File? file;
  String? message;
  bool finish;

  DownloadingStatus(this.file, this.message, this.finish);
}