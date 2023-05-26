import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

import '../../base.dart';

class CollectionPageLogic extends GetxController{
  bool isLoading = true;
  var c1 = <ComicItemBrief>[];
  var c2 = <ComicItemBrief>[];
  bool status = true;
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("推荐".tr),
      ),
      body: GetBuilder<CollectionPageLogic>(
        init: CollectionPageLogic(),
        builder: (logic){
          if(logic.isLoading){
            network.getCollection().then((collections){
              if(collections!=null){
                logic.c1 = collections[0];
                logic.c2 = collections[1];
                logic.change();
              }else{
                logic.status = false;
                logic.change();
              }
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(logic.c1.isEmpty&&logic.c2.isEmpty){
            return Stack(
              children: [
                Positioned(
                  top: MediaQuery.of(context).size.height/2-160,
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
                  top: MediaQuery.of(context).size.height/2-80,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text("没有推荐, 可能等级不足".tr),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: MediaQuery.of(context).size.height/2-40,
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 100,
                        height: 40,
                        child: FilledButton(
                          onPressed: (){
                            logic.status = true;
                            logic.change();
                          },
                          child: const Text("重试"),
                        ),
                      )
                  ),
                ),
              ],
            );
          } else if(logic.status){
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                    child: Text("本子妹推荐".tr,style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),),
                  )
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.c1.length,
                          (context, i){
                        return PicComicTile(logic.c1[i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 20)),
                const SliverToBoxAdapter(child: Divider(),),
                SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                      child: Text("本子母推荐".tr,style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),),
                    )
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.c2.length,
                          (context, i){
                        return PicComicTile(logic.c2[i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
              ],
            );
          }else{
            return showNetworkError(context, () {
              logic.status = true;
              logic.change();
            });
          }
        },
      ),
    );
  }
}
