import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';

import 'jm_widgets.dart';

class JmLatestPageLogic extends GetxController{
  bool loading = true;
  var comics = <JmComicBrief>[];
  int page = 0;
  String? message;
  ///当请求漫画的结果为空时, 认为加载达到上限, 将其设置为true
  ///
  /// 并不知道加载有没有上限, 也没必要通过大量的网络请求查看是否存在上限
  bool loadEnd = false;

  void get() async{
    var res = await jmNetwork.getLatest(page);
    if(!res.error){
      comics.addAll(res.data);
      if(!loading && res.data.isEmpty){
        loadEnd = true;
      }
    }else{
      message = res.errorMessage;
    }
    loading = false;
    update();
  }

  void refresh_(){
    comics.clear();
    loading = true;
    update();
  }
}

class JmLatestPage extends StatelessWidget {
  const JmLatestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JmLatestPageLogic>(
      builder: (logic){
        if(logic.loading){
          logic.get();
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.comics.isNotEmpty){
          return CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                        (context, index){
                      if(index == logic.comics.length-1){
                        logic.get();
                      }
                      return JmComicTile(logic.comics[index]);
                    },
                    childCount: logic.comics.length
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: comicTileMaxWidth,
                  childAspectRatio: comicTileAspectRatio,
                ),
              ),
              if(!logic.loadEnd)
                const SliverToBoxAdapter(
                  child: ListLoadingIndicator(),
                )
            ],
          );
        }else{
          return showNetworkError(logic.message!, logic.refresh_, context);
        }
      },
    );
  }
}
