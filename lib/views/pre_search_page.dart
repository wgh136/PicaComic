import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/pic_views/search_page.dart';
import 'package:pica_comic/views/widgets/custom_chips.dart';
import 'package:pica_comic/views/widgets/search.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'jm_views/jm_comic_page.dart';
import 'main_page.dart';

typedef FilterChip = CustomFilterChip;

class PreSearchController extends StateController{
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

  final searchController = StateController.put(PreSearchController());

  void search(BuildContext context, [String? s]){
    final keyword = (s ?? controller.text).trim();
    void toSearchPage(Widget Function() page){
      if(s == null){
        App.off(context, () => page());
      }else{
        App.to(context, () => page());
      }
    }
    switch(searchController.target){
      case 0: toSearchPage(()=>SearchPage(keyword));break;
      case 1: toSearchPage(()=>EhSearchPage(keyword));break;
      case 2: toSearchPage(()=>JmSearchPage(keyword));break;
      case 3: toSearchPage(()=>HitomiSearchPage(keyword));break;
      case 4: toSearchPage(()=>HtSearchPage(keyword));break;
      case 5: toSearchPage(()=>NhentaiSearchPage(keyword));break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if(UiMode.m1(context))
            SizedBox(height: MediaQuery.of(context).padding.top,),
          StateBuilder<PreSearchController>(
            builder: (logic) => FloatingSearchBar(
              onSearch:(s){
                if(s=="") return;
                search(context);
              },
              controller: controller,
              showPinnedButton: false,
              target: switch(logic.target){
                0 => ComicType.picacg,
                1 => ComicType.ehentai,
                2 => ComicType.jm,
                3 => ComicType.hitomi,
                4 => ComicType.htManga,
                5 => ComicType.nhentai,
                _ => null
              },
          ),),
          const SizedBox(height: 8,),
          buildBody(context)
        ],
      ),
    );
  }

  Widget buildBody(BuildContext context){
    return Expanded(
      child: buildMainView(context),
    );
  }

  Widget buildMainView(BuildContext context){
    final showSideBar =  MediaQuery.of(context).size.width > 900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(showSideBar)
          SizedBox(width: 250, height: double.infinity, child: buildHistorySideBar(context),),
        if(showSideBar)
          const VerticalDivider(),
        Expanded(child: SingleChildScrollView(
          padding: showSideBar ? EdgeInsets.zero : const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(showSideBar)
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: Text("搜索选项".tl),
                ),
              buildTargetSelector(context),
              buildModeSelector(context),
              buildHotSearch(context),
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
    );
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

    buildJMID(){
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          textStyle: Theme.of(context).textTheme.labelLarge,
          child: InkWell(
            onTap: () {
              var controller = TextEditingController();
              showDialog(context: context, builder: (context){
                return AlertDialog(
                  title: Text("输入禁漫漫画ID".tl),
                  content: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: controller,
                      onEditingComplete: () {
                        App.globalBack();
                        if(controller.text.isNum){
                          MainPage.to(()=>JmComicPage(controller.text));
                        }else{
                          showMessage(App.globalContext, "输入的ID不是数字".tl);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                      ],
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "ID",
                          prefix: Text("JM")
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: (){
                      App.globalBack();
                      if(controller.text.isNum){
                        MainPage.to(()=>JmComicPage(controller.text));
                      }else{
                        showMessage(App.globalContext, "输入的ID不是数字".tl);
                      }
                    }, child: Text("提交".tl))
                  ],
                );
              });
            },
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 7, 24, 7),
              child: const Text("JM ID"),
            ),
          ),
        ),
      );
    }

    return StateBuilder<PreSearchController>(builder: (logic){
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
                if(appdata.settings[21][2] == "1")
                  buildJMID(),
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

    return StateBuilder<PreSearchController>(
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

  List<Widget> buildHotSearchTags(BuildContext context){
    return [
      const SizedBox(height: 8,),
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("哔咔热搜".tl),
            Wrap(
              children: [
                for(var s in network.hotTags.getNoBlankList())
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
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        width: double.infinity,
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
      ),
      SizedBox(height: MediaQuery.of(context).padding.bottom,)
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

    return StateBuilder<PreSearchController>(
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
                        onTap: () => search(context, s),
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
    if(appdata.pinnedKeyword.isEmpty){
      return const SizedBox();
    }

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

    return StateBuilder<PreSearchController>(
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
                        onTap: () => search(context, s),
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
    return StateBuilder<PreSearchController>(builder: (logic)=>ListView.builder(
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
            onTap: () => search(context, appdata.searchHistory[appdata.searchHistory.length - index]),
          );
        }
      },
    ));
  }

  Widget buildPinnedSideBar(){
    return StateBuilder<PreSearchController>(builder: (logic) => ListView.builder(
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
            onTap: () => search(context, appdata.pinnedKeyword.elementAt(index-1)),
          );
        }
      },
    ));
  }

  Widget buildHotSearch(BuildContext context){
    return InkWell(
      onTap: () {
        showModalBottomSheet(context: context, builder: (context) =>
            buildStatefulHotSearch(context));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Row(
          children: [
            const SizedBox(width: 8,),
            Text("热搜".tl),
            const Spacer(),
            const Icon(Icons.arrow_right),
            const SizedBox(width: 8,)
          ],
        ),
      ),
    );
  }

  Widget buildStatefulHotSearch(BuildContext context){
    int loading = 2;
    String? message;
    bool flag = true;
    return StatefulBuilder(builder: (context, stateUpdater){
      if(flag) {
        flag = false;
        if (jmNetwork.hotTags.isEmpty) {
          jmNetwork.getHotTags().then((value) =>
              stateUpdater(() {
                loading--;
                if (value.error) {
                  message = value.errorMessageWithoutNull;
                }
              }));
        } else {
          loading--;
        }
        if (network.hotTags.isEmpty) {
          network.getKeyWords().then((value) =>
              stateUpdater(() {
                loading--;
                if (value.error) {
                  message = value.errorMessageWithoutNull;
                }
              }));
        } else {
          loading--;
        }
      }
      if(loading != 0){
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (message != null){
        return showNetworkError(message, () {
          stateUpdater((){
            loading = 2;
            message = null;
            flag = true;
          });
        }, context);
      } else {
        return SingleChildScrollView(
          child: Column(
            children: buildHotSearchTags(context),
          ),
        );
      }
    });
  }
}