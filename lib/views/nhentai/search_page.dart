import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/search.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:get/get.dart';

import '../../base.dart';

class _SearchPageComicsList extends ComicsPage<NhentaiComicBrief>{
  final String keyword;
  final Widget? head_;
  final NhentaiSort sort;
  const _SearchPageComicsList(this.keyword, this.sort, {this.head_, super.key});

  @override
  Future<Res<List<NhentaiComicBrief>>> getComics(int i){
    return NhentaiNetwork().search(keyword, i, sort);
  }

  @override
  String? get tag => "Nhentai search $keyword ${sort.name}";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.nhentai;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;

  @override
  bool get showBackWhenLoading => true;
}

class NhentaiSearchPage extends StatefulWidget {
  final String keyword;
  const NhentaiSearchPage(this.keyword, {Key? key}) : super(key: key);

  @override
  State<NhentaiSearchPage> createState() => _NhentaiSearchPageState();
}

class _NhentaiSearchPageState extends State<NhentaiSearchPage> {
  late String keyword = widget.keyword;
  var controller = TextEditingController();
  bool _showFab = true;
  NhentaiSort sort = NhentaiSort.values[int.parse(appdata.settings[39])];

  @override
  Widget build(BuildContext context) {
    controller.text = keyword;
    return Scaffold(
      floatingActionButton: _showFab?FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: (){
          var s = controller.text;
          if(s=="") return;
          setState(() {
            keyword = s;
          });
        },
      ):null,
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          final ScrollDirection direction = notification.direction;
          var showFab = _showFab;
          if (direction == ScrollDirection.reverse) {
            _showFab = false;
          } else if (direction == ScrollDirection.forward) {
            _showFab = true;
          }
          if(_showFab == showFab) return true;
          setState(() {});
          return true;
        },
        child: _SearchPageComicsList(
          keyword,sort,
          key: Key(keyword + sort.index.toString()),
          head_: SliverPersistentHeader(
            floating: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 0,
              child: FloatingSearchBar(
                supportingText: '搜索'.tl,
                f:(s){
                  if(s=="") return;
                  setState(() {
                    keyword = s;
                  });
                },
                trailing: Tooltip(
                  message: "选择搜索模式".tl,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    onPressed: (){
                      showDialog(context: context, builder: (context){
                        return SimpleDialog(
                            title: Text("选择漫画排序模式".tl),
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 400,),
                                  ListTile(
                                    trailing: Radio<int>(value: 0,groupValue: sort.index,onChanged: (i){
                                      setState(() {
                                        sort = NhentaiSort.values[0];
                                      });
                                      appdata.settings[39] = '0';
                                      appdata.updateSettings();
                                      Get.back();
                                    },),
                                    title: Text("最新".tl),
                                    onTap: (){
                                      setState(() {
                                        sort = NhentaiSort.values[0];
                                      });
                                      appdata.settings[39] = '0';
                                      appdata.updateSettings();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 1,groupValue: sort.index,onChanged: (i){
                                      setState(() {
                                        sort = NhentaiSort.values[1];
                                      });
                                      Get.back();
                                      appdata.settings[39] = '1';
                                      appdata.updateSettings();
                                    },),
                                    title: Text("热门 | 今天".tl),
                                    onTap: (){
                                      setState(() {
                                        sort = NhentaiSort.values[1];
                                      });
                                      appdata.settings[39] = '1';
                                      appdata.updateSettings();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 2,groupValue: sort.index,onChanged: (i){
                                      setState(() {
                                        sort = NhentaiSort.values[2];
                                      });
                                      appdata.settings[39] = '2';
                                      appdata.updateSettings();
                                      Get.back();
                                    },),
                                    title: Text("热门 | 一周".tl),
                                    onTap: (){
                                      setState(() {
                                        sort = NhentaiSort.values[2];
                                      });
                                      appdata.settings[39] = '2';
                                      appdata.updateSettings();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 3,groupValue: sort.index,onChanged: (i){
                                      setState(() {
                                        sort = NhentaiSort.values[3];
                                      });
                                      appdata.settings[39] = '3';
                                      appdata.updateSettings();
                                      Get.back();
                                    },),
                                    title: Text("热门 | 本月".tl),
                                    onTap: (){
                                      setState(() {
                                        sort = NhentaiSort.values[3];
                                      });
                                      appdata.settings[39] = '3';
                                      appdata.updateSettings();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 4,groupValue: sort.index,onChanged: (i){
                                      setState(() {
                                        sort = NhentaiSort.values[4];
                                      });
                                      appdata.settings[39] = '4';
                                      appdata.updateSettings();
                                      Get.back();
                                    },),
                                    title: Text("热门 | 所有时间".tl),
                                    onTap: (){
                                      setState(() {
                                        sort = NhentaiSort.values[4];
                                      });
                                      appdata.settings[39] = '4';
                                      appdata.updateSettings();
                                      Get.back();
                                    },
                                  ),
                                ],
                              )
                            ]
                        );
                      });
                    },
                  ),
                ),
                controller: controller,),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate{
  _SliverAppBarDelegate({required this.child,required this.maxHeight,required this.minHeight});
  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child,);
  }

  @override
  double get maxExtent => minHeight;

  @override
  double get minExtent => max(maxHeight,minHeight);

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxExtent || minHeight != oldDelegate.minExtent;
  }

}