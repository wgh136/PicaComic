import 'package:flutter/material.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';

class EhentaiPage extends StatelessWidget {
  const EhentaiPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Column(
      children: const [
        TabBar(tabs: [
          Tab(text: "主页",),
          Tab(text: "热门",),
        ]),
        Expanded(
          child: TabBarView(
            children: [
              EhHomePage(),
              EhPopularPage(),
            ],
          ),
        )
      ],
    ));
  }
}
