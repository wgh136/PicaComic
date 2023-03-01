import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        constraints: const BoxConstraints(minWidth: 360, maxWidth: 720),
        padding: const EdgeInsets.only(top: 5),
        width: double.infinity,
        height: effectiveHeight,
        child: Material(
          elevation: 0,
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(effectiveHeight / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              Tooltip(
                message: "返回",
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
