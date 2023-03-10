import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets/search.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';

class SearchPageLogic extends GetxController{
  var searchResult = SearchResult("", "", [], 1, 0);
  var controller = TextEditingController();
  bool isLoading = true;
  bool firstSearch = true;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void _refresh(){
    change();
    network.searchNew(searchResult.keyWord, appdata.settings[1], addToHistory: true).then((t){
      searchResult = t;
      change();
    });
  }
}

class ModeRadioLogic extends GetxController{
  int value = appdata.getSearchMod();
  void change(int i){
    value = i;
    appdata.saveSearchMode(i);
    update();
  }
}

class SearchPage extends StatelessWidget {
  final SearchPageLogic searchPageLogic = Get.put(SearchPageLogic());
  final String keyword;
  SearchPage(this.keyword,{super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.search),
          onPressed: (){
            var s = Get.find<SearchPageLogic>().controller.text;
            if(s=="") return;
            searchPageLogic.change();
            //controller.jumpTo(0);
            network.searchNew(s, appdata.settings[1],addToHistory: true).then((t){
              searchPageLogic.searchResult = t;
              searchPageLogic.change();
            });
          },
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 10)),
              SliverPersistentHeader(
                floating: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 60,
                  maxHeight: 0,
                  child: FloatingSearchBar(
                    supportingText: '??????',
                    trailing: Tooltip(
                      message: "????????????",
                      child: IconButton(
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        onPressed: (){
                          showDialog(context: context, builder: (context){
                            Get.put(ModeRadioLogic());
                            return SimpleDialog(
                                title: const Text("????????????????????????"),
                                children: [GetBuilder<ModeRadioLogic>(builder: (radioLogic){
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 400,),
                                      ListTile(
                                        trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                                          radioLogic.change(i!);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },),
                                        title: const Text("????????????"),
                                        onTap: (){
                                          radioLogic.change(0);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },
                                      ),
                                      ListTile(
                                        trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                                          radioLogic.change(i!);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },),
                                        title: const Text("????????????"),
                                        onTap: (){
                                          radioLogic.change(1);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },
                                      ),
                                      ListTile(
                                        trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                                          radioLogic.change(i!);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },),
                                        title: const Text("????????????"),
                                        onTap: (){
                                          radioLogic.change(2);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },
                                      ),
                                      ListTile(
                                        trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                                          radioLogic.change(i!);
                                          searchPageLogic._refresh();
                                          Get.back();
                                        },),
                                        title: const Text("????????????"),
                                        onTap: (){
                                          radioLogic.change(3);
                                          searchPageLogic._refresh();
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
                    searchPageLogic.change();
                    network.searchNew(s, appdata.settings[1],addToHistory: true).then((t){
                      searchPageLogic.searchResult = t;
                      searchPageLogic.change();
                    });
                  },
                    controller: searchPageLogic.controller,),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 5)),
              GetBuilder<SearchPageLogic>(builder: (searchPageLogic){
                if(searchPageLogic.isLoading){
                  if(searchPageLogic.firstSearch){
                    searchPageLogic.firstSearch = false;
                    network.searchNew(keyword, appdata.settings[1],addToHistory: true).then((t) {
                    searchPageLogic.searchResult = t;
                    searchPageLogic.controller.text = keyword;
                    searchPageLogic.change();
                    });
                  }
                return SliverToBoxAdapter(
                    child: SizedBox.fromSize(
                      size: Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height-60),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),),
                  );
                }else{
                  if(searchPageLogic.searchResult.comics.isNotEmpty){
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                          childCount: searchPageLogic.searchResult.comics.length,
                              (context, i){
                            if(i == searchPageLogic.searchResult.comics.length-1){
                              network.loadMoreSearch(searchPageLogic.searchResult).then((c){
                                searchPageLogic.update();
                              });
                            }
                            return ComicTile(searchPageLogic.searchResult.comics[i]);
                          }
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: comicTileMaxWidth,
                        childAspectRatio: comicTileAspectRatio,
                      ),
                    );
                  }else{
                    return const SliverToBoxAdapter(
                      child: ListTile(
                        leading: Icon(Icons.error_outline),
                        title: Text("??????????????????"),
                      ),
                    );
                  }
                }
              }),
              GetBuilder<SearchPageLogic>(builder: (searchPageLogic){
                if(searchPageLogic.searchResult.pages!=searchPageLogic.searchResult.loaded&&searchPageLogic.searchResult.pages!=1&&searchPageLogic.searchResult.pages!=0) {
                  return SliverToBoxAdapter(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 80,
                      child: const Center(
                        child: SizedBox(
                          width: 20,height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  );
                }else{
                  return const SliverToBoxAdapter(child: SizedBox(height: 1,),);
                }
              }),

              SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
            ],
          ),
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