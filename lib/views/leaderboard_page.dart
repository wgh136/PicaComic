import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/base.dart';
import 'package:pica_comic/views/widgets.dart';



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
        body: TabBarView(
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
  final leaderBoardLogic = Get.put(LeaderBoardH24Logic());
  LeaderBoardH24({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderBoardH24Logic>(builder: (leaderBoardLogic){
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
                maxCrossAxisExtent: 600,
                childAspectRatio: 5,
              ),
            )
          ],
        );
      }else{
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height/2-80,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.error_outline,size:60,),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height/2-10,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("网络错误"),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/2+20,
              left: MediaQuery.of(context).size.width/2-50,
              child: SizedBox(
                width: 100,
                height: 40,
                child: FilledButton(
                  onPressed: (){
                    leaderBoardLogic.change();
                  },
                  child: const Text("重试"),
                ),
              ),
            ),
          ],
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
  final leaderBoardLogic = Get.put(LeaderBoardD7Logic());
  LeaderBoardD7({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderBoardD7Logic>(builder: (leaderBoardLogic){
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
                maxCrossAxisExtent: 600,
                childAspectRatio: 5,
              ),
            )
          ],
        );
      }else{
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height/2-80,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.error_outline,size:60,),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height/2-10,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("网络错误"),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/2+20,
              left: MediaQuery.of(context).size.width/2-50,
              child: SizedBox(
                width: 100,
                height: 40,
                child: FilledButton(
                  onPressed: (){
                    leaderBoardLogic.change();
                  },
                  child: const Text("重试"),
                ),
              ),
            ),
          ],
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
  final leaderBoardLogic = Get.put(LeaderBoardD30Logic());
  LeaderBoardD30({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderBoardD30Logic>(builder: (leaderBoardLogic){
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
                maxCrossAxisExtent: 600,
                childAspectRatio: 5,
              ),
            )
          ],
        );
      }else{
        return Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height/2-80,
              left: 0,
              right: 0,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Icon(Icons.error_outline,size:60,),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.of(context).size.height/2-10,
              child: const Align(
                alignment: Alignment.topCenter,
                child: Text("网络错误"),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height/2+20,
              left: MediaQuery.of(context).size.width/2-50,
              child: SizedBox(
                width: 100,
                height: 40,
                child: FilledButton(
                  onPressed: (){
                    leaderBoardLogic.change();
                  },
                  child: const Text("重试"),
                ),
              ),
            ),
          ],
        );
      }
    });
  }
}