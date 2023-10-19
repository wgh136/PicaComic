import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/nhentai/nhentai_main_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';
import '../foundation/ui_mode.dart';
import 'package:pica_comic/tools/translations.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage(this.pages, {Key? key}) : super(key: key);
  final int pages;

  static void Function(int index)? jumpTo;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin{
  late TabController controller;

  bool showFB = true;

  double location = 0;

  @override
  void initState() {
    controller = TabController(length: widget.pages, vsync: this);
    ExplorePage.jumpTo = (index){
      controller.animateTo(index);
    };
    Get.put(NhentaiHomePageController());
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    bool shouldShowSwitchButton = !UiMode.m1(context) || App.isDesktop;

    Widget tabBar = TabBar(
      splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
      isScrollable: true,
      tabs: [
        if(appdata.settings[24][0] == "1")
          Tab(text: "Picacg".tl, key: const Key("Picacg"),),
        if(appdata.settings[24][1] == "1")
          Tab(text: "Picacg游戏".tl, key: const Key("Picacg游戏"),),
        if(appdata.settings[24][2] == "1")
          Tab(text: "Eh主页".tl, key: const Key("Eh主页"),),
        if(appdata.settings[24][3] == "1")
          Tab(text: "Eh热门".tl, key: const Key("Eh热门"),),
        if(appdata.settings[24][4] == "1")
          Tab(text: "禁漫主页".tl, key: const Key("禁漫主页")),
        if(appdata.settings[24][5] == "1")
          Tab(text: "禁漫最新".tl, key: const Key("禁漫最新")),
        if(appdata.settings[24][6] == "1")
          Tab(text: "Hitomi".tl, key: const Key("Hitomi主页")),
        if(appdata.settings[24][7] == "1")
          Tab(text: "Nhentai".tl, key: const Key("Nhentai")),
        if(appdata.settings[24][9] == "1")
          const Tab(text: "绅士漫画", key: Key("绅士漫画")),
      ],
      controller: controller,
    );

    if(shouldShowSwitchButton){
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
                      if(controller.index - 1 >  0)  controller.animateTo(controller.index - 1);
                    },
                    child: Container(
                      height: 50,
                      width: 30,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.6)
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16,),
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
                      if(controller.index + 1 < widget.pages) {
                        controller.animateTo(controller.index + 1);
                      }
                    },
                    child: Container(
                      height: 50,
                      width: 30,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface.withOpacity(0.6)
                      ),
                      child: const Icon(Icons.arrow_forward_ios_outlined, size: 16,),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: showFB ? FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: (){
          int page = controller.index;
          var logics = [
                () => Get.find<HomePageLogic>().refresh_(),
            if(appdata.settings[24][1] == "1")
                  () => Get.find<GamesPageLogic>().refresh_(),
            if(appdata.settings[24][2] == "1")
                  () => Get.find<EhHomePageLogic>().refresh_(),
            if(appdata.settings[24][3] == "1")
                  () => Get.find<EhPopularPageLogic>().refresh_(),
            if(appdata.settings[24][4] == "1")
                  () => Get.find<JmHomePageLogic>().refresh_(),
            if(appdata.settings[24][5] == "1")
                  () => Get.find<JmLatestPageLogic>().refresh_(),
            if(appdata.settings[24][6] == "1")
                  () => HitomiHomePageComics.refresh(),
            if(appdata.settings[24][7] == "1")
                  () => Get.find<NhentaiHomePageController>().refresh_(),
            if(appdata.settings[24][9] == "1")
                  () => Get.find<HtHomePageLogic>().refresh_(),
          ];
          logics[page]();
        },
      ) : null,
      body: Column(
        children: [
          tabBar,
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notifications) {
                if(notifications.metrics.axis == Axis.horizontal){
                  if(!showFB){
                    setState(() {
                      showFB = true;
                    });
                  }
                  return true;
                }

                var current = notifications.metrics.pixels;

                if((current > location && current != 0) && showFB){
                  setState(() {
                    showFB = false;
                  });
                }else if((current < location || current == 0) && !showFB){
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
                  if(appdata.settings[24][0] == "1")
                    const HomePage(),
                  if(appdata.settings[24][1] == "1")
                    const GamesPage(),
                  if(appdata.settings[24][2] == "1")
                    const EhHomePage(),
                  if(appdata.settings[24][3] == "1")
                    const EhPopularPage(),
                  if(appdata.settings[24][4] == "1")
                    const JmHomePage(),
                  if(appdata.settings[24][5] == "1")
                    const JmLatestPage(),
                  if(appdata.settings[24][6] == "1")
                    const HitomiHomePage(),
                  if(appdata.settings[24][7] == "1")
                    const NhentaiHomePage(),
                  if(appdata.settings[24][9] == "1")
                    const HtHomePage()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ExplorePageLogic extends GetxController{}

class ExplorePageWithGetControl extends StatelessWidget {
  const ExplorePageWithGetControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExplorePageLogic>(builder: (logic){
      int pages = 0;
      for(int i=0;i<appdata.settings[24].length;i++){
        if(i == 8)  continue;
        if(appdata.settings[24][i] == "1"){
          pages++;
        }
      }
      return ExplorePage(pages, key: Key(pages.toString()),);
    });
  }
}
