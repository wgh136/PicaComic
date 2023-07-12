import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../base.dart';
import '../widgets/select.dart';

class ReadingSettings extends StatefulWidget {
  const ReadingSettings(this.popUp, {super.key});

  final bool popUp;

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool keepScreenOn = appdata.settings[14] == "1";
  bool lowBrightness = appdata.settings[18] == "1";
  bool pageChangeValue = appdata.settings[0] == "1";
  bool showThreeButton = appdata.settings[4] == "1";
  bool useVolumeKeyChangePage = appdata.settings[7] == "1";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text("阅读".tr),
        ),
        ListTile(
          leading: Icon(Icons.touch_app_outlined,
              color: Theme.of(context).colorScheme.secondary),
          title: Text("点按翻页".tr),
          trailing: Switch(
            value: pageChangeValue,
            onChanged: (b) {
              b ? appdata.settings[0] = "1" : appdata.settings[0] = "0";
              setState(() => pageChangeValue = b);
              appdata.writeData();
            },
          ),
          onTap: () {},
        ),
        ListTile(
          leading:
          Icon(Icons.volume_mute, color: Theme.of(context).colorScheme.secondary),
          title: Text("使用音量键翻页".tr),
          subtitle: Text("仅安卓端有效".tr),
          trailing: Switch(
            value: useVolumeKeyChangePage,
            onChanged: (b) {
              b ? appdata.settings[7] = "1" : appdata.settings[7] = "0";
              setState(() => useVolumeKeyChangePage = b);
              appdata.writeData();
            },
          ),
          onTap: () {},
        ),
        ListTile(
          leading: Icon(Icons.control_camera,
              color: Theme.of(context).colorScheme.secondary),
          title: Text("宽屏时显示前进后退关闭按钮".tr),
          subtitle: Text("优化鼠标阅读体验".tr),
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
            leading: Icon(Icons.screenshot_outlined,
                color: Theme.of(context).colorScheme.secondary),
            title: Text("保持屏幕常亮".tr),
            onTap: () {},
            trailing: Switch(
              value: keepScreenOn,
              onChanged: (b) {
                b ? appdata.settings[14] = "1" : appdata.settings[14] = "0";
                setState(() {
                  keepScreenOn = b;
                });
                appdata.writeData();
              },
            ),
          ),
        ListTile(
          leading: Icon(Icons.brightness_4, color: Theme.of(context).colorScheme.secondary),
          title: Text("夜间模式降低图片亮度".tr),
          onTap: () {},
          trailing: Switch(
            value: lowBrightness,
            onChanged: (b) {
              b ? appdata.settings[18] = "1" : appdata.settings[18] = "0";
              setState(() {
                lowBrightness = b;
              });
              appdata.writeData();
            },
          ),
        ),
        ListTile(
          leading: Icon(Icons.chrome_reader_mode,
              color: Theme.of(context).colorScheme.secondary),
          title: Text("选择阅读模式".tr),
          trailing: Select(
            initialValue: int.parse(appdata.settings[9])-1,
            values: [
              "从左至右".tr,
              "从右至左".tr,
              "从上至下".tr,
              "从上至下(连续)".tr
            ],
            whenChange: (i){
              appdata.settings[9] = (i+1).toString();
              appdata.updateSettings();
            },
            inPopUpWidget: widget.popUp,
            width: 140,
          ),
        ),
        ListTile(
          leading: Icon(Icons.image_outlined,
              color: Theme.of(context).colorScheme.secondary),
          title: Text("图片预加载".tr),
          trailing: Select(
            initialValue: int.parse(appdata.settings[28]),
            values: const ["0","1","2","3","4","5"],
            whenChange: (i){
              appdata.settings[28] = i.toString();
              appdata.updateSettings();
            },
            inPopUpWidget: widget.popUp,
            width: 140,
          ),
        ),
      ],
    );
  }
}
