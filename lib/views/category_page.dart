import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/jm_views/detailed_categories.dart';
import 'package:pica_comic/views/jm_views/jm_categories_page.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import '../base.dart';
import 'models/tab_listener.dart';

class AllCategoryPage extends StatefulWidget {
  const AllCategoryPage(this.tabListener, this.pages, {Key? key}) : super(key: key);
  final TabListener tabListener;
  final int pages;
  @override
  State<AllCategoryPage> createState() => _AllCategoryPageState();
}

class _AllCategoryPageState extends State<AllCategoryPage> with TickerProviderStateMixin{
  late TabController controller;

  @override
  Widget build(BuildContext context) {
    widget.tabListener.controller = null;
    controller = TabController(length: widget.pages, vsync: this);
    widget.tabListener.controller = controller;
    return Column(
      children: [
        TabBar(
          splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
          tabs: [
            if(appdata.settings[21][0] == "1")
              Tab(text: "Picacg分类".tr, key: const Key("Picacg分类"),),
            if(appdata.settings[21][2] == "1")
              Tab(text: "禁漫分类".tr, key: const Key("禁漫分类"),),
            if(appdata.settings[21][2] == "1")
              Tab(text: "禁漫详细分类".tr, key: const Key("禁漫详细分类"),),
          ],
          controller: controller,
        ),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              if(appdata.settings[21][0] == "1")
                const CategoriesPage(),
              if(appdata.settings[21][2] == "1")
                const JmCategoriesPage(),
              if(appdata.settings[21][2] == "1")
                const JmDetailedCategoriesPage(),
            ],
          ),
        )
      ],
    );
  }
}

class CategoryPageLogic extends GetxController{}

class CategoryPageWithGetControl extends StatelessWidget {
  const CategoryPageWithGetControl(this.listener, {Key? key}) : super(key: key);
  final TabListener listener;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryPageLogic>(builder: (logic){
      int pages = int.parse(appdata.settings[21][0])*1 + int.parse(appdata.settings[21][2])*2;
      return AllCategoryPage(listener, pages);
    });
  }
}
