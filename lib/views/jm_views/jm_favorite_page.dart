import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';

import 'jm_widgets.dart';

class JmFavoritePageLogic extends GetxController{
  bool loading = true;
  FavoriteFolder? folder;
  String? message;

  void change(){
    loading = !loading;
    update();
  }

  void get() async{
    var res = await jmNetwork.getFolderComics("0");
    if(res.error){
      message = res.errorMessage;
      change();
    }else{
      folder = res.data;
      change();
    }
  }

  void loadMore() async{
    if(folder!.total <= folder!.loadedComics){
      return;
    }
    await jmNetwork.loadFavoriteFolderNextPage(folder!);
    update();
  }

  void refresh_(){
    folder = null;
    message = null;
    loading = true;
    update();
  }
}

class JmFavoritePage extends StatelessWidget {
  const JmFavoritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JmFavoritePageLogic>(builder: (logic){
      if(appdata.jmName == ""){
        return const Center(
          child: Text("未登录"),
        );
      }
      if(logic.loading){
        logic.get();
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(logic.folder == null){
        return showNetworkError(logic.message!, logic.refresh_, context, showBack: false);
      }else{
        return CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                      (context, index){
                    if(index == logic.folder!.comics.length-1){
                      logic.loadMore();
                    }
                    return JmComicTile(logic.folder!.comics[index]);
                  },
                  childCount: logic.folder!.comics.length
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            ),
            if(logic.folder!.total > logic.folder!.loadedComics)
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
      }
    });
  }
}
