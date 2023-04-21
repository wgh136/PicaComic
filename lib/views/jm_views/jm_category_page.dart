import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/jm_network/jm_main_network.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import 'package:pica_comic/views/settings/jm_settings.dart';
import 'jm_widgets.dart';

class CategoryPageLogic extends GetxController{
  bool loading = true;
  CategoryComicsRes? comics;
  String? message;

  void change(){
    loading = !loading;
    update();
  }

  void get(Category category,{bool leaderboard=false}) async{
    var res = await jmNetwork.getCategoryComics(category.slug, ComicsOrder.values[int.parse(appdata.settings[16])]);
    if(res.error){
      message = res.errorMessage;
      change();
    }else{
      comics = res.data;
      change();
    }
  }

  void refresh_(){
    comics = null;
    message = null;
    loading = true;
    update();
  }

  void loadMore() async{
    await jmNetwork.getCategoriesComicNextPage(comics!);
    update();
  }
}

class JmCategoryPage extends StatelessWidget {
  const JmCategoryPage(this.category, {Key? key}) : super(key: key);
  final Category category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          Tooltip(
            message: "设置排序方式",
            child: IconButton(
              icon: const Icon(Icons.manage_search_outlined),
              onPressed: () async{
                var res = await setJmComicsOrder(context);
                if(!res) {
                  Get.find<CategoryPageLogic>().refresh_();
                }
              },
            ),
          )
        ],
      ),
      body: GetBuilder<CategoryPageLogic>(
        init: CategoryPageLogic(),
        builder: (logic){
          if(logic.loading){
            logic.get(category);
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(logic.comics != null){
            return CustomScrollView(
              slivers: [
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                          (context, index){
                        if(index == logic.comics!.comics.length-1){
                          logic.loadMore();
                        }
                        return JmComicTile(logic.comics!.comics[index]);
                      },
                      childCount: logic.comics!.comics.length
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                if(logic.comics!.loaded < logic.comics!.total)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
              ],
            );
          }else{
            return showNetworkError(logic.message!, logic.refresh_, context, showBack: false);
          }
        },
      ),
    );
  }
}
