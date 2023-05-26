import 'dart:io';
import 'package:pica_comic/network/new_download.dart';
import 'package:pica_comic/views/category_page.dart';
import 'package:pica_comic/views/explore_page.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../network/update.dart';
import '../../tools/io_tools.dart';
import '../../tools/proxy.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';

void findUpdate(BuildContext context) {
  showMessage(context, "正在检查更新".tr, time: 2);
  checkUpdate().then((b) {
    if (b == null) {
      showMessage(context, "网络错误".tr);
    } else if (b) {
      getUpdatesInfo().then((s) {
        if (s != null) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("有可用更新".tr),
                  content: Text(s),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Get.back();
                          appdata.settings[2] = "0";
                          appdata.writeData();
                        },
                        child: Text("关闭更新检查".tr)),
                    TextButton(onPressed: () => Get.back(), child: Text("取消".tr)),
                    TextButton(
                        onPressed: () {
                          getDownloadUrl().then((s) {
                            launchUrlString(s, mode: LaunchMode.externalApplication);
                          });
                        },
                        child: Text("下载".tr))
                  ],
                );
              });
        } else {
          showMessage(context, "网络错误".tr);
        }
      });
    } else {
      showMessage(context, "已是最新版本".tr);
    }
  });
}

void giveComments(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text("提出建议".tr),
          children: [
            ListTile(
              leading: const Image(
                image: AssetImage("images/github.png"),
                width: 25,
              ),
              title: const Text("在Github上提出Issue"),
              onTap: () {
                launchUrlString("https://github.com/wgh136/PicaComic/issues",
                    mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: Icon(Icons.mail, color: Theme.of(context).colorScheme.secondary),
              title: const Text("发送邮件"),
              onTap: () {
                launchUrlString("mailto:nyne19710@proton.me",
                    mode: LaunchMode.externalApplication);
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
                title: Text("设置代理".tr),
                children: [
                  const SizedBox(
                    width: 400,
                  ),
                  ListTile(
                    title: Text("使用系统代理".tr),
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
                          hintText: controller.value ? "使用系统代理时无法手动设置".tr : "设置代理, 例如127.0.0.1:7890".tr),
                    ),
                  ),
                  if(!controller.value)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(18, 10, 15, 10),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20,),
                          Text("  留空表示禁用网络代理")
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
                        child: Text("确认".tr)),
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

void setReadingMethod(BuildContext context) {
  showDialog(
      context: context,
      builder: (BuildContext context) => SimpleDialog(title: Text("选择阅读模式".tr), children: [
        GetBuilder<ReadingMethodLogic>(
          init: ReadingMethodLogic(),
          builder: (radioLogic) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 400,
                ),
                ListTile(
                  trailing: Radio<int>(
                    value: 1,
                    groupValue: radioLogic.value,
                    onChanged: (i) {
                      radioLogic.setValue(i!);
                    },
                  ),
                  title: Text("从左至右".tr),
                  onTap: () {
                    radioLogic.setValue(1);
                  },
                ),
                ListTile(
                  trailing: Radio<int>(
                    value: 2,
                    groupValue: radioLogic.value,
                    onChanged: (i) {
                      radioLogic.setValue(i!);
                    },
                  ),
                  title: Text("从右至左".tr),
                  onTap: () {
                    radioLogic.setValue(2);
                  },
                ),
                ListTile(
                  trailing: Radio<int>(
                    value: 3,
                    groupValue: radioLogic.value,
                    onChanged: (i) {
                      radioLogic.setValue(i!);
                    },
                  ),
                  title: Text("从上至下".tr),
                  onTap: () {
                    radioLogic.setValue(3);
                  },
                ),
                ListTile(
                  trailing: Radio<int>(
                    value: 4,
                    groupValue: radioLogic.value,
                    onChanged: (i) {
                      radioLogic.setValue(i!);
                    },
                  ),
                  title: Text("从上至下(连续)".tr),
                  onTap: () {
                    radioLogic.setValue(4);
                  },
                ),
              ],
            );
          },
        ),
      ]));
}

class ReadingMethodLogic extends GetxController {
  var value = int.parse(appdata.settings[9]);

  void setValue(int i) {
    value = i;
    appdata.settings[9] = value.toString();
    update();
  }
}

void setComicSource(BuildContext context){
  showDialog(context: context, builder: (context){
    return SimpleDialog(
      title: Text("设置漫画源".tr),
      children: const [
        SizedBox(width: 400,),
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
    Future.delayed(const Duration(milliseconds: 500),(){
      try {
        Get.find<CategoryPageLogic>().update();
        Get.find<ExplorePageLogic>().update();
      }
      catch(e){
        //如果在test_network_page进行此操作将产生错误
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var titles = ["Picacg(不能禁用)".tr, "E-hentai", "禁漫天堂".tr, "Hitomi.la"];
    return SizedBox(
      child: Column(
        children: [
          for(int i = 0; i < 4; i++)
          CheckboxListTile(
            value: appdata.settings[21][i]=="1",
            onChanged: (b){
              setState(() {
                if(b!){
                  appdata.settings[21] = appdata.settings[21].replaceRange(i, i+1, '1');
                }else{
                  appdata.settings[21] = appdata.settings[21].replaceRange(i, i+1, '0');
                }
              });
            },
            enabled: i!=0,
            title: Text(titles[i]),
          ),
        ],
      ),
    );
  }
}

void setDownloadFolder(BuildContext context){
  showDialog(context: context, builder: (context)=>const SetDownloadFolderDialog());
}

class SetDownloadFolderDialog extends StatefulWidget {
  const SetDownloadFolderDialog({Key? key}) : super(key: key);

  @override
  State<SetDownloadFolderDialog> createState() => _SetDownloadFolderDialogState();
}

class _SetDownloadFolderDialogState extends State<SetDownloadFolderDialog> {
  final controller = TextEditingController();
  bool transform = true;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("设置下载目录".tr),
      children: [
        SizedBox(
          width: 400,
          height: 220,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: "路径".tr,
                    hintText: "为空表示使用App数据目录".tr
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: CheckboxListTile(value: transform, onChanged: (b) => setState(() {
                  transform = b!;
                }),title: Text("转移数据".tr),),
              ),
              Center(
                child: FilledButton(
                  onPressed: () async{
                    if(controller.text == appdata.settings[22]) return;
                    var directory = Directory(controller.text);
                    if(directory.existsSync() || controller.text == ""){
                      var oldPath = appdata.settings[22];
                      appdata.settings[22] = controller.text;
                      if(transform) {
                        showMessage(Get.context, "正在复制文件".tr);
                        await Future.delayed(const Duration(milliseconds: 200));
                      }
                      var res = await downloadManager.updatePath(controller.text, transform: transform);
                      if(res == "ok"){
                        Get.back();
                        showMessage(Get.context, "更新成功".tr);
                        appdata.updateSettings();
                      }else{
                        appdata.settings[22] = oldPath;
                        showMessage(Get.context, res);
                      }
                    }else{
                      showMessage(context, "目录不存在".tr);
                    }
                  },
                  child: Text("提交".tr),
                ),
              ),
              const SizedBox(height: 8,),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text("${"现在的路径为".tr}: ${DownloadManager().path}"),
              )
            ],
          ),
        )
      ],
    );
  }
}
