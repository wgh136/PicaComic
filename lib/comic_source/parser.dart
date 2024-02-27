part of comic_source;

class ComicSourceParseException implements Exception {
  final String message;

  ComicSourceParseException(this.message);

  @override
  String toString() {
    return message;
  }
}

class ComicSourceParser {
  /// comic source key
  String? _key;

  String? _name;

  Future<ComicSource> createAndParse(String toml, String fileName) async{
    if(!fileName.endsWith("toml")){
      fileName = "$fileName.toml";
    }
    var file = File("${App.dataPath}/comic_source/$fileName");
    if(file.existsSync()){
      int i = 0;
      while(file.existsSync()){
        file = File("${App.dataPath}/comic_source/$fileName($i).toml");
        i++;
      }
    }
    await file.writeAsString(toml);
    try{
      return await parse(toml, fileName);
    } catch (e) {
      await file.delete();
      rethrow;
    }
  }

  Future<ComicSource> parse(String toml, String filePath) async {
    var document = TomlDocument.parse(toml).toMap();
    _name = document["name"] ??
        (throw ComicSourceParseException("name is required"));
    final String key =
        document["key"] ?? (throw ComicSourceParseException("key is required"));
    for(var source in ComicSource.sources){
      if(source.key == key){
        throw ComicSourceParseException("key($key) already exists");
      }
    }
    _key = key;
    _checkKeyValidation();

    final account = _loadAccountConfig(document);
    final explorePageData = _loadExploreData(document["explore"] ?? const {});
    final categoryPageData =
        _loadCategoryData(document["category"] ?? const {});
    final categoryComicsData =
        _loadCategoryComicsData(document["categoryComics"]);
    final searchData = _loadSearchData(document["search"]);
    final loadComicFunc = _parseLoadComicFunc(document["comic"]);
    final loadComicPagesFunc = _parseLoadComicPagesFunc(document["comic"]);
    final favoriteData = _loadFavoriteData(document["favorite"]);

    var source =  ComicSource(
        _name!,
        key,
        account,
        categoryPageData,
        categoryComicsData,
        favoriteData,
        explorePageData,
        searchData,
        [],
        loadComicFunc,
        loadComicPagesFunc,
        null,
        document["comic"]?["matchBriefIdRegex"],
        filePath,
        document["url"] ?? "");

    await source.loadData();

    final initJs = document["init"];
    if(initJs != null) {
      // delay 50ms to wait for data loading
      Future.delayed(const Duration(milliseconds: 50),
              () => JsEngine().runProtectedWithKey("$initJs\ninit()", key));
    }

    return source;
  }

  _checkKeyValidation() {
    // 仅允许数字和字母以及下划线
    if (!_key!.contains(RegExp(r"^[a-zA-Z0-9_]+$"))) {
      throw ComicSourceParseException("key $_key is invalid");
    }
  }

  AccountConfig? _loadAccountConfig(Map<String, dynamic> document) {
    if (document["account"] == null) {
      return null;
    }

    LoginFunction? login;

    if (document["account"]["login"]["js"] != null) {
      login = (account, pwd) async {
        try {
          final loginJs = document["account"]["login"]["js"];
          var key = await JsEngine().runProtectedWithKey(
              "$loginJs\nlogin(${jsonEncode(account)}, ${jsonEncode(pwd)})",
              _key!);
          await JsEngine().wait(key);
          var source = ComicSource.sources
              .firstWhere((element) => element.key == _key);
          source.data["account"] = <String>[account, pwd];
          source.saveData();
          return const Res(true);
        } catch (e, s) {
          log("$e\n$s", "Network", LogLevel.error);
          return Res.error(e.toString());
        }
      };
    }

    return AccountConfig(
      login,
      document["account"]["login"]["website"],
      document["account"]["register"]["website"],
      ListOrNull.from(document["account"]["logout"]["cookies"]) ?? const [],
      ListOrNull.from(document["account"]["logout"]["data"]) ?? const [],
    );
  }

