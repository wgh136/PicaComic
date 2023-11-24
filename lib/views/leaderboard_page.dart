import 'package:flutter/material.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/eh_views/eh_leaderboard.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_leaderboard_page.dart';
import 'package:pica_comic/views/jm_views/jm_leaderboard.dart';
import 'package:pica_comic/views/pic_views/picacg_leaderboard_page.dart';

class LeaderboardPageLogic extends StateController {}

class LeaderBoardPage extends StatefulWidget {
  const LeaderBoardPage({Key? key}) : super(key: key);

  @override
  State<LeaderBoardPage> createState() => _LeaderBoardPageState();
}

class _LeaderBoardPageState extends State<LeaderBoardPage> {
  final logic = StateController.put(EhLeaderboardLogic());
  final logic5 = StateController.put(HitomiLeaderboardPageLogic());
  final logic6 = StateController.put(LeaderboardPageLogic());

  @override
  void initState() {
    PicacgLeaderboardPage.createState();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int pages = int.parse(appdata.settings[21][0]) +
        int.parse(appdata.settings[21][1]) +
        int.parse(appdata.settings[21][2]) +
        int.parse(appdata.settings[21][3]);
    if(pages == 0){
      return Center(
        child: Text("无数据".tl),
      );
    }

    return StateBuilder<LeaderboardPageLogic>(
        builder: (logic) => DefaultTabController(
            length: pages,
            child: Column(
              children: [
                TabBar(
                  splashBorderRadius:
                  const BorderRadius.all(Radius.circular(10)),
                  tabs: [
                    if (appdata.settings[21][0] == "1")
                      const Tab(
                        text: "Picacg",
                      ),
                    if (appdata.settings[21][1] == "1")
                      const Tab(
                        text: "E-Hentai",
                      ),
                    if (appdata.settings[21][2] == "1")
                      const Tab(
                        text: "JmComic",
                      ),
                    if (appdata.settings[21][3] == "1")
                      const Tab(
                        text: "Hitomi",
                      ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      if (appdata.settings[21][0] == "1")
                        const PicacgLeaderboardPage(),
                      if (appdata.settings[21][1] == "1") const EhLeaderboardPage(),
                      if (appdata.settings[21][2] == "1") const JmLeaderboardPage(),
                      if (appdata.settings[21][3] == "1")
                        const HitomiLeaderboardPage()
                    ],
                  )
                )
              ],
            )));
  }
}
