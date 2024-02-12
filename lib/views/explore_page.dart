import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/general_interface/category.dart';
import 'package:pica_comic/views/general_interface/search.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/nhentai/nhentai_main_page.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/normal_comic_tile.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../foundation/app.dart';
import '../foundation/ui_mode.dart';
import '../network/hitomi_network/hitomi_main_network.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage(this.pages, {Key? key}) : super(key: key);
  final int pages;

  static void Function(int index)? jumpTo;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with TickerProviderStateMixin {
  late TabController controller;

  bool showFB = true;

  double location = 0;

  @override
  void initState() {
    controller = TabController(length: widget.pages, vsync: this);
    ExplorePage.jumpTo = (index) {
      controller.animateTo(index);
    };
    StateController.put(NhentaiHomePageController());
    super.initState();
  }

  void refresh() {
    int page = controller.index;
    String currentPageId = appdata.settings[77].split(',')[page];
    switch (currentPageId) {
      case "0":
        StateController.find<HomePageLogic>().refresh_();
      case "1":
        StateController.find<GamesPageLogic>().refresh_();
      case "2":
        StateController.find<EhHomePageLogic>().refresh_();
      case "3":
        StateController.find<EhPopularPageLogic>().refresh_();
      case "4":
        StateController.find<JmHomePageLogic>().refresh_();
      case "5":
        StateController.find<ComicsPageLogic>(tag: JmLatestPage.stateTag)
            .refresh_();
      case "6":
        StateController.find<HitomiHomePageLogic>(
                tag: HitomiDataUrls.homePageAll)
            .refresh_();
      case "7":
        StateController.find<NhentaiHomePageController>().refresh_();
      case "8":
        StateController.find<HtHomePageLogic>().refresh_();
      default:
        StateController.find<SimpleController>(tag: currentPageId).refresh();
    }
  }

  Widget buildFAB() => Material(
        color: Colors.transparent,
        child: FloatingActionButton(
          key: const Key("FAB"),
          onPressed: refresh,
          child: const Icon(Icons.refresh),
        ),
      );

  Widget buildTab(String i) {
    return switch (i) {
      "0" => Tab(
          text: "Picacg".tl,
          key: const Key("Picacg"),
        ),
      "1" => Tab(
          text: "Picacg游戏".tl,
          key: const Key("Picacg游戏"),
        ),
      "2" => Tab(
          text: "Eh主页".tl,
          key: const Key("Eh主页"),
        ),
      "3" => Tab(
          text: "Eh热门".tl,
          key: const Key("Eh热门"),
        ),
      "4" => Tab(text: "禁漫主页".tl, key: const Key("禁漫主页")),
      "5" => Tab(text: "禁漫最新".tl, key: const Key("禁漫最新")),
      "6" => Tab(text: "Hitomi".tl, key: const Key("Hitomi主页")),
      "7" => Tab(text: "Nhentai".tl, key: const Key("Nhentai")),
      "8" => Tab(text: "绅士漫画".tl, key: const Key("绅士漫画")),
      _ => Tab(text: i, key: Key(i)),
    };
  }

  Widget buildBody(String i) => switch (i) {
      "0" => const HomePage(),
      "1" => const GamesPage(),
      "2" => const EhHomePage(),
      "3" => const EhPopularPage(),
      "4" => const JmHomePage(),
      "5" => const JmLatestPage(),
      "6" => const HitomiHomePage(),
      "7" => const NhentaiHomePage(),
      "8" => const HtHomePage(),
      _ => _CustomExplorePage(i, key: Key(i),)
    };

  @override
  Widget build(BuildContext context) {
    bool shouldShowSwitchButton = !UiMode.m1(context) || App.isDesktop;

    Widget tabBar = TabBar(
      splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      tabs: appdata.settings[77].split(',').map((e) => buildTab(e)).toList(),
      controller: controller,
    );

    if (shouldShowSwitchButton) {
      tabBar = SizedBox(
        width: double.infinity,
        height: 50,
        child: Stack(
          children: [
            Positioned.fill(
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: tabBar,
                ),
              ),
            ),
            Positioned(
              left: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (controller.index - 1 > 0) {
                      controller.animateTo(controller.index - 1);
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 30,
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.6)),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    if (controller.index + 1 < widget.pages) {
                      controller.animateTo(controller.index + 1);
                    }
                  },
                  child: Container(
                    height: 50,
                    width: 30,
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.6)),
                    child: const Icon(
                      Icons.arrow_forward_ios_outlined,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
            child: Column(
          children: [
            tabBar,
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notifications) {
                  if (notifications.metrics.axis == Axis.horizontal) {
                    if (!showFB) {
                      setState(() {
                        showFB = true;
                      });
                    }
                    return true;
                  }

                  var current = notifications.metrics.pixels;

                  if ((current > location && current != 0) && showFB) {
                    setState(() {
                      showFB = false;
                    });
                  } else if ((current < location || current == 0) && !showFB) {
                    setState(() {
                      showFB = true;
                    });
                  }

                  location = current;
                  return true;
                },
                child: TabBarView(
                  controller: controller,
                  children: appdata.settings[77]
                      .split(',')
                      .map((e) => buildBody(e))
                      .toList(),
                ),
              ),
            )
          ],
        )),
        Positioned(
          right: 16,
          bottom: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            reverseDuration: const Duration(milliseconds: 150),
            child: showFB ? buildFAB() : const SizedBox(),
            transitionBuilder: (widget, animation) {
              var tween = Tween<Offset>(
                  begin: const Offset(0, 1), end: const Offset(0, 0));
              return SlideTransition(
                position: tween.animate(animation),
                child: widget,
              );
            },
          ),
        )
      ],
    );
  }
}

