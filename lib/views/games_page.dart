import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets/game_widgets.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';

import '../base.dart';
import '../tools/ui_mode.dart';

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
        builder: (logic){
          if(logic.isLoading){
            network.getGames().then((c) {
              if(c!=null) {
                logic.games = c;
              }
              logic.change();
            });
            return Stack(
              children: [
                const Center(
                  child: CircularProgressIndicator(),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar.large(
                        centerTitle: true,
                        title: const Text(""),
                      ),
                    ],
                  ),
                )
              ],
            );
          }else if(logic.games.games.isNotEmpty){
            return Material(
              child: CustomScrollView(
                slivers: [
                  if(UiMode.m1(context))
                    SliverAppBar.large(
                      centerTitle: true,
                      title: const Text("游戏"),
                    ),
                  if(!UiMode.m1(context))
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
                  if(logic.games.total!=logic.games.loaded&&logic.games.total!=1)
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
                  SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
                ],
              ),
            );
          }else{
            return showNetworkError(context, ()=> logic.change(),showBack: false);
          }
        });
  }
}
