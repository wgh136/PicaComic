import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/foundation/pair.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/views/custom_views/search_page.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/nhentai/comic_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/pic_views/search_page.dart';
import 'package:pica_comic/views/widgets/custom_chips.dart';
import 'package:pica_comic/views/widgets/flyout.dart';
import 'package:pica_comic/views/widgets/select.dart';
import '../base.dart';
import 'package:pica_comic/network/jm_network/jm_network.dart';
import '../network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/tools/tags_translation.dart';
import 'jm_views/jm_comic_page.dart';
import 'main_page.dart';

typedef FilterChip = CustomFilterChip;

class _FloatingSearchBar extends StatefulWidget {
  const _FloatingSearchBar(
      {Key? key,
      required this.supportingText,
      required this.onFinish,
      required this.controller,
      this.onChanged,
      this.focusNode})
      : super(key: key);

  final void Function(String) onFinish;
  final String supportingText;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  @override
  State<_FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<_FloatingSearchBar> {
  final double height = 56;

  double get effectiveHeight {
    return max(height, 53);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    var padding = 12.0;
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
              child: TextField(
                cursorColor: colorScheme.primary,
                style: textTheme.bodyLarge,
                textAlignVertical: TextAlignVertical.center,
                controller: widget.controller,
                onChanged: (s) {
                  if (s.length <= 1) {
                    setState(() {});
                  }
                  widget.onChanged?.call(s);
                },
                focusNode: widget.focusNode,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: widget.supportingText,
                  hintStyle: textTheme.bodyLarge?.apply(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onFinish,
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              Tooltip(
                message: "clear",
                child: IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  iconSize: 18,
                  onPressed: () {
                    setState(() {
                      widget.controller.text = "";
                    });
                  },
                ),
              ),
            Tooltip(
              message: "search",
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  widget.onFinish(widget.controller.text);
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class PreSearchController extends StateController {
  String target = '0';
  int picComicsOrder = appdata.getSearchMode();
  int jmComicsOrder = int.parse(appdata.settings[19]);
  NhentaiSort nhentaiSort = NhentaiSort.values[int.parse(appdata.settings[39])];
  var customSourceOptions = <String>[];

  var suggestions = <Pair<String, TranslationType>>[];

  // eh advanced options
  int ehFCats = 0;
  int? ehStartPage;
  int? ehEndPage;
  int? ehMinStars;

  String? language;

  bool limitHistory = true;

  void updateCustomOptions() {
    for (var source in ComicSource.sources) {
      if (source.key == target &&
          source.searchPageData?.searchOptions != null) {
        customSourceOptions = List.generate(
            source.searchPageData!.searchOptions!.length,
            (index) => source
                .searchPageData!.searchOptions![index].options.keys.first);
      }
    }
  }

  void updateTarget(String i) {
    target = i;
    updateCustomOptions();
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

  PreSearchController() {
    var searchSource = <String>['0', '1', '2', '3', '4', '5'];
    for(var source in ComicSource.sources){
      searchSource.add(source.key);
    }
    if(int.parse(appdata.settings[63]) >= searchSource.length){
      appdata.settings[63] = '0';
      appdata.updateSettings();
    }
    target = searchSource[int.parse(appdata.settings[63])];
    updateCustomOptions();
  }
}

class PreSearchPage extends StatelessWidget {
  PreSearchPage({String initialValue = "", super.key})
      : controller = TextEditingController(text: initialValue);

  final TextEditingController controller;

  final searchController = StateController.put(PreSearchController());

  final comicSources =
      ComicSource.sources.where((element) => element.searchPageData != null);

  final FocusNode _focusNode = FocusNode();

  void search([String? s, String? type]) {
    var keyword = (s ?? controller.text).trim();
    if (searchController.language != null &&
        ['1', '5'].contains(searchController.target)) {
      keyword += " language:${searchController.language}";
    }
    switch (type ?? searchController.target) {
      case '0':
        MainPage.to(() => SearchPage(keyword));
      case '1':
        MainPage.to(() => EhSearchPage(
              keyword,
              fCats: searchController.ehFCats,
              startPages: searchController.ehStartPage,
              endPages: searchController.ehEndPage,
              minStars: searchController.ehMinStars,
            ));
      case '2':
        MainPage.to(() => JmSearchPage(
              keyword,
              order: ComicsOrder.values[searchController.jmComicsOrder],
            ));
      case '3':
        MainPage.to(() => HitomiSearchPage(keyword));
      case '4':
        MainPage.to(() => HtSearchPage(keyword));
      case '5':
        MainPage.to(() => NhentaiSearchPage(keyword));
      default:
        MainPage.to(() => CustomSearchPage(
            keyword: keyword,
            sourceKey: type ?? searchController.target,
            loader: comicSources
                .firstWhere((element) =>
                    element.key == (type ?? searchController.target))
                .searchPageData!
                .loadPage!,
            options: searchController.customSourceOptions));
    }
  }

  void findSuggestions() {
    var text = controller.text.split(" ").last;
    var suggestions = searchController.suggestions;

    suggestions.clear();

    if (canHandle(controller.text)) {
      suggestions.add(Pair("**URL**", TranslationType.other));
    } else {
      var text = controller.text;
      bool isJmId = false;
      bool isNhentaiId = false;
      if (text.isNum) {
        isJmId = true;
        isNhentaiId = true;
      } else {
        text = text.toLowerCase();
        if (text.startsWith("jm") && text.replaceFirst("jm", "").isNum) {
          isJmId = true;
        } else if (text.startsWith("nh") && text.replaceFirst("nh", "").isNum) {
          isNhentaiId = true;
        } else if (text.startsWith("nhentai") &&
            text.replaceFirst("nhentai", "").isNum) {
          isNhentaiId = true;
        }
      }
      if (isJmId) {
        suggestions.add(Pair("**JM ID**", TranslationType.other));
      }
      if (isNhentaiId) {
        suggestions.add(Pair("**NH ID**", TranslationType.other));
      }
    }

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
          Builder(
            builder: (context) => _FloatingSearchBar(
              supportingText: '${'搜索'.tl} / ${'链接'.tl} / ID',
              onFinish: (s) {
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
      builder: (logic) {
        if (controller.text.removeAllBlank.isEmpty ||
            controller.text.endsWith(" ") ||
            searchController.suggestions.isEmpty) {
          return buildMainView(context, logic);
        } else {
          return buildSuggestions(context);
        }
      },
    );
    return Expanded(
      child: widget,
    );
  }

  Widget buildMainView(BuildContext context, PreSearchController logic) {
    final showSideBar = MediaQuery.of(context).size.width > 950;
    var addWidth = (MediaQuery.of(context).size.width - 950) * 0.25;
    addWidth = addWidth.clamp(0, 50);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSideBar)
          SizedBox(
            width: 250 + addWidth,
            height: double.infinity,
            child: buildHistorySideBar(),
          ),
        if (showSideBar)
          const VerticalDivider(
            width: 1,
          ),
        Expanded(
          child: CustomScrollView(
            slivers: [
              if (showSideBar)
                ListTile(
                  leading: const Icon(Icons.select_all),
                  title: Text("搜索选项".tl),
                ).toSliver(),
              buildTargetSelector(context).paddingLeft(8).toSliver(),
              buildSearchOptions(context).paddingLeft(8).toSliver(),
              if (!showSideBar)
                ...buildHistoryAndFavoritesForMobile(logic),
              SliverPadding(
                padding: EdgeInsets.only(bottom: context.padding.bottom),)
            ],
        )),
        if (showSideBar)
          const VerticalDivider(
            width: 1,
          ),
        if (showSideBar)
          SizedBox(
            width: 250 + addWidth,
            height: double.infinity,
            child: buildFavoriteSideBar(),
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
        void onSelected(String text, TranslationType? type) {
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
            if (logic.target == '3' &&
                ["male", "female", "language"].contains(type?.name)) {
              text = text.replaceAll(" ", '_');
              text = "${type?.name}:$text";
            } else {
              text = "\"$text\"";
            }
          }
          if (logic.target == '1') {
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
          widget = buildMainView(context, logic);
        } else {
          bool showMethod = MediaQuery.of(context).size.width < 600;
          bool showTranslation = App.locale.languageCode == "zh";
          Widget buildItem(Pair<String, TranslationType> value) {
            if (value.left == "**URL**") {
              return ListTile(
                leading: const Icon(Icons.link),
                title: Text("打开链接".tl),
                subtitle: Text(
                  controller.text,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  handleAppLinks(Uri.parse(controller.text));
                },
              );
            }

            if (value.left == "**JM ID**") {
              var id = controller.text.nums;
              return ListTile(
                leading: const Icon(Icons.link),
                title: Text("打开禁漫ID".tl),
                subtitle: Text("JM$id"),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  MainPage.to(() => JmComicPage(id));
                },
              );
            }

            if (value.left == "**NH ID**") {
              var id = controller.text.nums;
              return ListTile(
                leading: const Icon(Icons.link),
                title: const Text("nhentai ID"),
                subtitle: Text(id),
                trailing: const Icon(Icons.arrow_right),
                onTap: () {
                  MainPage.to(() => NhentaiComicPage(id));
                },
              );
            }

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
                  if (!showMethod && showTranslation)
                    Text(
                      subTitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.outline),
                    )
                ],
              ),
              subtitle: (showMethod && showTranslation) ? Text(subTitle) : null,
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
                    const SizedBox(
                      width: 32,
                    ),
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
                        child: Icon(
                          Icons.close,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 36,
                    ),
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
    buildItem(PreSearchController logic, String id, String text) => Padding(
          padding: const EdgeInsets.all(4),
          child: FilterChip(
            label: Text(text),
            selected: logic.target == id,
            onSelected: (b) {
              logic.updateTarget(id);
            },
          ),
        );

    return StateBuilder<PreSearchController>(
      builder: (logic) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "目标".tl,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Wrap(
                children: [
                  buildItem(logic, '0', "Picacg"),
                  if (appdata.settings[21][1] == "1")
                    buildItem(logic, '1', "EHentai"),
                  if (appdata.settings[21][2] == "1")
                    buildItem(logic, '2', "JM Comic"),
                  if (appdata.settings[21][3] == "1")
                    buildItem(logic, '3', "Hitomi"),
                  if (appdata.settings[21][4] == "1")
                    buildItem(logic, '4', "绅士漫画"),
                  if (appdata.settings[21][5] == "1")
                    buildItem(logic, '5', "Nhentai"),
                  for (var source in comicSources)
                    buildItem(logic, source.key, source.name)
                ],
              ),
              const SizedBox(
                height: 8,
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildSearchOptions(BuildContext context) {
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

    Widget buildLangSelector() {
      const languages = ["chinese", "japanese", "english"];
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 8,
            ),
            Text("语言".tl),
            const SizedBox(
              width: 16,
            ),
            Select(
              initialValue: languages.indexOf(searchController.language ?? ""),
              onChange: (i) => searchController.language = languages[i],
              values: languages,
              outline: true,
            ),
          ],
        ),
      );
    }

    Widget buildEH() {
      Widget buildCategoryItem(String title, int value, double width) {
        bool disabled = searchController.ehFCats & (1 << value) == 1 << value;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          width: width,
          height: 38,
          decoration: BoxDecoration(
              color: !disabled
                  ? App.colors(context).tertiaryContainer
                  : App.colors(context).tertiaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              disabled
                  ? searchController.ehFCats -= (1 << value)
                  : searchController.ehFCats += (1 << value);
              searchController.update(["mode"]);
            },
            child: Center(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        );
      }

      const categories = [
        "Misc",
        "Doujinshi",
        "Manga",
        "Artist CG",
        "Game CG",
        "Image Set",
        "Cosplay",
        "Asian Porn",
        "Non-H",
        "Western"
      ];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "高级选项".tl,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            LayoutBuilder(
                builder: (context, constrains) => Wrap(
                      children: List.generate(categories.length, (index) {
                        const minWidth = 86;
                        var items = constrains.maxWidth ~/ minWidth;
                        return buildCategoryItem(categories[index], index,
                            constrains.maxWidth / items - items);
                      }),
                    )),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 8,
                ),
                const Text("Pages From"),
                const SizedBox(
                  width: 16,
                ),
                SizedBox(
                  width: 84,
                  //height: 38,
                  child: TextField(
                    onChanged: (s) =>
                        searchController.ehStartPage = int.tryParse(s),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                  ),
                ),
                const SizedBox(
                  width: 16,
                ),
                const Text("To"),
                const SizedBox(
                  width: 16,
                ),
                SizedBox(
                  width: 84,
                  //height: 38,
                  child: TextField(
                    onChanged: (s) =>
                        searchController.ehEndPage = int.tryParse(s),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Row(
              children: [
                const SizedBox(
                  width: 8,
                ),
                Text("最少星星".tl),
                const SizedBox(
                  width: 16,
                ),
                Select(
                  initialValue: searchController.ehMinStars,
                  onChange: (i) => searchController.ehMinStars = i,
                  values: const ["0", "1", "2", "3", "4", "5"],
                  outline: true,
                ),
              ],
            ),
            buildLangSelector(),
            const SizedBox(
              height: 8,
            )
          ],
        ),
      );
    }

    Widget buildCustom(PreSearchController logic) {
      var children = <Widget>[];
      final searchOptions = comicSources
              .firstWhere((element) => element.key == logic.target)
              .searchPageData!
              .searchOptions ??
          <SearchOptions>[];
      for (int i = 0; i < searchOptions.length; i++) {
        final option = searchOptions[i];
        children.add(Text(
          option.label,
          style: Theme.of(context).textTheme.bodyLarge,
        ));
        children.add(Wrap(
          runSpacing: 8,
          spacing: 8,
          children: option.options.entries
              .map((e) => InkWell(
                    onTap: () {
                      logic.customSourceOptions[i] = e.key;
                      logic.update();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Material(
                      elevation: 0.6,
                      surfaceTintColor:
                          Theme.of(context).colorScheme.surfaceTint,
                      color: logic.customSourceOptions[i] == e.key
                          ? App.colors(context).primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(e.value),
                      ),
                    ),
                  ))
              .toList(),
        ).paddingTop(8).paddingBottom(12).paddingLeft(4));
      }
      return SizedBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ).paddingLeft(10);
    }

    return StateBuilder<PreSearchController>(
      id: "mode",
      builder: (logic) {
        if (['3', '4'].contains(searchController.target)) {
          return const SizedBox();
        }

        if (!['0', '1', '2', '3', '4', '5'].contains(searchController.target)) {
          return buildCustom(logic);
        }

        if (searchController.target == '1') {
          return buildEH();
        }

        return Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "排序方式".tl,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Wrap(
                children: switch (logic.target) {
                  '0' => buildPicacg(logic),
                  '2' => buildJM(logic),
                  '5' => buildNhentai(logic),
                  _ => throw UnimplementedError()
                },
              ),
              if (logic.target == '5') buildLangSelector(),
              const SizedBox(
                height: 8,
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildHistoryItem(String history, PreSearchController logic) {
    return Flyout(
      enableLongPress: true,
      enableSecondaryTap: true,
      navigator: App.navigatorKey.currentState,
      flyoutBuilder: (context) {
        return FlyoutContent(
          title: "要删除此项目吗?".tl,
          actions: [
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                appdata.searchHistory.remove(history);
                logic.update(["history"]);
                appdata.writeHistory();
              },
              child: Text("确认".tl),
            )
          ],
        );
      },
      child: ListTile(
        title: Text(history),
        onTap: () => search(history),
      ),
    );
  }

  Widget buildFavoriteItem(String tag, PreSearchController logic) {
    return Flyout(
      enableLongPress: true,
      enableSecondaryTap: true,
      navigator: App.navigatorKey.currentState,
      flyoutBuilder: (context) {
        return FlyoutContent(
          title: "要删除此项目吗?".tl,
          actions: [
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                appdata.favoriteTags.remove(tag);
                searchController.update();
                appdata.writeHistory();
              },
              child: Text("确认".tl),
            )
          ],
        );
      },
      child: ListTile(
        title: Text(tag.substring(tag.indexOf(':') + 1)),
        subtitle: Text(tag.split(':').first),
        onTap: () {
          String type = switch (tag.split(':').first) {
            "Picacg" => '0',
            "EHentai" => '1',
            "JMComic" => '2',
            "hitomi" => '3',
            "HtComic" => '4',
            "Nhentai" => '5',
            _ => tag.split(':').first
          };
          final keyword = tag.substring(tag.indexOf(':') + 1);
          search(keyword, type);
        },
      ),
    );
  }

  Widget buildClearHistoryButton(PreSearchController logic) {
    return FlyoutIconButton(
      navigator: App.navigatorKey.currentState,
      flyoutBuilder: (context) {
        return FlyoutContent(
          title: "要清空历史记录吗?".tl,
          actions: [
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                appdata.searchHistory.clear();
                appdata.writeHistory();
                logic.update(["history"]);
              },
              child: Text("确认".tl),
            )
          ],
        );
      },
      icon: const Icon(Icons.clear_all),
    );
  }

