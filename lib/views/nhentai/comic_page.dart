import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/nhentai/comic_tile.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../../network/download.dart';
import '../main_page.dart';
import '../../foundation/local_favorites.dart';
import '../widgets/show_message.dart';
import 'comments.dart';
import 'package:get/get.dart';


class NhentaiComicPage extends ComicPage<NhentaiComic>{
  const NhentaiComicPage(this._id, {super.key});

  final String _id;

  @override
  String get url => "https://nhentai.net/g/$_id/";

  @override
  String get id => (data?.id) ?? _id;

  @override
  ActionFunc? get searchSimilar => (){
    String? subTitle = data!.subTitle;
    if(subTitle == ""){
      subTitle = null;
    }
    var title = subTitle ?? data!.title;
    title = title.replaceAll(RegExp(r"\[.*?\]"), "").replaceAll(RegExp(r"\(.*?\)"), "");
    MainPage.to(() => NhentaiSearchPage("\"$title\"".trim()));
  };

  @override
  Row? get actions => Row(
    children: [
      Expanded(
        child: ActionChip(
          label: Text("${data!.tags["Pages"]?.elementAtOrNull(0) ?? ""}P"),
          avatar: const Icon(Icons.pages),
          onPressed: () {},
        ),
      ),
      Expanded(
        child: ActionChip(
          label: !favorite ? Text("收藏".tl) : Text("已收藏".tl),
          avatar: !favorite ? const Icon(Icons.bookmark_add_outlined) : const Icon(Icons.bookmark_add),
          onPressed: ()=> favoriteComic(FavoriteComicWidget(
            havePlatformFavorite: NhentaiNetwork().logged,
            needLoadFolderData: false,
            favoriteOnPlatform: data!.favorite,
            initialFolder: "0",
            target: id,
            setFavorite: (b){
              if(favorite != b){
                favorite = b;
                update();
              }
            },
            folders: const {"0": "Nhentai"},
            selectFolderCallback: (folder, page) async{
              if(page == 0){
                showMessage(context, "正在添加收藏".tl);
                var res = await NhentaiNetwork().favoriteComic(id, data!.token);
                if(res.error){
                  showMessage(Get.context, res.errorMessageWithoutNull);
                  return;
                }
                data!.favorite = true;
                showMessage(Get.context, "成功添加收藏".tl);
              }else{
                LocalFavoritesManager().addComic(folder, FavoriteItem.fromNhentai(NhentaiComicBrief(
                    data!.title,
                    data!.cover,
                    id,"Unknown",
                    data!.tags["Tags"] ?? const <String>[]
                )));
                showMessage(Get.context, "成功添加收藏".tl);
              }
            },
            cancelPlatformFavorite: ()async{
              showMessage(context, "正在取消收藏".tl);
              var res = await NhentaiNetwork().unfavoriteComic(id, data!.token);
              showMessage(Get.context, !res.error?"成功取消收藏".tl:"网络错误".tl);
              data!.favorite = false;
            },
          )),
        ),
      ),
      Expanded(
        child: ActionChip(
            label: Text("评论".tl),
            avatar: const Icon(Icons.comment_outlined),
            onPressed: () => showComments(context, id)),
      ),
    ],
  );

  @override
  String get cover => data!.cover;

  @override
  FilledButton get downloadButton => FilledButton(
    onPressed: () {
      final id = "nhentai${data!.id}";
      if (DownloadManager().downloadedHtComics.contains(id)) {
        showMessage(context, "已下载".tl);
        return;
      }
      for (var i in DownloadManager().downloading) {
        if (i.id == id) {
          showMessage(context, "下载中".tl);
          return;
        }
      }
      DownloadManager().addNhentaiDownload(data!);
      showMessage(context, "已加入下载队列".tl);
    },
    child:
    DownloadManager().downloadedHtComics.contains("nhentai${data!.id}")
        ? Text("已下载".tl)
        : Text("下载".tl),
  );

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  bool get enableTranslationToCN =>
      PlatformDispatcher.instance.locale.languageCode == "zh";

  @override
  Future<Res<NhentaiComic>> loadData() => NhentaiNetwork().getComicInfo(_id);

  @override
  int? get pages => null;

  @override
  String? get subTitle => data!.subTitle;

  @override
  FilledButton get readButton => FilledButton(
    child: Text("阅读".tl),
    onPressed: () => readNhentai(data!),
  );

  @override
  void onThumbnailTapped(int index) {
    readNhentai(data!, index+1);
  }

  @override
  Future<bool> loadFavorite(NhentaiComic data) async{
    return data.favorite || (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }

  @override
  SliverGrid? recommendationBuilder(NhentaiComic data) => SliverGrid(
    delegate: SliverChildBuilderDelegate(
        childCount: data.recommendations.length, (context, i) {
      return NhentaiComicTile(data.recommendations[i]);
    }),
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: App.comicTileMaxWidth,
      childAspectRatio: App.comicTileAspectRatio,
    ),
  );

  @override
  String get tag => "Nhentai $_id";

  Map<String, List<String>> generateTags(){
    var tags = Map<String, List<String>>.from(data!.tags);
    tags.remove("Pages");
    tags.removeWhere((key, value) => value.isEmpty);
    return tags;
  }

  @override
  Map<String, List<String>>? get tags => generateTags();

  @override
  void tapOnTags(String tag) {
    if(tag.contains(" ")){
      tag = "\"$tag\"";
    }
    MainPage.to(()=>NhentaiSearchPage(tag));
  }

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData(data!.thumbnails, (page)async => const Res([]), 1);

  @override
  String? get title => data!.title;

  @override
  Card? get uploaderInfo => null;

  @override
  String get source => "Nhentai";
}