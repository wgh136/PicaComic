import 'package:flutter/material.dart';
import 'package:pica_comic/views/jm_views/jm_comics_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_week_recommendation_page.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/page_template/category_page.dart';
import '../main_page.dart';

class JmDetailedCategoriesPage extends StatelessWidget
    with CategoryPageBuilder {
  const JmDetailedCategoriesPage({Key? key}) : super(key: key);

  static const mainCategories = {
    "同人": "/albums/doujin",
    "單本": "/albums/single",
    "短篇": "/albums/short",
    "其他類": "/albums/another",
    "韓漫": "/albums/hanman",
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitle("每周必看".tl),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: SizedBox(
              width: 200,
              height: 50,
              child: InkWell(
                onTap: () => MainPage.to(() => JmWeekRecommendationPage()),
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 8,
                      ),
                      const Icon(Icons.book_outlined),
                      const SizedBox(
                        width: 16,
                      ),
                      Text("每周必看".tl),
                    ],
                  ),
                ),
              ),
            ),
          ),
          buildTitle("成人A漫"),
          buildTags(mainCategories.keys.toList()),
          buildTitle("主題A漫"),
          buildTags([
            '無修正',
            '劇情向',
            '青年漫',
            '校服',
            '純愛',
            '人妻',
            '教師',
            '百合',
            'Yaoi',
            '性轉',
            'NTR',
            '女裝',
            '癡女',
            '全彩',
            '女性向',
            '完結',
            '純愛',
            '禁漫漢化組'
          ]),
          buildTitle("角色扮演"),
          buildTags([
            '御姐',
            '熟女',
            '巨乳',
            '貧乳',
            '女性支配',
            '教師',
            '女僕',
            '護士',
            '泳裝',
            '眼鏡',
            '連褲襪',
            '其他制服',
            '兔女郎'
          ]),
          buildTitle("特殊PLAY"),
          buildTags([
            '群交',
            '足交',
            '束縛',
            '肛交',
            '阿黑顏',
            '藥物',
            '扶他',
            '調教',
            '野外露出',
            '催眠',
            '自慰',
            '觸手',
            '獸交',
            '亞人',
            '怪物女孩',
            '皮物',
            'ryona',
            '騎大車'
          ]),
          buildTitle("其它"),
          buildTags(['CG', '重口', '獵奇', '非H', '血腥暴力', '站長推薦']),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 50,
          )
        ],
      ),
    );
  }

  @override
  void handleClick(String tag, [String? namespace]) {
    if(mainCategories[tag] != null){
      MainPage.to(() => JmComicsPage(tag, mainCategories[tag]!));
    } else {
      MainPage.to(() => JmSearchPage(tag));
    }
  }
}
