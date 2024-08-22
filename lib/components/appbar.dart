part of 'components.dart';

class Appbar extends StatefulWidget implements PreferredSizeWidget {
  const Appbar(
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
  State<Appbar> createState() => _AppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class _AppbarState extends State<Appbar> {
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
    if (notification is ScrollUpdateNotification &&
        defaultScrollNotificationPredicate(notification)) {
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
    var content = SizedBox(
      height: _kAppBarHeight,
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
              style:
              DefaultTextStyle.of(context).style.copyWith(fontSize: 20),
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
    ).paddingTop(context.padding.top);
    if(widget.backgroundColor != Colors.transparent) {
      return Material(
        elevation: (_scrolledUnder && UiMode.m1(context)) ? 1 : 0,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: content,
      );
    }
    return content;
  }
}

class SliverAppbar extends StatelessWidget {
  const SliverAppbar(
      {super.key, required this.title, this.leading, this.actions});

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

  _MySliverAppBarDelegate(
      {this.leading,
      required this.title,
      this.actions,
      required this.topPadding});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: Material(
        elevation: 0,
        child: Row(
          children: [
            const SizedBox(width: 8),
            leading ??
                (Navigator.of(context).canPop()
                    ? Tooltip(
                        message: "返回".tl,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      )
                    : const SizedBox()),
            const SizedBox(
              width: 24,
            ),
            Expanded(
              child: DefaultTextStyle(
                style:
                    DefaultTextStyle.of(context).style.copyWith(fontSize: 20),
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

class FloatingSearchBar extends StatefulWidget {
  const FloatingSearchBar({
    Key? key,
    this.height = 56,
    this.trailing,
    required this.onSearch,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  /// height of search bar
  final double height;

  /// end of search bar
  final Widget? trailing;

  /// callback when user do search
  final void Function(String) onSearch;

  /// controller of [TextField]
  final TextEditingController controller;

  final void Function(String)? onChanged;

  @override
  State<FloatingSearchBar> createState() => _FloatingSearchBarState();
}

class _FloatingSearchBarState extends State<FloatingSearchBar> {
  double get effectiveHeight {
    return math.max(widget.height, 53);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    var text = widget.controller.text;
    if (text.isEmpty) {
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            Tooltip(
              message: "返回".tl,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextField(
                  controller: widget.controller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  onSubmitted: (s) {
                    widget.onSearch(s);
                  },
                  onChanged: widget.onChanged,
                ),
              ),
            ),
            if (widget.trailing != null) widget.trailing!
          ]),
        ),
      ),
    );
  }
}
