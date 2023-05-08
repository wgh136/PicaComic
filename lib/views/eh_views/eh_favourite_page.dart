import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_gallery_tile.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import '../../base.dart';
import '../../eh_network/eh_main_network.dart';
import '../widgets/widgets.dart';

class EhFavouritePageLogic extends GetxController{
  bool loading = true;
  Galleries? galleries;
  int page = 0;

  var pages = <List<EhGalleryBrief>>[];

  Future<void> getGallery() async{
    galleries = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php");
    pages.add([]);
    if(galleries != null) {
      for (var g in galleries!.galleries) {
        pages[page].add(g);
      }
    }
    loading = false;
    update();
  }

  void retry(){
    loading = true;
    update();
  }

  void change(){
    loading = !loading;
    update();
  }

  void changeToNextPage() async{
    if(galleries?.next == null && page+1 == pages.length){
      showMessage(Get.context, "已经是最后一页了");
      return;
    }
    if(pages.length>page+1){
      page++;
      update();
    }else{
      change();
      page++;
      galleries!.galleries.clear();
      await EhNetwork().getNextPageGalleries(galleries!);
      pages.add([]);
      for (var g in galleries!.galleries) {
        pages[page].add(g);
      }
      change();
    }
  }

  void changeToLastPage(){
    if(page == 0){
      showMessage(Get.context, "已经是第一页了");
      return;
    }
    page--;
    update();
  }
}

class EhFavouritePage extends StatelessWidget {
  const EhFavouritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EhFavouritePageLogic>(
      builder: (logic){
        if(logic.loading){
          if(appdata.settings[11]=="0"||logic.pages.isEmpty) {
            logic.getGallery();
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.galleries!=null){
          return appdata.settings[11]=="0"?buildNormalView(logic, context):buildPagesView(logic, context);
        }else{
          return showNetworkError(context, logic.retry, showBack:false, eh: true);
        }
      },
    );
  }

  Widget buildNormalView(EhFavouritePageLogic logic, BuildContext context){
    return CustomScrollView(
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: logic.galleries!.length,
                  (context, i){
                if(i==logic.galleries!.length-1){
                  EhNetwork().getNextPageGalleries(logic.galleries!).then((v)=>logic.update());
                }
                return EhGalleryTile(logic.galleries![i]);
              }
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: comicTileMaxWidth,
            childAspectRatio: comicTileAspectRatio,
          ),
        ),
        if(logic.galleries!.next!=null)
          const SliverToBoxAdapter(
            child: ListLoadingIndicator(),
          ),
      ],
    );
  }

  Widget buildPagesView(EhFavouritePageLogic logic, BuildContext context){
    return CustomScrollView(
      slivers: [
        SliverGrid(
          delegate: SliverChildBuilderDelegate(
              childCount: logic.pages[logic.page].length,
                  (context, i){
                return EhGalleryTile(logic.pages[logic.page][i]);
              }
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
                          onPressed: logic.changeToLastPage,
                          child: const Text("上一页")
                      ),
                      const Spacer(),
                      Text("${logic.page+1}/?"),
                      const Spacer(),
                      FilledButton(
                          onPressed: logic.changeToNextPage,
                          child: const Text("下一页")
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
