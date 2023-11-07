import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/main.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/settings/reading_settings.dart';
import 'package:pica_comic/views/settings/explore_settings.dart';
import 'package:pica_comic/views/settings/ht_settings.dart';
import 'package:pica_comic/views/settings/picacg_settings.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../foundation/app.dart';
import '../app_views/logs_page.dart';
import '../widgets/select.dart';
import 'eh_settings.dart';
import 'jm_settings.dart';
import 'app_settings.dart';
import 'package:pica_comic/tools/translations.dart';

class NewSettingsPage extends StatefulWidget {
  static void open() {
    App.to(App.globalContext!, () => const NewSettingsPage());
  }

  const NewSettingsPage({super.key});

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage> {
  int currentPage = -1;

  ColorScheme get colors => Theme.of(context).colorScheme;

  bool get enableTwoViews => !UiMode.m1(context);

  final categories = <String>["浏览", "漫画源", "阅读", "外观", "APP", "关于"];

  final icons = <IconData>[
    Icons.explore,
    Icons.source,
    Icons.book,
    Icons.color_lens,
    Icons.apps,
    Icons.info
  ];

  double offset = 0;

  late final HorizontalDragGestureRecognizer gestureRecognizer;

  @override
  void initState() {
    gestureRecognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onUpdate = ((details) => setState(() => offset += details.delta.dx))
      ..onEnd = (details) async {
        if (details.velocity.pixelsPerSecond.dx.abs() > 1 &&
            details.velocity.pixelsPerSecond.dx >= 0) {
          setState(() {
            Future.delayed(const Duration(milliseconds: 300), () => offset = 0);
            currentPage = -1;
          });
        } else if (offset > MediaQuery.of(context).size.width / 2) {
          setState(() {
            Future.delayed(const Duration(milliseconds: 300), () => offset = 0);
            currentPage = -1;
          });
        } else {
          int i = 10;
          while (offset != 0) {
            setState(() {
              offset -= i;
              i *= 10;
              if (offset < 0) {
                offset = 0;
              }
            });
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }
      ..onCancel = () async {
        int i = 10;
        while (offset != 0) {
          setState(() {
            offset -= i;
            i *= 10;
            if (offset < 0) {
              offset = 0;
            }
          });
          await Future.delayed(const Duration(milliseconds: 10));
        }
      };
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
    gestureRecognizer.dispose();
    App.temporaryDisablePopGesture = false;
  }

  @override
  Widget build(BuildContext context) {
    if (currentPage != -1 && !enableTwoViews) {
      App.temporaryDisablePopGesture = true;
    } else {
      App.temporaryDisablePopGesture = false;
    }
    return WillPopScope(
        onWillPop: App.enablePopGesture
            ? null
            : () async {
                if (currentPage != -1) {
                  setState(() {
                    currentPage = -1;
                  });
                  return false;
                }
                return true;
              },
        child: Material(
          child: buildBody(),
        ));
  }

  Widget buildBody() {
    if (enableTwoViews) {
      return Row(
        children: [
          SizedBox(
            width: 350,
            height: double.infinity,
            child: buildLeft(),
          ),
          Expanded(child: buildRight())
        ],
      );
    } else {
      return Stack(
        children: [
          Positioned.fill(child: buildLeft()),
          Positioned(
            left: offset,
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Listener(
              onPointerDown: handlePointerDown,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                reverseDuration: const Duration(milliseconds: 300),
                switchInCurve: Curves.fastOutSlowIn,
                switchOutCurve: Curves.fastOutSlowIn,
                transitionBuilder: (child, animation) {
                  var tween = Tween<Offset>(
                      begin: const Offset(1, 0), end: const Offset(0, 0));

                  return SlideTransition(
                    position: tween.animate(animation),
                    child: child,
                  );
                },
                child: currentPage == -1
                    ? const SizedBox(
                        key: Key("1"),
                      )
                    : buildRight(),
              ),
            ),
          )
        ],
      );
    }
  }

  void handlePointerDown(PointerDownEvent event) {
    if (event.position.dx < 20) {
      gestureRecognizer.addPointer(event);
    }
  }

  Widget buildLeft() {
    return Material(
      color: enableTwoViews ? colors.tertiaryContainer.withAlpha(50) : null,
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          SizedBox(
            height: 56,
            child: Row(children: [
              const SizedBox(
                width: 8,
              ),
              Tooltip(
                message: "Back",
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => App.globalBack(),
                ),
              ),
              const SizedBox(
                width: 24,
              ),
              Text(
                "设置".tl,
                style: Theme.of(context).textTheme.headlineSmall,
              )
            ]),
          ),
          const SizedBox(
            height: 4,
          ),
          Expanded(
            child: buildCategories(),
          )
        ],
      ),
    );
  }

  Widget buildCategories() {
    Widget buildItem(String name, int id) {
      final bool selected = id == currentPage;
      return Padding(
        padding: enableTwoViews
            ? const EdgeInsets.fromLTRB(16, 0, 16, 0)
            : EdgeInsets.zero,
        child: InkWell(
          onTap: () => setState(() => currentPage = id),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 64,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: BoxDecoration(
              color: selected ? colors.tertiaryContainer.withAlpha(150) : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Icon(icons[id]),
              const SizedBox(
                width: 16,
              ),
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (selected) const Icon(Icons.arrow_right)
            ]),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      itemBuilder: (context, index) => buildItem(categories[index].tl, index),
    );
  }

  Widget buildComicSourceSettings() {
    return const Column(
      children: [
        PicacgSettings(false),
        Divider(),
        EhSettings(false),
        Divider(),
        JmSettings(false),
        Divider(),
        HtSettings(false),
        Divider(),
        // Encountering some issues, temporarily disable this option.
        //buildNhentaiSettings(),
        //const Divider(),
      ],
    );
  }

  Widget buildReadingSettings() {
    return const Placeholder();
  }

  Widget buildAppearanceSettings() => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text("主题选择".tl),
            trailing: Select(
              initialValue: int.parse(appdata.settings[27]),
              values: const [
                "Dynamic",
                "Blue",
                "Light Blue",
                "Indigo",
                "Purple",
                "Pink",
                "Cyan",
                "Teal",
                "Yellow",
                "Brown"
              ],
              whenChange: (i) {
                appdata.settings[27] = i.toString();
                appdata.updateSettings();
                MyApp.updater?.call();
              },
              width: 140,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: Text("深色模式".tl),
            trailing: Select(
              initialValue: int.parse(appdata.settings[32]),
              values: ["跟随系统".tl, "禁用".tl, "启用".tl],
              whenChange: (i) {
                appdata.settings[32] = i.toString();
                appdata.updateSettings();
                MyApp.updater?.call();
              },
              width: 140,
            ),
          ),
          if (App.isAndroid)
            ListTile(
              leading: const Icon(Icons.smart_screen_outlined),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("高刷新率模式".tl),
                  const SizedBox(
                    width: 2,
                  ),
                  InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                    onTap: () => showDialogMessage(
                        context,
                        "高刷新率模式".tl,
                        "启用后, APP将尝试设置高刷新率\n"
                        "如果OS没有限制APP的刷新率, 无需启用此项\n"
                        "OS可能不会响应更改"),
                    child: const Icon(
                      Icons.info_outline,
                      size: 18,
                    ),
                  )
                ],
              ),
              trailing: Switch(
                value: appdata.settings[38] == "1",
                onChanged: (b) {
                  setState(() {
                    appdata.settings[38] = b ? "1" : "0";
                  });
                  appdata.updateSettings();
                  if (b) {
                    try {
                      FlutterDisplayMode.setHighRefreshRate();
                    } catch (e) {
                      // ignore
                    }
                  } else {
                    try {
                      FlutterDisplayMode.setLowRefreshRate();
                    } catch (e) {
                      // ignore
                    }
                  }
                },
              ),
            )
        ],
      );

  Widget buildAppSettings() {
    return Column(
      children: [
        ListTile(
          title: Text("日志".tl),
        ),
        ListTile(
          leading: const Icon(Icons.bug_report),
          title: const Text("Logs"),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => App.globalTo(() => const LogsPage()),
        ),
        ListTile(
          title: Text("更新".tl),
        ),
        ListTile(
          leading: const Icon(Icons.update),
          title: Text("检查更新".tl),
          subtitle: Text("${"当前:".tl} $appVersion"),
          onTap: () {
            findUpdate(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.security_update),
          title: Text("启动时检查更新".tl),
          trailing: Switch(
            value: appdata.settings[2] == "1",
            onChanged: (b) {
              b ? appdata.settings[2] = "1" : appdata.settings[2] = "0";
              setState(() {});
              appdata.writeData();
            },
          ),
          onTap: () {},
        ),
        ListTile(
          title: Text("数据".tl),
        ),
        if (App.isWindows || App.isAndroid)
          ListTile(
            leading: const Icon(Icons.folder),
            title: Text("设置下载目录".tl),
            trailing: const Icon(Icons.arrow_right),
            onTap: () => setDownloadFolder(),
          ),
        StateBuilder<CalculateCacheLogic>(
            init: CalculateCacheLogic(),
            builder: (logic) {
              if (logic.calculating) {
                logic.get();
                return ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text("缓存大小".tl),
                  subtitle: Text("计算中".tl),
                  onTap: () {},
                );
              } else {
                return ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text("清除缓存".tl),
                  subtitle: Text(
                      "${logic.size == double.infinity ? "未知" : logic.size.toStringAsFixed(2)} MB"),
                  onTap: () {
                    if (App.isAndroid || App.isIOS || App.isWindows) {
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
          leading: const Icon(Icons.chrome_reader_mode),
          title: Text("阅读器缓存限制".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => setCacheLimit(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: Text("清除所有数据".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => clearUserData(context),
        ),
        ListTile(
          leading: const Icon(Icons.sim_card_download),
          title: Text("导出用户数据".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => exportDataSetting(context),
        ),
        ListTile(
          leading: const Icon(Icons.data_object),
          title: Text("导入用户数据".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => importDataSetting(context),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text("数据同步".tl),
          trailing: const Icon(Icons.arrow_right),
          onTap: () => syncDataSettings(context),
        ),
        ListTile(
          title: Text("隐私".tl),
        ),
        if (App.isAndroid)
          ListTile(
            leading: const Icon(Icons.screenshot),
            title: Text("阻止屏幕截图".tl),
            subtitle: Text("需要重启App以应用更改".tl),
            trailing: Switch(
              value: appdata.settings[12] == "1",
              onChanged: (b) {
                b ? appdata.settings[12] = "1" : appdata.settings[12] = "0";
                setState(() {});
                appdata.writeData();
              },
            ),
          ),
        ListTile(
            leading: const Icon(Icons.security),
            title: Text("需要身份验证".tl),
            subtitle: Text("如果系统中未设置任何认证方法请勿开启".tl),
            trailing: Switch(
              value: appdata.settings[13] == "1",
              onChanged: (b) {
                b ? appdata.settings[13] = "1" : appdata.settings[13] = "0";
                setState(() {});
                appdata.writeData();
              },
            )),
        ListTile(
          title: Text("其它".tl),
        ),
        ListTile(
          title: Text("语言".tl),
          leading: const Icon(Icons.language),
          trailing: Select(
            initialValue: ["", "cn", "tw", "en"].indexOf(appdata.settings[50]),
            values: const ["System", "中文(简体)", "中文(繁體)", "English"],
            whenChange: (value) {
              appdata.settings[50] = ["", "cn", "tw", "en"][value];
              appdata.updateSettings();
              MyApp.updater?.call();
            },
          ),
        ),
        if(App.isAndroid)
          ListTile(
            title: Text("应用链接".tl),
            subtitle: Text("在系统设置中管理APP支持的链接".tl),
            leading: const Icon(Icons.link),
            trailing: const Icon(Icons.arrow_right),
            onTap: (){
              const MethodChannel("pica_comic/settings").invokeMethod("link");
            },
          ),
      ],
    );
  }

  Widget buildAbout() {
    return Column(
      children: [
        const SizedBox(
          height: 130,
          width: double.infinity,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: CircleAvatar(
                backgroundImage: AssetImage("images/app_icon.png"),
              ),
            ),
          ),
        ),
        const Text(
          "V$appVersion",
          style: TextStyle(fontSize: 16),
        ),
        Text("Pica Comic是一个完全免费的漫画阅读APP".tl),
        Text("仅用于学习交流".tl),
        const SizedBox(
          height: 16,
        ),
        ListTile(
          leading: const Icon(Icons.code),
          title: Text("项目地址".tl),
          onTap: () => launchUrlString("https://github.com/wgh136/PicaComic",
              mode: LaunchMode.externalApplication),
          trailing: const Icon(Icons.arrow_right),
        ),
        ListTile(
          leading: const Icon(Icons.comment_outlined),
          title: Text("提出建议(Github)".tl),
          onTap: () => launchUrlString(
              "https://github.com/wgh136/PicaComic/issues",
              mode: LaunchMode.externalApplication),
          trailing: const Icon(Icons.arrow_right),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: Text("通过电子邮件联系我".tl),
          onTap: () => launchUrlString("mailto://nyne19710@proton.me",
              mode: LaunchMode.externalApplication),
          trailing: const Icon(Icons.arrow_right),
        ),
        ListTile(
          leading: const Icon(Icons.support_outlined),
          title: Text("支持开发".tl),
          onTap: () => launchUrlString("https://wgh136.github.io/posts/1",
              mode: LaunchMode.externalApplication),
          trailing: const Icon(Icons.arrow_right),
        ),
                ListTile(
          leading: const Icon(Icons.telegram),
          title: Text("加入Telegram群".tl),
          onTap: () => launchUrlString("https://t.me/pica_group",
              mode: LaunchMode.externalApplication),
          trailing: const Icon(Icons.arrow_right),
        ),
      ],
    );
  }

  Widget buildRight() {
    final Widget body = switch (currentPage) {
      -1 => const SizedBox(),
      0 => buildExploreSettings(context, false),
      1 => buildComicSourceSettings(),
      2 => const ReadingSettings(false),
      3 => buildAppearanceSettings(),
      4 => buildAppSettings(),
      5 => buildAbout(),
      _ => throw UnimplementedError()
    };

    if (currentPage != -1) {
      return Material(
        child: CustomScrollView(
          primary: false,
          slivers: [
            SliverAppBar.medium(
                title: Text(categories[currentPage].tl),
                automaticallyImplyLeading: false,
                scrolledUnderElevation: enableTwoViews ? 0 : null,
                leading: enableTwoViews
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => setState(() => currentPage = -1),
                      )),
            SliverToBoxAdapter(
              child: body,
            )
          ],
        ),
      );
    }

    return body;
  }
}
