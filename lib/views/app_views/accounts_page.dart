import 'dart:convert';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/nhentai_network/login.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/views/eh_views/eh_login_page.dart';
import 'package:pica_comic/views/ht_views/ht_login_page.dart';
import 'package:pica_comic/views/jm_views/jm_login_page.dart';
import 'package:pica_comic/views/pic_views/login_page.dart';
import 'package:pica_comic/views/widgets/avatar.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../foundation/app.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/picacg_network/methods.dart';
import '../../network/picacg_network/models.dart';
import 'package:pica_comic/tools/translations.dart';

class AccountsPageLogic extends StateController {}

class AccountsPage extends StatelessWidget {
  AccountsPage({required this.popUp, super.key}) {
    StateController.put(AccountsPageLogic());
  }

  final bool popUp;

  AccountsPageLogic get logic => StateController.find<AccountsPageLogic>();

  @override
  Widget build(BuildContext context) {
    var body = StateBuilder<AccountsPageLogic>(
      builder: (logic) {
        return CustomScrollView(
          slivers: [
            SliverList(
                delegate: SliverChildListDelegate([
                  ...buildPicacg(context),
                  const Divider(),
                  ...buildEh(context),
                  const Divider(),
                  ...buildJm(context),
                  const Divider(),
                  ...buildHt(context),
                  const Divider(),
                  ...buildNh(context),
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
    String text = appdata.user.slogan ?? "";
    bool loading = false;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, updater) {
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
                            controller: TextEditingController(text: text),
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                            onChanged: (s) {
                              text = s;
                            },
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        if (!loading)
                          FilledButton(
                              onPressed: () {
                                updater(() {
                                  loading = true;
                                });
                                network
                                    .changeSlogan(text)
                                    .then((value) {
                                  if (value) {
                                    appdata.user.slogan = text;
                                    accountsPageLogic.update();
                                    App.back(context);
                                    showMessage(context, "修改成功".tl);
                                  } else {
                                    showMessage(context, "Network error");
                                  }
                                  updater(() {
                                    loading = false;
                                  });
                                });
                              },
                              child: Text("提交".tl)),
                        if (loading)
                          const CircularProgressIndicator(),
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
    String filePath = "";
    bool loading = false;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
              builder: (context, updater) {
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
                              child: filePath != ""
                                  ? Image.file(
                                      File(filePath),
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
                              if (App.isWindows) {
                                const XTypeGroup typeGroup = XTypeGroup(
                                  label: 'images',
                                  extensions: <String>['jpg', 'png'],
                                );
                                final XFile? file = await openFile(
                                    acceptedTypeGroups: <XTypeGroup>[
                                      typeGroup
                                    ]);
                                if (file != null) {
                                  filePath = file.path;
                                  updater(() {});
                                }
                              } else {
                                final ImagePicker picker = ImagePicker();
                                final XFile? file = await picker.pickImage(
                                    source: ImageSource.gallery);
                                if (file != null) {
                                  filePath = file.path;
                                  logic.update();
                                }
                              }
                            },
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          if (!loading)
                            FilledButton(
                                onPressed: () async {
                                  if (filePath == "") {
                                    showMessage(context, "请先选择图像".tl);
                                  } else {
                                    loading = true;
                                    updater(() {});
                                    var file = File(filePath);
                                    var bytes = await file.readAsBytes();
                                    String base64Image =
                                        "data:image/jpeg;base64,${base64Encode(bytes)}";
                                    network.uploadAvatar(base64Image).then((b) {
                                      if (b) {
                                        network.getProfile().then((t) {
                                          if (!t.error) {
                                            appdata.user = t.data;
                                            accountsPageLogic.update();
                                            App.back(context);
                                            showMessage(context, "上传成功".tl);
                                          } else {
                                            loading = false;
                                            updater(() {});
                                            showMessage(context, "Network error");
                                          }
                                        });
                                      } else {
                                        loading = false;
                                        updater(() {});
                                        showMessage(context, "Network error");
                                      }
                                    });
                                  }
                                },
                                child: Text("上传".tl)),
                          if (loading)
                            const CircularProgressIndicator(),
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
    String p1 = "";
    String p2 = "";
    String p3 = "";
    bool loading = false;

    showDialog(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (context, setState){
            return SimpleDialog(
              title: Text("修改密码".tl),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                        onChanged: (s) {
                          p1 = s;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.all(5),
                      ),
                      TextField(
                        decoration: InputDecoration(
                            labelText: "输入新密码".tl,
                            border: const OutlineInputBorder()),
                        obscureText: true,
                        onChanged: (s) {
                          p2 = s;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.all(5),
                      ),
                      TextField(
                        decoration: InputDecoration(
                            labelText: "再输一次新密码".tl,
                            border: const OutlineInputBorder()),
                        obscureText: true,
                        onChanged: (s) {
                          p3 = s;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.all(5),
                      ),
                      if (!loading)
                        FilledButton(
                          child: Text("提交".tl),
                          onPressed: () {
                            if (p1 == "" || p2 == "" || p3 == "") {
                              showMessage(context, "不能为空".tl);
                              return;
                            }
                            if (p2 != p3) {
                              showMessage(context, "两次输入的密码不一致".tl);
                              return;
                            }
                            if (p2.length < 8) {
                              showMessage(context, "密码至少8位".tl);
                              return;
                            }
                            setState(() {
                              loading = true;
                            });
                            network
                                .changePassword(p1, p2)
                                .then((value) {
                              setState(() {
                                loading = false;
                              });
                              if (!value.error) {
                                showMessage(context, "修改成功".tl);
                                App.back(context);
                              } else {
                                showMessage(context, value.errorMessage ?? "Unknown error");
                              }
                            });
                          },
                        ),
                      if (loading)
                        const CircularProgressIndicator(),
                    ],
                  ),
                )
              ],
            );
          });
        });
  }

  void logoutPicacg(BuildContext context, AccountsPageLogic logic) {
    showConfirmDialog(context, "退出登录".tl, "要退出登录吗".tl, () {
      appdata.token = "";
      appdata.settings[13] = "0";
      appdata.user = Profile("", defaultAvatarUrl, "", 0, 0, "",
          "", null, null, null);
      appdata.writeData();
      logic.update();
      App.globalBack();
    });
  }

  List<Widget> buildPicacg(BuildContext context) {
    return [
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
          onTap: () => setClipboard(appdata.user.email),
        ),
      if (appdata.token != "")
        ListTile(
          title: Text("用户名".tl),
          subtitle: Text(appdata.user.name),
          onTap: () => setClipboard(appdata.user.name),
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
          onTap: () => App.to(context, () => const LoginPage())
              .then((value) {
            logic.update();
            Webdav.uploadData();
          }),
        )
    ];
  }

  Iterable<Widget> buildEh(BuildContext context) sync*{
    yield const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        "ehentai",
        style: TextStyle(fontSize: 20),
      ),
    );

    if (appdata.ehAccount == "") {
      yield ListTile(
        title: Text("登录".tl),
        onTap: () => App.to(context, () => const EhLoginPage())
            .then((v) {
          logic.update();
          Webdav.uploadData();
        }),
      );
    }

    if (appdata.ehAccount != "") {
      yield ListTile(
        title: Text("用户名".tl),
        subtitle: Text(appdata.ehAccount),
        onTap: () => setClipboard(appdata.ehAccount),
      );
    }

    if (appdata.ehAccount != ""){
      yield ExpansionTile(title: const Text("cookies"), shape: const RoundedRectangleBorder(), children: [
        ListTile(
          title: const Text("ipb_member_id"),
          subtitle: Text(appdata.ehId),
          onTap: () => setClipboard(appdata.ehId),
        ),
        ListTile(
          title: const Text("ipb_pass_hash"),
          subtitle: Text(appdata.ehPassHash),
          onTap: () => setClipboard(appdata.ehPassHash),
        ),
        ListTile(
          title: const Text("igneous"),
          subtitle: Text(appdata.igneous),
          onTap: () => setClipboard(appdata.igneous),
        ),
      ]);
    }

    if(appdata.ehAccount != ""){
      yield ListTile(
        title: Text("图片配额".tl),
        onTap: () => ehImageLimit(context),
        trailing: const Icon(Icons.arrow_right),
      );
    }

    if (appdata.ehAccount != ""){
      yield ListTile(
        title: Text("退出登录".tl),
        onTap: () {
          appdata.ehPassHash = "";
          appdata.ehId = "";
          appdata.ehAccount = "";
          appdata.igneous = "";
          appdata.writeData();
          logic.update();
        },
        trailing: const Icon(Icons.logout),
      );
    }
  }

  List<Widget> buildJm(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          "禁漫天堂".tl,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      if (appdata.jmName != "")
        ListTile(
          title: Text("用户名".tl),
          subtitle: Text(appdata.jmName),
          onTap: () => setClipboard(appdata.jmName),
        ),
      if (appdata.jmName == "")
        ListTile(
          title: Text("登录".tl),
          onTap: () => App.to(context, () => const JmLoginPage())
              .then((v) {
            logic.update();
            Webdav.uploadData();
          }),
        ),
      if (appdata.jmName != "")
        ListTile(
          title: Text("重新登录".tl),
          subtitle: Text("如果登录失效点击此处".tl),
          onTap: () async {
            showMessage(App.globalContext, "正在重新登录".tl, time: 8);
            var res = await jmNetwork.loginFromAppdata();
            if (res.error) {
              showMessage(App.globalContext, res.errorMessage!);
            } else {
              showMessage(App.globalContext, "重新登录成功".tl);
            }
          },
          trailing: const Icon(Icons.refresh),
        ),
      if (appdata.jmName != "")
        ListTile(
          title: Text("退出登录".tl),
          onTap: () async{
            await jmNetwork.logout();
            logic.update();
          },
          trailing: const Icon(Icons.logout),
        ),
    ];
  }

