import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import '../../network/nhentai_network/tags.dart';
import '../main_page.dart';


class NhentaiCategories extends StatelessWidget {
  const NhentaiCategories({super.key});

  bool get enableTranslation => PlatformDispatcher.instance.locale.languageCode == 'zh';

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
          buildTags(["1-25", "25-75", "75-150", "150-500", "500-1000", ">1000"]),
          buildTitle("Tags".tl),
          buildTags(nhentaiTags.values.toList().sublist(0,200)),
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
        onTap: () => handleClick(tag),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(enableTranslation ? tag.translateTagsToCN : tag),
          ),
        ),
      ),
    );
  }

  void handleClick(String tag){
    if(tag == "随机".tl) {
      MainPage.to(() => const NhentaiComicPage(""));
    }
    else if(["chinese", "japanese", "english"].contains(tag)){
      MainPage.to(() => NhentaiSearchPage("language:$tag"));
    }else if(tag.nums.isNotEmpty){
      if(tag.contains('>')){
        MainPage.to(() => NhentaiSearchPage("pages:>${tag.nums}"));
      }else{
        var splits = tag.split('-');
        MainPage.to(() => NhentaiSearchPage("pages:>${splits[0]} pages:<${splits[1]}"));
      }
    }else{
      MainPage.to(() => NhentaiSearchPage(tag));
    }
  }
}
