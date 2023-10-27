// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'item_positions_listener.dart';
import 'item_positions_notifier.dart';
import 'positioned_list.dart';
import 'post_mount_callback.dart';

/// Number of screens to scroll when scrolling a long distance.
const int _screenScrollCount = 2;

/// A scrollable list of widgets similar to [ListView], except scroll control
/// and position reporting is based on index rather than pixel offset.
///
/// [ScrollablePositionedList] lays out children in the same way as [ListView].
///
/// The list can be displayed with the item at [initialScrollIndex] positioned
/// at a particular [initialAlignment].
///
/// The [itemScrollController] can be used to scroll or jump to particular items
/// in the list.  The [itemPositionsNotifier] can be used to get a list of items
/// currently laid out by the list.
///
/// All other parameters are the same as specified in [ListView].
class ScrollablePositionedList extends StatefulWidget {
  /// Create a [ScrollablePositionedList] whose items are provided by
  /// [itemBuilder].
  const ScrollablePositionedList.builder({
    required this.itemCount,
    required this.itemBuilder,
    Key? key,
    this.itemScrollController,
    this.shrinkWrap = false,
    ItemPositionsListener? itemPositionsListener,
    this.initialScrollIndex = 0,
    this.initialAlignment = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.semanticChildCount,
    this.padding,
    this.addSemanticIndexes = true,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.minCacheExtent, required this.scrollController,
  })  : itemPositionsNotifier = itemPositionsListener as ItemPositionsNotifier?,
        separatorBuilder = null,
        super(key: key);

  /// Create a [ScrollablePositionedList] whose items are provided by
  /// [itemBuilder] and separators provided by [separatorBuilder].
  const ScrollablePositionedList.separated({
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.scrollController,
    Key? key,
    this.shrinkWrap = false,
    this.itemScrollController,
    ItemPositionsListener? itemPositionsListener,
    this.initialScrollIndex = 0,
    this.initialAlignment = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.semanticChildCount,
    this.padding,
    this.addSemanticIndexes = true,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.minCacheExtent,
  })  : assert(separatorBuilder != null),
        itemPositionsNotifier = itemPositionsListener as ItemPositionsNotifier?,
        super(key: key);

  /// Number of items the [itemBuilder] can produce.
  final int itemCount;

  final ScrollController scrollController;

  /// Called to build children for the list with
  /// 0 <= index < itemCount.
  final IndexedWidgetBuilder itemBuilder;

  /// Called to build separators for between each item in the list.
  /// Called with 0 <= index < itemCount - 1.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Controller for jumping or scrolling to an item.
  final ItemScrollController? itemScrollController;

  /// Notifier that reports the items laid out in the list after each frame.
  final ItemPositionsNotifier? itemPositionsNotifier;

  /// Index of an item to initially align within the viewport.
  final int initialScrollIndex;

  /// Determines where the leading edge of the item at [initialScrollIndex]
  /// should be placed.
  ///
  /// See [ItemScrollController.jumpTo] for an explanation of alignment.
  final double initialAlignment;

  /// The axis along which the scroll view scrolls.
  ///
  /// Defaults to [Axis.vertical].
  final Axis scrollDirection;

  /// Whether the view scrolls in the reading direction.
  ///
  /// Defaults to false.
  ///
  /// See [ScrollView.reverse].
  final bool reverse;

  /// {@template flutter.widgets.scroll_view.shrinkWrap}
  /// Whether the extent of the scroll view in the [scrollDirection] should be
  /// determined by the contents being viewed.
  ///
  ///  Defaults to false.
  ///
  /// See [ScrollView.shrinkWrap].
  final bool shrinkWrap;

  /// How the scroll view should respond to user input.
  ///
  /// For example, determines how the scroll view continues to animate after the
  /// user stops dragging the scroll view.
  ///
  /// See [ScrollView.physics].
  final ScrollPhysics? physics;

  /// The number of children that will contribute semantic information.
  ///
  /// See [ScrollView.semanticChildCount] for more information.
  final int? semanticChildCount;

  /// The amount of space by which to inset the children.
  final EdgeInsets? padding;

  /// Whether to wrap each child in an [IndexedSemantics].
  ///
  /// See [SliverChildBuilderDelegate.addSemanticIndexes].
  final bool addSemanticIndexes;

  /// Whether to wrap each child in an [AutomaticKeepAlive].
  ///
  /// See [SliverChildBuilderDelegate.addAutomaticKeepAlives].
  final bool addAutomaticKeepAlives;

