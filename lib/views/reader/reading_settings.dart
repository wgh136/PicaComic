import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'package:pica_comic/views/reader/reading_type.dart';
import 'package:pica_comic/views/widgets/side_bar.dart';
import '../../foundation/ui_mode.dart';
import '../../network/picacg_network/methods.dart';
import '../../tools/keep_screen_on.dart';
import '../widgets/select.dart';
import '../widgets/show_message.dart';
import 'reading_logic.dart';
import 'package:pica_comic/tools/translations.dart';

void showSettings(BuildContext context){
  if(UiMode.m1(context)){
    showModalBottomSheet(context: context, builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height*0.6,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          child: const ReadingSettings(),
        ),
      ),
    ));
  }else{
    showSideBar(context, const SingleChildScrollView(
      child: ReadingSettings(),
    ), useSurfaceTintColor: true, width: 450);
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
    var logic = Get.find<ComicReadingPageLogic>();
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
            leading: Icon(Icons.touch_app_outlined,
                color: Theme.of(context).colorScheme.secondary),
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
            leading: Icon(Icons.touch_app_outlined,
                color: Theme.of(context).colorScheme.secondary),
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
                        max: 50,
                        min: 0,
                        divisions: 50,
                        value: int.parse(appdata.settings[40]).toDouble(),
                        overlayColor: MaterialStateColor.resolveWith(
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
            leading: Icon(Icons.volume_mute,
                color: Theme.of(context).colorScheme.secondary),
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
          if (!GetPlatform.isWeb && GetPlatform.isAndroid)
            ListTile(
              leading: Icon(Icons.screenshot_outlined,
                  color: Theme.of(context).colorScheme.secondary),
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
            leading: Icon(Icons.brightness_4,
                color: Theme.of(context).colorScheme.secondary),
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
                logic.update();
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.animation,
                color: Theme.of(context).colorScheme.secondary),
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
            leading: Icon(Icons.fit_screen_outlined,
                color: Theme.of(context).colorScheme.secondary),
            title: Text("图片缩放".tl),
            onTap: () {},
            trailing: Select(
              initialValue: int.parse(appdata.settings[41]),
              values: ["容纳".tl, "适应宽度".tl, "适应高度".tl],
              whenChange: (int i) {
                appdata.settings[41] = i.toString();
                appdata.updateSettings();
                logic.update();
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.timer_sharp,
                color: Theme.of(context).colorScheme.secondary),
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
          ListTile(
            leading: Icon(Icons.chrome_reader_mode,
                color: Theme.of(context).colorScheme.secondary),
            title: Text("选择阅读模式".tl),
            trailing: const Icon(Icons.arrow_right),
            onTap: () => setState(() {
              i = 1;
            }),
          ),
          if (!logic.downloaded &&
              (logic.data.type == ReadingType.picacg ||
                  logic.data.type == ReadingType.jm))
            ListTile(
              leading: Icon(Icons.account_tree_sharp,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text("设置分流".tl),
              trailing: const Icon(Icons.arrow_right),
              onTap: () => setState(() {
                i = 2;
              }),
            ),
        ],
      ),
      Column(
        children: [
          const SizedBox(
            width: 400,
          ),
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
          ListTile(
            trailing: Radio<int>(
              value: 1,
              groupValue: value,
              onChanged: (i) {
                setValue(i!);
              },
            ),
            title: Text("从左至右".tl),
            onTap: () {
              setValue(1);
            },
          ),
          ListTile(
            trailing: Radio<int>(
              value: 2,
              groupValue: value,
              onChanged: (i) {
                setValue(i!);
              },
            ),
            title: Text("从右至左".tl),
            onTap: () {
              setValue(2);
            },
          ),
          ListTile(
            trailing: Radio<int>(
              value: 3,
              groupValue: value,
              onChanged: (i) {
                setValue(i!);
              },
            ),
            title: Text("从上至下".tl),
            onTap: () {
              setValue(3);
            },
          ),
          ListTile(
            trailing: Radio<int>(
              value: 4,
              groupValue: value,
              onChanged: (i) {
                setValue(i!);
              },
            ),
            title: Text("从上至下(连续)".tl),
            onTap: () {
              setValue(4);
            },
          ),
          ListTile(
            trailing: Radio<int>(
              value: 5,
              groupValue: value,
              onChanged: (i) {
                setValue(i!);
              },
            ),
            title: Text("双页".tl),
            onTap: () {
              setValue(5);
            },
          ),
          ListTile(
            trailing: Radio<int>(
              value: 6,
              groupValue: value,
              onChanged: (i) {
                setValue(i!);
              },
            ),
            title: Text("双页(反向)".tl),
            onTap: () {
              setValue(6);
            },
          ),
        ],
      ),
      SizedBox(
        width: 400,
        child: Column(
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
            if (logic.data.type == ReadingType.picacg)
              ListTile(
                leading: Icon(Icons.hub_outlined,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("设置分流".tl),
                trailing: Select(
                  initialValue: int.parse(appdata.appChannel) - 1,
                  values: ["分流1".tl, "分流2".tl, "分流3".tl],
                  whenChange: (i) {
                    appdata.appChannel = (i + 1).toString();
                    appdata.writeData();
                    showMessage(Get.context, "正在获取分流IP".tl, time: 8);
                    network.updateApi().then((v) => Get.closeAllSnackbars());
                  },
                ),
              )
            else
              ListTile(
                leading: Icon(Icons.image,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text("图片分流".tl),
                trailing: Select(
                  initialValue: int.parse(appdata.settings[37]),
                  values: [
                    "分流1".tl,"分流2".tl,"分流3".tl,"分流4".tl, "分流5".tl, "分流6".tl,
                  ],
                  whenChange: (i) {
                    MyCacheManager.loadingItems.clear();
                    appdata.settings[37] = i.toString();
                    appdata.updateSettings();
                  },
                ),
              ),
            const SizedBox(
              height: 40,
            ),
            Center(
              child: FilledButton(
                child: const Text("重启阅读器"),
                onPressed: () {
                  Get.back();
                  logic.refresh_();
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
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
        child: SizedBox(
          key: Key(i.toString()),
          width: double.infinity,
          child: pages[i],
        ),
      ),
    );
  }

  void setValue(int i) {
    Get.back();
    value = i;
    appdata.settings[9] = value.toString();
    appdata.writeData();
    var logic = Get.find<ComicReadingPageLogic>();
    logic.tools = false;
    logic.showSettings = false;
    logic.index = 1;
    logic.pageController = PageController(initialPage: 1);
    logic.update();
  }
}
