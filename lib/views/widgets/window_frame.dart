import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/app_views/image_favorites.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/history.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';

import '../app_views/accounts_page.dart';

class WindowFrameController extends StateController {
  bool reverseButtonColor = false;

  void setDarkTheme() {
    reverseButtonColor = true;
    update();
  }

  void resetTheme() {
    reverseButtonColor = false;
    update();
  }

  VoidCallback openSideBar = () {};
}

class WindowFrame extends StatelessWidget {
  const WindowFrame(this.child, {super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    StateController.putIfNotExists<WindowFrameController>(
        WindowFrameController());
    if (App.isMobile) return child;
    return StateBuilder<WindowFrameController>(builder: (controller) {
      return WindowBorder(
        color: controller.reverseButtonColor ? Colors.black54 : Colors.white54,
        width: 1,
        child: Stack(
          children: [
            Positioned.fill(
                child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                  padding: EdgeInsets.only(top: appWindow.titleBarHeight)),
              child: child,
            )),
            const _SideBar(),
            if (!App.isMacOS)
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: WindowTitleBarBox(
                      child: Row(
                        children: [
                          buildMenuButton(controller, context)
                              .toAlign(Alignment.centerLeft),
                          Expanded(
                            child: MoveWindow(
                              child: Text(
                                'Pica Comic',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: (controller.reverseButtonColor ||
                                          Theme.of(context).brightness ==
                                              Brightness.dark)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ).toAlign(Alignment.centerLeft).paddingLeft(4),
                            ),
                          ),
                          _WindowButtons(
                            reverseColor: controller.reverseButtonColor,
                          ),
                        ],
                      ),
                    ),
                  ))
            else
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: WindowTitleBarBox(
                      child: Row(
                        children: [
                          MoveWindow(
                            child: const SizedBox(
                              height: double.infinity,
                              width: 16,
                            ),
                          ),
                          const _MacButtons(),
                          Expanded(
                            child: MoveWindow(
                              child: Text(
                                'Pica Comic',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: (controller.reverseButtonColor ||
                                          Theme.of(context).brightness ==
                                              Brightness.dark)
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ).toAlign(Alignment.centerLeft).paddingLeft(16),
                            ),
                          ),
                          buildMenuButton(controller, context)
                              .toAlign(Alignment.centerRight),
                        ],
                      ),
                    ),
                  ))
          ],
        ),
      );
    });
  }

  Widget buildMenuButton(WindowFrameController controller, BuildContext context) {
    return InkWell(
        onTap: () {
          controller.openSideBar();
        },
        child: SizedBox(
          width: 42,
          height: double.infinity,
          child: Center(
            child: CustomPaint(
              size: const Size(18, 20),
              painter: _MenuPainter(
                  color: (controller.reverseButtonColor ||
                          Theme.of(context).brightness ==
                              Brightness.dark)
                      ? Colors.white
                      : Colors.black),
            ),
          ),
        ));
  }
}

class _WindowButtons extends StatelessWidget {
  const _WindowButtons({Key? key, this.reverseColor = false}) : super(key: key);
  final bool reverseColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = reverseColor ? colors.onInverseSurface : colors.onSurface;
    final onMouseColor = reverseColor ? Colors.white10 : colors.surfaceVariant;
    final buttonColors = WindowButtonColors(
      iconNormal: iconColor,
      mouseOver: onMouseColor,
      mouseDown: onMouseColor,
      iconMouseOver: iconColor,
      iconMouseDown: iconColor,
    );

    final closeButtonColors = WindowButtonColors(
        mouseOver: const Color(0xFFD32F2F),
        mouseDown: const Color(0xFFB71C1C),
        iconNormal: iconColor,
        iconMouseOver: Colors.white);

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(
          colors: closeButtonColors,
          onPressed: () {
            var size = appWindow.size;
            var position = appWindow.position;
            File("${App.dataPath}/window_placement").writeAsStringSync(
                "${size.width}/${size.height}/${position.dx}/${position.dy}");
            appWindow.close();
          },
        ),
      ],
    );
  }
}

class _MenuPainter extends CustomPainter {
  final Color color;

