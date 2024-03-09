import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/foundation/history.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:share_plus/share_plus.dart';
import '../../base.dart';
import '../../foundation/app.dart';
import '../../foundation/ui_mode.dart';
import '../../network/res.dart';
import '../favorites/local_favorites.dart';
import '../show_image_page.dart';
import '../widgets/animations.dart';
import '../widgets/list_loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/foundation/stack.dart' as stack;

import 'dart:math' as math;

@immutable
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

  void get(Future<Res<T>> Function() loadData,
      Future<bool> Function(T) loadFavorite, String id) async {
    var res = await loadData();
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
    history = await HistoryManager().find(id);
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

abstract class ComicPage<T extends Object> extends StatelessWidget {
  /// comic info page, show comic's detailed information,
  /// and allow user to download or read comic.
  const ComicPage({super.key});

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

  /// tag, used by Get, creating a StateController.
  ///
  /// This should be a unique identifier,
  /// to prevent loading same data when user open more than one comic page.
  String get tag;

  /// comic total page
  ///
  /// when not null, it will be display at the end of the title.
  int? get pages;

  /// link to comic cover.
  String get cover;

  /// callback when user tap on a tag
  void tapOnTags(String tag);

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

  SliverGrid? recommendationBuilder(T data);

  /// update widget state
  @nonVirtual
  void update() => _logic.update();

  /// get context
  BuildContext get context => App.globalContext!;

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
          },
          dispose: (logic) {
            tagsStack.pop();
          },
          builder: (logic) {
            _logic.width = constraints.maxWidth;
            _logic.height = constraints.maxHeight;
            if (logic.loading) {
              logic.get(loadData, loadFavorite, id);
              return showLoading(context);
            } else if (logic.message != null) {
              return showNetworkError(logic.message, logic.refresh_, context);
            } else {
              _logic.thumbnailsData ??= thumbnailsCreator;
              logic.controller.removeListener(scrollListener);
              logic.controller.addListener(scrollListener);
              return CustomScrollView(
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
                          bottom: MediaQuery.of(context).padding.bottom))
                ],
              );
            }
          },
        ),
      );
    });
  }

  Widget buildTitle(ComicPageLogic<T> logic) {
    return SliverAppBar(
      surfaceTintColor: logic.showAppbarTitle ? null : Colors.transparent,
      shadowColor: Colors.transparent,
      scrolledUnderElevation: UiMode.m1(context) ? null : 0.0,
      title: AnimatedOpacity(
        opacity: logic.showAppbarTitle ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Text(title!),
      ),
      pinned: true,
      primary: UiMode.m1(context),
    );
  }

  Widget buildComicInfo(ComicPageLogic<T> logic, BuildContext context) {
    return SliverToBoxAdapter(
      child: LayoutBuilder(builder: (context, constrains){
        var width = constrains.maxWidth;
        var baseInfoHeight = 136.0;
        if(width > 500){
          baseInfoHeight = (baseInfoHeight * (width / 500)).clamp(136, 242);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCover(context, logic, baseInfoHeight, 142 * baseInfoHeight / 136),
                  const SizedBox(width: 8,),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: SelectableText(title!.trim(), style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(height: 8,),
                        if(subTitle != null)
                          SizedBox(
                            width: double.infinity,
                            child: Text(subTitle!, style: const TextStyle(fontSize: 14)),
                          ),
                        if(subTitle != null)
                          const SizedBox(height: 8,),
                        SizedBox(
                          width: double.infinity,
                          child: Text(source, style: const TextStyle(fontSize: 12)),
                        ),
                        if(pages != null)
                          const SizedBox(height: 8,),
                        if(pages != null)
                          SizedBox(
                            width: double.infinity,
                            child: Text("${pages}P", style: const TextStyle(fontSize: 12)),
                          ),
                        if(width >= 500)
                          buildActions(logic, context, false).paddingTop(12),
                      ],
                    ),
                  )
                ],
              ),
            ).paddingHorizontal(10).paddingBottom(12),
            if(width < 500)
              buildActions(logic, context, true).paddingHorizontal(12),
          ],
        );
      }),
    );
  }

  Widget buildCover(
      BuildContext context, ComicPageLogic logic, double height, double width) {
    if(headers["host"] == null && headers["Host"] == null){
      headers["host"] = Uri.parse(cover).host;
    }
    return GestureDetector(
      child: SizedBox(
        width: width,
        height: height,
        child: RoundedImage(
          image: CachedImageProvider(cover, headers: headers),
        ),
      ),
      onTap: () => App.globalTo(() => ShowImagePage(cover)),
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
            showMessage(context, "已复制".tl);
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

    Widget label(String text) => Text(text, style: const TextStyle(fontSize: 13));

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
          onTap: title ? null : () => tapOnTags(text),
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
            color: title ? colorScheme.primaryContainer
                : ElevationOverlay.applySurfaceTint(colorScheme.surface, colorScheme.surfaceTint, 3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            child: Padding(
              padding:
              const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: enableTranslationToCN
                  ? (title
                  ? label(text.translateTagsCategoryToCN)
                  : label(
                  TagsTranslation.translationTagWithNamespace(text, key)))
                  : label(text),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildActions(ComicPageLogic logic, BuildContext context, bool center){
    Widget buildItem(String title, IconData icon, VoidCallback onTap){
      return InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: SizedBox(
          height: 72,
          width: 64,
          child: Column(
            children: [
              const SizedBox(height: 12,),
              Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary,),
              const SizedBox(height: 8,),
              Text(title, style: const TextStyle(fontSize: 12),)
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: center ? WrapAlignment.center : WrapAlignment.start,
        children: [
          buildItem("从头开始".tl, Icons.not_started_outlined, () => read(null)),
          if(logic.history != null)
            buildItem("继续阅读".tl, Icons.menu_book, () => read(logic.history)),
          buildItem("复制".tl, Icons.copy, () {
            var text = title!;
            if(url != null){
              text += ":$url";
            }
            Clipboard.setData(ClipboardData(text: text));
            showToast(message: "已复制".tl, icon: Icons.check);
          }),
          buildItem("分享".tl, Icons.share, () {
            var text = title!;
            if(url != null){
              text += ":$url";
            }
            Share.share(text);
          }),
          buildItem("收藏".tl, Icons.collections_bookmark, openFavoritePanel),
          buildItem("下载".tl, Icons.download, download),
          if(onLike != null)
            buildItem(
                likeCount ?? "喜欢".tl,
                isLiked ? Icons.favorite : Icons.favorite_border,
                onLike!),
          if(openComments != null)
            buildItem(commentsCount ?? "评论".tl, Icons.comment, openComments!),
          if(searchSimilar != null)
            buildItem("相似".tl, Icons.search, searchSimilar!),
        ],
      ),
    );
  }

  Widget buildTags(ComicPageLogic logic, BuildContext context){
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
          const SizedBox(height: 12,),
          ...buildInfoCards(logic, context)
        ],
      ),
    );
  }

  Iterable<Widget> buildInfoCards(ComicPageLogic logic, BuildContext context) sync*{
    if (buildMoreInfo != null) {
      yield Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 30, 8),
        child: buildMoreInfo!,
      );
    }

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

  Iterable<Widget> buildEpisodeInfo(BuildContext context) sync*{
    final colorScheme = Theme.of(context).colorScheme;
    if (eps == null) return;

    yield const SliverToBoxAdapter(
      child: Divider(),
    );

    yield SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "章节".tl,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 18),
              ),
              const Spacer(),
              Tooltip(
                message: "排序".tl,
                child: IconButton(
                  icon: Icon(_logic.reverseEpsOrder ?
                  Icons.vertical_align_top :
                  Icons.vertical_align_bottom_outlined),
                  onPressed: (){
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

    if(!_logic.showFullEps){
      length = math.min(length, 20);
    }

    yield SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(childCount: length,
                (context, i) {
              if(_logic.reverseEpsOrder){
                i = eps!.eps.length - i - 1;
              }
              bool visited = (_logic.history?.readEpisode ?? const {}).contains(i + 1);
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Center(
                        child: Text(
                          eps!.eps[i],
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: visited
                                  ? colorScheme.outline
                                  : null),
                        ),
                      ),
                    ),
                  ),
                  onTap: () => eps!.onTap(i),
                ),
              );
            }),
        gridDelegate: const SliverGridDelegateWithFixedHeight(
            maxCrossAxisExtent: 200,
            itemHeight: 48
        ),
      ),
    );

    if(eps!.eps.length > 20 && !_logic.showFullEps){
      yield SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.center,
          child: FilledButton.tonal(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                  const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)))),
            ),
            onPressed: (){
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                )
              ],
            )),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
          child: CustomSelectableText(text: introduction!),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
    ];
  }

  Widget _thumbnailImageBuilder(int index) {
    return Image(
      image: CachedImageProvider(
        thumbnails!.thumbnails[index],
        headers: headers
      ),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 18),
                )
              ],
            )),
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
            )),
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
      showSideBar(context, widget, title: "收藏漫画".tl, useSurfaceTintColor: true);
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
  final void Function(String id, int type)? selectFolderCallback;

  /// initial selected folder id
  final String? initialFolder;

  /// whether this comic have been added to platform's favorite folder
  final bool favoriteOnPlatform;

  /// identifier for the comic
  final String target;

  final void Function()? cancelPlatformFavorite;

  final void Function(bool favorite) setFavorite;

  @override
  State<FavoriteComicWidget> createState() => _FavoriteComicWidgetState();
}

