import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import '../../base.dart';
import 'eh_widgets/eh_gallery_tile.dart';

class EhLeaderboardLogic extends GetxController{
  var leaderboards = <EhLeaderboard>[
    EhLeaderboard(EhLeaderboardType.yesterday, [], 0),
    EhLeaderboard(EhLeaderboardType.month, [], 0),
    EhLeaderboard(EhLeaderboardType.year, [], 0),
    EhLeaderboard(EhLeaderboardType.all, [], 0),
  ];
}

class EhLeaderboardPage extends StatelessWidget {
  EhLeaderboardPage({Key? key}) : super(key: key);
  final logic = Get.put(EhLeaderboardLogic());

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 4, child: Column(
      children: [
        const TabBar(tabs: [
          Tab(text: "昨天"),
          Tab(text: "一个月"),
          Tab(text: "一年"),
          Tab(text: "所有时间"),
        ]),
        Expanded(child: TabBarView(
          children: logic.leaderboards.map((e) => GetBuilder<EhLeaderboardLogic>(builder: (logic){
            if(e.galleries.isEmpty){
              ehNetwork.getLeaderboard(e.type).then((board){
                if(board!=null){
                  e = board;
                  logic.update();
                }
              });
            }
            return CustomScrollView(
              slivers: [
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: e.galleries.length,
                          (context, i){
                        if(i==e.galleries.length-1&&e.loaded!=EhLeaderboard.max){
                          ehNetwork.getLeaderboardNextPage(e).then((v)=>logic.update());
                        }
                        return EhGalleryTile(e.galleries[i]);
                      }
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                if(e.loaded!=EhLeaderboard.max)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 80,
                      child: const Center(
                        child: SizedBox(
                          width: 20,height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          })).toList(),
        ))
      ],
    ));
  }
}
