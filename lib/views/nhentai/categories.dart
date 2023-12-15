import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/page_template/category_page.dart';
import '../../network/nhentai_network/tags.dart';
import '../main_page.dart';

class NhentaiCategories extends StatefulWidget {
  const NhentaiCategories({super.key});

  @override
  State<NhentaiCategories> createState() => _NhentaiCategoriesState();
}

class _NhentaiCategoriesState extends State<NhentaiCategories>
    with CategoryPageBuilder {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTitle("随机".tl),
          buildTags(["随机".tl]),
          buildTitle("语言".tl),
          buildTags(["chinese", "japanese", "english"]),
          buildTitle("长度".tl),
          buildTags(
              ["1-25", "25-75", "75-150", "150-500", "500-1000", ">1000"]),
          buildTitleWithRefresh("Tags", () => setState(() {})),
          buildTags(generateTags()),
        ],
      ),
    );
  }

  List<String> generateTags() {
    var res = <String>[];
    var tags = nhentaiTags.values.toList();
    var start = Random().nextInt(tags.length - 100);
    while (res.length < 100) {
      res.add(tags[start]);
      start++;
    }
    return res;
  }

  @override
  void handleClick(String tag, [String? namespace]) {
    if (tag == "随机".tl) {
      MainPage.to(() => const NhentaiComicPage(""));
    } else if (["chinese", "japanese", "english"].contains(tag)) {
      MainPage.to(() => NhentaiSearchPage("language:$tag"));
    } else if (tag.nums.isNotEmpty) {
      if (tag.contains('>')) {
        MainPage.to(() => NhentaiSearchPage("pages:>${tag.nums}"));
      } else {
        var splits = tag.split('-');
        MainPage.to(
            () => NhentaiSearchPage("pages:>${splits[0]} pages:<${splits[1]}"));
      }
    } else {
      if (tag.contains(' ')) {
        tag = "\"$tag\"";
      }
      MainPage.to(() => NhentaiSearchPage(tag));
    }
  }
}
