import 'package:pica_comic/foundation/app.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
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

  final double height;
  final Widget? trailing;
  final void Function(String) onSearch;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final bool showPinnedButton;
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
              if(widget.showPinnedButton)
                Tooltip(
                  message: "固定".tl,
                  child: IconButton(
                    icon: const Icon(Icons.sell_outlined),
                    onPressed: (){
                      appdata.pinnedKeyword.add(widget.controller.text);
                      appdata.writeHistory();
                      try {
                        StateController.find<PreSearchController>().update();
                      }
                      catch(e){
                        // ignore
                      }
                      showMessage(App.globalContext, "已固定".tl);
                    },
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