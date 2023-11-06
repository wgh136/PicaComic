import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/pair.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/pic_views/search_page.dart';
import 'package:pica_comic/views/widgets/custom_chips.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'jm_views/jm_comic_page.dart';
import 'main_page.dart';

typedef FilterChip = CustomFilterChip;

class _FloatingSearchBar extends StatelessWidget {
  const _FloatingSearchBar(
      {Key? key,
      required this.supportingText,
      required this.f,
      required this.controller,
      this.onChanged,
      this.focusNode})
      : super(key: key);

  final double height = 56;
  double get effectiveHeight {
    return max(height, 53);
  }

  final void Function(String) f;
  final String supportingText;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    var padding = 16.0;
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 9, padding, 0),
      width: double.infinity,
      height: effectiveHeight,
      child: Material(
        elevation: 0,
        color: colorScheme.primaryContainer.withOpacity(0.8),
        borderRadius: BorderRadius.circular(effectiveHeight / 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            Tooltip(
              message: "返回".tl,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => MainPage.back(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  cursorColor: colorScheme.primary,
                  style: textTheme.bodyLarge,
                  textAlignVertical: TextAlignVertical.center,
                  controller: controller,
                  onChanged: onChanged,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    hintText: supportingText,
                    hintStyle: textTheme.bodyLarge?.apply(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: f,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class PreSearchController extends StateController {
  int target = 0;
  int picComicsOrder = appdata.getSearchMode();
  int jmComicsOrder = int.parse(appdata.settings[19]);
  NhentaiSort nhentaiSort = NhentaiSort.values[int.parse(appdata.settings[39])];

  var suggestions = <Pair<String, TranslationType>>[];

  void updateTarget(int i) {
    target = i;
    update();
  }

  void updatePicComicsOrder(int i) {
    picComicsOrder = i;
    appdata.setSearchMode(i);
    update();
  }

  void updateJmComicsOrder(int i) {
    jmComicsOrder = i;
    appdata.settings[19] = i.toString();
    appdata.updateSettings();
    update();
  }
}

class PreSearchPage extends StatelessWidget {
  PreSearchPage({super.key});

  final controller = TextEditingController();

  final searchController = StateController.put(PreSearchController());

  final FocusNode _focusNode = FocusNode();

  void search([String? s]) {
    final keyword = (s ?? controller.text).trim();
    switch (searchController.target) {
      case 0:
        MainPage.to(() => SearchPage(keyword));
        break;
      case 1:
        MainPage.to(() => EhSearchPage(keyword));
        break;
      case 2:
        MainPage.to(() => JmSearchPage(keyword));
        break;
      case 3:
        MainPage.to(() => HitomiSearchPage(keyword));
        break;
      case 4:
        MainPage.to(() => HtSearchPage(keyword));
        break;
      case 5:
        MainPage.to(() => NhentaiSearchPage(keyword));
        break;
    }
  }

  void findSuggestions() {
    var text = controller.text.split(" ").last;
    var suggestions = searchController.suggestions;

    suggestions.clear();

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
          if (UiMode.m1(context))
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
          _FloatingSearchBar(
            supportingText: '搜索'.tl,
            f: (s) {
              if (s == "") return;
              search();
            },
            controller: controller,
            onChanged: (s) {
              findSuggestions();
              searchController.update([1, 100]);
            },
            focusNode: _focusNode,
          ),
          const SizedBox(
            height: 8,
          ),
          buildBody(context)
        ],
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    var widget = StateBuilder<PreSearchController>(
      id: 100,
      builder: (_) {
        if (controller.text.removeAllBlank.isEmpty ||
            controller.text.endsWith(" ") ||
            searchController.suggestions.isEmpty) {
          return buildMainView(context);
        } else {
          return buildSuggestions(context);
        }
      },
    );
    return Expanded(
      child: widget,
    );
  }

  Widget buildMainView(BuildContext context) {
    final showSideBar = MediaQuery.of(context).size.width > 900;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSideBar)
          SizedBox(
            width: 250,
            height: double.infinity,
            child: buildHistorySideBar(context),
          ),
        if (showSideBar) const VerticalDivider(),
        Expanded(
          child: SingleChildScrollView(
            padding: showSideBar
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSideBar)
                  ListTile(
                    leading: const Icon(Icons.select_all),
                    title: Text("搜索选项".tl),
                  ),
                buildTargetSelector(context),
                buildModeSelector(context),
                buildHotSearch(context),
                if (!showSideBar) buildPinned(context),
                if (!showSideBar) buildHistory(context),
                SizedBox(height: MediaQuery.of(context).padding.bottom,),
              ],
            ),
        )),
        if (showSideBar) const VerticalDivider(),
        if (showSideBar)
          SizedBox(
            width: 250,
            height: double.infinity,
            child: buildPinnedSideBar(),
          ),
      ],
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

    return StateBuilder<PreSearchController>(
      builder: (logic) {
        void onSelected(String text, TranslationType? type, [bool? male]) {
          var words = controller.text.split(" ");
          if (words.length >= 2 &&
              check("${words[words.length - 2]} ${words[words.length - 1]}",
                  text, text.translateTagsToCN)) {
            controller.text = controller.text.replaceLast(
                "${words[words.length - 2]} ${words[words.length - 1]}", "");
          } else {
            controller.text =
                controller.text.replaceLast(words[words.length - 1], "");
          }
          if (text.contains(" ")) {
            if (logic.target == 3) {
              text = text.replaceAll(" ", '_');
            } else {
              text = "\"$text\"";
            }
          }
          if (logic.target == 1) {
            if (type != null) {
              controller.text += "${type.name}:$text ";
            } else {
              controller.text += "$text ";
            }
          } else {
            controller.text += "$text ";
          }
          logic.update([1, 100]);
          _focusNode.requestFocus();
        }

        Widget widget;

        if (controller.text.removeAllBlank.isEmpty) {
          widget = buildMainView(context);
        } else {
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

          widget = Column(
            children: [
              SizedBox(
                height: 32,
                child: Row(
                  children: [
                    const SizedBox(width: 32,),
                    Text("建议".tl),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        searchController.suggestions.clear();
                        logic.update([100]);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 20,),
                      ),
                    ),
                    const SizedBox(width: 32,),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: searchController.suggestions.length,
                  itemBuilder: (context, index) =>
                      buildItem(searchController.suggestions[index]),
                ),
              )
            ],
          );
        }
        return widget;
      },
      id: 1,
    );
  }

  Widget buildTargetSelector(BuildContext context) {
    buildItem(PreSearchController logic, int id, String text) => Padding(
          padding: const EdgeInsets.all(5),
          child: FilterChip(
            label: Text(text),
            selected: logic.target == id,
            onSelected: (b) {
              logic.updateTarget(id);
            },
          ),
        );

    buildJMID() {
      return Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          textStyle: Theme.of(context).textTheme.labelLarge,
          child: InkWell(
            onTap: () {
              var controller = TextEditingController();
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("输入禁漫漫画ID".tl),
                      content: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: controller,
                          onEditingComplete: () {
                            App.back(context);
                            if (controller.text.isNum) {
                              MainPage.to(() => JmComicPage(controller.text));
                            } else {
                              showMessage(context, "输入的ID不是数字".tl);
                            }
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                          ],
                          decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "ID",
                              prefix: Text("JM")),
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              App.back(context);
                              if (controller.text.isNum) {
                                MainPage.to(() => JmComicPage(controller.text));
                              } else {
                                showMessage(context, "输入的ID不是数字".tl);
                              }
                            },
                            child: Text("提交".tl))
                      ],
                    );
                  });
            },
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Container(
              decoration: BoxDecoration(
                border:
                    Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 7, 24, 7),
              child: const Text("JM ID"),
            ),
          ),
        ),
      );
    }

    return StateBuilder<PreSearchController>(
      builder: (logic) {
        return Card(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("目标".tl),
              Wrap(
                children: [
                  buildItem(logic, 0, "Picacg"),
                  if (appdata.settings[21][1] == "1")
                    buildItem(logic, 1, "EHentai"),
                  if (appdata.settings[21][2] == "1")
                    buildItem(logic, 2, "JM Comic"),
                  if (appdata.settings[21][2] == "1") buildJMID(),
                  if (appdata.settings[21][3] == "1")
                    buildItem(logic, 3, "Hitomi"),
                  if (appdata.settings[21][4] == "1")
                    buildItem(logic, 4, "绅士漫画"),
                  if (appdata.settings[21][5] == "1")
                    buildItem(logic, 5, "Nhentai"),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildModeSelector(BuildContext context) {
    List<Widget> buildPicacg(PreSearchController logic) {
      Widget buildItem(String text, int index) => Padding(
            padding: const EdgeInsets.all(5),
            child: FilterChip(
              label: Text(text),
              selected: logic.picComicsOrder == index,
              onSelected: (b) {
                logic.updatePicComicsOrder(index);
              },
            ),
          );

      return [
        buildItem("新到书".tl, 0),
        buildItem("旧到新".tl, 1),
        buildItem("最多喜欢".tl, 2),
        buildItem("最多指名".tl, 3),
      ];
    }

    List<Widget> buildJM(PreSearchController logic) {
      Widget buildItem(String text, int index) => Padding(
            padding: const EdgeInsets.all(5),
            child: FilterChip(
              label: Text(text),
              selected: logic.jmComicsOrder == index,
              onSelected: (b) {
                logic.updateJmComicsOrder(index);
              },
            ),
          );

      return [
        buildItem("最新".tl, 0),
        buildItem("最多点击".tl, 1),
        buildItem("最多图片".tl, 5),
        buildItem("最多喜欢".tl, 6),
      ];
    }

    List<Widget> buildNhentai(PreSearchController logic) {
      Widget buildItem(String text, int index) => Padding(
            padding: const EdgeInsets.all(5),
            child: FilterChip(
              label: Text(text),
              selected: logic.nhentaiSort.index == index,
              onSelected: (b) {
                logic.nhentaiSort = NhentaiSort.values[index];
                logic.update();
                appdata.settings[39] = index.toString();
                appdata.updateSettings();
              },
            ),
          );

      return [
        buildItem("最新".tl, 0),
        buildItem("热门 | 今天".tl, 1),
        buildItem("热门 | 一周".tl, 2),
        buildItem("热门 | 本月".tl, 3),
        buildItem("热门 | 所有时间".tl, 4),
      ];
    }

    return StateBuilder<PreSearchController>(
      builder: (logic) {
        if (![0, 2, 5].contains(searchController.target)) {
          return const SizedBox();
        }

        return Card(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          elevation: 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("漫画排序模式".tl),
              Wrap(
                children: switch (logic.target) {
                  0 => buildPicacg(logic),
                  2 => buildJM(logic),
                  5 => buildNhentai(logic),
                  _ => throw UnimplementedError()
                },
              )
            ],
          ),
        );
      },
    );
  }

  List<Widget> buildHotSearchTags(BuildContext context) {
    return [
      const SizedBox(
        height: 8,
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("哔咔热搜".tl),
            Wrap(
              children: [
                for (var s in network.hotTags.getNoBlankList())
                  Card(
                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    elevation: 0,
                    color:
                        Theme.of(context).colorScheme.surfaceTint.withAlpha(40),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      onTap: () => MainPage.to(() => SearchPage(s)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Text(s),
                      ),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("禁漫热搜".tl),
            Wrap(
              children: [
                for (var s in jmNetwork.hotTags.getNoBlankList())
                  Card(
                    margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    elevation: 0,
                    color:
                        Theme.of(context).colorScheme.surfaceTint.withAlpha(40),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      onTap: () => MainPage.to(() => JmSearchPage(s)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Text(s),
                      ),
                    ),
                  )
              ],
            )
          ],
        ),
      ),
      SizedBox(
        height: MediaQuery.of(context).padding.bottom,
      )
    ];
  }

  Widget buildHistory(BuildContext context) {
    buildClearButton() {
      if (appdata.searchHistory.isNotEmpty) {
        return Row(children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: InkWell(
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
              onTap: () {
                appdata.searchHistory.clear();
                appdata.writeHistory();
                searchController.update();
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Theme.of(context).colorScheme.secondaryContainer),
                width: 125,
                height: 26,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 5,
                    ),
                    const Icon(
                      Icons.clear_all,
                      color: Colors.indigo,
                    ),
                    Text("清除历史记录".tl)
                  ],
                ),
              ),
            ),
          )
        ]);
      } else {
        return const SizedBox();
      }
    }

    return StateBuilder<PreSearchController>(
      builder: (controller) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("历史搜索".tl),
              Wrap(
                children: [
                  for (var s in appdata.searchHistory.reversed)
                    Card(
                      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        onTap: () => search(s),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Text(s),
                        ),
                      ),
                    ),
                ],
              ),
              buildClearButton(),
            ],
          ),
        );
      },
    );
  }

  Widget buildPinned(BuildContext context) {
    if (appdata.pinnedKeyword.isEmpty) {
      return const SizedBox();
    }

    buildClearButton() {
      if (appdata.pinnedKeyword.isNotEmpty) {
        return Row(children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: InkWell(
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
              onTap: () {
                appdata.pinnedKeyword.clear();
                appdata.writeHistory();
                searchController.update();
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    color: Theme.of(context).colorScheme.secondaryContainer),
                width: 75,
                height: 28,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 8,
                    ),
                    const Icon(
                      Icons.clear_all,
                      color: Colors.indigo,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text("清除".tl)
                  ],
                ),
              ),
            ),
          )
        ]);
      } else {
        return const SizedBox();
      }
    }

    return StateBuilder<PreSearchController>(
      builder: (controller) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("已固定".tl),
              Wrap(
                children: [
                  for (var s in appdata.pinnedKeyword)
                    Card(
                      margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        onTap: () => search(s),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Text(s),
                        ),
                      ),
                    ),
                ],
              ),
              buildClearButton(),
            ],
          ),
        );
      },
    );
  }

  Widget buildHistorySideBar(BuildContext context) {
    return StateBuilder<PreSearchController>(
        builder: (logic) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: appdata.searchHistory.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.history_toggle_off),
                    title: Text("历史搜索".tl),
                    trailing: TextButton(
                      onPressed: () {
                        appdata.searchHistory.clear();
                        appdata.writeHistory();
                        searchController.update();
                      },
                      child: Text("清空".tl),
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text(appdata
                        .searchHistory[appdata.searchHistory.length - index]),
                    onTap: () => search(appdata
                        .searchHistory[appdata.searchHistory.length - index]),
                  );
                }
              },
            ));
  }

  Widget buildPinnedSideBar() {
    return StateBuilder<PreSearchController>(
        builder: (logic) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: appdata.pinnedKeyword.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.sell_outlined),
                    title: Text("已固定".tl),
                    trailing: TextButton(
                      onPressed: () {
                        appdata.pinnedKeyword.clear();
                        appdata.writeHistory();
                        searchController.update();
                      },
                      child: Text("清空".tl),
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text(appdata.pinnedKeyword.elementAt(index - 1)),
                    onTap: () =>
                        search(appdata.pinnedKeyword.elementAt(index - 1)),
                  );
                }
              },
            ));
  }

  Widget buildHotSearch(BuildContext context) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (context) => buildStatefulHotSearch(context));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Row(
          children: [
            const SizedBox(
              width: 8,
            ),
            Text("热搜".tl),
            const Spacer(),
            const Icon(Icons.arrow_right),
            const SizedBox(
              width: 8,
            )
          ],
        ),
      ),
    );
  }

  Widget buildStatefulHotSearch(BuildContext context) {
    int loading = 2;
    String? message;
    bool flag = true;
    return StatefulBuilder(builder: (context, stateUpdater) {
      if (flag) {
        flag = false;
        if (jmNetwork.hotTags.isEmpty) {
          jmNetwork.getHotTags().then((value) => stateUpdater(() {
                loading--;
                if (value.error) {
                  message = value.errorMessageWithoutNull;
                }
              }));
        } else {
          loading--;
        }
        if (network.hotTags.isEmpty) {
          network.getKeyWords().then((value) => stateUpdater(() {
                loading--;
                if (value.error) {
                  message = value.errorMessageWithoutNull;
                }
              }));
        } else {
          loading--;
        }
      }
      if (loading != 0) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      } else if (message != null) {
        return showNetworkError(message, () {
          stateUpdater(() {
            loading = 2;
            message = null;
            flag = true;
          });
        }, context);
      } else {
        return SingleChildScrollView(
          child: Column(
            children: buildHotSearchTags(context),
          ),
        );
      }
    });
  }
}
