import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/models/local_favorites.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import 'package:share_plus/share_plus.dart';
import '../../base.dart';
import '../../foundation/ui_mode.dart';
import '../../network/res.dart';
import '../show_image_page.dart';
import '../widgets/animations.dart';
import '../widgets/list_loading.dart';
import '../widgets/selectable_text.dart';
import '../widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

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

class ComicPageLogic<T extends Object> extends GetxController {
  bool loading = true;
  T? data;
  String? message;
  bool showAppbarTitle = false;
  ScrollController controller = ScrollController();
  ThumbnailsData? thumbnailsData;
  double? width;
  double? height;
  bool favorite = false;

  void get(Future<Res<T>> Function() loadData, Future<bool> Function(T) loadFavorite) async {
    var res = await loadData();
    if (res.error) {
      message = res.errorMessage;
    } else {
      data = res.data;
      favorite = await loadFavorite(res.data);
    }
    loading = false;
    update();
  }

  void refresh_() {
    data = null;
    message = null;
    loading = true;
    update();
  }
}

abstract class ComicPage<T extends Object> extends StatelessWidget {
  /// comic info page, show comic's detailed information,
  /// and allow user download or read comic.
  const ComicPage({super.key});

  ComicPageLogic<T> get _logic => Get.find<ComicPageLogic<T>>(tag: tag);

  /// title
  String? get title;

  /// tags
  Map<String, List<String>>? get tags;

  /// load comic data
  Future<Res<T>> loadData();

  /// get comic data
  @nonVirtual
  T? get data => _logic.data;

  /// tag, used by Get, creating a GetxController.
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

  /// actions for comic, such as like, favorite, comment
  Row? get actions;

  FilledButton get downloadButton;

  FilledButton get readButton;

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
  BuildContext get context => Get.context!;

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

  /// callback when a thumbnail is tapped
  void onThumbnailTapped(int index){}

