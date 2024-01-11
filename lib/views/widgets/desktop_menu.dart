import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';

void showDesktopMenu(BuildContext context, Offset location, List<DesktopMenuEntry> entries){
  Navigator.of(context).push(DesktopMenuRoute(entries, location));
}

class DesktopMenuRoute<T> extends PopupRoute<T>{
  final List<DesktopMenuEntry> entries;

  final Offset location;

  DesktopMenuRoute(this.entries, this.location);

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "menu";

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    const width = 186.0;
    final size = MediaQuery.of(context).size;
    var left = location.dx;
    if(left + width > size.width){
      left = size.width - width;
    }
    var top = location.dy;
    var height = 16 + 32*entries.length;
    if(top + height > size.height){
      top = size.height - height;
    }
    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: Material(
            elevation: 1,
            color: App.colors(context).surface,
            surfaceTintColor: App.colors(context).surfaceTint,
            type: MaterialType.card,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: width,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: entries.map((e) => buildEntry(e, context)).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildEntry(DesktopMenuEntry entry, BuildContext context){
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: (){
        Navigator.of(context).pop();
        entry.onClick();
      },
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            const SizedBox(width: 4,),
            if(entry.icon != null)
              Icon(entry.icon, size: 18,),
            const SizedBox(width: 4,),
            Text(entry.text),
          ],
        ),
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(opacity: animation.drive(Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.ease))), child: child,);
  }
}

class DesktopMenuEntry{
  final String text;
  final IconData? icon;
  final void Function() onClick;

  DesktopMenuEntry({required this.text, this.icon, required this.onClick});
}