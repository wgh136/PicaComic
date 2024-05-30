import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/ui_mode.dart';

class CustomAppbar extends StatefulWidget implements PreferredSizeWidget{
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
  State<CustomAppbar> createState() => _CustomAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _CustomAppbarState extends State<CustomAppbar> {
  ScrollNotificationObserverState? _scrollNotificationObserver;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    if (_scrollNotificationObserver != null) {
      _scrollNotificationObserver!.removeListener(_handleScrollNotification);
      _scrollNotificationObserver = null;
    }
    super.dispose();
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification
        && defaultScrollNotificationPredicate(notification)) {
      final bool oldScrolledUnder = _scrolledUnder;
      final ScrollMetrics metrics = notification.metrics;
      switch (metrics.axisDirection) {
        case AxisDirection.up:
        // Scroll view is reversed
          _scrolledUnder = metrics.extentAfter > 0;
        case AxisDirection.down:
          _scrolledUnder = metrics.extentBefore > 0;
        case AxisDirection.right:
        case AxisDirection.left:
        // Scrolled under is only supported in the vertical axis, and should
        // not be altered based on horizontal notifications of the same
        // predicate since it could be a 2D scroller.
          break;
      }

      if (_scrolledUnder != oldScrolledUnder) {
        setState(() {
          // React to a change in MaterialState.scrolledUnder
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double padding = 0;
    if(UiMode.m1(context)){
      padding += MediaQuery.paddingOf(context).top;
    }
    return Material(
      elevation: (_scrolledUnder && UiMode.m1(context)) ? 4 : 0,
      surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: 8),
            widget.leading ??
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
                child: widget.title,
              ),
            ),
            ...?widget.actions,
            const SizedBox(
              width: 8,
            )
          ],
        ),
      ).paddingTop(padding),
    );
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

class MySliverAppBar extends StatelessWidget {
  const MySliverAppBar({super.key, required this.title, this.leading, this.actions});

  final Widget? leading;

  final Widget title;

  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _MySliverAppBarDelegate(
        leading: leading,
        title: title,
        actions: actions,
        topPadding: MediaQuery.of(context).padding.top,
      ),
    );
  }
}

const _kAppBarHeight = 58.0;

class _MySliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget? leading;

  final Widget title;

  final List<Widget>? actions;

  final double topPadding;

  _MySliverAppBarDelegate({this.leading, required this.title, this.actions, required this.topPadding});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Material(
        elevation: 0,
        child: Row(
          children: [
            const SizedBox(width: 8),
            leading ??(Navigator.of(context).canPop() ?
                Tooltip(
                  message: "返回".tl,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ) : const SizedBox()),
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
        ).paddingTop(topPadding),
      ),
    );
  }

  @override
  double get maxExtent => _kAppBarHeight + topPadding;

  @override
  double get minExtent => _kAppBarHeight + topPadding;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate is! _MySliverAppBarDelegate ||
        leading != oldDelegate.leading ||
        title != oldDelegate.title ||
        actions != oldDelegate.actions;
  }
}