  List<ExplorePageData> _loadExploreData(Map<String, dynamic> doc) {
    if (doc["pages"] == null ||
        (doc["pages"] is! List) ||
        (doc["pages"] as List).isEmpty) {
      return const [];
    }
    var pages = <ExplorePageData>[];
    for (var page in doc["pages"]) {
      final String title = page["title"];
      final String type = page["type"];
      final String? loadMultiPartJs = page["loadMultiPart"];
      final String? loadPageJs = page["loadPage"];
      Future<Res<List<ExplorePagePart>>> Function()? loadMultiPart;
      Future<Res<List<BaseComic>>> Function(int page)? loadPage;
      if (loadMultiPartJs != null) {
        loadMultiPart = () async {
          try {
            var key = await JsEngine().runProtectedWithKey(
                "$loadMultiPartJs\nloadMultiPart();", _key!);
            var res = await JsEngine().wait(key);
            if (res is! Map<String, dynamic>) {
              log("loadMultiPart return invalid type: ${res.runtimeType}\n $res",
                  "Data Analysis", LogLevel.error);
              return Res.error(
                  "loadMultiPart return invalid type: ${res.runtimeType}");
            }
            return Res(res.keys
                .map((e) => ExplorePagePart(
                    e,
                    (res[e] as List)
                        .map<CustomComic>((e) => CustomComic.fromJson(e, _key!))
                        .toList(),
                    null))
                .toList());
          } catch (e, s) {
            log("$e\n$s", "Data Analysis", LogLevel.error);
            return Res.error(e.toString());
          }
        };
      } else if (loadPageJs != null) {
        loadPage = (int page) async {
          try {
            var key = await JsEngine().runProtectedWithKey(
                "$loadPageJs\nloadPage($page);", _key!);
            var res = await JsEngine().wait(key);
            return Res(
                List.generate(res["comics"].length,
                        (index) => CustomComic.fromJson(res["comics"][index], _key!)),
                subData: res["maxPage"]);
          } catch (e, s) {
            log("$e\n$s", "Data Analysis", LogLevel.error);
            return Res.error(e.toString());
          }
        };
      }
      pages.add(ExplorePageData(
          title,
          switch (type) {
            "singlePageWithMultiPart" =>
              ExplorePageType.singlePageWithMultiPart,
            "multiPageComicList" => ExplorePageType.multiPageComicList,
            _ =>
              throw ComicSourceParseException("Unknown explore page type $type")
          },
          loadPage,
          loadMultiPart));
    }
    return pages;
  }

  CategoryData? _loadCategoryData(Map<String, dynamic> doc) {
    if (doc["title"] == null) {
      return null;
    }

    final String title = doc["title"];
    final bool? enableRankingPage = doc["enableRankingPage"];

    var categoryParts = <BaseCategoryPart>[];

    for (var c in doc["parts"]) {
      final String name = c["name"];
      final String type = c["type"];
      final List<String> tags = List.from(c["categories"]);
      final String itemType = c["itemType"];
      final List<String>? categoryParams =
          c["categoryParams"] == null ? null : List.from(c["categoryParams"]);
      if (type == "fixed") {
        categoryParts
            .add(FixedCategoryPart(name, tags, itemType, categoryParams));
      } else if (type == "random") {
        categoryParts.add(
            RandomCategoryPart(name, tags, c["randomNumber"] ?? 1, itemType));
      }
    }

    return CategoryData(
        title: title,
        categories: categoryParts,
        enableRecommendationPage: false,
        enableRankingPage: enableRankingPage ?? false,
        enableRandomPage: false,
        key: title);
  }

