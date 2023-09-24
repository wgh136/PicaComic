import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/pic_views/search_page.dart';
import 'package:pica_comic/views/widgets/custom_chips.dart';
import 'package:pica_comic/views/widgets/search.dart';
import '../base.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'main_page.dart';

typedef FilterChip = CustomFilterChip;

class PreSearchController extends GetxController{
  int target = 0;
  int picComicsOrder = appdata.getSearchMode();
  int jmComicsOrder = int.parse(appdata.settings[19]);
  NhentaiSort nhentaiSort = NhentaiSort.values[int.parse(appdata.settings[39])];

  void updateTarget(int i){
    target = i;
    update();
  }

  void updatePicComicsOrder(int i){
    picComicsOrder = i;
    appdata.setSearchMode(i);
    update();
  }

  void updateJmComicsOrder(int i){
    jmComicsOrder = i;
    appdata.settings[19] = i.toString();
    appdata.updateSettings();
    update();
  }
}

class PreSearchPage extends StatelessWidget {
  PreSearchPage({Key? key}) : super(key: key);
  final controller = TextEditingController();
  final searchController = Get.put(PreSearchController());

  void search([String? s]){
    final keyword = (s ?? controller.text).trim();
    switch(searchController.target){
      case 0: MainPage.to(()=>SearchPage(keyword));break;
      case 1: MainPage.to(()=>EhSearchPage(keyword));break;
      case 2: MainPage.to(()=>JmSearchPage(keyword));break;
      case 3: MainPage.to(()=>HitomiSearchPage(keyword));break;
      case 4: MainPage.to(()=>HtSearchPage(keyword));break;
      case 5: MainPage.to(()=>NhentaiSearchPage(keyword));break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: search,
        child: const Icon(Icons.search),
      ),
      body: CustomScrollView(
        slivers: [
          if(UiMode.m1(context))
            SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),),
          SliverPersistentHeader(
            floating: true,
            pinned: true,
            delegate: _SliverAppBarDelegate(
              minHeight: 60,
              maxHeight: 60,
              child: FloatingSearchBar(supportingText: '搜索'.tl,f:(s){
                if(s=="") return;
                search();
              },
                controller: controller,
                onChanged: (s) => searchController.update([1]),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(top: 5)),
          SliverToBoxAdapter(
            child: GetBuilder<PreSearchController>(builder: (logic){
              Widget widget;

              bool check(String text, String element){
                if(text.removeAllWhitespace == ""){
                  return false;
                }
                if(element.length >= text.length && element.substring(0, text.length) == text
                    || (element.contains(" ") && element.split(" ").last.length >= text.length
                        && element.split(" ").last.substring(0, text.length) == text)){
                  return true;
                }else if(element.translateTagsToCN.length >= text.length
                    && element.translateTagsToCN.contains(text)){
                  return true;
                }
                return false;
              }

              if(controller.text.removeAllWhitespace.isEmpty){
                widget = const SizedBox();
              }else{
                var text = controller.text.split(" ").last;
                var suggestions = <String>[];
                for (var element in TagsTranslation.enTagsTranslations.keys.toList()) {
                  if(check(text, element)){
                    suggestions.add(element);
                  }
                  if(suggestions.length > 50){
                    break;
                  }
                }
                widget = Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(padding: const EdgeInsets.only(left: 8),child: Text("建议".tl),),
                      Wrap(
                        children: [
                          for(var s in suggestions)
                            Card(
                              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              elevation: 0,
                              color: Theme.of(context).colorScheme.primaryContainer,
                              child: InkWell(
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                onTap: (){
                                  var words = controller.text.split(" ");
                                  if(words.length >= 2 && check("${words[words.length-2]} ${words[words.length-1]}", s)){
                                    controller.text = controller.text.replaceLast("${words[words.length-2]} ${words[words.length-1]}", "");
                                  }else{
                                    controller.text = controller.text.replaceLast(words[words.length-1], "");
                                  }
                                  controller.text += s += " ";
                                  logic.update([1]);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Text("$s | ${s.translateTagsToCN}"),),
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                );
              }
              return widget;
            }, id: 1,),
          ),
          SliverToBoxAdapter(
            child: GetBuilder<PreSearchController>(builder: (logic){
              return Card(
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                      child: Text("目标".tl),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: Wrap(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5),
                            child: FilterChip(
                              label: const Text("Picacg"),
                              selected: logic.target==0,
                              onSelected: (b){
                                logic.updateTarget(0);
                              },
                            ),
                          ),
                          if(appdata.settings[21][1] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("E-Hentai"),
                                selected: logic.target==1,
                                onSelected: (b){
                                  logic.updateTarget(1);
                                },
                              ),
                            ),
                          if(appdata.settings[21][2] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("JmComic"),
                                selected: logic.target==2,
                                onSelected: (b){
                                  logic.updateTarget(2);
                                },
                              ),
                            ),
                          if(appdata.settings[21][3] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("Hitomi"),
                                selected: logic.target==3,
                                onSelected: (b){
                                  logic.updateTarget(3);
                                },
                              ),
                            ),
                          if(appdata.settings[21][4] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("绅士漫画"),
                                selected: logic.target==4,
                                onSelected: (b){
                                  logic.updateTarget(4);
                                },
                              ),
                            ),
                          if(appdata.settings[21][5] == "1")
                            Padding(
                              padding: const EdgeInsets.all(5),
                              child: FilterChip(
                                label: const Text("Nhentai"),
                                selected: logic.target==5,
                                onSelected: (b){
                                  logic.updateTarget(5);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },),
          ),
          SliverToBoxAdapter(
            child: GetBuilder<PreSearchController>(
              builder: (logic){
                if(logic.target == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Card(
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                            child: Text("漫画排序模式".tl),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: Wrap(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("新到书".tl),
                                    selected: logic.picComicsOrder == 0,
                                    onSelected: (b) {
                                      logic.updatePicComicsOrder(0);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("旧到新".tl),
                                    selected: logic.picComicsOrder == 1,
                                    onSelected: (b) {
                                      logic.updatePicComicsOrder(1);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最多喜欢".tl),
                                    selected: logic.picComicsOrder == 2,
                                    onSelected: (b) {
                                      logic.updatePicComicsOrder(2);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最多指名".tl),
                                    selected: logic.picComicsOrder == 3,
                                    onSelected: (b) {
                                      logic.updatePicComicsOrder(3);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }else if(logic.target == 2){
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Card(
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                            child: Text("漫画排序模式".tl),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: Wrap(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最新".tl),
                                    selected: logic.jmComicsOrder == 0,
                                    onSelected: (b) {
                                      logic.updateJmComicsOrder(0);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最多点击".tl),
                                    selected: logic.jmComicsOrder == 1,
                                    onSelected: (b) {
                                      logic.updateJmComicsOrder(1);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最多图片".tl),
                                    selected: logic.jmComicsOrder == 5,
                                    onSelected: (b) {
                                      logic.updateJmComicsOrder(5);
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最多喜欢".tl),
                                    selected: logic.jmComicsOrder == 6,
                                    onSelected: (b) {
                                      logic.updateJmComicsOrder(6);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }else if(logic.target == 5){
                  return Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Card(
                      elevation: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(13, 5, 0, 0),
                            child: Text("漫画排序模式".tl),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                            child: Wrap(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("最新".tl),
                                    selected: logic.nhentaiSort.index == 0,
                                    onSelected: (b) {
                                      logic.nhentaiSort = NhentaiSort.recent;
                                      logic.update();
                                      appdata.settings[39] = '0';
                                      appdata.updateSettings();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("热门 | 今天".tl),
                                    selected: logic.nhentaiSort.index == 1,
                                    onSelected: (b) {
                                      logic.nhentaiSort = NhentaiSort.popularToday;
                                      logic.update();
                                      appdata.settings[39] = '1';
                                      appdata.updateSettings();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("热门 | 一周".tl),
                                    selected: logic.nhentaiSort.index == 2,
                                    onSelected: (b) {
                                      logic.nhentaiSort = NhentaiSort.popularWeek;
                                      logic.update();
                                      appdata.settings[39] = '2';
                                      appdata.updateSettings();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("热门 | 本月".tl),
                                    selected: logic.nhentaiSort.index == 3,
                                    onSelected: (b) {
                                      logic.nhentaiSort = NhentaiSort.popularMonth;
                                      logic.update();
                                      appdata.settings[39] = '3';
                                      appdata.updateSettings();
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: FilterChip(
                                    label: Text("热门 | 所有时间".tl),
                                    selected: logic.nhentaiSort.index == 4,
                                    onSelected: (b) {
                                      logic.nhentaiSort = NhentaiSort.popularAll;
                                      logic.update();
                                      appdata.settings[39] = '4';
                                      appdata.updateSettings();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return const SizedBox();
                }
              },
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
                  Text("  哔咔热搜".tl),
                  Wrap(
                    children: [
                      for(var s in hotSearch.getNoBlankList())
                        Card(
                          margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceTint.withAlpha(40),
                          child: InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(16)),
                            onTap: ()=>MainPage.to(()=>SearchPage(s)),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Text(s),),
                          ),
                        )
                    ],
                  )
                ],
              ),
            ),
          ),
          if(appdata.settings[21][2] == "1")
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(10),
                elevation: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("  禁漫热搜".tl),
                    Wrap(
                      children: [
                        for(var s in jmNetwork.hotTags.getNoBlankList())
                          Card(
                            margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                            elevation: 0,
                            color: Theme.of(context).colorScheme.surfaceTint.withAlpha(40),
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              onTap: ()=>MainPage.to(()=>JmSearchPage(s)),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Text(s),),
                            ),
                          )
                      ],
                    )
                  ],
                ),
              ),
            ),
          GetBuilder<PreSearchController>(
            builder: (controller){
              return SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("  历史搜索".tl),
                      Wrap(
                        children: [
                          for(var s in appdata.searchHistory.reversed)
                            Card(
                              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                              elevation: 0,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              child: InkWell(
                                borderRadius: const BorderRadius.all(Radius.circular(16)),
                                onTap: () => search(s),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8), child: Text(s),),
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
          GetBuilder<PreSearchController>(
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
                              appdata.writeHistory();
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
                                children: [
                                  const SizedBox(width: 5,),
                                  const Icon(Icons.clear_all,color: Colors.indigo,),
                                  Text("清除历史记录".tl)
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
      )
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