class ExplorePageLogic extends StateController {}

class ExplorePageWithGetControl extends StatelessWidget {
  const ExplorePageWithGetControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<ExplorePageLogic>(builder: (logic) {
      int pages = appdata.settings[77].split(',').length;
      return ExplorePage(
        pages,
        key: Key(appdata.settings[77]),
      );
    });
  }
}

class _CustomExplorePage extends StatefulWidget {
  const _CustomExplorePage(this.title, {super.key});

  final String title;

  @override
  State<_CustomExplorePage> createState() => _CustomExplorePageState();
}

class _CustomExplorePageState extends StateWithController<_CustomExplorePage> {
  late final ExplorePageData data;

  bool loading = true;

  String? message;

  List<ExplorePagePart>? parts;

  late final String comicSourceKey;

  @override
  void initState() {
    super.initState();
    for (var source in ComicSource.sources) {
      for (var d in source.explorePages) {
        if (d.title == widget.title) {
          data = d;
          comicSourceKey = source.key;
          return;
        }
      }
    }
    throw "Explore Page ${widget.title} Not Found!";
  }

  @override
  Widget build(BuildContext context) {
    if (data.loadMultiPart != null) {
      return buildMultiPart();
    } else if (data.loadPage != null) {
      return buildComicList();
    } else {
      return const Center(
        child: Text("Empty Page"),
      );
    }
  }

  Widget buildComicList() => _ComicList(data.loadPage!, tag.toString());

  void load() async{
    var res = await data.loadMultiPart!();
    loading = false;
    setState(() {
      if(res.error){
        message = res.errorMessageWithoutNull;
      } else {
        parts = res.data;
      }
    });
  }

  Widget buildMultiPart() {
    if(loading){
      load();
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if(message != null){
      return showNetworkError(message, refresh, context);
    } else {
      return buildPage();
    }
  }

  Widget buildPage(){
    return CustomScrollView(
      primary: false,
      slivers: _buildPage().toList(),
    );
  }

  Iterable<Widget> _buildPage() sync*{
    for(var part in parts!){
      yield buildTitle(part);
      yield buildComics(part);
    }
  }

  Widget buildTitle(ExplorePagePart part){
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
          child: Row(
            children: [
              Text(
                part.title,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if(part.viewMore != null)
              TextButton(
                  onPressed: () {
                    if(part.viewMore!.startsWith("search:")){
                      toSearchPage(comicSourceKey, part.viewMore!.replaceFirst("search:", ""));
                    } else if(part.viewMore!.startsWith("category:")){
                      toCategoryPage(comicSourceKey, part.viewMore!.replaceFirst("category:", ""), null);
                    }
                  },
                  child: Text("查看更多".tl))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildComics(ExplorePagePart part){
    return SliverGrid(delegate: SliverChildBuilderDelegate(
      (context, index){
        final item = part.comics[index];
        return NormalComicTile(
            description_: item.description,
            coverPath: item.cover,
            name: item.title,
            subTitle_: item.subTitle,
            tags: item.tags,
            onTap: onTap);
      },
      childCount: part.comics.length,
    ), gridDelegate: SliverGridDelegateWithComics());
  }

  @override
  Object? get tag => widget.title;

  @override
  void refresh() {
    if (data.loadMultiPart != null) {
      setState(() {
        loading = true;
      });
    } else if (data.loadPage != null) {
      StateController.findOrNull<ComicsPageLogic>(tag: tag.toString())?.refresh();
    }
  }

  void onTap() {
    // TODO
  }
}

class _ComicList extends ComicsPage<BaseComic> {
  const _ComicList(this.builder, this.tag);

  @override
  final String tag;

  final ComicListBuilder builder;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) {
    return builder(i);
  }

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.other;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  bool get showBackWhenError => false;

  @override
  bool get showBackWhenLoading => false;

  @override
  Widget buildItem(BuildContext context, BaseComic item) {
    return NormalComicTile(
        description_: item.description,
        coverPath: item.cover,
        name: item.title,
        subTitle_: item.subTitle,
        tags: item.tags,
        onTap: onTap);
  }

  void onTap() {
    // TODO
  }
}
