import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import '../../tools/keep_screen_on.dart';
import 'reading_logic.dart';

Widget buildSettingWindow(ComicReadingPageLogic comicReadingPageLogic, BuildContext context) {
  return Positioned(
    right: 10,
    top: 60 + MediaQuery.of(context).viewPadding.top,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 150),
      switchInCurve: Curves.fastOutSlowIn,
      child: comicReadingPageLogic.showSettings
          ? Container(
              width: MediaQuery.of(context).size.width > 620
                  ? 600
                  : MediaQuery.of(context).size.width - 20,
              //height: 300,
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(16))),
              child: const ReadingSettings(),
            )
          : const SizedBox(
              width: 0,
              height: 0,
            ),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    ),
  );
}

class ReadingSettings extends StatefulWidget {
  const ReadingSettings({Key? key}) : super(key: key);

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool pageChangeValue = appdata.settings[0] == "1";
  bool showThreeButton = appdata.settings[4] == "1";
  bool useVolumeKeyChangePage = appdata.settings[7] == "1";
  bool keepScreenOn = appdata.settings[14] == "1";

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 0, 5),
          child: Text(
            "阅读设置",
            style: TextStyle(fontSize: 18),
          ),
        ),
        ListTile(
          leading: Icon(Icons.switch_left, color: Theme.of(context).colorScheme.secondary),
          title: const Text("点击屏幕左右区域翻页"),
          trailing: Switch(
            value: pageChangeValue,
            onChanged: (b) {
              b ? appdata.settings[0] = "1" : appdata.settings[0] = "0";
              setState(() {
                pageChangeValue = b;
              });
              appdata.writeData();
            },
          ),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.volume_mute, color: Theme.of(context).colorScheme.secondary),
          title: const Text("使用音量键翻页"),
          trailing: Switch(
            value: useVolumeKeyChangePage,
            onChanged: (b) {
              b ? appdata.settings[7] = "1" : appdata.settings[7] = "0";
              setState(() {
                useVolumeKeyChangePage = b;
              });
              appdata.writeData();
              Get.find<ComicReadingPageLogic>().update();
            },
          ),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.control_camera, color: Theme.of(context).colorScheme.secondary),
          title: const Text("宽屏时显示前进后退关闭按钮"),
          onTap: () {},
          trailing: Switch(
            value: showThreeButton,
            onChanged: (b) {
              b ? appdata.settings[4] = "1" : appdata.settings[4] = "0";
              setState(() {
                showThreeButton = b;
              });
              appdata.writeData();
            },
          ),
        ),
        if (!GetPlatform.isWeb && GetPlatform.isAndroid)
          ListTile(
            leading:
                Icon(Icons.screenshot_outlined, color: Theme.of(context).colorScheme.secondary),
            title: const Text("保持屏幕常亮"),
            onTap: () {},
            trailing: Switch(
              value: keepScreenOn,
              onChanged: (b) {
                b ? setKeepScreenOn() : cancelKeepScreenOn();
                b ? appdata.settings[14] = "1" : appdata.settings[14] = "0";
                setState(() {
                  keepScreenOn = b;
                });
                appdata.writeData();
              },
            ),
          ),
        ListTile(
          leading: Icon(Icons.chrome_reader_mode, color: Theme.of(context).colorScheme.secondary),
          title: const Text("选择阅读模式"),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => setReadingMethod(context),
        )
      ],
    );
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
    appdata.writeData();
    update();
    var logic = Get.find<ComicReadingPageLogic>();
    logic.index = 1;
    logic.tools = false;
    logic.showSettings = false;
    logic.change();
    Get.back();
  }
}
