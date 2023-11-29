import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/ht_views/ht_favorites_page.dart';
import 'package:pica_comic/views/jm_views/jm_favorite_page.dart';
import 'package:pica_comic/views/nhentai/favorites_page.dart';
import 'package:pica_comic/views/pic_views/favorites_page.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import '../base.dart';
import 'package:pica_comic/tools/translations.dart';

class AllFavoritesPage extends StatefulWidget {
  const AllFavoritesPage({Key? key}) : super(key: key);

  @override
  State<AllFavoritesPage> createState() => _AllFavoritesPageState();
}

class _AllFavoritesPageState extends State<AllFavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController controller;
  int pages = int.parse(appdata.settings[21][0]) +
      int.parse(appdata.settings[21][1]) +
      int.parse(appdata.settings[21][2]) +
      int.parse(appdata.settings[21][4]) +
      int.parse(appdata.settings[21][5]);

  @override
  void initState() {
    controller = TabController(length: pages, vsync: this);
    StateController.put(JmFavoritePageLogic());
    StateController.put(HtFavoritePageLogic());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool showInlineTabBar = App.screenSize(context).width > 720;

    final tabBar = TabBar(
      splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
      isScrollable: MediaQuery.of(context).size.width < pages * 90,
      tabAlignment: TabAlignment.center,
      tabs: [
        if (appdata.settings[21][0] == "1")
          const Tab(
            text: "Picacg",
          ),
        if (appdata.settings[21][1] == "1")
          const Tab(
            text: "EHentai",
          ),
        if (appdata.settings[21][2] == "1")
          Tab(
            text: "禁漫天堂".tl,
          ),
        if (appdata.settings[21][4] == "1")
          Tab(
            text: "绅士漫画".tl,
          ),
        if (appdata.settings[21][5] == "1")
          const Tab(
            text: "Nhentai",
          ),
      ],
      controller: controller,
    );

    return Scaffold(
      body: Column(
        children: [
          CustomAppbar(
            title: Text("收藏夹".tl),
            actions: [
              if(showInlineTabBar)
                tabBar
            ],
          ),

          if(!showInlineTabBar)
            tabBar,

          Expanded(
            child: TabBarView(
              controller: controller,
              children: [
                if (appdata.settings[21][0] == "1") const FavoritesPage(),
                if (appdata.settings[21][1] == "1") const EhFavoritePage(),
                if (appdata.settings[21][2] == "1") const JmFavoritePage(),
                if (appdata.settings[21][4] == "1") const HtFavoritePage(),
                if (appdata.settings[21][5] == "1") const NhentaiFavoritePage(),
              ],
            ),
          )
        ],
      ),
    );
  }
}
