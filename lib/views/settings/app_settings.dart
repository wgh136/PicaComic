import 'package:url_launcher/url_launcher_string.dart';
import '../../network/update.dart';
import '../../tools/io_tools.dart';
import '../../tools/proxy.dart';
import '../widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';

void findUpdate(BuildContext context) {
  showMessage(context, "正在检查更新", time: 2);
  checkUpdate().then((b) {
    if (b == null) {
      showMessage(context, "网络错误");
    } else if (b) {
      getUpdatesInfo().then((s) {
        if (s != null) {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("有可用更新"),
                  content: Text(s),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Get.back();
                          appdata.settings[2] = "0";
                          appdata.writeData();
                        },
                        child: const Text("关闭更新检查")),
                    TextButton(onPressed: () => Get.back(), child: const Text("取消")),
                    TextButton(
                        onPressed: () {
                          getDownloadUrl().then((s) {
                            launchUrlString(s, mode: LaunchMode.externalApplication);
                          });
                        },
                        child: const Text("下载"))
                  ],
                );
              });
        } else {
          showMessage(context, "网络错误");
        }
      });
    } else {
      showMessage(context, "已是最新版本");
    }
  });
}

void giveComments(BuildContext context) {
  showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text("提出建议"),
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
                title: const Text("设置代理"),
                children: [
                  const SizedBox(
                    width: 400,
                  ),
                  ListTile(
                    title: const Text("使用系统代理"),
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
                          hintText: controller.value ? "使用系统代理时无法手动设置" : "设置代理, 例如127.0.0.1:8080"),
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
                        child: const Text("确认")),
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
      builder: (BuildContext context) => SimpleDialog(title: const Text("选择阅读模式"), children: [
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
                  title: const Text("从左至右"),
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
                  title: const Text("从右至左"),
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
                  title: const Text("从上至下"),
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
                  title: const Text("从上至下(连续)"),
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