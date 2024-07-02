import 'package:pica_comic/foundation/app.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/eh_views/eh_comments_page.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/stars.dart';
import 'package:pica_comic/views/main_page.dart';
import '../../foundation/history.dart';
import '../../network/eh_network/get_gallery_id.dart';
import '../../foundation/local_favorites.dart';
import '../page_template/comic_page.dart';
import '../reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class EhGalleryPage extends ComicPage<Gallery> {
  EhGalleryPage(EhGalleryBrief brief, {super.key})
      : link = brief.link, comicCover = brief.coverPath, comicTitle = brief.title;

  const EhGalleryPage.fromLink(this.link, {super.key}): comicCover = null, comicTitle = null;

  final String link;

  final String? comicCover;

  final String? comicTitle;

  @override
  String get url => link;

  @override
  ActionFunc? get searchSimilar => () {
        var title = data!.subTitle ?? data!.title;
        title = title
            .replaceAll(RegExp(r"\[.*?\]"), "")
            .replaceAll(RegExp(r"\(.*?\)"), "");
        MainPage.to(() => EhSearchPage("\"$title\"".trim()));
      };

  @override
  String? get cover => comicCover ?? data?.coverPath;

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => null;

  @override
  Future<Res<Gallery>> loadData() async {
    var res =
        await EhNetwork().getGalleryInfo(link, appdata.settings[47] == "1");
    if (res.error && res.errorMessage == "Content Warning") {
      bool shouldIgnore = false;
      await showDialog(
          context: App.globalContext!,
          builder: (context) => AlertDialog(
                title: Text("警告".tl),
                content: Text("此画廊存在令人不适的内容\n在设置中可以禁用此警告".tl),
                actions: [
                  TextButton(
                      onPressed: () {
                        App.globalBack();
                      },
                      child: Text("返回".tl)),
                  TextButton(
                      onPressed: () {
                        shouldIgnore = true;
                        App.globalBack();
                      },
                      child: Text("忽略".tl))
                ],
              ));
      if (shouldIgnore) {
        return await EhNetwork().getGalleryInfo(link, true);
      } else {
        MainPage.back();
        return const Res(null, errorMessage: "Exit");
      }
    }
    return res;
  }

  @override
  int? get pages => int.tryParse(data?.maxPage ?? "");

  @override
  Future<bool> loadFavorite(Gallery data) async {
    return data.favorite ||
        (await LocalFavoritesManager().find(data.link)).isNotEmpty;
  }

  @override
  SliverGrid? recommendationBuilder(Gallery data) => null;

  @override
  String get tag => "Eh ComicPage $link";

  @override
  Map<String, List<String>>? get tags => {
        "类型".tl: data!.type.toList(),
        "时间".tl: data!.time.toList(),
        "上传者".tl: data!.uploader.toList(),
        ...data!.tags
      };

  @override
  bool get enableTranslationToCN =>
      App.locale.languageCode == "zh";

  @override
  void onThumbnailTapped(int index) {
    readEhGallery(data!, index + 1);
  }

  @override
  void tapOnTag(String tag, String key) {
    var namespace = "";
    for (var entry in data!.tags.entries) {
      if (entry.value.contains(tag)) {
        namespace = entry.key;
        break;
      }
    }
    if(tag == data!.uploader){
      namespace = "uploader";
    }
    if (tag.contains(" ")) {
      tag = "\"$tag\"";
    }
    if (namespace != "") {
      tag = "$namespace:$tag";
    }
    MainPage.to(() => EhSearchPage(tag));
  }

  @override
  Map<String, String> get headers => {
        "Cookie": EhNetwork().cookiesStr,
        "User-Agent": webUA,
        "Referer": EhNetwork().ehBaseUrl,
      };


  @override
  ThumbnailsData? get thumbnailsCreator {
    if(data?.auth?["thumbnailKey"] != null && data!.auth!["thumbnailKey"]!.startsWith("large thumbnail")){
      return ThumbnailsData(
          data!.thumbnails,
          (page) => EhNetwork().getLargeThumbnails(data!, page),
          int.tryParse(data!.auth!["thumbnailKey"]!.nums) ?? 1
      );
    } else {
      return ThumbnailsData([], (page) => EhNetwork().getThumbnailUrls(data!), 2);
    }
  }

  @override
  String? get title => comicTitle ?? data?.title;

  @override
  String? get subTitle => data?.subTitle;

  @override
  Card? get uploaderInfo => null;

  @override
  Widget thumbnailImageBuilder(int index, String imageUrl) {
    if(data?.auth?["thumbnailKey"] != null && data!.auth!["thumbnailKey"]!.startsWith("large thumbnail")){
      return super.thumbnailImageBuilder(index, imageUrl);
    }
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: EhThumbnailLoader(
          image: CachedImageProvider(imageUrl), index: index),
    );
  }

  void starRating(BuildContext context, Map<String, String> auth) {
    if (appdata.ehAccount == "") {
      showMessage(context, "未登录".tl);
      return;
    }
    showDialog(
        context: context,
        builder: (dialogContext) => StateBuilder<RatingLogic>(
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
                                          App.globalBack();
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
  Widget get buildMoreInfo => MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () => starRating(context, data!.auth!),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < (data!.stars ~/ 0.5) ~/ 2; i++)
              const Icon(
                Icons.star,
                size: 30,
                color: Color(0xffffbf00),
              ),
            if ((data!.stars ~/ 0.5) % 2 == 1)
              const Icon(
                Icons.star_half,
                size: 30,
                color: Color(0xffffbf00),
              ),
            for (int i = 0;
            i < (5 - (data!.stars ~/ 0.5) ~/ 2 - (data!.stars ~/ 0.5) % 2);
            i++)
              const Icon(
                Icons.star_border,
                size: 30,
                color: Color(0xffffbf00),
              ),
            const SizedBox(
              width: 5,
            ),
            if (data!.rating != null) Text(data!.rating!)
          ],
        ),
      ),
    ),
  );

  @override
  String get id => link;

  @override
  String get source => "EHentai";

  @override
  FavoriteItem toLocalFavoriteItem() => FavoriteItem.fromEhentai(data!.toBrief());

  @override
  void download() {
    int current = 0;
    bool loading = true;
    ArchiveDownloadInfo? info;
    bool cancelUnlock = false;

    showDialog(context: context, builder: (context) => Dialog(
      child: StatefulBuilder(builder: (context, setState) {

        void load() async{
          if(data?.auth?["archiveDownload"] == null){
            return;
          }

          Res<ArchiveDownloadInfo> res;
          if(cancelUnlock){
            cancelUnlock = false;
            res = await EhNetwork().cancelAndReloadArchiveInfo(info!);
          } else {
            res = await EhNetwork().getArchiveDownloadInfo(
                data!.auth!["archiveDownload"]!);
          }
          if (res.error) {
            showToast(message: "网络错误".tl);
          } else {
            info = res.data;
            loading = false;
            if(context.mounted) {
              setState(() {});
            }
          }
        }

        if(loading){
          load();
        }

        return Container(
          width: 350,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("下载".tl, style: const TextStyle(fontSize: 20)).paddingLeft(16),
              const Divider(),
              RadioListTile(
                  value: 0,
                  groupValue: current,
                  onChanged: (value) => setState(() => current = value as int),
                  title: Text("普通下载".tl)
              ),
              ExpansionTile(
                title: Text("归档下载".tl),
                shape: Border.all(color: Colors.transparent),
                children: [
                  if(loading)
                    const CircularProgressIndicator().paddingVertical(8).toCenter()
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile(
                            value: 1,
                            groupValue: current,
                            onChanged: (value) => setState(() => current = value as int),
                            title: Text("Original".tl),
                            subtitle: Text("${info!.originCost} ${info!.originSize}"),
                        ),
                        RadioListTile(
                            value: 2,
                            groupValue: current,
                            onChanged: (value) => setState(() => current = value as int),
                            title: Text("Resample".tl),
                            subtitle: Text("${info!.resampleCost} ${info!.resampleSize}"),
                        ),
                        if(info!.cancelUnlockUrl != null)
                          ListTile(
                            leading: const Icon(Icons.lock_open),
                            title: Text("取消解锁".tl),
                            subtitle: Text("长按执行此操作".tl),
                            onLongPress: (){
                              setState((){
                                cancelUnlock = true;
                                loading = true;
                              });
                            },
                          ).paddingLeft(6),
                      ],
                    )
              ],),
              FilledButton(onPressed: () {
                startDownload(current);
                App.back(context);
              }, child: Text("确认".tl)).toCenter()
            ],
          ),
        );
      },),));
  }

  void startDownload(int type) {
    final id = getGalleryId(data!.link);
    if (downloadManager.downloaded.contains(id)) {
      showToast(message: "已下载".tl);
      return;
    }
    for (var i in downloadManager.downloading) {
      if (i.id == id) {
        showToast(message: "下载中".tl);
        return;
      }
    }
    downloadManager.addEhDownload(data!, type);
    showToast(message: "已加入队列".tl);
  }

  @override
  void openFavoritePanel() {
    favoriteComic(FavoriteComicWidget(
      havePlatformFavorite: appdata.ehAccount != "",
      needLoadFolderData: false,
      folders: Map<String, String>.fromIterable(
        EhNetwork().folderNames,
      ),
      favoriteOnPlatform: data!.favorite,
      target: link,
      setFavorite: (b) {
        if (favorite != b) {
          favorite = b;
          update();
        }
      },
      selectFolderCallback: (folder, page) async {
        if (page == 0) {
          showMessage(context, "正在添加收藏".tl);
          var res = await EhNetwork().favorite(
              data!.auth!["gid"]!, data!.auth!["token"]!,
              id: EhNetwork().folderNames.indexOf(folder).toString());
          res ? (data!.favorite = true) : null;
          showMessage(App.globalContext, res ? "成功添加收藏".tl : "网络错误".tl);
        } else {
          LocalFavoritesManager().addComic(
              folder, FavoriteItem.fromEhentai(data!.toBrief()));
          showMessage(App.globalContext, "成功添加收藏".tl);
        }
      },
      cancelPlatformFavorite: () {
        EhNetwork()
            .unfavorite(data!.auth!["gid"]!, data!.auth!["token"]!);
      },
    ));
  }

  @override
  void read(History? history) {
    readEhGallery(data!, history?.page, false);
  }

  @override
  ActionFunc? get openComments =>
          () => showComments(context, link, data!.uploader);

  @override
  String get downloadedId => getGalleryId(link);
}

