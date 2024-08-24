import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/pages/ranking_page.dart';
import 'package:pica_comic/pages/search_result_page.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'package:pica_comic/pages/category_comics_page.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/translations.dart';

class AllCategoryPage extends StatelessWidget {
  const AllCategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StateBuilder<SimpleController>(
        tag: "category",
        init: SimpleController(),
        builder: (controller) {
          final categories = appdata.appSettings.categoryPages;
          return Material(
            child: DefaultTabController(
              length: categories.length,
              key: Key(appdata.appSettings.categoryPages.toString()),
              child: Column(
                children: [
                  FilledTabBar(
                    tabs: categories.map((e) {
                      String title = e;
                      try {
                        title = getCategoryDataWithKey(e).title;
                      } catch (e) {
                        //
                      }
                      return Tab(
                        text: title,
                        key: Key(e),
                      );
                    }).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                        children:
                            categories.map((e) => CategoryPage(e)).toList()),
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
  const CategoryPage(this.category, {super.key});

  final String category;

  CategoryData get data => getCategoryDataWithKey(category);

  String findComicSourceKey() {
    for (var source in ComicSource.sources) {
      if (source.categoryData?.key == category) {
        return source.key;
      }
    }
    return "";
  }

  void handleClick(
    String tag,
    String? param,
    String type,
    String namespace,
    String categoryKey,
  ) {
    if (type == 'search') {
      App.mainNavigatorKey?.currentContext?.to(
        () => SearchResultPage(
          keyword: tag,
          options: const [],
          sourceKey: findComicSourceKey(),
        ),
      );
    } else if (type == "search_with_namespace") {
      if (tag.contains(" ")) {
        tag = '"$tag"';
      }
      App.mainNavigatorKey?.currentContext?.to(
        () => SearchResultPage(
          keyword: "$namespace:$tag",
          options: const [],
          sourceKey: findComicSourceKey(),
        ),
      );
    } else if (type == "category") {
      App.mainNavigatorKey!.currentContext!.to(
        () => CategoryComicsPage(
          category: tag,
          categoryKey: categoryKey,
          param: param,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];
    if (data.enableRankingPage || data.buttons.isNotEmpty) {
      children.add(buildTitle(data.title));
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
        child: Wrap(
          children: [
            if (data.enableRankingPage)
              buildTag("排行榜".tl, (p0, p1) {
                context.to(() => RankingPage(sourceKey: findComicSourceKey()));
              }),
            for(var buttonData in data.buttons)
              buildTag(buttonData.label.tl, (p0, p1) => buttonData.onTap())
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
                  key,
                  param,
                  part.categoryType,
                  part.title,
                  category,
                ),
              )
            ],
          );
        }));
      } else {
        children.add(buildTitle(part.title));
        children.add(
          buildTagsWithParams(
            part.categories,
            part.categoryParams,
            part.title,
            (tag, param) => handleClick(
              tag,
              param,
              part.categoryType,
              part.title,
              data.key,
            ),
          ),
        );
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
      child: Text(title.tl,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
    );
  }

  Widget buildTitleWithRefresh(String title, void Function() onRefresh) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
      child: Row(
        children: [
          Text(
            title.tl,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh))
        ],
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
          (index) => buildTag(
            tags[index],
            onClick,
            namespace,
            params?.elementAtOrNull(index),
          ),
        ),
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
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        onTap: () => onClick(tag, param),
        child: Builder(
          builder: (context) {
            return Material(
              elevation: 1,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              color: context.colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(translateTag(tag)),
              ),
            );
          },
        ),
      ),
    );
  }

  bool get enableTranslation => App.locale.languageCode == 'zh';
}
