import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/settings/blocking_keyword_page.dart';
import 'package:pica_comic/views/settings/picacg_settings.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../widgets/select.dart';
import 'eh_settings.dart';
import 'jm_settings.dart';
import 'app_settings.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({this.popUp = false, Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool pageChangeValue = appdata.settings[0] == "1";
  bool checkUpdateValue = appdata.settings[2] == "1";
  bool showThreeButton = appdata.settings[4] == "1";
  bool useVolumeKeyChangePage = appdata.settings[7] == "1";
  bool blockScreenshot = appdata.settings[12] == "1";
  bool needBiometrics = appdata.settings[13] == "1";
  bool keepScreenOn = appdata.settings[14] == "1";
  bool lowBrightness = appdata.settings[18] == "1";

  @override
  Widget build(BuildContext context) {
    var body = CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [

              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("浏览"),
                    ),
                    ListTile(
                      leading: Icon(Icons.block, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("关键词屏蔽"),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => BlockingKeywordPage(
                                popUp: widget.popUp,
                              ))),
                      trailing: const Icon(Icons.arrow_right),
                    ),
                    if (!GetPlatform.isWeb)
                      ListTile(
                        leading: Icon(Icons.network_ping,
                            color: Theme.of(context).colorScheme.secondary),
                        title: const Text("设置代理"),
                        trailing: const Icon(
                          Icons.arrow_right,
                        ),
                        onTap: () {
                          setProxy(context);
                        },
                      ),
                    ListTile(
                      leading: Icon(Icons.source, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("启用的漫画源"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => setComicSource(context),
                    )
                  ],
                ),
              ),

              const Divider(),

              PicacgSettings(widget.popUp),

              const Divider(),

              EhSettings(widget.popUp),

              const Divider(),

              JmSettings(widget.popUp),

              const Divider(),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("阅读"),
                    ),
                    ListTile(
                      leading: Icon(Icons.touch_app_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      title: const Text("点按翻页"),
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
                      title: const Text("使用音量键翻页"),
                      subtitle: const Text("仅安卓端有效"),
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
                      title: const Text("宽屏时显示前进后退关闭按钮"),
                      subtitle: const Text("优化鼠标阅读体验"),
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
                        title: const Text("保持屏幕常亮"),
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
                      title: const Text("夜间模式降低图片亮度"),
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
                      title: const Text("选择阅读模式"),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[9])-1,
                        values: const [
                          "从左向右",
                          "从右向左",
                          "从上至下",
                          "从上至下(连续)"
                        ],
                        whenChange: (i){
                          appdata.settings[9] = (i+1).toString();
                          appdata.updateSettings();
                        },
                        inPopUpWidget: widget.popUp,
                        width: 140,
                      ),
                    )
                  ],
                ),
              ),
              const Divider(),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("App"),
                    ),
                    if (!GetPlatform.isWeb)
                      ListTile(
                        leading: Icon(Icons.update, color: Theme.of(context).colorScheme.secondary),
                        title: const Text("检查更新"),
                        subtitle: const Text("当前: $appVersion"),
                        onTap: () {
                          findUpdate(context);
                        },
                      ),
                    if (!GetPlatform.isWeb)
                      ListTile(
                        leading: Icon(Icons.security_update,
                            color: Theme.of(context).colorScheme.secondary),
                        title: const Text("启动时检查更新"),
                        trailing: Switch(
                          value: checkUpdateValue,
                          onChanged: (b) {
                            b ? appdata.settings[2] = "1" : appdata.settings[2] = "0";
                            setState(() => checkUpdateValue = b);
                            appdata.writeData();
                          },
                        ),
                        onTap: () {},
                      ),
                    if(GetPlatform.isWindows)
                      ListTile(
                        leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.secondary),
                        title: const Text("设置下载目录"),
                        onTap: () => setDownloadFolder(context),
                      ),
                    if (!GetPlatform.isWeb)
                      GetBuilder<CalculateCacheLogic>(
                          init: CalculateCacheLogic(),
                          builder: (logic) {
                            if (logic.calculating) {
                              logic.get();
                              return ListTile(
                                leading: Icon(Icons.storage,
                                    color: Theme.of(context).colorScheme.secondary),
                                title: const Text("缓存大小"),
                                subtitle: const Text("计算中"),
                                onTap: () {},
                              );
                            } else {
                              return ListTile(
                                leading: Icon(Icons.storage,
                                    color: Theme.of(context).colorScheme.secondary),
                                title: const Text("清除缓存"),
                                subtitle: Text(
                                    "${logic.size == double.infinity ? "未知" : logic.size.toStringAsFixed(2)} MB"),
                                onTap: () {
                                  if (GetPlatform.isAndroid) {
                                    eraseCache();
                                    logic.size = 0;
                                    logic.update();
                                  } else if (GetPlatform.isWindows) {
                                    eraseCache();
                                  }
                                },
                              );
                            }
                          })
                  ],
                ),
              ),
              if (!GetPlatform.isWeb) const Divider(),
              if (!GetPlatform.isWeb)
                Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      const ListTile(
                        title: Text("隐私"),
                      ),
                      if (GetPlatform.isAndroid)
                        ListTile(
                          leading: Icon(Icons.screenshot,
                              color: Theme.of(context).colorScheme.secondary),
                          title: const Text("阻止屏幕截图"),
                          subtitle: const Text("需要重启App以应用更改"),
                          trailing: Switch(
                            value: blockScreenshot,
                            onChanged: (b) {
                              b ? appdata.settings[12] = "1" : appdata.settings[12] = "0";
                              setState(() => blockScreenshot = b);
                              appdata.writeData();
                            },
                          ),
                          onTap: () => showMessage(context, "禁止涩涩"),
                        ),
                      ListTile(
                        leading:
                            Icon(Icons.security, color: Theme.of(context).colorScheme.secondary),
                        title: const Text("需要身份验证"),
                        subtitle: const Text("如果系统中未设置任何认证方法请勿开启"),
                        trailing: Switch(
                          value: needBiometrics,
                          onChanged: (b) {
                            b ? appdata.settings[13] = "1" : appdata.settings[13] = "0";
                            setState(() => needBiometrics = b);
                            appdata.writeData();
                          },
                        ),
                        onTap: () => showMessage(context, "禁止涩涩"),
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    const ListTile(
                      title: Text("关于"),
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("PicaComic"),
                      subtitle: const Text("本软件仅用于学习交流"),
                      onTap: () => showMessage(context, "禁止涩涩"),
                    ),
                    ListTile(
                      leading: Icon(Icons.code, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("项目地址"),
                      subtitle: const Text("https://github.com/wgh136/PicaComic"),
                      onTap: () => launchUrlString("https://github.com/wgh136/PicaComic",
                          mode: LaunchMode.externalApplication),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("提出建议"),
                      onTap: () => giveComments(context),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
        SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
      ],
    );
    if (widget.popUp) {
      return PopUpWidgetScaffold(title: "设置", body: body);
    } else {
      return Scaffold(
        appBar: AppBar(title: const Text("设置")),
        body: body,
      );
    }
  }
}
