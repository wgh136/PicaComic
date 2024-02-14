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

  Future<ComicSource> parse(String toml) async{
    var document = TomlDocument.parse(toml).toMap();
    final String name = document["name"] ?? (throw ComicSourceParseException("name is required"));
    final String key = document["key"] ?? (throw ComicSourceParseException("key is required"));
    _key = key;

    final account = _loadAccountConfig(document);
    final explorePageData = _loadExploreData(document["explore"] ?? const {});
    final categoryPageData = _loadCategoryData(document["category"] ?? const {});

    return ComicSource(name, key, account, categoryPageData, null, explorePageData, null, [], null, null, null);
  }

  AccountConfig? _loadAccountConfig(Map<String, dynamic> document){
    if(document["account"] == null){
      return null;
    }

    LoginFunction? login;

    if(document["account"]["login"]["js"] != null){
      login = (account, pwd) async{
        try{
          final loginJs = document["account"]["login"]["js"];
          var key = await JsEngine().runProtectedWithKey(
              "$loginJs\nlogin(${jsonEncode(account)}, ${jsonEncode(pwd)})", _key!);
          await JsEngine().wait(key);
          ComicSource.sources.firstWhere((element) => element.key == _key)
              .data["account"] = <String>[account, pwd];
          return const Res(true);
        }
        catch(e, s){
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

  List<ExplorePageData> _loadExploreData(Map<String, dynamic> doc){
    if(doc["pages"] == null || (doc["pages"] is! List) || (doc["pages"] as List).isEmpty){
      return const [];
    }
    var pages = <ExplorePageData>[];
    for(var element in doc["pages"]){
      if(element is! String || doc[element] is! Map){
        continue;
      }
      Map<String, dynamic> page = doc[element];
      final String title = page["title"];
      final String type = page["type"];
      final String? loadMultiPartJs = page["loadMultiPart"];
      final String? loadPageJs = page["loadPage"];
      Future<Res<List<ExplorePagePart>>> Function()? loadMultiPart;
      Future<Res<List<BaseComic>>> Function(int page)? loadPage;
      if(loadMultiPartJs != null){
        loadMultiPart = () async{
          try {
            var key = await JsEngine().runProtectedWithKey(
                "$loadMultiPartJs\nloadMultiPart();", _key!);
            var res = await JsEngine().wait(key);
            if(res is! Map<String, dynamic>){
              log("loadMultiPart return invalid type: ${res.runtimeType}\n $res", "Data Analysis", LogLevel.error);
              return Res.error("loadMultiPart return invalid type: ${res.runtimeType}");
            }
            return Res(res.keys.map((e) =>
                ExplorePagePart(e, (res[e] as List).map<CustomComic>((e) => CustomComic.fromJson(e)).toList(), null))
                .toList());
          }
          catch(e, s){
            log("$e\n$s", "Data Analysis", LogLevel.error);
            return Res.error(e.toString());
          }
        };
      } else if(loadPageJs != null){
        // TODO
      }
      pages.add(ExplorePageData(title, switch(type){
        "singlePageWithMultiPart" => ExplorePageType.singlePageWithMultiPart,
        "multiPageComicList" => ExplorePageType.multiPageComicList,
        _ => throw ComicSourceParseException("Unknown explore page type $type")
      }, loadPage, loadMultiPart));
    }
    return pages;
  }

  CategoryData? _loadCategoryData(Map<String, dynamic> doc){
    if(doc["title"] == null){
      return null;
    }

    final String title = doc["title"];
    final bool? enableRankingPage = doc["enableRankingPage"];
    final List<String> parts = List.from(doc["parts"]);

    var categoryParts = <BaseCategoryPart>[];

    for(var part in parts){
      var c = doc[part];
      final String name = c["name"];
      final String type = c["type"];
      final List<String> tags = List.from(c["categories"]);
      final String itemType = c["itemType"];
      final List<String>? categoryParams = c["categoryParams"] == null ? null : List.from(c["categoryParams"]);
      if(type == "fixed"){
        categoryParts.add(FixedCategoryPart(name, tags, itemType, categoryParams));
      } else if(type == "random"){
        categoryParts.add(RandomCategoryPart(name, tags, c["randomNumber"] ?? 1, itemType));
      }
    }

    return CategoryData(title: title, categories: categoryParts, enableRecommendationPage: false, enableRankingPage: enableRankingPage ?? false, enableRandomPage: false, key: title);
  }
}

