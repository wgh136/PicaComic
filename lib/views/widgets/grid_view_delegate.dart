import 'package:flutter/material.dart';

class SliverGridViewWithFixedItemHeight extends StatelessWidget {
  const SliverGridViewWithFixedItemHeight(
      {required this.delegate,
      required this.maxCrossAxisExtent,
      required this.itemHeight,
      super.key});

  final SliverChildDelegate delegate;

  final double maxCrossAxisExtent;

  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
        builder: ((context, constraints) => SliverGrid(
              delegate: delegate,
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxCrossAxisExtent,
                  childAspectRatio:
                      calcChildAspectRatio(constraints.crossAxisExtent)),
            )));
  }

  double calcChildAspectRatio(double width) {
    var crossItems = width ~/ maxCrossAxisExtent;
    if (width % maxCrossAxisExtent != 0) {
      crossItems += 1;
    }
    final itemWidth = width / crossItems;
    return itemWidth / itemHeight;
  }
}
