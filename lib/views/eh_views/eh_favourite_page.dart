import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/views/eh_views/eh_widgets/eh_gallery_tile.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../base.dart';
import '../../network/eh_network/eh_main_network.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class EhFavouritePageLogic extends GetxController{
  bool loading = true;
  Galleries? galleries;
  ///收藏夹编号, 为-1表示加载全部
  int folder = -1;
  String? message;
  var folderNames = List.generate(10, (index) => "Favorite $index");

  Future<void> getGallery() async{
    if(folder == -1) {
      var res = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php", favoritePage: true);
      if(res.error){
        message = res.errorMessage;
      } else {
        galleries = res.data;
        folderNames = res.subData??folderNames;
        EhNetwork().folderNames = folderNames;
      }
    }else{
      var res = await EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php?favcat=$folder", favoritePage: true);
      if(res.error){
        message = res.errorMessage;
      } else {
        galleries = res.data;
      }
    }
    loading = false;
    try {
      update();
    }
    catch(e){
      //网络请求返回时页面已退出
    }
  }

  void retry(){
    loading = true;
    update();
  }

  void change(){
    loading = !loading;
    update();
  }

  void refresh_(){
    message = null;
    galleries = null;
    loading = true;
    update();
  }
}

class EhFavouritePage extends StatelessWidget {
  const EhFavouritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async{
        Get.find<EhFavouritePageLogic>().refresh_();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GetBuilder<EhFavouritePageLogic>(
            builder: (logic) => buildFolderSelector(context, logic),
          ),
          Expanded(
            child: GetBuilder<EhFavouritePageLogic>(
              builder: (logic){
                if(logic.loading){
                  if(appdata.settings[11]=="0") {
                    logic.getGallery();
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }else if(logic.galleries!=null){
                  return buildNormalView(logic, context);
                }else{
                  return showNetworkError(logic.message??"网络错误", logic.retry, context, showBack:false);
                }
              },
            ),
          )
        ],
    ));
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

  Widget buildFolderSelector(BuildContext context, EhFavouritePageLogic logic){
    var logic = Get.find<EhFavouritePageLogic>();
    final double width = MediaQuery.of(context).size.width > 400 ? 400 : MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      width: width,
      height: 50,
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: const BorderRadius.all(Radius.circular(16))
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("  收藏夹:  ".tr),
          logic.folder==-1 ? Text("全部".tr) : Text(logic.folderNames[logic.folder]),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.arrow_drop_down_sharp),
            onPressed: (){
              if(logic.loading){
                showMessage(context, "加载中".tr);
                return;
              }
              showMenu(
                  context: context,
                  position: RelativeRect.fromLTRB(width, 150, MediaQuery.of(context).size.width-width, MediaQuery.of(context).size.height-150),
                  items: [
                    PopupMenuItem(
                      height: 40,
                      child: Text("全部".tr),
                      onTap: (){
                        if(logic.folder != -1){
                          logic.folder = -1;
                          logic.refresh_();
                        }
                      },
                    ),
                    for(int i=0;i<=9;i++)
                      PopupMenuItem(
                        height: 40,
                        child: Text(logic.folderNames[i]),
                        onTap: (){
                          if(logic.folder != i){
                            logic.folder = i;
                            logic.refresh_();
                          }
                        },
                      )
                  ]
              );
            },
          )
        ],
      ),
    );
  }
}
