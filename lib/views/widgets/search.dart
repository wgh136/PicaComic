import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/translations.dart';

import '../../base.dart';

class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailing,
    required this.supportingText,
    required this.f,
    required this.controller
  }) : super(key: key);

  final double height;
  double get effectiveHeight {
    return max(height, 53);
  }
  final Widget? trailing;
  final void Function(String) f;
  final String supportingText;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    var padding = 10.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 0),
      child: Container(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 720),
        padding: const EdgeInsets.only(top: 5),
        width: double.infinity,
        height: effectiveHeight,
        child: Material(
          elevation: 0,
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(effectiveHeight / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Tooltip(
                message: "返回".tl,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: (){
                    Get.back();
                  },
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
              if(trailing!=null)
                trailing!
            ]),
          ),
        ),
      ),
    );
  }
}

class NewFloatingSearchBar extends StatelessWidget{
  const NewFloatingSearchBar({super.key,
    this.trailing,
    required this.supportingText,
    required this.f,
    required this.controller
  });

  final Widget? trailing;
  final void Function(String) f;
  final String supportingText;
  final SearchController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: SearchAnchor.bar(
        barElevation: MaterialStateProperty.all<double>(0),
        barBackgroundColor: MaterialStateProperty.all<Color>(Theme.of(context).colorScheme.surfaceVariant),
        barPadding: MaterialStateProperty.all<EdgeInsets>(const EdgeInsets.fromLTRB(8, 0, 8, 0)),
        searchController: controller,
        barLeading: Tooltip(
          message: "返回",
          child: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: ()=>Get.back(),
          ),
        ),
        barTrailing: [
          if(trailing!=null)
            trailing!
        ],
        viewTrailing: [
          IconButton(onPressed: ()=>f(controller.text), icon: const Icon(Icons.search))
        ],
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
          return List<Widget>.generate(
            appdata.searchHistory.length,
                (int index) {
              return ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(appdata.searchHistory[index]),
                onTap: () => f(appdata.searchHistory[index]),
              );
            },
          );
        },
      ),
    );
  }

}