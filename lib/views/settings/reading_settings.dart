import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import '../../base.dart';
import '../widgets/select.dart';
import 'package:pica_comic/tools/translations.dart';

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
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.touch_app_outlined),
          title: Text("点按翻页".tl),
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
        if (App.isAndroid)
          ListTile(
            leading: const Icon(Icons.volume_mute),
            title: Text("使用音量键翻页".tl),
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
          leading: const Icon(Icons.control_camera),
          title: Text("宽屏时显示控制按钮".tl),
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
        if (App.isAndroid)
          ListTile(
            leading: const Icon(Icons.screenshot_outlined),
            title: Text("保持屏幕常亮".tl),
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
          leading: const Icon(Icons.brightness_4),
          title: Text("夜间模式降低图片亮度".tl),
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
          leading: const Icon(Icons.chrome_reader_mode),
          title: Text("选择阅读模式".tl),
          trailing: Select(
            initialValue: int.parse(appdata.settings[9]) - 1,
            values: [
              "从左至右".tl,
              "从右至左".tl,
              "从上至下".tl,
              "从上至下(连续)".tl,
              "双页".tl,
              "双页(反向)".tl
            ],
            whenChange: (i) {
              appdata.settings[9] = (i + 1).toString();
              appdata.updateSettings();
            },
            inPopUpWidget: widget.popUp,
            width: 140,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.image_outlined),
          title: Text("图片预加载".tl),
          trailing: Select(
            initialValue: int.parse(appdata.settings[28]),
            values: const ["0", "1", "2", "3", "4", "5"],
            whenChange: (i) {
              appdata.settings[28] = i.toString();
              appdata.updateSettings();
            },
            inPopUpWidget: widget.popUp,
            width: 140,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.animation),
          title: Text("翻页动画".tl),
          onTap: () {},
          trailing: Switch(
            value: appdata.settings[36] == "1",
            onChanged: (b) {
              setState(() {
                b ? appdata.settings[36] = "1" : appdata.settings[36] = "0";
              });
              appdata.writeData();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.timer_sharp),
          subtitle: SizedBox(
            height: 25,
            child: Stack(
              children: [
                Positioned(
                    top: 0,
                    bottom: 0,
                    left: -20,
                    right: 0,
                    child: Slider(
                      max: 20,
                      min: 0,
                      divisions: 20,
                      value: int.parse(appdata.settings[33]).toDouble(),
                      overlayColor: MaterialStateColor.resolveWith(
                          (states) => Colors.transparent),
                      onChanged: (v) {
                        if (v == 0) return;
                        appdata.settings[33] = v.toInt().toString();
                        appdata.updateSettings();
                        setState(() {});
                      },
                    ))
              ],
            ),
          ),
          trailing: SizedBox(
            width: 40,
            child: Text(
              "${appdata.settings[33]}秒",
              style: const TextStyle(fontSize: 14),
            ),
          ),
          title: Text("自动翻页时间间隔".tl),
        ),
      ],
    );
  }
}
