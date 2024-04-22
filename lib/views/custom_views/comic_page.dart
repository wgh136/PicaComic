import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/general_interface/search.dart';
import 'package:pica_comic/views/page_template/comic_page.dart';
import 'package:pica_comic/views/reader/goto_reader.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../../foundation/app.dart';
import '../../foundation/ui_mode.dart';
import '../../network/base_comic.dart';
import '../widgets/comment.dart';
import '../widgets/select_download_eps.dart';
import '../widgets/show_error.dart';
import '../widgets/side_bar.dart';
import 'custom_comic_tile.dart';

class CustomComicPage extends ComicPage<ComicInfoData> {
  const CustomComicPage({required this.sourceKey, required this.id,
    this.comicCover, super.key});

  final String sourceKey;

  @override
  final String id;

  final String? comicCover;

  @override
  String? get cover => comicCover ?? data?.cover;

  void downloadComic() async {
    final downloadId = DownloadManager().generateId(sourceKey, id);
    final eps = data!.chapters?.values.toList();
    for (var i in DownloadManager().downloading) {
      if (i.id == downloadId) {
        showToast(message: "下载中".tl);
        return;
      }
    }
    var downloaded = <int>[];
    if (DownloadManager().downloaded.contains(downloadId)) {
      if (eps == null) {
        showToast(message: "已下载".tl);
        return;
      }
      var downloadedComic = await DownloadManager().getComicOrNull(downloadId);
      downloaded.addAll(downloadedComic!.downloadedEps);
    } else {
      if (eps == null) {
        DownloadManager().addCustomDownload(data!, [0]);
        App.globalBack();
        showToast(message: "已加入下载".tl);
        return;
      }
    }
    if (UiMode.m1(App.globalContext!)) {
      showModalBottomSheet(
          context: App.globalContext!,
          builder: (context) {
            return SelectDownloadChapter(eps, (selectedEps) {
              DownloadManager().addCustomDownload(data!, selectedEps);
              App.globalBack();
              showToast(message: "已加入下载".tl);
            }, downloaded);
          });
    } else {
      showSideBar(
          App.globalContext!,
          SelectDownloadChapter(eps, (selectedEps) {
            DownloadManager().addCustomDownload(data!, selectedEps);
            App.globalBack();
            showToast(message: "已加入下载".tl);
          }, downloaded),
          useSurfaceTintColor: true);
    }
  }

  @override
  void download() => downloadComic();

  @override
  EpsData? get eps => data!.chapters != null
      ? EpsData(data!.chapters!.values.toList(), (ep) {
          readWithKey(sourceKey, id, ep + 1, 1, data!.title,
              {"eps": data!.chapters, "cover": data!.cover});
        })
      : null;

  @override
  String? get introduction => data!.description;

  ComicSource? get comicSource => ComicSource.find(sourceKey);

  @override
  Future<Res<ComicInfoData>> loadData() {
    if (comicSource == null) throw "Comic Source Not Found";
    return comicSource!.loadComicInfo!(id);
  }

  @override
  Future<bool> loadFavorite(ComicInfoData data) async {
    return false;
  }

  @override
  int? get pages => null;

  @override
  void read(History? history) {
    readWithKey(sourceKey, id, history?.ep ?? 1, history?.page ?? 1,
        data!.title, {"eps": data!.chapters, "cover": data!.cover});
  }

  @override
  SliverGrid? recommendationBuilder(ComicInfoData data) {
    if (data.suggestions == null) return null;

    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) =>
            CustomComicTile(data.suggestions![index] as CustomComic),
        childCount: data.suggestions!.length,
      ),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }

  @override
  String get source => comicSource!.name;

  @override
  String get tag => "$key comic page with id: $id";

  @override
  Map<String, List<String>>? get tags => data!.tags;

  @override
  void tapOnTags(String tag) {
    toSearchPage(comicSource!.key, tag);
  }

  @override
  ThumbnailsData? get thumbnailsCreator {
    if (data!.thumbnails == null && data!.thumbnailLoader == null) return null;

    return ThumbnailsData(
        data!.thumbnails ?? [],
        (page) =>
            data!.thumbnailLoader?.call(id, page) ??
            Future.value(const Res.error("")),
        data!.thumbnailMaxPage);
  }

  @override
  String? get title => data?.title;

  @override
  FavoriteItem toLocalFavoriteItem() {
    var tags = <String>[];
    data!.tags.forEach((key, value) => tags.addAll(value));
    return FavoriteItem.fromBaseComic(CustomComic(data!.title,
        data!.subTitle ?? "", data!.cover, id, tags, "", sourceKey));
  }

  @override
  Card? get uploaderInfo => null;

  @override
  void openFavoritePanel() {
    favoriteComic(FavoriteComicWidget(
      havePlatformFavorite:
          comicSource!.favoriteData != null && comicSource!.isLogin,
      needLoadFolderData: comicSource!.favoriteData?.multiFolder ?? false,
      folders: {
        if (!(comicSource!.favoriteData?.multiFolder ?? false))
          '0': comicSource!.name
      },
      foldersLoader: comicSource?.favoriteData?.loadFolders == null
        ? null
        : () => comicSource!.favoriteData!.loadFolders!(data!.comicId),
      initialFolder:
          (comicSource!.favoriteData?.multiFolder ?? false) ? null : '0',
      target: id,
      setFavorite: (b) {
        if (favorite != b) {
          favorite = b;
          update();
        }
      },
      favoriteOnPlatform: data!.isFavorite,
      selectFolderCallback: (folder, type) {
        if (type == 1) {
          LocalFavoritesManager().addComic(folder, toLocalFavoriteItem());
          showMessage(context, "成功添加收藏".tl);
        } else {
          showMessage(context, "正在添加收藏".tl);
          comicSource!.favoriteData!.addOrDelFavorite!(id, folder, true)
              .then((value) {
            hideMessage(context);
            if (value.error) {
              showMessage(context, "添加收藏失败".tl);
            } else {
              showMessage(context, "成功添加收藏".tl);
            }
          });
        }
      },
      cancelPlatformFavorite: () {
        showMessage(context, "正在取消收藏".tl);
        comicSource!.favoriteData!.addOrDelFavorite!(id, '0', false)
            .then((value) {
          hideMessage(context);
          if (value.error) {
            showMessage(context, "取消收藏失败".tl);
          } else {
            showMessage(context, "成功取消收藏".tl);
          }
        });
      },
      cancelPlatformFavoriteWithFolder: (folder) {
        showMessage(context, "正在取消收藏".tl);
        comicSource!.favoriteData!.addOrDelFavorite!(id, folder, false)
            .then((value) {
          hideMessage(context);
          if (value.error) {
            showMessage(context, "取消收藏失败".tl);
          } else {
            showMessage(context, "成功取消收藏".tl);
          }
        });
      },
    ));
  }

  @override
  ActionFunc? get openComments => comicSource!.commentsLoader != null
      ? () {
          showSideBar(App.globalContext!,
              _CommentsPage(data: data!, source: comicSource!),
              title: "评论".tl);
        }
      : null;
}