  CategoryComicsData? _loadCategoryComicsData(Map<String, dynamic>? doc) {
    if (doc == null) return null;
    var options = <CategoryComicsOptions>[];
    for (var element in doc["options"]) {
      LinkedHashMap<String, String> map = LinkedHashMap<String, String>();
      for (var option in (element["content"] as String)
          .replaceAll("\r\n", "\n")
          .split("\n")) {
        if (option.isEmpty || !option.contains("-")) {
          continue;
        }
        var split = option.split("-");
        var key = split.removeAt(0);
        var value = split.join("-");
        map[key] = value;
      }
      options.add(
          CategoryComicsOptions(map, List.from(element["notShowWhen"] ?? [])));
    }
    var loadJs = doc["load"];
    return CategoryComicsData(options, (category, param, options, page) async {
      try {
        final key = await JsEngine().runProtectedWithKey(
            "$loadJs\nload(${jsonEncode(category)}, ${jsonEncode(param)}, ${jsonEncode(options)}, $page)",
            _key!);
        var res = await JsEngine().wait(key);
        return Res(
            List.generate(res["comics"].length,
                (index) => CustomComic.fromJson(res["comics"][index], _key!)),
            subData: res["maxPage"]);
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    });
  }

  SearchPageData? _loadSearchData(Map<String, dynamic>? doc) {
    if (doc == null) return null;
    var options = <SearchOptions>[];
    for (var element in doc["options"] ?? []) {
      LinkedHashMap<String, String> map = LinkedHashMap<String, String>();
      for (var option in (element["content"] as String)
          .replaceAll("\r\n", "\n")
          .split("\n")) {
        if (option.isEmpty || !option.contains("-")) {
          continue;
        }
        var split = option.split("-");
        var key = split.removeAt(0);
        var value = split.join("-");
        map[key] = value;
      }
      options.add(SearchOptions(map, element["label"]));
    }
    var loadJs = doc["load"];
    return SearchPageData(options, (keyword, page, searchOption) async {
      try {
        final key = await JsEngine().runProtectedWithKey(
            "$loadJs\nload(${jsonEncode(keyword)}, ${jsonEncode(searchOption)}, $page)",
            _key!);
        var res = await JsEngine().wait(key);
        return Res(
            List.generate(res["comics"].length,
                (index) => CustomComic.fromJson(res["comics"][index], _key!)),
            subData: res["maxPage"]);
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    });
  }

  LoadComicFunc? _parseLoadComicFunc(Map<String, dynamic>? doc) {
    if (doc == null) return null;

    var loadJs = doc["loadInfo"];

    return (id) async {
      try {
        final key = await JsEngine()
            .runProtectedWithKey("$loadJs\nloadInfo(${jsonEncode(id)})", _key!);
        var res = await JsEngine().wait(key);
        var tags = <String, List<String>>{};
        (res["tags"] as Map<String, dynamic>?)
            ?.forEach((key, value) => tags[key] = List.from(value));
        return Res(ComicInfoData(
            res["title"],
            res["subTitle"],
            res["cover"],
            res["description"],
            tags,
            Map.from(res["chapters"]),
            ListOrNull.from(res["thumbnails"]),
            // TODO: implement thumbnailLoader
            null,
            res["thumbnailMaxPage"] ?? 1,
            (res["suggestions"] as List?)
                ?.map((e) => CustomComic.fromJson(e, _key!))
                .toList(),
            _key!,
            id,
            isFavorite: res["isFavorite"],));
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    };
  }

  LoadComicPagesFunc? _parseLoadComicPagesFunc(Map<String, dynamic>? doc) {
    if (doc == null) return null;

    var loadJs = doc["loadEp"];

    return (id, ep) async {
      try {
        final key = await JsEngine().runProtectedWithKey(
            "$loadJs\nloadEp(${jsonEncode(id)}, ${jsonEncode(ep)})", _key!);
        var res = await JsEngine().wait(key);
        return Res(List.from(res["images"]));
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    };
  }

  FavoriteData? _loadFavoriteData(Map<String, dynamic>? doc) {
    if (doc == null) return null;
    final bool multiFolder = doc["multiFolder"];
    final String? addOrDelFavJs = doc["addOrDelFavorite"];
    AddOrDelFavFunc? addOrDelFavFunc;
    if (addOrDelFavJs != null) {
      addOrDelFavFunc = (comicId, folderId, isAdding) async {
        func() async {
          try {
            final key = await JsEngine().runProtectedWithKey(
                "$addOrDelFavJs\naddOrDelFavorite(${jsonEncode(comicId)}, ${jsonEncode(folderId)}, $isAdding)",
                _key!);
            await JsEngine().wait(key);
            return const Res(true);
          } catch (e, s) {
            log("$e\n$s", "Network", LogLevel.error);
            return Res<bool>.error(e.toString());
          }
        }

        var res = await func();
        if (res.error && res.errorMessage!.contains("Login expired")) {
          var reLoginRes = await ComicSource.find(_key!)!.reLogin();
          if (!reLoginRes) {
            return const Res.error("Login expired and re-login failed");
          } else {
            return func();
          }
        }
        return res;
      };
    }
    final String loadComicJs = doc["loadComics"];
    Future<Res<List<BaseComic>>> loadComic(int page, [String? folder]) async {
      Future<Res<List<BaseComic>>> func() async{
        try {
          final key = await JsEngine().runProtectedWithKey(
              "$loadComicJs\nloadComics($page, ${jsonEncode(folder)})",
              _key!);
          var res = await JsEngine().wait(key);
          return Res(
              List.generate(res["comics"].length,
                      (index) => CustomComic.fromJson(res["comics"][index], _key!)),
              subData: res["maxPage"]);
        } catch (e, s) {
          log("$e\n$s", "Network", LogLevel.error);
          return Res.error(e.toString());
        }
      }
      var res = await func();
      if (res.error && res.errorMessage!.contains("Login expired")) {
        var reLoginRes = await ComicSource.find(_key!)!.reLogin();
        if (!reLoginRes) {
          return const Res.error("Login expired and re-login failed");
        } else {
          return func();
        }
      }
      return res;
    }

    return FavoriteData(
        key: _key!,
        title: _name!,
        multiFolder: multiFolder,
        loadComic: loadComic,
        addOrDelFavorite: addOrDelFavFunc);
  }
}
