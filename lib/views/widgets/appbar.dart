import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/ui_mode.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar(
      {required this.title,
      this.leading,
      this.actions,
      this.backgroundColor,
      super.key});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (UiMode.m1(context)) {
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        backgroundColor: backgroundColor,
      );
    } else {
      return SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 8),
            leading ??
                Tooltip(
                  message: "返回".tl,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
            const SizedBox(
              width: 24,
            ),
            Expanded(
              child: DefaultTextStyle(
                style: DefaultTextStyle.of(context).style.copyWith(
                    fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: title,
              ),
            ),
            ...?actions,
            const SizedBox(
              width: 8,
            )
          ],
        ),
      );
    }
  }
}

class CustomSmallSliverAppbar extends StatelessWidget {
  const CustomSmallSliverAppbar(
      {required this.title,
      this.leading,
      this.actions,
      this.backgroundColor,
      super.key});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      title: title,
      leading: leading,
      actions: actions,
      scrolledUnderElevation: UiMode.m1(context) ? null : 0.0,
      backgroundColor: backgroundColor,
      primary: UiMode.m1(context),
    );
  }
}

class CustomSliverAppbar extends StatelessWidget {
  const CustomSliverAppbar(
      {required this.title,
      this.leading,
      this.actions,
      super.key,
      required this.centerTitle});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar.large(
      title: title,
      leading: leading,
      actions: actions,
      scrolledUnderElevation: UiMode.m1(context) ? null : 0,
      centerTitle: centerTitle,
      primary: UiMode.m1(context),
    );
  }
}
