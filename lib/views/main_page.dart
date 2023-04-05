import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/categories_page.dart';
import 'package:pica_comic/views/eh_views/eh_main_page.dart';
import 'package:pica_comic/views/games_page.dart';
import 'package:pica_comic/views/history.dart';
import 'package:pica_comic/views/leaderboard_page.dart';
import 'package:pica_comic/views/pre_search_page.dart';
import 'package:pica_comic/views/settings_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../network/update.dart';
import '../tools/ui_mode.dart';
import 'home_page.dart';
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
  var titles = [
    "我",
    "探索",
    "分类",
    "游戏"
  ];

  var pages = [
    MePage(),
    const HomePage(),
    const CategoriesPage(),
    const GamesPage(),
    const EhMainPage()
  ];

  @override
  void initState() {
    Get.put(HomePageLogic());
    Get.put(CategoriesPageLogic());
    Get.put(GamesPageLogic());
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
          showMessage(context, "打卡成功");
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
            TextSpan(text: "本App的开发目的仅为学习交流与个人兴趣, 不接受任何形式捐赠, 无任何获利\n\n",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            TextSpan(text: "请尽可能使用官方App, 如您坚持使用本App, 您可以点击分类中的",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            TextSpan(text: "援助哔咔",style: TextStyle(fontWeight: FontWeight.w600,color: Theme.of(context).colorScheme.onSurface)),
            TextSpan(text: ", 为官方运营出力\n",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          ]),
        ),
        actions: [
          TextButton(onPressed: ()=>Get.back(), child: const Text("了解"))
        ],
      )));
    }

    return Scaffold(
      floatingActionButton: i==1?FloatingActionButton(
        onPressed: () {
          var logic = Get.find<HomePageLogic>();
          logic.refresh_();
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
            label: '探索',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree),
            label: '分类',
          ),
          NavigationDestination(
            icon: Icon(Icons.games),
            label: '游戏',
          ),
          NavigationDestination(
            icon: EhIcon(),
            label: 'Eh',
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
        child: Row(
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
                    NavigatorItem(Icons.explore_outlined,Icons.explore, "探索",i==1,()=>setState(()=>i=1)),
                    NavigatorItem(Icons.account_tree_outlined,Icons.account_tree, "分类",i==2,()=>setState(()=>i=2)),
                    NavigatorItem(Icons.games_outlined,Icons.games, "游戏",i==3,()=>setState(()=>i=3)),
                    EhNavigationItem(()=>setState(()=>i=4), i==4),
                    const Divider(),
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
                    label: Text('探索'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.account_tree_outlined),
                    selectedIcon: Icon(Icons.account_tree),
                    label: Text('分类'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.games_outlined),
                    selectedIcon: Icon(Icons.games),
                    label: Text('游戏'),
                  ),
                  NavigationRailDestination(
                    icon: EhIcon(),
                    selectedIcon: EhIcon(),
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

class EhNavigationItem extends StatelessWidget {
  const EhNavigationItem(this.onTap,this.selected,{Key? key}) : super(key: key);
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
              children: const [
                SizedBox(width: 16,),
                EhIcon(),
                SizedBox(width: 12,),
                Text("EHentai")
              ],
            ),
          ),
        )
    );
  }
}
