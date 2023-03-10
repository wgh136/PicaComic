import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';

class CategoryComicPageLogic extends GetxController{
  var search = SearchResult("", "", [], 1, 0);
  bool isLoading = true;
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class ModeRadioLogic1 extends GetxController{
  int value = appdata.getSearchMod();
  void change(int i){
    value = i;
    appdata.saveSearchMode(i);
    update();
  }
}

class CategoryComicPage extends StatelessWidget {
  final String keyWord;
  final int type;
  const CategoryComicPage(this.keyWord,{this.type=2,Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CategoryComicPageLogic>(
        init: CategoryComicPageLogic(),
        builder: (categoryComicPageLogic){
        if(categoryComicPageLogic.isLoading){
          if(type == 1){
              network.getCategoryComics(keyWord, appdata.settings[1]).then((s) {
                categoryComicPageLogic.search = s;
                categoryComicPageLogic.change();
              });
          }else{
            network.searchNew(keyWord, appdata.settings[1]).then((s) {
              categoryComicPageLogic.search = s;
              categoryComicPageLogic.change();
            });
          }
            return showLoading(context);
        }else{
          if(categoryComicPageLogic.search.comics.isNotEmpty){
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  centerTitle: true,
                  title: Text(keyWord),
                  actions: [
                    Tooltip(
                      message: "选择漫画排序模式",
                      child: IconButton(
                        icon: const Icon(Icons.manage_search_rounded),
                        onPressed: (){
                          showDialog(context: context, builder: (context){
                            Get.put(ModeRadioLogic1());
                            return SimpleDialog(
                              title: const Text("选择漫画排序模式"),
                              children: [GetBuilder<ModeRadioLogic1>(builder: (radioLogic){
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(width: 400,),
                                    ListTile(
                                      trailing: Radio<int>(value: 0,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },),
                                      title: const Text("新书在前"),
                                      onTap: (){
                                        radioLogic.change(0);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },
                                    ),
                                    ListTile(
                                      trailing: Radio<int>(value: 1,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },),
                                      title: const Text("旧书在前"),
                                      onTap: (){
                                        radioLogic.change(1);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },
                                    ),
                                    ListTile(
                                      trailing: Radio<int>(value: 2,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },),
                                      title: const Text("最多喜欢"),
                                      onTap: (){
                                        radioLogic.change(2);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },
                                    ),
                                    ListTile(
                                      trailing: Radio<int>(value: 3,groupValue: radioLogic.value,onChanged: (i){
                                        radioLogic.change(i!);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
                                        Get.back();
                                      },),
                                      title: const Text("最多指名"),
                                      onTap: (){
                                        radioLogic.change(3);
                                        categoryComicPageLogic.search = SearchResult("", "", [], 1, 0);
                                        categoryComicPageLogic.change();
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
                  ],
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: categoryComicPageLogic.search.comics.length,
                          (context, i){
                        if(i == categoryComicPageLogic.search.comics.length-1&&categoryComicPageLogic.search.loaded!=categoryComicPageLogic.search.pages){
                          if(type==1){
                          network.getMoreCategoryComics(categoryComicPageLogic.search).then((c) {
                            categoryComicPageLogic.update();
                          });
                        }else{
                            network.loadMoreSearch(categoryComicPageLogic.search).then((c) {
                              categoryComicPageLogic.update();
                            });
                          }
                      }
                        return ComicTile(categoryComicPageLogic.search.comics[i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                if(categoryComicPageLogic.search.loaded!=categoryComicPageLogic.search.pages&&categoryComicPageLogic.search.pages!=1)
                SliverToBoxAdapter(
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
                ),
                SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
              ],
            );
          }else{
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  centerTitle: true,
                  title: Text(keyWord),
                ),
                const SliverToBoxAdapter(
                  child: ListTile(
                    leading: Icon(Icons.error_outline),
                    title: Text("没有任何结果"),
                  ),
                )
              ],
            );
          }
        }
      },),
    );
  }
}
