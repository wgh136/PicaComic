import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_extensions.dart';
import 'package:pica_comic/foundation/image_loader/image_recombine.dart';
import '../base.dart';
import '../network/eh_network/eh_main_network.dart';
import '../network/hitomi_network/image.dart';
import '../network/res.dart';

class ImageManager {
  static ImageManager? cache;

  ///用于标记正在加载的项目, 避免出现多个异步函数加载同一张图片
  static Map<String, DownloadProgress> loadingItems = {};

  /// Image cache manager for reader and download manager
  factory ImageManager() {
    createFolder();
    return cache ?? (cache = ImageManager._create());
  }

  static void createFolder() async {
    var folder = Directory(
        "${(await getTemporaryDirectory()).path}${pathSep}imageCache");
    if (!folder.existsSync()) {
      folder.createSync(recursive: true);
    }
  }

  static bool get haveTask => loadingItems.isNotEmpty;

  static void clearTasks() {
    loadingItems.clear();
  }

  ImageManager._create();

  Map<String, String>? _paths;

  final dio = logDio(BaseOptions());

  Future<void> readData() async {
    if (_paths == null) {
      var appDataPath = (await getApplicationSupportDirectory()).path;
      var file = File("$appDataPath${pathSep}cache.json");
      if (file.existsSync()) {
        try {
          _paths = Map<String, String>.from(
              const JsonDecoder().convert(await file.readAsString()));
        } catch (e) {
          clear();
          _paths = {};
        }
      } else {
        _paths = {};
      }
    }
  }

  /// Clear image cache exceeding limit and save data into json file.
  Future<void> saveData() async {
    LogManager.addLog(
        LogLevel.info, "Cache Manager", "Performing clear cache and save Data");
    var clearNum = 0;
    final maxNumber = int.parse(appdata.settings[34]);
    final maxSize = int.parse(appdata.settings[35]);
    if (_paths != null) {
      // check the limitation of number
      if (_paths!.length > maxNumber) {
        var keys = _paths!.keys.toList();
        for (int i = 0; i < maxNumber - _paths!.length; i++) {
          var file = File(_paths![keys[i]]!);
          if (file.existsSync()) {
            clearNum++;
            file.deleteSync();
          }
          _paths!.remove(keys[i]);
        }
      }
      // check the information of size
      var cachePath =
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache";
      var size = Directory(cachePath).getMBSizeSync();
      LogManager.addLog(LogLevel.info, "Cache Manager",
          "Current cache number is ${_paths!.length}, size is ${size.toStringAsFixed(2)}MB");
      if (size > maxSize) {
        while (size > maxSize) {
          var first = _paths!.keys.first;
          var firstFile = File(_paths![first]!);
          if (firstFile.existsSync()) {
            clearNum++;
            size -= firstFile.getMBSizeSync();
            firstFile.deleteSync();
          } else {
            _paths!.remove(first);
          }
        }
      }
      // save info
      var appDataPath = (await getApplicationSupportDirectory()).path;
      var file = File("$appDataPath${pathSep}cache.json");
      if (!file.existsSync()) {
        await file.create();
      }
      if (_paths != null) {
        await file.writeAsString(const JsonEncoder().convert(_paths),
            mode: FileMode.writeOnly);
      }
      _paths = null;
    }
    LogManager.addLog(LogLevel.info, "Cache Manager",
        "Cleared $clearNum caches that exceeded the limit");
    loadingItems.clear();
  }

  int ehLoading = 0;

