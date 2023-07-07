import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/search.dart';
import '../../base.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

class ModeRadioLogic extends GetxController{
  int value = appdata.getSearchMode();
  void change(int i){
    value = i;
    appdata.setSearchMode(i);
    update();
  }
}

class SearchPageComicsList extends ComicsPage<ComicItemBrief>{
  final String keyword;
  final Widget? head_;
  const SearchPageComicsList(this.keyword, {this.head_, super.key});

  @override
  Future<Res<List<ComicItemBrief>>> getComics(int i) {
    return network.search(keyword, appdata.settings[1], i, addToHistory: true);
  }

  @override
  String? get tag => "Picacg search $keyword";

  @override
  String get title => "";

  @override
  ComicType get type => ComicType.picacg;

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  Widget? get head => head_;

  @override
  bool get showBackWhenLoading => true;
}

class SearchPage extends StatefulWidget {
  final String keyword;
  const SearchPage(this.keyword, {Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late String keyword = widget.keyword;
  var controller = TextEditingController();
  bool _showFab = true;

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
        child: SearchPageComicsList(
          keyword,
          key: Key(keyword),
          head_: SliverPersistentHeader(
            floating: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 0,
              child: FloatingSearchBar(
                supportingText: '搜索'.tr,
                trailing: Tooltip(
                  message: "选择搜索模式".tr,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    onPressed: (){
                      showDialog(context: context, builder: (context){
                        Get.put(ModeRadioLogic());
                        return SimpleDialog(
                            title: Text("选择漫画排序模式".tr),
                            children: [GetBuilder<ModeRadioLogic>(builder: (radioLogic){
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(width: 400,),
                                  ListTile(
                                    trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                                      radioLogic.change(i!);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },),
                                    title: Text("新到书".tr),
                                    onTap: (){
                                      radioLogic.change(0);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                                      radioLogic.change(i!);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },),
                                    title: Text("旧到新".tr),
                                    onTap: (){
                                      radioLogic.change(1);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                                      radioLogic.change(i!);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },),
                                    title: Text("最多喜欢".tr),
                                    onTap: (){
                                      radioLogic.change(2);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },
                                  ),
                                  ListTile(
                                    trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                                      radioLogic.change(i!);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },),
                                    title: Text("最多指名".tr),
                                    onTap: (){
                                      radioLogic.change(3);
                                      Get.find<ComicsPageLogic<ComicItemBrief>>(tag: "Picacg search $keyword").refresh_();
                                      Get.back();
                                    },
                                  ),
                                ],
                              );
                            },),]
                        );
                      });
                    },
                  ),
                ),
                f:(s){
                  if(s=="") return;
                  setState(() {
                    keyword = s;
                  });
                },
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