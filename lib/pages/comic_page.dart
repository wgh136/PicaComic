import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/comment.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/components/select_download_eps.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/image_loader/stream_image_provider.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/foundation/stack.dart' as stack;
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/pages/favorites/local_favorites.dart';
import 'package:pica_comic/pages/reader/comic_reading_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/tools/translations.dart';
import 'show_image_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'dart:math' as math;

class ComicPage extends StatelessWidget {
  const ComicPage({
    super.key,
    required this.sourceKey,
    required this.id,
    this.cover,
  });

  final String sourceKey;

  final String id;

  final String? cover;

  @override
  Widget build(BuildContext context) {
    var comicSource = ComicSource.find(sourceKey);
    if (comicSource?.comicPageBuilder != null) {
      return comicSource!.comicPageBuilder!(context, id, cover);
    }
    return _ComicPageImpl(
      sourceKey: sourceKey,
      id: id,
      comicCover: cover,
    );
  }
}

class _ComicPageImpl extends BaseComicPage<ComicInfoData> {
  const _ComicPageImpl(
      {required this.sourceKey, required this.id, this.comicCover});

  @override
  final String sourceKey;

  @override
  final String id;

  final String? comicCover;

  @override
  String? get cover => comicCover ?? data?.cover;

  @override
  void download() async {
    final downloadId = DownloadManager().generateId(sourceKey, id);
    final eps = data!.chapters?.values.toList();
    for (var i in DownloadManager().downloading) {
      if (i.id == downloadId) {
        showToast(message: "下载中".tl);
        return;
      }
    }
    var downloaded = <int>[];
    if (DownloadManager().isExists(downloadId)) {
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
  EpsData? get eps {
    if (data!.chapters != null && data!.chapters!.isNotEmpty) {
      return EpsData(
        data!.chapters!.values.toList(),
        (ep) async {
          await History.findOrCreate(data!);
          App.globalTo(
            () => ComicReadingPage(
              CustomReadingData(
                data!.target,
                data!.title,
                ComicSource.find(sourceKey)!,
                data!.chapters,
              ),
              0,
              ep + 1,
            ),
          );
        },
      );
    }
    return null;
  }

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
    return data.isFavorite ?? false;
  }

  @override
  int? get pages => null;

  @override
  void read(History? history) async {
    history = await History.createIfNull(history, data!);
    App.globalTo(
      () => ComicReadingPage(
        CustomReadingData(
          data!.target,
          data!.title,
          ComicSource.find(sourceKey)!,
          data!.chapters,
        ),
        history!.page,
        history.ep,
      ),
    );
  }

  @override
  Widget? recommendationBuilder(ComicInfoData data) {
    if (data.suggestions == null) return null;

    return SliverGridComics(comics: data.suggestions!, sourceKey: sourceKey);
  }

  @override
  String get source => comicSource!.name;

  @override
  String get tag => "$key comic page with id: $id";

  @override
  Map<String, List<String>>? get tags => data!.tags;

  @override
  void tapOnTag(String tag, String key) {
    context.to(
      () => SearchResultPage(
        keyword: tag,
        options: const [],
        sourceKey: sourceKey,
      ),
    );
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
  Widget thumbnailImageBuilder(int index, String imageUrl) {
    return Image(
      image: StreamImageProvider(
          () => ImageManager().getCustomThumbnail(imageUrl, sourceKey),
          imageUrl),
      fit: BoxFit.contain,
      errorBuilder: (context, s, d) => const Icon(Icons.error),
    );
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
  bool? get favoriteOnPlatformInitial => data?.isFavorite;

  ComicPageLogic<ComicInfoData> get logic =>
      StateController.find<ComicPageLogic<ComicInfoData>>(tag: tag);

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
      favoriteOnPlatform: logic.favoriteOnPlatform,
      selectFolderCallback: (folder, type) async {
        if (type == 1) {
          LocalFavoritesManager().addComic(folder, toLocalFavoriteItem());
          return const Res(true);
        } else {
          var res = await comicSource!.favoriteData!.addOrDelFavorite!(
              id, folder, true);
          if (!comicSource!.favoriteData!.multiFolder && res.success) {
            logic.favoriteOnPlatform = true;
            update();
          }
          return res;
        }
      },
      cancelPlatformFavorite: () async {
        var res =
            await comicSource!.favoriteData!.addOrDelFavorite!(id, '0', false);
        if (res.success) {
          logic.favoriteOnPlatform = false;
        }
        return res;
      },
      cancelPlatformFavoriteWithFolder: (folder) {
        return comicSource!.favoriteData!.addOrDelFavorite!(id, folder, false);
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

  @override
  String get downloadedId => downloadManager.generateId(comicSource!.key, id);
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
      showToast(message: res.errorMessage ?? "Unknown Error");
    } else {
      setState(() {
        _comments!.addAll(res.data);
        _page++;
        if (maxPage == null && res.data.isEmpty) {
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
      return NetworkError(
        message: _error!,
        retry: () {
          setState(() {
            _loading = true;
          });
        },
        withAppbar: false,
      );
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
                  if (_page < (maxPage ?? _page + 1)) {
                    loadMore();
                    return const ListLoadingIndicator();
                  } else {
                    return const SizedBox();
                  }
                }

                bool enableReply = _comments![index].replyCount != null;

                return CommentTile(
                  leading: _comments![index].avatar == null
                      ? null
                      : Container(
                          width: 40,
                          height: 40,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer),
                          child: AnimatedImage(
                            image: StreamImageProvider(
                              () => ImageManager().getCustomThumbnail(
                                _comments![index].avatar!,
                                widget.data.sourceKey,
                              ),
                              _comments![index].avatar!,
                            ),
                          ),
                        ),
                  avatarUrl: null,
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
                            title: "回复".tl,
                          );
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
    if (widget.source.sendCommentFunc == null) {
      return const SizedBox(
        height: 0,
      );
    }
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Material(
          child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(160),
                borderRadius: const BorderRadius.all(Radius.circular(30))),
            child: Row(
              children: [
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        hintText: "评论".tl),
                    minLines: 1,
                    maxLines: 5,
                  ),
                )),
                sending
                    ? const Padding(
                        padding: EdgeInsets.all(8.5),
                        child: SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : IconButton(
                        onPressed: () async {
                          if (controller.text.isEmpty) {
                            return;
                          }
                          setState(() {
                            sending = true;
                          });
                          var b = await widget.source.sendCommentFunc!(
                              widget.data.comicId,
                              widget.data.subId,
                              controller.text,
                              widget.replyId);
                          if (!b.error) {
                            controller.text = "";
                            setState(() {
                              sending = false;
                              _loading = true;
                              _comments?.clear();
                              _page = 1;
                              maxPage = null;
                            });
                          } else {
                            showToast(message: b.errorMessage ?? "Error");
                            setState(() {
                              sending = false;
                            });
                          }
                        },
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EpsData {
  /// episodes text
  final List<String> eps;

  /// callback when a episode button is tapped
  final void Function(int) onTap;

  /// comic episode data
  const EpsData(this.eps, this.onTap);
}

class ThumbnailsData {
  List<String> thumbnails;
  int current = 1;
  final int maxPage;
  final Future<Res<List<String>>> Function(int page) load;

  Future<void> get(void Function() update) async {
    if (current >= maxPage) {
      return;
    }
    var res = await load(current + 1);
    if (res.success) {
      thumbnails.addAll(res.data);
      current++;
      update();
    } else {
      Log.error("Network", "Failed to load thumbnails: ${res.errorMessage}");
    }
  }

  ThumbnailsData(this.thumbnails, this.load, this.maxPage);
}

class ComicPageLogic<T extends Object> extends StateController {
  bool loading = true;
  T? data;
  String? message;
  bool showAppbarTitle = false;
  ScrollController controller = ScrollController();
  ThumbnailsData? thumbnailsData;
  double? width;
  double? height;
  bool favorite = false;
  History? history;
  bool reverseEpsOrder = false;
  bool showFullEps = false;
  int colorIndex = 0;
  bool? favoriteOnPlatform;

  void get(Future<Res<T>> Function() loadData,
      Future<bool> Function(T) loadFavorite, String Function() getId) async {
    var [res, _] = await Future.wait(
        [loadData(), Future.delayed(const Duration(milliseconds: 300))]);
    if (res.error) {
      if (res.errorMessage == "Exit") {
        return;
      }
      message = res.errorMessage;
    } else {
      data = res.data;
      favorite = await loadFavorite(res.data);
    }
    loading = false;
    history = await HistoryManager().find(getId());
    update();
  }

  void refresh_() {
    data = null;
    message = null;
    loading = true;
    update();
  }

  updateHistory(History? newHistory) {
    if (newHistory != null) {
      history = newHistory;
      update();
    }
  }
}

abstract class BaseComicPage<T extends Object> extends StatelessWidget {
  /// comic info page, show comic's detailed information,
  /// and allow user to download or read comic.
  const BaseComicPage({super.key});

  ComicPageLogic<T> get _logic =>
      StateController.find<ComicPageLogic<T>>(tag: tag);

  /// title
  String? get title;

  /// tags
  Map<String, List<String>>? get tags;

  /// load comic data
  Future<Res<T>> loadData();

  /// get comic data
  @nonVirtual
  T? get data => _logic.data;

  /// Used by StateController.
  ///
  /// This should be a unique identifier,
  /// to prevent loading same data when user open more than one comic page.
  String get tag;

  /// comic total page
  ///
  /// when not null, it will be display at the end of the title.
  int? get pages;

  /// link to comic cover.
  String? get cover;

  /// callback when user tap on a tag
  void tapOnTag(String tag, String key);

  void read(History? history);

  void download();

  void openFavoritePanel();

  ActionFunc? get openComments => null;

  String? get commentsCount => null;

  ActionFunc? get onLike => null;

  bool get isLiked => false;

  String? get likeCount => null;

  /// display uploader info
  Card? get uploaderInfo;

  /// episodes information
  EpsData? get eps;

  /// comic introduction
  String? get introduction;

  /// create thumbnails data
  ThumbnailsData? get thumbnailsCreator;

  @nonVirtual
  ThumbnailsData? get thumbnails => _logic.thumbnailsData;

  Widget? recommendationBuilder(T data);

  /// update widget state
  @nonVirtual
  void update() => _logic.update();

  /// get context
  BuildContext get context => App.mainNavigatorKey!.currentContext!;

  /// interface for building more info widget
  Widget? get buildMoreInfo => null;

  /// translation tags to CN
  bool get enableTranslationToCN => false;

  String? get subTitle => null;

  Map<String, String> get headers => {};

  @nonVirtual
  bool get favorite => _logic.favorite;

  @nonVirtual
  set favorite(bool f) => _logic.favorite = f;

  Future<bool> loadFavorite(T data);

  /// used for history
  String get id;

  /// url linked to this comic
  String? get url => null;

  /// callback when a thumbnail is tapped
  void onThumbnailTapped(int index) {}

  ActionFunc? get searchSimilar => null;

  Widget thumbnailImageBuilder(int index, String imageUrl) =>
      _thumbnailImageBuilder(index);

  /// The source of this comic, displayed at the beginning of the [title],
  /// can be translated into the user's language.
  String get source;

  FavoriteItem toLocalFavoriteItem();

  bool? get favoriteOnPlatformInitial => null;

  String get downloadedId;

  String get sourceKey;

  void scrollListener() {
    try {
      var logic = _logic;
      bool temp = logic.showAppbarTitle;
      if (!logic.controller.hasClients) {
        return;
      }
      logic.showAppbarTitle = logic.controller.position.pixels > 136;
      if (temp != logic.showAppbarTitle) {
        logic.update();
      }
    } catch (e) {
      return;
    }
  }

  static stack.Stack<ComicPageLogic> tagsStack = stack.Stack<ComicPageLogic>();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: StateBuilder<ComicPageLogic<T>>(
          tag: tag,
          init: ComicPageLogic<T>(),
          initState: (logic) {
            tagsStack.push(_logic);
            _logic.favoriteOnPlatform = favoriteOnPlatformInitial;
          },
          dispose: (logic) {
            tagsStack.pop();
          },
          builder: (logic) {
            _logic.width = constraints.maxWidth;
            _logic.height = constraints.maxHeight;
            if (logic.loading) {
              logic.get(loadData, loadFavorite, () => id);
              return buildLoading(context);
            } else if (logic.message != null) {
              return NetworkError(
                message: logic.message!,
                retry: logic.refresh_,
              );
            } else {
              _logic.thumbnailsData ??= thumbnailsCreator;
              logic.controller.removeListener(scrollListener);
              logic.controller.addListener(scrollListener);
              return SmoothCustomScrollView(
                controller: logic.controller,
                slivers: [
                  buildTitle(logic),
                  buildComicInfo(logic, context),
                  buildTags(logic, context),
                  ...buildEpisodeInfo(context),
                  ...buildIntroduction(context),
                  ...buildThumbnails(context),
                  ...buildRecommendation(context),
                  SliverPadding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom),
                  )
                ],
              );
            }
          },
        ),
      );
    });
  }