  _MenuPainter({this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(0, size.height / 4)
      ..lineTo(size.width, size.height / 4)
      ..moveTo(0, size.height / 4 * 2)
      ..lineTo(size.width, size.height / 4 * 2)
      ..moveTo(0, size.height / 4 * 3)
      ..lineTo(size.width, size.height / 4 * 3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SideBar extends StatefulWidget {
  const _SideBar();

  @override
  State<_SideBar> createState() => __SideBarState();
}

class __SideBarState extends State<_SideBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  void run() {
    if (_controller.isAnimating) return;
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 160), value: 0);
    var controller = StateController.find<WindowFrameController>();
    controller.openSideBar = run;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: CurvedAnimation(
            parent: _controller, curve: Curves.fastEaseInToSlowEaseOut),
        builder: (context, child) {
          var value = _controller.value;
          return Stack(
            children: [
              Positioned.fill(
                  child: GestureDetector(
                onTap: run,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color:
                      value == 0 ? null : Colors.black.withOpacity(0.2 * value),
                ),
              )),
              Positioned(
                left: !App.isMacOS ? (1 - _controller.value) * (-300) : null,
                right: App.isMacOS ? (_controller.value - 1) * 300 : null,
                top: 0,
                bottom: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  elevation: 2,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: SizedBox(
                    width: 300,
                    height: double.infinity,
                    child: const SingleChildScrollView(
                      child: _SideBarBody(),
                    ).paddingTop(appWindow.titleBarHeight),
                  ),
                ),
              )
            ],
          );
        });
  }
}

class _SideBarBody extends StatelessWidget {
  const _SideBarBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        buildItem(
            icon: Icons.person_outline,
            title: '账号管理'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              showAdaptiveWidget(
                  App.globalContext!,
                  AccountsPage(
                    popUp: MediaQuery.of(App.globalContext!).size.width > 600,
                  ));
            }),
        buildItem(
            icon: Icons.history,
            title: '历史记录'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => const HistoryPage());
            }),
        buildItem(
            icon: Icons.download_outlined,
            title: '已下载'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => const DownloadPage());
            }),
        buildItem(
            icon: Icons.image_outlined,
            title: '图片收藏'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => const ImageFavoritesPage());
            }),
        const Divider().paddingHorizontal(8),
        buildItem(
            icon: Icons.search,
            title: '搜索'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => PreSearchPage());
            }),
        buildItem(
            icon: Icons.settings,
            title: '设置'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              NewSettingsPage.open();
            }),
      ],
    );
  }

  Widget buildItem(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ).paddingHorizontal(8);
  }
}

class _MacButtons extends StatefulWidget {
  const _MacButtons();

  @override
  State<_MacButtons> createState() => _MacButtonsState();
}

class _MacButtonsState extends State<_MacButtons> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setState(() => isHover = true),
      onExit: (event) => setState(() => isHover = false),
      cursor: SystemMouseCursors.click,
      child: SizedBox(
        height: double.infinity,
        width: 54,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => appWindow.close(),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: const Color(0Xffff5f57), borderRadius: BorderRadius.circular(14)),
                child: isHover
                    ? const Center(
                        child: Icon(
                          Icons.close,
                          size: 10,
                          color: _macButtonIconColor,
                        ),
                      )
                    : null,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => appWindow.minimize(),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: const Color(0Xfffebc2e),
                    borderRadius: BorderRadius.circular(14)),
                child: isHover
                    ? Center(
                        child: CustomPaint(
                          painter: _MinimizePainter(),
                          size: const Size.square(8),
                        ),
                      )
                    : null,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => appWindow.maximizeOrRestore(),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                    color: const Color(0Xff28c840),
                    borderRadius: BorderRadius.circular(14)),
                child: isHover
                    ? Center(
                        child: CustomPaint(
                          painter: _MaximizePainter(),
                          size: const Size.square(6),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimizePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var painter = Paint()
      ..color = _macButtonIconColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), painter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaximizePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var painter = Paint()
      ..color = _macButtonIconColor
      ..strokeWidth = 1
      ..style = PaintingStyle.fill;
    var path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(0, 0);
    path.lineTo(w*0.8, 0);
    path.lineTo(0, h*0.8);
    path.close();
    canvas.drawPath(path, painter);
    path = Path();
    path.moveTo(w, h);
    path.lineTo(w*0.2, h);
    path.lineTo(w, h*0.2);
    path.close();
    canvas.drawPath(path, painter);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const _macButtonIconColor = Color.fromARGB(120, 0, 0, 0);
