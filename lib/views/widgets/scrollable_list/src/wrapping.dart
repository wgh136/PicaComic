import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that is bigger on the inside and shrink wraps its children in the
/// main axis.
///
/// [ShrinkWrappingViewport] displays a subset of its children according to its
/// own dimensions and the given [offset]. As the offset varies, different
/// children are visible through the viewport.
///
/// [ShrinkWrappingViewport] differs from [Viewport] in that [Viewport] expands
/// to fill the main axis whereas [ShrinkWrappingViewport] sizes itself to match
/// its children in the main axis. This shrink wrapping behavior is expensive
/// because the children, and hence the viewport, could potentially change size
/// whenever the [offset] changes (e.g., because of a collapsing header).
///
/// [ShrinkWrappingViewport] cannot contain box children directly. Instead, use
/// a [SliverList], [SliverFixedExtentList], [SliverGrid], or a
/// [SliverToBoxAdapter], for example.
///
/// See also:
///
///  * [ListView], [PageView], [GridView], and [CustomScrollView], which combine
///    [Scrollable] and [ShrinkWrappingViewport] into widgets that are easier to
///    use.
///  * [SliverToBoxAdapter], which allows a box widget to be placed inside a
///    sliver context (the opposite of this widget).
///  * [Viewport], a viewport that does not shrink-wrap its contents.
class CustomShrinkWrappingViewport extends CustomViewport {
  /// Creates a widget that is bigger on the inside and shrink wraps its
  /// children in the main axis.
  ///
  /// The viewport listens to the [offset], which means you do not need to
  /// rebuild this widget when the [offset] changes.
  ///
  /// The [offset] argument must not be null.
  CustomShrinkWrappingViewport({
    Key? key,
    AxisDirection axisDirection = AxisDirection.down,
    AxisDirection? crossAxisDirection,
    double anchor = 0.0,
    required ViewportOffset offset,
    List<RenderSliver>? children,
    Key? center,
    double? cacheExtent,
    List<Widget> slivers = const <Widget>[],
  })  : _anchor = anchor,
        super(
            key: key,
            axisDirection: axisDirection,
            crossAxisDirection: crossAxisDirection,
            offset: offset,
            center: center,
            cacheExtent: cacheExtent,
            slivers: slivers);

  // [Viewport] enforces constraints on [Viewport.anchor], so we need our own
  // version.
  final double _anchor;

  @override
  double get anchor => _anchor;

  @override
  CustomRenderShrinkWrappingViewport createRenderObject(BuildContext context) {
    return CustomRenderShrinkWrappingViewport(
      axisDirection: axisDirection,
      crossAxisDirection: crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection),
      offset: offset,
      anchor: anchor,
      cacheExtent: cacheExtent,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, CustomRenderShrinkWrappingViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..cacheExtent = cacheExtent
      ..cacheExtentStyle = cacheExtentStyle
      ..clipBehavior = clipBehavior;
  }
}

