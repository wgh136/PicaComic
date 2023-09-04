import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/nhentai_network/login.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/views/eh_views/eh_login_page.dart';
import 'package:pica_comic/views/ht_views/ht_login_page.dart';
import 'package:pica_comic/views/jm_views/jm_login_page.dart';
import 'package:pica_comic/views/pic_views/login_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../network/jm_network/jm_main_network.dart';
import '../network/picacg_network/methods.dart';
import '../network/picacg_network/models.dart';
import 'package:pica_comic/tools/translations.dart';

class AccountsPageLogic extends GetxController {}

class SloganLogic extends GetxController {
  bool isUploading = false;
  bool status = false;
  bool status2 = false;
  var controller = TextEditingController();
}

class ChangeAvatarLogic extends GetxController {
  bool isUploading = false;
  String url = "";
  bool success = true;
}

class PasswordLogic extends GetxController {
  bool isLoading = false;
  var c1 = TextEditingController();
  var c2 = TextEditingController();
  var c3 = TextEditingController();
  int status = -1;
  var errors = ["网络错误".tl, "旧密码错误".tl, "两次输入的密码不一致".tl, "密码至少8位".tl];
}

class AccountsPage extends StatelessWidget {
  AccountsPage({required this.popUp, super.key}) {
    Get.put(AccountsPageLogic());
  }

  final bool popUp;

