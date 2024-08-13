// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Widget whose [Element] calls a callback when the element is mounted.
class PostMountCallback extends StatelessWidget {
  /// Creates a [PostMountCallback] widget.
  const PostMountCallback({required this.child, this.callback, Key? key})
      : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  /// Callback to call when the element for this widget is mounted.
  final void Function()? callback;

  @override
  StatelessElement createElement() => _PostMountCallbackElement(this);

  @override
  Widget build(BuildContext context) => child;
}

class _PostMountCallbackElement extends StatelessElement {
  _PostMountCallbackElement(PostMountCallback widget) : super(widget);

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    final PostMountCallback postMountCallback = widget as PostMountCallback;
    postMountCallback.callback?.call();
  }
}