  Widget buildLoading(BuildContext context) {
    return Shimmer(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        colorOpacity: 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 56,
              child: const BackButton().toAlign(Alignment.centerLeft),
            ).paddingLeft(8),
            SizedBox(
              width: double.infinity,
              child: buildComicInfo(_logic, context, false),
            ),
            const Divider(),
            SizedBox(
              width: 100,
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                  ),
                  Text(
                    "信息".tl,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 18),
                  )
                ],
              ),
            ).paddingBottom(8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                8,
                (index) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                  child: Container(
                    width: double.infinity,
                    height: 32,
                    constraints: const BoxConstraints(maxWidth: 400),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            )
          ],
        )).paddingTop(MediaQuery.of(context).padding.top);
  }

  Widget buildTitle(ComicPageLogic<T> logic) {
    return SliverAppbar(
      title: AnimatedOpacity(
        opacity: logic.showAppbarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(title!),
      ),
      actions: [
        IconButton(
            onPressed: showMoreActions, icon: const Icon(Icons.more_horiz))
      ],
    );
  }

  void showMoreActions() {
    final width = MediaQuery.of(context).size.width;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(width, 0, 0, 0),
      items: [
        PopupMenuItem(
          child: Text("复制标题".tl),
          onTap: () {
            var text = title!;
            if (url != null) {
              text += ":$url";
            }
            Clipboard.setData(ClipboardData(text: text));
            showToast(message: "已复制".tl, icon: const Icon(Icons.check));
          },
        ),
        if (url != null)
          PopupMenuItem(
            child: Text("复制链接".tl),
            onTap: () {
              Clipboard.setData(ClipboardData(text: url!));
              showToast(message: "已复制".tl, icon: const Icon(Icons.check));
            },
          ),
        PopupMenuItem(
          child: Text("分享".tl),
          onTap: () {
            var text = title!;
            if (url != null) {
              text += ":$url";
            }
            Share.share(text);
          },
        ),
      ],
    );
  }

  Widget buildComicInfo(ComicPageLogic<T> logic, BuildContext context,
      [bool sliver = true]) {
    var body = LayoutBuilder(builder: (context, constrains) {
      var width = constrains.maxWidth;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 8,
                ),
                buildCover(context, logic, 136, 102),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SelectableText(title?.trim() ?? "",
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      if (subTitle != null)
                        SizedBox(
                          width: double.infinity,
                          child: SelectableText(subTitle!,
                              style: const TextStyle(fontSize: 14)),
                        ),
                      if (subTitle != null)
                        const SizedBox(
                          height: 8,
                        ),
                      SizedBox(
                        width: double.infinity,
                        child:
                            Text(source, style: const TextStyle(fontSize: 12)),
                      ),
                      if (pages != null)
                        const SizedBox(
                          height: 8,
                        ),
                      if (pages != null)
                        SizedBox(
                          width: double.infinity,
                          child: Text("${pages}P",
                              style: const TextStyle(fontSize: 12)),
                        ),
                      if (width >= 500)
                        buildActions(logic, context, false).paddingTop(12),
                    ],
                  ),
                )
              ],
            ),
          ).paddingHorizontal(10).paddingBottom(12),
          if (width < 500)
            buildActions(logic, context, true).paddingHorizontal(12),
        ],
      );
    });

    if (sliver == true) {
      return SliverToBoxAdapter(
        child: body,
      );
    }

    return body;
  }

  Widget buildCover(
      BuildContext context, ComicPageLogic logic, double height, double width) {
    if (cover == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    if (headers["host"] == null && headers["Host"] == null) {
      headers["host"] = Uri.parse(cover!).host;
    }
    ImageProvider image = StreamImageProvider(
        () => ImageManager().getCustomThumbnail(cover!, sourceKey), cover!);
    return GestureDetector(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Hero(
          tag: "image$tag",
          child: Image(
            image: image,
            fit: BoxFit.cover,
          ),
        ),
      ),
      onTap: () =>
          App.globalTo(() => ShowImagePageWithHero(cover!, "image$tag")),
    );
  }

  Widget buildInfoCard(String text, BuildContext context,
      {bool title = false, String key = "key"}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (text == "") {
      text = "未知".tl;
    }

    List<PopupMenuEntry<dynamic>> buildPopMenus() {
      return [
        PopupMenuItem(
          child: Text("复制".tl),
          onTap: () {
            Clipboard.setData(ClipboardData(text: (text)));
            showToast(message: "已复制".tl);
          },
        ),
        if (!title)
          PopupMenuItem(
            child: Text("屏蔽".tl),
            onTap: () {
              appdata.blockingKeyword.add(text);
              appdata.writeData();
            },
          ),
        if (!title)
          PopupMenuItem(
            child: Text("收藏".tl),
            onTap: () {
              var res = source.tlEN;
              if (source == "EHentai") {
                res += ":$key";
              }
              if (source == "Nhentai" && key == "Artists") {
                res += ":Artist";
              }
              if (text.contains(" ")) {
                res += ":\"$text\"";
              } else {
                res += ":$text";
              }
              appdata.favoriteTags.add(res);
              appdata.writeHistory();
            },
          )
      ];
    }

    Widget label(String text) =>
        Text(text, style: const TextStyle(fontSize: 13));

    if (title) {
      _logic.colorIndex++;
    }

    return GestureDetector(
      onLongPressStart: (details) {
        showMenu(
            context: App.globalContext!,
            position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy),
            items: buildPopMenus());
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: title ? null : () => tapOnTag(text, key),
          onSecondaryTapDown: (details) {
            showMenu(
                context: App.globalContext!,
                position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy),
                items: buildPopMenus());
          },
          child: Card(
            margin: EdgeInsets.zero,
            color: title
                ? Color(colors[_logic.colorIndex % colors.length])
                    .withOpacity(0.3)
                : ElevationOverlay.applySurfaceTint(
                    colorScheme.surface, colorScheme.surfaceTint, 3),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: enableTranslationToCN
                  ? (title
                      ? label(text.translateTagsCategoryToCN)
                      : label(TagsTranslation.translationTagWithNamespace(
                          text, key)))
                  : label(text),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildActions(ComicPageLogic logic, BuildContext context, bool center) {
    if (logic.loading) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        height: 72,
        width: double.infinity,
      );
    }

    Widget buildItem(String title, IconData icon, VoidCallback onTap,
        [VoidCallback? onLongPress]) {
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: SizedBox(
          height: 72,
          width: 64,
          child: Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 12),
              )
            ],
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: UiMode.m1(context)
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: center ? WrapAlignment.center : WrapAlignment.start,
            children: [
              if (width >= 500 || (width < 500 && logic.history != null))
                buildItem(
                    "从头开始".tl, Icons.not_started_outlined, () => read(null)),
              if (logic.history != null && width >= 500)
                buildItem(
                    "继续阅读".tl, Icons.menu_book, () => read(logic.history)),
              buildItem("分享".tl, Icons.share, () {
                var text = title!;
                if (url != null) {
                  text += ":$url";
                }
                Share.share(text);
              }),
              buildItem(
                  favorite ? "已收藏".tl : "收藏".tl,
                  favorite
                      ? Icons.collections_bookmark
                      : Icons.collections_bookmark_outlined,
                  openFavoritePanel, () {
                var folder = appdata.settings[51];
                if (LocalFavoritesManager().folderNames.contains(folder)) {
                  LocalFavoritesManager()
                      .addComic(folder, toLocalFavoriteItem());
                  showToast(message: "已收藏".tl);
                }
              }),
              if (width >= 500) buildItem("下载".tl, Icons.download, download),
              if (onLike != null)
                buildItem(likeCount ?? "喜欢".tl,
                    isLiked ? Icons.favorite : Icons.favorite_border, onLike!),
              if (openComments != null)
                buildItem(
                    commentsCount ?? "评论".tl, Icons.comment, openComments!),
              if (searchSimilar != null)
                buildItem("相似".tl, Icons.search, searchSimilar!),
              if (downloadManager.isExists(downloadedId))
                Flyout(
                  enableTap: true,
                  navigator: App.navigatorKey.currentState!,
                  withInkWell: true,
                  borderRadius: 8,
                  flyoutBuilder: (context) => FlyoutContent(
                    title: "是否删除下载".tl,
                    actions: [
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await downloadManager.delete([downloadedId]);
                          showToast(message: "已删除".tl);
                          logic.update();
                        },
                        child: Text("删除".tl),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("取消".tl),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 72,
                    width: 64,
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 12,
                        ),
                        Icon(
                          Icons.delete_outline,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        Text(
                          "删除下载".tl,
                          style: const TextStyle(fontSize: 12),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (width < 500)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: download,
                      child: Text("下载".tl),
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => read(_logic.history),
                      child: Text("阅读".tl),
                    ),
                  ),
                ],
              ),
            ).paddingHorizontal(8)
        ],
      ),
    );
  }

  Widget buildTags(ComicPageLogic logic, BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          SizedBox(
              width: 100,
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                  ),
                  Text(
                    "信息".tl,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 18),
                  )
                ],
              )),
          const SizedBox(
            height: 12,
          ),
          ...buildInfoCards(logic, context)
        ],
      ),
    );
  }

  Iterable<Widget> buildInfoCards(
      ComicPageLogic logic, BuildContext context) sync* {
    if (buildMoreInfo != null) {
      yield Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 30, 8),
        child: buildMoreInfo!,
      );
    }

    _logic.colorIndex = 0;

    for (var key in tags!.keys) {
      yield Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Wrap(
          children: [
            buildInfoCard(key, context, title: true),
            for (var tag in tags![key]!) buildInfoCard(tag, context, key: key)
          ],
        ),
      );
    }

    if (uploaderInfo != null) {
      yield Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 420,
            ),
            child: uploaderInfo,
          ),
        ),
      );
    }
  }

  Iterable<Widget> buildEpisodeInfo(BuildContext context) sync* {
    final colorScheme = Theme.of(context).colorScheme;
    if (eps == null) return;

    yield const SliverToBoxAdapter(
      child: Divider(),
    );

    yield SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          Text(
            "章节".tl,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          ),
          const Spacer(),
          Tooltip(
            message: "排序".tl,
            child: IconButton(
              icon: Icon(_logic.reverseEpsOrder
                  ? Icons.vertical_align_top
                  : Icons.vertical_align_bottom_outlined),
              onPressed: () {
                _logic.reverseEpsOrder = !_logic.reverseEpsOrder;
                _logic.update();
              },
            ),
          )
        ]),
      ),
    );

    yield const SliverPadding(padding: EdgeInsets.all(6));

    int length = eps!.eps.length;

    if (!_logic.showFullEps) {
      length = math.min(length, 20);
    }

    yield SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(childCount: length, (context, i) {
          if (_logic.reverseEpsOrder) {
            i = eps!.eps.length - i - 1;
          }
          bool visited =
              (_logic.history?.readEpisode ?? const {}).contains(i + 1);
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              child: Material(
                elevation: 5,
                color: colorScheme.surface,
                surfaceTintColor: colorScheme.surfaceTint,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                shadowColor: Colors.transparent,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Center(
                    child: Text(
                      eps!.eps[i],
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: visited ? colorScheme.outline : null),
                    ),
                  ),
                ),
              ),
              onTap: () => eps!.onTap(i),
            ),
          );
        }),
        gridDelegate: const SliverGridDelegateWithFixedHeight(
            maxCrossAxisExtent: 200, itemHeight: 48),
      ),
    );

    if (eps!.eps.length > 20 && !_logic.showFullEps) {
      yield SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.center,
          child: FilledButton.tonal(
            style: ButtonStyle(
              shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)))),
            ),
            onPressed: () {
              _logic.showFullEps = true;
              _logic.update();
            },
            child: Text("${"显示全部".tl} (${eps!.eps.length})"),
          ).paddingTop(12),
        ),
      );
    }
  }

  List<Widget> buildIntroduction(BuildContext context) {
    if (introduction == null) return [];

    return [
      const SliverPadding(padding: EdgeInsets.all(5)),
      const SliverToBoxAdapter(
        child: Divider(),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          width: 100,
          child: Row(
            children: [
              const SizedBox(
                width: 18,
              ),
              Text(
                "简介".tl,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              )
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: SelectableText(introduction!),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
    ];
  }

  Widget _thumbnailImageBuilder(int index) {
    return Image(
      image:
          CachedImageProvider(thumbnails!.thumbnails[index], headers: headers),
      fit: BoxFit.contain,
      errorBuilder: (context, s, d) => const Icon(Icons.error),
    );
  }

  List<Widget> buildThumbnails(BuildContext context) {
    if (thumbnails == null ||
        (thumbnails!.thumbnails.isEmpty &&
            !tag.contains("Hitomi") &&
            !tag.contains("Eh"))) return [];
    if (thumbnails!.thumbnails.isEmpty) {
      thumbnails!.get(update);
    }
    return [
      const SliverPadding(padding: EdgeInsets.all(5)),
      const SliverToBoxAdapter(
        child: Divider(),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          width: 100,
          child: Row(
            children: [
              const SizedBox(
                width: 18,
              ),
              Text(
                "预览".tl,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              )
            ],
          ),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: thumbnails!.thumbnails.length, (context, index) {
            if (index == thumbnails!.thumbnails.length - 1) {
              thumbnails!.get(update);
            }
            return Padding(
              padding: UiMode.m1(context)
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                      child: InkWell(
                    onTap: () => onThumbnailTapped(index),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      width: double.infinity,
                      height: double.infinity,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        child: thumbnailImageBuilder(
                            index, thumbnails!.thumbnails[index]),
                      ),
                    ),
                  )),
                  const SizedBox(
                    height: 4,
                  ),
                  Text((index + 1).toString()),
                ],
              ),
            );
          }),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.65,
          ),
        ),
      ),
      if (thumbnails!.current < thumbnails!.maxPage)
        const SliverToBoxAdapter(
          child: ListLoadingIndicator(),
        ),
    ];
  }

  List<Widget> buildRecommendation(BuildContext context) {
    var recommendation = recommendationBuilder(_logic.data!);
    if (recommendation == null) return [];
    return [
      const SliverToBoxAdapter(
        child: Divider(),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
            width: 100,
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                ),
                Text(
                  "相关推荐".tl,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                )
              ],
            )),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
      recommendation,
    ];
  }

  void favoriteComic(FavoriteComicWidget widget) {
    if (UiMode.m1(context)) {
      showModalBottomSheet(context: context, builder: (context) => widget);
    } else {
      showSideBar(
        App.globalContext!,
        widget,
        title: "收藏漫画".tl,
        useSurfaceTintColor: true,
      );
    }
  }
}

