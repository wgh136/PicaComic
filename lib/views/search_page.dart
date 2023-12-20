import 'package:flutter/material.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../foundation/app.dart';
import '../foundation/def.dart';
import '../foundation/pair.dart';
import '../tools/tags_translation.dart';

class SearchPage extends StatefulWidget {
  const SearchPage(
      {required this.controller,
      this.onPop,
      this.onSearch,
      this.type,
      super.key});

  final TextEditingController controller;

  final void Function()? onPop;

  final void Function(String)? onSearch;

  final ComicType? type;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _focusNode = FocusNode();

  void search() {
    widget.onSearch?.call(widget.controller.text);
  }

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 200), _focusNode.requestFocus);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: search,
        child: const Icon(Icons.search),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 0.8))),
            child: Row(
              children: [
                Tooltip(
                  message: "Back",
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_sharp),
                    onPressed: () {
                      App.back(context);
                      widget.onPop?.call();
                    },
                  ),
                ),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: widget.controller,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: "Search"),
                    onSubmitted: (s) => search(),
                    onChanged: (s) => setState(() {}),
                  ),
                ),
                if(widget.controller.text.isNotEmpty)
                  Tooltip(
                    message: "clear",
                    child: IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: (){
                        setState(() {
                          widget.controller.text = "";
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: buildSuggestions(context),
          )
        ],
      ),
    );
  }

  Widget buildSuggestions(BuildContext context) {
    bool check(String text, String key, String value) {
      if (text.removeAllBlank == "") {
        return false;
      }
      if (key.length >= text.length && key.substring(0, text.length) == text ||
          (key.contains(" ") &&
              key.split(" ").last.length >= text.length &&
              key.split(" ").last.substring(0, text.length) == text)) {
        return true;
      } else if (value.length >= text.length && value.contains(text)) {
        return true;
      }
      return false;
    }

    final controller = widget.controller;

    final comicType = widget.type;

    void onSelected(String text, TranslationType? type) {
      var words = controller.text.split(" ");
      if (words.length >= 2 &&
          check("${words[words.length - 2]} ${words[words.length - 1]}", text,
              text.translateTagsToCN)) {
        controller.text = controller.text.replaceLast(
            "${words[words.length - 2]} ${words[words.length - 1]}", "");
      } else {
        controller.text =
            controller.text.replaceLast(words[words.length - 1], "");
      }
      if (text.contains(" ")) {
        if (comicType == ComicType.hitomi && ["male", "female", "language"].contains(type?.name)) {
          text = text.replaceAll(" ", '_');
          text = "${type?.name}:$text";
        } else {
          text = "\"$text\"";
        }
      }
      if (comicType == ComicType.ehentai) {
        if (type != null) {
          controller.text += "${type.name}:$text ";
        } else {
          controller.text += "$text ";
        }
      } else {
        controller.text += "$text ";
      }
      _focusNode.requestFocus();
      setState(() {});
    }

    Widget body;

    if (controller.text.removeAllBlank.isEmpty) {
      body = const SizedBox(
        height: 0,
      );
    } else {
      var text = controller.text.split(" ").last;
      var suggestions = <Pair<String, TranslationType>>[];

      void find(Map<String, String> map, TranslationType type) {
        for (var element in map.entries) {
          if (suggestions.length > 200) {
            break;
          }
          if (check(text, element.key, element.value)) {
            suggestions.add(Pair(element.key, type));
          }
        }
      }

      find(TagsTranslation.femaleTags, TranslationType.female);
      find(TagsTranslation.maleTags, TranslationType.male);
      find(TagsTranslation.parodyTags, TranslationType.parody);
      find(TagsTranslation.characterTranslations, TranslationType.character);
      find(TagsTranslation.otherTags, TranslationType.other);
      find(TagsTranslation.mixedTags, TranslationType.mixed);
      find(TagsTranslation.languageTranslations, TranslationType.language);
      find(TagsTranslation.artistTags, TranslationType.artist);
      find(TagsTranslation.groupTags, TranslationType.group);
      find(TagsTranslation.cosplayerTags, TranslationType.cosplayer);

      bool showMethod = MediaQuery.of(context).size.width < 600;
      Widget buildItem(Pair<String, TranslationType> value) {
        var subTitle = TagsTranslation.translationTagWithNamespace(
            value.left, value.right.name);
        return ListTile(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value.left),
              if (!showMethod)
                const SizedBox(
                  width: 12,
                ),
              if (!showMethod)
                Text(
                  subTitle,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline),
                )
            ],
          ),
          subtitle: showMethod ? Text(subTitle) : null,
          trailing: Text(
            value.right.name,
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () => onSelected(value.left, value.right),
        );
      }

      body = ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: suggestions.length,
        itemBuilder: (context, index) => buildItem(suggestions[index]),
      );
    }
    return body;
  }
}
