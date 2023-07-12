import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'reading_settings.dart';
import 'package:pica_comic/views/settings/blocking_keyword_page.dart';
import 'package:pica_comic/views/settings/ht_settings.dart';
import 'package:pica_comic/views/settings/picacg_settings.dart';
import 'package:pica_comic/views/widgets/pop_up_widget_scaffold.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../logs_page.dart';
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
  bool checkUpdateValue = appdata.settings[2] == "1";
  bool blockScreenshot = appdata.settings[12] == "1";
  bool needBiometrics = appdata.settings[13] == "1";

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
                    ListTile(
                      title: Text("浏览".tr),
                    ),
                    ListTile(
                      leading: Icon(Icons.block, color: Theme.of(context).colorScheme.secondary),
                      title: Text("关键词屏蔽".tr),
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
                        title: Text("设置代理".tr),
                        trailing: const Icon(
                          Icons.arrow_right,
                        ),
                        onTap: () {
                          setProxy(context);
                        },
                      ),
                    ListTile(
                      leading: Icon(Icons.article_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("初始页面".tr),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[23]),
                        whenChange: (i){
                          appdata.settings[23] = i.toString();
                          appdata.updateSettings();
                        },
                        values: const ["我", "探索", "分类"],
                        inPopUpWidget: widget.popUp,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.source, color: Theme.of(context).colorScheme.secondary),
                      title:  Text("漫画源(非探索页面)".tr),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => setComicSource(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.pages, color: Theme.of(context).colorScheme.secondary),
                      title:  Text("显示的探索页面".tr),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => setExplorePages(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.list,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("漫画列表显示方式".tr),
                      subtitle: Text("适用于非探索页面".tr),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[25]),
                        whenChange: (i){
                          appdata.settings[25] = i.toString();
                          appdata.updateSettings();
                        },
                        values: const ["顺序显示", "分页显示"],
                        inPopUpWidget: widget.popUp,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.file_download_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("已下载的漫画排序方式".tr),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[26]),
                        whenChange: (i){
                          appdata.settings[26] = i.toString();
                          appdata.updateSettings();
                        },
                        values: const ["时间", "漫画名", "作者名", "大小"],
                        inPopUpWidget: widget.popUp,
                      ),
                    ),
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

              HtSettings(widget.popUp),

              const Divider(),
              ReadingSettings(widget.popUp),

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
                        title: Text("检查更新".tr),
                        subtitle: Text("${"当前:".tr} $appVersion"),
                        onTap: () {
                          findUpdate(context);
                        },
                      ),
                    if (!GetPlatform.isWeb)
                      ListTile(
                        leading: Icon(Icons.security_update,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text("启动时检查更新".tr),
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
                    if(GetPlatform.isWindows || GetPlatform.isAndroid)
                      ListTile(
                        leading: Icon(Icons.folder, color: Theme.of(context).colorScheme.secondary),
                        title: Text("设置下载目录".tr),
                        onTap: () => setDownloadFolder(),
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
                                title: Text("缓存大小".tr),
                                subtitle: Text("计算中".tr),
                                onTap: () {},
                              );
                            } else {
                              return ListTile(
                                leading: Icon(Icons.storage,
                                    color: Theme.of(context).colorScheme.secondary),
                                title: Text("清除缓存".tr),
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
                          }),
                    ListTile(
                      leading: Icon(Icons.color_lens,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("主题选择".tr),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[27]),
                        values: const ["动态", "Blue", "Light Blue", "Indigo", "Purple", "Pink", "Cyan", "Teal", "Yellow", "Brown"],
                        whenChange: (i){
                          appdata.settings[27] = i.toString();
                          appdata.updateSettings();
                          Get.forceAppUpdate();
                        },
                        inPopUpWidget: widget.popUp,
                        width: 140,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.dark_mode,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("深色模式".tr),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[32]),
                        values: ["跟随系统".tr, "禁用".tr, "启用".tr],
                        whenChange: (i){
                          appdata.settings[32] = i.toString();
                          appdata.updateSettings();
                          Get.forceAppUpdate();
                        },
                        inPopUpWidget: widget.popUp,
                        width: 140,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.bug_report, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("日志"),
                      onTap: ()=>Get.to(()=>const LogsPage()),
                    )
                  ],
                ),
              ),
              if (!GetPlatform.isWeb) const Divider(),
              if (!GetPlatform.isWeb)
                Card(
                  elevation: 0,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("隐私".tr),
                      ),
                      if (GetPlatform.isAndroid)
                        ListTile(
                          leading: Icon(Icons.screenshot,
                              color: Theme.of(context).colorScheme.secondary),
                          title: Text("阻止屏幕截图".tr),
                          subtitle: Text("需要重启App以应用更改".tr),
                          trailing: Switch(
                            value: blockScreenshot,
                            onChanged: (b) {
                              b ? appdata.settings[12] = "1" : appdata.settings[12] = "0";
                              setState(() => blockScreenshot = b);
                              appdata.writeData();
                            },
                          ),
                        ),
                      ListTile(
                        leading:
                            Icon(Icons.security, color: Theme.of(context).colorScheme.secondary),
                        title: Text("需要身份验证".tr),
                        subtitle: Text("如果系统中未设置任何认证方法请勿开启".tr),
                        trailing: Switch(
                          value: needBiometrics,
                          onChanged: (b) {
                            b ? appdata.settings[13] = "1" : appdata.settings[13] = "0";
                            setState(() => needBiometrics = b);
                            appdata.writeData();
                          },
                        )
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
                      subtitle: Text("本软件仅用于学习交流".tr),
                      onTap: () => showMessage(context, "禁止涩涩"),
                    ),
                    ListTile(
                      leading: Icon(Icons.code, color: Theme.of(context).colorScheme.secondary),
                      title: Text("项目地址".tr),
                      subtitle: const Text("https://github.com/wgh136/PicaComic"),
                      onTap: () => launchUrlString("https://github.com/wgh136/PicaComic",
                          mode: LaunchMode.externalApplication),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.secondary),
                      title: Text("提出建议".tr),
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
      return PopUpWidgetScaffold(title: "设置".tr, body: body);
    } else {
      return Scaffold(
        appBar: AppBar(title: Text("设置".tr)),
        body: body,
      );
    }
  }
}
