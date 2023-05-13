import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_home_page.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_main_page.dart';
import 'package:pica_comic/views/jm_views/jm_categories_page.dart';
import 'package:pica_comic/views/jm_views/jm_home_page.dart';
import 'package:pica_comic/views/jm_views/jm_latest_page.dart';
import 'package:pica_comic/views/jm_views/jm_main_page.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/leaderboard_page.dart';
import 'package:pica_comic/views/pic_views/picacg_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings/settings_page.dart';
import 'package:pica_comic/views/eh_views/ehentai_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import '../network/hitomi_network/hitomi_main_network.dart';
import '../network/update.dart';
import '../tools/ui_mode.dart';
import 'eh_views/eh_home_page.dart';
import 'models/tab_listener.dart';
import 'pic_views/home_page.dart';
import 'me_page.dart';
import 'widgets/my_icons_icons.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';

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
  var downloadFlag = true;
  var downloadManagerFlag = true;

  List<Destination> destinations = <Destination>[
    const Destination(
        '最近阅读', Icon(Icons.history), Icon(Icons.history)),
    const Destination(
        '排行榜', Icon(Icons.leaderboard), Icon(Icons.leaderboard)),
    const Destination(
        '设置', Icon(Icons.settings), Icon(Icons.settings)),
  ];

  int i = 0;//页面
  int m = 0;//导航栏页面
  TabListener picListener = TabListener();
  TabListener ehListener = TabListener();
  TabListener jmListener = TabListener();
  TabListener hiListener = TabListener();

  var titles = [
    "我",
    "探索",
    "分类",
    "游戏"
  ];

  late var pages = [
    MePage(),
    PicacgPage(picListener),
    EhentaiPage(ehListener),
    JmMainPage(jmListener),
    HitomiPage(hiListener),
  ];

  @override
  void initState() {
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
      network.punchIn().then((b){
        if(b){
          appdata.user.isPunched = true;
          showMessage(context, "打卡成功", useGet: false);
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
                  title: const Text("有可用更新"),
                  content: Text(s),
                  actions: [
                    TextButton(onPressed: (){Get.back();appdata.settings[2]="0";appdata.writeData();}, child: const Text("关闭更新检查")),
                    TextButton(onPressed: ()=>Get.back(), child: const Text("取消")),
                    if(!GetPlatform.isWeb)
                    TextButton(
                        onPressed: (){
                          getDownloadUrl().then((s){
                            launchUrlString(s,mode: LaunchMode.externalApplication);
                          });
                        },
                        child: const Text("下载"))
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
            title: const Text("下载管理器"),
            content: const Text("有未完成的下载, 是否继续?"),
            actions: [
              TextButton(onPressed: ()=>Get.back(), child: const Text("否")),
              TextButton(onPressed: (){
                downloadManager.start();
                Get.back();
              }, child: const Text("是"))
            ],
          );
        });
      });
    }
    downloadManagerFlag = false;

    //检查是否第一次使用
    if(appdata.settings[10]=="0"){
      appdata.settings[10] = "1";
      appdata.writeData();
      Future.delayed(const Duration(microseconds: 600),()=>showDialog(context: context, builder: (dialogContext)=>AlertDialog(
        title: const Text("欢迎"),
        content: RichText(
          text: TextSpan(children: [
            TextSpan(text: "感谢使用本软件, 请注意:\n\n",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            TextSpan(text: "本App的开发目的仅为学习交流与个人兴趣, 无任何获利\n\n",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            TextSpan(text: "此项目与Picacg, e-hentai.org, JmComic无任何关系",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ]),
        ),
        actions: [
          TextButton(onPressed: ()=>Get.back(), child: const Text("了解"))
        ],
      )));
    }

    var titles = [
      "我",
      "Picacg",
      "EHentai",
      "JmComic",
      "Hitomi"
    ];

    return Scaffold(
      appBar: UiMode.m1(context)?AppBar(
        scrolledUnderElevation: 0,
        title: Text(titles[i]),
        actions: [
          Tooltip(
            message: "搜索",
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: (){
                Get.to(()=>PreSearchPage());
              },
            ),
          ),
          Tooltip(
            message: "排行榜",
            child: IconButton(
              icon: const Icon(Icons.leaderboard),
              onPressed: (){
                Get.to(()=>const LeaderBoardPage());
              },
            ),
          ),
          Tooltip(
            message: "设置",
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: (){
                Get.to(()=>const SettingsPage());
              },
            ),
          ),
        ],
      ):null,
      floatingActionButton: i!=0?FloatingActionButton(
        onPressed: () {
          if(i == 1){
            switch(picListener.getIndex()){
              case 0: Get.find<HomePageLogic>().refresh_();break;
              case 1: Get.find<CategoriesPageLogic>().refresh_();break;
              case 2: Get.find<GamesPageLogic>().refresh_();break;
            }
          }else if(i == 2){
            switch(ehListener.getIndex()){
              case 0: Get.find<EhHomePageLogic>().refresh_();break;
              case 1: Get.find<EhPopularPageLogic>().refresh_();break;
            }
          }else if(i == 3){
            switch(jmListener.getIndex()){
              case 0: Get.find<JmHomePageLogic>().refresh_();break;
              case 1: Get.find<JmLatestPageLogic>().refresh_();break;
              case 2: Get.find<JmCategoriesPageLogic>().refresh_();break;
            }
          }else if(i == 4){
            switch(hiListener.getIndex()){
              case 0: Get.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageAll).refresh_();break;
              case 1: Get.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageCn).refresh_();break;
              case 2: Get.find<HitomiHomePageLogic>(tag: HitomiDataUrls.homePageJp).refresh_();break;
            }
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
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.person),
            label: '我',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore),
            label: 'Picacg',
          ),
          NavigationDestination(
            icon: Icon(MyIcons.eh, size: 20,),
            label: 'Ehentai',
          ),
          NavigationDestination(
            icon: Icon(MyIcons.jm, size: 18,),
            label: 'JmComic',
          ),
          NavigationDestination(
            icon: Icon(Icons.book, size: 18,),
            label: 'Hitomi',
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: ()async{
          bool exit = false;
          if(downloadManager.downloading.isNotEmpty){
            await showDialog(context: context, builder: (dialogContext){
              return AlertDialog(
                title: const Text("下载未完成"),
                content: const Text("有未完成的下载, 确定退出?"),
                actions: [
                  TextButton(onPressed: ()=>Get.back(), child: const Text("否")),
                  TextButton(onPressed: (){
                    exit = true;
                    downloadManager.pause();
                    Get.back();
                  }, child: const Text("是")),
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
                        NavigatorItem(Icons.person_outlined,Icons.person, "我",i==0,()=>setState(()=>i=0)),
                        NavigatorItem(Icons.explore_outlined,Icons.explore, "Picacg",i==1,()=>setState(()=>i=1)),
                        NavigatorItem(MyIcons.eh,MyIcons.eh, "Ehentai",i==2,()=>setState(()=>i=2)),
                        NavigatorItem(MyIcons.jm,MyIcons.jm, "JmComic",i==3,()=>setState(()=>i=3)),
                        NavigatorItem(Icons.book_outlined,Icons.book, "Hitomi",i==3,()=>setState(()=>i=4)),
                        const Divider(),
                        const Spacer(),
                        NavigatorItem(Icons.search,Icons.games, "搜索",false,()=>Get.to(()=>PreSearchPage())),
                        NavigatorItem(Icons.leaderboard,Icons.games, "排行榜",false,()=>Get.to(()=>const LeaderBoardPage())),
                        NavigatorItem(Icons.settings,Icons.games, "设置",false,()=>showAdaptiveWidget(context, SettingsPage(popUp: MediaQuery.of(context).size.width>600,)),),
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
                            icon: const Icon(Icons.leaderboard),
                            onPressed: ()=>Get.to(()=>const LeaderBoardPage()),
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
                    destinations: const <NavigationRailDestination>[
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outlined),
                        selectedIcon: Icon(Icons.person),
                        label: Text('我'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: Text('Picacg'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(MyIcons.eh, size: 20,),
                        selectedIcon: Icon(MyIcons.eh, size: 20,),
                        label: Text('EHentai'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(MyIcons.jm, size: 18,),
                        selectedIcon: Icon(MyIcons.jm, size: 18,),
                        label: Text('JmComic'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.book_outlined, size: 18,),
                        selectedIcon: Icon(Icons.book, size: 18,),
                        label: Text('Hitomi'),
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
    if(icon == MyIcons.eh){
      size = 20;
    }else if(icon == MyIcons.jm){
      size = 18;
    }
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