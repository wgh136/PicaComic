import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/ht_views/ht_favorites_page.dart';
import 'package:pica_comic/views/jm_views/jm_favorite_page.dart';
import 'package:pica_comic/views/nhentai/favorites_page.dart';
import 'package:pica_comic/views/pic_views/favorites_page.dart';
import '../../base.dart';
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
    controller.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildTabBar(),
        const Divider(height: 1,),
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
    );
  }

  Widget buildTabBar() {
    final folders = <String>[
      if (appdata.settings[21][0] == "1")
        "Picacg",
      if (appdata.settings[21][1] == "1")
        "EHentai",
      if (appdata.settings[21][2] == "1")
        "禁漫天堂".tl,
      if (appdata.settings[21][4] == "1")
        "绅士漫画".tl,
      if (appdata.settings[21][5] == "1")
        "Nhentai",
    ];

    Widget buildTab(int index, [bool all=false]){
      var showName = folders[index];
      bool selected = index == controller.index;
      return InkWell(
        key: Key(showName),
        borderRadius: BorderRadius.circular(8),
        splashColor: App.colors(context).primary.withOpacity(0.2),
        onTap: (){
          setState(() {});
          controller.animateTo(index);
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
                border: selected ? Border(bottom: BorderSide(color: App.colors(context).primary, width: 2)) : null
            ),
            child: Center(
              child: Text(showName, style: TextStyle(
                color: selected ? App.colors(context).primary : null,
                fontWeight: FontWeight.w600,
              ),),
            ),
          ),
        ),
      );
    }

    return Material(
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const SizedBox(width: 8,),
              for(int i=0; i<folders.length; i++)
                buildTab(i),
              const SizedBox(width: 8,),
            ],
          ),
        ),
      ),
    );
  }
}