class _FavoriteComicWidgetState extends State<FavoriteComicWidget> {
  late String? selectID;
  late int page = 0;
  late Map<String, String> folders;
  bool loadedData = false;
  List<String> addedFolders = [];

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
                if (addedFolders.contains(name) && p == 1)
                  const SizedBox(
                    width: 12,
                  ),
                if (addedFolders.contains(name) && p == 1)
                  Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8))),
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

    Widget button = SizedBox(
      height: 35,
      width: 120,
      child: FilledButton(
        child: Text("收藏".tl),
        onPressed: () {
          hideMessage(context);
          if (selectID != null) {
            widget.setFavorite(true);
            App.globalBack();
            widget.selectFolderCallback?.call(selectID!, page);
          }
        },
      ),
    );

    Widget platform = SingleChildScrollView(
      child: Column(
        children: List.generate(
            folders.length,
            (index) => buildFolder(folders.values.elementAt(index),
                folders.keys.elementAt(index), 0)),
      ),
    );

    if (widget.favoriteOnPlatform) {
      platform = Center(
        child: Text("已收藏".tl),
      );
      if (page == 0) {
        button = SizedBox(
          height: 35,
          width: 120,
          child: FilledButton(
            onPressed: () {
              hideMessage(context);
              if (addedFolders.isEmpty) {
                widget.setFavorite(false);
              }
              App.globalBack();
              widget.cancelPlatformFavorite?.call();
            },
            child: const Text("取消收藏"),
          ),
        );
      }
    }

    if (page == 1 && addedFolders.contains(selectID)) {
      button = SizedBox(
        height: 35,
        width: 120,
        child: FilledButton(
          onPressed: () {
            hideMessage(context);
            App.globalBack();
            if (addedFolders.length == 1 && !widget.favoriteOnPlatform) {
              widget.setFavorite(false);
            }
            LocalFavoritesManager()
                .deleteComicWithTarget(selectID!, widget.target);
          },
          child: const Text("取消收藏"),
        ),
      );
    } else if (widget.havePlatformFavorite &&
        widget.needLoadFolderData &&
        !loadedData) {
      widget.foldersLoader!.call().then((res) {
        if (res.error) {
          showMessage(App.globalContext, res.errorMessageWithoutNull);
        } else {
          setState(() {
            loadedData = true;
            folders = res.data;
          });
        }
      });
      platform = const Center(
        child: CircularProgressIndicator(),
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
                ]),
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