  void scrollListener(){
    try {
      var logic = _logic;
      bool temp = logic.showAppbarTitle;
      if (!logic.controller.hasClients) {
        return;
      }
      logic.showAppbarTitle = logic.controller.position.pixels >
          boundingTextSize(title!, const TextStyle(fontSize: 22),
              maxWidth: logic.width!)
              .height +
              50;
      if (temp != logic.showAppbarTitle) {
        logic.update();
      }
    }
    catch(e){
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints){
      return Scaffold(
        body: GetBuilder<ComicPageLogic<T>>(
          tag: tag,
          initState: (logic) {
            Get.put(ComicPageLogic<T>(), tag: tag);
          },
          builder: (logic) {
            _logic.width = constraints.maxWidth;
            _logic.height = constraints.maxHeight;
            if (logic.loading) {
              logic.get(loadData, loadFavorite);
              return showLoading(context);
            } else if (logic.message != null) {
              return showNetworkError(logic.message, logic.refresh_, context);
            } else {
              _logic.thumbnailsData ??= thumbnailsCreator;
              logic.controller.removeListener(scrollListener);
              if(UiMode.m1(context)) {
                logic.controller.addListener(scrollListener);
              }
              return CustomScrollView(
                controller: logic.controller,
                slivers: [
                  ...buildTitle(logic),
                  buildSubTitle(context),
                  buildComicInfo(logic, context),
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

  List<Widget> buildTitle(ComicPageLogic<T> logic) {
    var actions = [
      Tooltip(
        message: "分享".tl,
        child: IconButton(
          icon: const Icon(
            Icons.share,
          ),
          onPressed: () {
            Share.share(title!);
          },
        ),
      ),
      Tooltip(
        message: "复制".tl,
        child: IconButton(
          icon: const Icon(
            Icons.copy,
          ),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: title!));
          },
        ),
      ),
    ];

    if(!UiMode.m1(context)){
      return [CustomSliverAppbar(
          title: CustomSelectableText(
            text: "$title${pages == null ? "" : "(${pages}P)"}",
            style: const TextStyle(fontSize: 28),
            withAddToBlockKeywordButton: true,
          ), actions: actions, centerTitle: false
      )];
    }

    return [
      SliverAppBar(
        surfaceTintColor: logic.showAppbarTitle ? null : Colors.transparent,
        shadowColor: Colors.transparent,
        title: AnimatedOpacity(
          opacity: logic.showAppbarTitle ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text("$title${pages == null ? "" : "(${pages}P)"}"),
        ),
        pinned: true,
        actions: actions,
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 20, 10, 15),
          child: SizedBox(
            width: double.infinity,
            child: CustomSelectableText(
              text: "$title${pages == null ? "" : "(${pages}P)"}",
              style: const TextStyle(fontSize: 26),
              withAddToBlockKeywordButton: true,
            ),
          ),
        ),
      ),
    ];
  }

  Widget buildSubTitle(BuildContext context) {
    if(subTitle == null || subTitle == ""){
      return const SliverToBoxAdapter(child: SizedBox(height: 0,),);
    }
    return SliverPadding(
      padding: UiMode.m1(context) ? const EdgeInsets.fromLTRB(10, 0, 10, 8) : const EdgeInsets.fromLTRB(20, 0, 20, 8),
      sliver: SliverToBoxAdapter(child: SelectableText(subTitle!, style: const TextStyle(fontSize: 18),),),
    );
  }

  Widget buildComicInfo(ComicPageLogic<T> logic, BuildContext context) {
    if (UiMode.m1(context)) {
      return SliverToBoxAdapter(
        child: SizedBox(
          width: _logic.width! / 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //封面
              buildCover(
                  context, logic, 350, _logic.width!),

              const SizedBox(
                height: 20,
              ),

              ...buildInfoCards(logic, context),
            ],
          ),
        ),
      );
    } else {
      return SliverToBoxAdapter(
        child: SizedBox(
          width: _logic.width!,
          child: Row(
            children: [
              buildCover(
                  context, logic, 550, _logic.width! / 2),
              SizedBox(
                width: _logic.width! / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: buildInfoCards(logic, context),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget buildCover(
      BuildContext context, ComicPageLogic logic, double height, double width) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: width-32,
          height: height - 32,
          child: RoundedImage(image: CachedNetworkImageProvider(
            cover
          ),),
        ),
      ),
      onTap: () => Get.to(() => ShowImagePage(cover)),
    );
  }

  Widget buildInfoCard(String text, BuildContext context,
      {bool title = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    double size = 1;
    int values = 0;
    for (var v in tags!.values.toList()) {
      values += v.length;
    }
    if (values < 20) {
      size = size * 1.5;
    }

    if (text == "") {
      text = "未知".tl;
    }

    return GestureDetector(
      onLongPressStart: (details) {
        showMenu(
            context: Get.context!,
            position: RelativeRect.fromLTRB(
                details.globalPosition.dx,
                details.globalPosition.dy,
                details.globalPosition.dx,
                details.globalPosition.dy),
            items: [
              PopupMenuItem(
                child: Text("复制".tl),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: (text)));
                  showMessage(context, "已复制".tl);
                },
              ),
              if (!title)
                PopupMenuItem(
                  child: Text("添加到屏蔽词".tl),
                  onTap: () {
                    appdata.blockingKeyword.add(text);
                    appdata.writeData();
                  },
                ),
            ]);
      },
      child: Container(
        decoration: BoxDecoration(
            color: title
                ? colorScheme.primaryContainer
                : colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.all(Radius.circular(12))),
        margin: EdgeInsets.fromLTRB(3*size, 3*size, 3*size, 3*size),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: title ? null : () => tapOnTags(text),
          onSecondaryTapDown: (details) {
            showMenu(
                context: Get.context!,
                position: RelativeRect.fromLTRB(
                    details.globalPosition.dx,
                    details.globalPosition.dy,
                    details.globalPosition.dx,
                    details.globalPosition.dy),
                items: [
                  PopupMenuItem(
                    child: Text("复制".tl),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: (text)));
                      showMessage(context, "已复制".tl);
                    },
                  ),
                  if (!title)
                    PopupMenuItem(
                      child: Text("添加到屏蔽词".tl),
                      onTap: () {
                        appdata.blockingKeyword.add(text);
                        appdata.writeData();
                      },
                    ),
                ]);
          },
          child: Padding(
            padding:
                EdgeInsets.fromLTRB(8 * size, 5 * size, 8 * size, 5 * size),
            child: enableTranslationToCN
                ? (title
                    ? Text(text.translateTagsCategoryToCN)
                    : Text(text.translateTagsToCN))
                : Text(text),
          ),
        ),
      ),
    );
  }

  List<Widget> buildInfoCards(ComicPageLogic logic, BuildContext context) {
    var res = <Widget>[];
    var res2 = <Widget>[];

    if (buildMoreInfo != null) {
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
        child: buildMoreInfo!,
      ));
    }

    if (actions != null) {
      res2.add(Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
        child: actions,
      ));
    }

    res2.add(Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: downloadButton,
          ),
          SizedBox.fromSize(
            size: const Size(10, 1),
          ),
          Expanded(
            child: readButton,
          ),
        ],
      ),
    ));

    for (var key in tags!.keys) {
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 10, 8),
        child: Wrap(
          children: [
            buildInfoCard(key, context, title: true),
            for (var tag in tags![key]!) buildInfoCard(tag, context)
          ],
        ),
      ));
    }

    if (uploaderInfo != null) {
      res.add(Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
        child: uploaderInfo,
      ));
    }

    return !UiMode.m1(context) ? res + res2 : res2 + res;
  }

  List<Widget> buildEpisodeInfo(BuildContext context) {
    if (eps == null) return [];

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
                  width: 20,
                ),
                Icon(Icons.library_books,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  "章节".tl,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16),
                )
              ],
            )),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(childCount: eps!.eps.length,
              (context, i) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Card(
                  elevation: 1,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  margin: EdgeInsets.zero,
                  child: Center(
                    child: Text(eps!.eps[i]),
                  ),
                ),
                onTap: () => eps!.onTap(i),
              ),
            );
          }),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 250,
            childAspectRatio: 4,
          ),
        ),
      )
    ];
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
                  width: 20,
                ),
                Icon(Icons.insert_drive_file,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  "简介".tl,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16),
                )
              ],
            )),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: CustomSelectableText(text: introduction!),
        ),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
    ];
  }

  List<Widget> buildThumbnails(BuildContext context) {
    if (thumbnails == null || (thumbnails!.thumbnails.isEmpty && !tag.contains("Hitomi"))) return [];
    if(thumbnails!.thumbnails.isEmpty){
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
                  width: 20,
                ),
                Icon(Icons.remove_red_eye,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(
                  width: 20,
                ),
                const Text(
                  "预览",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
                    Expanded(child: InkWell(
                      onTap: () => onThumbnailTapped(index),
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        width: double.infinity,
                        height: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: thumbnails!.thumbnails[index],
                            httpHeaders: headers,
                            fit: BoxFit.contain,
                            placeholder: (context, s) => ColoredBox(
                                color: Theme.of(context).colorScheme.surfaceVariant),
                            errorWidget: (context, s, d) => const Icon(Icons.error),
                          ),
                        ),
                      ),
                    )),
                    const SizedBox(height: 4,),
                    Text((index+1).toString()),
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

  /// calculate title size
  Size boundingTextSize(String text, TextStyle style,
      {int maxLines = 2 ^ 31, double maxWidth = double.infinity}) {
    if (text.isEmpty) {
      return Size.zero;
    }
    final TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(text: text, style: style),
        maxLines: maxLines)
      ..layout(maxWidth: maxWidth);
    return textPainter.size;
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
                  width: 20,
                ),
                Icon(Icons.recommend,
                    color: Theme.of(context).colorScheme.secondary),
                const SizedBox(
                  width: 20,
                ),
                Text(
                  "相关推荐".tl,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 16),
                )
              ],
            )),
      ),
      const SliverPadding(padding: EdgeInsets.all(5)),
      recommendation,
    ];
  }

  void favoriteComic(FavoriteComicWidget widget) {
    if(UiMode.m1(context)){
      showModalBottomSheet(
        context: context,
        builder: (context) => widget
      );
    }else{
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
      this.favoriteOnPlatform=false,
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
    LocalFavoritesManager().find(widget.target).then((folder){
      Future.microtask(() => setState(()=>addedFolders = folder));
    });
    selectID = widget.initialFolder;
    if(!widget.havePlatformFavorite){
      page = 1;
    }
    folders = widget.folders;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.havePlatformFavorite || page!=0);

    Widget buildFolder(String name, String id, int p){
      return InkWell(
        onTap: () => setState(() {
          selectID=id;
          page=p;
        }),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(Icons.folder, size: 30, color: Theme.of(context).colorScheme.secondary,),
                const SizedBox(width: 12,),
                Text(name),
                if(addedFolders.contains(name) && p == 1)
                  const SizedBox(width: 12,),
                if(addedFolders.contains(name) && p == 1)
                Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(8))
                    ),
                    child: Center(
                      child: Text("已收藏".tl),
                    ),
                  ),
                const Spacer(),
                if(selectID == id)
                  const AnimatedCheckIcon()
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
        onPressed: (){
          Get.closeAllSnackbars();
          if(selectID != null){
            widget.setFavorite(true);
            Get.back();
            widget.selectFolderCallback?.call(selectID!, page);
          }
        },
      ),
    );

    Widget platform = SingleChildScrollView(
      child: Column(
        children: List.generate(folders.length, (index) =>
            buildFolder(folders.values.elementAt(index), folders.keys.elementAt(index), 0)),
      ),
    );

    if(widget.favoriteOnPlatform){
      platform = Center(child: Text("已收藏".tl),);
      if(page == 0) {
        button = SizedBox(
          height: 35,
          width: 120,
          child: FilledButton(
            onPressed: (){
              Get.closeAllSnackbars();
              if(addedFolders.isEmpty){
                widget.setFavorite(false);
              }
              Get.back();
              widget.cancelPlatformFavorite?.call();
            },
            child: const Text("取消收藏"),
          ),
        );
      }
    }

    if(page == 1 && addedFolders.contains(selectID)){
      button = SizedBox(
        height: 35,
        width: 120,
        child: FilledButton(
          onPressed: (){
            Get.closeAllSnackbars();
            Get.back();
            if(addedFolders.length == 1 && !widget.favoriteOnPlatform){
              widget.setFavorite(false);
            }
            LocalFavoritesManager().deleteComicWithTarget(selectID!, widget.target);
          },
          child: const Text("取消收藏"),
        ),
      );
    }

    else if(widget.havePlatformFavorite && widget.needLoadFolderData && !loadedData){
      widget.foldersLoader!.call().then((res){
        if(res.error){
          showMessage(Get.context, res.errorMessageWithoutNull);
        }else{
          setState(() {
            loadedData = true;
            folders = res.data;
          });
        }
      });
      platform =  const Center(
        child: CircularProgressIndicator(),
      );
    }

    Widget local;

    var localFolders = LocalFavoritesManager().folderNames;

    if(localFolders == null){
      LocalFavoritesManager().readData().then((value) => setState(()=>{}));
      local = const SizedBox();
    }else{
      local = SingleChildScrollView(child: Column(
        children: List.generate(localFolders.length, (index) =>
            buildFolder(localFolders[index], localFolders[index], 1)),
      ),);
    }

    return DefaultTabController(
        length: widget.havePlatformFavorite ? 2 : 1,
        child: Column(
          children: [
            TabBar(
              onTap: (i){
                setState(() {
                  if(i == 0){
                    selectID = widget.initialFolder;
                  }else{
                    selectID = null;
                  }
                  page = i;
                  if(!widget.havePlatformFavorite){
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
                  if(widget.havePlatformFavorite)
                    platform,
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

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  Widget build(BuildContext context) {
    if(image == null){
      return const SizedBox();
    }else{
      return CustomPaint(
        painter: _RoundedImagePainter(image: image!, borderRadius: 16),
        child: const SizedBox(
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
  }
  
  void _loadImage() async{
    final imageStream = widget.image.resolve(ImageConfiguration.empty);

    var listener = ImageStreamListener((imageInfo, _) {
      if(mounted) {
        setState(() {
          image = imageInfo.image;
        });
      }
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
    RRect roundedRect = RRect.fromRectAndRadius(drawRect, Radius.circular(borderRadius));
    Path clipPath = Path()..addRRect(roundedRect);

    // Clip the canvas with the rounded rectangle path
    canvas.clipPath(clipPath);

    // Draw the image within the clipped area
    Rect srcRect = Rect.fromLTRB(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, srcRect, drawRect, Paint());
  }

  @override
  bool shouldRepaint(_RoundedImagePainter oldDelegate) {
    return image != oldDelegate.image || borderRadius != oldDelegate.borderRadius;
  }
}