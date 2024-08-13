import 'package:pica_comic/network/nhentai_network/tags.dart';
import 'package:pica_comic/tools/tags_translation.dart';

import 'comic_source.dart';

const CategoryData picacgCategory = CategoryData(
    title: "Picacg",
    key: "picacg",
    categories: [
      FixedCategoryPart(
          "分类",
          [
            "大家都在看",
            "大濕推薦",
            "那年今天",
            "官方都在看",
            "嗶咔漢化",
            "全彩",
            "長篇",
            "同人",
            "短篇",
            "圓神領域",
            "碧藍幻想",
            "CG雜圖",
            "英語 ENG",
            "生肉",
            "純愛",
            "百合花園",
            "耽美花園",
            "偽娘哲學",
            "後宮閃光",
            "扶他樂園",
            "單行本",
            "姐姐系",
            "妹妹系",
            "SM",
            "性轉換",
            "足の恋",
            "人妻",
            "NTR",
            "強暴",
            "非人類",
            "艦隊收藏",
            "Love Live",
            "SAO 刀劍神域",
            "Fate",
            "東方",
            "WEBTOON",
            "禁書目錄",
            "歐美",
            "Cosplay",
            "重口地帶"
          ],
          "category"),
    ], enableRankingPage: false);

CategoryData ehCategory = CategoryData(
    title: "ehentai",
    key: "ehentai",
    categories: [
      RandomCategoryPartWithRuntimeData(
          "male",
          () => TagsTranslation.maleTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "female",
          () => TagsTranslation.femaleTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "parody",
          () => TagsTranslation.parodyTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "character",
          () => TagsTranslation.characterTranslations.keys.toList(),
          20,
          "search"),
      RandomCategoryPartWithRuntimeData(
          "mixed",
          () => TagsTranslation.mixedTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "artist",
          () => TagsTranslation.artistTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "group",
          () => TagsTranslation.groupTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "cosplayer",
          () => TagsTranslation.cosplayerTags.keys.toList(),
          20,
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "other",
          () => TagsTranslation.otherTags.keys.toList(),
          20,
          "search_with_namespace"),
    ],
    enableRankingPage: true,);

const CategoryData jmCategory = CategoryData(
    title: "禁漫天堂",
    key: "jm",
    categories: [
      FixedCategoryPart(
          "成人A漫",
          [
            "最新A漫",
            "同人",
            "單本",
            "短篇",
            "其他類",
            "韓漫",
            "美漫",
            "Cosplay",
            "3D",
            "禁漫漢化組"
          ],
          "category",
          [
            "0",
            "doujin",
            "single",
            "short",
            "another",
            "hanman",
            "meiman",
            "another_cosplay",
            "3D",
            "禁漫漢化組"
          ]),
      FixedCategoryPart(
          "主題A漫",
          [
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
          ],
          "search"),
      FixedCategoryPart(
          "角色扮演",
          [
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
          ],
          "search"),
      FixedCategoryPart(
          "特殊PLAY",
          [
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
          ],
          "search"),
      FixedCategoryPart(
          "其它", ['CG', '重口', '獵奇', '非H', '血腥暴力', '站長推薦'], "search"),
    ],
    enableRankingPage: true,);

const CategoryData htCategory = CategoryData(
    title: "绅士漫画",
    key: "htmanga",
    categories: [
      FixedCategoryPart("最新", ["最新漫画"], "category", ["/albums.html"]),
      FixedCategoryPart(
          "同人志",
          [
            "同人志",
            "同人志-汉化",
            "同人志-日语",
            "同人志-English",
            "同人志-CG画集",
            "同人志-3D漫画",
            "同人志-Cosplay"
          ],
          "category",
          [
            "/albums-index-cate-5.html",
            "/albums-index-cate-1.html",
            "/albums-index-cate-12.html",
            "/albums-index-cate-16.html",
            "/albums-index-cate-2.html",
            "/albums-index-cate-22.html",
            "/albums-index-cate-3.html",
          ]),
      FixedCategoryPart(
          "单行本",
          ["单行本", "单行本-汉化", "单行本-日语", "单行本-English"],
          "category",
          [
            "/albums-index-cate-6.html",
            "/albums-index-cate-9.html",
            "/albums-index-cate-13.html",
            "/albums-index-cate-17.html",
          ]),
      FixedCategoryPart(
          "杂志&短篇",
          ["杂志&短篇", "杂志&短篇-汉化", "杂志&短篇-日语", "杂志&短篇-English"],
          "category",
          [
            "/albums-index-cate-7.html",
            "/albums-index-cate-10.html",
            "/albums-index-cate-14.html",
            "/albums-index-cate-18.html",
          ]),
      FixedCategoryPart(
          "韩漫",
          ["韩漫", "韩漫-汉化", "韩漫-其它"],
          "category",
          [
            "/albums-index-cate-19.html",
            "/albums-index-cate-20.html",
            "/albums-index-cate-21.html",
          ]),
    ],
    enableRankingPage: false,);

final nhCategory = CategoryData(
    title: "nhentai",
    key: "nhentai",
    categories: [
      const FixedCategoryPart("language", ["chinese", "japanese", "english"],
          "search_with_namespace"),
      RandomCategoryPartWithRuntimeData(
          "Tags", () => nhentaiTags.values.toList(), 50, "search"),
    ],
    enableRankingPage: false);
