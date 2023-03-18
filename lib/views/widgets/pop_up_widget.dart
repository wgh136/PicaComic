import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PopUpWidget<T> extends PopupRoute<T>{
  PopUpWidget(this.widget);

  final Widget widget;
  @override
  Color? get barrierColor => Colors.black54;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "exit";

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return Center(
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        clipBehavior: Clip.antiAlias,
        width: 550,
        height: MediaQuery.of(context).size.height*0.9,
        child: ClipRect(
          child: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => widget,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);
}

Future<T> showPopUpWidget<T>(BuildContext context, Widget widget) async{
  return await Navigator.of(context).push(PopUpWidget(widget));
}

void showAdaptiveWidget(BuildContext context, Widget widget){
  //根据当前宽度显示页面
  //当页面宽度大于600, 显示弹窗
  //小于600, 跳转页面
  MediaQuery.of(context).size.width>600?showPopUpWidget(context, widget):Get.to(()=>widget);
}