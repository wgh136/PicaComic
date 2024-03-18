part of pica_settings;

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
        SwitchSetting(
          title: "点按翻页".tl,
          settingsIndex: 0,
          icon: const Icon(Icons.touch_app_outlined),
        ),
        SwitchSetting(
          title: "点按翻页".tl,
          settingsIndex: 70,
          icon: const Icon(Icons.touch_app),
        ),
        if (App.isAndroid)
          SwitchSetting(
            title: "使用音量键翻页".tl,
            settingsIndex: 7,
            icon: const Icon(Icons.volume_mute),
          ),
        SwitchSetting(
          title: "宽屏时显示控制按钮".tl,
          settingsIndex: 4,
          icon: const Icon(Icons.control_camera),
        ),
        SwitchSetting(
          title: "保持屏幕常亮".tl,
          settingsIndex: 14,
          icon: const Icon(Icons.screenshot_outlined),
        ),
        if (App.isAndroid)
          SwitchSetting(
            title: "保持屏幕常亮".tl,
            settingsIndex: 14,
            icon: const Icon(Icons.screenshot_outlined),
          ),
        SwitchSetting(
          title: "深色模式下降低图片亮度".tl,
          settingsIndex: 18,
          icon: const Icon(Icons.brightness_4),
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
            initialValue: ["0", "1", "2", "3", "4", "5", "10", "15"].indexOf(appdata.settings[28]),
            values: const ["0", "1", "2", "3", "4", "5", "10", "15"],
            whenChange: (i) {
              appdata.settings[28] = ["0", "1", "2", "3", "4", "5", "10", "15"][i];
              appdata.updateSettings();
            },
            inPopUpWidget: widget.popUp,
            width: 140,
          ),
        ),
        SwitchSetting(
          title: "翻页动画".tl,
          settingsIndex: 36,
          icon: const Icon(Icons.animation),
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
        SwitchSetting(
          title: "双击缩放".tl,
          settingsIndex: 49,
          icon: const Icon(Icons.zoom_out_map),
        ),
        SwitchSetting(
          title: "长按缩放".tl,
          settingsIndex: 55,
          icon: const Icon(Icons.zoom_in),
        ),
        SwitchSetting(
          title: "显示页面信息".tl,
          settingsIndex: 57,
          icon: const Icon(Icons.insert_drive_file_outlined),
        ),
        if(App.isAndroid)
          SwitchSetting(
            title: "固定横屏".tl,
            settingsIndex: 76,
            icon: const Icon(Icons.screen_lock_landscape),
          ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
      ],
    );
  }
}
