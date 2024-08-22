part of 'components.dart';

class ComicTileMenuOption {
  final String title;
  final IconData icon;
  final void Function(String? comicId) onTap;

  const ComicTileMenuOption(this.title, this.icon, this.onTap);
}

abstract class ComicTile extends StatelessWidget {
  /// Show a comic brief information. Usually displayed in comic list page.
  const ComicTile({Key? key}) : super(key: key);

  Widget get image;

  Widget? buildSubDescription(BuildContext context) => null;

  String get title;

  String get subTitle;

  String get description;

  String? get badge => null;

  List<String>? get tags => null;

  int get maxLines => 2;

  FavoriteItem? get favoriteItem => null;

  ActionFunc? get read => null;

  bool get enableLongPressed => true;

  int? get pages => null;

  List<ComicTileMenuOption>? get addonMenuOptions => null;

  /// Comic ID, used to identify a comic.
  String? get comicID => null;

  bool get showFavorite => true;

  void showBlockPane() {
    showDialog(
      context: App.globalContext!,
      builder: (context) => _BlockingPane(comic: this),
    );
  }

  void onLongTap_() {
    bool favorite = false;
    showDialog(
      context: App.globalContext!,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          Widget child;
          if (!favorite) {
            child = Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  key: const Key("1"),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: SelectableText(
                        title.replaceAll("\n", ""),
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.article),
                      title: Text("查看详情".tl),
                      onTap: () {
                        context.pop();
                        onTap_();
                      },
                    ),
                    if (favoriteItem != null)
                      ListTile(
                        leading: const Icon(Icons.bookmark_rounded),
                        title: Text("本地收藏".tl),
                        onTap: () {
                          setState(() {
                            favorite = true;
                          });
                        },
                      ),
                    if (read != null)
                      ListTile(
                        leading: const Icon(Icons.chrome_reader_mode),
                        title: Text("阅读".tl),
                        onTap: () {
                          context.pop();
                          read!();
                        },
                      ),
                    ListTile(
                      leading: const Icon(Icons.search),
                      title: Text("搜索".tl),
                      onTap: () {
                        context.pop();
                        context.to(() => PreSearchPage(
                              initialValue: title,
                            ));
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.block),
                      title: Text("屏蔽".tl),
                      onTap: () {
                        context.pop();
                        showBlockPane();
                      },
                    ),
                    if (addonMenuOptions != null)
                      for (var option in addonMenuOptions!)
                        ListTile(
                          leading: Icon(option.icon),
                          title: Text(option.title),
                          onTap: () => option.onTap(comicID),
                        ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
              ),
            );
          } else {
            child = buildFavoriteDialog(context);
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        });
      },
    );
  }

  Widget buildFavoriteDialog(BuildContext context) {
    String? folder = appdata.settings[51];
    int? initialFolderIndex =
        LocalFavoritesManager().folderNames.indexOf(appdata.settings[51]);
    if (initialFolderIndex == -1) {
      folder = null;
      initialFolderIndex = null;
    }
    return SimpleDialog(
      title: Text("添加收藏".tl),
      children: [
        ListTile(
          title: Text("收藏夹".tl),
          trailing: Select(
            outline: true,
            width: 156,
            values: LocalFavoritesManager().folderNames,
            initialValue: initialFolderIndex,
            onChange: (i) => folder = LocalFavoritesManager().folderNames[i],
          ),
        ),
        const SizedBox(
          height: 16,
        ),
        Center(
          child: FilledButton(
            child: const Text("确认"),
            onPressed: () {
              LocalFavoritesManager().addComic(folder!, favoriteItem!);
              context.pop();
            },
          ),
        ),
        const SizedBox(
          height: 16,
        ),
      ],
    );
  }

  void onTap_();

  void onSecondaryTap_(TapDownDetails details) {
    showDesktopMenu(App.globalContext!,
        Offset(details.globalPosition.dx, details.globalPosition.dy), [
      DesktopMenuEntry(
        text: "查看".tl,
        onClick: () => Future.microtask(onTap_),
      ),
      if (read != null)
        DesktopMenuEntry(
          text: "阅读".tl,
          onClick: () => Future.microtask(read!),
        ),
      DesktopMenuEntry(
        text: "搜索".tl,
        onClick: () => Future.microtask(
          () {
            App.mainNavigatorKey!.currentContext!.to(
              () => PreSearchPage(
                initialValue: title,
              ),
            );
          },
        ),
      ),
      DesktopMenuEntry(
        text: "本地收藏".tl,
        onClick: () => Future.microtask(() => showDialog(
            context: App.globalContext!,
            builder: (context) => buildFavoriteDialog(context))),
      ),
      DesktopMenuEntry(
        text: "屏蔽".tl,
        onClick: () => Future.microtask(showBlockPane),
      ),
      if (addonMenuOptions != null)
        for (var option in addonMenuOptions!)
          DesktopMenuEntry(
            text: option.title,
            onClick: () => option.onTap(comicID),
          ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    var type = appdata.settings[44].split(',').first;
    Widget child;
    bool detailedMode;
    if (type == "0" || type == "3") {
      detailedMode = true;
      child = _buildDetailedMode(context);
    } else {
      detailedMode = false;
      child = _buildBriefMode(context);
    }
    if (comicID == null) {
      return child;
    }

    var isFavorite = appdata.settings[72] == '1'
        ? LocalFavoritesManager().isExist(comicID!)
        : false;
    var history = appdata.settings[73] == '1'
        ? HistoryManager().findSync(comicID!)
        : null;
    if (history?.page == 0) {
      history!.page = 1;
    }

    if (!isFavorite && history == null) {
      return child;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: child,
        ),
        Positioned(
          left: detailedMode ? 16 : 6,
          top: 8,
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                if (isFavorite)
                  Container(
                    height: 24,
                    width: 24,
                    color: Colors.green,
                    child: const Icon(
                      Icons.bookmark_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                if (history != null)
                  Container(
                    height: 24,
                    color: Colors.blue.withOpacity(0.9),
                    constraints: const BoxConstraints(minWidth: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: CustomPaint(
                      painter:
                          _ReadingHistoryPainter(history.page, history.maxPage),
                    ),
                  )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDetailedMode(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      final height = constrains.maxHeight - 16;
      return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap_,
          onLongPress: enableLongPressed ? onLongTap_ : null,
          onSecondaryTapDown: onSecondaryTap_,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
            child: Row(
              children: [
                Container(
                    width: height * 0.68,
                    height: double.infinity,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.antiAlias,
                    child: image),
                SizedBox.fromSize(
                  size: const Size(16, 5),
                ),
                Expanded(
                  child: _ComicDescription(
                    //标题中不应出现换行符, 爬虫可能多爬取换行符, 为避免麻烦, 直接在此处删去
                    title: pages == null
                        ? title.replaceAll("\n", "")
                        : "[${pages}P]${title.replaceAll("\n", "")}",
                    user: subTitle,
                    description: description,
                    subDescription: buildSubDescription(context),
                    badge: badge,
                    tags: tags,
                    maxLines: maxLines,
                  ),
                ),
              ],
            ),
          ));
    });
  }

  Widget _buildBriefMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: 1,
        child: Stack(
          children: [
            Positioned.fill(
                child: Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8)),
                    clipBehavior: Clip.antiAlias,
                    child: image)),
            Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.5),
                          ]),
                      borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8))),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text(
                      title.replaceAll("\n", ""),
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap_,
                  onLongPress: enableLongPressed ? onLongTap_ : null,
                  onSecondaryTapDown: onSecondaryTap_,
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox.expand(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ComicDescription extends StatelessWidget {
  const _ComicDescription(
      {required this.title,
      required this.user,
      required this.description,
      this.subDescription,
      this.badge,
      this.maxLines = 2,
      this.tags});

  final String title;
  final String user;
  final String description;
  final Widget? subDescription;
  final String? badge;
  final List<String>? tags;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    if (tags != null) {
      tags!.removeWhere((element) => element.removeAllBlank == "");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.0,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (user != "")
          Text(
            user,
            style: const TextStyle(fontSize: 10.0),
            maxLines: 1,
          ),
        const SizedBox(
          height: 4,
        ),
        if (tags != null)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: EdgeInsets.only(bottom: constraints.maxHeight % 23),
                child: Wrap(
                  runAlignment: WrapAlignment.start,
                  clipBehavior: Clip.antiAlias,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  children: [
                    for (var s in tags!)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 4, 3),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(3, 1, 3, 3),
                          decoration: BoxDecoration(
                            color: s == "Unavailable"
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Text(
                            s,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      )
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(
          height: 2,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subDescription != null) subDescription!,
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(fontSize: 12),
                ),
              )
          ],
        )
      ],
    );
  }
}

