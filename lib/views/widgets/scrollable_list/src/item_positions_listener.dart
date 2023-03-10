// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'item_positions_notifier.dart';
import 'scrollable_positioned_list.dart';

/// Provides a listenable iterable of [itemPositions] of items that are on
/// screen and their locations.
abstract class ItemPositionsListener {
  /// Creates an [ItemPositionsListener] that can be used by a
  /// [ScrollablePositionedList] to return the current position of items.
  factory ItemPositionsListener.create() => ItemPositionsNotifier();

  /// The position of items that are at least partially visible in the viewport.
  ValueListenable<Iterable<ItemPosition>> get itemPositions;
}

/// Position information for an item in the list.
class ItemPosition {
  /// Create an [ItemPosition].
  const ItemPosition(
      {required this.index,
      required this.itemLeadingEdge,
      required this.itemTrailingEdge});

  /// Index of the item.
  final int index;

  /// Distance in proportion of the viewport's main axis length from the leading
  /// edge of the viewport to the leading edge of the item.
  ///
  /// May be negative if the item is partially visible.
  final double itemLeadingEdge;

  /// Distance in proportion of the viewport's main axis length from the leading
  /// edge of the viewport to the trailing edge of the item.
  ///
  /// May be greater than one if the item is partially visible.
  final double itemTrailingEdge;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType) return false;
    final ItemPosition otherPosition = other;
    return otherPosition.index == index &&
        otherPosition.itemLeadingEdge == itemLeadingEdge &&
        otherPosition.itemTrailingEdge == itemTrailingEdge;
  }

  @override
  int get hashCode =>
      31 * (31 * (7 + index.hashCode) + itemLeadingEdge.hashCode) +
      itemTrailingEdge.hashCode;

  @override
  String toString() =>
      'ItemPosition(index: $index, itemLeadingEdge: $itemLeadingEdge, itemTrailingEdge: $itemTrailingEdge)';
}
