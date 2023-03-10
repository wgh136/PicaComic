import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets/search.dart';
import '../base.dart';

class HistorySearchController extends GetxController{}

class PreSearchPage extends StatelessWidget {
  PreSearchPage({Key? key}) : super(key: key);
  final controller = TextEditingController();
  final searchController = Get.put(HistorySearchController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.search),
        onPressed: (){
          Get.to(()=>SearchPage(controller.text));
        },
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 10)),
            SliverPersistentHeader(
              floating: true,
              pinned: true,
              delegate: _SliverAppBarDelegate(
                minHeight: 60,
                maxHeight: 0,
                child: FloatingSearchBar(supportingText: '搜索',f:(s){
                  if(s=="") return;
                  Get.to(()=>SearchPage(controller.text));
                },
                  controller: controller,
                  trailing: Tooltip(
                    message: "选择模式",
                    child: IconButton(
                      icon: const Icon(Icons.arrow_drop_down_rounded),
                      onPressed: (){
                        showDialog(context: context, builder: (context){
                          return SimpleDialog(
                              title: const Text("选择漫画排序模式"),
                              children: [GetBuilder<ModeRadioLogic>(
                                init: ModeRadioLogic(),
                                builder: (radioLogic){
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 400,),
                                    ListTile(
                                      trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        Get.back();
                                      },),
                                      title: const Text("新书在前"),
                                      onTap: (){
                                        radioLogic.change(0);
                                        Get.back();
                                      },
                                    ),
                                    ListTile(
                                      trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        Get.back();
                                      },),
                                      title: const Text("旧书在前"),
                                      onTap: (){
                                        radioLogic.change(1);
                                        Get.back();
                                      },
                                    ),
                                    ListTile(
                                      trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        Get.back();
                                      },),
                                      title: const Text("最多喜欢"),
                                      onTap: (){
                                        radioLogic.change(2);
                                        Get.back();
                                      },
                                    ),
                                    ListTile(
                                      trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        Get.back();
                                      },),
                                      title: const Text("最多指名"),
                                      onTap: (){
                                        radioLogic.change(3);
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
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(top: 5)),
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("  热搜"),
                    Wrap(
                      children: [
                        for(var s in hotSearch)
                          GestureDetector(
                            onTap: (){
                              Get.to(()=>SearchPage(s));
                            },
                            child: Card(
                              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              elevation: 0,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5), child: Text(s),),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            GetBuilder<HistorySearchController>(
              builder: (controller){
                return SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("  历史搜索"),
                        Wrap(
                          children: [
                            for(var s in appdata.searchHistory.reversed)
                              GestureDetector(
                                onTap: (){
                                  Get.to(()=>SearchPage(s));
                                },
                                child: Card(
                                  margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                  elevation: 0,
                                  color: Theme.of(context).colorScheme.surfaceVariant,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5), child: Text(s),),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            GetBuilder<HistorySearchController>(
              builder: (controller){
                if(appdata.searchHistory.isNotEmpty) {
                  return SliverToBoxAdapter(
                  child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 13),
                          child: InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(10),),
                            onTap: (){
                              appdata.searchHistory.clear();
                              appdata.writeData();
                              controller.update();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                  color: Theme.of(context).colorScheme.secondaryContainer
                              ),
                              width: 125,
                              height: 26,
                              child: Row(
                                children: const [
                                  SizedBox(width: 5,),
                                  Icon(Icons.clear_all,color: Colors.indigo,),
                                  Text("清除历史记录")
                                ],
                              ),
                            ),
                          ),
                        )
                      ]
                  ),
                );
                }else{
                  return const SliverPadding(padding: EdgeInsets.all(0));
                }
              },
            ),
          ],
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