class _CommentsPage extends StatefulWidget {
  const _CommentsPage({required this.data, required this.source, this.replyId});

  final ComicInfoData data;

  final ComicSource source;

  final String? replyId;

  @override
  State<_CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<_CommentsPage> {
  bool _loading = true;
  List<Comment>? _comments;
  String? _error;
  int _page = 1;
  int? maxPage;
  var controller = TextEditingController();
  bool sending = false;

  void firstLoad() async {
    var res = await widget.source.commentsLoader!(
        widget.data.comicId, widget.data.subId, 1, widget.replyId);
    if (res.error) {
      setState(() {
        _error = res.errorMessage;
        _loading = false;
      });
    } else {
      setState(() {
        _comments = res.data;
        _loading = false;
        maxPage = res.subData;
      });
    }
  }

  void loadMore() async {
    var res = await widget.source.commentsLoader!(
        widget.data.comicId, widget.data.subId, _page + 1, widget.replyId);
    if (res.error) {
      showMessage(null, res.errorMessage ?? "Unknown Error");
    } else {
      setState(() {
        _comments!.addAll(res.data);
        _page++;
        if(maxPage == null && res.data.isEmpty) {
          maxPage = _page;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      firstLoad();
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (_error != null) {
      return showNetworkError(_error!, () {
        setState(() {
          _loading = true;
        });
      }, context, showBack: false);
    } else {
      return Column(
        children: [
          Expanded(
            child: ListView.builder(
              primary: false,
              padding: EdgeInsets.zero,
              itemCount: _comments!.length + 1,
              itemBuilder: (context, index) {
                if (index == _comments!.length) {
                  if (_page < (maxPage ?? _page+1)) {
                    loadMore();
                    return const ListLoadingIndicator();
                  } else {
                    return const SizedBox();
                  }
                }

                bool enableReply = _comments![index].replyCount != null;

                return CommentTile(
                  avatarUrl: _comments![index].avatar,
                  name: _comments![index].userName,
                  time: _comments![index].time,
                  content: _comments![index].content,
                  comments: _comments![index].replyCount,
                  onTap: enableReply
                      ? () {
                    showSideBar(
                        context,
                        _CommentsPage(
                          data: widget.data,
                          source: widget.source,
                          replyId: _comments![index].id,
                        ),
                        title: "回复".tl);
                  }
                      : null,
                );
              },
            ),
          ),
          buildBottom(context)
        ],
      );
    }
  }

  Widget buildBottom(BuildContext context) {
    if(widget.source.sendCommentFunc == null){
      return const SizedBox(height: 0,);
    }
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Material(
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withAlpha(160),
                borderRadius: const BorderRadius.all(Radius.circular(30))
            ),
            child: Row(
              children: [
                Expanded(child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: "评论".tl
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                )),
                sending?const Padding(
                  padding: EdgeInsets.all(8.5),
                  child: SizedBox(width: 23,height: 23,child: CircularProgressIndicator(),),
                ):IconButton(onPressed: () async{
                  if(controller.text.isEmpty){
                    return;
                  }
                  setState(() {
                    sending = true;
                  });
                  var b = await widget.source.sendCommentFunc!(widget.data.comicId, widget.data.subId, controller.text, widget.replyId);
                  if(!b.error){
                    controller.text = "";
                    setState(() {
                      sending = false;
                      _loading = true;
                      _comments?.clear();
                      _page = 1;
                      maxPage = null;
                    });
                  }else{
                    showMessage(App.globalContext, b.errorMessageWithoutNull);
                    setState(() {
                      sending = false;
                    });
                  }
                }, icon: Icon(Icons.send, color: Theme.of(context).colorScheme.secondary,))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