  /// 获取图片, 适用于没有任何限制的图片链接
  Stream<DownloadProgress> getImage(String url, [Map<String, String>? headers]) async* {
    while (loadingItems[url] != null) {
      var progress = loadingItems[url]!;
      yield progress;
      if (progress.finished) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[url] = DownloadProgress(0, 1, url, "");
    try {
      await readData();
      //检查缓存
      if (_paths![url] != null) {
        if (File(_paths![url]!).existsSync()) {
          yield DownloadProgress(1, 1, url, _paths![url]!);
          loadingItems.remove(url);
          return;
        } else {
          _paths!.remove(url);
        }
      }

      if(url.contains("s.exhentai.org") || url.contains("ehgt.org")) {
        await Future.delayed(Duration(seconds: 2 * ehLoading));
        ehLoading++;
      }

      //生成文件名
      var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
      if (fileName.length > 10) {
        fileName = fileName.substring(0, 10);
      }
      fileName = "$fileName.jpg";
      final savePath =
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache$pathSep$fileName";
      yield DownloadProgress(0, 100, url, savePath);
      headers = headers ?? {};
      headers["User-Agent"] ??= webUA;
      if (url.contains("nhentai")) {
        var cookies = await NhentaiNetwork().cookieJar!.loadForRequest(Uri.parse(url));
        var res = "";
        for (var cookie in cookies) {
          res += "${cookie.name}=${cookie.value}; ";
        }
        headers["Cookie"] = res;
      }
      headers["Connection"] = "keep-alive";
      var dioRes = await dio.get<ResponseBody>(url,
          options: Options(
              responseType: ResponseType.stream, headers: headers));
      if (dioRes.data == null) {
        throw Exception("Empty Data");
      }
      List<int> imageData = [];
      int? expectedBytes;
      try {
        expectedBytes =
            int.parse(dioRes.data!.headers["Content-Length"]![0]) + 1;
      } catch (e) {
        //忽略
      }
      var file = File(savePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      file.createSync();
      await for (var res in dioRes.data!.stream) {
        imageData.addAll(res);
        file.writeAsBytesSync(res, mode: FileMode.append);
        var progress = DownloadProgress(imageData.length,
            expectedBytes ?? (imageData.length + 1), url, savePath);
        yield progress;
        loadingItems[url] = progress;
      }
      await saveInfo(url, savePath);
      yield DownloadProgress(1, 1, url, savePath);
    } catch (e, s) {
      log("$e\n$s", "Network", LogLevel.error);
      rethrow;
    } finally {
      loadingItems.remove(url);
      if(url.contains("s.exhentai.org") || url.contains("ehgt.org")){
        ehLoading--;
      }
    }
  }

  Stream<DownloadProgress> getEhImageNew(
      final Gallery gallery, final int page) async* {
    final galleryLink = gallery.link;
    final cacheKey = "$galleryLink$page";
    final gid = getGalleryId(galleryLink);

    // check whether this image is loading
    while (loadingItems[cacheKey] != null) {
      var progress = loadingItems[cacheKey]!;
      yield progress;
      if (progress.finished) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[cacheKey] = DownloadProgress(0, 1, cacheKey, "");

    try {
      await readData();
      // find cache
      if (_paths![cacheKey] != null) {
        if (File(_paths![cacheKey]!).existsSync()) {
          yield DownloadProgress(1, 1, cacheKey, _paths![cacheKey]!);
          loadingItems.remove(cacheKey);
          return;
        } else {
          _paths!.remove(cacheKey);
        }
      }

      final options = BaseOptions(
          followRedirects: true,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 20),
          headers: {"user-agent": webUA, "cookie": EhNetwork().cookiesStr});

      var dio = logDio(options);

      // Get imgKey
      final readerLink =  (await EhNetwork().getReaderLink(galleryLink, page)).data;

      Future<void> getShowKey() async {
        while (gallery.auth!["showKey"] == "loading") {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        if (gallery.auth!["showKey"] != null || gallery.auth!["mpvKey"] != null) {
          return;
        }
        gallery.auth!["showKey"] = "loading";
        try {
          var res = await EhNetwork().request(readerLink);

          var html = parse(res.data);
          var script = html
              .querySelectorAll("script")
              .firstWhereOrNull((element) => element.text.contains("showkey"));
          if(script != null) {
            var match = RegExp(r'showkey="(.*?)"').firstMatch(script.text);
            final showKey = match!.group(1)!;
            gallery.auth!["showKey"] = showKey;
          } else {
            final script = html
                .querySelectorAll("script")
                .firstWhereOrNull((element) => element.text.contains("mpvkey"))?.text;
            if(script == null){
              throw Exception("Failed to get showKey or mpvkey");
            }
            var mpvKey= script.split(";").firstWhere((element) => element.contains("mpvkey"));
            gallery.auth!["mpvKey"] = mpvKey.removeAllBlank
                .replaceFirst("varmpvkey=", "").replaceAll('"', "");
            var imageListScript = script.split(";").firstWhere((element) => element.contains("imagelist"))
                .removeAllBlank.replaceFirst("varimagelist=", "");
            gallery.auth!["imgKey"] = jsonDecode(imageListScript).map((e) => e["k"]).join(",");
            gallery.auth!.remove("showKey");
          }
        }
        catch(e){
          gallery.auth!.remove("showKey");
          rethrow;
        }
      }
      await getShowKey();
      assert(gallery.auth?["showKey"] != null || gallery.auth?["mpvKey"] != null);

      // generate file name
      var fileName =
          md5.convert(const Utf8Encoder().convert(cacheKey)).toString();
      if (fileName.length > 10) {
        fileName = fileName.substring(0, 10);
      }
      fileName = "$fileName.jpg";
      final savePath =
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache$pathSep$fileName";
      yield DownloadProgress(0, 100, cacheKey, savePath);


      Response<ResponseBody>? res;

      var imgKey = readerLink.split('/')[4];

      if(gallery.auth?["mpvKey"] != null){
        Future<(String image, String nl)> getImageFromApi([String? nl]) async{
          Res<String>? apiRes = await EhNetwork().apiRequest({
            "gid": int.parse(gid),
            "imgkey": gallery.auth!["imgKey"]!.split(',')[page-1],
            "method": "imagedispatch",
            "page": page,
            "mpvkey": gallery.auth!["mpvKey"],
            if(nl != null)
              "nl": nl
          });
          var apiJson = const JsonDecoder().convert(apiRes.data);
          return (apiJson["i"].toString(), apiJson["s"].toString());
        }
        var (image, nl) = await getImageFromApi();
        int retryTimes = 0;
        while(res == null){
          try{
            if(image == ""){
              throw "empty url";
            }
            res = await dio.get<ResponseBody>(image,
                options: Options(responseType: ResponseType.stream));
            if (res.data!.headers["Content-Type"]?[0] == "text/html; charset=UTF-8" ||
                res.data!.headers["content-type"]?[0] == "text/html; charset=UTF-8") {
              throw ImageExceedError();
            }
          }
          catch(e){
            retryTimes++;
            if(retryTimes == 4){
              throw "Failed to load image.\nMaximum number of retries reached.";
            }
            (image, nl) = await getImageFromApi(nl);
          }
        }
      } else {
        Future<(String, String, String?)> getImageFromApi() async{
          // get image url through api
          Res<String>? apiRes = await EhNetwork().apiRequest({
            "gid": int.parse(gid),
            "imgkey": imgKey,
            "method": "showpage",
            "page": page,
            "showkey": gallery.auth!["showKey"]
          });

          if(apiRes.error && apiRes.errorMessage!.contains("handshake")){
            throw "Failed to make api request.\n"
                "This may be due to too frequent requests.\n"
                "Try to wait for some time and retry.";
          }

          var apiJson = const JsonDecoder().convert(apiRes.data);

          var i6 = apiJson["i6"] as String;

          RegExp regex = RegExp(r"nl\('(.+?)'\)");
          var nl = regex.firstMatch(i6)?.group(1);

          var originImage = i6.split("<a href=\"").last.split("\">").first;

          var image = apiJson["i3"] as String;

          image = image.substring(
              image.indexOf("src=\"") + 5, image.indexOf("\" style") - 1);

          return (image, originImage, nl);
        }

        Future<(String, String, String?)> getImageFromHtml() async{
          var res = await EhNetwork().request(readerLink);
          if(res.error){
            throw res.errorMessage ?? "error";
          }else{
            var document = parse(res.data);
            var image = document.querySelector("div#i3 > a > img")?.attributes["src"];
            var nl = document.querySelector("div#i6 > div > a#loadfail")?.attributes["onclick"]?.split('\'')
                .firstWhereOrNull((element) => element.contains('-'));
            var originImage = document.querySelectorAll("div#i6 > div > a")
                .firstWhereOrNull((element) => element.text.contains("original"))
                ?.attributes["href"] ?? "";
            return (image ?? "", originImage, nl);
          }
        }

        String image, originImage;
        String? nl;

        try{
          (image, originImage, nl) = await getImageFromApi();
        }
        catch(e){
          (image, originImage, nl) = await getImageFromHtml();
        }

        if (image.contains("/img/509.gi")) {
          throw ImageExceedError();
        }

        if(appdata.settings[29] == "1" && originImage.isURL){
          image = originImage;
        }

        int retryTimes = 0;

        while(res == null){
          try{
            if(image == ""){
              throw "empty url";
            }
            res = await dio.get<ResponseBody>(image,
                options: Options(responseType: ResponseType.stream));
            if (res.data!.headers["Content-Type"]?[0] == "text/html; charset=UTF-8" ||
                res.data!.headers["content-type"]?[0] == "text/html; charset=UTF-8") {
              throw ImageExceedError();
            }
          }
          catch(e){
            retryTimes++;
            if(retryTimes == 4){
              throw "Failed to load image.\nMaximum number of retries reached.";
            }
            if(nl == null){
              rethrow;
            }
            var (newImage, newNl) = await EhNetwork().getImageLinkWithNL(
                getGalleryId(galleryLink), imgKey, page, nl);
            image = newImage;
            if(kDebugMode){
              print("Get new image: $image, new nl $newNl");
            }
            if(newNl != null){
              nl = newNl;
            }
          }
        }
      }

      var stream = res.data!.stream;
      int? expectedBytes;
      try {
        expectedBytes = int.parse(res.data!.headers["Content-Length"]![0]);
      } catch (e) {
        try {
          expectedBytes = int.parse(res.data!.headers["content-length"]![0]);
        } catch (e) {
          // ignore
        }
      }
      var currentBytes = 0;
      var file = File(savePath);
      if (!file.existsSync()) {
        file.create();
      } else {
        file.deleteSync();
        file.createSync();
      }
      await for (var b in stream) {
        file.writeAsBytesSync(b, mode: FileMode.append);
        currentBytes += b.length;
        var progress = DownloadProgress(currentBytes,
            (expectedBytes ?? currentBytes) + 1, cacheKey, savePath);
        yield progress;
        loadingItems[cacheKey] = progress;
      }
      await saveInfo(cacheKey, savePath);
      yield DownloadProgress(1, 1, cacheKey, savePath);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
    }finally {
      loadingItems.remove(cacheKey);
    }
  }

  ///为Hitomi设计的图片加载函数
  ///
  /// 使用hash标识图片
  Stream<DownloadProgress> getHitomiImage(
      HitomiFile image, String galleryId) async* {
    while (loadingItems[image.hash] != null) {
      var progress = loadingItems[image.hash]!;
      yield progress;
      if (progress.finished) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[image.hash] = DownloadProgress(0, 1, image.hash, "");
    try {
      await readData();
      //检查缓存
      if (_paths![image.hash] != null) {
        if (File(_paths![image.hash]!).existsSync()) {
          yield DownloadProgress(1, 1, image.hash, _paths![image.hash]!);
          loadingItems.remove(image.hash);
          return;
        } else {
          _paths!.remove(image.hash);
        }
      }
      var directory = Directory(
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache");
      if (!directory.existsSync()) {
        directory.create();
      }
      final gg = GG();
      var url = await gg.urlFromUrlFromHash(galleryId, image, 'webp', null);
      int l;
      for (l = url.length - 1; l >= 0; l--) {
        if (url[l] == '.') {
          break;
        }
      }
      var fileName = image.hash + url.substring(l);
      final savePath =
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache$pathSep$fileName";
      var dio = logDio();
      dio.options.headers = {
        "User-Agent": webUA,
        "Referer": "https://hitomi.la/reader/$galleryId.html"
      };
      var file = File(savePath);
      try {
        var res = await dio.get<ResponseBody>(url,
            options: Options(responseType: ResponseType.stream));
        var stream = res.data!.stream;
        int? expectedBytes;
        try {
          expectedBytes = int.parse(res.data!.headers["Content-Length"]![0]);
        } catch (e) {
          try {
            expectedBytes = int.parse(res.data!.headers["content-length"]![0]);
          } catch (e) {
            //忽视
          }
        }
        if (!file.existsSync()) {
          file.create();
        }
        var currentBytes = 0;
        await for (var b in stream) {
          file.writeAsBytesSync(b.toList(), mode: FileMode.append);
          currentBytes += b.length;
          var progress = DownloadProgress(
              currentBytes, expectedBytes ?? (currentBytes + 1), url, savePath);
          yield progress;
          loadingItems[image.hash] = progress;
        }
        yield DownloadProgress(currentBytes, currentBytes, url, savePath);
      } catch (e) {
        if (file.existsSync()) {
          file.deleteSync();
        }
        rethrow;
      }
      await saveInfo(image.hash, savePath);
    } catch (e) {
      rethrow;
    } finally {
      loadingItems.remove(image.hash);
    }
  }

  ///获取禁漫图片, 如果缓存中没有, 则尝试下载
  Stream<DownloadProgress> getJmImage(String url, Map<String, String>? headers,
      {required String epsId,
      required String scrambleId,
      required String bookId}) async* {
    bookId = bookId.replaceAll(RegExp(r"\..+"), "");
    final urlWithoutParam = url.replaceAll(RegExp(r"\?.+"), "");
    while (loadingItems[urlWithoutParam] != null) {
      var progress = loadingItems[urlWithoutParam]!;
      yield progress;
      if (progress.finished) return;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    loadingItems[urlWithoutParam] = DownloadProgress(0, 1, url, "");
    try {
      await readData();
      var directory = Directory(
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache");
      if (!directory.existsSync()) {
        directory.create();
      }
      //检查缓存
      if (_paths![urlWithoutParam] != null) {
        if (File(_paths![urlWithoutParam]!).existsSync()) {
          yield DownloadProgress(1, 1, url, _paths![urlWithoutParam]!);
          return;
        } else {
          _paths!.remove(urlWithoutParam);
        }
      }
      //生成文件名
      var fileName = md5.convert(const Utf8Encoder().convert(url)).toString();
      if (fileName.length > 10) {
        fileName = fileName.substring(0, 10);
      }
      int l;
      int r = url.length;
      for (l = url.length - 1; l >= 0; l--) {
        if (url[l] == '.') {
          break;
        }
        if (url[l] == '?') {
          r = l;
        }
      }
      fileName += url.substring(l, r);
      fileName = fileName.replaceAll(RegExp(r"\?.+"), "");
      final savePath =
          "${(await getTemporaryDirectory()).path}${pathSep}imageCache$pathSep$fileName";

      var dio = logDio();
      yield DownloadProgress(0, 1, url, savePath);

      var bytes = <int>[];
      try {
        var res = await dio.get<ResponseBody>(url,
            options: Options(responseType: ResponseType.stream, headers: {
              "User-Agent":
                  "Mozilla/5.0 (Linux; Android 13; WD5DDE5 Build/TQ1A.230205.002; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/114.0.5735.196 Safari/537.36",
              "x-requested-with": "com.jiaohua_browser",
              "referer": "https://www.jmapibranch2.cc/"
            }));
        var stream = res.data!.stream;
        int i = 0;
        await for (var b in stream) {
          //不直接写入文件, 因为需要对图片进行重组, 处理完成后再写入
          bytes.addAll(b.toList());
          //构建虚假的进度条, 由于无法获取jm文件大小, 出此下策
          //每获取到一次数据, 进度条增加1%
          i += 5;
          if (i > 750) {
            i = 750;
          }
          var progress = DownloadProgress(i, 1000, url, savePath);
          yield progress;
          loadingItems[urlWithoutParam] = progress;
        }
      } catch (e) {
        rethrow;
      }
      var progress = DownloadProgress(750, 1000, url, savePath);
      yield progress;
      loadingItems[urlWithoutParam] = progress;
      var file = File(savePath);
      if (!file.existsSync()) {
        file.create();
      }
      if (url.substring(l, r) != ".gif") {
        await startRecombineAndWriteImage(
            Uint8List.fromList(bytes), epsId, scrambleId, bookId, savePath);
      } else {
        await startWriteFile(WriteInfo(savePath, bytes));
      }
      //告知完成
      await saveInfo(urlWithoutParam, savePath);
      progress = DownloadProgress(1, 1, url, savePath);
      yield progress;
      loadingItems[urlWithoutParam] = progress;
    } catch (e) {
      rethrow;
    } finally {
      await Future.delayed(const Duration(milliseconds: 50));
      loadingItems.remove(url);
    }
  }

  Future<void> saveInfo(String url, String savePath) async {
    if (_paths == null) {
      //此时为退出了阅读器, 数据已清除
      return;
    }
    _paths![url] = savePath;
    //await saveData();
  }

  Future<File?> getFile(String url) async {
    await readData();
    return _paths?[url] == null ? null : File(_paths![url]!);
  }

  Future<void> clear() async {
    var appDataPath = (await getApplicationSupportDirectory()).path;
    var file = File("$appDataPath${pathSep}cache.json");
    if (file.existsSync()) {
      file.delete();
    }
    if (_paths != null) {
      _paths!.clear();
    }
    final savePath = Directory(
        "${(await getTemporaryDirectory()).path}${pathSep}imageCache");
    if (savePath.existsSync()) {
      savePath.deleteSync(recursive: true);
    }
  }

  Future<bool> find(String key) async {
    await readData();
    return _paths![key] != null;
  }

  Future<void> delete(String key) async {
    await readData();
    try {
      var file = File(_paths![key]!);
      file.deleteSync();
      _paths!.remove(key);
    } catch (e) {
      //忽视
    }
  }
}

@immutable
class DownloadProgress {
  final int _currentBytes;
  final int _expectedBytes;
  final String url;
  final String savePath;

  int get currentBytes => _currentBytes;
  int get expectedBytes => _expectedBytes;
  bool get finished => _currentBytes == _expectedBytes;

  const DownloadProgress(
      this._currentBytes, this._expectedBytes, this.url, this.savePath);

  File getFile() => File(savePath);
}

class WriteInfo {
  String path;
  List<int> bytes;

  WriteInfo(this.path, this.bytes);
}

Future<void> writeData(WriteInfo info) async {
  var file = File(info.path);
  if (!file.existsSync()) {
    file.createSync();
  }
  file.writeAsBytesSync(info.bytes);
}

Future<void> startWriteFile(WriteInfo info) async {
  return compute(writeData, info);
}

class ImageExceedError extends Error {
  @override
  String toString() => "Maximum image loading limit reached.";
}
