import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';

import '../../base.dart';
import '../widgets/list_loading.dart';
import '../widgets/show_error.dart';
import 'hi_widgets.dart';

class HitomiLeaderboardPageLogic extends GetxController{
  var loading = <bool>[true, true, true, true];
  var comics = <ComicList>[
    ComicList(HitomiDataUrls.todayPopular),
    ComicList(HitomiDataUrls.weekPopular),
    ComicList(HitomiDataUrls.monthPopular),
    ComicList(HitomiDataUrls.yearPopular),
  ];

  var message = <String?>[null, null, null, null];

  void load(int index) async{
    var res = await HiNetwork().loadNextPage(comics[index]);
    if(res.error){
      message[index] = res.errorMessage;
    }
    loading[index] = false;
    try {
      update();
    }
    catch(e){
      //已退出页面时网络请求返回会导致出错
    }
  }

  void refresh_(int index){
    comics[index].total = 100;
    comics[index].toLoad = 0;
    comics[index].comics.clear();
    message[index] = null;
    loading[index] = true;
    update();
  }
}

class HitomiLeaderboardPage extends StatelessWidget {
  const HitomiLeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 4, child: Column(
      children: [
        TabBar(tabs: [
          Tab(text: "今天".tr,),
          Tab(text: "本周".tr,),
          Tab(text: "本月".tr,),
          Tab(text: "今年".tr,),
        ],),
        Expanded(
          child: GetBuilder<HitomiLeaderboardPageLogic>(
            builder: (logic) => const TabBarView(
              children: [
                OneLeaderboardPage(0),
                OneLeaderboardPage(1),
                OneLeaderboardPage(2),
                OneLeaderboardPage(3),
              ],
            ),
          ),
        )
      ],
    ));
  }

}

class OneLeaderboardPage extends StatelessWidget {
  const OneLeaderboardPage(this.index, {Key? key}) : super(key: key);
  final int index;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HitomiLeaderboardPageLogic>(builder: (logic){
      if(logic.loading[index]){
        logic.load(index);
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(logic.message[index] != null){
        return showNetworkError(logic.message[index]!, () => logic.refresh_(index), context, showBack: false);
      }else{
        return CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate((context, i) {
                if(i == logic.comics[index].comics.length-1){
                  logic.load(index);
                }
                return HiComicTile(logic.comics[index].comics[i]);
              }, childCount: logic.comics[index].comics.length),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            ),
            if(logic.comics[index].toLoad < logic.comics[index].total)
              const SliverToBoxAdapter(child: ListLoadingIndicator(),)
          ],
        );
      }
    });
  }
}
