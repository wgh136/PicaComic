import 'package:flutter/material.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/category_page.dart';
import 'package:pica_comic/views/pic_views/category_comic_page.dart';
import 'package:pica_comic/views/pic_views/collections_page.dart';
import 'package:pica_comic/views/pic_views/picacg_latest_page.dart';
import 'package:pica_comic/views/pic_views/picacg_leaderboard_page.dart';
import 'package:pica_comic/tools/translations.dart';


class CategoriesPage extends StatelessWidget with CategoryPageBuilder{
  const CategoriesPage({super.key});

  static const categories = ["大家都在看", "大濕推薦", "那年今天", "官方都在看",
    "嗶咔漢化", "全彩", "長篇", "同人", "短篇", "圓神領域", "碧藍幻想", "CG雜圖",
    "英語 ENG", "生肉", "純愛", "百合花園", "耽美花園", "偽娘哲學", "後宮閃光",
    "扶他樂園", "單行本", "姐姐系", "妹妹系", "SM", "性轉換", "足の恋", "人妻",
    "NTR", "強暴", "非人類", "艦隊收藏", "Love Live", "SAO 刀劍神域", "Fate",
    "東方", "WEBTOON", "禁書目錄", "歐美", "Cosplay", "重口地帶"];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitle("Picacg".tl),
          buildTags(["本子妹/本子母推荐".tl, "最新漫画".tl, "排行榜".tl], "basic"),
          buildTitle("分类".tl),
          buildTags(categories, "category"),
        ],
      ),
    );
  }

  @override
  void handleClick(String tag, String? namespace) {
    if(namespace == "category"){
      MainPage.to(() => CategoryComicPage(tag, categoryType: 1,));
    } else if(namespace == "basic"){
      if(tag == "本子妹/本子母推荐".tl){
        MainPage.to(() => const CollectionsPage());
      } else if(tag == "最新漫画".tl){
        MainPage.to(() => const PicacgLatestPage());
      } else {
        MainPage.to(() => const PicacgLeaderboardPage());
      }
    }
  }
}