/// A render object that is bigger on the inside and shrink wraps its children
/// in the main axis.
///
/// [RenderShrinkWrappingViewport] displays a subset of its children according
/// to its own dimensions and the given [offset]. As the offset varies, different
/// children are visible through the viewport.
///
/// [RenderShrinkWrappingViewport] differs from [RenderViewport] in that
/// [RenderViewport] expands to fill the main axis whereas
/// [RenderShrinkWrappingViewport] sizes itself to match its children in the
/// main axis. This shrink wrapping behavior is expensive because the children,
/// and hence the viewport, could potentially change size whenever the [offset]
/// changes (e.g., because of a collapsing header).
///
/// [RenderShrinkWrappingViewport] cannot contain [RenderBox] children directly.
/// Instead, use a [RenderSliverList], [RenderSliverFixedExtentList],
/// [RenderSliverGrid], or a [RenderSliverToBoxAdapter], for example.
///
/// See also:
///
///  * [RenderViewport], a viewport that does not shrink-wrap its contents.
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
class CustomRenderShrinkWrappingViewport extends CustomRenderViewport {
  /// Creates a viewport (for [RenderSliver] objects) that shrink-wraps its
  /// contents.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  CustomRenderShrinkWrappingViewport({
    AxisDirection axisDirection = AxisDirection.down,
    required AxisDirection crossAxisDirection,
    required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver>? children,
    RenderSliver? center,
    double? cacheExtent,
  })  : _anchor = anchor,
        super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          center: center,
          cacheExtent: cacheExtent,
          children: children,
        );

  double _anchor;

  @override
  double get anchor => _anchor;

  @override
  bool get sizedByParent => false;

  double lastMainAxisExtent = -1;

  @override
  set anchor(double value) {
    if (value == _anchor) return;
    _anchor = value;
    markNeedsLayout();
  }

  late double _shrinkWrapExtent;

  /// This value is set during layout based on the [CacheExtentStyle].
  ///
  /// When the style is [CacheExtentStyle.viewport], it is the main axis extent
  /// of the viewport multiplied by the requested cache extent, which is still
  /// expressed in pixels.
  double? _calculatedCacheExtent;

  /// While List in a wrapping container, eg. ListView，the mainAxisExtent will
  /// be infinite. This time need to change mainAxisExtent to this value.
  final double _maxMainAxisExtent = double.maxFinite;

  @override
  void performLayout() {
    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }

    assert(center!.parent == this);

    final BoxConstraints constraints = this.constraints;
    if (firstChild == null) {
      switch (axis) {
        case Axis.vertical:
          assert(constraints.hasBoundedWidth);
          size = Size(constraints.maxWidth, constraints.minHeight);
          break;
        case Axis.horizontal:
          assert(constraints.hasBoundedHeight);
          size = Size(constraints.minWidth, constraints.maxHeight);
          break;
      }
      offset.applyViewportDimension(0.0);
      _maxScrollExtent = 0.0;
      _shrinkWrapExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0.0, 0.0);
      return;
    }

    double mainAxisExtent;
    final double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        assert(constraints.hasBoundedWidth);
        mainAxisExtent = constraints.maxHeight;
        crossAxisExtent = constraints.maxWidth;
        break;
      case Axis.horizontal:
        assert(constraints.hasBoundedHeight);
        mainAxisExtent = constraints.maxWidth;
        crossAxisExtent = constraints.maxHeight;
        break;
    }

    if (mainAxisExtent.isInfinite) {
      mainAxisExtent = _maxMainAxisExtent;
    }

    final centerOffsetAdjustment = center!.centerOffsetAdjustment;

    double correction;
    double effectiveExtent;
    do {
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent,
          offset.pixels + centerOffsetAdjustment);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        switch (axis) {
          case Axis.vertical:
            effectiveExtent = constraints.constrainHeight(_shrinkWrapExtent);
            break;
          case Axis.horizontal:
            effectiveExtent = constraints.constrainWidth(_shrinkWrapExtent);
            break;
        }
        // *** Difference from [RenderViewport].
        final top = _minScrollExtent + mainAxisExtent * anchor;
        final bottom = _maxScrollExtent - mainAxisExtent * (1.0 - anchor);

        final maxScrollOffset = math.max(math.min(0.0, top), bottom);
        final minScrollOffset = math.min(top, maxScrollOffset);

        final bool didAcceptViewportDimension =
            offset.applyViewportDimension(effectiveExtent);
        final bool didAcceptContentDimension =
            offset.applyContentDimensions(minScrollOffset, maxScrollOffset);
        if (didAcceptViewportDimension && didAcceptContentDimension) {
          break;
        }
      }
    } while (true);
    switch (axis) {
      case Axis.vertical:
        size =
            constraints.constrainDimensions(crossAxisExtent, effectiveExtent);
        break;
      case Axis.horizontal:
        size =
            constraints.constrainDimensions(effectiveExtent, crossAxisExtent);
        break;
    }
  }

  double _attemptLayout(
      double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;
    _shrinkWrapExtent = 0.0;

    // centerOffset is the offset from the leading edge of the RenderViewport
    // to the zero scroll offset (the line between the forward slivers and the
    // reverse slivers).
    final centerOffset = mainAxisExtent * anchor - correctedOffset;
    final reverseDirectionRemainingPaintExtent =
        centerOffset.clamp(0.0, mainAxisExtent);
    final forwardDirectionRemainingPaintExtent =
        (mainAxisExtent - centerOffset).clamp(0.0, mainAxisExtent);

    switch (cacheExtentStyle) {
      case CacheExtentStyle.pixel:
        _calculatedCacheExtent = cacheExtent;
        break;
      case CacheExtentStyle.viewport:
        _calculatedCacheExtent = mainAxisExtent * cacheExtent!;
        break;
    }

    final fullCacheExtent = mainAxisExtent + 2 * _calculatedCacheExtent!;
    final centerCacheOffset = centerOffset + _calculatedCacheExtent!;
    final reverseDirectionRemainingCacheExtent =
        centerCacheOffset.clamp(0.0, fullCacheExtent);
    final forwardDirectionRemainingCacheExtent =
        (fullCacheExtent - centerCacheOffset).clamp(0.0, fullCacheExtent);

    final leadingNegativeChild = childBefore(center!);

    if (leadingNegativeChild != null) {
      // negative scroll offsets
      final result = layoutChildSequence(
        child: leadingNegativeChild,
        scrollOffset: math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        overlap: 0.0,
        layoutOffset: forwardDirectionRemainingPaintExtent,
        remainingPaintExtent: reverseDirectionRemainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: GrowthDirection.reverse,
        advance: childBefore,
        remainingCacheExtent: reverseDirectionRemainingCacheExtent,
        cacheOrigin: (mainAxisExtent - centerOffset)
            .clamp(-_calculatedCacheExtent!, 0.0),
      );
      if (result != 0.0) return -result;
    }

    // positive scroll offsets
    return layoutChildSequence(
      child: center,
      scrollOffset: math.max(0.0, -centerOffset),
      overlap:
          leadingNegativeChild == null ? math.min(0.0, -centerOffset) : 0.0,
      layoutOffset: centerOffset >= mainAxisExtent
          ? centerOffset
          : reverseDirectionRemainingPaintExtent,
      remainingPaintExtent: forwardDirectionRemainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: forwardDirectionRemainingCacheExtent,
      cacheOrigin: centerOffset.clamp(-_calculatedCacheExtent!, 0.0),
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
        break;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
        break;
    }
    if (childLayoutGeometry.hasVisualOverflow) _hasVisualOverflow = true;
    _shrinkWrapExtent += childLayoutGeometry.maxPaintExtent;
    growSize = _shrinkWrapExtent;
  }

  @override
  String labelForChild(int index) => 'child $index';
}

