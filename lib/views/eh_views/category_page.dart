import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/category_page.dart';

class EhCategoryPage extends StatelessWidget with CategoryPageBuilder{
  const EhCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          buildItem("Male", TagsTranslation.maleTags),
          buildItem("Female", TagsTranslation.femaleTags),
          buildItem("Parody", TagsTranslation.parodyTags),
          buildItem("Character", TagsTranslation.characterTranslations),
          buildItem("Mixed", TagsTranslation.mixedTags),
          buildItem("Artist", TagsTranslation.artistTags),
          buildItem("Group", TagsTranslation.groupTags),
          buildItem("Cosplayer", TagsTranslation.cosplayerTags),
          buildItem("Other", TagsTranslation.otherTags),
        ],
      ),
    );
  }

  Widget buildItem(String title, Map<String, String> tagsWithTranslation){
    return StatefulBuilder(builder: (context, stateUpdater) {
      var res = <String>[];
      var tags = tagsWithTranslation.keys.toList();
      if(tags.length <= 20){
        res.addAll(tags);
      } else {
        var start = Random().nextInt(tags.length - 20);
        while(res.length < 20){
          res.add(tags[start]);
          start++;
        }
      }
      return SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: buildTitleAndTags(title, res, () => stateUpdater((){})),
        ),
      );
    });
  }

  @override
  void handleClick(String tag, [String? namespace]) {
    var keyword = "";
    if(namespace != null){
      keyword += namespace;
      keyword += ":";
    }
    if(tag.contains(" ")){
      tag = "\"$tag\"";
    }
    keyword += tag;
    MainPage.to(() => EhSearchPage(keyword));
  }
}
