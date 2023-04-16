import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/pic_views/categories_page.dart';
import 'package:pica_comic/views/eh_views/eh_popular_page.dart';
import 'package:pica_comic/views/pic_views/games_page.dart';
import 'package:pica_comic/views/history.dart';
import 'package:pica_comic/views/leaderboard_page.dart';
import 'package:pica_comic/views/pic_views/picacg_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings_page.dart';
import 'package:pica_comic/views/eh_views/ehentai_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../network/update.dart';
import '../tools/ui_mode.dart';
import 'eh_views/eh_home_page.dart';
import 'models/tab_listener.dart';
import 'pic_views/home_page.dart';
import 'me_page.dart';

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

  var titles = [
    "我",
    "探索",
    "分类",
    "游戏"
  ];

  late var pages = [
    MePage(),
    PicacgPage(picListener),
    EhentaiPage(ehListener)
  ];

  @override
  void initState() {
    Get.put(HomePageLogic());
    Get.put(CategoriesPageLogic());
    Get.put(GamesPageLogic());
    Get.put(EhHomePageLogic());
    Get.put(EhPopularPageLogic());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
    if(hotSearch.isEmpty) {
      network.getKeyWords().then((s){
      if(s!=null){
        hotSearch = s.keyWords;
      }
    });
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
                    TextButton(onPressed: (){Get.back();}, child: const Text("取消")),
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
            TextSpan(text: "此项目与Picacg, e-hentai.org无任何关系\n\n",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
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
      "EHentai"
    ];

    return Scaffold(
      appBar: UiMode.m1(context)?AppBar(
        title: Text(titles[i]),
        centerTitle: true,
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
            icon: Icon(Icons.book),
            label: 'Ehentai',
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
                        NavigatorItem(Icons.book_outlined,Icons.book, "Ehentai",i==2,()=>setState(()=>i=2)),
                        const Divider(),
                        const Spacer(),
                        NavigatorItem(Icons.search,Icons.games, "搜索",false,()=>Get.to(()=>PreSearchPage())),
                        NavigatorItem(Icons.history,Icons.games, "历史记录",false,()=>Get.to(()=>const HistoryPage())),
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
                            icon: const Icon(Icons.history),
                            onPressed: ()=>Get.to(()=>const HistoryPage()),
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
                        icon: Icon(Icons.book_outlined),
                        selectedIcon: Icon(Icons.book),
                        label: Text('EHentai'),
                      ),
                    ],
                  ),
                //if(MediaQuery.of(context).size.width>changePoint)
                //  const VerticalDivider(),
                Expanded(
                  child: ClipRect(
                    child:AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: pages[i],
                    ),
                  ),
                ),
              ],
            ))
          ],
        ),
      ),
      drawer: !(UiMode.m1(context))?null:NavigationDrawer(
        selectedIndex: null,
        onDestinationSelected: (t){
          Navigator.pop(context);
          if(t == 0){
            Get.to(()=>const HistoryPage());
          }else if(t == 1){
            Get.to(()=>const LeaderBoardPage());
          }else{
            showAdaptiveWidget(context, SettingsPage(popUp: MediaQuery.of(context).size.width>600));
          }
        },
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Pica Comic',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ...destinations.map((Destination destination) {
            return NavigationDrawerDestination(
              label: Text(destination.label),
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
            );
          }),
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
            child: Divider(),
          ),
        ],
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
              Icon(selected?selectedIcon:icon,color: theme.onSurfaceVariant,),
              const SizedBox(width: 12,),
              Text(title)
            ],
          ),
        ),
      )
    );
  }
}

class EhIcon extends StatelessWidget {
  const EhIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 25,
      height: 25,
      child: Center(
        child: Text("EH",style: TextStyle(fontSize: 16,fontWeight: FontWeight.w600),),
      ),
    );
  }
}