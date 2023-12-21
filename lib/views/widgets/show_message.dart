import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';

SnackRoute? _route;

/// show message
void showMessage(BuildContext? context, String message,
    {int time = 2, bool useGet = true, Widget? action}) {
  hideMessage(context);

  var newRoute = SnackRoute(message, action);

  _route = newRoute;

  Navigator.of(App.globalContext!).push(_route!);

  Future.delayed(Duration(seconds: time), () {
    if(_route == newRoute){
      Navigator.of(App.globalContext!).removeRoute(_route!);
      _route = null;
    }
  });
}

void hideMessage(BuildContext? context) {
  try {
    if (_route != null) {
      Navigator.of(App.globalContext!).removeRoute(_route!);
      _route = null;
    }
  }
  catch(e){
    _route = null;
  }
}

void showDialogMessage(BuildContext context, String title, String message) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => App.back(context), child: Text("了解".tl))
            ],
          ));
}

void showConfirmDialog(BuildContext context, String title, String content,
    void Function() onConfirm) {
  showDialog(
      context: context,
      builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                  onPressed: () => App.back(context), child: Text("取消".tl)),
              TextButton(
                  onPressed: () {
                    App.back(context);
                    onConfirm();
                  },
                  child: Text("确认".tl)),
            ],
          ));
}

class SnackRoute<T> extends PopupRoute<T>{
  SnackRoute(this.message, this.action);

  final String message;

  final Widget? action;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => "Message";

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          left: 8,
          right: 8
        ),
        child: Material(
          color: Theme.of(context).colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(4),
          elevation: 2,
          child: Container(
            constraints:
            const BoxConstraints(minHeight: 48, maxHeight: 104, maxWidth: 380),
            padding: const EdgeInsets.only(top: 8, bottom: 8,),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      maxLines: 3,
                    )),
                if (action != null) action!,
                const SizedBox(
                  width: 8,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get maintainState => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return SlideTransition(
      position: animation.drive(
          Tween(begin: const Offset(0, 1), end: Offset.zero)
              .chain(CurveTween(curve: Curves.fastOutSlowIn))),
      child: child,
    );
  }

  @override
  bool get barrierDismissible => false;

  @override
  void onPopInvoked(bool didPop) {
    _route = null;
    super.onPopInvoked(didPop);
  }
}