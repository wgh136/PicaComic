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

  Future<ComicSource> createAndParse(String js, String fileName) async{
    if(!fileName.endsWith("js")){
      fileName = "$fileName.js";
    }
    var file = File("${App.dataPath}/comic_source/$fileName");
    if(file.existsSync()){
      int i = 0;
      while(file.existsSync()){
        file = File("${App.dataPath}/comic_source/$fileName($i).js");
        i++;
      }
    }
    await file.writeAsString(js);
    try{
      return await parse(js, file.path);
    } catch (e) {
      await file.delete();
      rethrow;
    }
  }

  Future<ComicSource> parse(String js, String filePath) async {
    js = js.replaceAll("\r\n", "\n");
    var line1 = js.split('\n')
        .firstWhereOrNull((element) => element.removeAllBlank.isNotEmpty);
    if(line1 == null || !line1.startsWith("class ") || !line1.contains("extends ComicSource")){
      throw ComicSourceParseException("Invalid Content");
    }
    var className = line1.split("class")[1].split("extends ComicSource").first;
    className = className.trim();
    JsEngine().runCode("""
      (() => {
        $js
        this['temp'] = new $className()
      }).call()
    """);
    _name = JsEngine().runCode("this['temp'].name")
        ?? (throw ComicSourceParseException('name is required'));
    var key = JsEngine().runCode("this['temp'].key")
        ?? (throw ComicSourceParseException('key is required'));
    var version = JsEngine().runCode("this['temp'].version")
        ?? (throw ComicSourceParseException('version is required'));
    var minAppVersion = JsEngine().runCode("this['temp'].minAppVersion");
    var url = JsEngine().runCode("this['temp'].url");
    var matchBriefIdRegex = JsEngine().runCode("this['temp'].comic.matchBriefIdRegex");
    if(minAppVersion != null){
      if(compareSemVer(minAppVersion, appVersion)){
        throw ComicSourceParseException("minAppVersion $minAppVersion is required");
      }
    }
    for(var source in ComicSource.sources){
      if(source.key == key){
        throw ComicSourceParseException("key($key) already exists");
      }
    }
    _key = key;
    _checkKeyValidation();

    JsEngine().runCode("""
      ComicSource.sources.$_key = this['temp'];
    """);

    final account = _loadAccountConfig();
    final explorePageData = _loadExploreData();
    final categoryPageData = _loadCategoryData();
    final categoryComicsData =
    _loadCategoryComicsData();
    final searchData = _loadSearchData();
    final loadComicFunc = _parseLoadComicFunc();
    final loadComicPagesFunc = _parseLoadComicPagesFunc();
    final favoriteData = _loadFavoriteData();
    final commentsLoader = _parseCommentsLoader();
    final sendCommentFunc = _parseSendCommentFunc();

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
        matchBriefIdRegex,
        filePath,
        url ?? "",
        version ?? "1.0.0",
        commentsLoader,
        sendCommentFunc);

    await source.loadData();

    Future.delayed(const Duration(milliseconds: 50), () {
      JsEngine().runCode("ComicSource.sources.$_key.init()");
    });

    return source;
  }

  _checkKeyValidation() {
    // 仅允许数字和字母以及下划线
    if (!_key!.contains(RegExp(r"^[a-zA-Z0-9_]+$"))) {
      throw ComicSourceParseException("key $_key is invalid");
    }
  }

  bool _checkExists(String index){
    return JsEngine().runCode("ComicSource.sources.$_key.$index !== null "
        "&& ComicSource.sources.$_key.$index !== undefined");
  }

  dynamic _getValue(String index) {
    return JsEngine().runCode("ComicSource.sources.$_key.$index");
  }

  AccountConfig? _loadAccountConfig() {
    if (!_checkExists("account")) {
      return null;
    }

    Future<Res<bool>> login(account, pwd) async {
      try {
        await JsEngine().runCode("""
          ComicSource.sources.$_key.account.login(${jsonEncode(account)}, 
          ${jsonEncode(pwd)})
        """);
        var source = ComicSource.sources
            .firstWhere((element) => element.key == _key);
        source.data["account"] = <String>[account, pwd];
        source.saveData();
        return const Res(true);
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    }

    void logout(){
      JsEngine().runCode("ComicSource.sources.$_key.account.logout()");
    }

    return AccountConfig(
      login,
      _getValue("account.login.website"),
      _getValue("account.registerWebsite"),
      logout
    );
  }

  List<ExplorePageData> _loadExploreData() {
    if (!_checkExists("explore")) {
      return const [];
    }
    var length = JsEngine().runCode("ComicSource.sources.$_key.explore.length");
    var pages = <ExplorePageData>[];
    for (int i=0; i<length; i++) {
      final String title = _getValue("explore[$i].title");
      final String type = _getValue("explore[$i].type");
      Future<Res<List<ExplorePagePart>>> Function()? loadMultiPart;
      Future<Res<List<BaseComic>>> Function(int page)? loadPage;
      if (type == "singlePageWithMultiPart") {
        loadMultiPart = () async {
          try {
            var res = await JsEngine()
                .runCode("ComicSource.sources.$_key.explore[$i].load()");
            return Res(List.from(res.keys.map((e) => ExplorePagePart(
                e,
                (res[e] as List)
                    .map<CustomComic>((e) => CustomComic.fromJson(e, _key!))
                    .toList(),
                null))
                .toList()));
          } catch (e, s) {
            log("$e\n$s", "Data Analysis", LogLevel.error);
            return Res.error(e.toString());
          }
        };
      } else if (type == "multiPageComicList") {
        loadPage = (int page) async {
          try {
            var res = await JsEngine()
                .runCode("ComicSource.sources.$_key.explore[$i].load()");
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

  CategoryData? _loadCategoryData() {
    var doc = _getValue("category");

    if (doc?["title"] == null) {
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

  CategoryComicsData? _loadCategoryComicsData() {
    if (!_checkExists("categoryComics")) return null;
    var options = <CategoryComicsOptions>[];
    for (var element in _getValue("categoryComics.optionList")) {
      LinkedHashMap<String, String> map = LinkedHashMap<String, String>();
      for (var option in element["options"]) {
        if (option.isEmpty || !option.contains("-")) {
          continue;
        }
        var split = option.split("-");
        var key = split.removeAt(0);
        var value = split.join("-");
        map[key] = value;
      }
      options.add(
          CategoryComicsOptions(
            map,
            List.from(element["notShowWhen"] ?? []),
            element["showWhen"] == null ? null : List.from(element["showWhen"])
          ));
    }
    return CategoryComicsData(options, (category, param, options, page) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.categoryComics.load(
            ${jsonEncode(category)}, 
            ${jsonEncode(param)}, 
            ${jsonEncode(options)}, 
            ${jsonEncode(page)}
          )
        """);
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

  SearchPageData? _loadSearchData() {
    if (!_checkExists("search")) return null;
    var options = <SearchOptions>[];
    for (var element in _getValue("search.optionList") ?? []) {
      LinkedHashMap<String, String> map = LinkedHashMap<String, String>();
      for (var option in element["options"]) {
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
    return SearchPageData(options, (keyword, page, searchOption) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.search.load(
            ${jsonEncode(keyword)}, ${jsonEncode(searchOption)}, ${jsonEncode(page)})
        """);
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

  LoadComicFunc? _parseLoadComicFunc() {
    return (id) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadInfo(${jsonEncode(id)})
        """);
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
            isFavorite: res["isFavorite"],
            subId: res["subId"],));
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    };
  }

  LoadComicPagesFunc? _parseLoadComicPagesFunc() {
    return (id, ep) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadEp(${jsonEncode(id)}, ${jsonEncode(ep)})
        """);
        return Res(List.from(res["images"]));
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    };
  }

  FavoriteData? _loadFavoriteData() {
    if (!_checkExists("favorites")) return null;

    final bool multiFolder = _getValue("favorites.multiFolder");

    Future<Res<bool>> addOrDelFavFunc(comicId, folderId, isAdding) async {
      func() async {
        try {
          await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.addOrDelFavorite(
              ${jsonEncode(comicId)}, ${jsonEncode(folderId)}, ${jsonEncode(isAdding)})
          """);
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
    }

    Future<Res<List<BaseComic>>> loadComic(int page, [String? folder]) async {
      Future<Res<List<BaseComic>>> func() async{
        try {
          var res = await JsEngine().runCode("""
            ComicSource.sources.$_key.favorites.loadComics(
              ${jsonEncode(page)}, ${jsonEncode(folder)})
          """);
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

  CommentsLoader? _parseCommentsLoader(){
    if(!_checkExists("comic.loadComments")) return null;
    return (id, subId, page, replyTo) async {
      try {
        var res = await JsEngine().runCode("""
          ComicSource.sources.$_key.comic.loadComments(
            ${jsonEncode(id)}, ${jsonEncode(subId)}, ${jsonEncode(page)}, ${jsonEncode(replyTo)})
        """);
        return Res(
            (res["comments"] as List).map((e) => Comment(
                e["userName"], e["avatar"], e["content"], e["time"], e["replyCount"], e["id"].toString()
            )).toList(),
            subData: res["maxPage"]);
      } catch (e, s) {
        log("$e\n$s", "Network", LogLevel.error);
        return Res.error(e.toString());
      }
    };
  }

  SendCommentFunc? _parseSendCommentFunc(){
    if(!_checkExists("comic.sendComment")) return null;
    return (id, subId, content, replyTo) async {
      Future<Res<bool>> func() async{
        try {
          await JsEngine().runCode("""
            ComicSource.sources.$_key.comic.sendComment(
              ${jsonEncode(id)}, ${jsonEncode(subId)}, ${jsonEncode(content)}, ${jsonEncode(replyTo)})
          """);
          return const Res(true);
        } catch (e, s) {
          log("$e\n$s", "Network", LogLevel.error);
          return Res.error(e.toString());
        }
      }
      var res = await func();
      if(res.error && res.errorMessage!.contains("Login expired")){
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
}
