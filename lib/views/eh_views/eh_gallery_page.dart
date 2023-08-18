import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/eh_views/eh_comments_page.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/stars.dart';
import 'package:pica_comic/views/main_page.dart';
import '../../network/eh_network/get_gallery_id.dart';
import '../models/local_favorites.dart';
import '../page_template/comic_page.dart';
import '../reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class EhGalleryPage extends ComicPage<Gallery> {
  const EhGalleryPage(this.brief, {super.key});
  final EhGalleryBrief brief;

  @override
  Row get actions => Row(
        children: [
          Expanded(
            child: ActionChip(
              label: Text("评分".tl),
              avatar: const Icon(Icons.star),
              onPressed: () => starRating(context, data!.auth!),
            ),
          ),
          Expanded(
            child: ActionChip(
              label: Text("收藏".tl),
              avatar: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: appdata.ehAccount != "",
                needLoadFolderData: false,
                folders: Map<String, String>.fromIterable(EhNetwork().folderNames,),
                favoriteOnPlatform: data!.favorite,
                selectFolderCallback: (folder, page) async{
                  if(page == 0){
                    showMessage(context, "正在添加收藏".tl);
                    var res = await EhNetwork().favorite(
                        data!.auth!["gid"]!, data!.auth!["token"]!,
                        id: EhNetwork().folderNames.indexOf(folder).toString());
                    res?(data!.favorite=true):null;
                    showMessage(Get.context, res?"成功添加收藏".tl:"网络错误".tl);
                  }else{
                    LocalFavoritesManager().addComic(folder,
                        FavoriteItem.fromEhentai(brief));
                    showMessage(Get.context, "成功添加收藏".tl);
                  }
                },
                cancelPlatformFavorite: (){
                  EhNetwork().unfavorite(data!.auth!["gid"]!, data!.auth!["token"]!);
                },
              ))
            ),
          ),
          Expanded(
            child: ActionChip(
                label: const Text("评论"),
                avatar: const Icon(Icons.comment_outlined),
                onPressed: () =>
                    showComments(context, brief.link, data!.uploader)),
          ),
        ],
      );

  @override
  String get cover => brief.coverPath;

  @override
  FilledButton get downloadButton => FilledButton(
        onPressed: () {
          final id = getGalleryId(data!.link);
          if (downloadManager.downloadedGalleries.contains(id)) {
            showMessage(context, "已下载".tl);
            return;
          }
          for (var i in downloadManager.downloading) {
            if (i.id == id) {
              showMessage(context, "下载中".tl);
              return;
            }
          }
          downloadManager.addEhDownload(data!);
          showMessage(context, "已加入下载队列".tl);
        },
        child: (downloadManager.downloadedGalleries
                .contains(getGalleryId(data!.link)))
            ? const Text("已下载")
            : const Text("下载"),
      );

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  Future<Res<Gallery>> loadData() => EhNetwork().getGalleryInfo(brief);

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
        onPressed: () => readEhGallery(data!),
        child: Text("阅读".tl),
      );

  @override
  SliverGrid? recommendationBuilder(Gallery data) => null;

  @override
  String get tag => "Eh ComicPage ${brief.link}";

  @override
  Map<String, List<String>>? get tags => {
        "类型".tl: data!.type.toList(),
        "时间".tl: data!.time.toList(),
        ...data!.tags
      };

  @override
  bool get enableTranslationToCN =>
      PlatformDispatcher.instance.locale.languageCode == "zh";

  @override
  void tapOnTags(String tag) =>
      MainPage.to(() => EhSearchPage(tag));

  @override
  Map<String, String> get headers => {
    "Cookie": EhNetwork().cookiesStr,
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
    "Referer": EhNetwork().ehBaseUrl,
  };

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData(
      data!.thumbnailUrls,
      (page) => EhNetwork().getThumbnailUrls(brief.link, page),
      int.parse(data!.maxPage));

  @override
  String? get title => brief.title;

  @override
  Card? get uploaderInfo => null;

  void starRating(BuildContext context, Map<String, String> auth) {
    if (appdata.ehId == "") {
      showMessage(context, "未登录".tl);
      return;
    }
    showDialog(
        context: context,
        builder: (dialogContext) => GetBuilder<RatingLogic>(
            init: RatingLogic(),
            builder: (logic) => SimpleDialog(
                  title: const Text("评分"),
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      child: Center(
                        child: SizedBox(
                          width: 210,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 10,
                              ),
                              RatingWidget(
                                padding: 2,
                                onRatingUpdate: (value) => logic.rating = value,
                                value: 0,
                                selectAble: true,
                                size: 40,
                              ),
                              const Spacer(),
                              if (!logic.running)
                                FilledButton(
                                    onPressed: () {
                                      logic.running = true;
                                      logic.update();
                                      EhNetwork()
                                          .rateGallery(
                                              auth, logic.rating.toInt())
                                          .then((b) {
                                        if (b) {
                                          Get.back();
                                          showMessage(context, "评分成功".tl);
                                        } else {
                                          logic.running = false;
                                          logic.update();
                                          showMessage(dialogContext, "网络错误");
                                        }
                                      });
                                    },
                                    child: Text("提交".tl))
                              else
                                const CircularProgressIndicator()
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                )));
  }

  @override
  Widget get buildMoreInfo => SizedBox(
        height: 30,
        child: Row(
          children: [
            for (int i = 0; i < (data!.stars ~/ 0.5) ~/ 2; i++)
              Icon(
                Icons.star,
                size: 30,
                color: Theme.of(context).colorScheme.secondary,
              ),
            if ((data!.stars ~/ 0.5) % 2 == 1)
              Icon(
                Icons.star_half,
                size: 30,
                color: Theme.of(context).colorScheme.secondary,
              ),
            for (int i = 0;
                i < (5 - (data!.stars ~/ 0.5) ~/ 2 - (data!.stars ~/ 0.5) % 2);
                i++)
              const Icon(
                Icons.star_border,
                size: 30,
              ),
            const SizedBox(
              width: 5,
            ),
            if (data!.rating != null) Text(data!.rating!)
          ],
        ),
      );
}

class RatingLogic extends GetxController {
  double rating = 0;
  bool running = false;
}

class CommentLogic extends GetxController {
  final controller = TextEditingController();
  bool sending = false;
}
