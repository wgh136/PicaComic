import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import '../page_template/comic_page.dart';
import '../widgets/avatar.dart';
import '../widgets/show_message.dart';

class HtComicPage extends ComicPage<HtComicInfo>{
  const HtComicPage(this.comic, {super.key});

  final HtComicBrief comic;

  @override
  Row? get actions => Row(
    children: [
      SizedBox.fromSize(
        size: const Size(10, 1),
      ),
      Expanded(
        child: ActionChip(
            label: Padding(
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 0),
              child: Text("收藏".tr),
            ),
            avatar: const Icon(Icons.bookmark_outline),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return FavoriteComicDialog(data!.id);
                  });
            }),
      ),
      SizedBox.fromSize(
        size: const Size(10, 1),
      ),
      Expanded(
        child: ActionChip(
          label: Text("页数: ${data!.pages}"),
          avatar: const Icon(Icons.pages),
          onPressed: () {},
        ),
      )
    ],
  );

  @override
  String get cover => comic.image;

  @override
  FilledButton get downloadButton => FilledButton(
    onPressed: () {
      final id = "Ht${data!.id}";
      if (DownloadManager().downloadedHtComics.contains(id)) {
        showMessage(context, "已下载".tr);
        return;
      }
      for (var i in DownloadManager().downloading) {
        if (i.id == id) {
          showMessage(context, "下载中".tr);
          return;
        }
      }
      DownloadManager().addHtDownload(data!);
      showMessage(context, "已加入下载队列".tr);
    },
    child:
    DownloadManager().downloadedHtComics.contains("Ht${data!.id}")
        ? Text("已下载".tr)
        : Text("下载".tr),
  );

  @override
  EpsData? get eps => null;

  @override
  String? get introduction => data!.description;

  @override
  Future<Res<HtComicInfo>> loadData() => HtmangaNetwork().getComicInfo(comic.id);

  @override
  int? get pages => null;

  @override
  FilledButton get readButton => FilledButton(
    onPressed: () => readHtmangaComic(data!),
    child: Text("阅读".tr),
  );

  @override
  SliverGrid? recommendationBuilder(HtComicInfo data) => null;

  @override
  String get tag => "Ht ComicPage ${comic.id}";

  @override
  Map<String, List<String>>? get tags => {
    "分类".tr: data!.category.toList(),
    "标签".tr: data!.tags.keys.toList()
  };

  @override
  void tapOnTags(String tag) =>
      Get.to(() => HtSearchPage(tag), preventDuplicates: false);

  @override
  ThumbnailsData? get thumbnailsCreator => ThumbnailsData(data!.thumbnails,
      (page) => HtmangaNetwork().getThumbnails(data!.id, page),
      (data!.pages / data!.thumbnails.length).ceil());

  @override
  String? get title => comic.name.removeAllBlank;

  @override
  Card? get uploaderInfo => Card(
    elevation: 0,
    color: Theme.of(context).colorScheme.inversePrimary,
    child: SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            flex: 0,
            child: Avatar(
              size: 50,
              avatarUrl: data!.avatar,
              couldBeShown: false,
              name: data!.uploader,
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data!.uploader,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text("投稿作品${data!.uploadNum}部")
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

}

class HtComicPageLogic extends GetxController {
  bool loading = true;
  HtComicInfo? comic;
  String? message;
  ScrollController controller = ScrollController();
  bool showAppbarTitle = false;
  List<String> images = [];

  void get(String id) async {
    var res = await HtmangaNetwork().getComicInfo(id);
    message = res.errorMessage;
    comic = res.dataOrNull;
    if (res.subData != null) {
      images.addAll(res.subData);
    }
    loading = false;
    update();
  }

  void refresh_() {
    comic = null;
    message = null;
    loading = true;
    update();
  }

  void getImages() async {
    var nextPage = images.length ~/ 12 + 1;
    var res = await HtmangaNetwork().getThumbnails(comic!.id, nextPage);
    if (!res.error) {
      images.addAll(res.data);
      update();
    }
  }
}


class FavoriteComicDialog extends StatefulWidget {
  const FavoriteComicDialog(this.id, {Key? key}) : super(key: key);
  final String id;

  @override
  State<FavoriteComicDialog> createState() => _FavoriteComicDialogState();
}

class _FavoriteComicDialogState extends State<FavoriteComicDialog> {
  bool loading = true;
  Map<String, String> folders = {};
  String? message;
  String folderName = "选择收藏夹".tr;
  String folderId = "";
  bool loading2 = false;
  bool addedFavorite = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      get();
    }
    return SimpleDialog(
      title: Text("收藏漫画".tr),
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
          const SizedBox(
            key: Key("1"),
            width: 300,
            height: 150,
            child: Center(
              child: Text("网络错误"),
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
                      Text("  选择收藏夹:  ".tr),
                      Text(folderName),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.arrow_drop_down_sharp),
                        onPressed: () {
                          if (loading) {
                            showMessage(context, "加载中".tr);
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
                        if (folderId == "") {
                          return;
                        }
                        setState(() {
                          loading2 = true;
                        });
                        var res = await HtmangaNetwork()
                            .addFavorite(widget.id, folderId);
                        if (res.error) {
                          showMessage(Get.context, res.errorMessage!);
                          setState(() {
                            loading2 = false;
                          });
                        } else {
                          Get.back();
                          showMessage(Get.context, "添加成功".tr);
                        }
                      },
                      child: Text("提交".tr))
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
    var r = await HtmangaNetwork().getFolders();
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