/// A widget that is bigger on the inside.
///
/// [Viewport] is the visual workhorse of the scrolling machinery. It displays a
/// subset of its children according to its own dimensions and the given
/// [offset]. As the offset varies, different children are visible through
/// the viewport.
///
/// [Viewport] hosts a bidirectional list of slivers, anchored on a [center]
/// sliver, which is placed at the zero scroll offset. The center widget is
/// displayed in the viewport according to the [anchor] property.
///
/// Slivers that are earlier in the child list than [center] are displayed in
/// reverse order in the reverse [axisDirection] starting from the [center]. For
/// example, if the [axisDirection] is [AxisDirection.down], the first sliver
/// before [center] is placed above the [center]. The slivers that are later in
/// the child list than [center] are placed in order in the [axisDirection]. For
/// example, in the preceding scenario, the first sliver after [center] is
/// placed below the [center].
///
/// [Viewport] cannot contain box children directly. Instead, use a
/// [SliverList], [SliverFixedExtentList], [SliverGrid], or a
/// [SliverToBoxAdapter], for example.
///
/// See also:
///
///  * [ListView], [PageView], [GridView], and [CustomScrollView], which combine
///    [Scrollable] and [Viewport] into widgets that are easier to use.
///  * [SliverToBoxAdapter], which allows a box widget to be placed inside a
///    sliver context (the opposite of this widget).
///  * [ShrinkWrappingViewport], a variant of [Viewport] that shrink-wraps its
///    contents along the main axis.
abstract class CustomViewport extends MultiChildRenderObjectWidget {
  /// Creates a widget that is bigger on the inside.
  ///
  /// The viewport listens to the [offset], which means you do not need to
  /// rebuild this widget when the [offset] changes.
  ///
  /// The [offset] argument must not be null.
  ///
  /// The [cacheExtent] must be specified if the [cacheExtentStyle] is
  /// not [CacheExtentStyle.pixel].
  CustomViewport({
    Key? key,
    this.axisDirection = AxisDirection.down,
    this.crossAxisDirection,
    this.anchor = 0.0,
    required this.offset,
    this.center,
    this.cacheExtent,
    this.cacheExtentStyle = CacheExtentStyle.pixel,
    this.clipBehavior = Clip.hardEdge,
    List<Widget> slivers = const <Widget>[],
  })  : assert(offset != null),
        assert(slivers != null),
        assert(center == null ||
            slivers.where((Widget child) => child.key == center).length == 1),
        assert(cacheExtentStyle != null),
        assert(cacheExtentStyle != CacheExtentStyle.viewport ||
            cacheExtent != null),
        assert(clipBehavior != null),
        super(key: key, children: slivers);

