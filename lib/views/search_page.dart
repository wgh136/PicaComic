import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';

class SearchPageLogic extends GetxController{
  var searchResult = SearchResult("", "", [], 1, 0);
  var controller = TextEditingController();
  bool isLoading = false;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void _refresh(){
    change();
    network.searchNew(searchResult.keyWord, appdata.settings[1]).then((t){
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

  SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: FloatingSearchBar(supportingText: '搜索',trailingIcon: const Icon(Icons.arrow_drop_down_outlined),f:(s){
                    if(s=="") return;
                    searchPageLogic.change();
                    network.searchNew(s, appdata.settings[1]).then((t){
                      searchPageLogic.searchResult = t;
                      searchPageLogic.change();
                    });
                  },searchPageLogic: searchPageLogic,controller: searchPageLogic.controller,),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(top: 5)),
              GetBuilder<SearchPageLogic>(builder: (searchPageLogic){
                if(searchPageLogic.isLoading){
                  return SliverToBoxAdapter(
                    child: SizedBox.fromSize(
                      size: Size(MediaQuery.of(context).size.width,MediaQuery.of(context).size.height),
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
                        maxCrossAxisExtent: 600,
                        childAspectRatio: 4,
                      ),
                    );
                  }else if(searchPageLogic.searchResult.keyWord!=""){
                    return const SliverToBoxAdapter(
                      child: ListTile(
                        leading: Icon(Icons.error_outline),
                        title: Text("没有任何结果"),
                      ),
                    );
                  }else{
                    return SliverToBoxAdapter(
                      child: SizedBox(
                        width: Get.size.width,
                        height: 200,
                        child: Column(
                          children: [
                            Wrap(
                              children: [
                                for(var s in hotSearch)
                                  GestureDetector(
                                    onTap: (){
                                      searchPageLogic.controller.text = s;
                                      searchPageLogic.change();
                                      network.searchNew(s, appdata.settings[1]).then((t){
                                        searchPageLogic.searchResult = t;
                                        searchPageLogic.change();
                                      });
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                                      elevation: 0,
                                      color: Theme
                                          .of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(5, 2, 5, 2), child: Text(s),),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }
                }
              }),
            ],
          ),
        )
    );
  }
}

class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailingIcon,
    required this.supportingText,
    required this.f,
    required this.searchPageLogic,
    required this.controller
  }) : super(key: key);

  final double height;
  double get effectiveHeight {
    return max(height, 53);
  }
  final Widget? trailingIcon;
  final void Function(String) f;
  final String supportingText;
  final SearchPageLogic searchPageLogic;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 720),
        padding: const EdgeInsets.only(top: 5),
        width: double.infinity,
        height: effectiveHeight,
        child: Material(
          elevation: 0,
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(effectiveHeight / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Tooltip(
                message: "返回",
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: (){
                    Get.back();
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextField(
                    autofocus: true,
                    cursorColor: colorScheme.primary,
                    style: textTheme.bodyLarge,
                    textAlignVertical: TextAlignVertical.center,
                    controller: controller,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      hintText: supportingText,
                      hintStyle: textTheme.bodyLarge?.apply(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: f,
                  ),
                ),
              ),
              if (trailingIcon != null)
                Tooltip(
                  message: "选择模式",
                  child: IconButton(
                    icon: trailingIcon!,
                    onPressed: (){
                      showDialog(context: context, builder: (context){
                        Get.put(ModeRadioLogic());
                        return Dialog(
                          child: GetBuilder<ModeRadioLogic>(builder: (radioLogic){
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const ListTile(title: Text("选择搜索及分类排序模式"),),
                                ListTile(
                                  trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                                    radioLogic.change(i!);
                                    searchPageLogic._refresh();
                                    Get.back();
                                  },),
                                  title: const Text("新书在前"),
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
                                  title: const Text("旧书在前"),
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
                                  title: const Text("最多喜欢"),
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
                                  title: const Text("最多指名"),
                                  onTap: (){
                                    radioLogic.change(3);
                                    searchPageLogic._refresh();
                                    Get.back();
                                  },
                                ),
                              ],
                            );
                          },),
                        );
                      });
                    },
                  ),
                ),
            ]),
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