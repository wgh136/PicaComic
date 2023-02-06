import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets.dart';

import 'base.dart';

class CategoryComicPageLogic extends GetxController{
  var search = SearchResult("", "", [], 1, 0);
  bool isLoading = true;
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class CategoryComicPage extends StatelessWidget {
  final String keyWord;
  final categoryComicPageLogic = Get.put(CategoryComicPageLogic());
  CategoryComicPage(this.keyWord,{Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<CategoryComicPageLogic>(builder: (categoryComicPageLogic){
        if(categoryComicPageLogic.isLoading){
          network.searchNew(keyWord, "dd").then((s){
            categoryComicPageLogic.search = s;
            categoryComicPageLogic.change();
          });
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else{
          if(categoryComicPageLogic.search.comics.isNotEmpty){
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  centerTitle: true,
                  title: Text(keyWord),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: categoryComicPageLogic.search.comics.length,
                          (context, i){
                        if(i == categoryComicPageLogic.search.comics.length-1&&categoryComicPageLogic.search.loaded!=categoryComicPageLogic.search.pages){
                          network.loadMoreSearch(categoryComicPageLogic.search).then((c){
                            categoryComicPageLogic.update();
                          });
                        }
                        return ComicTile(categoryComicPageLogic.search.comics[i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    childAspectRatio: 5,
                  ),
                ),
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
