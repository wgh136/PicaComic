import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';



class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({Key? key}) : super(key: key);

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  final List<Tab> tabs = <Tab>[
    const Tab(text: '24小时'),
    const Tab(text: '7天'),
    const Tab(text: '30天'),
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: TabBar(
            tabs: tabs,
          ),
        ),
        body: const TabBarView(
            children: [
              LeaderBoardH24(),
              LeaderBoardD7(),
              LeaderBoardD30()
            ]
        ),
      ),
    );
  }
}

class LeaderBoardH24Logic extends GetxController{
  bool isLoading = true;
  var comics = <ComicItemBrief>[];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class LeaderBoardH24 extends StatelessWidget {
  final String time = "H24";
  const LeaderBoardH24({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderBoardH24Logic>(
      init: LeaderBoardH24Logic(),
        builder: (leaderBoardLogic){
      if(leaderBoardLogic.isLoading){
        network.getLeaderboard(time).then((c){
          leaderBoardLogic.comics = c;
          leaderBoardLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(leaderBoardLogic.comics.isNotEmpty){
        return CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: leaderBoardLogic.comics.length,
                      (context, i){
                    return ComicTile(leaderBoardLogic.comics[i]);
                  }
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            )
          ],
        );
      }else{
        return showNetworkError(context, () {
          leaderBoardLogic.change();
        });
      }
    });
  }
}

class LeaderBoardD7Logic extends GetxController{
  bool isLoading = true;
  var comics = <ComicItemBrief>[];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class LeaderBoardD7 extends StatelessWidget {
  final String time = "D7";
  const LeaderBoardD7({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderBoardD7Logic>(
      init: LeaderBoardD7Logic(),
        builder: (leaderBoardLogic){
      if(leaderBoardLogic.isLoading){
        network.getLeaderboard(time).then((c){
          leaderBoardLogic.comics = c;
          leaderBoardLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(leaderBoardLogic.comics.isNotEmpty){
        return CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: leaderBoardLogic.comics.length,
                      (context, i){
                    return ComicTile(leaderBoardLogic.comics[i]);
                  }
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            )
          ],
        );
      }else{
        return showNetworkError(context, () {
          leaderBoardLogic.change();
        });
      }
    });
  }
}

class LeaderBoardD30Logic extends GetxController{
  bool isLoading = true;
  var comics = <ComicItemBrief>[];
  void change(){
    isLoading = !isLoading;
    update();
  }
}

class LeaderBoardD30 extends StatelessWidget {
  final String time = "D30";
  const LeaderBoardD30({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderBoardD30Logic>(
      init: LeaderBoardD30Logic(),
        builder: (leaderBoardLogic){
      if(leaderBoardLogic.isLoading){
        network.getLeaderboard(time).then((c){
          leaderBoardLogic.comics = c;
          leaderBoardLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(leaderBoardLogic.comics.isNotEmpty){
        return CustomScrollView(
          slivers: [
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: leaderBoardLogic.comics.length,
                      (context, i){
                    return ComicTile(leaderBoardLogic.comics[i]);
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
          leaderBoardLogic.change();
        });
      }
    });
  }
}