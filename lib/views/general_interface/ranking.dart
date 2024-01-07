import 'package:pica_comic/views/eh_views/eh_leaderboard.dart';
import 'package:pica_comic/views/jm_views/jm_leaderboard.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pic_views/picacg_leaderboard_page.dart';

void toRankingPage(String key) {
  switch (key) {
    case "picacg":
      MainPage.to(() => const PicacgLeaderboardPage());
    case "ehentai":
      MainPage.to(() => const EhLeaderboardPage());
    case "jm":
      MainPage.to(() => const JmLeaderboardPage());
  }
}
