import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_windows_webview/flutter_windows_webview.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/views/app_views/accounts_page.dart';
import 'package:pica_comic/views/app_views/webview.dart';
import 'package:pica_comic/views/download_page.dart';
import 'package:pica_comic/views/all_favorites_page.dart';
import 'package:pica_comic/views/eh_views/subscription.dart';
import 'package:pica_comic/views/widgets/pop_up_widget.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../base.dart';
import '../foundation/app.dart';
import 'history.dart';
import 'package:pica_comic/tools/translations.dart';
import 'jm_views/jm_comic_page.dart';
import 'local_favorites_page.dart';
import 'main_page.dart';
import 'package:pica_comic/tools/extensions.dart';

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
                Divider(height: 1, color: App.colors.outlineVariant,)
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
                color: App.colors.tertiaryContainer,
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
        splashColor: App.colors.primary.withOpacity(0.2),
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
                border: selected ? Border(bottom: BorderSide(color: App.colors.primary, width: 2)) : null
            ),
            child: Center(
              child: Text(name, style: TextStyle(
                color: selected ? App.colors.primary : null,
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
                            Text("新建".tl, style: TextStyle(color: App.colors.primary),),
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

  void openTool(){
    showModalBottomSheet(context: App.globalContext!, builder: (context) => Column(
      children: [
        ListTile(title: Text("工具".tl),),
        ListTile(
          leading: const Icon(Icons.subscriptions),
          title: Text("EH订阅".tl),
          onTap: () {
            App.globalBack();
            MainPage.to(() => const SubscriptionPage());
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_search_outlined),
          title: Text("图片搜索 [搜图bot酱]".tl),
          onTap: () async{
            App.globalBack();
            if(Platform.isAndroid || Platform.isIOS) {
              MainPage.to(() => AppWebview(
                initialUrl: "https://soutubot.moe/",
                onNavigation: (uri){
                  return handleAppLinks(Uri.parse(uri), showMessageWhenError: false);
                },
              ),);
            }else{
              var webview = FlutterWindowsWebview();
              webview.launchWebview(
                  "https://soutubot.moe/",
                  WebviewOptions(
                      onNavigation: (uri){
                        if(handleAppLinks(Uri.parse(uri), showMessageWhenError: false)){
                          Future.microtask(() => webview.close());
                          return true;
                        }
                        return false;
                      }
                  )
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_search),
          title: Text("图片搜索 [SauceNAO]".tl),
          onTap: () async{
            App.globalBack();
            if(Platform.isAndroid || Platform.isIOS) {
              MainPage.to(() => AppWebview(
                initialUrl: "https://saucenao.com/",
                onNavigation: (uri){
                  return handleAppLinks(Uri.parse(uri), showMessageWhenError: false);
                },
              ),);
            }else{
              var webview = FlutterWindowsWebview();
              webview.launchWebview(
                  "https://saucenao.com/",
                  WebviewOptions(
                      onNavigation: (uri){
                        if(handleAppLinks(Uri.parse(uri), showMessageWhenError: false)){
                          Future.microtask(() => webview.close());
                          return true;
                        }
                        return false;
                      }
                  )
              );
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.web),
          title: Text("打开链接".tl),
          onTap: (){
            App.globalBack();
            showDialog(context: App.globalContext!, builder: (context) {
              final controller = TextEditingController();

              validateText() {
                var text = controller.text;
                if(text == ""){
                  return null;
                }

                if(!text.contains("http://") && !text.contains("https://")){
                  text = "https://$text";
                }

                if(!text.isURL){
                  return "不支持的链接".tl;
                }
                var uri = Uri.parse(text);
                if(!["exhentai.org", "e-hentai.org", "hitomi.la",
                  "nhentai.net", "nhentai.xxx"].contains(uri.host)){
                  return "不支持的链接".tl;
                }
                return null;
              }

              void Function(void Function())? stateSetter;

              onFinish(){
                if(validateText() != null){
                  stateSetter?.call((){});
                }else{
                  App.globalBack();
                  var text = controller.text;
                  if(!text.contains("http://") && !text.contains("https://")){
                    text = "https://$text";
                  }
                  handleAppLinks(Uri.parse(text));
                }
              }

              return AlertDialog(
                title: Text("输入链接".tl),
                content: StatefulBuilder(
                  builder: (BuildContext context, void Function(void Function()) setState) {
                    stateSetter = setState;
                    return TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        errorText: validateText(),
                      ),
                      onSubmitted: (s) => onFinish(),
                    );
                  },
                ),
                actions: [
                  TextButton(onPressed: onFinish, child: Text("打开".tl)),
                ],
              );
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text("禁漫漫画ID".tl),
          onTap: (){
            App.globalBack();
            var controller = TextEditingController();
            showDialog(context: context, builder: (context){
              return AlertDialog(
                title: Text("输入禁漫漫画ID".tl),
                content: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: controller,
                    onEditingComplete: () {
                      App.globalBack();
                      if(controller.text.isNum){
                        MainPage.to(()=>JmComicPage(controller.text));
                      }else{
                        showMessage(App.globalContext, "输入的ID不是数字".tl);
                      }
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                    ],
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "ID",
                        prefix: Text("JM")
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: (){
                    App.globalBack();
                    if(controller.text.isNum){
                      MainPage.to(()=>JmComicPage(controller.text));
                    }else{
                      showMessage(App.globalContext, "输入的ID不是数字".tl);
                    }
                  }, child: Text("提交".tl))
                ],
              );
            });
          },
        )
      ],
    ));
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
              color: App.colors.primaryContainer,
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