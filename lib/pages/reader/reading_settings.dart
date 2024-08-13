part of pica_reader;

void showSettings(BuildContext context) {
  if (UiMode.m1(context)) {
    showModalBottomSheet(
        context: context,
        builder: (context) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: const ReadingSettings(),
            ));
  } else {
    showSideBar(
        context,
        const SingleChildScrollView(
          child: ReadingSettings(),
        ),
        useSurfaceTintColor: true,
        width: 450);
  }
}

class ReadingSettings extends StatefulWidget {
  const ReadingSettings({Key? key}) : super(key: key);

  @override
  State<ReadingSettings> createState() => _ReadingSettingsState();
}

class _ReadingSettingsState extends State<ReadingSettings> {
  bool pageChangeValue = appdata.settings[0] == "1";
  bool useVolumeKeyChangePage = appdata.settings[7] == "1";
  bool keepScreenOn = appdata.settings[14] == "1";
  bool lowBrightness = appdata.settings[18] == "1";
  var value = int.parse(appdata.settings[9]);
  int i = 0;
  double opacityLevel = 1.0;

  @override
  Widget build(BuildContext context) {
    var logic = StateController.find<ComicReadingPageLogic>();
    var pages = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 0, 5),
            child: Text(
              "阅读设置".tl,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome_motion),
            title: Text("首页显示单张图片".tl),
            trailing: Switch(
              value: appdata.implicitData[1] == '1',
              onChanged: (b) {
                appdata.implicitData[1] = b ? '1' : '0';
                appdata.writeData();
                setState(() {});
                logic.update();
              },
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.touch_app_outlined),
            title: Text("点按翻页".tl),
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
            leading: const SizedBox(),
            title: Text("点按翻页识别范围".tl),
            subtitle: SizedBox(
              height: 25,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                      top: 0,
                      bottom: 0,
                      left: -20,
                      right: 0,
                      child: Slider(
                        max: 40,
                        min: 0,
                        divisions: 40,
                        value: int.parse(appdata.settings[40]).toDouble(),
                        overlayColor: WidgetStateColor.resolveWith(
                            (states) => Colors.transparent),
                        onChanged: (v) {
                          if (v == 0) return;
                          appdata.settings[40] = v.toInt().toString();
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
                "${appdata.settings[40]}%",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.touch_app),
            title: Text("反转点按翻页".tl),
            trailing: Switch(
              value: appdata.settings[70] == "1",
              onChanged: (b) => setState(() {
                appdata.settings[70] = b ? "1" : "0";
                appdata.updateSettings();
              }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.volume_mute),
            title: Text("使用音量键翻页".tl),
            trailing: Switch(
              value: useVolumeKeyChangePage,
              onChanged: (b) {
                b ? appdata.settings[7] = "1" : appdata.settings[7] = "0";
                setState(() {
                  useVolumeKeyChangePage = b;
                });
                appdata.writeData();
                logic.update();
              },
            ),
            onTap: () {},
          ),
          if (App.isAndroid)
            ListTile(
              leading: const Icon(Icons.screenshot_outlined),
              title: Text("保持屏幕常亮".tl),
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
            leading: const Icon(Icons.brightness_4),
            title: Text("深色模式下降低图片亮度".tl),
            onTap: () {},
            trailing: Switch(
              value: lowBrightness,
              onChanged: (b) {
                b ? appdata.settings[18] = "1" : appdata.settings[18] = "0";
                setState(() {
                  lowBrightness = b;
                });
                appdata.writeData();
                logic.update();
              },
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
          if (logic.readingMethod != ReadingMethod.topToBottomContinuously)
            ListTile(
              leading: const Icon(Icons.fit_screen_outlined),
              title: Text("图片缩放".tl),
              onTap: () {},
              trailing: Select(
                initialValue: int.parse(appdata.settings[41]),
                values: ["容纳".tl, "适应宽度".tl, "适应高度".tl],
                onChange: (int i) {
                  appdata.settings[41] = i.toString();
                  appdata.updateSettings();
                  logic.photoViewController.resetWithNewBoxFit(switch(i){
                    0 => BoxFit.contain,
                    1 => BoxFit.fitWidth,
                    2 => BoxFit.fitHeight,
                    _ => BoxFit.contain,
                  });
                },
              ),
            ),
          ListTile(
            leading: const Icon(Icons.zoom_out_map),
            title: Text("双击缩放".tl),
            onTap: () {},
            trailing: Switch(
              value: appdata.settings[49] == "1",
              onChanged: (value) {
                appdata.settings[49] = value ? "1" : "0";
                logic.update();
                appdata.updateSettings();
                setState(() {});
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.timer_sharp),
            subtitle: SizedBox(
              height: 25,
              child: Stack(
                clipBehavior: Clip.none,
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
                        overlayColor: WidgetStateColor.resolveWith(
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
          if (logic.readingMethod == ReadingMethod.topToBottomContinuously)
            ListTile(
              leading: const Icon(Icons.width_normal_sharp),
              title: Text("限制图片最大显示宽度".tl),
              trailing: Switch(
                value: appdata.settings[43] == "1",
                onChanged: (b) => setState(() {
                  appdata.settings[43] = b ? "1" : "0";
                  appdata.updateSettings();
                  Future.microtask(() => logic.update());
                }),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.zoom_in),
            title: Text("长按缩放".tl),
            trailing: Switch(
              value: appdata.settings[55] == "1",
              onChanged: (b) => setState(() {
                appdata.settings[55] = b ? "1" : "0";
                appdata.updateSettings();
                Future.microtask(() => logic.update());
              }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text("显示页面信息".tl),
            trailing: Switch(
              value: appdata.settings[57] == "1",
              onChanged: (b) => setState(() {
                appdata.settings[57] = b ? "1" : "0";
                appdata.updateSettings();
                Future.microtask(() => logic.update());
              }),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chrome_reader_mode),
            title: Text("选择阅读模式".tl),
            trailing: const Icon(Icons.arrow_right),
            onTap: () => setState(() {
              i = 1;
            }),
          ),
          if (!logic.data.downloaded &&
              (logic.data.type == ReadingType.picacg ||
                  logic.data.type == ReadingType.jm))
            ListTile(
              leading: const Icon(Icons.account_tree_sharp),
              title: Text("设置分流".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => setState(() {
                i = 2;
              }),
            ),
        ],
      ),
      buildReadingMethodSetting(),
      Column(
        children: [
          SizedBox(
            height: 60,
            child: Row(
              children: [
                const SizedBox(
                  width: 6,
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_back_outlined,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => setState(() {
                    i = 0;
                  }),
                ),
                Text(
                  "设置分流".tl,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 40,
          ),
          Center(
            child: FilledButton(
              child: const Text("重启阅读器"),
              onPressed: () {
                App.globalBack();
                logic.refresh_();
              },
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    ];

    return ClipRect(
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        reverseDuration: const Duration(milliseconds: 0),
        switchInCurve: Curves.ease,
        transitionBuilder: (Widget child, Animation<double> animation) {
          Tween<Offset> tween;
          if (i == 0) {
            tween = Tween<Offset>(
                begin: const Offset(-0.1, 0), end: const Offset(0, 0));
          } else {
            tween = Tween<Offset>(
                begin: const Offset(0.1, 0), end: const Offset(0, 0));
          }
          return SlideTransition(
            position: tween.animate(animation),
            child: child,
          );
        },
        child: SingleChildScrollView(
          primary: false,
          key: Key(i.toString()),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: pages[i],
        ),
      ),
    );
  }

  void setValue(int i) {
    App.globalBack();
    value = i;
    appdata.settings[9] = value.toString();
    appdata.writeData();
    var logic = StateController.find<ComicReadingPageLogic>();
    logic.tools = false;
    logic.showSettings = false;
    logic.index = 1;
    logic.pageController = PageController(initialPage: 1);
    logic.clearPhotoViewControllers();
    logic.update();
  }

  Widget buildReadingMethodSetting() {
    var options = [
      "从左至右".tl,
      "从右至左".tl,
      "从上至下".tl,
      "从上至下(连续)".tl,
      "双页".tl,
      "双页(反向)".tl
    ];
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: Row(
            children: [
              const SizedBox(
                width: 6,
              ),
              IconButton(
                icon: Icon(
                  Icons.arrow_back_outlined,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => setState(() {
                  i = 0;
                }),
              ),
              Text(
                "选择阅读模式".tl,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
        ...List.generate(
            6,
            (index) => ListTile(
                  trailing: Radio<int>(
                    value: index + 1,
                    groupValue: value,
                    onChanged: (i) {
                      setValue(i!);
                    },
                  ),
                  title: Text(options[index]),
                  onTap: () {
                    setValue(index + 1);
                  },
                ))
      ],
    );
  }
}
