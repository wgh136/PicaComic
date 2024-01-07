import 'package:pica_comic/comic_source/category.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/views/general_interface/category.dart';
import 'package:pica_comic/views/general_interface/random.dart';
import 'package:pica_comic/views/general_interface/ranking.dart';
import 'package:pica_comic/views/general_interface/recommendation.dart';
import 'package:pica_comic/views/general_interface/search.dart';
import '../base.dart';
import 'package:pica_comic/tools/translations.dart';

class AllCategoryPage extends StatelessWidget {
  const AllCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StateBuilder<SimpleController>(
        tag: "category",
        builder: (controller) {
          final categories = appdata.settings[67].split(',').map((e) => getCategoryDataWithKey(e));
          return Material(
            child: DefaultTabController(
              length: categories.length,
              key: Key(appdata.settings[67]),
              child: Column(
                children: [
                  TabBar.secondary(
                    splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
                    tabs: [
                      for (var c in categories)
                        Tab(
                          text: c.title,
                          key: Key(c.key),
                        )
                    ],
                    isScrollable: true,
                    tabAlignment: TabAlignment.center,
                  ),
                  Expanded(
                    child: TabBarView(
                        children: [for (var c in categories) CategoryPage(c)]),
                  )
                ],
              ),
            ),
          );
        });
  }
}

typedef ClickTagCallback = void Function(String, String?);

class CategoryPage extends StatelessWidget {
  const CategoryPage(this.data, {super.key});

  final CategoryData data;

  void handleClick(
      String tag, String? param, String type, String namespace, String key) {
    if (type == 'search') {
      toSearchPage(key, tag);
    } else if (type == "search_with_namespace") {
      if (tag.contains(" ")) {
        tag = '"$tag"';
      }
      toSearchPage(key, "$namespace:$tag");
    } else if (type == "category") {
      toCategoryPage(key, tag, param);
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    if (data.enableRandomPage ||
        data.enableRandomPage ||
        data.enableRankingPage) {
      children.add(buildTitle(data.title));
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
        child: Wrap(
          children: [
            if (data.enableRandomPage)
              buildTag("随机".tl, (p0, p1) => randomComic(data.key)),
            if (data.enableRankingPage)
              buildTag("排行榜".tl, (p0, p1) => toRankingPage(data.key)),
            if (data.enableSuggestionPage)
              buildTag(data.recommendPageName.tl,
                  (p0, p1) => buildRecommendation(data.key))
          ],
        ),
      ));
    }
    for (var part in data.categories) {
      if (part.enableRandom) {
        children.add(StatefulBuilder(builder: (context, updater) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTitleWithRefresh(part.title, () => updater(() {})),
              buildTagsWithParams(
                  part.categories,
                  part.categoryParams,
                  part.title,
                  (key, param) => handleClick(
                      key, param, part.categoryType, part.title, data.key))
            ],
          );
        }));
      } else {
        children.add(buildTitle(part.title));
        children.add(buildTagsWithParams(
            part.categories,
            part.categoryParams,
            part.title,
            (tag, param) => handleClick(
                tag, param, part.categoryType, part.title, data.key)));
      }
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
      child: Text(title.translateTagsCategoryToCN,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
    );
  }

  Widget buildTitleWithRefresh(String title, void Function() onRefresh) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
      child: Row(
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const Spacer(),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh))
        ],
      ),
    );
  }

  Widget buildTags(List<String> tags, ClickTagCallback onClick,
      [String? namespace]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Wrap(
        children: List<Widget>.generate(
            tags.length, (index) => buildTag(tags[index], onClick, namespace)),
      ),
    );
  }

  Widget buildTagsWithParams(
    List<String> tags,
    List<String>? params,
    String? namespace,
    ClickTagCallback onClick,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Wrap(
        children: List<Widget>.generate(
            tags.length,
            (index) => buildTag(tags[index], onClick, namespace,
                params?.elementAtOrNull(index))),
      ),
    );
  }

  Widget buildTag(String tag, ClickTagCallback onClick,
      [String? namespace, String? param]) {
    String translateTag(String tag) {
      if (enableTranslation) {
        if (namespace != null) {
          tag = TagsTranslation.translationTagWithNamespace(tag, namespace);
        } else {
          tag = tag.translateTagsToCN;
        }
      }
      return tag;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => onClick(tag, param),
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(translateTag(tag)),
          ),
        ),
      ),
    );
  }

  bool get enableTranslation => App.locale.languageCode == 'zh';
}