  List<Widget> buildHt(BuildContext context) {
    return [
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
          onTap: () => setClipboard(appdata.htName),
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
            showMessage(App.globalContext, "正在重新登录".tl, time: 8);
            var res = await HtmangaNetwork().loginFromAppdata();
            if (res.error) {
              showMessage(App.globalContext, res.errorMessage!);
            } else {
              showMessage(App.globalContext, "重新登录成功".tl);
            }
          },
          trailing: const Icon(Icons.refresh),
        ),
      if (appdata.htName == "")
        ListTile(
          title: Text("登录".tl),
          onTap: () => App.to(context, () => const HtLoginPage())
              .then((v) {
            logic.update();
            Webdav.uploadData();
          }),
        ),
    ];
  }

  List<Widget> buildNh(BuildContext context){
    return [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          "nhentai",
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
          onTap: ()=>login(() {
            logic.update();
            Webdav.uploadData();
          }),
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
    ];
  }

  void setClipboard(String text){
    Clipboard.setData(ClipboardData(text: text));
    showToast(message: "已复制".tl, icon: Icons.check);
  }

  void ehImageLimit(BuildContext context) async{
    bool cancel = false;
    var controller = showLoadingDialog(context, () => cancel = true);
    var res = await EhNetwork().getImageLimit();
    if(cancel)  return;
    controller.close();
    if(res.error){
      showMessage(App.globalContext, res.errorMessage!);
    }else{
      showDialog(context: App.globalContext!, builder: (context){
        return AlertDialog(
          title: Text("图片配额".tl),
          content: Text("${"已用".tl}: ${res.data.current}/${res.data.max}\n"
              "${"重置花费".tl}: ${res.data.resetCost}\n"
              "${"可用货币".tl}: ${res.data.kGP}kGP, ${res.data.credits}credits"
          ),
          actions: [
            TextButton(onPressed: () => App.back(context), child: Text("返回".tl),),
            if(res.data.current > 0)
              TextButton(onPressed: (){
                App.back(context);
                showMessage(context, "加载中".tl, time: 8);
                EhNetwork().resetImageLimit().then((value){
                  hideMessage(context);
                  if(!value){
                    showMessage(context, "Error");
                  }else{
                    showMessage(context, "重置成功".tl);
                  }
                });
              }, child: Text("重置".tl)),
          ],
        );
      });
    }
  }
}