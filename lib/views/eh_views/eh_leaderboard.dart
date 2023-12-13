import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/app.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../widgets/grid_view_delegate.dart';
import '../widgets/list_loading.dart';
import 'eh_widgets/eh_gallery_tile.dart';

class EhLeaderboardLogic extends StateController{
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

class EhLeaderboardPage extends StatefulWidget {
  const EhLeaderboardPage({Key? key}) : super(key: key);

  @override
  State<EhLeaderboardPage> createState() => _EhLeaderboardPageState();
}

class _EhLeaderboardPageState extends State<EhLeaderboardPage> {
  @override
  void initState() {
    StateController.put(EhLeaderboardLogic());
    super.initState();
  }

  @override
  void dispose() {
    StateController.remove<EhLeaderboardLogic>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        primary: UiMode.m1(context),
        title: Text("排行榜".tl),
      ),
      body: DefaultTabController(length: 4, child: Column(
        children: [
          TabBar(
              splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
              tabs: [
                Tab(text: "昨天".tl),
                Tab(text: "一个月".tl),
                Tab(text: "一年".tl),
                Tab(text: "所有时间".tl),
              ]),
          const Expanded(child: TabBarView(
              children: [
                OneEhLeaderboardPage(0),
                OneEhLeaderboardPage(1),
                OneEhLeaderboardPage(2),
                OneEhLeaderboardPage(3),
              ]
          ),)
        ],
      )),
    );
  }
}

class OneEhLeaderboardPage extends StatelessWidget{
  const OneEhLeaderboardPage(this.index,{super.key});
  final int index;

  @override
  Widget build(BuildContext context) {
    return StateBuilder<EhLeaderboardLogic>(
      builder: (logic){
        if(logic.leaderboards[index].galleries.isEmpty&&!logic.networkStatus[index]){
          EhNetwork().getLeaderboard(logic.leaderboards[index].type).then((board){
            if(board.success){
              logic.leaderboards[index] = board.data;
              try {
                logic.update();
              }
              catch(e){
                //忽视
              }
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
                      EhNetwork().getLeaderboardNextPage(logic.leaderboards[index]).then((v)=>logic.update());
                    }
                    return EhGalleryTile(logic.leaderboards[index].galleries[i]);
                  }
              ),
              gridDelegate: const SliverGridDelegateWithComics(),
            ),
            if(logic.leaderboards[index].loaded!=EhLeaderboard.max&&!logic.networkStatus[index])
              const SliverToBoxAdapter(
                child: ListLoadingIndicator(),
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
                            Text("网络错误".tl)
                          ],
                        ),
                      ),
                      Expanded(child: Center(child: FilledButton(
                        child: Text("重试".tl),
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