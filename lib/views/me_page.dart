import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/views/accounts_page.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/all_favorites_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import '../base.dart';
import 'history.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (!UiMode.m1(context))
          const SliverPadding(padding: EdgeInsets.all(30)),
        SliverToBoxAdapter(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.fromSize(
                  size: const Size(400, 120),
                  child: const Center(
                    child: Text(
                      "Pica Comic",
                      style: TextStyle(
                          fontFamily: "font2",
                          fontSize: 40,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 650,
            childAspectRatio: 3
          ),
          delegate: SliverChildListDelegate(
              [
                MePageButton(
                  title: "账号管理".tr,
                  subTitle: "查看或修改账号信息".tr,
                  icon: Icons.switch_account,
                  onTap: () => showAdaptiveWidget(context, AccountsPage()),
                ),
                MePageButton(
                  title: "收藏夹".tr,
                  subTitle: "查看已收藏的漫画".tr,
                  icon: Icons.bookmarks,
                  onTap: () => Get.to(() => const AllFavoritesPage()),
                ),
                MePageButton(
                  title: "已下载".tr,
                  subTitle: "管理已下载的漫画".tr,
                  icon: Icons.download_for_offline,
                  onTap: () => Get.to(() => const DownloadPage()),
                ),
                MePageButton(
                  title: "历史记录".tr,
                  subTitle: "查看历史记录".tr,
                  icon: Icons.history,
                  onTap: () => Get.to(() => const HistoryPage()),
                ),

              ]
          ),
        )
      ],
    );
  }
}

Widget mePageItem(BuildContext context, Widget icon, void Function() page,
    String title, String subTitle) {
  double width;
  double screenWidth = MediaQuery.of(context).size.width;
  double padding = 10.0;
  if (screenWidth > changePoint2) {
    screenWidth -= 450;
    width = screenWidth / 2 - padding * 2;
  } else if (screenWidth > changePoint) {
    screenWidth -= 100;
    width = screenWidth / 2 - padding * 2;
  } else {
    width = screenWidth - padding * 4;
  }

  if (width > 400) {
    width = 400;
  }

  return Padding(
    padding: EdgeInsets.fromLTRB(padding, 5, padding, 5),
    child: InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      onTap: page,
      child: Container(
        width: width,
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 25, 0, 0),
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
                    child: Text(subTitle),
                  )
                ],
              ),
            ),
            const SizedBox(
              width: 5,
            ),
            Expanded(flex: 1, child: Center(child: icon)),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
      ),
    ),
  );
}

class MePageButton extends StatefulWidget {
  const MePageButton({required this.title, required this.subTitle, required this.icon, required this.onTap, super.key});

  final String title;
  final String subTitle;
  final IconData icon;
  final void Function() onTap;

  @override
  State<MePageButton> createState() => _MePageButtonState();
}

class _MePageButtonState extends State<MePageButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: UiMode.m1(context)?const EdgeInsets.fromLTRB(16, 8, 16, 8):const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: MouseRegion(
        onEnter: (event) => setState(() => hovering = true),
        onExit: (event) => setState(() => hovering = false),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerUp: (event) => setState(() => hovering = false),
          onPointerDown: (event) => setState(() => hovering = true),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            onTap: widget.onTap,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  color: hovering?Theme.of(context).colorScheme.inversePrimary.withAlpha(150):Theme.of(context).colorScheme.inversePrimary.withAlpha(40)
              ),
              duration: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(widget.subTitle, style: const TextStyle(fontSize: 15),),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipPath(
                        clipper: MePageIconClipper(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: hovering?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.surface,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(widget.icon, color: hovering?Theme.of(context).colorScheme.onPrimary:Theme.of(context).colorScheme.onSurface,),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MePageIconClipper extends CustomClipper<Path>{
  @override
  Path getClip(Size size) {
    final path = Path();
    final r = size.width * 0.3; // 控制弧线的大小

    // 起始点
    path.moveTo(r, 0);

    // 上边弧线
    path.arcToPoint(
      Offset(size.width - r, 0),
      radius: Radius.circular(r * 2),
      clockwise: false,
    );

    // 右上角圆弧
    path.arcToPoint(
      Offset(size.width, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 右边弧线
    path.arcToPoint(
      Offset(size.width, size.height - r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 右下角圆弧
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 下边弧线
    path.arcToPoint(
      Offset(r, size.height),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左下角圆弧
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 左边弧线
    path.arcToPoint(
      Offset(0, r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左上角圆弧
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }

}