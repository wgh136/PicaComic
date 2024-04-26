part of pica_reader;

abstract class ReadingData {
  ReadingData();

  String get title;

  String get id;

  String get downloadId;

  ComicType get type;

  String get sourceKey;

  bool get hasEp;

  Map<String, String>? get eps;

  bool get downloaded => DownloadManager().downloaded.contains(downloadId);

  List<int> downloadedEps = [];

  String get favoriteId => id;

  bool checkEpDownloaded(int ep) {
    return !hasEp || downloadedEps.contains(ep-1);
  }

  Future<Res<List<String>>> loadEp(int ep) async {
    if(downloaded && downloadedEps.isEmpty){
      downloadedEps = (await DownloadManager().getComicOrNull(downloadId))!.downloadedEps;
    }
    if (downloaded && checkEpDownloaded(ep)){
      int length;
      if(hasEp) {
        length = await DownloadManager().getEpLength(downloadId, ep);
      } else {
        length = await DownloadManager().getComicLength(downloadId);
      }
      return Res(List.filled(length, ""));
    } else {
      return await loadEpNetwork(ep);
    }
  }

  /// Load image from local or network
  ///
  /// [page] starts from 0, [ep] starts from 1
  Stream<DownloadProgress> loadImage(int ep, int page, String url) async* {
    if (downloaded && checkEpDownloaded(ep)) {
      yield DownloadProgress(
          1, 1, "", DownloadManager().getImage(downloadId, hasEp ? ep : 0, page).path);
    } else {
      yield* loadImageNetwork(ep, page, url);
    }
  }

  ImageProvider createImageProvider(int ep, int page, String url){
    if (downloaded && checkEpDownloaded(ep)){
      return FileImageProvider(downloadId, hasEp ? ep : 0, page);
    } else {
      return StreamImageProvider(() => loadImage(ep, page, url), "$id$ep$page");
    }
  }

  Future<Res<List<String>>> loadEpNetwork(int ep);

  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url);
}

class PicacgReadingData extends ReadingData {
  @override
  final String title;

  @override
  final String id;

  PicacgReadingData(this.title, this.id, List<String> epsList)
      : eps = {for (var e in epsList) e: e};

  @override
  final Map<String, String> eps;

  @override
  bool get hasEp => true;

  @override
  String get sourceKey => "picacg";

  @override
  ComicType get type => ComicType.picacg;

  @override
  String get downloadId => id;

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) {
    return PicacgNetwork().getComicContent(id, ep);
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    return ImageManager().getImage(url);
  }
}

class EhReadingData extends ReadingData {
  final Gallery gallery;

  EhReadingData(this.gallery);

  @override
  bool get hasEp => eps != null;

  @override
  String get sourceKey => "ehentai";

  @override
  ComicType get type => ComicType.ehentai;

  @override
  String get downloadId => getGalleryId(id);

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) {
    return Future.value(Res(List.filled(int.parse(gallery.maxPage), "")));
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    return ImageManager().getEhImageNew(gallery, page+1);
  }

  @override
  Map<String, String>? get eps => null;

  @override
  String get id => gallery.link;

  @override
  String get title => gallery.title;
}

class JmReadingData extends ReadingData {
  @override
  final String title;

  @override
  final String id;

  int? commentsLength;
  
  static Map<String, String> generateMap(List<String> epIds, List<String> epNames){
    if(epIds.length == epNames.length){
      return Map.fromIterables(epIds, epNames);
    } else {
      return Map.fromIterables(epIds, List.generate(epIds.length, (index) => "第${index+1}章"));
    }
  }

  JmReadingData(this.title, this.id, List<String> epIds, List<String> epNames)
      : eps = generateMap(epIds, epNames);

  @override
  bool get hasEp => true;

  @override
  String get sourceKey => "jm";

  @override
  ComicType get type => ComicType.jm;

  @override
  String get downloadId => "jm$id";

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) async{
    var res = await JmNetwork().getChapter(eps.keys.elementAtOrNull(ep-1) ?? id);
    commentsLength = res.subData;
    return res;
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    var bookId = "";
    for (int i = url.length - 1; i >= 0; i--) {
      if (url[i] == '/') {
        bookId = url.substring(i + 1, url.length - 5);
        break;
      }
    }
    return ImageManager().getJmImage(url, null,
        epsId: eps.keys.elementAtOrNull(ep-1) ?? id,
        scrambleId: "220980",
        bookId: bookId);
  }

  @override
  final Map<String, String> eps;
}

class HitomiReadingData extends ReadingData {
  @override
  final String title;

  @override
  final String id;

  final List<HitomiFile> images;

  final String link;

  HitomiReadingData(this.title, this.id, this.images, this.link);

  @override
  Map<String, String>? get eps => null;

  @override
  bool get hasEp => false;

  @override
  String get sourceKey => "hitomi";

  @override
  ComicType get type => ComicType.hitomi;

  @override
  String get downloadId => "hitomi$id";

  @override
  String get favoriteId => link;

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) {
    return Future.value(Res(List.filled(images.length, "")));
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    return ImageManager().getHitomiImage(images[page], id);
  }
}

class HtReadingData extends ReadingData {
  @override
  final String title;

  @override
  final String id;

  HtReadingData(this.title, this.id,);

  @override
  Map<String, String>? get eps => null;

  @override
  bool get hasEp => false;

  @override
  String get sourceKey => "htManga";

  @override
  ComicType get type => ComicType.htManga;

  @override
  String get downloadId => "Ht$id";

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) {
    return HtmangaNetwork().getImages(id);
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    return ImageManager().getImage(url);
  }
}

class NhentaiReadingData extends ReadingData {
  @override
  final String title;

  @override
  final String id;

  NhentaiReadingData(this.title, this.id);

  @override
  Map<String, String>? get eps => null;

  @override
  bool get hasEp => false;

  @override
  String get sourceKey => "nhentai";

  @override
  ComicType get type => ComicType.nhentai;

  @override
  String get downloadId => "nhentai$id";

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) {
    return NhentaiNetwork().getImages(id);
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    return ImageManager().getImage(url);
  }
}

class CustomReadingData extends ReadingData{
  CustomReadingData(this.id, this.title, this.source, this.eps);

  final ComicSource source;

  @override
  String get downloadId => DownloadManager().generateId(sourceKey, id);

  @override
  final Map<String, String>? eps;

  @override
  bool get hasEp => eps != null;

  @override
  String id;

  @override
  final String title;

  @override
  Future<Res<List<String>>> loadEpNetwork(int ep) {
    if(hasEp){
      return source.loadComicPages!(id, eps!.keys.elementAtOrNull(ep-1) ?? id);
    } else {
      return source.loadComicPages!(id, null);
    }
  }

  @override
  Stream<DownloadProgress> loadImageNetwork(int ep, int page, String url) {
    return ImageManager().getCustomImage(
        url,
        id,
        eps?.keys.elementAtOrNull(ep-1) ?? id,
        sourceKey
    );
  }

  @override
  String get sourceKey => source.key;

  @override
  ComicType get type => ComicType.other;

}
