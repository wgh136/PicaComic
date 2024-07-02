import 'dart:io' as io;

import 'package:app_links/app_links.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/js_engine.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/network/cookie_jar.dart';
import 'package:pica_comic/network/http_proxy.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/background_service.dart';
import 'package:pica_comic/tools/cache_auto_clear.dart';
import 'package:pica_comic/tools/io_extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:workmanager/workmanager.dart';
import 'base.dart';
import 'foundation/app.dart';
import 'network/nhentai_network/nhentai_main_network.dart';

Future<void> init() async{
  try {
    LogManager.addLog(LogLevel.info, "App Status", "Start initialization.");
    await App.init();
    await appdata.readData();
    SingleInstanceCookieJar("${App.dataPath}/cookies.db");
    HttpProxyServer.createConfigFile();
    if(appdata.settings[58] == "1"){
      HttpProxyServer.startServer();
    }
    startClearCache();
    if (App.isAndroid) {
      final appLinks = AppLinks();
      appLinks.allUriLinkStream.listen((uri) {
        handleAppLinks(uri);
      });
    }
    if (App.isMobile) {
      Workmanager().initialize(
        onStart,
      );
    }
    await checkDownloadPath();
    await _checkOldData();

    await JsEngine().init();

    await ComicSource.init();

    await Future.wait([
      downloadManager.init(),
      NhentaiNetwork().init(),
      JmNetwork().init(),
      LocalFavoritesManager().init(),
      HistoryManager().init(),
      AppTranslation.init(),
    ]);
  }
  catch(e, s){
    LogManager.addLog(LogLevel.error, "Init", "App initialization failed!\n$e$s");
  }
}

Future<void> _checkOldData() async{
  try {
    // settings
    appdata.settings[77] = appdata.settings[77].replaceFirst(',1,', ',');
    if (int.parse(appdata.settings[17]) >= 4) {
      appdata.settings[17] = '0';
    }
    if(int.parse(appdata.settings[40]) > 40) {
      appdata.settings[40] = '40';
    }
    appdata.blockingKeyword.removeWhere((value) => value.isEmpty);

    if (io.Directory("${App.dataPath}/comic_source/cookies/").existsSync() ||
        io.Directory("${App.dataPath}/eh_cookies").existsSync() ||
        io.Directory("${App.dataPath}/comic_source/cookies").existsSync()) {
      // cookies, old version use package cookie_jar
      final cookieJars = [
        PersistCookieJar(storage: FileStorage("${App.dataPath}/cookies")),
        PersistCookieJar(storage: FileStorage("${App.dataPath}/eh_cookies")),
        PersistCookieJar(
            storage: FileStorage("${App.dataPath}/comic_source/cookies/"))
      ];
      var cookies = <io.Cookie>[];
      for (var cookie in (await cookieJars[0].loadForRequest(
          Uri.parse("https://nhentai.net")))) {
        cookie.domain ??= ".nhentai.net";
        cookies.add(cookie);
      }
      for (var cookie in (await cookieJars[1].loadForRequest(
          Uri.parse("https://e-hentai.org")))) {
        cookie.domain ??= ".e-hentai.org";
        cookies.add(cookie);
      }
      for (var cookie in (await cookieJars[1].loadForRequest(
          Uri.parse("https://exhentai.org")))) {
        cookie.domain ??= ".exhentai.org";
        cookies.add(cookie);
      }
      try {
        for (var file in io.Directory("${App.dataPath}/comic_source/cookies/")
            .listSync()) {
          var domain = file.path
              .split("/")
              .last;
          if (domain == '.domains' || domain == '.index') {
            continue;
          }
          if (domain.startsWith('.')) {
            domain = domain.substring(1);
          }
          for (var cookie in (await cookieJars[2].loadForRequest(
              Uri.parse("https://$domain")))) {
            cookie.domain ??= ".$domain";
            cookies.add(cookie);
          }
        }
      }
      catch(e){
        // ignore
      }
      if(io.Directory("${App.dataPath}/cookies").existsSync()) {
        io.Directory("${App.dataPath}/cookies").deleteSync(recursive: true);
      }
      if(io.Directory("${App.dataPath}/eh_cookies").existsSync()) {
        io.Directory("${App.dataPath}/eh_cookies").deleteSync(recursive: true);
      }
      if(io.Directory("${App.dataPath}/comic_source/cookies").existsSync()) {
        io.Directory("${App.dataPath}/comic_source/cookies").deleteSync(
            recursive: true);
      }
    }

    if(io.File("${App.dataPath}/cache.json").existsSync()){
      io.File("${App.dataPath}/cache.json").deleteIgnoreError();
    }
    if(io.Directory("${App.cachePath}/imageCache").existsSync()){
      io.Directory("${App.cachePath}/imageCache").deleteIgnoreError(recursive: true);
    }
    if(io.Directory("${App.cachePath}/cachedNetwork").existsSync()){
      io.Directory("${App.cachePath}/cachedNetwork").deleteIgnoreError(recursive: true);
    }
  }
  catch(e, s){
    LogManager.addLog(LogLevel.error, "Init", "Check old data failed!\n$e$s");
  }
}