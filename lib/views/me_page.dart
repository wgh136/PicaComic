import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/methods.dart';
import 'package:pica_comic/tools/debug.dart';
import 'package:pica_comic/tools/ui_mode.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/jm_views/jm_login_page.dart';
import 'package:pica_comic/views/pic_views/login_page.dart';
import 'package:pica_comic/views/pic_views/profile_page.dart';
import 'package:pica_comic/views/all_favorites_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/selectable_text.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';
import '../jm_network/jm_main_network.dart';
import 'eh_views/eh_login_page.dart';
import 'history.dart';

class InfoController extends GetxController {}

class MePage extends StatelessWidget {
  MePage({super.key});
  final infoController = Get.put(InfoController());

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        if (!UiMode.m1(context)) const SliverPadding(padding: EdgeInsets.all(30)),
        SliverToBoxAdapter(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.fromSize(
                  size: const Size(400, 220),
                  child: GetBuilder<InfoController>(
                    builder: (logic) {
                      return Card(
                          elevation: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: Avatar(
                                  size: 150,
                                  avatarUrl: appdata.user.avatarUrl == defaultAvatarUrl
                                      ? null
                                      : appdata.user.avatarUrl,
                                  frame: appdata.user.frameUrl,
                                ),
                              ),
                              Center(
                                child: Text(appdata.token==""?"未登录":appdata.user.name,
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                              ),
                              Center(
                                child: Text("Lv${appdata.user.level} ${appdata.user.title}",
                                    style:
                                        const TextStyle(fontWeight: FontWeight.w300, fontSize: 15)),
                              ),
                            ],
                          ));
                    },
                  ),
                ),
                Wrap(
                  children: [
                    mePageItem(
                        context, Icons.badge, () => manageAccounts(context), "账号管理", "查看或修改账号信息"),
                    mePageItem(context, Icons.bookmarks,
                        () => Get.to(() => const AllFavoritesPage()), "收藏夹", "查看已收藏的漫画"),
                    mePageItem(context, Icons.download_for_offline,
                        () => Get.to(() => const DownloadPage()), "已下载", "管理已下载的漫画"),
                    mePageItem(context, Icons.history, () => Get.to(() => const HistoryPage()),
                        "历史记录", "查看历史记录"),
                    if (kDebugMode)
                      mePageItem(context, Icons.bug_report, () async {
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

  void manageEhAccount(BuildContext context) {
    if (appdata.ehId == "") {
      Get.to(() => const EhLoginPage());
    } else {
      showDialog(
          context: context,
          builder: (dialogContext) => SimpleDialog(
                contentPadding: const EdgeInsets.fromLTRB(22, 12, 15, 10),
                title: const Text("Eh账户"),
                children: [
                  SelectableTextCN(text: "当前账户: ${appdata.ehAccount}"),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text("cookies:"),
                  SelectableTextCN(text: "  ipb_member_id: ${appdata.ehId}"),
                  SelectableTextCN(text: "  ipb_pass_hash: ${appdata.ehPassHash}"),
                  const SizedBox(
                    height: 12,
                  ),
                  Center(
                    child: FilledButton(
                      child: const Text("退出登录"),
                      onPressed: () {
                        appdata.ehPassHash = "";
                        appdata.ehId = "";
                        appdata.ehAccount = "";
                        appdata.writeData();
                        Get.back();
                      },
                    ),
                  )
                ],
              ));
    }
  }

  void manageJmAccount(BuildContext context) {
    if (appdata.jmName == "") {
      Get.to(() => const JmLoginPage());
    } else {
      showDialog(
          context: context,
          builder: (dialogContext) => SimpleDialog(
                contentPadding: const EdgeInsets.fromLTRB(30, 12, 23, 10),
                title: const Text("禁漫账户"),
                children: [
                  SelectableTextCN(text: "当前账户: ${appdata.jmName}"),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text("信息:"),
                  SelectableTextCN(text: "  邮箱: ${appdata.jmEmail}"),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton(
                        child: const Text("退出登录"),
                        onPressed: () {
                          jmNetwork.logout();
                          Get.back();
                        },
                      ),
                      const SizedBox(width: 16,),
                      FilledButton(
                        child: const Text("重新登录"),
                        onPressed: () async{
                          showMessage(Get.context, "正在重新登录", time: 8);
                          var res = await jmNetwork.loginFromAppdata();
                          if(res.error){
                            showMessage(Get.context, res.errorMessage!);
                          }else{
                            showMessage(Get.context, "重新登录成功");
                          }
                        },
                      ),
                    ],
                  )
                ],
              ));
    }
  }

  void manageAccounts(BuildContext context) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            title: const Text("账号管理"),
            children: [
              SizedBox(
                width: 400,
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("哔咔账号"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () {
                        Get.back();
                        Future.delayed(
                            const Duration(milliseconds: 200),
                            (){
                              if(appdata.token != ""){
                                showAdaptiveWidget(
                                    context,
                                    ProfilePage(
                                      infoController,
                                      popUp: MediaQuery.of(context).size.width > 600,
                                    ));
                              }else{
                                Get.to(() => const LoginPage());
                              }
                            });
                      },
                    ),
                    ListTile(
                      title: const Text("E-Hentai账号"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () {
                        Get.back();
                        Future.delayed(
                            const Duration(milliseconds: 200), () => manageEhAccount(context));
                      },
                    ),
                    ListTile(
                      title: const Text("禁漫账号"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () {
                        Get.back();
                        Future.delayed(
                            const Duration(milliseconds: 200), () => manageJmAccount(context));
                      },
                    ),
                  ],
                ),
              )
            ],
          );
        });
  }
}

Widget mePageItem(
    BuildContext context, IconData icon, void Function() page, String title, String subTitle) {
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
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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
            Expanded(
                flex: 1,
                child: Center(
                    child: Icon(
                  icon,
                  size: 55,
                  color: Theme.of(context).colorScheme.secondary,
                ))),
          ],
        ),
      ),
    ),
  );
}
