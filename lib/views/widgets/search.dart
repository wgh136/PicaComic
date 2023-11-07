import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/search_page.dart';
import '../../base.dart';


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
    var padding = 16.0;
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
                  child: Text(text),
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
}