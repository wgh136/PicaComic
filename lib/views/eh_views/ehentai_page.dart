import 'package:flutter/material.dart';
import 'package:pica_comic/views/eh_views/eh_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import '../models/tab_listener.dart';

class EhentaiPage extends StatefulWidget {
  const EhentaiPage(this.tabListener, {Key? key}) : super(key: key);
  final TabListener tabListener;

  @override
  State<EhentaiPage> createState() => _EhentaiPageState();
}

class _EhentaiPageState extends State<EhentaiPage> with SingleTickerProviderStateMixin{
  late TabController controller;

  @override
  void initState() {
    controller = TabController(length: 2, vsync: this);
    widget.tabListener.controller = controller;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(tabs: const [
          Tab(text: "主页",),
          Tab(text: "热门",),
        ], controller: controller,),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: const [
              EhHomePage(),
              EhPopularPage(),
            ],
          ),
        )
      ],
    );
  }
}
