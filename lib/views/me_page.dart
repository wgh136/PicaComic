import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/all_favorites_page.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import '../foundation/app.dart';
import '../foundation/ui_mode.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'local_favorites_page.dart';
import 'main_page.dart';
import 'package:sliver_tools/sliver_tools.dart';

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

class _NewMePageState extends StateWithController<NewMePage>{
  String? folderName;
  final controller = ScrollController();
  final tabController = ScrollController();
  bool shouldScrollTabBar = false;

  void hideLocalFavorites(){
    setState(() {
      appdata.settings[52] = "1";
      appdata.updateSettings();
    });
  }

  void showLocalFavorites(){
    setState(() {
      appdata.settings[52] = "0";
      appdata.updateSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
      child: appdata.settings[52] == "0" ? buildNewView(context) : buildOldView(context),
    );
  }

  Widget buildOldView(BuildContext context) {
    return CustomScrollView(
      key: const Key("1"),
      slivers: [
        if (!UiMode.m1(context))
          const SliverPadding(padding: EdgeInsets.all(30)),
        SliverToBoxAdapter(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.fromSize(
                  size: const Size(400, 120),
                  child: const Center(
                    child: Text(
                      "Pica Comic",
                      style: TextStyle(
                          fontFamily: "font2",
                          fontSize: 40,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Wrap(
                  children: [
                    MePageButton(
                      title: "账号管理".tl,
                      subTitle: "查看或修改账号信息".tl,
                      icon: Icons.switch_account,
                      onTap: () => showAdaptiveWidget(App.globalContext!,
                          AccountsPage(popUp: MediaQuery.of(App.globalContext!).size.width>600,)),
                    ),
                    MePageButton(
                      title: "收藏夹".tl,
                      subTitle: "查看已收藏的漫画".tl,
                      icon: Icons.bookmarks,
                      onTap: () => MainPage.to(() => const AllFavoritesPage()),
                    ),
                    MePageButton(
                      title: "已下载".tl,
                      subTitle: "管理已下载的漫画".tl,
                      icon: Icons.download_for_offline,
                      onTap: () => MainPage.to(() => const DownloadPage()),
                    ),
                    MePageButton(
                      title: "历史记录".tl,
                      subTitle: "查看历史记录".tl,
                      icon: Icons.history,
                      onTap: () => MainPage.to(() => const HistoryPage()),
                    ),
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: showLocalFavorites,
                    child: Text("显示收藏".tl),
                  ),
                )
              ],
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 12)),
      ],
    );
  }

  Widget buildNewView(BuildContext context) {
    return CustomScrollView(
      key: const Key("0"),
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
        SliverAnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: buildComics(),
        ),
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
            constraints: const BoxConstraints(maxWidth: 400, minHeight: 56),
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
                .then((value) {
                  if(folderName == name && !LocalFavoritesManager().folderNames.contains(folderName)){
                    folderName = null;
                  }
                  setState((){});
            });
          }),
          buildItem(const Icon(Icons.text_snippet_outlined), "生成文本并复制".tl, () async{
            App.globalBack();
            var res = await LocalFavoritesManager().folderToString(name);
            Clipboard.setData(ClipboardData(text: res));
            showMessage(App.globalContext, "已复制".tl);
          }),
          buildItem(const Icon(Icons.import_export), "导出".tl, () async{
            App.globalBack();
            var controller = showLoadingDialog(App.globalContext!, () {}, true, true, "正在导出".tl);
            try {
              await exportStringDataAsFile(
                  LocalFavoritesManager().folderToJsonString(name),
                  "comics.json");
              controller.close();
            }
            catch(e, s){
              controller.close();
              showMessage(App.globalContext, e.toString());
              LogManager.addLog(LogLevel.error, "IO", "$e\n$s");
            }
          }),
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
                            const SizedBox(width: 12,),
                            Text("新建".tl, style: TextStyle(color: App.colors(context).primary),),
                            const SizedBox(width: 4,),
                            const Icon(Icons.add, size: 18,),
                            const SizedBox(width: 12,),
                          ],
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: hideLocalFavorites,
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12,),
                            Text("隐藏".tl, style: TextStyle(color: App.colors(context).primary),),
                            const SizedBox(width: 4,),
                            const Icon(Icons.close, size: 18,),
                            const SizedBox(width: 12,),
                          ],
                        ),
                      ),
                    ),
                  ),
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

  Widget buildEmptyView(){
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("这里什么都没有"),
            const SizedBox(height: 8,),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '前往'.tl,
                  ),
                  TextSpan(
                      text: '探索页面'.tl,
                      style: TextStyle(color: App.colors(context).primary),
                      recognizer:  TapGestureRecognizer()..onTap = () {
                        MainPage.toExplorePage?.call();
                      }
                  ),
                  TextSpan(
                    text: '寻找漫画'.tl,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }


  Widget buildAllComics(){
    var comics = LocalFavoritesManager().allComics();
    if(comics.isEmpty){
      return buildEmptyView();
    }
    return SliverGrid.builder(
      key: const Key("_pica_comic_"),
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
    var comics = LocalFavoritesManager().getAllComics(folderName!);
    if(comics.isEmpty){
      return buildEmptyView();
    }
    return SliverGrid.builder(
      key: Key(folderName!),
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

  @override
  Object? get tag => "me page";
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

class MePageButton extends StatefulWidget {
  const MePageButton({required this.title, required this.subTitle, required this.icon, required this.onTap, super.key});

  final String title;
  final String subTitle;
  final IconData icon;
  final void Function() onTap;

  @override
  State<MePageButton> createState() => _MePageButtonState();
}

class _MePageButtonState extends State<MePageButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    double width;
    double screenWidth = MediaQuery.of(context).size.width;
    double padding = 10.0;
    if (screenWidth > changePoint2) {
      screenWidth -= 400;
      width = screenWidth / 2 - padding * 2;
    } else if (screenWidth > changePoint) {
      screenWidth -= 80;
      width = screenWidth / 2 - padding * 2;
    } else {
      width = screenWidth - padding * 2;
    }

    if (width > 400) {
      width = 400;
    }
    var height = width / 3;
    if(height < 100){
      height = 100;
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(padding, 8, padding, 8),
      child: MouseRegion(
        onEnter: (event) => setState(() => hovering = true),
        onExit: (event) => setState(() => hovering = false),
        cursor: SystemMouseCursors.click,
        child: Listener(
          onPointerUp: (event) => setState(() => hovering = false),
          onPointerDown: (event) => setState(() => hovering = true),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(24)),
            onTap: widget.onTap,
            child: SizedBox(
              width: width,
              height: height,
              child: AnimatedContainer(
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    color: hovering?Theme.of(context).colorScheme.inversePrimary.withAlpha(150):Theme.of(context).colorScheme.inversePrimary.withAlpha(40)
                ),
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 8, 32, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(widget.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),),
                              ),
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(widget.subTitle, style: const TextStyle(fontSize: 15),),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ClipPath(
                          clipper: MePageIconClipper(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: hovering?Theme.of(context).colorScheme.primary:Theme.of(context).colorScheme.surface,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(widget.icon, color: hovering?Theme.of(context).colorScheme.onPrimary:Theme.of(context).colorScheme.onSurface,),
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
        ),
      ),
    );
  }
}

class MePageIconClipper extends CustomClipper<Path>{
  @override
  Path getClip(Size size) {
    final path = Path();
    final r = size.width * 0.3; // 控制弧线的大小

    // 起始点
    path.moveTo(r, 0);

    // 上边弧线
    path.arcToPoint(
      Offset(size.width - r, 0),
      radius: Radius.circular(r * 2),
      clockwise: false,
    );

    // 右上角圆弧
    path.arcToPoint(
      Offset(size.width, r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 右边弧线
    path.arcToPoint(
      Offset(size.width, size.height - r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 右下角圆弧
    path.arcToPoint(
      Offset(size.width - r, size.height),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 下边弧线
    path.arcToPoint(
      Offset(r, size.height),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左下角圆弧
    path.arcToPoint(
      Offset(0, size.height - r),
      radius: Radius.circular(r),
      clockwise: true,
    );

    // 左边弧线
    path.arcToPoint(
      Offset(0, r),
      radius: Radius.circular(r*2),
      clockwise: false,
    );

    // 左上角圆弧
    path.arcToPoint(
      Offset(r, 0),
      radius: Radius.circular(r),
      clockwise: true,
    );

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }

}