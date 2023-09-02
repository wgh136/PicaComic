import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/tools/extensions.dart';
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
import 'package:pica_comic/tools/translations.dart';


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
                      title: Text("浏览".tl),
                    ),
                    ListTile(
                      leading: Icon(Icons.block, color: Theme.of(context).colorScheme.secondary),
                      title: Text("关键词屏蔽".tl),
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
                        title: Text("设置代理".tl),
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
                      title: Text("初始页面".tl),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[23]),
                        whenChange: (i){
                          appdata.settings[23] = i.toString();
                          appdata.updateSettings();
                        },
                        values: ["我".tl, "探索".tl, "分类".tl, "排行榜".tl],
                        inPopUpWidget: widget.popUp,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.source, color: Theme.of(context).colorScheme.secondary),
                      title:  Text("漫画源(非探索页面)".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => setComicSource(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.pages, color: Theme.of(context).colorScheme.secondary),
                      title:  Text("显示的探索页面".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => setExplorePages(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.list,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("漫画列表显示方式".tl),
                      subtitle: Text("适用于非探索页面".tl),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[25]),
                        whenChange: (i){
                          appdata.settings[26] = appdata.settings[25] = i.toString();
                          appdata.updateSettings();
                        },
                        values: ["顺序显示".tl, "分页显示".tl],
                        inPopUpWidget: widget.popUp,
                      ),
                    ),
                    ListTile(
                      leading: Icon(Icons.file_download_outlined,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("已下载的漫画排序方式".tl),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[26][0]),
                        whenChange: (i){
                          appdata.settings[26].setValueAt(i.toString(), 0);
                          appdata.updateSettings();
                        },
                        values: ["时间".tl, "漫画名".tl, "作者名".tl, "大小".tl],
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
                    ListTile(
                      title: Text("外观".tl),
                    ),
                    ListTile(
                      leading: Icon(Icons.color_lens,
                          color: Theme.of(context).colorScheme.secondary),
                      title: Text("主题选择".tl),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[27]),
                        values: const ["Dynamic", "Blue", "Light Blue", "Indigo", "Purple", "Pink", "Cyan", "Teal", "Yellow", "Brown"],
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
                      title: Text("深色模式".tl),
                      trailing: Select(
                        initialValue: int.parse(appdata.settings[32]),
                        values: ["跟随系统".tl, "禁用".tl, "启用".tl],
                        whenChange: (i){
                          appdata.settings[32] = i.toString();
                          appdata.updateSettings();
                          Get.forceAppUpdate();
                        },
                        inPopUpWidget: widget.popUp,
                        width: 140,
                      ),
                    ),
                    if(GetPlatform.isAndroid)
                      ListTile(
                        leading: Icon(Icons.smart_screen_outlined,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("高刷新率模式".tl),
                            const SizedBox(width: 2,),
                            InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(18)),
                              onTap: () => showDialogMessage(
                                  context,
                                  "高刷新率模式".tl,
                                  "启用后, APP将尝试设置高刷新率\n"
                                  "如果OS没有限制APP的刷新率, 无需启用此项\n"
                                  "OS可能不会响应更改"
                              ),
                              child: const Icon(Icons.info_outline, size: 18,),
                            )
                          ],
                        ),
                        trailing: Switch(
                          value: appdata.settings[38] == "1",
                          onChanged: (b){
                            setState(() {
                              appdata.settings[38] = b? "1" : "0";
                            });
                            appdata.updateSettings();
                            if(b){
                              try {
                                FlutterDisplayMode.setHighRefreshRate();
                              }
                              catch(e){
                                // ignore
                              }
                            }else{
                              try {
                                FlutterDisplayMode.setLowRefreshRate();
                              }
                              catch(e){
                                // ignore
                              }
                            }
                          },
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
                        title: Text("检查更新".tl),
                        subtitle: Text("${"当前:".tl} $appVersion"),
                        onTap: () {
                          findUpdate(context);
                        },
                      ),
                    if (!GetPlatform.isWeb)
                      ListTile(
                        leading: Icon(Icons.security_update,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text("启动时检查更新".tl),
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
                        title: Text("设置下载目录".tl),
                        trailing: const Icon(Icons.arrow_right),
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
                                title: Text("缓存大小".tl),
                                subtitle: Text("计算中".tl),
                                onTap: () {},
                              );
                            } else {
                              return ListTile(
                                leading: Icon(Icons.storage,
                                    color: Theme.of(context).colorScheme.secondary),
                                title: Text("清除缓存".tl),
                                subtitle: Text(
                                    "${logic.size == double.infinity ? "未知" : logic.size.toStringAsFixed(2)} MB"),
                                onTap: () {
                                  if (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isWindows) {
                                    showConfirmDialog(context, "清除缓存".tl, "确认清除缓存?".tl, () {
                                      eraseCache();
                                      logic.size = 0;
                                      logic.update();
                                    });
                                  }
                                },
                              );
                            }
                          }),
                    ListTile(
                      leading: Icon(Icons.chrome_reader_mode, color: Theme.of(context).colorScheme.secondary),
                      title: Text("阅读器缓存限制".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => setCacheLimit(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.bug_report, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("Logs"),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: ()=>Get.to(()=>const LogsPage()),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.secondary),
                      title: Text("清除所有数据".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => clearUserData(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.sim_card_download, color: Theme.of(context).colorScheme.secondary),
                      title: Text("导出用户数据".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => exportDataSetting(context),
                    ),
                    ListTile(
                      leading: Icon(Icons.data_object, color: Theme.of(context).colorScheme.secondary),
                      title: Text("导入用户数据".tl),
                      trailing: const Icon(Icons.arrow_right),
                      onTap: () => importDataSetting(context),
                    ),
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
                        title: Text("隐私".tl),
                      ),
                      if (GetPlatform.isAndroid)
                        ListTile(
                          leading: Icon(Icons.screenshot,
                              color: Theme.of(context).colorScheme.secondary),
                          title: Text("阻止屏幕截图".tl),
                          subtitle: Text("需要重启App以应用更改".tl),
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
                        title: Text("需要身份验证".tl),
                        subtitle: Text("如果系统中未设置任何认证方法请勿开启".tl),
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
                    ListTile(
                      title: Text("关于".tl),
                    ),
                    ListTile(
                      leading:
                          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                      title: const Text("PicaComic"),
                      subtitle: Text("本软件仅用于学习交流".tl),
                      onTap: () => showMessage(context, "禁止涩涩"),
                    ),
                    ListTile(
                      leading: Icon(Icons.code, color: Theme.of(context).colorScheme.secondary),
                      title: Text("项目地址".tl),
                      subtitle: const Text("https://github.com/wgh136/PicaComic"),
                      onTap: () => launchUrlString("https://github.com/wgh136/PicaComic",
                          mode: LaunchMode.externalApplication),
                    ),
                    ListTile(
                      leading: Icon(Icons.chat, color: Theme.of(context).colorScheme.secondary),
                      title: Text("提出建议".tl),
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
      return PopUpWidgetScaffold(title: "设置".tl, body: body);
    } else {
      return Scaffold(
        appBar: AppBar(title: Text("设置".tl)),
        body: body,
      );
    }
  }
}
