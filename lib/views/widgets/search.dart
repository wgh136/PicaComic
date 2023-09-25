import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../base.dart';


class FloatingSearchBar extends StatelessWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailing,
    required this.supportingText,
    required this.f,
    required this.controller,
    this.onChanged,
    this.showPinnedButton = true,
    this.focusNode
  }) : super(key: key);

  final double height;
  double get effectiveHeight {
    return max(height, 53);
  }
  final Widget? trailing;
  final void Function(String) f;
  final String supportingText;
  final TextEditingController controller;
  final void Function(String)? onChanged;
  final bool showPinnedButton;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    var padding = 10.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 4, padding, 0),
      child: Container(
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
              if(showPinnedButton)
                Tooltip(
                  message: "固定".tl,
                  child: IconButton(
                    icon: const Icon(Icons.sell_outlined),
                    onPressed: (){
                      appdata.pinnedKeyword.add(controller.text);
                      appdata.writeHistory();
                      try {
                        Get.find<PreSearchController>().update();
                      }
                      catch(e){
                        // ignore
                      }
                      showMessage(Get.context, "已固定".tl);
                    },
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