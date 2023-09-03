import 'package:flutter/material.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/ui_mode.dart';

class CustomAppbar extends StatelessWidget {
  const CustomAppbar({required this.title, this.leading, this.actions, this.backgroundColor, super.key});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if(UiMode.m1(context)){
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        backgroundColor: backgroundColor,
      );
    }else{
      return SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 8),
            leading ?? Tooltip(message: "返回".tl, child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),),
            const SizedBox(width: 24,),
            Material(
              textStyle: Theme.of(context).textTheme.headlineSmall,
              child: Expanded(child: title),
            ),
            const Spacer(),
            ...?actions,
            const SizedBox(width: 8,)
          ],
        ),
      );
    }
  }
}

class CustomSmallSliverAppbar extends StatelessWidget{
  const CustomSmallSliverAppbar({required this.title, this.leading, this.actions, this.backgroundColor, super.key});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if(UiMode.m1(context)){
      return SliverAppBar(
        pinned: true,
        title: title,
        leading: leading,
        actions: actions,
        backgroundColor: backgroundColor,
      );
    }else{
      return SliverToBoxAdapter(
        child: Material(
          textStyle: Theme.of(context).textTheme.headlineSmall,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 8),
                leading ?? Tooltip(message: "返回".tl, child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),),
                const SizedBox(width: 24,),
                Expanded(child: title),
                ...?actions,
                const SizedBox(width: 16,)
              ],
            ),
          ),
        ),
      );
    }
  }

}

class CustomSliverAppbar extends StatelessWidget{
  const CustomSliverAppbar({required this.title, this.leading,
    this.actions, super.key, required this.centerTitle});

  final Widget title;

  final Widget? leading;

  final List<Widget>? actions;

  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    if(UiMode.m1(context)){
      return SliverAppBar.large(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
      );
    }else{
      return SliverToBoxAdapter(
        child: Material(
          textStyle: Theme.of(context).textTheme.headlineMedium,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        leading ?? Tooltip(message: "返回".tl, child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),),
                        const Spacer(),
                        ...?actions,
                      ],
                    ),
                  ),
                  const SizedBox(height: 32,),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: title,
                  ),
                  const SizedBox(height: 28,)
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
