import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/network/eh_network/eh_main_network.dart';
import 'package:pica_comic/views/category_page.dart';
import 'package:pica_comic/views/explore_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/ht_views/home_page.dart';
import 'package:pica_comic/views/jm_views/jm_categories_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/leaderboard_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../network/hitomi_network/hitomi_main_network.dart';
import '../network/update.dart';
import '../foundation/ui_mode.dart';
import 'eh_views/eh_home_page.dart';
import 'models/tab_listener.dart';
import 'pic_views/home_page.dart';
import 'me_page.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/views/widgets/show_message.dart';

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var updateFlag = true;
  var downloadManagerFlag = true;

  int i = int.parse(appdata.settings[23]);//页面
  TabListener exploreListener = TabListener();
  TabListener categoriesListener = TabListener();

  late var pages = [
    const MePage(),
    ExplorePageWithGetControl(exploreListener),
    CategoryPageWithGetControl(categoriesListener),
    const LeaderBoardPage(),
  ];

  @override
  void initState() {
    EhNetwork().getGalleries("${EhNetwork().ehBaseUrl}/favorites.php", favoritePage: true);
    Get.put(HomePageLogic());
    Get.put(CategoriesPageLogic());
    Get.put(GamesPageLogic());
    Get.put(EhHomePageLogic());
    Get.put(EhPopularPageLogic());
    Get.put(JmHomePageLogic());
    Get.put(JmLatestPageLogic());
    Get.put(JmCategoriesPageLogic());
    Get.put(HitomiHomePageLogic(), tag: HitomiDataUrls.homePageAll);
    Get.put(HitomiHomePageLogic(), tag: HitomiDataUrls.homePageCn);
    Get.put(HitomiHomePageLogic(), tag: HitomiDataUrls.homePageJp);
    Get.put(ExplorePageLogic());
    Get.put(CategoryPageLogic());
    Get.put(HtHomePageLogic());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(appdata.firstUse[3] == "0") {
      appdata.firstUse[3] = "1";
      appdata.writeFirstUse();
    }

    //清除未正常退出时的下载通知
    try {
      notifications.endProgress();
    }
    catch(e){
      //不清楚清除一个不存在的通知会不会引发错误
    }

    //检查是否打卡
    if(appdata.user.isPunched==false&&appdata.settings[6]=="1"){
      appdata.user.isPunched = true;
      network.punchIn().then((b){
        if(b){
          showMessage(Get.context, "打卡成功", useGet: false);
          appdata.user.exp+=10;
        }
      });
    }

    //获取热搜
    if(hotSearch.isEmpty || jmNetwork.hotTags.isEmpty) {
      if(jmNetwork.hotTags.isEmpty) {
        jmNetwork.getHotTags();
      }
      if(hotSearch.isEmpty) {
        network.getKeyWords().then((s) {
          if (s != null) {
            hotSearch = s.keyWords;
            try {
              Get.find<PreSearchController>().update();
            }
            catch (e) {
              //处于搜索页面时更新页面, 否则忽视
            }
          }
        });
      }
    }

    //检查更新
    if(appdata.settings[2]=="1"&&updateFlag&&!GetPlatform.isWeb) {
      checkUpdate().then((b){
      if(b!=null){
        if(b){
          getUpdatesInfo().then((s){
            if(s!=null){
              showDialog(context: context, builder: (context){
                return AlertDialog(
                  title: Text("有可用更新".tr),
                  content: Text(s),
                  actions: [
                    TextButton(onPressed: (){Get.back();appdata.settings[2]="0";appdata.writeData();}, child: const Text("关闭更新检查")),
                    TextButton(onPressed: ()=>Get.back(), child: Text("取消".tr)),
                    if(!GetPlatform.isWeb)
                    TextButton(
                        onPressed: (){
                          getDownloadUrl().then((s){
                            launchUrlString(s,mode: LaunchMode.externalApplication);
                          });
                        },
                        child: Text("下载".tr))
                  ],
                );
              });
            }
          });
        }
      }
    });
    }
    updateFlag = false;

    //检查是否有未完成的下载
    if(downloadManager.downloading.isNotEmpty&&downloadManagerFlag){
      Future.delayed(const Duration(microseconds: 500),(){
        showDialog(context: context, builder: (dialogContext){
          return AlertDialog(
            title: Text("下载管理器".tr),
            content: Text("有未完成的下载, 是否继续?".tr),
            actions: [
              TextButton(onPressed: ()=>Get.back(), child: Text("否".tr)),
              TextButton(onPressed: (){
                downloadManager.start();
                Get.back();
              }, child: Text("是".tr))
            ],
          );
        });
      });
    }
    downloadManagerFlag = false;

    var titles = [
      "我".tr,
      "探索".tr,
      "分类".tr,
      "排行榜".tr
    ];

    return Scaffold(
      appBar: UiMode.m1(context)?AppBar(
        title: Text(titles[i]),
        actions: [
          Tooltip(
            message: "搜索".tr,
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: (){
                Get.to(()=>PreSearchPage());
              },
            ),
          ),
          Tooltip(
            message: "设置".tr,
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: (){
                Get.to(()=>const SettingsPage());
              },
            ),
          ),
        ],
      ):null,
      floatingActionButton: (i!=0 && i!=3)?FloatingActionButton(
        onPressed: () {
          if(i==1){
            int page = exploreListener.getIndex();
            var logics = [
              () => Get.find<HomePageLogic>().refresh_(),
              if(appdata.settings[24][1] == "1")
              () => Get.find<GamesPageLogic>().refresh_(),
              if(appdata.settings[24][2] == "1")
                () => Get.find<EhHomePageLogic>().refresh_(),
              if(appdata.settings[24][3] == "1")
                () => Get.find<EhPopularPageLogic>().refresh_(),
              if(appdata.settings[24][4] == "1")
                () => Get.find<JmHomePageLogic>().refresh_(),
              if(appdata.settings[24][5] == "1")
                () => Get.find<JmLatestPageLogic>().refresh_(),
              if(appdata.settings[24][6] == "1")
                () => Get.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageAll).refresh_(),
              if(appdata.settings[24][7] == "1")
                () => Get.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageCn).refresh_(),
              if(appdata.settings[24][8] == "1")
                () => Get.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageJp).refresh_(),
              if(appdata.settings[24][9] == "1")
                () => Get.find<HtHomePageLogic>().refresh_(),
            ];
            logics[page]();
          } else if (i == 2) {
            int page = categoriesListener.getIndex();
            var logics = [
              () => Get.find<CategoriesPageLogic>().refresh_(),
              if(appdata.settings[21][2] == "1")
                () => Get.find<JmCategoriesPageLogic>().refresh_(),
              if(appdata.settings[21][2] == "1")
                (){}
            ];
            logics[page]();
          }
        },
        child: const Icon(Icons.refresh),
      ):null,
      bottomNavigationBar: (!UiMode.m1(context))?null:NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            i = index;
          });
        },
        selectedIndex: i,
        destinations: <Widget>[
          NavigationDestination(
            icon: const Icon(Icons.person),
            label: '我'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore),
            label: '探索'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_tree, size: 20,),
            label: '分类'.tr,
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard, size: 20,),
            label: '排行榜'.tr,
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: ()async{
          bool exit = false;
          if(downloadManager.downloading.isNotEmpty){
            await showDialog(context: context, builder: (dialogContext){
              return AlertDialog(
                title: Text("下载未完成".tr),
                content: Text("有未完成的下载, 确定退出?".tr),
                actions: [
                  TextButton(onPressed: ()=>Get.back(), child: const Text("否")),
                  TextButton(onPressed: (){
                    exit = true;
                    downloadManager.pause();
                    Get.back();
                  }, child: Text("是".tr)),
                ],
              );
            });
          }else{
            exit = true;
          }
          return exit;
        },
        child: Column(
          children: [
            if(!UiMode.m1(context))
            SizedBox(
              height: Get.statusBarHeight / context.mediaQuery.devicePixelRatio,
            ),
            Expanded(child: Row(
              children: [
                if(UiMode.m3(context))
                  SafeArea(child: Container(
                    width: 340,
                    height: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("      Pica Comic"),
                        const SizedBox(height: 10,),
                        NavigatorItem(Icons.person_outlined,Icons.person, "我".tr,i==0,()=>setState(()=>i=0)),
                        NavigatorItem(Icons.explore_outlined,Icons.explore, "探索".tr,i==1,()=>setState(()=>i=1)),
                        NavigatorItem(Icons.account_tree_outlined,Icons.account_tree, "分类".tr,i==2,()=>setState(()=>i=2)),
                        NavigatorItem(Icons.leaderboard_outlined,Icons.leaderboard, "排行榜".tr,i==3,()=>setState(()=>i=3)),
                        const Divider(),
                        const Spacer(),
                        NavigatorItem(Icons.search,Icons.games, "搜索".tr,false,()=>Get.to(()=>PreSearchPage())),
                        NavigatorItem(Icons.settings,Icons.games, "设置".tr,false,()=>showAdaptiveWidget(context, SettingsPage(popUp: MediaQuery.of(context).size.width>600,)),),
                      ],
                    ),
                  ))
                else if(UiMode.m2(context))
                  NavigationRail(
                    leading: const Padding(padding: EdgeInsets.only(bottom: 20),child: CircleAvatar(backgroundImage: AssetImage("images/app_icon.png"),),),
                    selectedIndex: i,
                    trailing: Expanded(child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(child: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: ()=>Get.to(()=>PreSearchPage()),
                          ),),
                          Flexible(child: IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: ()=>showAdaptiveWidget(context, SettingsPage(popUp: MediaQuery.of(context).size.width>600)),
                          ),),
                        ],
                      ),
                    ),),
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
                        label: Text('我'.tr),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.explore_outlined),
                        selectedIcon: const Icon(Icons.explore),
                        label: Text('探索'.tr),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.account_tree_outlined),
                        selectedIcon: const Icon(Icons.account_tree),
                        label: Text('分类'.tr),
                      ),
                      NavigationRailDestination(
                        icon: const Icon(Icons.leaderboard_outlined),
                        selectedIcon: const Icon(Icons.leaderboard),
                        label: Text('排行榜'.tr),
                      ),
                    ],
                  ),
                //if(MediaQuery.of(context).size.width>changePoint)
                //  const VerticalDivider(),
                Expanded(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      reverseDuration: const Duration(milliseconds: 0),
                      switchInCurve: Curves.ease,
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        var tween = Tween<Offset>(begin: const Offset(0, 0.05), end: const Offset(0, 0));
                        return SlideTransition(
                          position: tween.animate(animation),
                          child: child,
                        );
                      },
                      child: pages[i],
                    ),
                  ),
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }
}

class NavigatorItem extends StatelessWidget {
  const NavigatorItem(this.icon,this.selectedIcon,this.title,this.selected,this.onTap,{Key? key}) : super(key: key);
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
        child: Container(
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              color: selected?theme.secondaryContainer:null
          ),
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16,),
              Icon(selected?selectedIcon:icon,color: theme.onSurfaceVariant,size: size,),
              const SizedBox(width: 12,),
              Text(title)
            ],
          ),
        ),
      )
    );
  }
}