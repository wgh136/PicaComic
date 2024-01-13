import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/network/webdav.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/background_service.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/category_page.dart';
import 'package:pica_comic/views/explore_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/favorites/favorites_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/custom_navigation_bar.dart';
import 'package:pica_comic/views/widgets/will_pop_scope.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../foundation/app.dart';
import '../network/htmanga_network/htmanga_main_network.dart';
import '../network/update.dart';
import '../foundation/ui_mode.dart';
import 'eh_views/eh_home_page.dart';
import 'pic_views/home_page.dart';
import 'me_page.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

typedef MePage = NewMePage;

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @protected
  static GlobalKey<NavigatorState>? navigatorKey;

  static void to(Widget Function() widget) async {
    while (navigatorKey == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    App.to(navigatorKey!.currentContext!, widget);
  }

  static canPop() =>
      Navigator.of(navigatorKey?.currentContext ?? App.globalContext!).canPop();

  static void back() {
    if (canPop()) {
      navigatorKey?.currentState?.pop();
    }
  }

  static void Function()? toExplorePage;

  static void toExplorePageAt(int page) async {
    toExplorePage?.call();
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _i = int.parse(appdata.settings[23]);

  int get i => _i;

  set i(int value) {
    _i = value;
    Navigator.popUntil(
        MainPage.navigatorKey!.currentContext!, (route) => route.isFirst);
  }

  final pages = [
    const MePage(),
    const LocalFavoritesPage(),
    const ExplorePageWithGetControl(),
    const AllCategoryPage(),
  ];

  void login() {
    network.updateProfile().then((res) {
      if (res.error) {
        showMessage(
            App.globalContext!, "登录哔咔时发生错误:".tl + res.errorMessageWithoutNull);
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
    StateController.put(GamesPageLogic());
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

    checkUpdates();

    checkDownload();

    MainPage.toExplorePage = () => setState(() => i = 2);

    Future.delayed(const Duration(milliseconds: 300),
            () => Webdav.syncData()).then(checkClipboard);

    super.initState();
  }

  void checkClipboard(v) async{
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

  @override
  Widget build(BuildContext context) {
    var titles = ["我".tl, "收藏夹".tl, "探索".tl, "分类".tl];

    return Material(
      child: CustomWillPopScope(
        action: () {
          if (MainPage.canPop()) {
            MainPage.back();
          } else {
            SystemNavigator.pop();
          }
        },
        popGesture: App.isIOS && !UiMode.m1(context),
        child: Row(
          children: [
            NavigateBar(
                index: () => i,
                indexSetter: (index) => setState(() {
                      i = index;
                    })),
            Expanded(
              child: Column(
                children: [
                  if (!UiMode.m1(context))
                    SizedBox(
                      height: MediaQuery.of(context).padding.top,
                    ),
                  Expanded(
                    child: ClipRect(
                      child: Navigator(
                        key: (MainPage.navigatorKey ??
                            (MainPage.navigatorKey = GlobalKey())),
                        onGenerateRoute: (settings) =>
                            MaterialPageRoute(builder: (context) {
                          return Column(
                            children: [
                              if (UiMode.m1(context))
                                AppBar(
                                  title: Text(titles[i]),
                                  notificationPredicate: (notifications) =>
                                      notifications.context?.widget is MePage,
                                  actions: [
                                    Tooltip(
                                      message: "搜索".tl,
                                      child: IconButton(
                                          icon: const Icon(Icons.search),
                                          onPressed: () => MainPage.to(
                                              () => PreSearchPage())),
                                    ),
                                    Tooltip(
                                      message: "设置".tl,
                                      child: IconButton(
                                        icon: const Icon(Icons.settings),
                                        onPressed: () => NewSettingsPage.open(),
                                      ),
                                    ),
                                  ],
                                ),
                              Expanded(
                                child: AnimatedMainPage(
                                  pages[i],
                                  key: Key(i.toString()),
                                ),
                              ),
                              if (UiMode.m1(context))
                                CustomNavigationBar(
                                  onDestinationSelected: (int index) {
                                    setState(() {
                                      i = index;
                                    });
                                  },
                                  selectedIndex: i,
                                  destinations: <NavigationItemData>[
                                    NavigationItemData(
                                      icon: const Icon(Icons.person_outlined),
                                      selectedIcon: const Icon(Icons.person),
                                      label: '我'.tl,
                                    ),
                                    NavigationItemData(
                                      icon: const Icon(Icons.local_activity_outlined),
                                      selectedIcon: const Icon(Icons.local_activity),
                                      label: '收藏'.tl,
                                    ),
                                    NavigationItemData(
                                      icon: const Icon(Icons.explore_outlined),
                                      selectedIcon: const Icon(Icons.explore),
                                      label: '探索'.tl,
                                    ),
                                    NavigationItemData(
                                      icon: const Icon(
                                          Icons.account_tree_outlined),
                                      selectedIcon:
                                          const Icon(Icons.account_tree),
                                      label: '分类'.tl,
                                    ),
                                  ],
                                )
                            ],
                          );
                        }),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavigatorItem extends StatelessWidget {
  const NavigatorItem(
      this.icon, this.selectedIcon, this.title, this.selected, this.onTap,
      {Key? key})
      : super(key: key);
  final IconData icon;
  final IconData selectedIcon;
  final String title;
  final void Function() onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    double? size;
    final theme = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                color: selected ? theme.secondaryContainer : null),
            height: 56,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                ),
                Icon(
                  selected ? selectedIcon : icon,
                  color: theme.onSurfaceVariant,
                  size: size,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(title)
              ],
            ),
          ),
        ));
  }
}

class AnimatedMainPage extends StatefulWidget {
  const AnimatedMainPage(this.widget, {super.key});

  final Widget widget;

  @override
  State<AnimatedMainPage> createState() => _AnimatedMainPageState();
}

class _AnimatedMainPageState extends State<AnimatedMainPage> {
  var offset = const Offset(0, 0.05);

  static bool initial = true;

  @override
  void initState() {
    if (!initial) {
      Future.microtask(() => setState(() {
            offset = const Offset(0, 0);
          }));
    } else {
      offset = const Offset(0, 0);
    }
    initial = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: offset,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 300),
      child: widget.widget,
    );
  }
}

class NavigateBar extends StatefulWidget {
  const NavigateBar(
      {required this.index, required this.indexSetter, super.key});

  final void Function(int) indexSetter;

  final int Function() index;

  @override
  State<NavigateBar> createState() => _NavigateBarState();
}

class _NavigateBarState extends State<NavigateBar> {
  set i(int i) {
    widget.indexSetter(i);
  }

  int get i => widget.index();

  @override
  Widget build(BuildContext context) {
    if (UiMode.m3(context)) {
      return SafeArea(
          child: Container(
        width: 340,
        height: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.fromLTRB(28, 0, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                          backgroundImage: AssetImage("images/app_icon.png")),
                      SizedBox(
                        width: 16,
                      ),
                      Text(
                        "Pica Comic",
                        style: TextStyle(fontFamily: "font2", fontSize: 18),
                      )
                    ],
                  ),
                ),
              ),
            ),
            NavigatorItem(Icons.person_outlined, Icons.person, "我".tl, i == 0,
                () => setState(() => i = 0)),
            NavigatorItem(Icons.local_activity_outlined, Icons.local_activity, "收藏".tl, i == 1,
                    () => setState(() => i = 1)),
            NavigatorItem(Icons.explore_outlined, Icons.explore, "探索".tl,
                i == 2, () => setState(() => i = 2)),
            NavigatorItem(Icons.account_tree_outlined, Icons.account_tree,
                "分类".tl, i == 3, () => setState(() => i = 3)),
            const Divider(),
            const Spacer(),
            NavigatorItem(Icons.search, Icons.search, "搜索".tl, false,
                () => MainPage.to(() => PreSearchPage())),
            NavigatorItem(
              Icons.settings,
              Icons.settings,
              "设置".tl,
              false,
              () => NewSettingsPage.open(),
            ),
          ],
        ),
      ));
    } else if (UiMode.m2(context)) {
      return NavigationRail(
        leading: const Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: CircleAvatar(
            backgroundImage: AssetImage("images/app_icon.png"),
          ),
        ),
        selectedIndex: i,
        trailing: Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => MainPage.to(() => PreSearchPage()),
                  ),
                ),
                Flexible(
                  child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => NewSettingsPage.open(),
                  ),
                ),
              ],
            ),
          ),
        ),
        groupAlignment: -1,
        onDestinationSelected: (int index) {
          setState(() {
            i = index;
          });
        },
        labelType: NavigationRailLabelType.all,
        destinations: <NavigationRailDestination>[
          NavigationRailDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person),
            label: Text('我'.tl),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.local_activity_outlined),
            selectedIcon: const Icon(Icons.local_activity),
            label: Text('收藏'.tl),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: Text('探索'.tl),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.account_tree_outlined),
            selectedIcon: const Icon(Icons.account_tree),
            label: Text('分类'.tl),
          ),
        ],
      );
    }
    return const SizedBox();
  }
}