class FavoriteComicWidget extends StatefulWidget {
  const FavoriteComicWidget(
      {required this.havePlatformFavorite,
      required this.needLoadFolderData,
      required this.target,
      this.folders = const {},
      this.foldersLoader,
      this.selectFolderCallback,
      this.initialFolder,
      this.favoriteOnPlatform = false,
      this.cancelPlatformFavorite,
      this.cancelPlatformFavoriteWithFolder,
      required this.setFavorite,
      super.key});

  /// whether this platform has favorites feather
  final bool havePlatformFavorite;

  /// need load folder data before show folders
  final bool needLoadFolderData;

  /// initial folders, default is empty
  ///
  /// key - folder's name, value - folders id(used by callback)
  final Map<String, String> folders;

  /// load folders method
  final Future<Res<Map<String, String>>> Function()? foldersLoader;

  /// callback when user choose a folder
  ///
  /// type=0: platform, type=1:local
  final FutureOr<Res<bool>> Function(String id, int type)? selectFolderCallback;

  /// initial selected folder id
  final String? initialFolder;

  /// whether this comic have been added to platform's favorite folder
  /// if this is null, it is required to send a request to check it
  final bool? favoriteOnPlatform;

  /// identifier for the comic
  final String target;

  final Future<Res<bool>> Function()? cancelPlatformFavorite;

