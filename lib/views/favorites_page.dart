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
  final favoritesPageLogic = Get.put(FavoritesPageLogic());

  FavoritesPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<FavoritesPageLogic>(builder: (favoritesPageLogic){
        if(favoritesPageLogic.isLoading) {
          favoritesPageLogic.get().then((t){favoritesPageLogic.change();});
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else{
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
                    childAspectRatio: 5,
                  ),
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
