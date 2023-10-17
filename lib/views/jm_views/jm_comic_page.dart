import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/jm_network/jm_image.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/jm_views/jm_comments_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_widgets.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/comic_reading_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../../foundation/app.dart';
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import '../../foundation/ui_mode.dart';
import '../../network/download.dart';
import '../main_page.dart';
import '../../foundation/local_favorites.dart';
import '../widgets/select_download_eps.dart';
import '../widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class JmComicPage extends ComicPage<JmComicInfo> {
  const JmComicPage(this.id, {super.key});
  @override
  final String id;

  @override
  Row get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: Text(data!.likes.toString()),
              avatar: data!.liked
                  ? const Icon(Icons.favorite)
                  : const Icon(Icons.favorite_outline),
              onPressed: () {
                if (data!.liked) {
                  showMessage(context, "已经喜欢了");
                  return;
                }
                jmNetwork.likeComic(data!.id);
                data!.liked = true;
                update();
              },
            ),
          ),
          Expanded(
            child: ActionChip(
              label: !favorite ? Text("收藏".tl) : Text("已收藏".tl),
              avatar: !favorite ? const Icon(Icons.bookmark_add_outlined) : const Icon(Icons.bookmark_add),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: appdata.jmEmail != "",
                needLoadFolderData: true,
                setFavorite: (b){
                  if(favorite != b){
                    favorite = b;
                    update();
                  }
                },
                foldersLoader: () async{
                  var res = await jmNetwork.getFolders();
                  if(res.error){
                    return res;
                  }else{
                    var resData = <String, String>{"-1":"全部收藏".tl};
                    resData.addAll(res.data);
                    return Res(resData);
                  }
                },
                target: id,
                favoriteOnPlatform: data!.favorite,
                selectFolderCallback: (folder, page) async{
                  if(page == 0){
                    showMessage(context, "正在添加收藏".tl);
                    var res = await jmNetwork.favorite(id);
                    if(res.error){
                      showMessage(Get.context, res.errorMessageWithoutNull);
                      return;
                    }
                    if(folder != "-1") {
                      var res2 = await jmNetwork.moveToFolder(id, folder);
                      if (res2.error) {
                        showMessage(Get.context, res2.errorMessageWithoutNull);
                        return;
                      }
                    }
                    data!.favorite = true;
                    showMessage(Get.context, "成功添加收藏".tl);
                  }else{
                    LocalFavoritesManager().addComic(folder, FavoriteItem.fromJmComic(JmComicBrief(
                      id,
                      data!.author.elementAtOrNull(0)??"",
                      data!.name,
                      data!.description,
                      [],
                      [],
                      ignoreExamination: true
                    )));
                    showMessage(Get.context, "成功添加收藏".tl);
                  }
                },
                cancelPlatformFavorite: ()async{
                  showMessage(context, "正在取消收藏".tl);
                  var res = await jmNetwork.favorite(id);
                  showMessage(Get.context, !res.error?"成功取消收藏".tl:"网络错误".tl);
                  data!.favorite = false;
                },
              )),
            ),
          ),
          Expanded(
            child: ActionChip(
                label: Text(data!.comments.toString()),
                avatar: const Icon(Icons.comment_outlined),
                onPressed: () => showComments(context, id)),
          ),
        ],
      );

  @override
  String get cover => getJmCoverUrl(id);

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () => downloadComic(data!, context),
        child: downloadManager.downloadedJmComics.contains("jm$id")
            ? Text("修改".tl)
            : Text("下载".tl),
      );

  @override
  EpsData? get eps => EpsData(
          List<String>.generate(data!.series.values.length,
              (index) => "第 @c 章".tlParams({"c": (index + 1).toString()})),
          (i) async{
        await addJmHistory(data!);
        Get.to(() => ComicReadingPage.jmComic(
            data!.id, data!.name, data!.series.values.toList(), i + 1));
      });

  @override
  String? get introduction => data!.description;

  @override
  Future<Res<JmComicInfo>> loadData() => JmNetwork().getComicInfo(id);

  @override
  int? get pages => null;

  @override
  Future<bool> loadFavorite(JmComicInfo data) async{
    return data.favorite || (await LocalFavoritesManager().find(data.id)).isNotEmpty;
  }

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readJmComic(data!, data!.series.values.toList()),
        child: Text("阅读".tl),
      );

  @override
  SliverGrid recommendationBuilder(JmComicInfo data) => SliverGrid(
        delegate: SliverChildBuilderDelegate(
            childCount: data.relatedComics.length, (context, i) {
          return JmComicTile(data.relatedComics[i]);
        }),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: App.comicTileMaxWidth,
          childAspectRatio: App.comicTileAspectRatio,
        ),
      );

  @override
  String get tag => "Jm ComicPage $id";

  @override
  Map<String, List<String>>? get tags => {
        "作者".tl: (data!.author.isEmpty) ? "未知".tl.toList() : data!.author,
        "ID": "JM${data!.id}".toList(),
        "查看".tl: "${data!.views}".toList(),
        "标签".tl: data!.tags
      };

  @override
  void tapOnTags(String tag) =>
      MainPage.to(() => JmSearchPage(tag));

  @override
  ThumbnailsData? get thumbnailsCreator => null;

  @override
  String? get title => data!.name;

  @override
  Card? get uploaderInfo => null;

  @override
  String get source => "禁漫天堂".tl;
}

void downloadComic(JmComicInfo comic, BuildContext context) async {
  for (var i in downloadManager.downloading) {
    if (i.id == comic.id) {
      showMessage(context, "下载中".tl);
      return;
    }
  }

  List<String> eps = [];
  if (comic.series.isEmpty) {
    eps.add("第1章".tl);
  } else {
    eps = List<String>.generate(comic.series.length,
        (index) => "第 @c 章".tlParams({"c": (index + 1).toString()}));
  }

  var downloaded = <int>[];
  if (DownloadManager().downloadedJmComics.contains("jm${comic.id}")) {
    var downloadedComic =
        await DownloadManager().getJmComicFormId("jm${comic.id}");
    downloaded.addAll(downloadedComic.downloadedEps);
  }

  if (UiMode.m1(Get.context!)) {
    showModalBottomSheet(
        context: Get.context!,
        builder: (context) {
          return SelectDownloadChapter(eps, (selectedEps) {
            downloadManager.addJmDownload(comic, selectedEps);
            Get.back();
            showMessage(context, "已加入下载".tl);
          }, downloaded);
        });
  } else {
    showSideBar(
        Get.context!,
        SelectDownloadChapter(eps, (selectedEps) {
          downloadManager.addJmDownload(comic, selectedEps);
          Get.back();
          showMessage(context, "已加入下载".tl);
        }, downloaded),
        useSurfaceTintColor: true);
  }
}