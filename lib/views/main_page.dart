import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/categories_page.dart';
import 'package:pica_comic/views/games_page.dart';
import 'package:pica_comic/views/history.dart';
import 'package:pica_comic/views/leaderboard_page.dart';
import 'package:pica_comic/views/search_page.dart';
import 'package:pica_comic/views/settings_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../network/update.dart';
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

  List<Destination> destinations = <Destination>[
    const Destination(
        '最近阅读', Icon(Icons.history), Icon(Icons.history)),
    const Destination(
        '排行榜', Icon(Icons.leaderboard), Icon(Icons.leaderboard)),
    const Destination(
        '设置', Icon(Icons.settings), Icon(Icons.settings)),
  ];

  int i = 0;
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
    const GamesPage()
  ];

  @override
  Widget build(BuildContext context) {
    if(appdata.user.isPunched==false&&appdata.settings[6]=="1"){
      network.punchIn().then((b){
        if(b){
          appdata.user.isPunched = true;
          showMessage(context, "打卡成功");
          appdata.user.exp+=10;
        }
      });
    }
    if(hotSearch.isEmpty) {
      network.getKeyWords().then((s){
      if(s!=null){
        hotSearch = s.keyWords;
      }
    });
    }

    if(appdata.settings[2]=="1"&&updateFlag) {
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
    return Scaffold(
      bottomNavigationBar: MediaQuery.of(context).size.shortestSide>changePoint?null:NavigationBar(
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
        ],
      ),
      body: Row(
        children: [
          if(MediaQuery.of(context).size.shortestSide>changePoint)
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
                    onPressed: (){Get.to(()=>SearchPage());},
                  ),),
                  Flexible(child: IconButton(
                    icon: const Icon(Icons.leaderboard),
                    onPressed: (){Get.to(()=>const LeaderBoardPage());},
                  ),),
                  Flexible(child: IconButton(
                    icon: const Icon(Icons.history),
                    onPressed: (){Get.to(()=>const HistoryPage());},
                  ),),
                  Flexible(child: IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: (){Get.to(()=>const SettingsPage());},
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
            ],
          ),
          if(MediaQuery.of(context).size.shortestSide>changePoint)
          const VerticalDivider(),
          Expanded(
            child: ClipRect(
              child: Navigator(
                onGenerateRoute: (settings) => MaterialPageRoute(
                  builder: (context) => pages[i],
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.shortestSide>changePoint?null:NavigationDrawer(
        selectedIndex: null,
        onDestinationSelected: (t){
          Navigator.pop(context);
          if(t == 0){
            Get.to(()=>const HistoryPage());
          }else if(t == 1){
            Get.to(()=>const LeaderBoardPage());
          }else{
            Get.to(()=>const SettingsPage());
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
