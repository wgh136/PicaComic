import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/tags_translation.dart';

abstract mixin class CategoryPageBuilder {
  void handleClick(String tag, String? namespace);

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
          Text(title.translateTagsCategoryToCN,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          const Spacer(),
          IconButton(onPressed: onRefresh, icon: const Icon(Icons.refresh))
        ],
      ),
    );
  }

  Widget buildTags(List<String> tags, [String? namespace]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
      child: Wrap(
        children: List<Widget>.generate(
            tags.length, (index) => buildTag(tags[index], namespace)),
      ),
    );
  }

  Widget buildTag(String tag, [String? namespace]) {
    String translateTag(String tag){
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
        onTap: () => handleClick(tag, namespace),
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

  List<Widget> buildTitleAndTags(String title, List<String> tags,
      [void Function()? onRefresh]) {
    return [
      if (onRefresh == null)
        buildTitle(title)
      else
        buildTitleWithRefresh(title, onRefresh),
      buildTags(tags, title.toLowerCase()),
    ];
  }

  bool get enableTranslation =>
      PlatformDispatcher.instance.locale.languageCode == 'zh';
}
