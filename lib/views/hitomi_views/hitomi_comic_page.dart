import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/hitomi_network/image.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/hitomi_views/hi_widgets.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../base.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../models/local_favorites.dart';
import 'package:pica_comic/tools/translations.dart';

class HitomiComicPage extends ComicPage<HitomiComic> {
  const HitomiComicPage(this.comic, {super.key});

  HitomiComicPage.fromLink(String link, {super.key}):
      comic = HitomiComicBrief("", "", "", [], "", "", link, "");

  final HitomiComicBrief comic;

  @override
  Row? get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: !favorite ? Text("收藏".tl) : Text("已收藏".tl),
              avatar: !favorite ? const Icon(Icons.bookmark_add_outlined) : const Icon(Icons.bookmark_add),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: false,
                needLoadFolderData: false,
                target: comic.link,
                setFavorite: (b){
                  if(favorite != b){
                    favorite = b;
                    update();
                  }
                },
                selectFolderCallback: (folder, page){
                  LocalFavoritesManager().addComic(folder, FavoriteItem.fromHitomi(data!.toBrief(comic.link, cover)));
                  showMessage(context, "成功添加收藏".tl);
                },
              )),
            ),
          ),
        ],
      );

  @override
  String get cover => comic.cover;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () => downloadComic(data!, context, comic.cover, comic.link),
        child: Text("下载".tl),
      );

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  Future<Res<HitomiComic>> loadData() async{
    if(comic.cover == ""){
      var id = RegExp(r"\d+(?=\.html)").firstMatch(comic.link)![0]!;
      var res = await HiNetwork().getComicInfoBrief(id);
      if(res.error){
        return Res.fromErrorRes(res);
      }else{
        comic.cover = res.data.cover;
        comic.name = res.data.name;
        comic.tags = res.data.tags;
        comic.artist = res.data.artist;
        comic.lang = res.data.lang;
        comic.time = res.data.time;
        comic.type = res.data.type;
      }
    }
    return HiNetwork().getComicInfo(comic.link);
  }

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readHitomiComic(data!, comic.cover),
        child: Text("阅读".tl),
      );

  @override
  SliverGrid? recommendationBuilder(HitomiComic data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(childCount: data.related.length,
            (context, i) {
          return HitomiComicTileDynamicLoading(data.related[i]);
        }),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: comicTileMaxWidth,
          childAspectRatio: comicTileAspectRatio,
        ),
      );

  @override
  String get tag => "Hitomi ComicPage ${comic.link}";

  @override
  Map<String, List<String>>? get tags => {
        "类型".tl: data!.type.toList(),
        "时间".tl: data!.time.toList(),
        "语言".tl: data!.lang.toList(),
        "标签".tl:
            List.generate(data!.tags.length, (index) => data!.tags[index].name)
      };

  @override
  bool get enableTranslationToCN =>
      PlatformDispatcher.instance.locale.languageCode == "zh";

  @override
  void tapOnTags(String tag) =>
      MainPage.to(() => HitomiSearchPage(tag));

  @override
  Map<String, String> get headers => {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36",
    "Referer": "https://hitomi.la/"
  };

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData([], (page)async{
    try {
      var gg = GG();
      var images = <String>[];
      for (var file in data!.files) {
        images.add(await gg.urlFromUrlFromHash(
            data!.id, file, "webpsmallsmalltn", "webp", 'tn'));
      }
      return Res(images);
    }
    catch(e, s){
      print("$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }, 2);

  @override
  void onThumbnailTapped(int index) {
    readHitomiComic(data!, cover, index+1);
  }

  @override
  String? get title => comic.name;

  @override
  Card? get uploaderInfo => null;

  @override
  Future<bool> loadFavorite(HitomiComic data) async{
    return (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }
}

void downloadComic(
    HitomiComic comic, BuildContext context, String cover, String link) {
  if (downloadManager.downloaded.contains(comic.id)) {
    showMessage(context, "已下载".tl);
    return;
  }
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tl);
      return;
    }
  }
  downloadManager.addHitomiDownload(comic, cover, link);
  showMessage(context, "已加入下载".tl);
}
