import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/app_page_route.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/background_service.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/category_page.dart';
import 'package:pica_comic/views/explore_page.dart';
import 'package:pica_comic/views/favorites/main_favorites_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/navigation_bar.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../foundation/app.dart';
import '../network/htmanga_network/htmanga_main_network.dart';
import '../network/update.dart';
import 'eh_views/eh_home_page.dart';
import 'pic_views/home_page.dart';
import 'me_page.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

void checkClipboard() async{
  if(appdata.settings[61] == "0"){
    return;
  }
  var data = await Clipboard.getData(Clipboard.kTextPlain);
  if(data?.text != null && canHandle(data!.text!)){
    await Future.delayed(const Duration(milliseconds: 200));
    showMessage(
        App.globalContext,
        "${"发现剪切板中的链接".tl}\n${data.text}",
        time: 5,
        action: TextButton(
          child: Text("打开".tl, style: TextStyle(
              color: App.colors(App.globalContext!).onInverseSurface),),
          onPressed: (){
            hideMessage(App.globalContext);
            handleAppLinks(Uri.parse(data.text!));
          },
        ));
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  static GlobalKey<NavigatorState>? _navigatorKey;

  static NaviObserver? _observer;

  static void to(Widget Function() widget, {bool preventDuplicate = false}) async {
    while (_navigatorKey == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if(preventDuplicate) {
      var page = widget();
      if("/${page.runtimeType}" == _observer?.routes.last.toString())  return;
    }
    App.to(_navigatorKey!.currentContext!, widget);
  }

  static canPop() =>
      Navigator.of(_navigatorKey?.currentContext ?? App.globalContext!).canPop();

  static void back() {
    if (canPop()) {
      _navigatorKey?.currentState?.pop();
    }
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final pages = [
    const MePage(key: Key("0"),),
    FavoritesPage(key: const Key("1"),),
    const ExplorePageWithGetControl(key: Key("2"),),
    const AllCategoryPage(key: Key("3"),),
  ];

  void login() {
    network.updateProfile().then((res) {
      if (res.error) {
        showMessage(
            App.globalContext!, "登录哔咔时发生错误:".tl + res.errorMessageWithoutNull);
      } else {
        //检查是否打卡
        if (appdata.user.isPunched == false && appdata.settings[6] == "1") {
          if (App.isMobile) {
            runBackgroundService();
          } else {
            appdata.user.isPunched = true;
            network.punchIn().then((b) {
              if (b) {
                showMessage(App.globalContext, "打卡成功".tl, useGet: false);
                appdata.user.exp += 10;
              }
            });
          }
        }
      }
    });
    HtmangaNetwork().loginFromAppdata().then((res) {
      if (res.error) {
        showMessage(App.globalContext!,
            "登录绅士漫画时发生错误:".tl + res.errorMessageWithoutNull);
      }
    });
  }

  void checkUpdates() {
    if (appdata.settings[2] == "1") {
      checkUpdate().then((b) {
        if (b != null) {
          if (b) {
            getUpdatesInfo().then((s) {
              if (s != null) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("有可用更新".tl),
                        content: Text(s),
                        actions: [
                          TextButton(
                              onPressed: () {
                                App.globalBack();
                                appdata.settings[2] = "0";
                                appdata.writeData();
                              },
                              child: const Text("关闭更新检查")),
                          TextButton(
                              onPressed: () => App.globalBack(),
                              child: Text("取消".tl)),
                          TextButton(
                              onPressed: () {
                                getDownloadUrl().then((s) {
                                  launchUrlString(s,
                                      mode: LaunchMode.externalApplication);
                                });
                              },
                              child: Text("下载".tl))
                        ],
                      );
                    });
              }
            });
          }
        }
      });
    }

    if (appdata.settings[80] == "1") {
      ComicSourceSettings.checkCustomComicSourceUpdate();
    }
  }

  void checkDownload() {
    if (downloadManager.downloading.isNotEmpty) {
      Future.delayed(const Duration(microseconds: 500), () {
        showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text("下载管理器".tl),
                content: Text("有未完成的下载, 是否继续?".tl),
                actions: [
                  TextButton(
                      onPressed: () => App.globalBack(), child: Text("否".tl)),
                  TextButton(
                      onPressed: () {
                        downloadManager.start();
                        App.globalBack();
                      },
                      child: Text("是".tl))
                ],
              );
            });
      });
    }
  }

  void initLogic() {
    StateController.put(HomePageLogic());
    StateController.put(EhHomePageLogic());
    StateController.put(EhPopularPageLogic());
    StateController.put(JmHomePageLogic());
    StateController.put(ExplorePageLogic());
    StateController.put(SimpleController(), tag: "category");
    StateController.put(HtHomePageLogic());
  }

  @override
  void initState() {
    initLogic();

    login();

    notifications.requestPermission();

    if (appdata.ehAccount != "") {
      EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php",
          favoritePage: true);
    }

    if (appdata.firstUse[3] == "0") {
      appdata.firstUse[3] = "1";
      appdata.writeData();
    }
    //清除未正常退出时的下载通知
    notifications.cancelAll();

    checkUpdates();

    checkDownload();

    Future.delayed(const Duration(milliseconds: 300),
            () => Webdav.syncData()).then((v) => checkClipboard());
    MainPage._observer = observer;
    super.initState();
  }

  var observer = NaviObserver();

  @override
  Widget build(BuildContext context) {
    return NaviPane(
      initialPage: int.parse(appdata.settings[23]),
      observer: observer,
      paneItems: [
        PaneItemEntry(
          label: '我'.tl,
          icon: Icons.person_outline,
          activeIcon: Icons.person
        ),
        PaneItemEntry(
            label: '收藏'.tl,
            icon: Icons.local_activity_outlined,
            activeIcon: Icons.local_activity
        ),
        PaneItemEntry(
            label: '探索'.tl,
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore
        ),
        PaneItemEntry(
            label: '分类'.tl,
            icon: Icons.account_tree_outlined,
            activeIcon: Icons.account_tree
        ),
      ],
      paneActions: [
        PaneActionEntry(
          icon: Icons.search,
          label: "搜索".tl,
          onTap: () => MainPage.to(() => PreSearchPage(), preventDuplicate: true)
        ),
        PaneActionEntry(
            icon: Icons.settings,
            label: "设置".tl,
            onTap: () => NewSettingsPage.open()
        ),
      ],
      pageBuilder: (index) {
        return MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Navigator(
            observers: [
              observer
            ],
            key: MainPage._navigatorKey ??= GlobalKey(),
            onGenerateRoute: (settings) =>
                AppPageRoute(
                  preventRebuild: false,
                  isRootRoute: true,
                  builder: (context) {
                    return pages[index];
                }),
          ),
        );
      },
      onPageChange: (index) {
        MainPage._navigatorKey!.currentState?.pushAndRemoveUntil(
            AppPageRoute(
              preventRebuild: false,
              isRootRoute: true,
              builder: (context) {
                return pages[index];
            }),
            (route) => false
        );
      },
    );
  }
}
