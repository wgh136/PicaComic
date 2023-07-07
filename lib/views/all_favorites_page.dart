import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/ht_views/ht_favorites_page.dart';
import 'package:pica_comic/views/jm_views/jm_favorite_page.dart';
import 'package:pica_comic/views/pic_views/favorites_page.dart';
import '../base.dart';

class AllFavoritesPage extends StatefulWidget {
  const AllFavoritesPage({Key? key}) : super(key: key);

  @override
  State<AllFavoritesPage> createState() => _AllFavoritesPageState();
}

class _AllFavoritesPageState extends State<AllFavoritesPage> with SingleTickerProviderStateMixin{
  late TabController controller;
  int pages = int.parse(appdata.settings[21][0]) + int.parse(appdata.settings[21][1]) +
      int.parse(appdata.settings[21][2]) + int.parse(appdata.settings[21][4]);

  @override
  void initState() {
    controller = TabController(length: pages, vsync: this);
    Get.put(JmFavoritePageLogic());
    super.initState();
  }

  @override
  void dispose() {
    Get.find<JmFavoritePageLogic>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("收藏夹".tr),
      ),
      body: Column(
        children: [
          TabBar(
            splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
            tabs: [
              const Tab(text: "Picacg",),
              if(appdata.settings[21][1] == "1")
                const Tab(text: "EHentai",),
              if(appdata.settings[21][2] == "1")
                const Tab(text: "JmComic",),
              if(appdata.settings[21][4] == "1")
                Tab(text: "绅士漫画".tr,),
            ],
            controller: controller,),
          Expanded(
            child: TabBarView(
              controller: controller,
              children: [
                const FavoritesPage(),
                if(appdata.settings[21][1] == "1")
                  const EhFavoritePage(),
                if(appdata.settings[21][2] == "1")
                  const JmFavoritePage(),
                if(appdata.settings[21][4] == "1")
                  const HtFavoritePage()
              ],
            ),
          )
        ],
      ),
    );
  }
}