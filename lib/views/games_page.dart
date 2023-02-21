import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets/game_widgets.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';

import '../base.dart';

class GamesPageLogic extends GetxController{
  bool isLoading = true;
  var games = Games([], 0, 1);
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class GamesPage extends StatelessWidget {
  const GamesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GamesPageLogic>(
        init: GamesPageLogic(),
        builder: (logic){
          if(logic.isLoading){
            network.getGames().then((c) {
              if(c!=null) {
                logic.games = c;
              }
              logic.change();
            });
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(logic.games.games.isNotEmpty){
            return Material(
              child: CustomScrollView(
                slivers: [
                  if(MediaQuery.of(context).size.shortestSide<=changePoint)
                    SliverAppBar.large(
                      centerTitle: true,
                      title: const Text("游戏"),
                    ),
                  if(MediaQuery.of(context).size.shortestSide>changePoint)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 180,
                        child: const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(padding: EdgeInsets.fromLTRB(15, 0, 0, 30),child: Text("游戏",style: TextStyle(fontSize: 28),),),
                        ),
                      ),
                    ),
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        childCount: logic.games.games.length,
                            (context, i){
                          if(i == logic.games.games.length-1&&logic.games.loaded!=logic.games.total){
                            network.getMoreGames(logic.games).then((c){
                              logic.update();
                            });
                          }
                          return GameTile(logic.games.games[i]);
                        }
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 600,
                      childAspectRatio: 1.7,
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
                ],
              ),
            );
          }else{
            return showNetworkError(context, () {
              logic.change();
            });
          }
        });
  }
}
