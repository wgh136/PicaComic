import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

import '../../foundation/app.dart';

class CollectionPageLogic extends GetxController{
  bool isLoading = true;
  var c1 = <ComicItemBrief>[];
  var c2 = <ComicItemBrief>[];
  bool status = true;
  String? message;

  void change(){
    isLoading = !isLoading;
    update();
  }

  void get() async{
    var collections = await network.getCollection();
    if(collections.success){
      c1 = collections.data[0];
      c2 = collections.data[1];
      change();
    } else {
      status = false;
      message = collections.errorMessageWithoutNull;
      change();
    }
  }
}

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("推荐".tl),
      ),
      body: GetBuilder<CollectionPageLogic>(
        init: CollectionPageLogic(),
        builder: (logic){
          if(logic.isLoading){
            network.getCollection().then((collections){
              if(collections.success){
                logic.c1 = collections.data[0];
                logic.c2 = collections.data[1];
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
                    child: Text("没有推荐, 可能等级不足".tl),
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
                    child: Text("本子妹推荐".tl,style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),),
                  )
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.c1.length,
                          (context, i){
                        return PicComicTile(logic.c1[i]);
                      }
                  ),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: App.comicTileMaxWidth,
                    childAspectRatio: App.comicTileAspectRatio,
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 20)),
                const SliverToBoxAdapter(child: Divider(),),
                SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 0, 5),
                      child: Text("本子母推荐".tl,style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),),
                    )
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.c2.length,
                          (context, i){
                        return PicComicTile(logic.c2[i]);
                      }
                  ),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: App.comicTileMaxWidth,
                    childAspectRatio: App.comicTileAspectRatio,
                  ),
                ),
                SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
              ],
            );
          }else{
            return showNetworkError(logic.message??"网络错误".tl,
                    () {
                  logic.status = true;
                  logic.change();
                }, context);
          }
        },
      ),
    );
  }
}
