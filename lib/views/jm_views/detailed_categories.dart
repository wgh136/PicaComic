import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';

class JmDetailedCategoriesPage extends StatelessWidget {
  const JmDetailedCategoriesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Divider(),
          buildTitle("角色扮演"),
          buildTags(
              ['御姐', '熟女', '巨乳', '貧乳', '女性支配', '教師', '女僕', '護士', '泳裝', '眼鏡', '連褲襪', '其他制服', '兔女郎']),
          const Divider(),
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
          const Divider(),
          buildTitle("其它"),
          buildTags(['CG', '重口', '獵奇', '非H', '血腥暴力', '站長推薦']),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 50,
          )
        ],
      ),
    );
  }

  Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
    );
  }

  Widget buildTags(List<String> tags) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Wrap(
        children: List<Widget>.generate(tags.length, (index) => buildTag(tags[index])),
      ),
    );
  }

  Widget buildTag(String tag) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => Get.to(() => JmSearchPage(tag)),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(tag),
          ),
        ),
      ),
    );
  }
}
