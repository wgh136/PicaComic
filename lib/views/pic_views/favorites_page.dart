import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class FavoritesPageLogic extends GetxController{
  var favorites = Favorites([], 1, 0);
  int page = 1;
  int pages = 0;
  var comics = <ComicItemBrief>[]; //加载指定页漫画使用的列表
  var controller = TextEditingController();
  bool isLoading = true;
  Future<void> get()async {
    if(favorites.comics.isEmpty){
      favorites = await network.getFavorites();
    }else{
      await network.loadMoreFavorites(favorites);
    }
  }
  void change(){
    isLoading = !isLoading;
    try {
      update();
    }
    catch(e){
      //已退出页面
    }
  }

  void changePage(String p){
    int i;
    try{
      i = int.parse(p);
      if(i<1||i>pages){
        showMessage(Get.context, "输入的数字不合法".tr);
      }
      if(i != page){
        page = i;
        comics.clear();
        change();
      }
    }
    catch(e){
      showMessage(Get.context, "输入的数字不合法".tr);
    }
  }
}



class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FavoritesPageLogic>(
        builder: (favoritesPageLogic){
          favoritesPageLogic.controller = TextEditingController();
          return appdata.settings[11]=="0"?buildComicList(favoritesPageLogic, context):buildComicListWithSelectedPage(favoritesPageLogic, context);
        });
  }

  Widget buildComicList(FavoritesPageLogic favoritesPageLogic, BuildContext context){
    if(favoritesPageLogic.isLoading) {
      favoritesPageLogic.get().then((t)=>favoritesPageLogic.change());
      return const Center(child: CircularProgressIndicator(),);
    }else if(favoritesPageLogic.favorites.loaded!=0){
      return RefreshIndicator(
        onRefresh: () async{
          favoritesPageLogic.favorites = Favorites([], 1, 0);
          await favoritesPageLogic.get();
          favoritesPageLogic.update();
        },
        child: CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: favoritesPageLogic.favorites.comics.length,
                      (context, i){
                    if(i == favoritesPageLogic.favorites.comics.length-1&&favoritesPageLogic.favorites.pages!=favoritesPageLogic.favorites.loaded){
                      network.loadMoreFavorites(favoritesPageLogic.favorites).then((t)=>favoritesPageLogic.update());
                    }
                    return PicComicTile(favoritesPageLogic.favorites.comics[i]);
                  }
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            ),
            if(favoritesPageLogic.favorites.pages!=favoritesPageLogic.favorites.loaded&&favoritesPageLogic.favorites.pages!=1)
              const SliverToBoxAdapter(
                child: ListLoadingIndicator(),
              ),
            SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
          ],
        ),
      );
    }else{
      return showNetworkError(context, ()=>favoritesPageLogic.change(), showBack: false);
    }
  }

  Widget buildComicListWithSelectedPage(FavoritesPageLogic favoritesPageLogic,BuildContext context){
    if(favoritesPageLogic.isLoading){
      network.getSelectedPageFavorites(favoritesPageLogic.page,favoritesPageLogic.comics).then((i){
        favoritesPageLogic.isLoading = false;
        favoritesPageLogic.pages = i;
        favoritesPageLogic.update();
      });
      return const Center(child: CircularProgressIndicator(),);
    }else {
      return CustomScrollView(
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: favoritesPageLogic.comics.length,
                  (context, i)=>PicComicTile(favoritesPageLogic.comics[i])
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: comicTileMaxWidth,
            childAspectRatio: comicTileAspectRatio,
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width>600?600:MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      const SizedBox(width: 10,),
                      FilledButton(
                          onPressed: (){
                            if(favoritesPageLogic.page==1||favoritesPageLogic.pages==0){
                              showMessage(context, "已经是第一页了".tr);
                            }else{
                              favoritesPageLogic.page--;
                              favoritesPageLogic.change();
                            }
                          },
                          child: const Text("上一页")
                      ),
                      const Spacer(),
                      Text("${favoritesPageLogic.page}/${favoritesPageLogic.pages}"),
                      const Spacer(),
                      FilledButton(
                          onPressed: (){
                            if(favoritesPageLogic.page==favoritesPageLogic.pages||favoritesPageLogic.pages==0){
                              showMessage(context, "已经是最后一页了".tr);
                            }else{
                              favoritesPageLogic.page++;
                              favoritesPageLogic.change();
                            }
                          },
                          child: Text("下一页".tr)
                      ),
                      const SizedBox(width: 10,),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),

      ],
    );
    }
  }
}


