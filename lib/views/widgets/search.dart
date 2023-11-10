import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/eh_views/eh_search_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_search.dart';
import 'package:pica_comic/views/ht_views/ht_search_page.dart';
import 'package:pica_comic/views/jm_views/jm_search_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/nhentai/search_page.dart';
import 'package:pica_comic/views/search_page.dart';
import '../../base.dart';
import '../pic_views/search_page.dart' as pic;


class FloatingSearchBar extends StatefulWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailing,
    required this.onSearch,
    required this.controller,
    this.onChanged,
    this.showPinnedButton = true,
    this.target
  }) : super(key: key);

  /// height of search bar
  final double height;

  /// end of search bar
  final Widget? trailing;

  /// callback when user do search
  final void Function(String) onSearch;

  /// controller of [TextField]
  final TextEditingController controller;

  /// callback when text changed
  final void Function(String)? onChanged;

  /// Deprecated
  final bool showPinnedButton;

  /// search target
  final ComicType? target;

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  double get effectiveHeight {
    return max(widget.height, 53);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    var text = widget.controller.text;
    if(text.isEmpty){
      text = "Search";
    }
    var padding = 12.0;
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 9, padding, 0),
      width: double.infinity,
      height: effectiveHeight,
      child: Material(
        elevation: 0,
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(effectiveHeight / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(effectiveHeight / 2),
          onTap: (){
            MainPage.to(() => SearchPage(
              controller: widget.controller,
              onPop: () => Future.microtask(() => setState((){})),
              onSearch: widget.onSearch,
              type: widget.target,
            ),);
          },
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
                  child: Text(text, style: const TextStyle(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis,),
                ),
              ),
              Tooltip(
                message: "切换源".tl,
                child: IconButton(
                  icon: const Icon(Icons.burst_mode_outlined),
                  onPressed: changeSource,
                ),
              ),
              if(widget.trailing!=null)
                widget.trailing!
            ]),
          ),
        ),
      ),
    );
  }

  void changeSource(){
    showDialog(context: App.globalContext!, builder: (_) => SimpleDialog(
      title: Text("切换源".tl),
      children: [
        const SizedBox(width: 350,),
        ListTile(
          title: const Text("Picacg"),
          onTap: () {
            App.globalBack();
            App.off(context, () => pic.SearchPage(widget.controller.text));
          },
        ),
        ListTile(
          title: const Text("EHentai"),
          onTap: () {
            App.globalBack();
            App.off(context, () => EhSearchPage(widget.controller.text));
          },
        ),
        ListTile(
          title: Text("禁漫天堂".tl),
          onTap: () {
            App.globalBack();
            App.off(context, () => JmSearchPage(widget.controller.text));
          },
        ),
        ListTile(
          title: const Text("nhentai"),
          onTap: () {
            App.globalBack();
            App.off(context, () => NhentaiSearchPage(widget.controller.text));
          },
        ),
        ListTile(
          title: Text("绅士漫画".tl),
          onTap: () {
            App.globalBack();
            App.off(context, () => HtSearchPage(widget.controller.text));
          },
        ),
        ListTile(
          title: const Text("hitomi"),
          onTap: () {
            App.globalBack();
            App.off(context, () => HitomiSearchPage(widget.controller.text));
          },
        ),
      ],
    ));
  }
}