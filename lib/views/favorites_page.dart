import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/widgets.dart';

class FavoritesPageLogic extends GetxController{
  var favorites = Favorites([], 1, 0);
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
    update();
  }
}



class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<FavoritesPageLogic>(
        init: FavoritesPageLogic(),
          builder: (favoritesPageLogic){
        if(favoritesPageLogic.isLoading) {
          favoritesPageLogic.get().then((t){favoritesPageLogic.change();});
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(favoritesPageLogic.favorites.loaded!=0){
          return RefreshIndicator(
            onRefresh: () async{
              favoritesPageLogic.favorites = Favorites([], 1, 0);
              await favoritesPageLogic.get();
              favoritesPageLogic.update();
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  centerTitle: true,
                  title: const Text("收藏夹"),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: favoritesPageLogic.favorites.comics.length,
                          (context, i){
                        if(i == favoritesPageLogic.favorites.comics.length-1&&favoritesPageLogic.favorites.pages!=favoritesPageLogic.favorites.loaded){
                          network.loadMoreFavorites(favoritesPageLogic.favorites).then((t){favoritesPageLogic.update();});
                        }
                        return ComicTile(favoritesPageLogic.favorites.comics[i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 600,
                    childAspectRatio: 4,
                  ),
                ),
              ],
            ),
          );
        }else{
          return Stack(
            children: [
              Positioned(top: 0,
                left: 0,child: Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),child: Tooltip(
                  message: "返回",
                  child: IconButton(
                    iconSize: 25,
                    icon: const Icon(Icons.arrow_back_outlined),
                    onPressed: (){Get.back();},
                  ),
                ),),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height/2-80,
                left: 0,
                right: 0,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Icon(Icons.error_outline,size:60,),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height/2-10,
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Text("网络错误"),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height/2+20,
                left: MediaQuery.of(context).size.width/2-50,
                child: SizedBox(
                  width: 100,
                  height: 40,
                  child: FilledButton(
                    onPressed: (){
                      favoritesPageLogic.favorites = Favorites([], 1, 0);
                      favoritesPageLogic.change();
                    },
                    child: const Text("重试"),
                  ),
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
