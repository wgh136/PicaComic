library pica_settings;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/cache_manager.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/main.dart';
import 'package:pica_comic/network/app_dio.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../comic_source/comic_source.dart';
import '../../foundation/app.dart';
import '../../foundation/local_favorites.dart';
import '../../network/download.dart';
import '../../network/eh_network/eh_main_network.dart';
import '../../network/http_client.dart';
import '../../network/http_proxy.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/update.dart';
import '../../network/webdav.dart';
import '../../tools/background_service.dart';
import '../../tools/debug.dart';
import '../app_views/logs_page.dart';
import '../explore_page.dart';
import '../welcome_page.dart';
import '../widgets/loading.dart';
import '../widgets/pop_up_widget.dart';
import '../widgets/pop_up_widget_scaffold.dart';
import '../widgets/select.dart';
import '../widgets/value_listenable_widget.dart';
import 'package:pica_comic/tools/translations.dart';

part "reading_settings.dart";
part "picacg_settings.dart";
part "network_setting.dart";
part "multi_pages_filter.dart";
part "local_favorite_settings.dart";
part "jm_settings.dart";
part "ht_settings.dart";
part "explore_settings.dart";
part "eh_settings.dart";
part "comic_source_settings.dart";
part "blocking_keyword_page.dart";
part "app_settings.dart";
part 'components.dart';

class NewSettingsPage extends StatefulWidget {
  static void open([int initialPage = -1]) {
    App.to(App.globalContext!, () => NewSettingsPage(initialPage: initialPage,));
  }

  const NewSettingsPage({this.initialPage = -1, super.key});

  final int initialPage;

  @override
  State<NewSettingsPage> createState() => _NewSettingsPageState();
}

class _NewSettingsPageState extends State<NewSettingsPage> implements PopEntry{
  int currentPage = -1;

  ColorScheme get colors => Theme.of(context).colorScheme;

  bool get enableTwoViews => !UiMode.m1(context);

  final categories = <String>["浏览", "漫画源", "阅读", "外观", "本地收藏", "APP", "网络", "关于"];

  final icons = <IconData>[
    Icons.explore,
    Icons.source,
    Icons.book,
    Icons.color_lens,
    Icons.collections_bookmark_rounded,
    Icons.apps,
    Icons.public,
    Icons.info
  ];

  double offset = 0;

  late final HorizontalDragGestureRecognizer gestureRecognizer;

  ModalRoute? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? nextRoute = ModalRoute.of(context);
    if (nextRoute != _route) {
      _route?.unregisterPopEntry(this);
      _route = nextRoute;
      _route?.registerPopEntry(this);
    }
  }

  @override
  void initState() {
    currentPage = widget.initialPage;
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
    _route?.unregisterPopEntry(this);
  }

  @override
  Widget build(BuildContext context) {
    if (currentPage != -1 && !enableTwoViews) {
      canPop.value = false;
      App.temporaryDisablePopGesture = true;
    } else {
      canPop.value = true;
      App.temporaryDisablePopGesture = false;
    }
    return Material(
      child: buildBody(),
    );
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
      color: enableTwoViews ? colors.surface : null,
      elevation: enableTwoViews ? 1 : 0,
      surfaceTintColor: colors.surfaceTint,
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

      Widget content = AnimatedContainer(
        key: ValueKey(id),
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 58,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        decoration: BoxDecoration(
            color: selected ? colors.primaryContainer : null,
            borderRadius: BorderRadius.circular(16)
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
      );

      return Padding(
        padding: enableTwoViews
            ? const EdgeInsets.fromLTRB(16, 0, 16, 0)
            : EdgeInsets.zero,
        child: InkWell(
          onTap: () => setState(() => currentPage = id),
          borderRadius: BorderRadius.circular(16),
          child: content,
        ).paddingVertical(4),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: categories.length,
      itemBuilder: (context, index) => buildItem(categories[index].tl, index),
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
        SwitchSetting(
          title: "启动时检查更新".tl,
          settingsIndex: 2,
          icon: const Icon(Icons.security_update),
        ),
        ListTile(
          title: Text("数据".tl),
        ),
        if (App.isDesktop || App.isAndroid)
          ListTile(
            leading: const Icon(Icons.folder),
            title: Text("设置下载目录".tl),
            trailing: const Icon(Icons.arrow_right),
            onTap: () => setDownloadFolder(),
          ),
        ListTile(
          leading: const Icon(Icons.storage),
          title: Text("缓存大小".tl),
          subtitle: Text(bytesLengthToReadableSize(CacheManager().currentSize)),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.delete),
          title: Text("清除缓存".tl),
          onTap: () {
            CacheManager().clear().then((value) {
              if(mounted) {
                setState(() {});
              }
            });
          },
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
        SwitchSetting(
          title: "需要身份验证".tl,
          subTitle: "如果系统中未设置任何认证方法请勿开启".tl,
          settingsIndex: 13,
          icon: const Icon(Icons.security),
        ),
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
        ListTile(
          title: Text("下载并行".tl),
          leading: const Icon(Icons.download),
          trailing: Select(
            initialValue: ["1", "2", "4", "6", "8", "16"].indexOf(appdata.settings[79]),
            values: const ["1", "2", "4", "6", "8", "16"],
            whenChange: (value) {
              appdata.settings[79] = ["1", "2", "4", "6", "8", "16"][value];
              appdata.updateSettings();
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
        if(kDebugMode)
          const ListTile(
            title: Text("Debug"),
            onTap: debug,
          ),
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
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
          onTap: () => launchUrlString("https://note.wgh136.xyz/m/KG96QMR9sgubST82TeLTA8",
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
        Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom))
      ],
    );
  }

  Widget buildRight() {
    final Widget body = switch (currentPage) {
      -1 => const SizedBox(),
      0 => buildExploreSettings(context, false),
      1 => const ComicSourceSettings(),
      2 => const ReadingSettings(false),
      3 => buildAppearanceSettings(),
      4 => const LocalFavoritesSettings(),
      5 => buildAppSettings(),
      6 => const NetworkSettings(),
      7 => buildAbout(),
      _ => throw UnimplementedError()
    };

    if (currentPage != -1) {
      return Material(
        child: CustomScrollView(
          primary: false,
          slivers: [
            SliverAppBar(
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

  var canPop = ValueNotifier(true);

  @override
  ValueListenable<bool> get canPopNotifier => canPop;

  @override
  PopInvokedCallback? get onPopInvoked => (canPop){
    if (currentPage != -1) {
      setState(() {
        currentPage = -1;
      });
    }
  };
}