  final Future<Res<bool>> Function(String folder)?
      cancelPlatformFavoriteWithFolder;

  final void Function(bool favorite) setFavorite;

  @override
  State<FavoriteComicWidget> createState() => _FavoriteComicWidgetState();
}

class _FavoriteComicWidgetState extends State<FavoriteComicWidget> {
  late String? selectID;
  late int page = 0;

  /// network folders
  late Map<String, String> folders;

  /// network folders that have been added to favorite
  var favoritedFolders = <String>[];
  bool loadedData = false;
  List<String> addedFolders = [];
  bool isAdding = false;

  @override
  void initState() {
    LocalFavoritesManager().find(widget.target).then((folder) {
      Future.microtask(() => setState(() => addedFolders = folder));
    });
    selectID = widget.initialFolder;
    if (!widget.havePlatformFavorite) {
      page = 1;
    }
    folders = widget.folders;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.havePlatformFavorite || page != 0);

    Widget buildFolder(String name, String id, int p) {
      return InkWell(
        onTap: () => setState(() {
          selectID = id;
          page = p;
        }),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 30,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(name),
                if ((addedFolders.contains(name) && p == 1) ||
                    (favoritedFolders.contains(id) && p == 0))
                  const SizedBox(
                    width: 12,
                  ),
                if ((addedFolders.contains(name) && p == 1) ||
                    (favoritedFolders.contains(id) && p == 0))
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Center(
                      child: Text("已收藏".tl),
                    ),
                  ),
                const Spacer(),
                if (selectID == id) const AnimatedCheckIcon()
              ],
            ),
          ),
        ),
      );
    }

    Widget button = Button.filled(
      isLoading: isAdding,
      child: Text("收藏".tl),
      onPressed: () async {
        if (selectID != null) {
          setState(() {
            isAdding = true;
          });
          var res = await widget.selectFolderCallback!.call(selectID!, page);
          if (res.success) {
            widget.setFavorite(true);
            if (context.mounted) {
              context.pop();
            }
            showToast(message: "成功添加收藏".tl);
          } else {
            setState(() {
              isAdding = false;
            });
            showToast(message: res.errorMessage!);
          }
        }
      },
    );

    Widget platform = SingleChildScrollView(
      child: Column(
        children: List.generate(
            folders.length,
            (index) => buildFolder(folders.values.elementAt(index),
                folders.keys.elementAt(index), 0)),
      ),
    );

    if (widget.favoriteOnPlatform == true) {
      platform = Center(
        child: Text("已收藏".tl),
      );
      if (page == 0) {
        button = Button.filled(
          isLoading: isAdding,
          onPressed: () async {
            setState(() {
              isAdding = true;
            });
            var res = await widget.cancelPlatformFavorite!.call();
            if (res.success) {
              if (addedFolders.isEmpty) {
                widget.setFavorite(false);
              }
              showToast(message: "取消收藏成功".tl);
              if (context.mounted) {
                context.pop();
              }
            } else {
              setState(() {
                isAdding = false;
              });
              showToast(message: res.errorMessage!);
            }
          },
          child: Text("取消收藏".tl),
        );
      }
    }

    if (page == 1 && addedFolders.contains(selectID)) {
      button = SizedBox(
        height: 35,
        width: 120,
        child: FilledButton(
          onPressed: () {
            context.hideMessages();
            App.globalBack();
            if (addedFolders.length == 1 &&
                widget.favoriteOnPlatform == false &&
                favoritedFolders.isEmpty) {
              widget.setFavorite(false);
            }
            LocalFavoritesManager()
                .deleteComicWithTarget(selectID!, widget.target);
          },
          child: Text("取消收藏".tl),
        ),
      );
    } else if (widget.havePlatformFavorite &&
        widget.needLoadFolderData &&
        !loadedData) {
      widget.foldersLoader!.call().then((res) {
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          setState(() {
            loadedData = true;
            folders = res.data;
            favoritedFolders = res.subData ?? [];
          });
        }
      });
      platform = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (page == 0 &&
        selectID != null &&
        favoritedFolders.contains(selectID)) {
      button = SizedBox(
        height: 35,
        width: 120,
        child: FilledButton(
          onPressed: () async {
            var res = await widget.cancelPlatformFavoriteWithFolder!(selectID!);
            if (res.success) {
              showToast(message: "取消收藏成功".tl);
              if (context.mounted) {
                context.pop();
              }
            } else {
              showToast(message: res.errorMessage!);
            }
          },
          child: Text("取消收藏".tl),
        ),
      );
    }

    Widget local;

    var localFolders = LocalFavoritesManager().folderNames;

    var children = List.generate(localFolders.length,
        (index) => buildFolder(localFolders[index], localFolders[index], 1));
    children.add(SizedBox(
      height: 56,
      width: double.infinity,
      child: Center(
        child: TextButton(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("新建".tl),
              const SizedBox(
                width: 4,
              ),
              const Icon(Icons.add),
            ],
          ),
          onPressed: () => showDialog(
                  context: App.globalContext!,
                  builder: (_) => const CreateFolderDialog())
              .then((value) => setState(() {})),
        ),
      ),
    ));
    local = SingleChildScrollView(
      child: Column(
        children: children,
      ),
    );

    return DefaultTabController(
        length: widget.havePlatformFavorite ? 2 : 1,
        child: Column(
          children: [
            TabBar(
              onTap: (i) {
                setState(() {
                  if (i == 0) {
                    selectID = widget.initialFolder;
                  } else {
                    selectID = null;
                  }
                  page = i;
                  if (!widget.havePlatformFavorite) {
                    page = 1;
                  }
                });
              },
              tabs: [
                if (widget.havePlatformFavorite)
                  Tab(
                    text: "网络".tl,
                  ),
                Tab(
                  text: "本地".tl,
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  if (widget.havePlatformFavorite) platform,
                  local,
                ],
              ),
            ),
            SizedBox(
              height: 60,
              child: Center(
                child: button,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            )
          ],
        ));
  }
}