class RatingLogic extends StateController {
  double rating = 0;
  bool running = false;
}

class CommentLogic extends StateController {
  final controller = TextEditingController();
  bool sending = false;
}

class EhThumbnailLoader extends StatefulWidget {
  const EhThumbnailLoader(
      {required this.image, required this.index, super.key});

  final ImageProvider image;

  final int index;

  @override
  State<EhThumbnailLoader> createState() => _EhThumbnailLoaderState();
}

class _EhThumbnailLoaderState extends State<EhThumbnailLoader> {
  ui.Image? image;

  bool failed = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return const Center(
        child: Icon(Icons.error),
      );
    }

    if (image == null) {
      return const SizedBox();
    } else {
      return CustomPaint(
        painter: _EhThumbnailPainter(widget.index, image!),
        child: const SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
  }

  void _loadImage() async {
    final imageStream = widget.image.resolve(ImageConfiguration.empty);

    var listener = ImageStreamListener((imageInfo, _) {
      if (mounted) {
        setState(() {
          image = imageInfo.image;
        });
      }
    }, onError: (error, stack) {
      setState(() {
        failed = true;
      });
    });

    imageStream.addListener(listener);
  }
}

class _EhThumbnailPainter extends CustomPainter {
  final int index;
  final ui.Image image;

  _EhThumbnailPainter(this.index, this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final start = index % 20 * 100;
    final end = start + 100;
    final rect = Rect.fromLTRB(0, 0, size.width, size.height);
    final srcRect = Rect.fromLTRB(
        start.toDouble(), 0, end.toDouble(), image.height.toDouble());

    canvas.drawImageRect(
      image,
      srcRect,
      rect,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant _EhThumbnailPainter oldDelegate) {
    return image != oldDelegate.image;
  }
}
