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


class PreSearchPage extends StatelessWidget{
  PreSearchPage({super.key});

  final controller = TextEditingController();

  final searchController = Get.put(PreSearchController());

  final FocusNode _focusNode = FocusNode();

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
    final showSideBar =  MediaQuery.of(context).size.width > 900;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: search,
        child: const Icon(Icons.search),
      ),

      body: Column(
        children: [
          if(UiMode.m1(context))
            SizedBox(height: MediaQuery.of(context).padding.top,),
          FloatingSearchBar(supportingText: '搜索'.tl,f:(s){
            if(s=="") return;
            search();
          },
            controller: controller,
            onChanged: (s) => searchController.update([1]),
            showPinnedButton: false,
            focusNode: _focusNode,
          ),
          const SizedBox(height: 8,),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(showSideBar)
                  SizedBox(width: 250, height: double.infinity, child: buildHistorySideBar(context),),
                if(showSideBar)
                const VerticalDivider(),
                Expanded(child: SingleChildScrollView(
                  padding: showSideBar ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if(showSideBar)
                        ListTile(
                          leading: const Icon(Icons.select_all),
                          title: Text("搜索选项".tl),
                        ),
                      buildSuggestions(context),
                      buildTargetSelector(context),
                      buildModeSelector(context),
                      ...buildHotSearch(context),
                      if(!showSideBar)
                        buildPinned(context),
                      if(!showSideBar)
                        buildHistory(context)
                    ],
                  ),
                )),
                if(showSideBar)
                const VerticalDivider(),
                if(showSideBar)
                  SizedBox(width: 250, height: double.infinity, child: buildPinnedSideBar(),),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildSuggestions(BuildContext context){
    return GetBuilder<PreSearchController>(builder: (logic){
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
        widget = const SizedBox(height: 0,);
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
              Text("建议".tl),
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
                          _focusNode.requestFocus();
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
    }, id: 1,);
  }

  Widget buildTargetSelector(BuildContext context){
    buildItem(PreSearchController logic, int id, String text) => Padding(
      padding: const EdgeInsets.all(5),
      child: FilterChip(
        label: Text(text),
        selected: logic.target==id,
        onSelected: (b){
          logic.updateTarget(id);
        },
      ),
    );

    return GetBuilder<PreSearchController>(builder: (logic){
      return Card(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("目标".tl),
            Wrap(
              children: [
                buildItem(logic, 0, "Picacg"),
                if(appdata.settings[21][1] == "1")
                  buildItem(logic, 1, "EHentai"),
                if(appdata.settings[21][2] == "1")
                  buildItem(logic, 2, "JM Comic"),
                if(appdata.settings[21][3] == "1")
                  buildItem(logic, 3, "Hitomi"),
                if(appdata.settings[21][4] == "1")
                  buildItem(logic, 4, "绅士漫画"),
                if(appdata.settings[21][5] == "1")
                  buildItem(logic, 5, "Nhentai"),
              ],
            )
          ],
        ),
      );
    },);
  }

  Widget buildModeSelector(BuildContext context){
    List<Widget> buildPicacg(PreSearchController logic){
      Widget buildItem(String text, int index) => Padding(
        padding: const EdgeInsets.all(5),
        child: FilterChip(
          label: Text(text),
          selected: logic.picComicsOrder == index,
          onSelected: (b) {
            logic.updatePicComicsOrder(index);
          },
        ),
      );

      return [
        buildItem("新到书".tl, 0),
        buildItem("旧到新".tl, 1),
        buildItem("最多喜欢".tl, 2),
        buildItem("最多指名".tl, 3),
      ];
    }

    List<Widget> buildJM(PreSearchController logic){
      Widget buildItem(String text, int index) => Padding(
        padding: const EdgeInsets.all(5),
        child: FilterChip(
          label: Text(text),
          selected: logic.jmComicsOrder == index,
          onSelected: (b) {
            logic.updateJmComicsOrder(index);
          },
        ),
      );

      return [
        buildItem("最新".tl, 0),
        buildItem("最多点击".tl, 1),
        buildItem("最多图片".tl, 5),
        buildItem("最多喜欢".tl, 6),
      ];
    }

    List<Widget> buildNhentai(PreSearchController logic){
      Widget buildItem(String text, int index) => Padding(
        padding: const EdgeInsets.all(5),
        child: FilterChip(
          label: Text(text),
          selected: logic.nhentaiSort.index == index,
          onSelected: (b) {
            logic.nhentaiSort = NhentaiSort.values[index];
            logic.update();
            appdata.settings[39] = index.toString();
            appdata.updateSettings();
          },
        ),
      );

      return [
        buildItem("最新".tl, 0),
        buildItem("热门 | 今天".tl, 1),
        buildItem("热门 | 一周".tl, 2),
        buildItem("热门 | 本月".tl, 3),
        buildItem("热门 | 所有时间".tl, 4),
      ];
    }

    return GetBuilder<PreSearchController>(
      builder: (logic){
        if(![0,2,5].contains(searchController.target)){
          return const SizedBox();
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("漫画排序模式".tl),
              Wrap(
                children: switch(logic.target){
                  0 => buildPicacg(logic),
                  2 => buildJM(logic),
                  5 => buildNhentai(logic),
                  _ => throw UnimplementedError()
                },
              )
            ],
          ),
        );
      },
    );
  }

  List<Widget> buildHotSearch(BuildContext context){
    return [
      Card(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("哔咔热搜".tl),
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
      Card(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("禁漫热搜".tl),
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
      )
    ];
  }

  Widget buildHistory(BuildContext context){
    buildClearButton(){
      if(appdata.searchHistory.isNotEmpty) {
        return Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(10),),
                  onTap: (){
                    appdata.searchHistory.clear();
                    appdata.writeHistory();
                    searchController.update();
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
        );
      }else{
        return const SizedBox();
      }
    }

    return GetBuilder<PreSearchController>(
      builder: (controller){
        return Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("历史搜索".tl),
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
              ),
              buildClearButton(),
            ],
          ),
        );
      },
    );
  }

  Widget buildPinned(BuildContext context){
    buildClearButton(){
      if(appdata.pinnedKeyword.isNotEmpty) {
        return Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(10),),
                  onTap: (){
                    appdata.pinnedKeyword.clear();
                    appdata.writeHistory();
                    searchController.update();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        color: Theme.of(context).colorScheme.secondaryContainer
                    ),
                    width: 75,
                    height: 28,
                    child: Row(
                      children: [
                        const SizedBox(width: 8,),
                        const Icon(Icons.clear_all,color: Colors.indigo,),
                        const SizedBox(width: 4,),
                        Text("清除".tl)
                      ],
                    ),
                  ),
                ),
              )
            ]
        );
      }else{
        return const SizedBox();
      }
    }

    return GetBuilder<PreSearchController>(
      builder: (controller){
        return Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("已固定".tl),
              Wrap(
                children: [
                  for(var s in appdata.pinnedKeyword)
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
              ),
              buildClearButton(),
            ],
          ),
        );
      },
    );
  }

  Widget buildHistorySideBar(BuildContext context){
    return GetBuilder<PreSearchController>(builder: (logic)=>ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: appdata.searchHistory.length + 1,
      itemBuilder: (context, index){
        if(index == 0){
          return ListTile(
            leading: const Icon(Icons.history_toggle_off),
            title: Text("历史搜索".tl),
            trailing: TextButton(
              onPressed: (){
                appdata.searchHistory.clear();
                appdata.writeHistory();
                searchController.update();
              },
              child: Text("清空".tl),
            ),
          );
        } else {
          return ListTile(
            title: Text(appdata.searchHistory[appdata.searchHistory.length - index]),
            onTap: () => search(appdata.searchHistory[appdata.searchHistory.length - index]),
          );
        }
      },
    ));
  }

  Widget buildPinnedSideBar(){
    return GetBuilder<PreSearchController>(builder: (logic) => ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: appdata.pinnedKeyword.length + 1,
      itemBuilder: (context, index){
        if(index == 0){
          return ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: Text("已固定".tl),
            trailing: TextButton(
              onPressed: (){
                appdata.pinnedKeyword.clear();
                appdata.writeHistory();
                searchController.update();
              },
              child: Text("清空".tl),
            ),
          );
        } else {
          return ListTile(
            title: Text(appdata.pinnedKeyword.elementAt(index-1)),
            onTap: () => search(appdata.pinnedKeyword.elementAt(index-1)),
          );
        }
      },
    ));
  }
}