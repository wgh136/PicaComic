import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/eh_views/eh_leaderboard.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_leaderboard_page.dart';
import 'package:pica_comic/views/jm_views/jm_leaderboard.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

class LeaderboardPageLogic extends GetxController{}



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
  final logic5 = Get.put(HitomiLeaderboardPageLogic());
  final logic6 = Get.put(LeaderboardPageLogic());


  final List<Tab> tabs = <Tab>[
    Tab(text: '24小时'.tr),
    Tab(text: '7天'.tr),
    Tab(text: '30天'.tr),
  ];

  @override
  void initState() {
    createLogic();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int pages = int.parse(appdata.settings[21][0]) + int.parse(appdata.settings[21][1]) +
        int.parse(appdata.settings[21][2]) + int.parse(appdata.settings[21][3]);
    return GetBuilder<LeaderboardPageLogic>(builder: (logic) => DefaultTabController(length: pages, child: Scaffold(
      appBar: AppBar(title:
      TabBar(
        splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
        tabs: [
          if(appdata.settings[21][0] == "1")
            const Tab(text: "Picacg",),
          if(appdata.settings[21][1] == "1")
            const Tab(text: "E-Hentai",),
          if(appdata.settings[21][2] == "1")
            const Tab(text: "JmComic",),
          if(appdata.settings[21][3] == "1")
            const Tab(text: "Hitomi",),
        ],
      ),),
      body: TabBarView(children: [
        if(appdata.settings[21][0] == "1")
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
        if(appdata.settings[21][1] == "1")
          const EhLeaderboardPage(),
        if(appdata.settings[21][2] == "1")
          const JmLeaderboardPage(),
        if(appdata.settings[21][3] == "1")
          const HitomiLeaderboardPage()
      ],),
    )));
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
                    return PicComicTile(leaderBoardLogic.comics[i]);
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
          network.status?network.message:"网络错误",
          () => leaderBoardLogic.change(),
          context,
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
                    return PicComicTile(leaderBoardLogic.comics[i]);
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
            network.status?network.message:"网络错误",
                () => leaderBoardLogic.change(),
            context,
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
                    return PicComicTile(leaderBoardLogic.comics[i]);
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
            network.status?network.message:"网络错误",
                () => leaderBoardLogic.change(),
            context,
            showBack: false
        );
      }
    });
  }
}