class RoundedImage extends StatefulWidget {
  const RoundedImage({required this.image, super.key});

  final ImageProvider image;

  @override
  State<RoundedImage> createState() => _RoundedImageState();
}

class _RoundedImageState extends State<RoundedImage> {
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
      return const SizedBox(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      return CustomPaint(
        painter: _RoundedImagePainter(image: image!, borderRadius: 8),
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
      if (kDebugMode) {
        print("$error\n$stack");
      }
      setState(() {
        failed = true;
      });
    });

    imageStream.addListener(listener);
  }
}

class _RoundedImagePainter extends CustomPainter {
  final ui.Image image;
  final double borderRadius;

  _RoundedImagePainter({required this.image, required this.borderRadius});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the layout rectangle for the contained image
    double imageAspectRatio = image.width.toDouble() / image.height.toDouble();
    double containerAspectRatio = size.width / size.height;

    double drawWidth, drawHeight, xOffset, yOffset;

    if (imageAspectRatio > containerAspectRatio) {
      drawWidth = size.width;
      drawHeight = size.width / imageAspectRatio;
      xOffset = 0;
      yOffset = (size.height - drawHeight) / 2;
    } else {
      drawWidth = size.height * imageAspectRatio;
      drawHeight = size.height;
      xOffset = (size.width - drawWidth) / 2;
      yOffset = 0;
    }

    Rect drawRect = Offset(xOffset, yOffset) & Size(drawWidth, drawHeight);

    // Create a rounded rectangle path
    RRect roundedRect =
        RRect.fromRectAndRadius(drawRect, Radius.circular(borderRadius));
    Path clipPath = Path()..addRRect(roundedRect);

    // Clip the canvas with the rounded rectangle path
    canvas.clipPath(clipPath);

    // Draw the image within the clipped area
    Rect srcRect =
        Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, srcRect, drawRect, Paint());
  }

  @override
  bool shouldRepaint(_RoundedImagePainter oldDelegate) {
    return image != oldDelegate.image ||
        borderRadius != oldDelegate.borderRadius;
  }
}
