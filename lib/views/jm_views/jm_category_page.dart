import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/settings/jm_settings.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'jm_widgets.dart';

class CategoryPageLogic extends GetxController{
  bool loading = true;
  CategoryComicsRes? comics;
  String? message;

  void change(){
    loading = !loading;
    update();
  }

  void get(Category category,{bool leaderboard=false, bool fromHomePage=false}) async{
    ComicsOrder order;
    if(fromHomePage){
      order = ComicsOrder.latest;
    }else{
      order = ComicsOrder.values[int.parse(appdata.settings[16])];
    }
    var res = await jmNetwork.getCategoryComics(category.slug, order);
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
  const JmCategoryPage(this.category, {this.fromHomePage=false,Key? key}) : super(key: key);
  final Category category;
  final bool fromHomePage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        actions: [
          if(! fromHomePage)
          Tooltip(
            message: "选择漫画排序模式".tr,
            child: IconButton(
              icon: const Icon(Icons.manage_search_outlined),
              onPressed: () async{
                var res = await setJmComicsOrder(context);
                if(!res) {
                  Get.find<CategoryPageLogic>(tag: "jm").refresh_();
                }
              },
            ),
          )
        ],
      ),
      body: GetBuilder<CategoryPageLogic>(
        init: CategoryPageLogic(),
        tag: "jm",
        builder: (logic){
          if(logic.loading){
            logic.get(category, fromHomePage: fromHomePage);
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
                    child: ListLoadingIndicator(),
                  ),
                SliverPadding(padding: MediaQuery.of(context).padding),
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
