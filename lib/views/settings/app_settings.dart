import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/network/download.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/views/category_page.dart';
import 'package:pica_comic/views/explore_page.dart';
import 'package:pica_comic/views/welcome_page.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../network/update.dart';
import '../../tools/io_tools.dart';
import '../../network/proxy.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import '../leaderboard_page.dart';
import '../widgets/value_listenable_widget.dart';
import 'package:pica_comic/tools/translations.dart';

void findUpdate(BuildContext context) {
  showMessage(context, "正在检查更新".tl, time: 2);
  checkUpdate().then((b) {
    if (b == null) {
      showMessage(context, "网络错误".tl);
    } else if (b) {
      getUpdatesInfo().then((s) {
        if (s != null) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("有可用更新".tl),
                  content: Text(s),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Get.back();
                          appdata.settings[2] = "0";
                          appdata.writeData();
                        },
                        child: Text("关闭更新检查".tl)),
                    TextButton(onPressed: () => Get.back(), child: Text("取消".tl)),
                    TextButton(
                        onPressed: () {
                          getDownloadUrl().then((s) {
                            launchUrlString(s, mode: LaunchMode.externalApplication);
                          });
                        },
                        child: Text("下载".tl))
                  ],
                );
              });
        } else {
          showMessage(context, "网络错误".tl);
        }
      });
    } else {
      showMessage(context, "已是最新版本".tl);
    }
  });
}

void giveComments(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("提出建议".tl),
          children: [
            ListTile(
              leading: const Image(
                image: AssetImage("images/github.png"),
                width: 25,
              ),
              title: const Text("Github"),
              onTap: () {
                launchUrlString("https://github.com/wgh136/PicaComic/issues",
                    mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: Icon(Icons.mail, color: Theme.of(context).colorScheme.secondary),
              title: const Text("Email"),
              onTap: () {
                launchUrlString("mailto:nyne19710@proton.me", mode: LaunchMode.externalApplication);
              },
            ),
          ],
        );
      });
}

class ProxyController extends GetxController {
  bool value = appdata.settings[8] == "0";
  late var controller = TextEditingController(text: value ? "" : appdata.settings[8]);
}

void setProxy(BuildContext context) {
  showDialog(
      context: context,
      builder: (dialogContext) {
        return GetBuilder(
            init: ProxyController(),
            builder: (controller) {
              return SimpleDialog(
                title: Text("设置代理".tl),
                children: [
                  const SizedBox(
                    width: 400,
                  ),
                  ListTile(
                    title: Text("使用系统代理".tl),
                    trailing: Switch(
                      value: controller.value,
                      onChanged: (value) {
                        if (value == true) {
                          controller.controller.text = "";
                        }
                        controller.value = !controller.value;
                        controller.update();
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                    child: TextField(
                      readOnly: controller.value,
                      controller: controller.controller,
                      decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText:
                              controller.value ? "使用系统代理时无法手动设置".tl : "设置代理, 例如127.0.0.1:7890".tl),
                    ),
                  ),
                  if (!controller.value)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 15, 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                          ),
                          Text("  ${"留空表示禁用网络代理".tl}")
                        ],
                      ),
                    ),
                  Center(
                    child: FilledButton(
                        onPressed: () {
                          if (controller.value) {
                            appdata.settings[8] = "0";
                            appdata.writeData();
                            setNetworkProxy();
                            Get.back();
                          } else {
                            appdata.settings[8] = controller.controller.text;
                            appdata.writeData();
                            setNetworkProxy();
                            Get.back();
                          }
                        },
                        child: Text("确认".tl)),
                  )
                ],
              );
            });
      });
}

class CalculateCacheLogic extends GetxController {
  bool calculating = true;
  double size = 0;
  void change() {
    calculating = !calculating;
    update();
  }

  void get() async {
    size = await calculateCacheSize();
    change();
  }
}


void setComicSource(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("设置漫画源".tl),
          children: const [
            SizedBox(
              width: 400,
            ),
            ComicSourceSetting(),
          ],
        );
      });
}

class ComicSourceSetting extends StatefulWidget {
  const ComicSourceSetting({Key? key}) : super(key: key);

  @override
  State<ComicSourceSetting> createState() => _ComicSourceSettingState();
}

