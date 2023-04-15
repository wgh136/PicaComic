import 'package:flutter/material.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pic_views/home_page.dart';

class PicacgPage extends StatelessWidget {
  const PicacgPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Column(
      children: const [
        TabBar(tabs: [
          Tab(text: "探索",),
          Tab(text: "分类",),
          Tab(text: "游戏",),
        ]),
        Expanded(
          child: TabBarView(
            children: [
              HomePage(),
              CategoriesPage(),
              GamesPage(),
            ],
          ),
        )
      ],
    ));
  }
}
