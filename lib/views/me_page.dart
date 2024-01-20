import 'package:flutter/material.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/tools.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import '../base.dart';
import '../foundation/app.dart';
import '../foundation/ui_mode.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'main_page.dart';

class MePage extends StatelessWidget {
  const MePage({super.key});

  int calcAccounts(){
    int count = 0;
    if(appdata.picacgAccount != "") count++;
    if(appdata.ehAccount != "") count++;
    if(appdata.jmName != "") count++;
    if(appdata.htName != "") count++;
    if(NhentaiNetwork().logged) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    int accounts = calcAccounts();
    return CustomScrollView(
      key: const Key("1"),
      slivers: [
        if (!UiMode.m1(context))
          const SliverPadding(padding: EdgeInsets.all(30)),
        SliverToBoxAdapter(
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
              Wrap(
                children: [
                  MePageButton(
                    title: "账号管理".tl,
                    subTitle: "已登录 @a 个账号".tlParams({"a": accounts.toString()}),
                    icon: Icons.switch_account,
                    onTap: () => showAdaptiveWidget(App.globalContext!,
                        AccountsPage(popUp: MediaQuery.of(App.globalContext!).size.width>600,)),
                  ),
                  MePageButton(
                    title: "已下载".tl,
                    subTitle: "共 @a 部漫画".tlParams({"a": DownloadManager().downloaded.length.toString()}),
                    icon: Icons.download_for_offline,
                    onTap: () => MainPage.to(() => const DownloadPage()),
                  ),
                  MePageButton(
                    title: "历史记录".tl,
                    subTitle: "@a 条历史记录".tlParams({"a": appdata.history.length.toString()}),
                    icon: Icons.history,
                    onTap: () => MainPage.to(() => const HistoryPage()),
                  ),
                  MePageButton(
                    title: "工具".tl,
                    subTitle: "使用工具发现更多漫画".tl,
                    icon: Icons.build_circle,
                    onTap: openTool,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 12)),
      ],
    );
  }
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
    double width;
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = 10.0;
    if (screenWidth > changePoint2) {
      screenWidth -= 400;
      width = screenWidth / 2 - padding * 2;
    } else if (screenWidth > changePoint) {
      screenWidth -= 80;
      width = screenWidth / 2 - padding * 2;
    } else {
      width = screenWidth - padding * 2;
    }

    if (width > 400) {
      width = 400;
    }
    var height = width / 3;
    if(height < 100){
      height = 100;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
      child: MouseRegion(
        onEnter: (event) => setState(() => hovering = true),
        onExit: (event) => setState(() => hovering = false),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerUp: (event) => setState(() => hovering = false),
          onPointerDown: (event) => setState(() => hovering = true),
          onPointerCancel: (event) => setState(() => hovering = false),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            onTap: widget.onTap,
            child: SizedBox(
              width: width,
              height: height,
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
                            duration: const Duration(milliseconds: 200),
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