class _ComicSourceSettingState extends State<ComicSourceSetting> {
  @override
  void dispose() {
    appdata.updateSettings();
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        Get.find<CategoryPageLogic>().update();
        Get.find<ExplorePageLogic>().update();
        Get.find<LeaderboardPageLogic>().update();
      } catch (e) {
        //如果在test_network_page进行此操作将产生错误
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var titles = ["Picacg", "E-hentai", "禁漫天堂".tl, "Hitomi.la", "绅士漫画".tl, "nhentai"];
    return SizedBox(
      child: Column(
        children: [
          for (int i = 0; i < 6; i++)
            CheckboxListTile(
              value: appdata.settings[21][i] == "1",
              onChanged: (b) {
                setState(() {
                  if (b!) {
                    appdata.settings[21] = appdata.settings[21].replaceRange(i, i + 1, '1');
                  } else {
                    appdata.settings[21] = appdata.settings[21].replaceRange(i, i + 1, '0');
                  }
                });
              },
              title: Text(titles[i]),
            ),
        ],
      ),
    );
  }
}

void setDownloadFolder() async {
  if(DownloadManager().downloading.isNotEmpty){
    showMessage(Get.context!, "请在下载任务完成后进行操作".tl);
    return;
  }
  if (GetPlatform.isAndroid) {
    var directories = await getExternalStorageDirectories();
    var paths =
        List<String>.generate(directories?.length ?? 0, (index) => directories?[index].path ?? "");
    showDialog(
        context: Get.context!,
        builder: (context) => SetDownloadFolderDialog(
              paths: paths,
            ));
  } else {
    showDialog(context: Get.context!, builder: (context) => const SetDownloadFolderDialog());
  }
}

class SetDownloadFolderDialog extends StatefulWidget {
  const SetDownloadFolderDialog({this.paths, Key? key}) : super(key: key);
  final List<String>? paths;

  @override
  State<SetDownloadFolderDialog> createState() => _SetDownloadFolderDialogState();
}