  /// The direction in which the [offset]'s [ViewportOffset.pixels] increases.
  ///
  /// For example, if the [axisDirection] is [AxisDirection.down], a scroll
  /// offset of zero is at the top of the viewport and increases towards the
  /// bottom of the viewport.
  final AxisDirection axisDirection;

  /// The direction in which child should be laid out in the cross axis.
  ///
  /// If the [axisDirection] is [AxisDirection.down] or [AxisDirection.up], this
  /// property defaults to [AxisDirection.left] if the ambient [Directionality]
  /// is [TextDirection.rtl] and [AxisDirection.right] if the ambient
  /// [Directionality] is [TextDirection.ltr].
  ///
  /// If the [axisDirection] is [AxisDirection.left] or [AxisDirection.right],
  /// this property defaults to [AxisDirection.down].
  final AxisDirection? crossAxisDirection;

  /// The relative position of the zero scroll offset.
  ///
  /// For example, if [anchor] is 0.5 and the [axisDirection] is
  /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
  /// vertically centered within the viewport. If the [anchor] is 1.0, and the
  /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
  /// on the left edge of the viewport.
  final double anchor;

  /// Which part of the content inside the viewport should be visible.
  ///
  /// The [ViewportOffset.pixels] value determines the scroll offset that the
  /// viewport uses to select which part of its content to display. As the user
  /// scrolls the viewport, this value changes, which changes the content that
  /// is displayed.
  ///
  /// Typically a [ScrollPosition].
  final ViewportOffset offset;

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// Children after [center] will be placed in the [axisDirection] relative to
  /// the [center]. Children before [center] will be placed in the opposite of
  /// the [axisDirection] relative to the [center].
  ///
  /// The [center] must be the key of a child of the viewport.
  final Key? center;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtent}
  ///
  /// See also:
  ///
  ///  * [cacheExtentStyle], which controls the units of the [cacheExtent].
  final double? cacheExtent;

  /// {@macro flutter.rendering.RenderViewportBase.cacheExtentStyle}
  final CacheExtentStyle cacheExtentStyle;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Given a [BuildContext] and an [AxisDirection], determine the correct cross
  /// axis direction.
  ///
  /// This depends on the [Directionality] if the `axisDirection` is vertical;
  /// otherwise, the default cross axis direction is downwards.
  static AxisDirection getDefaultCrossAxisDirection(
      BuildContext context, AxisDirection axisDirection) {
    assert(axisDirection != null);
    switch (axisDirection) {
      case AxisDirection.up:
        assert(debugCheckHasDirectionality(
          context,
          why:
              'to determine the cross-axis direction when the viewport has an \'up\' axisDirection',
          alternative:
              'Alternatively, consider specifying the \'crossAxisDirection\' argument on the Viewport.',
        ));
        return textDirectionToAxisDirection(Directionality.of(context));
      case AxisDirection.right:
        return AxisDirection.down;
      case AxisDirection.down:
        assert(debugCheckHasDirectionality(
          context,
          why:
              'to determine the cross-axis direction when the viewport has a \'down\' axisDirection',
          alternative:
              'Alternatively, consider specifying the \'crossAxisDirection\' argument on the Viewport.',
        ));
        return textDirectionToAxisDirection(Directionality.of(context));
      case AxisDirection.left:
        return AxisDirection.down;
    }
  }

  @override
  CustomRenderViewport createRenderObject(BuildContext context);

  @override
  _ViewportElement createElement() => _ViewportElement(this);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<AxisDirection>('axisDirection', axisDirection));
    properties.add(EnumProperty<AxisDirection>(
        'crossAxisDirection', crossAxisDirection,
        defaultValue: null));
    properties.add(DoubleProperty('anchor', anchor));
    properties.add(DiagnosticsProperty<ViewportOffset>('offset', offset));
    if (center != null) {
      properties.add(DiagnosticsProperty<Key>('center', center));
    } else if (children.isNotEmpty && children.first.key != null) {
      properties.add(DiagnosticsProperty<Key>('center', children.first.key,
          tooltip: 'implicit'));
    }
    properties.add(DiagnosticsProperty<double>('cacheExtent', cacheExtent));
    properties.add(DiagnosticsProperty<CacheExtentStyle>(
        'cacheExtentStyle', cacheExtentStyle));
  }
}

