import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';
import '../foundation/ui_mode.dart';
import 'models/tab_listener.dart';
import 'package:pica_comic/tools/translations.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage(this.tabListener, this.pages, {Key? key}) : super(key: key);
  final TabListener tabListener;
  final int pages;

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> with TickerProviderStateMixin{
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: widget.pages, vsync: this);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    widget.tabListener.controller = null;
    widget.tabListener.controller = controller;
    return Column(
      children: [
        SizedBox(
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
                    padding: EdgeInsets.symmetric(horizontal: (!UiMode.m1(context) || GetPlatform.isDesktop) ? 30 : 0),
                    child: TabBar(
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
                        if(appdata.settings[24][9] == "1")
                          const Tab(text: "绅士漫画", key: Key("绅士漫画")),
                      ],
                      controller: controller,
                    ),
                  ),
                ),
              ),
              if(!UiMode.m1(context) || GetPlatform.isDesktop)
              Positioned(
                left: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => controller.animateTo(controller.index - 1),
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
              if(!UiMode.m1(context) || GetPlatform.isDesktop)
              Positioned(
                right: 0,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => controller.animateTo(controller.index + 1),
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
        ),
        Expanded(
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
              if(appdata.settings[24][9] == "1")
                const HtHomePage()
            ],
          ),
        )
      ],
    );
  }
}

class ExplorePageLogic extends GetxController{}

class ExplorePageWithGetControl extends StatelessWidget {
  const ExplorePageWithGetControl(this.listener, {Key? key}) : super(key: key);
  final TabListener listener;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ExplorePageLogic>(builder: (logic){
      int pages = 0;
      for(int i=0;i<appdata.settings[24].length;i++){
        if(i == 7 || i == 8)  continue;
        if(appdata.settings[24][i] == "1"){
          pages++;
        }
      }
      return ExplorePage(listener, pages, key: Key(pages.toString()),);
    });
  }
}