  Widget buildClearFavoriteButton(PreSearchController logic) {
    return FlyoutIconButton(
      navigator: App.navigatorKey.currentState,
      flyoutBuilder: (context) {
        return FlyoutContent(
          title: "要清空收藏吗?".tl,
          actions: [
            FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.error),
              ),
              onPressed: () {
                appdata.favoriteTags.clear();
                appdata.writeHistory();
                logic.update();
              },
              child: Text("确认".tl),
            )
          ],
        );
      },
      icon: const Icon(Icons.clear_all),
    );
  }

  Widget buildHistorySideBar() {
    return StateBuilder<PreSearchController>(
        id: "history",
        builder: (logic) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: appdata.searchHistory.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text("历史搜索".tl),
                    trailing: buildClearHistoryButton(logic),
                  );
                } else {
                  var history = appdata
                      .searchHistory[appdata.searchHistory.length - index];
                  return buildHistoryItem(history, logic);
                }
              },
            ));
  }

  Widget buildFavoriteSideBar() {
    return StateBuilder<PreSearchController>(
        builder: (logic) => ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: appdata.favoriteTags.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: Text("收藏".tl),
                    trailing: buildClearFavoriteButton(logic),
                  );
                } else {
                  final s = appdata.favoriteTags.elementAt(index - 1);
                  return buildFavoriteItem(s, logic);
                }
              },
            ));
  }

  Iterable<Widget> buildHistoryAndFavoritesForMobile(PreSearchController logic) sync*{
    yield ListTile(
      title: Text("历史搜索".tl),
      trailing: buildClearHistoryButton(logic),
    ).toSliver();
    yield StateBuilder<PreSearchController>(
        id: "history",
        builder: (logic) {
          var length = appdata.searchHistory.length;
          if(length < 10) {
            logic.limitHistory = false;
          }
          if (logic.limitHistory) {
            length = length.clamp(0, 10);
          }
          return SliverList.builder(
            itemCount: length,
            itemBuilder: (context, index) {
              if(index == length - 1 && logic.limitHistory){
                return TextButton(
                  child: Text("查看更多".tl),
                  onPressed: () {
                    logic.limitHistory = false;
                    logic.update();
                  },
                ).toAlign(Alignment.center);
              }
              var history = appdata.searchHistory[appdata.searchHistory.length - index - 1];
              return buildHistoryItem(history, logic);
            },
          ).sliverPaddingHorizontal(8);
        });

    yield ListTile(
      title: Text("收藏".tl),
      trailing: buildClearFavoriteButton(logic),
    ).toSliver();

    yield StateBuilder<PreSearchController>(
        builder: (logic) => SliverList.builder(
          itemCount: appdata.favoriteTags.length,
          itemBuilder: (context, index) {
            final s = appdata.favoriteTags.elementAt(index);
            return buildFavoriteItem(s, logic);
          },
        ).sliverPaddingHorizontal(8));
  }
}