  @override
  Widget build(BuildContext context) {
    var body = GetBuilder<AccountsPageLogic>(
      builder: (logic) {
        return CustomScrollView(
          slivers: [
            SliverList(
                delegate: SliverChildListDelegate([
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Picacg",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("头像".tl),
                      subtitle: Text("更换头像".tl),
                      trailing: Avatar(
                        size: 50,
                        avatarUrl: appdata.user.avatarUrl,
                      ),
                      onTap: () => changeAvatar(context, logic),
                    ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("账号".tl),
                      subtitle: Text(appdata.user.email),
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: appdata.user.email)),
                    ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("用户名".tl),
                      subtitle: Text(appdata.user.name),
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: appdata.user.name)),
                    ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("等级".tl),
                      subtitle: Text(
                          "Lv${appdata.user.level}    ${appdata.user.title}    Exp${appdata.user.exp.toString()}"),
                      onTap: () {},
                    ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("自我介绍".tl),
                      subtitle: Text(appdata.user.slogan ?? "无"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => changeSlogan(context, logic),
                    ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("修改密码".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => changePassword(context),
                    ),
                  if (appdata.token != "")
                    ListTile(
                      title: Text("退出登录".tl),
                      onTap: () => logoutPicacg(context, logic),
                      trailing: const Icon(Icons.logout),
                    ),
                  if (appdata.token == "")
                    ListTile(
                      title: Text("登录".tl),
                      onTap: () => Get.to(() => const LoginPage())
                          ?.then((value) => logic.update()),
                    ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Ehentai",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  if (appdata.ehAccount == "")
                    ListTile(
                      title: const Text("登录"),
                      onTap: () => Get.to(() => const EhLoginPage())
                          ?.then((v) => logic.update()),
                    ),
                  if (appdata.ehAccount != "")
                    ListTile(
                      title: Text("用户名".tl),
                      subtitle: Text(appdata.ehAccount),
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: appdata.ehAccount)),
                    ),
                  if (appdata.ehAccount != "")
                    ListTile(
                      title: const Text("ipb_member_id"),
                      subtitle: Text(appdata.ehId),
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: appdata.ehId)),
                    ),
                  if (appdata.ehAccount != "")
                    ListTile(
                      title: const Text("ipb_pass_hash"),
                      subtitle: Text(appdata.ehPassHash),
                      onTap: () => Clipboard.setData(
                          ClipboardData(text: appdata.ehPassHash)),
                    ),
                  if (appdata.ehAccount != "")
                    ListTile(
                      title: const Text("igneous"),
                      subtitle: Text(appdata.igneous),
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: appdata.igneous)),
                    ),
                  if (appdata.ehAccount != "")
                    ListTile(
                      title: Text("退出登录".tl),
                      onTap: () {
                        appdata.ehPassHash = "";
                        appdata.ehId = "";
                        appdata.ehAccount = "";
                        appdata.igneous = "";
                        appdata.writeData();
                        EhNetwork().cookieJar.deleteAll();
                        logic.update();
                      },
                      trailing: const Icon(Icons.logout),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "禁漫天堂".tl,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  if (appdata.jmEmail != "")
                    ListTile(
                      title: Text("用户名".tl),
                      subtitle: Text(appdata.jmName),
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: appdata.jmName)),
                    ),
                  if (appdata.jmEmail != "")
                    ListTile(
                      title: const Text("Email"),
                      subtitle: Text(appdata.jmEmail),
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: appdata.jmEmail)),
                    ),
                  if (appdata.jmEmail == "")
                    ListTile(
                      title: Text("登录".tl),
                      onTap: () => Get.to(() => const JmLoginPage())
                          ?.then((v) => logic.update()),
                    ),
                  if (appdata.jmEmail != "")
                    ListTile(
                      title: Text("重新登录".tl),
                      subtitle: Text("如果登录失效点击此处".tl),
                      onTap: () async {
                        showMessage(Get.context, "正在重新登录".tl, time: 8);
                        var res = await jmNetwork.loginFromAppdata();
                        if (res.error) {
                          showMessage(Get.context, res.errorMessage!);
                        } else {
                          showMessage(Get.context, "重新登录成功".tl);
                        }
                      },
                      trailing: const Icon(Icons.refresh),
                    ),
                  if (appdata.jmEmail != "")
                    ListTile(
                      title: Text("退出登录".tl),
                      onTap: () {
                        jmNetwork.logout();
                        logic.update();
                      },
                      trailing: const Icon(Icons.logout),
                    ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "绅士漫画".tl,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  if (appdata.htName != "")
                    ListTile(
                      title: Text("用户名".tl),
                      subtitle: Text(appdata.htName),
                      onTap: () =>
                          Clipboard.setData(ClipboardData(text: appdata.htName)),
                    ),
                  if (appdata.htName != "")
                    ListTile(
                      title: Text("退出登录".tl),
                      onTap: () {
                        appdata.htName = "";
                        appdata.htPwd = "";
                        HtmangaNetwork().cookieJar.deleteAll();
                        appdata.writeData();
                        logic.update();
                      },
                      trailing: const Icon(Icons.logout),
                    ),
                  if (appdata.htName != "")
                    ListTile(
                      title: Text("重新登录".tl),
                      subtitle: Text("如果登录失效点击此处".tl),
                      onTap: () async {
                        showMessage(Get.context, "正在重新登录".tl, time: 8);
                        var res = await HtmangaNetwork().loginFromAppdata();
                        if (res.error) {
                          showMessage(Get.context, res.errorMessage!);
                        } else {
                          showMessage(Get.context, "重新登录成功".tl);
                        }
                      },
                      trailing: const Icon(Icons.refresh),
                    ),
                  if (appdata.htName == "")
                    ListTile(
                      title: Text("登录".tl),
                      onTap: () => Get.to(() => const HtLoginPage())
                          ?.then((v) => logic.update()),
                    ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "Nhentai",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  ListTile(
                    title: Text("账号".tl),
                    subtitle: Text(NhentaiNetwork().logged ? "已登录".tl : "未登录".tl),
                  ),
                  if(!NhentaiNetwork().logged)
                    ListTile(
                      title: Text("登录".tl),
                      onTap: ()=>login(() => logic.update()),
                    ),
                  if(NhentaiNetwork().logged)
                    ListTile(
                      title: Text("退出登录".tl),
                      onTap: (){
                        NhentaiNetwork().logged = false;
                        NhentaiNetwork().logout();
                        logic.update();
                      },
                      trailing: const Icon(Icons.logout),
                    ),
                ])),
            const SliverPadding(padding: EdgeInsets.only(bottom: 50))
          ],
        );
      },
    );

    if(popUp){
      return PopUpWidgetScaffold(title: "账号管理".tl, body: body);
    }else{
      return Scaffold(
        appBar: AppBar(title: Text("账号管理".tl),),
        body: body,
      );
    }
  }

  ///更改哔咔账号简介
  void changeSlogan(BuildContext context, AccountsPageLogic accountsPageLogic) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return GetBuilder<SloganLogic>(
            init: SloganLogic(),
            builder: (logic) {
              return SimpleDialog(
                title: Text("更改自我介绍".tl),
                children: [
                  SizedBox(
                    width: 400,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                          child: TextField(
                            maxLines: 5,
                            controller: logic.controller,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        if (!logic.isUploading)
                          FilledButton(
                              onPressed: () {
                                if (logic.controller.text == "") {
                                  logic.status2 = true;
                                  logic.update();
                                  return;
                                }
                                logic.isUploading = true;
                                logic.status2 = false;
                                logic.update();
                                network
                                    .changeSlogan(logic.controller.text)
                                    .then((t) {
                                  if (t) {
                                    appdata.user.slogan = logic.controller.text;
                                    accountsPageLogic.update();
                                    Get.back();
                                  } else {
                                    logic.isUploading = false;
                                    logic.status = true;
                                    logic.update();
                                  }
                                });
                              },
                              child: Text("提交".tl)),
                        if (logic.isUploading)
                          const CircularProgressIndicator(),
                        if (!logic.isUploading && logic.status)
                          SizedBox(
                              width: 100,
                              height: 30,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const Spacer(),
                                  Text(
                                    "网络错误".tl,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  )
                                ],
                              )),
                        if (!logic.isUploading && logic.status2)
                          SizedBox(
                              width: 100,
                              height: 30,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const Spacer(),
                                  Text(
                                    "不能为空".tl,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                  )
                                ],
                              )),
                      ],
                    ),
                  )
                ],
              );
            },
          );
        });
  }

  ///更改哔咔头像
  void changeAvatar(BuildContext context, AccountsPageLogic accountsPageLogic) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return GetBuilder<ChangeAvatarLogic>(
              init: ChangeAvatarLogic(),
              builder: (logic) {
                return SimpleDialog(
                  title: Text("更换头像".tl),
                  children: [
                    SizedBox(
                      width: 300,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          GestureDetector(
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(150)),
                              clipBehavior: Clip.antiAlias,
                              width: 150,
                              height: 150,
                              child: logic.url != ""
                                  ? Image.file(
                                      File(logic.url),
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    child: Center(
                                      child: Text("选择图像".tl, style: const TextStyle(fontSize: 22),),
                                    ),
                              ),
                            ),
                            onTap: () async {
                              if (GetPlatform.isWindows) {
                                const XTypeGroup typeGroup = XTypeGroup(
                                  label: 'images',
                                  extensions: <String>['jpg', 'png'],
                                );
                                final XFile? file = await openFile(
                                    acceptedTypeGroups: <XTypeGroup>[
                                      typeGroup
                                    ]);
                                if (file != null) {
                                  logic.url = file.path;
                                  logic.update();
                                }
                              } else {
                                final ImagePicker picker = ImagePicker();
                                final XFile? file = await picker.pickImage(
                                    source: ImageSource.gallery);
                                if (file != null) {
                                  logic.url = file.path;
                                  logic.update();
                                }
                              }
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          if (!logic.isUploading)
                            FilledButton(
                                onPressed: () async {
                                  if (logic.url == "") {
                                    showMessage(context, "请先选择图像".tl);
                                  } else {
                                    logic.isUploading = true;
                                    logic.update();
                                    File file = File(logic.url);
                                    var bytes = await file.readAsBytes();
                                    String base64Image =
                                        "data:image/jpeg;base64,${base64Encode(bytes)}";
                                    network.uploadAvatar(base64Image).then((b) {
                                      if (b) {
                                        network.getProfile().then((t) {
                                          if (!t.error) {
                                            appdata.user = t.data;
                                            accountsPageLogic.update();
                                            Get.back();
                                            showMessage(context, "上传成功".tl);
                                          } else {
                                            logic.success = false;
                                            logic.isUploading = false;
                                            logic.update();
                                          }
                                        });
                                      } else {
                                        logic.success = false;
                                        logic.isUploading = false;
                                        logic.update();
                                      }
                                    });
                                  }
                                },
                                child: Text("上传".tl)),
                          if (logic.isUploading)
                            const CircularProgressIndicator(
                              strokeWidth: 4,
                            ),
                          if (!logic.isUploading && !logic.success)
                            SizedBox(
                                width: 60,
                                height: 50,
                                child: Row(
                                  children: [
                                    const Icon(Icons.error),
                                    const Spacer(),
                                    Text("失败".tl)
                                  ],
                                ))
                        ],
                      ),
                    )
                  ],
                );
              });
        });
  }

  ///更改哔咔密码
  void changePassword(BuildContext context) {
    showDialog(
        context: context,
        builder: (dialogContext) {
          return GetBuilder<PasswordLogic>(
            init: PasswordLogic(),
            builder: (logic) {
              return SimpleDialog(
                title: Text("修改密码".tl),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(5),
                          ),
                          TextField(
                            decoration: InputDecoration(
                                labelText: "输入旧密码".tl,
                                border: const OutlineInputBorder()),
                            obscureText: true,
                            controller: logic.c1,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(5),
                          ),
                          TextField(
                            decoration: InputDecoration(
                                labelText: "输入新密码".tl,
                                border: const OutlineInputBorder()),
                            obscureText: true,
                            controller: logic.c2,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(5),
                          ),
                          TextField(
                            decoration: InputDecoration(
                                labelText: "再输一次新密码".tl,
                                border: const OutlineInputBorder()),
                            obscureText: true,
                            controller: logic.c3,
                          ),
                          const Padding(
                            padding: EdgeInsets.all(5),
                          ),
                          if (!logic.isLoading)
                            FilledButton(
                              child: Text("提交".tl),
                              onPressed: () {
                                if (logic.c2.text != logic.c3.text) {
                                  logic.status = 2;
                                  logic.update();
                                } else if (logic.c2.text.length < 8) {
                                  logic.status = 3;
                                  logic.update();
                                } else {
                                  logic.isLoading = !logic.isLoading;
                                  logic.update();
                                  network
                                      .changePassword(
                                          logic.c1.text, logic.c2.text)
                                      .then((b) {
                                    if (b.success) {
                                      if (b.data) {
                                        logic.isLoading = !logic.isLoading;
                                        appdata.picacgPassword = logic.c2.text;
                                        appdata.writeData();
                                        Get.back();
                                        showMessage(context, "密码修改成功".tl);
                                      } else {
                                        logic.status = 1;
                                        logic.isLoading = !logic.isLoading;
                                        logic.update();
                                      }
                                    } else {
                                      logic.status = 0;
                                      logic.isLoading = !logic.isLoading;
                                      logic.update();
                                    }
                                  });
                                }
                              },
                            ),
                          if (logic.isLoading)
                            const CircularProgressIndicator(),
                          if (!logic.isLoading && logic.status != -1)
                            const SizedBox(
                              height: 10,
                            ),
                          if (!logic.isLoading && logic.status != -1)
                            SizedBox(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(logic.errors[logic.status])
                                ],
                              ),
                            )
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          );
        });
  }

  void logoutPicacg(BuildContext context, AccountsPageLogic logic) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("退出登录".tl),
            content: Text("要退出登录吗".tl),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                  onPressed: () => Get.back(),
                  child: Text(
                    "取消".tl,
                    textAlign: TextAlign.end,
                  )),
              TextButton(
                  onPressed: () {
                    appdata.token = "";
                    appdata.settings[13] = "0";
                    appdata.user = Profile("", defaultAvatarUrl, "", 0, 0, "",
                        "", null, null, null);
                    appdata.writeData();
                    logic.update();
                    Get.back();
                  },
                  child: Text("确定".tl, textAlign: TextAlign.end))
            ],
          );
        });
  }
}
