import 'package:flutter/material.dart';
import 'package:pica_comic/views/ht_views/ht_comic_list.dart';
import '../main_page.dart';

class HtCategoriesPage extends StatelessWidget {
  const HtCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitle("最新"),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: buildTag("最新漫画", "/albums.html"),
          ),
          buildTitle("同人志"),
          buildTags([
            "同人志",
            "同人志-汉化",
            "同人志-日语",
            "同人志-English",
            "同人志-CG画集",
            "同人志-3D漫画",
            "同人志-Cosplay"
          ], [
            "/albums-index-cate-5.html",
            "/albums-index-cate-1.html",
            "/albums-index-cate-12.html",
            "/albums-index-cate-16.html",
            "/albums-index-cate-2.html",
            "/albums-index-cate-22.html",
            "/albums-index-cate-3.html",
          ]),
          buildTitle("单行本"),
          buildTags([
            "单行本",
            "单行本-汉化",
            "单行本-日语",
            "单行本-English"
          ], [
            "/albums-index-cate-6.html",
            "/albums-index-cate-9.html",
            "/albums-index-cate-13.html",
            "/albums-index-cate-17.html",
          ]),
          buildTitle("杂志&短篇"),
          buildTags([
            "杂志&短篇",
            "杂志&短篇-汉化",
            "杂志&短篇-日语",
            "杂志&短篇-English"
          ], [
            "/albums-index-cate-7.html",
            "/albums-index-cate-10.html",
            "/albums-index-cate-14.html",
            "/albums-index-cate-18.html",
          ]),
          buildTitle("韩漫"),
          buildTags([
            "韩漫",
            "韩漫-汉化",
            "韩漫-其它"
          ], [
            "/albums-index-cate-19.html",
            "/albums-index-cate-20.html",
            "/albums-index-cate-21.html",
          ]),
        ],
      ),
    );
  }

  Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
      child: Text(title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
    );
  }

  Widget buildTags(List<String> tags, List<String> urls) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
        child: Wrap(
          children: List<Widget>.generate(
            tags.length,
            (index) => buildTag(tags[index], urls[index]),
          ),
        ));
  }

  Widget buildTag(String tag, String url) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => MainPage.to(() => HtComicList(name: tag, url: url)),
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