class _ViewportElement extends MultiChildRenderObjectElement {
  /// Creates an element that uses the given widget as its configuration.
  _ViewportElement(CustomViewport widget) : super(widget);

  @override
  CustomViewport get widget => super.widget as CustomViewport;

  @override
  CustomRenderViewport get renderObject =>
      super.renderObject as CustomRenderViewport;

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    _updateCenter();
  }

  @override
  void update(MultiChildRenderObjectWidget newWidget) {
    super.update(newWidget);
    _updateCenter();
  }

  void _updateCenter() {
    if (widget.center != null) {
      renderObject.center = children
          .singleWhere((Element element) => element.widget.key == widget.center)
          .renderObject as RenderSliver?;
    } else if (children.isNotEmpty) {
      renderObject.center = children.first.renderObject as RenderSliver?;
    } else {
      renderObject.center = null;
    }
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where((Element e) {
      final RenderSliver renderSliver = e.renderObject! as RenderSliver;
      return renderSliver.geometry!.visible;
    }).forEach(visitor);
  }
}

class CustomSliverPhysicalContainerParentData
    extends SliverPhysicalContainerParentData {
  /// The position of the child relative to the zero scroll offset.
  ///
  /// The number of pixels from from the zero scroll offset of the parent sliver
  /// (the line at which its [SliverConstraints.scrollOffset] is zero) to the
  /// side of the child closest to that offset. A [layoutOffset] can be null
  /// when it cannot be determined. The value will be set after layout.
  ///
  /// In a typical list, this does not change as the parent is scrolled.
  ///
  /// Defaults to null.
  double? layoutOffset;

  GrowthDirection? growthDirection;
}

