import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/eh_views/category_page.dart';
import 'package:pica_comic/views/ht_views/ht_categories_page.dart';
import 'package:pica_comic/views/jm_views/detailed_categories.dart';
import 'package:pica_comic/views/nhentai/categories.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import '../base.dart';
import 'package:pica_comic/tools/translations.dart';

class AllCategoryPage extends StatefulWidget {
  const AllCategoryPage(this.pages, {Key? key}) : super(key: key);
  final int pages;
  @override
  State<AllCategoryPage> createState() => _AllCategoryPageState();
}

class _AllCategoryPageState extends State<AllCategoryPage>
    with TickerProviderStateMixin {
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: widget.pages, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: [
            if (appdata.settings[21][0] == "1")
              Tab(
                text: "Picacg".tl,
                key: const Key("Picacg分类"),
              ),
            if (appdata.settings[21][1] == "1")
              Tab(
                text: "EHentai".tl,
                key: const Key("Ehentai"),
              ),
            if (appdata.settings[21][2] == "1")
              Tab(
                text: "禁漫天堂".tl,
                key: const Key("禁漫详细分类"),
              ),
            if (appdata.settings[21][4] == "1")
              Tab(
                text: "绅士漫画".tl,
                key: const Key("绅士漫画"),
              ),
            if (appdata.settings[21][5] == "1")
              Tab(
                text: "Nhentai".tl,
                key: const Key("Nhentai"),
              ),
          ],
          controller: controller,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              if (appdata.settings[21][0] == "1") const CategoriesPage(),
              if (appdata.settings[21][1] == "1") const EhCategoryPage(),
              if (appdata.settings[21][2] == "1")
                const JmDetailedCategoriesPage(),
              if (appdata.settings[21][4] == "1") const HtCategoriesPage(),
              if (appdata.settings[21][5] == "1") const NhentaiCategories()
            ],
          ),
        )
      ],
    );
  }
}

class CategoryPageLogic extends StateController {}

class CategoryPageWithGetControl extends StatelessWidget {
  const CategoryPageWithGetControl({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<CategoryPageLogic>(builder: (logic) {
      int pages = int.parse(appdata.settings[21][0]) +
          int.parse(appdata.settings[21][1]) +
          int.parse(appdata.settings[21][2]) +
          int.parse(appdata.settings[21][4]) +
          int.parse(appdata.settings[21][5]);
      if (pages == 0) {
        return Center(
          child: Text("无数据".tl),
        );
      }
      return AllCategoryPage(pages);
    });
  }
}
