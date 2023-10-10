import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import '../../foundation/app.dart';
import '../../network/picacg_network/methods.dart';
import '../../network/picacg_network/models.dart';
import '../widgets/show_error.dart';
import 'package:pica_comic/tools/translations.dart';

class PicacgLeaderboardPageLogic extends GetxController{
  bool loading = true;
  List<ComicItemBrief>? comics;
  String? message;

  void get(String time) async{
    var res = await network.getLeaderboard(time);
    if(res.error){
      message = res.errorMessage;
    }else{
      comics = res.data;
    }
    loading = false;
    update();
  }

  void refresh_(){
    message = null;
    comics = null;
    loading = true;
    update();
  }
}

class OnePicacgLeaderboardPage extends StatelessWidget {
  const OnePicacgLeaderboardPage(this.time, {super.key});
  final String time;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PicacgLeaderboardPageLogic>(
        tag: time,
        builder: (logic){
          if(logic.loading){
            logic.get(time);
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(logic.comics != null){
            return CustomScrollView(
              slivers: [
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      childCount: logic.comics!.length,
                          (context, i){
                        return PicComicTile(logic.comics![i]);
                      }
                  ),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: App.comicTileMaxWidth,
                    childAspectRatio: App.comicTileAspectRatio,
                  ),
                )
              ],
            );
          }else{
            return showNetworkError(
                logic.message??"未知错误".tl,
                    () => logic.refresh_(),
                context,
                showBack: false
            );
          }
        });
  }
}

class PicacgLeaderboardPage extends StatelessWidget{
  const PicacgLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Tab> tabs = <Tab>[
      Tab(text: '24小时'.tl),
      Tab(text: '7天'.tl),
      Tab(text: '30天'.tl),
    ];
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(tabs: tabs, splashBorderRadius: const BorderRadius.all(Radius.circular(10)),),
          const Expanded(child: TabBarView(
              children: [
                OnePicacgLeaderboardPage("H24"),
                OnePicacgLeaderboardPage("D7"),
                OnePicacgLeaderboardPage("D30")
              ]
          ))
        ],
      ),
    );
  }

  static createState(){
    Get.put(PicacgLeaderboardPageLogic(), tag: "H24");
    Get.put(PicacgLeaderboardPageLogic(), tag: "D7");
    Get.put(PicacgLeaderboardPageLogic(), tag: "D30");
  }
}