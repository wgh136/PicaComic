import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/eh_views/eh_leaderboard.dart';
import 'package:pica_comic/views/jm_views/jm_leaderboard.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';



class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({Key? key}) : super(key: key);

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  final logic = Get.put(EhLeaderboardLogic());
  final logic2 = Get.put(LeaderBoardD7Logic());
  final logic3 = Get.put(LeaderBoardD30Logic());
  final logic4 = Get.put(LeaderBoardH24Logic());


  final List<Tab> tabs = <Tab>[
    const Tab(text: '24小时'),
    const Tab(text: '7天'),
    const Tab(text: '30天'),
  ];

  @override
  void initState() {
    createLogic();
    super.initState();
  }

  @override
  void dispose(){
    logic.dispose();
    logic2.dispose();
    logic3.dispose();
    logic4.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Scaffold(
      appBar: AppBar(title:
        const TabBar(
          splashBorderRadius: BorderRadius.all(Radius.circular(10)),
          tabs: [
            Tab(text: "Picacg",),
            Tab(text: "E-Hentai",),
            Tab(text: "JmComic",)
          ],
      ),),
      body: TabBarView(children: [
        DefaultTabController(
          length: tabs.length,
          child: Column(
            children: [
              TabBar(tabs: tabs, splashBorderRadius: const BorderRadius.all(Radius.circular(10)),),
              const Expanded(child: TabBarView(
                  children: [
                    LeaderBoardH24(),
                    LeaderBoardD7(),
                    LeaderBoardD30()
                  ]
              ))
            ],
          ),
        ),
        const EhLeaderboardPage(),
        const JmLeaderboardPage()
      ],),
    ));
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
        return showNetworkError(
          context,
          () => leaderBoardLogic.change(),
          showBack: false
        );
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
        return showNetworkError(
            context,
            () => leaderBoardLogic.change(),
            showBack: false
        );
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
        return showNetworkError(
            context,
            () => leaderBoardLogic.change(),
            showBack: false
        );
      }
    });
  }
}