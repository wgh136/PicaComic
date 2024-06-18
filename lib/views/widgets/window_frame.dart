import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/app_views/image_favorites.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/downloading_page.dart';
import 'package:pica_comic/views/history.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:window_manager/window_manager.dart';

import '../app_views/accounts_page.dart';

const _kTitleBarHeight = 32.0;

class WindowFrameController extends StateController {
  bool useDarkTheme = false;

  bool isHideWindowFrame = false;

  void setDarkTheme() {
    useDarkTheme = true;
    update();
  }

  void resetTheme() {
    useDarkTheme = false;
    update();
  }

  VoidCallback openSideBar = () {};

  void hideWindowFrame() {
    isHideWindowFrame = true;
    update();
  }

  void showWindowFrame() {
    isHideWindowFrame = false;
    update();
  }
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
      if (controller.isHideWindowFrame) return child;

      return Stack(
        children: [
          Positioned.fill(
              child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: _kTitleBarHeight)),
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
                  child: SizedBox(
                    height: _kTitleBarHeight,
                    child: Row(
                      children: [
                        buildMenuButton(controller, context)
                            .toAlign(Alignment.centerLeft),
                        Expanded(
                          child: DragToMoveArea(
                            child: Text(
                              'Pica Comic',
                              style: TextStyle(
                                fontSize: 13,
                                color: (controller.useDarkTheme ||
                                        Theme.of(context).brightness ==
                                            Brightness.dark)
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ).toAlign(Alignment.centerLeft).paddingLeft(4),
                          ),
                        ),
                        Theme(
                          data: Theme.of(context).copyWith(
                            brightness: controller.useDarkTheme
                                ? Brightness.dark
                                : null,
                          ),
                          child: const WindowButtons(),
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
                  child: SizedBox(
                    height: _kTitleBarHeight,
                    child: Row(
                      children: [
                        const DragToMoveArea(
                          child: SizedBox(
                            height: double.infinity,
                            width: 16,
                          ),
                        ),
                        const SizedBox(
                          width: 52,
                        ),
                        Expanded(
                          child: DragToMoveArea(
                            child: Text(
                              'Pica Comic',
                              style: TextStyle(
                                fontSize: 13,
                                color: (controller.useDarkTheme ||
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
      );
    });
  }

  Widget buildMenuButton(
      WindowFrameController controller, BuildContext context) {
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
                  color: (controller.useDarkTheme ||
                          Theme.of(context).brightness == Brightness.dark)
                      ? Colors.white
                      : Colors.black),
            ),
          ),
        ));
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
                    ).paddingTop(_kTitleBarHeight),
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
              showAdaptiveWidget(App.globalContext!, AccountsPage());
            }),
        buildItem(
            icon: Icons.history,
            title: '历史记录'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => const HistoryPage(), preventDuplicate: true);
            }),
        buildItem(
            icon: Icons.download_outlined,
            title: '已下载'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => const DownloadPage(), preventDuplicate: true);
            }),
        buildItem(
            icon: Icons.downloading,
            title: '下载管理器'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              showAdaptiveWidget(App.globalContext!, const DownloadingPage());
            }),
        buildItem(
            icon: Icons.image_outlined,
            title: '图片收藏'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => const ImageFavoritesPage(), preventDuplicate: true);
            }),
        const Divider().paddingHorizontal(8),
        buildItem(
            icon: Icons.search,
            title: '搜索'.tl,
            onTap: () {
              StateController.find<WindowFrameController>().openSideBar();
              MainPage.to(() => PreSearchPage(), preventDuplicate: true);
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

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  State<WindowButtons> createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> with WindowListener{
  bool isMaximized = false;

  @override
  void initState() {
    windowManager.addListener(this);
    windowManager.isMaximized().then((value) {
      if(value) {
        setState(() {
          isMaximized = true;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {
      isMaximized = true;
    });
    super.onWindowMaximize();
  }

  @override
  void onWindowUnmaximize() {
    setState(() {
      isMaximized = false;
    });
    super.onWindowUnmaximize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.iconTheme.color ?? Colors.black;
    final hoverColor = theme.colorScheme.surfaceContainerHighest;

    return SizedBox(
      width: 138,
      height: _kTitleBarHeight,
      child: Row(
        children: [
          WindowButton(
            icon: MinimizeIcon(color: color),
            hoverColor: hoverColor,
            onPressed: () async {
              bool isMinimized = await windowManager.isMinimized();
              if (isMinimized) {
                windowManager.restore();
              } else {
                windowManager.minimize();
              }
            },
          ),
          if (isMaximized)
            WindowButton(
              icon: RestoreIcon(
                color: color,
              ),
              hoverColor: hoverColor,
              onPressed: () {
                windowManager.unmaximize();
              },
            )
          else
            WindowButton(
              icon: MaximizeIcon(
                color: color,
              ),
              hoverColor: hoverColor,
              onPressed: () {
                windowManager.maximize();
              },
            ),
          WindowButton(
            icon: CloseIcon(
              color: color,
            ),
            hoverIcon: CloseIcon(
              color: theme.brightness == Brightness.light
                  ? Colors.white
                  : Colors.black,
            ),
            hoverColor: Colors.red,
            onPressed: () {
              windowManager.close();
            },
          )
        ],
      ),
    );
  }
}

class WindowButton extends StatefulWidget {
  const WindowButton(
      {required this.icon,
      required this.onPressed,
      required this.hoverColor,
      this.hoverIcon,
      super.key});

  final Widget icon;

  final void Function() onPressed;

  final Color hoverColor;

  final Widget? hoverIcon;

  @override
  State<WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<WindowButton> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setState(() {
        isHovering = true;
      }),
      onExit: (event) => setState(() {
        isHovering = false;
      }),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: double.infinity,
          decoration:
              BoxDecoration(color: isHovering ? widget.hoverColor : null),
          child: isHovering ? widget.hoverIcon ?? widget.icon : widget.icon,
        ),
      ),
    );
  }
}

/// Close
class CloseIcon extends StatelessWidget {
  final Color color;
  const CloseIcon({super.key, required this.color});
  @override
  Widget build(BuildContext context) => _AlignedPaint(_ClosePainter(color));
}

class _ClosePainter extends _IconPainter {
  _ClosePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color, true);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), p);
    canvas.drawLine(Offset(0, size.height), Offset(size.width, 0), p);
  }
}

