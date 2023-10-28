import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';

class CustomWillPopScope extends StatelessWidget {
  const CustomWillPopScope(
      {required this.child,
      this.popGesture = false,
      Key? key,
      required this.action})
      : super(key: key);

  final Widget child;
  final bool popGesture;
  final VoidCallback action;

  static bool panStartAtEdge = false;

  @override
  Widget build(BuildContext context) {
    Widget res = App.isIOS ? child : WillPopScope(
        onWillPop: App.isDesktop ? null : () async {
          action();
          return false;
        },
        child: child);
    if(popGesture){
      res = GestureDetector(
          onPanStart: (details){
            if(details.globalPosition.dx < 64){
              panStartAtEdge = true;
            }
          },
          onPanEnd: (details) {
            if (details.velocity.pixelsPerSecond.dx < 0 ||
                details.velocity.pixelsPerSecond.dx > 0) {
              if (panStartAtEdge) {
                action();
              }
            }
            panStartAtEdge = false;
          },
          child: res);
    }
    return res;
  }
}
