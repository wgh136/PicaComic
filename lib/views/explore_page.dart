import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/nhentai/nhentai_main_page.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';
import 'package:pica_comic/tools/translations.dart';
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

  void refresh(){
    int page = controller.index;
    String currentPageId = appdata.settings[59][page];
    switch(currentPageId){
      case "0": StateController.find<HomePageLogic>().refresh_();
      case "1": StateController.find<GamesPageLogic>().refresh_();
      case "2": StateController.find<EhHomePageLogic>().refresh_();
      case "3": StateController.find<EhPopularPageLogic>().refresh_();
      case "4": StateController.find<JmHomePageLogic>().refresh_();
      case "5": StateController.find<ComicsPageLogic>(tag: JmLatestPage.stateTag).refresh_();
      case "6": StateController.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageAll).refresh_();
      case "7": StateController.find<NhentaiHomePageController>().refresh_();
      case "8": StateController.find<HtHomePageLogic>().refresh_();
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

  Widget buildTab(String i){
    return switch(i){
      "0" => Tab(text: "Picacg".tl, key: const Key("Picacg"),),
      "1" => Tab(text: "Picacg游戏".tl, key: const Key("Picacg游戏"),),
      "2" => Tab(text: "Eh主页".tl, key: const Key("Eh主页"),),
      "3" => Tab(text: "Eh热门".tl, key: const Key("Eh热门"),),
      "4" => Tab(text: "禁漫主页".tl, key: const Key("禁漫主页")),
      "5" => Tab(text: "禁漫最新".tl, key: const Key("禁漫最新")),
      "6" => Tab(text: "Hitomi".tl, key: const Key("Hitomi主页")),
      "7" => Tab(text: "Nhentai".tl, key: const Key("Nhentai")),
      "8" => Tab(text: "绅士漫画".tl, key: const Key("绅士漫画")),
      _ => throw UnimplementedError()
    };
  }

  Widget buildBody(String i){
    return switch(i){
      "0" => const HomePage(),
      "1" => const GamesPage(),
      "2" => const EhHomePage(),
      "3" => const EhPopularPage(),
      "4" => const JmHomePage(),
      "5" => const JmLatestPage(),
      "6" => const HitomiHomePage(),
      "7" => const NhentaiHomePage(),
      "8" => const HtHomePage(),
      _ => throw UnimplementedError()
    };
  }

  @override
  Widget build(BuildContext context) {
    bool shouldShowSwitchButton = !UiMode.m1(context) || App.isDesktop;

    Widget tabBar = TabBar(
      splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
      isScrollable: true,
      tabAlignment: TabAlignment.center,
      tabs: [
        for(int i=0; i<appdata.settings[59].length; i++)
          buildTab(appdata.settings[59][i])
      ],
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
                  children: [
                    for(int i=0; i<appdata.settings[59].length; i++)
                      buildBody(appdata.settings[59][i])
                  ],
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
      int pages = appdata.settings[59].length;
      return ExplorePage(
        pages,
        key: Key(pages.toString()),
      );
    });
  }
}