/// Maximize
class MaximizeIcon extends StatelessWidget {
  final Color color;
  const MaximizeIcon({super.key, required this.color});
  @override
  Widget build(BuildContext context) => _AlignedPaint(_MaximizePainter(color));
}

class _MaximizePainter extends _IconPainter {
  _MaximizePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width - 1, size.height - 1), p);
  }
}

/// Restore
class RestoreIcon extends StatelessWidget {
  final Color color;
  const RestoreIcon({
    super.key,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => _AlignedPaint(_RestorePainter(color));
}

class _RestorePainter extends _IconPainter {
  _RestorePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawRect(Rect.fromLTRB(0, 2, size.width - 2, size.height), p);
    canvas.drawLine(const Offset(2, 2), const Offset(2, 0), p);
    canvas.drawLine(const Offset(2, 0), Offset(size.width, 0), p);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, size.height - 2), p);
    canvas.drawLine(Offset(size.width, size.height - 2),
        Offset(size.width - 2, size.height - 2), p);
  }
}

/// Minimize
class MinimizeIcon extends StatelessWidget {
  final Color color;
  const MinimizeIcon({super.key, required this.color});
  @override
  Widget build(BuildContext context) => _AlignedPaint(_MinimizePainter(color));
}

class _MinimizePainter extends _IconPainter {
  _MinimizePainter(super.color);
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = getPaint(color);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), p);
  }
}

/// Helpers
abstract class _IconPainter extends CustomPainter {
  _IconPainter(this.color);
  final Color color;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AlignedPaint extends StatelessWidget {
  const _AlignedPaint(this.painter);
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.center,
        child: CustomPaint(size: const Size(10, 10), painter: painter));
  }
}

Paint getPaint(Color color, [bool isAntiAlias = false]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..isAntiAlias = isAntiAlias
  ..strokeWidth = 1;

class WindowPlacement {
  final Rect rect;

  final bool isMaximized;

  const WindowPlacement(this.rect, this.isMaximized);

  Future<void> applyToWindow() async {
    await windowManager.setBounds(rect);

    if(!validate(rect)){
      await windowManager.center();
    }

    if (isMaximized) {
      await windowManager.maximize();
    }
  }

  Future<void> writeToFile() async {
    var file = File("${App.dataPath}/window_placement");
    await file.writeAsString(jsonEncode({
      'width': rect.width,
      'height': rect.height,
      'x': rect.topLeft.dx,
      'y': rect.topLeft.dy,
      'isMaximized': isMaximized
    }));
  }

  static Future<WindowPlacement> loadFromFile() async {
    try {
      var file = File("${App.dataPath}/window_placement");
      if (!file.existsSync()) {
        return defaultPlacement;
      }
      var json = jsonDecode(await file.readAsString());
      var rect =
          Rect.fromLTWH(json['x'], json['y'], json['width'], json['height']);
      return WindowPlacement(rect, json['isMaximized']);
    } catch (e) {
      return defaultPlacement;
    }
  }

  static Future<WindowPlacement> get current async {
    var rect = await windowManager.getBounds();
    var isMaximized = await windowManager.isMaximized();
    return WindowPlacement(rect, isMaximized);
  }

  static const defaultPlacement =
      WindowPlacement(Rect.fromLTWH(10, 10, 900, 600), false);

  static WindowPlacement cache = defaultPlacement;

  static Timer? timer;

  static void loop() async {
    timer ??= Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      var placement = await WindowPlacement.current;
      if(!validate(placement.rect)){
        return;
      }
      if (placement.rect != cache.rect ||
          placement.isMaximized != cache.isMaximized) {
        cache = placement;
        await placement.writeToFile();
      }
    });
  }

  static bool validate(Rect rect){
    return rect.topLeft.dx >= 0 && rect.topLeft.dy >= 0;
  }
}
