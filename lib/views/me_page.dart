import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/tools/debug.dart';
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
                Wrap(
                  children: [
                    mePageItem(
                        context,
                        Image.asset(
                          "images/account.png",
                          width: 70,
                          height: 70,
                          filterQuality: FilterQuality.medium,
                        ),
                        () => showAdaptiveWidget(context, AccountsPage()),
                        "账号管理".tr,
                        "查看或修改账号信息".tr),
                    mePageItem(
                        context,
                        Image.asset(
                          "images/favorites.png",
                          width: 70,
                          height: 70,
                          filterQuality: FilterQuality.medium,
                        ),
                        () => Get.to(() => const AllFavoritesPage()),
                        "收藏夹".tr,
                        "查看已收藏的漫画".tr),
                    mePageItem(
                        context,
                        Image.asset(
                          "images/download.png",
                          width: 70,
                          height: 70,
                          filterQuality: FilterQuality.medium,
                        ),
                        () => Get.to(() => const DownloadPage()),
                        "已下载".tr,
                        "管理已下载的漫画".tr),
                    mePageItem(
                        context,
                        Image.asset(
                          "images/history.png",
                          width: 70,
                          height: 70,
                          filterQuality: FilterQuality.medium,
                        ),
                        () => Get.to(() => const HistoryPage()),
                        "历史记录".tr,
                        "查看历史记录".tr),
                    if (kDebugMode)
                      mePageItem(
                          context,
                          const Icon(
                            Icons.bug_report,
                            size: 60,
                          ), () async {
                        debug();
                      }, "Debug", ""),
                  ],
                )
              ],
            ),
          ),
        ),
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
