import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/all_favorites_page.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import '../foundation/app.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'local_favorites_page.dart';
import 'main_page.dart';

class _SliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SliverPersistentHeaderDelegate(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: child,
        )
      ],
    ),);
  }

  @override
  double get maxExtent => 107;

  @override
  double get minExtent => 49;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
    oldDelegate is! _SliverPersistentHeaderDelegate || child != oldDelegate.child;

}


class NewMePage extends StatefulWidget {
  const NewMePage({super.key});

  @override
  State<NewMePage> createState() => _NewMePageState();
}

class _NewMePageState extends State<NewMePage>{
  String? folderName;
  final controller = ScrollController();
  final tabController = ScrollController();
  bool shouldScrollTabBar = false;

  @override
  void initState() {
    Future.microtask(() => LocalFavoritesManager().readData()).then((value) => setState((){}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      primary: false,
      controller: controller,
      physics: shouldScrollTabBar ? const NeverScrollableScrollPhysics() : null,
      slivers: [
        SliverPersistentHeader(
          delegate: _SliverPersistentHeaderDelegate(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 58,
                  width: double.infinity,
                  child: Row(
                    children: [
                      NewMePageButton(icon: const Icon(Icons.switch_account), title: "账号管理".tl, onTap: () => showAdaptiveWidget(App.globalContext!,
                          AccountsPage(popUp: MediaQuery.of(App.globalContext!).size.width>600,))),
                      NewMePageButton(icon: const Icon(Icons.download_for_offline), title: "已下载".tl, onTap: () => MainPage.to(() => const DownloadPage())),
                      NewMePageButton(icon: const Icon(Icons.history), title: "历史记录".tl, onTap: () => MainPage.to(() => const HistoryPage())),
                      NewMePageButton(icon: const Icon(Icons.cloud), title: "网络收藏".tl, onTap: () => App.to(context, () => const AllFavoritesPage()))
                    ],
                  ),
                ),
                buildTabBar(),
                Divider(height: 1, color: App.colors(context).outlineVariant,)
              ],
            )
          ),
          pinned: true,
        ),
        if(appdata.firstUse[4] == "1")
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              decoration: BoxDecoration(
                color: App.colors(context).tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text("要管理收藏夹, 请长按收藏夹标签或者使用鼠标右键".tl),
                  ),
                  IconButton(onPressed: (){
                    setState(() {
                      appdata.firstUse[4] = "0";
                    });
                    appdata.writeFirstUse();
                  }, icon: const Icon(Icons.close))
                ],
              ),
            ),
          ),
        buildComics(),
      ],
    );
  }

  void showFolderManageDialog(String name) async{
    if(name == "全部".tl){
      showMessage(context, "不能管理\"全部\"收藏".tl);
    } else {
      Widget buildItem(Icon icon, String title, void Function() onTap){
        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, minHeight: 42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  icon,
                  const SizedBox(width: 12,),
                  Text(title)
                ],
              ),
            ),
          ),
        );
      }

      bool isModified = false;

      await showDialog(context: App.globalContext!, builder: (context) => SimpleDialog(
        title: Text(name),
        children: [
          buildItem(const Icon(Icons.delete), "删除".tl, () {
            isModified = true;
            LocalFavoritesManager().deleteFolder(name);
            if(name == folderName){
              folderName = null;
            }
            App.globalBack();
          }),
          buildItem(const Icon(Icons.reorder), "排序".tl, () async{
            App.globalBack();
            await App.globalTo(() => LocalFavoritesFolder(name))
                .then((value) => setState((){}));
          }),
          buildItem(const Icon(Icons.drive_file_rename_outline), "重命名".tl, () async{
            App.globalBack();
            showDialog(context: context, builder: (context) => RenameFolderDialog(name))
                .then((value) => setState((){}));
          })
        ],
      ));

      if(isModified){
        setState(() {});
      }
    }
  }

  Widget buildTabBar() {
    Widget buildTab(String name){
      bool selected = folderName == name || (name == "全部".tl && folderName == null);
      return InkWell(
        key: Key(name),
        borderRadius: BorderRadius.circular(8),
        splashColor: App.colors(context).primary.withOpacity(0.2),
        onTap: (){
          if(name == "全部".tl){
            setState(() {
              folderName = null;
            });
          } else {
            setState(() {
              folderName = name;
            });
          }
          if(controller.position.pixels > controller.position.minScrollExtent + 58) {
            controller.jumpTo(controller.position.minScrollExtent + 58);
          }
        },
        onLongPress: () => showFolderManageDialog(name),
        onSecondaryTapDown: (details) => showFolderManageDialog(name),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
                border: selected ? Border(bottom: BorderSide(color: App.colors(context).primary, width: 2)) : null
            ),
            child: Center(
              child: Text(name, style: TextStyle(
                color: selected ? App.colors(context).primary : null,
                fontWeight: FontWeight.w600,
              ),),
            ),
          ),
        ),
      );
    }

    final folders = LocalFavoritesManager().folderNames;
    if(folders == null) {
      Future.microtask(() => LocalFavoritesManager().readData())
          .then((value) => setState(() {}));
      return const SizedBox();
    }
    return Material(
      child: MouseRegion(
        onEnter: (details) => setState(() => shouldScrollTabBar = true),
        onExit: (details) => setState(() => shouldScrollTabBar = false),
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerSignal: (details){
            if(details is PointerScrollEvent){
              tabController.jumpTo(
                  (tabController.position.pixels + details.scrollDelta.dy).clamp(
                      tabController.position.minScrollExtent,
                      tabController.position.maxScrollExtent
                  ));
            }
          },
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: tabController,
              child: Row(
                children: [
                  const SizedBox(width: 8,),
                  buildTab("全部".tl),
                  for(var name in folders)
                    buildTab(name),
                  const SizedBox(width: 8,),
                  InkWell(
                    onTap: (){
                      showDialog(context: context, builder: (context) =>
                      const CreateFolderDialog()).then((value) => setState((){}));
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8,),
                            Text("新建".tl, style: TextStyle(color: App.colors(context).primary),),
                            const SizedBox(width: 4,),
                            const Icon(Icons.add, size: 18,),
                            const SizedBox(width: 8,),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildComics(){
    if(folderName == null){
      return buildAllComics();
    } else {
      return buildFolderComics();
    }
  }


  Widget buildAllComics(){
    var comics = LocalFavoritesManager().allComics();
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: App.comicTileMaxWidth,
        childAspectRatio: App.comicTileAspectRatio,
      ),
      itemCount: comics.length,
      itemBuilder: (BuildContext context, int index) {
        return LocalFavoriteTile(
          comics[index].comic,
          comics[index].folder,
              () {
            comics.clear();
            setState(() {
              comics = LocalFavoritesManager().allComics();
            });
          },
          true,
          showFolderInfo: true,
        );
      },
    );
  }

  Widget buildFolderComics(){
    var comics = LocalFavoritesManager().getAllComics(folderName!)!;
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: App.comicTileMaxWidth,
        childAspectRatio: App.comicTileAspectRatio,
      ),
      itemCount: comics.length,
      itemBuilder: (BuildContext context, int index) {
        return LocalFavoriteTile(
          comics[index],
          folderName!,
          () => setState(() {}),
          true,
          showFolderInfo: true,
        );
      },
    );
  }
}

class NewMePageButton extends StatelessWidget {
  const NewMePageButton({required this.icon, required this.title, required this.onTap, super.key});

  final Icon icon;

  final String title;

  final ActionFunc onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(builder: (context, constrains){
        Widget child;

        if(constrains.maxWidth < 148){
          child = Center(
            child: icon,
          );
        } else {
          child =  Row(
            children: [
              const SizedBox(width: 16,),
              icon,
              const SizedBox(width: 8,),
              Text(title),
              const SizedBox(width: 16,),
            ],
          );
        }

        return Container(
          width: double.infinity,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
              color: App.colors(context).primaryContainer,
              borderRadius: BorderRadius.circular(16)
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: child,
            ),
          ),
        );
    }));
  }
}