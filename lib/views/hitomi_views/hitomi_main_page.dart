import 'package:flutter/material.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import '../models/tab_listener.dart';

class HitomiPage extends StatefulWidget {
  const HitomiPage(this.tabListener, {Key? key}) : super(key: key);
  final TabListener tabListener;

  @override
  State<HitomiPage> createState() => _HitomiPageState();
}

class _HitomiPageState extends State<HitomiPage> with SingleTickerProviderStateMixin{
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
        TabBar(
          splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
          tabs: const [
            Tab(text: "全部",),
            Tab(text: "中文",),
            Tab(text: "日文",),
          ],
          controller: controller,),
        Expanded(
          child: TabBarView(
            controller: controller,
            children: [
              HitomiHomePage(HitomiDataUrls.homePageAll),
              HitomiHomePage(HitomiDataUrls.homePageCn),
              HitomiHomePage(HitomiDataUrls.homePageJp),
            ],
          ),
        )
      ],
    );
  }
}
