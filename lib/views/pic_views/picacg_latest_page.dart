import 'package:flutter/material.dart';
import "package:get/get.dart";
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

import '../../base.dart';

class PicacgLatestPageLogic extends GetxController{
  bool loading = true;
  List<ComicItemBrief>? comics;
  String? message;
  int page = 1;

  void get() async{
    var res = await network.getLatest(1);
    if(res.error){
      message = res.errorMessage!;
    }else{
      comics = res.data;
    }
    loading = false;
    try {
      update();
    }
    catch(e){
      //忽视
    }
  }

  void loadMore() async{
    var res = await network.getLatest(page+1);
    if(!res.error){
      comics!.addAll(res.data);
      update();
    }else{
      showMessage(Get.context, res.errorMessage!);
    }
  }

  void refresh_(){
    loading = true;
    comics = null;
    message = null;
    page = 1;
    get();
  }
}



class PicacgLatestPage extends StatelessWidget {
  const PicacgLatestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<PicacgLatestPageLogic>(
        init: PicacgLatestPageLogic(),
        builder: (logic){
          if(logic.loading){
            logic.get();
            return showLoading(context);
          }else if(logic.comics!=null){
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  centerTitle: true,
                  title: const Text("最新漫画"),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.comics!.length,
                          (context, i){
                        if(i == logic.comics!.length-1){
                          logic.loadMore();
                        }
                        return PicComicTile(logic.comics![i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: ListLoadingIndicator(),
                )
              ],
            );
          }else{
            return showNetworkError(logic.message!, logic.refresh_, context);
          }
      }),
    );
  }
}