class _SetDownloadFolderDialogState extends State<SetDownloadFolderDialog> {
  final controller = TextEditingController();
  String current = appdata.settings[22];
  bool transform = true;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("设置下载目录".tl),
      children: [
        if (GetPlatform.isWindows || GetPlatform.isLinux)
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: "路径".tl,
                        hintText: "为空表示使用App数据目录".tl),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CheckboxListTile(
                    value: transform,
                    onChanged: (b) => setState(() {
                      transform = b!;
                    }),
                    title: Text("转移数据".tl),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 18,),
                      const SizedBox(width: 4,),
                      Expanded(
                        child: SizedBox(
                          child: Text("如需还原之前的下载, 将路径填写为下载数据的位置, 并取消勾选转移数据".tl),
                        ),
                      )
                    ],
                  ),
                ),
                Center(
                  child: FilledButton(
                    onPressed: () async {
                      if (controller.text == appdata.settings[22]) return;
                      var directory = Directory(controller.text);
                      if (directory.existsSync() || controller.text == "") {
                        var oldPath = appdata.settings[22];
                        appdata.settings[22] = controller.text;
                        if (transform) {
                          showMessage(Get.context, "正在复制文件".tl);
                          await Future.delayed(const Duration(milliseconds: 200));
                        }
                        var res =
                            await downloadManager.updatePath(controller.text, transform: transform);
                        if (res == "ok") {
                          Get.closeAllSnackbars();
                          Navigator.of(Get.context!).pop();
                          showMessage(Get.context, "更新成功".tl);
                          appdata.updateSettings();
                        } else {
                          appdata.settings[22] = oldPath;
                          showMessage(Get.context, res);
                        }
                      } else {
                        showMessage(context, "目录不存在".tl);
                      }
                    },
                    child: Text("提交".tl),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text("${"现在的路径为".tl}: ${DownloadManager().path}"),
                )
              ],
            ),
          )
        else
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                    title: Text("App内部储存目录".tl),
                    value: "",
                    groupValue: current,
                    onChanged: (value) => setState(() {
                          current = value!;
                        })),
                for (int i = 0; i < widget.paths!.length; i++)
                  RadioListTile<String>(
                      title: Text(widget.paths![i]),
                      value: widget.paths![i],
                      groupValue: current,
                      onChanged: (value) => setState(() {
                            current = value!;
                          })),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CheckboxListTile(
                    value: transform,
                    onChanged: (b) => setState(() {
                      transform = b!;
                    }),
                    title: Text("转移数据".tl),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 18,),
                      const SizedBox(width: 2,),
                      Expanded(
                        child: SizedBox(
                          child: Text("如需还原之前的下载, 将路径填写为下载数据的位置, 并取消勾选转移数据".tl),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                  child: Center(
                    child: FilledButton(
                      child: const Text("确认"),
                      onPressed: () async {
                        if (appdata.settings[22] != current) {
                          var oldPath = appdata.settings[22];
                          appdata.settings[22] = current;
                          if (transform) {
                            showMessage(Get.context, "正在复制文件".tl);
                            await Future.delayed(const Duration(milliseconds: 200));
                          }
                          var res = await downloadManager.updatePath(current, transform: transform);
                          if (res == "ok") {
                            Get.back();
                            showMessage(Get.context, "更新成功".tl);
                            appdata.updateSettings();
                          } else {
                            appdata.settings[22] = oldPath;
                            showMessage(Get.context, res);
                          }
                        } else {
                          Get.back();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
      ],
    );
  }
}

void setExplorePages(BuildContext context) {
  showDialog(
      context: context,
      builder: (logic) => SimpleDialog(
            title: Text("显示的探索页面".tl),
            children: const [SetExplorePages()],
          ));
}

class SetExplorePages extends StatefulWidget {
  const SetExplorePages({Key? key}) : super(key: key);

  @override
  State<SetExplorePages> createState() => _SetExplorePagesState();
}

class _SetExplorePagesState extends State<SetExplorePages> {
  @override
  void dispose() {
    appdata.updateSettings();
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        Get.find<ExplorePageLogic>().update();
      } catch (e) {
        //如果在test_network_page进行此操作将产生错误
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var titles = [
      "Picacg".tl,
      "Picacg游戏".tl,
      "Eh主页".tl,
      "Eh热门".tl,
      "禁漫主页".tl,
      "禁漫最新".tl,
      "Hitomi".tl,
      "nhentai",
      "",
      "绅士漫画".tl
    ];
    var options = <Widget>[];
    for (int i = 0; i < 10; i++) {
      if(i == 8)  continue;
      options.add(CheckboxListTile(
        value: appdata.settings[24][i] == "1",
        onChanged: (b) {
          setState(() {
            if (b!) {
              appdata.settings[24] = appdata.settings[24].replaceRange(i, i + 1, '1');
            } else {
              appdata.settings[24] = appdata.settings[24].replaceRange(i, i + 1, '0');
            }
          });
        },
        title: Text(titles[i]),
      ));
    }
    return SizedBox(
      width: 400,
      child: Column(
        children: options,
      ),
    );
  }
}

void setCacheLimit(BuildContext context) async{
  int? number;
  int? size;
  await showDialog(context: context, builder: (context)=>SimpleDialog(
    title: const Text("阅读器缓存限制"),
    children: [
      SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text("缓存数量限制".tl),
              ),
              ValueListenableWidget<String>(
                initialValue: appdata.settings[34],
                builder: (value, update) => Row(
                  children: [
                    Expanded(child: Slider(
                      value: int.parse(value).toDouble(),
                      max: 2000,
                      min: 200,
                      divisions: 1799,
                      onChanged: (newValue){
                        number = newValue.toInt();
                        update(newValue.toInt().toString());
                      },
                    )),
                    SizedBox(
                      width: 50,
                      child: Center(
                        child: Text(value),
                      ),
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text("缓存大小限制"),
              ),
              ValueListenableWidget<String>(
                initialValue: appdata.settings[35],
                builder: (value, update) => Row(
                  children: [
                    Expanded(child: Slider(
                      value: int.parse(value).toDouble(),
                      max: 1024,
                      min: 128,
                      divisions: 897,
                      onChanged: (newValue){
                        size = newValue.toInt();
                        update(newValue.toInt().toString());
                      },
                    )),
                    SizedBox(
                      width: 50,
                      child: Text("$value MB"),
                    )
                  ],
                ),
              ),
              SizedBox(
                height: 20,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 16,),
                      Text("仅在退出阅读器时检查缓存是否超出限制".tl)
                    ],
                  ),
                ),
              )
            ],
          )
        ),
      )
    ],
  ));
  if(number != null){
    appdata.settings[34] = number!.toString();
    appdata.updateSettings();
  }
  if(size != null){
    appdata.settings[35] = size!.toString();
    appdata.updateSettings();
  }
}

void clearUserData(BuildContext context){
  showDialog(context: context, builder: (context)=>AlertDialog(
    title: Text("警告".tl),
    content: Text("此操作无法撤销, 是否继续".tl),
    actions: [
      TextButton(onPressed: ()  => Get.back(), child: Text("取消".tl)),
      TextButton(onPressed: () async{
        await clearAppdata();
        Get.offAll(() => const WelcomePage());
        Get.forceAppUpdate();
      }, child: Text("继续".tl)),
    ],
  ));
}

