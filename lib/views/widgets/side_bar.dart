import 'package:flutter/material.dart';

///显示侧边栏的变换
///
/// 此组件会自动适应窗口大小:
/// 大于600显示为右侧的侧边栏
/// 小于600显示为从侧边划入的页面
class SideBarRoute<T> extends PopupRoute<T> {
  SideBarRoute(this.title, this.widget,
      {this.showBarrier = true,
      this.useSurfaceTintColor = false,
      this.width = 450,
      this.addBottomPadding = true,
      this.addTopPadding = true});

  ///标题
  final String? title;

  ///子组件
  final Widget widget;

  ///是否显示Barrier
  final bool showBarrier;

  ///使用SurfaceTintColor作为背景色
  final bool useSurfaceTintColor;

  ///宽度
  final double width;

  final bool addTopPadding;

  final bool addBottomPadding;

  @override
  Color? get barrierColor => showBarrier ? Colors.black54 : Colors.transparent;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => "exit";

  @override
  Widget buildPage(
      BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    bool showSideBar = MediaQuery.of(context).size.width > 600;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        decoration: BoxDecoration(
            borderRadius:
                showSideBar ? const BorderRadius.horizontal(left: Radius.circular(16)) : null,
            color: Theme.of(context).colorScheme.surfaceTint),
        clipBehavior: Clip.antiAlias,
        width: showSideBar ? width : MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Material(
          child: ClipRect(
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  0,
                  addTopPadding ? MediaQuery.of(context).padding.top : 0,
                  MediaQuery.of(context).padding.right,
                  addBottomPadding ? MediaQuery.of(context).padding.bottom + MediaQuery.of(context).viewInsets.bottom : 0
              ),
              color: useSurfaceTintColor
                  ? Theme.of(context).colorScheme.surfaceTint.withAlpha(20)
                  : null,
              child: Column(
                children: [
                  /*
                  不能使用Appbar, 它会自动在左侧加上padding以回避屏幕左侧的阻碍
                  if (title != null)
                    AppBar(
                      title: Text(title!),
                      backgroundColor: showSideBar
                          ? Theme.of(context).colorScheme.surfaceTint.withAlpha(1)
                          : null,
                      leading: Tooltip(
                        message: "返回",
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                   */
                  if (title != null)
                    SizedBox(
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 8,
                          ),
                          Tooltip(
                            message: "返回",
                            child: IconButton(
                              iconSize: 25,
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            title!,
                            style: const TextStyle(fontSize: 22),
                          )
                        ],
                      ),
                    ),
                  Expanded(child: widget)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    var offset = Tween<Offset>(begin: const Offset(1, 0), end: const Offset(0, 0));
    return SlideTransition(
      position: offset.animate(CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
      )),
      child: child,
    );
  }
}

///显示侧边栏
///
/// 此组件会自动适应窗口大小:
/// 大于600显示为右侧的侧边栏
/// 小于600显示为从侧边划入的页面
///
/// [width] 侧边栏的宽度
///
/// [title] 标题, 为空时不显示顶部的Appbar
void showSideBar(BuildContext context, Widget widget,
    { String? title,
      bool showBarrier = true,
      bool useSurfaceTintColor = false,
      double width = 450,
      bool addTopPadding = true,
      bool addBottomPadding = true}) {
  Navigator.of(context).push(SideBarRoute(title, widget,
      showBarrier: showBarrier,
      useSurfaceTintColor: useSurfaceTintColor,
      width: width,
      addTopPadding: addTopPadding,
      addBottomPadding: addBottomPadding));
}