  /// Whether to wrap each child in a [RepaintBoundary].
  ///
  /// See [SliverChildBuilderDelegate.addRepaintBoundaries].
  final bool addRepaintBoundaries;

  /// The minimum cache extent used by the underlying scroll lists.
  /// See [ScrollView.cacheExtent].
  ///
  /// Note that the [ScrollablePositionedList] uses two lists to simulate long
  /// scrolls, so using the [ScrollController.scrollTo] method may result
  /// in builds of widgets that would otherwise already be built in the
  /// cache extent.
  final double? minCacheExtent;

  @override
  State<StatefulWidget> createState() => _ScrollablePositionedListState();
}

/// Controller to jump or scroll to a particular position in a
/// [ScrollablePositionedList].
class ItemScrollController {
  /// Whether any ScrollablePositionedList objects are attached this object.
  ///
  /// If `false`, then [jumpTo] and [scrollTo] must not be called.
  bool get isAttached => _scrollableListState != null;

  _ScrollablePositionedListState? _scrollableListState;

  /// Immediately, without animation, reconfigure the list so that the item at
  /// [index]'s leading edge is at the given [alignment].
  ///
  /// The [alignment] specifies the desired position for the leading edge of the
  /// item.  The [alignment] is expected to be a value in the range \[0.0, 1.0\]
  /// and represents a proportion along the main axis of the viewport.
  ///
  /// For a vertically scrolling view that is not reversed:
  /// * 0 aligns the top edge of the item with the top edge of the view.
  /// * 1 aligns the top edge of the item with the bottom of the view.
  /// * 0.5 aligns the top edge of the item with the center of the view.
  ///
  /// For a horizontally scrolling view that is not reversed:
  /// * 0 aligns the left edge of the item with the left edge of the view
  /// * 1 aligns the left edge of the item with the right edge of the view.
  /// * 0.5 aligns the left edge of the item with the center of the view.
  void jumpTo({required int index, double alignment = 0}) {
    _scrollableListState!._jumpTo(index: index, alignment: alignment);
  }

