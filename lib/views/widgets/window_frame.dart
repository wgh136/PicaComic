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
            Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: WindowTitleBarBox(
                    child: Row(
                      children: [
                        buildMenuButton(controller)
                            .toAlign(Alignment.centerLeft),
                        Expanded(
                          child: MoveWindow(
                            child: Text(
                              'Pica Comic',
                              style: TextStyle(
                                fontSize: 13,
                                color: controller.reverseButtonColor
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
                )),
          ],
        ),
      );
    });
  }

  Widget buildMenuButton(WindowFrameController controller) {
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
                  color: controller.reverseButtonColor
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
        CloseWindowButton(colors: closeButtonColors),
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
        animation: CurvedAnimation(parent: _controller, curve: Curves.fastEaseInToSlowEaseOut),
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
                left: (1 - _controller.value) * (-300),
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
              showAdaptiveWidget(App.globalContext!,
                  AccountsPage(popUp: MediaQuery.of(App.globalContext!).size.width>600,));
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

  Widget buildItem({required IconData icon, required String title, required VoidCallback onTap}) {
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
