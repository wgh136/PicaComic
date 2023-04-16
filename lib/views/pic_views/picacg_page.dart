import 'package:flutter/material.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';
import '../models/tab_listener.dart';

class PicacgPage extends StatefulWidget {
  const PicacgPage(this.tabListener, {Key? key}) : super(key: key);
  final TabListener tabListener;

  @override
  State<PicacgPage> createState() => _PicacgPageState();
}

class _PicacgPageState extends State<PicacgPage> with SingleTickerProviderStateMixin{
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: 3, vsync: this);
    widget.tabListener.controller = controller;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(tabs: const [
          Tab(text: "探索",),
          Tab(text: "分类",),
          Tab(text: "游戏",),
        ], controller: controller,),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: const [
              HomePage(),
              CategoriesPage(),
              GamesPage(),
            ],
          ),
        )
      ],
    );
  }
}