  /// Animate the list over [duration] using the given [curve] such that the
  /// item at [index] ends up with its leading edge at the given [alignment].
  /// See [jumpTo] for an explanation of alignment.
  ///
  /// The [duration] must be greater than 0; otherwise, use [jumpTo].
  ///
  /// When item position is not available, because it's too far, the scroll
  /// is composed into three phases:
  ///
  ///  1. The currently displayed list view starts scrolling.
  ///  2. Another list view, which scrolls with the same speed, fades over the
  ///     first one and shows items that are close to the scroll target.
  ///  3. The second list view scrolls and stops on the target.
  ///
  /// The [opacityAnimationWeights] can be used to apply custom weights to these
  /// three stages of this animation. The default weights, `[40, 20, 40]`, are
  /// good with default [Curves.linear].  Different weights might be better for
  /// other cases.  For example, if you use [Curves.easeOut], consider setting
  /// [opacityAnimationWeights] to `[20, 20, 60]`.
  ///
  /// See [TweenSequenceItem.weight] for more info.
  Future<void> scrollTo({
    required int index,
    double alignment = 0,
    required Duration duration,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) {
    assert(_scrollableListState != null);
    assert(opacityAnimationWeights.length == 3);
    assert(duration > Duration.zero);
    return _scrollableListState!._scrollTo(
      index: index,
      alignment: alignment,
      duration: duration,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
    );
  }

  void _attach(_ScrollablePositionedListState scrollableListState) {
    assert(_scrollableListState == null);
    _scrollableListState = scrollableListState;
  }

  void _detach() {
    _scrollableListState = null;
  }
}

class _ScrollablePositionedListState extends State<ScrollablePositionedList>
    with TickerProviderStateMixin {
  /// Details for the primary (active) [ListView].
  late _ListDisplayDetails primary = _ListDisplayDetails(widget.scrollController,const ValueKey('Ping'),);

  /// Details for the secondary (transitional) [ListView] that is temporarily
  /// shown when scrolling a long distance.
  late var secondary = _ListDisplayDetails(widget.scrollController,const ValueKey('Pong'));

  final opacity = ProxyAnimation(const AlwaysStoppedAnimation<double>(0));

  void Function() startAnimationCallback = () {};

  bool _isTransitioning = false;

  var _animationController;

  @override
  void initState() {
    super.initState();
    ItemPosition? initialPosition = PageStorage.of(context).readState(context);
    primary.target = initialPosition?.index ?? widget.initialScrollIndex;
    primary.alignment =
        initialPosition?.itemLeadingEdge ?? widget.initialAlignment;
    if (widget.itemCount > 0 && primary.target > widget.itemCount - 1) {
      primary.target = widget.itemCount - 1;
    }
    widget.itemScrollController?._attach(this);
    primary.itemPositionsNotifier.itemPositions.addListener(_updatePositions);
    secondary.itemPositionsNotifier.itemPositions.addListener(_updatePositions);
  }

  @override
  void deactivate() {
    widget.itemScrollController?._detach();
    super.deactivate();
  }

  @override
  void dispose() {
    primary.itemPositionsNotifier.itemPositions
        .removeListener(_updatePositions);
    secondary.itemPositionsNotifier.itemPositions
        .removeListener(_updatePositions);
    _animationController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ScrollablePositionedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemScrollController?._scrollableListState == this) {
      oldWidget.itemScrollController?._detach();
    }
    if (widget.itemScrollController?._scrollableListState != this) {
      widget.itemScrollController?._detach();
      widget.itemScrollController?._attach(this);
    }

    if (widget.itemCount == 0) {
      setState(() {
        primary.target = 0;
        secondary.target = 0;
      });
    } else {
      if (primary.target > widget.itemCount - 1) {
        setState(() {
          primary.target = widget.itemCount - 1;
        });
      }
      if (secondary.target > widget.itemCount - 1) {
        setState(() {
          secondary.target = widget.itemCount - 1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheExtent = _cacheExtent(constraints);
        return GestureDetector(
          child: Stack(
            children: <Widget>[
              PostMountCallback(
                key: primary.key,
                callback: startAnimationCallback,
                child: FadeTransition(
                  opacity: ReverseAnimation(opacity),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (_) => _isTransitioning,
                    child: PositionedList(
                      itemBuilder: widget.itemBuilder,
                      separatorBuilder: widget.separatorBuilder,
                      itemCount: widget.itemCount,
                      positionedIndex: primary.target,
                      controller: primary.scrollController,
                      itemPositionsNotifier: primary.itemPositionsNotifier,
                      scrollDirection: widget.scrollDirection,
                      reverse: widget.reverse,
                      cacheExtent: cacheExtent,
                      alignment: primary.alignment,
                      physics: widget.physics,
                      shrinkWrap: widget.shrinkWrap,
                      addSemanticIndexes: widget.addSemanticIndexes,
                      semanticChildCount: widget.semanticChildCount,
                      padding: widget.padding,
                      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
                      addRepaintBoundaries: widget.addRepaintBoundaries,
                    ),
                  ),
                ),
              ),
              if (_isTransitioning)
                PostMountCallback(
                  key: secondary.key,
                  callback: startAnimationCallback,
                  child: FadeTransition(
                    opacity: opacity,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (_) => false,
                      child: PositionedList(
                        itemBuilder: widget.itemBuilder,
                        separatorBuilder: widget.separatorBuilder,
                        itemCount: widget.itemCount,
                        itemPositionsNotifier: secondary.itemPositionsNotifier,
                        positionedIndex: secondary.target,
                        controller: secondary.scrollController,
                        scrollDirection: widget.scrollDirection,
                        reverse: widget.reverse,
                        cacheExtent: cacheExtent,
                        alignment: secondary.alignment,
                        physics: widget.physics,
                        shrinkWrap: widget.shrinkWrap,
                        addSemanticIndexes: widget.addSemanticIndexes,
                        semanticChildCount: widget.semanticChildCount,
                        padding: widget.padding,
                        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
                        addRepaintBoundaries: widget.addRepaintBoundaries,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _cacheExtent(BoxConstraints constraints) => max(
        constraints.maxHeight * _screenScrollCount,
        widget.minCacheExtent ?? 0,
      );

  void _jumpTo({required int index, required double alignment}) {
    _stopScroll(canceled: true);
    if (index > widget.itemCount - 1) {
      index = widget.itemCount - 1;
    }
    setState(() {
      primary.scrollController.jumpTo(0);
      primary.target = index;
      primary.alignment = alignment;
    });
  }

  Future<void> _scrollTo({
    required int index,
    required double alignment,
    required Duration duration,
    Curve curve = Curves.linear,
    required List<double> opacityAnimationWeights,
  }) async {
    if (index > widget.itemCount - 1) {
      index = widget.itemCount - 1;
    }
    if (_isTransitioning) {
      _stopScroll(canceled: true);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _startScroll(
          index: index,
          alignment: alignment,
          duration: duration,
          curve: curve,
          opacityAnimationWeights: opacityAnimationWeights,
        );
      });
    } else {
      await _startScroll(
        index: index,
        alignment: alignment,
        duration: duration,
        curve: curve,
        opacityAnimationWeights: opacityAnimationWeights,
      );
    }
  }

  Future<void> _startScroll({
    required int index,
    required double alignment,
    required Duration duration,
    Curve curve = Curves.linear,
    required List<double> opacityAnimationWeights,
  }) async {
    final direction = index > primary.target ? 1 : -1;
    final itemPosition = primary.itemPositionsNotifier.itemPositions.value
        .firstWhereOrNull(
            (ItemPosition itemPosition) => itemPosition.index == index);
    if (itemPosition != null) {
      // Scroll directly.
      final localScrollAmount = itemPosition.itemLeadingEdge *
          primary.scrollController.position.viewportDimension;
      await primary.scrollController.animateTo(
          primary.scrollController.offset +
              localScrollAmount -
              alignment * primary.scrollController.position.viewportDimension,
          duration: duration,
          curve: curve);
    } else {
      final scrollAmount = _screenScrollCount *
          primary.scrollController.position.viewportDimension;
      final startCompleter = Completer<void>();
      final endCompleter = Completer<void>();
      startAnimationCallback = () {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          startAnimationCallback = () {};
          _animationController?.dispose();
          _animationController =
              AnimationController(vsync: this, duration: duration)..forward();
          opacity.parent = _opacityAnimation(opacityAnimationWeights)
              .animate(_animationController);
          secondary.scrollController.jumpTo(-direction *
              (_screenScrollCount *
                      primary.scrollController.position.viewportDimension -
                  alignment *
                      secondary.scrollController.position.viewportDimension));

          startCompleter.complete(primary.scrollController.animateTo(
              primary.scrollController.offset + direction * scrollAmount,
              duration: duration,
              curve: curve));
          endCompleter.complete(secondary.scrollController
              .animateTo(0, duration: duration, curve: curve));
        });
      };
      setState(() {
        secondary.target = index;
        secondary.alignment = alignment;
        _isTransitioning = true;
      });
      await Future.wait<void>([startCompleter.future, endCompleter.future]);
      _stopScroll();
    }
  }

  void _stopScroll({bool canceled = false}) {
    if (!_isTransitioning) {
      return;
    }

    if (canceled) {
      if (primary.scrollController.hasClients) {
        primary.scrollController.jumpTo(primary.scrollController.offset);
      }
      if (secondary.scrollController.hasClients) {
        secondary.scrollController.jumpTo(secondary.scrollController.offset);
      }
    }

    if (mounted) {
      setState(() {
        if (opacity.value >= 0.5) {
          // Secondary [ListView] is more visible than the primary; make it the
          // new primary.
          var temp = primary;
          primary = secondary;
          secondary = temp;
        }
        _isTransitioning = false;
        opacity.parent = const AlwaysStoppedAnimation<double>(0);
      });
    }
  }

  Animatable<double> _opacityAnimation(List<double> opacityAnimationWeights) {
    const startOpacity = 0.0;
    const endOpacity = 1.0;
    return TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: ConstantTween<double>(startOpacity),
          weight: opacityAnimationWeights[0]),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: startOpacity, end: endOpacity),
          weight: opacityAnimationWeights[1]),
      TweenSequenceItem<double>(
          tween: ConstantTween<double>(endOpacity),
          weight: opacityAnimationWeights[2]),
    ]);
  }

  void _updatePositions() {
    final itemPositions = primary.itemPositionsNotifier.itemPositions.value
        .where((ItemPosition position) =>
            position.itemLeadingEdge < 1 && position.itemTrailingEdge > 0);
    if (itemPositions.isNotEmpty) {
      PageStorage.of(context).writeState(
          context,
          itemPositions.reduce((value, element) =>
              value.itemLeadingEdge < element.itemLeadingEdge
                  ? value
                  : element));
    }
    widget.itemPositionsNotifier?.itemPositions.value = itemPositions;
  }
}

class _ListDisplayDetails {
  _ListDisplayDetails(this.scrollController,this.key);

  final itemPositionsNotifier = ItemPositionsNotifier();
  final ScrollController scrollController;

  /// The index of the item to scroll to.
  int target = 0;

  /// The desired alignment for [target].
  ///
  /// See [ItemScrollController.jumpTo] for an explanation of alignment.
  double alignment = 0;

  final Key key;
}