class _ReadingHistoryPainter extends CustomPainter {
  final int page;
  final int? maxPage;

  const _ReadingHistoryPainter(this.page, this.maxPage);

  @override
  void paint(Canvas canvas, Size size) {
    if (maxPage == null) {
      // 在中央绘制page
      final textPainter = TextPainter(
        text: TextSpan(
          text: "$page",
          style: TextStyle(
            fontSize: size.width * 0.8,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset((size.width - textPainter.width) / 2,
              (size.height - textPainter.height) / 2));
    } else if (page == maxPage) {
      // 在中央绘制勾
      final paint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(size.width * 0.2, size.height * 0.5),
          Offset(size.width * 0.45, size.height * 0.75), paint);
      canvas.drawLine(Offset(size.width * 0.45, size.height * 0.75),
          Offset(size.width * 0.85, size.height * 0.3), paint);
    } else {
      // 在左上角绘制page, 在右下角绘制maxPage
      final textPainter = TextPainter(
        text: TextSpan(
          text: "$page",
          style: TextStyle(
            fontSize: size.width * 0.8,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, const Offset(0, 0));
      final textPainter2 = TextPainter(
        text: TextSpan(
          text: "/$maxPage",
          style: TextStyle(
            fontSize: size.width * 0.5,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter2.layout();
      textPainter2.paint(
          canvas,
          Offset(size.width - textPainter2.width,
              size.height - textPainter2.height));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _ReadingHistoryPainter ||
        oldDelegate.page != page ||
        oldDelegate.maxPage != maxPage;
  }
}

class NormalComicTile extends ComicTile {
  const NormalComicTile(
      {required this.description_,
      required this.coverPath,
      required this.name,
      required this.subTitle_,
      required this.onTap,
      this.onLongTap,
      this.badgeName,
      this.headers,
      this.tags,
      super.key});

  final String description_;
  final String coverPath;
  final void Function() onTap;
  final String subTitle_;
  final String name;
  final void Function()? onLongTap;
  final String? badgeName;
  final Map<String, String>? headers;

  @override
  final List<String>? tags;

  @override
  String get description => description_;

  @override
  void onLongTap_() => onLongTap?.call();

  @override
  String? get badge => badgeName;

  @override
  Widget get image => AnimatedImage(
        image: CachedImageProvider(coverPath, headers: headers),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  @override
  void onTap_() => onTap();

  @override
  String get subTitle => subTitle_;

  @override
  String get title => name;
}

class ComicTilePlaceholder extends StatelessWidget {
  const ComicTilePlaceholder({super.key, this.type = 'full'});

  final String type;

  @override
  Widget build(BuildContext context) {
    var type = appdata.settings[44].split(',').first;
    Widget child;
    if (type == "0" || type == "3") {
      child = _buildDetailedMode(context);
    } else {
      child = _buildBriefMode(context);
    }
    return child;
  }

  Widget _buildDetailedMode(BuildContext context) {
    return LayoutBuilder(builder: (context, constrains) {
      final height = constrains.maxHeight - 16;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
        child: Row(
          children: [
            Container(
              width: height * 0.68,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.colorScheme.secondaryContainer.withAlpha(140),
              ),
            ),
            SizedBox.fromSize(
              size: const Size(16, 5),
            ),
            if (type != 'full')
              const Spacer()
            else
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 3,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: context.colorScheme.tertiaryContainer
                            .withAlpha(140),
                      ),
                      height: 26,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: context.colorScheme.tertiaryContainer
                            .withAlpha(140),
                      ),
                      height: 18,
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: context.colorScheme.tertiaryContainer
                            .withAlpha(140),
                      ),
                      height: 18,
                    ),
                  ],
                ),
              ),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBriefMode(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class CustomComicTile extends ComicTile {
  const CustomComicTile(this.comic, {super.key, this.addonMenuOptions});

  final CustomComic comic;

  @override
  String get description => comic.description;

  @override
  Widget get image => AnimatedImage(
        image: StreamImageProvider(
            () =>
                ImageManager().getCustomThumbnail(comic.cover, comic.sourceKey),
            comic.id),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );

  @override
  void onTap_() {
    App.mainNavigatorKey!.currentContext!.to(() => ComicPage(
          sourceKey: comic.sourceKey,
          id: comic.id,
          cover: comic.cover,
        ));
  }

  @override
  String get subTitle => comic.subTitle;

  @override
  String get title => comic.title;

  @override
  FavoriteItem? get favoriteItem => FavoriteItem.custom(comic);

  @override
  List<String>? get tags => comic.tags;

  @override
  final List<ComicTileMenuOption>? addonMenuOptions;

  @override
  String? get comicID => comic.id;

  @override
  get read => () async {
        bool cancel = false;
        var dialog = showLoadingDialog(
          App.globalContext!,
          onCancel: () => cancel = true,
        );
        var comicSource = ComicSource.find(comic.sourceKey)!;
        var res = await comicSource.loadComicInfo!(comic.id);
        if (cancel) return;
        dialog.close();
        if (res.error) {
          showToast(message: res.errorMessage ?? "Error");
        } else {
          var history = await History.findOrCreate(res.data);
          App.globalTo(
            () => ComicReadingPage(
              CustomReadingData(
                res.data.target,
                res.data.title,
                comicSource,
                res.data.chapters,
              ),
              history.page,
              history.ep,
            ),
          );
        }
      };
}

Widget buildComicTile(BuildContext context, BaseComic item, String sourceKey) {
  var source = ComicSource.find(sourceKey);
  if (source == null) {
    throw "Comic Source Not Found";
  }
  if (!appdata.appSettings.fullyHideBlockedWorks || sourceKey == 'hitomi') {
    var blockWord = isBlocked(item);
    if (blockWord != null) {
      return Stack(
        children: [
          const Positioned.fill(
              child: ComicTilePlaceholder(
            type: '',
          )),
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${"屏蔽".tl}: $blockWord",
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
  if (source.comicTileBuilderOverride != null) {
    return source.comicTileBuilderOverride!(
      context,
      item,
      const [],
    );
  } else {
    return CustomComicTile(item as CustomComic);
  }
}

/// return the first blocked keyword, or null if not blocked
String? isBlocked(BaseComic item) {
  for (var word in appdata.blockingKeyword) {
    if (item.title.contains(word)) {
      return word;
    }
    if (item.subTitle.contains(word)) {
      return word;
    }
    if (item.description.contains(word)) {
      return word;
    }
    for (var tag in item.tags) {
      if (tag == word) {
        return word;
      }
      if (tag.contains(':')) {
        tag = tag.split(':')[1];
        if (tag == word) {
          return word;
        }
      }
      if(item.enableTagsTranslation && tag.translateTagsToCN == word) {
        return word;
      }
    }
  }
  return null;
}

class _BlockingPane extends StatefulWidget {
  const _BlockingPane({required this.comic});

  final ComicTile comic;

  @override
  State<_BlockingPane> createState() => _BlockingPaneState();
}

class _BlockingPaneState extends State<_BlockingPane> {
  var controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Appbar(title: Text("屏蔽".tl), backgroundColor: Colors.transparent,),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buildTags().toList(),
          ).paddingVertical(8),
        ).paddingHorizontal(16),
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: "屏蔽关键词".tl,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ).paddingHorizontal(16),
        const SizedBox(height: 16),
        Button.filled(onPressed: onSubmit, child: Text("提交".tl)),
        const SizedBox(height: 16),
      ],
    );

    if(context.width > 400) {
      return Dialog(
        elevation: 0,
        backgroundColor: context.colorScheme.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: content,
        ),
      );
    } else {
      return Dialog.fullscreen(
        backgroundColor: context.colorScheme.surface,
        child: content,
      );
    }
  }

  Iterable<Widget> buildTags() sync* {
    yield buildTag(widget.comic.title);
    yield buildTag(widget.comic.subTitle);
    for (var tag in widget.comic.tags ?? []) {
      yield buildTag(tag);
    }
  }

  bool _isExisted(String text) {
    if (text.contains(':')) {
      text = text.split(':')[1];
    }
    return controller.text.split(';').contains(text);
  }

  Widget buildTag(String text) {
    var isExisted = _isExisted(text);
    if (isExisted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: context.colorScheme.primaryContainer.withOpacity(0.4),
        ),
        child: Text(text),
      );
    }
    return GestureDetector(
      onTap: () => handleText(text),
      child: HoverBox(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          key: Key(text),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.colorScheme.primaryContainer,
          ),
          child: Text(text),
        ),
      ),
    );
  }

  void handleText(String text) {
    if (text.contains(':')) {
      text = text.split(':')[1];
    }
    controller.text += "$text;";
    setState(() {});
  }

  void onSubmit() {
    for (var word in controller.text.split(';')) {
      if (word.isNotEmpty && !appdata.blockingKeyword.contains(word)) {
        appdata.blockingKeyword.add(word);
      }
    }
    appdata.writeData();
    for (var c in StateController.findAll<ComicsPageLogic>()) {
      c.update();
    }
    for (var c in StateController.findAll<SliverGridComicsController>()) {
      c.update();
    }
    context.pop();
  }
}
