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
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import '../../foundation/ui_mode.dart';
import '../../network/download.dart';
import '../models/local_favorites.dart';
import '../widgets/select_download_eps.dart';
import '../widgets/side_bar.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class JmComicPage extends ComicPage<JmComicInfo> {
  const JmComicPage(this.id, {super.key});
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
              label: Text("收藏".tl),
              avatar: const Icon(Icons.bookmark_add_outlined),
              onPressed: () => favoriteComic(FavoriteComicWidget(
                havePlatformFavorite: appdata.jmEmail != "",
                needLoadFolderData: true,
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
            ? const Text("已下载")
            : const Text("下载"),
      );

  @override
  EpsData? get eps => EpsData(
          List<String>.generate(data!.series.values.length,
              (index) => "第 @c 章".tlParams({"c": (index + 1).toString()})),
          (i) {
        addJmHistory(data!);
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
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: comicTileMaxWidth,
          childAspectRatio: comicTileAspectRatio,
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
      Get.to(() => JmSearchPage(tag), preventDuplicates: false);

  @override
  ThumbnailsData? get thumbnailsCreator => null;

  @override
  String? get title => data!.name;

  @override
  Card? get uploaderInfo => null;
}

class FavoriteComicDialog extends StatefulWidget {
  const FavoriteComicDialog(this.id, this.comic, {Key? key}) : super(key: key);
  final String id;
  final JmComicInfo comic;

  @override
  State<FavoriteComicDialog> createState() => _FavoriteComicDialogState();
}

class _FavoriteComicDialogState extends State<FavoriteComicDialog> {
  bool loading = true;
  Map<String, String> folders = {};
  String? message;
  String folderName = "全部收藏".tl;
  String folderId = "0";
  bool loading2 = false;
  bool addedFavorite = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      get();
    }
    return SimpleDialog(
      title: Text("收藏漫画".tl),
      children: [
        if (loading)
          const SizedBox(
            key: Key("0"),
            width: 300,
            height: 150,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else if (message != null)
          SizedBox(
            key: const Key("1"),
            width: 300,
            height: 150,
            child: Center(
              child: Text(message!),
            ),
          )
        else
          SizedBox(
            key: const Key("2"),
            width: 300,
            height: 150,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(5),
                  width: 300,
                  height: 50,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(16))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("  选择收藏夹:  ".tl),
                      Text(folderName),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down_sharp),
                        onPressed: () {
                          if (loading) {
                            showMessage(context, "加载中".tl);
                            return;
                          }
                          showMenu(
                              context: context,
                              position: RelativeRect.fromLTRB(
                                  MediaQuery.of(context).size.width / 2 + 150,
                                  MediaQuery.of(context).size.height / 2,
                                  MediaQuery.of(context).size.width / 2 - 150,
                                  MediaQuery.of(context).size.height / 2),
                              items: [
                                PopupMenuItem(
                                  child: Text("全部收藏".tl),
                                  onTap: () {
                                    setState(() {
                                      folderName = "全部收藏".tl;
                                    });
                                    folderId = "0";
                                  },
                                ),
                                for (var folder in folders.entries)
                                  PopupMenuItem(
                                    child: Text(folder.value),
                                    onTap: () {
                                      setState(() {
                                        folderName = folder.value;
                                      });
                                      folderId = folder.key;
                                    },
                                  )
                              ]);
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                if (!loading2)
                  FilledButton(
                      onPressed: () async {
                        setState(() {
                          loading2 = true;
                        });
                        if (!addedFavorite) {
                          var res = await jmNetwork.favorite(widget.id);
                          if (res.error) {
                            showMessage(Get.context, res.errorMessage!);
                            setState(() {
                              loading2 = false;
                            });
                            return;
                          }
                        }
                        addedFavorite = true;
                        if (folderId != "0") {
                          var res2 =
                              await jmNetwork.moveToFolder(widget.id, folderId);
                          if (res2.error) {
                            showMessage(Get.context, res2.errorMessage!);
                            setState(() {
                              loading2 = false;
                            });
                            return;
                          }
                        }
                        Get.back();
                        widget.comic.favorite = true;
                        Get.find<ComicPageLogic<JmComicInfo>>(
                                tag: "Jm ComicPage ${widget.id}")
                            .update();
                        showMessage(Get.context, "添加成功".tl);
                      },
                      child: Text("提交".tl))
                else
                  const Center(
                    child: CircularProgressIndicator(),
                  )
              ],
            ),
          )
      ],
    );
  }

  void get() async {
    var r = await jmNetwork.getFolders();
    if (r.error) {
      message = r.errorMessage;
    } else {
      folders = r.data;
    }
    try {
      setState(() {
        loading = false;
      });
    } catch (e) {
      //可能退出了弹窗后网络请求返回
    }
  }
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
            showMessage(context, "已加入下载".tl);
          }, downloaded);
        });
  } else {
    showSideBar(
        Get.context!,
        SelectDownloadChapter(eps, (selectedEps) {
          downloadManager.addJmDownload(comic, selectedEps);
          showMessage(context, "已加入下载".tl);
        }, downloaded),
        useSurfaceTintColor: true);
  }
}