/// A render object that is bigger on the inside.
///
/// [RenderViewport] is the visual workhorse of the scrolling machinery. It
/// displays a subset of its children according to its own dimensions and the
/// given [offset]. As the offset varies, different children are visible through
/// the viewport.
///
/// [RenderViewport] hosts a bidirectional list of slivers, anchored on a
/// [center] sliver, which is placed at the zero scroll offset. The center
/// widget is displayed in the viewport according to the [anchor] property.
///
/// Slivers that are earlier in the child list than [center] are displayed in
/// reverse order in the reverse [axisDirection] starting from the [center]. For
/// example, if the [axisDirection] is [AxisDirection.down], the first sliver
/// before [center] is placed above the [center]. The slivers that are later in
/// the child list than [center] are placed in order in the [axisDirection]. For
/// example, in the preceding scenario, the first sliver after [center] is
/// placed below the [center].
///
/// [RenderViewport] cannot contain [RenderBox] children directly. Instead, use
/// a [RenderSliverList], [RenderSliverFixedExtentList], [RenderSliverGrid], or
/// a [RenderSliverToBoxAdapter], for example.
///
/// See also:
///
///  * [RenderSliver], which explains more about the Sliver protocol.
///  * [RenderBox], which explains more about the Box protocol.
///  * [RenderSliverToBoxAdapter], which allows a [RenderBox] object to be
///    placed inside a [RenderSliver] (the opposite of this class).
///  * [RenderShrinkWrappingViewport], a variant of [RenderViewport] that
///    shrink-wraps its contents along the main axis.
abstract class CustomRenderViewport
    extends RenderViewportBase<CustomSliverPhysicalContainerParentData> {
  /// Creates a viewport for [RenderSliver] objects.
  ///
  /// If the [center] is not specified, then the first child in the `children`
  /// list, if any, is used.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [new ViewportOffset.zero] or [new ViewportOffset.fixed].
  CustomRenderViewport({
    AxisDirection axisDirection = AxisDirection.down,
    required AxisDirection crossAxisDirection,
    required ViewportOffset offset,
    double anchor = 0.0,
    List<RenderSliver>? children,
    RenderSliver? center,
    double? cacheExtent,
    CacheExtentStyle cacheExtentStyle = CacheExtentStyle.pixel,
    Clip clipBehavior = Clip.hardEdge,
  })  : assert(anchor != null),
        assert(anchor >= 0.0 && anchor <= 1.0),
        assert(cacheExtentStyle != CacheExtentStyle.viewport ||
            cacheExtent != null),
        assert(clipBehavior != null),
        _center = center,
        super(
          axisDirection: axisDirection,
          crossAxisDirection: crossAxisDirection,
          offset: offset,
          cacheExtent: cacheExtent,
          cacheExtentStyle: cacheExtentStyle,
          clipBehavior: clipBehavior,
        ) {
    addAll(children);
    if (center == null && firstChild != null) _center = firstChild;
  }

  /// If a [RenderAbstractViewport] overrides
  /// [RenderObject.describeSemanticsConfiguration] to add the [SemanticsTag]
  /// [useTwoPaneSemantics] to its [SemanticsConfiguration], two semantics nodes
  /// will be used to represent the viewport with its associated scrolling
  /// actions in the semantics tree.
  ///
  /// Two semantics nodes (an inner and an outer node) are necessary to exclude
  /// certain child nodes (via the [excludeFromScrolling] tag) from the
  /// scrollable area for semantic purposes: The [SemanticsNode]s of children
  /// that should be excluded from scrolling will be attached to the outer node.
  /// The semantic scrolling actions and the [SemanticsNode]s of scrollable
  /// children will be attached to the inner node, which itself is a child of
  /// the outer node.
  ///
  /// See also:
  ///
  /// * [RenderViewportBase.describeSemanticsConfiguration], which adds this
  ///   tag to its [SemanticsConfiguration].
  static const SemanticsTag useTwoPaneSemantics =
      SemanticsTag('RenderViewport.twoPane');

  /// When a top-level [SemanticsNode] below a [RenderAbstractViewport] is
  /// tagged with [excludeFromScrolling] it will not be part of the scrolling
  /// area for semantic purposes.
  ///
  /// This behavior is only active if the [RenderAbstractViewport]
  /// tagged its [SemanticsConfiguration] with [useTwoPaneSemantics].
  /// Otherwise, the [excludeFromScrolling] tag is ignored.
  ///
  /// As an example, a [RenderSliver] that stays on the screen within a
  /// [Scrollable] even though the user has scrolled past it (e.g. a pinned app
  /// bar) can tag its [SemanticsNode] with [excludeFromScrolling] to indicate
  /// that it should no longer be considered for semantic actions related to
  /// scrolling.
  static const SemanticsTag excludeFromScrolling =
      SemanticsTag('RenderViewport.excludeFromScrolling');

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! CustomSliverPhysicalContainerParentData)
      child.parentData = CustomSliverPhysicalContainerParentData();
  }

  /// The relative position of the zero scroll offset.
  ///
  /// For example, if [anchor] is 0.5 and the [axisDirection] is
  /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
  /// vertically centered within the viewport. If the [anchor] is 1.0, and the
  /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
  /// on the left edge of the viewport.
  double get anchor;

  set anchor(double value);

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// This child that will be at the position defined by [anchor] when the
  /// [ViewportOffset.pixels] of [offset] is `0`.
  ///
  /// Children after [center] will be placed in the [axisDirection] relative to
  /// the [center]. Children before [center] will be placed in the opposite of
  /// the [axisDirection] relative to the [center].
  ///
  /// The [center] must be a child of the viewport.
  RenderSliver? get center => _center;
  RenderSliver? _center;

  set center(RenderSliver? value) {
    if (value == _center) return;
    _center = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(() {
      if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
        switch (axis) {
          case Axis.vertical:
            if (!constraints.hasBoundedHeight) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Vertical viewport was given unbounded height.'),
                ErrorDescription(
                    'Viewports expand in the scrolling direction to fill their container. '
                    'In this case, a vertical viewport was given an unlimited amount of '
                    'vertical space in which to expand. This situation typically happens '
                    'when a scrollable widget is nested inside another scrollable widget.'),
                ErrorHint(
                    'If this widget is always nested in a scrollable widget there '
                    'is no need to use a viewport because there will always be enough '
                    'vertical space for the children. In this case, consider using a '
                    'Column instead. Otherwise, consider using the "shrinkWrap" property '
                    '(or a ShrinkWrappingViewport) to size the height of the viewport '
                    'to the sum of the heights of its children.')
              ]);
            }
            if (!constraints.hasBoundedWidth) {
              throw FlutterError(
                  'Vertical viewport was given unbounded width.\n'
                  'Viewports expand in the cross axis to fill their container and '
                  'constrain their children to match their extent in the cross axis. '
                  'In this case, a vertical viewport was given an unlimited amount of '
                  'horizontal space in which to expand.');
            }
            break;
          case Axis.horizontal:
            if (!constraints.hasBoundedWidth) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Horizontal viewport was given unbounded width.'),
                ErrorDescription(
                    'Viewports expand in the scrolling direction to fill their container. '
                    'In this case, a horizontal viewport was given an unlimited amount of '
                    'horizontal space in which to expand. This situation typically happens '
                    'when a scrollable widget is nested inside another scrollable widget.'),
                ErrorHint(
                    'If this widget is always nested in a scrollable widget there '
                    'is no need to use a viewport because there will always be enough '
                    'horizontal space for the children. In this case, consider using a '
                    'Row instead. Otherwise, consider using the "shrinkWrap" property '
                    '(or a ShrinkWrappingViewport) to size the width of the viewport '
                    'to the sum of the widths of its children.')
              ]);
            }
            if (!constraints.hasBoundedHeight) {
              throw FlutterError(
                  'Horizontal viewport was given unbounded height.\n'
                  'Viewports expand in the cross axis to fill their container and '
                  'constrain their children to match their extent in the cross axis. '
                  'In this case, a horizontal viewport was given an unlimited amount of '
                  'vertical space in which to expand.');
            }
            break;
        }
      }
      return true;
    }());
    return constraints.biggest;
  }

  // Out-of-band data computed during layout.
  late double _minScrollExtent;
  late double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  double growSize = 0;

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
        break;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
        break;
    }
    if (childLayoutGeometry.hasVisualOverflow) _hasVisualOverflow = true;
  }

  @override
  void updateChildLayoutOffset(RenderSliver child, double layoutOffset,
      GrowthDirection growthDirection) {
    final CustomSliverPhysicalContainerParentData childParentData =
        child.parentData! as CustomSliverPhysicalContainerParentData;
    childParentData.layoutOffset = layoutOffset;
    childParentData.growthDirection = growthDirection;
  }

  @override
  Offset paintOffsetOf(RenderSliver child) {
    final CustomSliverPhysicalContainerParentData childParentData =
        child.parentData! as CustomSliverPhysicalContainerParentData;
    return computeAbsolutePaintOffset(
        child, childParentData.layoutOffset!, childParentData.growthDirection!);
  }

  @override
  double scrollOffsetOf(RenderSliver child, double scrollOffsetWithinChild) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    switch (growthDirection) {
      case GrowthDirection.forward:
        double scrollOffsetToChild = 0.0;
        RenderSliver? current = center;
        while (current != child) {
          scrollOffsetToChild += current!.geometry!.scrollExtent;
          current = childAfter(current);
        }
        return scrollOffsetToChild + scrollOffsetWithinChild;
      case GrowthDirection.reverse:
        double scrollOffsetToChild = 0.0;
        RenderSliver? current = childBefore(center!);
        while (current != child) {
          scrollOffsetToChild -= current!.geometry!.scrollExtent;
          current = childBefore(current);
        }
        return scrollOffsetToChild - scrollOffsetWithinChild;
    }
  }

  @override
  double maxScrollObstructionExtentBefore(RenderSliver child) {
    assert(child.parent == this);
    final GrowthDirection growthDirection = child.constraints.growthDirection;
    switch (growthDirection) {
      case GrowthDirection.forward:
        double pinnedExtent = 0.0;
        RenderSliver? current = center;
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childAfter(current);
        }
        return pinnedExtent;
      case GrowthDirection.reverse:
        double pinnedExtent = 0.0;
        RenderSliver? current = childBefore(center!);
        while (current != child) {
          pinnedExtent += current!.geometry!.maxScrollObstructionExtent;
          current = childBefore(current);
        }
        return pinnedExtent;
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final Offset offset = paintOffsetOf(child as RenderSliver);
    transform.translate(offset.dx, offset.dy);
  }

  @override
  double computeChildMainAxisPosition(
      RenderSliver child, double parentMainAxisPosition) {
    final CustomSliverPhysicalContainerParentData childParentData =
        child.parentData! as CustomSliverPhysicalContainerParentData;
    switch (applyGrowthDirectionToAxisDirection(
        child.constraints.axisDirection, child.constraints.growthDirection)) {
      case AxisDirection.down:
      case AxisDirection.right:
        return parentMainAxisPosition - childParentData.layoutOffset!;
      case AxisDirection.up:
        return (size.height - parentMainAxisPosition) -
            childParentData.layoutOffset!;
      case AxisDirection.left:
        return (size.width - parentMainAxisPosition) -
            childParentData.layoutOffset!;
    }
  }

  @override
  int get indexOfFirstChild {
    assert(center != null);
    assert(center!.parent == this);
    assert(firstChild != null);
    int count = 0;
    RenderSliver? child = center;
    while (child != firstChild) {
      count -= 1;
      child = childBefore(child!);
    }
    return count;
  }

  @override
  String labelForChild(int index) {
    if (index == 0) return 'center child';
    return 'child $index';
  }

  @override
  Iterable<RenderSliver> get childrenInPaintOrder sync* {
    if (firstChild == null) return;
    RenderSliver? child = firstChild;
    while (child != center) {
      yield child!;
      child = childAfter(child);
    }
    child = lastChild;
    while (true) {
      yield child!;
      if (child == center) return;
      child = childBefore(child);
    }
  }

  @override
  Iterable<RenderSliver> get childrenInHitTestOrder sync* {
    if (firstChild == null) return;
    RenderSliver? child = center;
    while (child != null) {
      yield child;
      child = childAfter(child);
    }
    child = childBefore(center!);
    while (child != null) {
      yield child;
      child = childBefore(child);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('anchor', anchor));
  }
}