void exportDataSetting(BuildContext context){
  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text("导出用户数据".tl),
    content: Text("将导出设置, 账号, 历史记录, 下载内容, 本地收藏等数据".tl),
    actions: [
      TextButton(onPressed: ()=>Get.back(), child: Text("取消".tl)),
      TextButton(onPressed: (){
        Get.back();
        showDialog(barrierDismissible: false, context: context, builder: (context) => const SimpleDialog(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          ],
        ));
        runExportData(false).then((v){
          if(v){
            Get.back();
            showMessage(Get.context, "成功导出");
          }else{
            Get.back();
            showMessage(Get.context, "导出失败");
          }
        });
      }, child: Text("导出不含下载的数据".tr)),
      TextButton(onPressed: (){
        Get.back();
        showDialog(barrierDismissible: false, context: context, builder: (context) => const SimpleDialog(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          ],
        ));
        runExportData(true).then((v){
          if(v){
            Get.back();
            showMessage(Get.context, "成功导出");
          }else{
            Get.back();
            showMessage(Get.context, "导出失败");
          }
        });
      }, child: Text("导出所有数据".tr))
    ],
  ));
}

void importDataSetting(BuildContext context){
  showDialog(context: context, builder: (context) => AlertDialog(
    title: Text("导入用户数据".tl),
    content: Text("将导入设置, 账号, 历史记录, 下载内容, 本地收藏等数据, 现在的所有数据将会被覆盖".tl+
        "\n如果导入的数据中包含下载数据, 则当前的下载数据也将被覆盖".tl),
    actions: [
      TextButton(onPressed: ()=>Get.back(), child: Text("取消".tl)),
      TextButton(onPressed: (){
        Get.back();
        showDialog(barrierDismissible: false, context: context, builder: (context) => const SimpleDialog(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          ],
        ));
        importData().then((v){
          if(v){
            Get.back();
            showMessage(Get.context, "成功导入");
          }else{
            Get.back();
            showMessage(Get.context, "导入失败");
          }
        });
      }, child: Text("继续".tl))
    ],
  ));
}

void syncDataSettings(BuildContext context){
  var configs = ["", "", "", ""];
  if(appdata.settings[45] != ""){
    configs = appdata.settings[45].split(';');
  }
  String url = configs[0];
  String username = configs[1];
  String pwd = configs[2];
  String path = configs[3];
  int value = 0;
  showDialog(context: context, builder: (context) => SimpleDialog(
    title: const Text("Webdav"),
    children: [
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        width: 400,
        child: Column(
          children: [
            TextField(
              onChanged: (s) => url = s,
              controller: TextEditingController(text: url),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                label: Text("URL"),
                hintText: "https://example.com:4433/webdav"
            )),
            const SizedBox(height: 8,),
            TextField(
                onChanged: (s) => username = s,
                controller: TextEditingController(text: username),
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    label: Text("用户名".tl),
                )),
            const SizedBox(height: 8,),
            TextField(
                onChanged: (s) => pwd = s,
                controller: TextEditingController(text: pwd),
                obscureText: true,
                decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    label: Text("密码".tl),
                )),
            const SizedBox(height: 8,),
            TextField(
                onChanged: (s) => path = s,
                controller: TextEditingController(text: path),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  label: Text("储存路径".tl),
                  hintText: "请确保路径存在"
                )),
            const SizedBox(height: 8,),
            StatefulBuilder(builder: (context, stateSetter){
              return Row(
                children: [
                  const Text("立即执行:"),
                  Radio<int>(value: 0, groupValue: value,
                      onChanged: (i) => stateSetter(() => value = 0)),
                  const Text("上传数据"),
                  Radio<int>(value: 1, groupValue: value,
                      onChanged: (i) => stateSetter(() => value = 1)),
                  const Text("下载数据"),
                ],
              );
            }),
            const SizedBox(height: 8,),
            Center(
              child: FilledButton(
                child: Text("提交".tl),
                onPressed: () async{
                  if(url.isEmpty){
                    appdata.settings[45] = "$url;$username;$pwd;$path";
                    appdata.updateSettings();
                    Get.back();
                    return;
                  }
                  showLoadingDialog(context, () {}, false, false, value == 0 ? "Uploading" : "Downloading");
                  var res = value == 0 ? await Webdav.uploadData("$url;$username;$pwd;$path")
                      : await Webdav.downloadData("$url;$username;$pwd;$path");
                  if(!res){
                    Get.back();
                    showMessage(Get.context, "Failed to sync data");
                  }else {
                    appdata.settings[45] = "$url;$username;$pwd;$path";
                    appdata.updateSettings();
                    Get.back();
                    Get.back();
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                  ),
                  Text("  ${"将URL留空以禁用同步".tl}")
                ],
              ),
            ),
          ],
        ),
      )
    ],
  ));
}