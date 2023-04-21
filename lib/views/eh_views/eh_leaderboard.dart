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

  var networkStatus = <bool>[
    false,
    false,
    false,
    false
  ];
}

class EhLeaderboardPage extends StatelessWidget {
  const EhLeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 4, child: Column(
      children: const [
        TabBar(
          splashBorderRadius: BorderRadius.all(Radius.circular(10)),
          tabs: [
            Tab(text: "昨天"),
            Tab(text: "一个月"),
            Tab(text: "一年"),
            Tab(text: "所有时间"),
          ]),
        Expanded(child: TabBarView(
            children: [
              OneEhLeaderboardPage(0),
              OneEhLeaderboardPage(1),
              OneEhLeaderboardPage(2),
              OneEhLeaderboardPage(3),
            ]
        ),)
      ],
    ));
  }
}

class OneEhLeaderboardPage extends StatelessWidget{
  const OneEhLeaderboardPage(this.index,{super.key});
  final int index;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EhLeaderboardLogic>(builder: (logic){
      if(logic.leaderboards[index].galleries.isEmpty&&!logic.networkStatus[index]){
        ehNetwork.getLeaderboard(logic.leaderboards[index].type).then((board){
          if(board!=null){
            logic.leaderboards[index] = board;
            logic.update();
          }else{
            logic.networkStatus[index] = true;
            logic.update();
          }
        });
      }
      return CustomScrollView(
        slivers: [
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
                childCount: logic.leaderboards[index].galleries.length,
                    (context, i){
                  if(i==logic.leaderboards[index].galleries.length-1&&logic.leaderboards[index].loaded!=EhLeaderboard.max){
                    ehNetwork.getLeaderboardNextPage(logic.leaderboards[index]).then((v)=>logic.update());
                  }
                  return EhGalleryTile(logic.leaderboards[index].galleries[i]);
                }
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: comicTileMaxWidth,
              childAspectRatio: comicTileAspectRatio,
            ),
          ),
          if(logic.leaderboards[index].loaded!=EhLeaderboard.max&&!logic.networkStatus[index])
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
          if(logic.networkStatus[index])
            SliverToBoxAdapter(
              child: SizedBox(
                height: 80,
                child: Column(
                  children: [
                    SizedBox(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,size: 25,),
                          const SizedBox(width: 2,),
                          Text(ehNetwork.status?ehNetwork.message:"网络错误")
                        ],
                      ),
                    ),
                    Expanded(child: Center(child: FilledButton(
                      child: const Text("重试"),
                      onPressed: (){
                        logic.networkStatus[index] = false;
                        logic.update();
                      },
                    ),))
                  ],
                ),
              ),
            )
        ],
      );
    });
  }

}