import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/foundation/log.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/views/favorites/network_favorites_pages.dart';
import 'package:pica_comic/foundation/local_favorites.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../foundation/app.dart';
import '../../tools/io_tools.dart';
import '../main_page.dart';
import '../widgets/select.dart';
import 'local_favorites.dart';

const _networkFolderFlag = "**##network##**";

List<String> get _allFolders => [_networkFolderFlag] + LocalFavoritesManager().folderNames;
List<FolderSync> get _allFolderSync => LocalFavoritesManager().folderSync;

class LocalFavoritesPage extends StatefulWidget {
  const LocalFavoritesPage({super.key});

  @override
  State<LocalFavoritesPage> createState() => _LocalFavoritesPageState();
}

class _LocalFavoritesPageState extends StateWithController<LocalFavoritesPage> {
  String? _folderName = _networkFolderFlag;

  String? get folderName => _folderName;

  set folderName(String? value) {
    var page = _allFolders.indexOf(value!);
    _folderName = value;
    scheduleMicrotask(() {
      controller.to(page);
    });
  }

  final tabController = ScrollController();
  bool shouldScrollTabBar = false;
  bool searchMode = false;
  String keyword = "";
  bool _local = appdata.settings[52] == "1";

  bool get local => _local;

  set local(bool value) {
    appdata.settings[52] = value ? "1" : "0";
    Future.delayed(const Duration(milliseconds: 250), () => appdata.updateSettings());
    _local = value;
  }

  late final controller = ComicsPageViewController(updateFolderName);

  @override
  void initState() {
    if(LocalFavoritesManager().folderNames.isEmpty){
      LocalFavoritesManager().createFolder("default");
    }
    var names = LocalFavoritesManager().folderNames;
    if(names.contains(appdata.settings[51])){
      _folderName = appdata.settings[51];
    }
    super.initState();
  }

  void updateFolderName(int i){
    if(_allFolders[i] != folderName) {
      setState(() {
        _folderName = _allFolders[i];
      });
    }
  }

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
    return buildBody(context);
  }

  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        if(searchMode)
          buildSearchBar()
        else
          buildTabBar(),
        const Divider(height: 1,),
        if(appdata.firstUse[4] == "1")
          Container(
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
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: buildComics(),
          ),
        ),
      ],
    );
  }

  void showFolderManageDialog(String name) async{
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
          var index = LocalFavoritesManager().folderNames.indexOf(name);
          LocalFavoritesManager().deleteFolder(name);
          if(index == LocalFavoritesManager().folderNames.length){
            index--;
          }
          if(name == folderName){
            _folderName = LocalFavoritesManager().folderNames[index];
          }
          setState(() {});
          App.globalBack();
        }),
        buildItem(const Icon(Icons.reorder), "排序".tl, () async{
          App.globalBack();
          await App.globalTo(() => LocalFavoritesFolder(name))
              .then((value) => setState((){}));
        }),
        buildItem(const Icon(Icons.drive_file_rename_outline), "重命名".tl, () async{
          App.globalBack();
          var index = LocalFavoritesManager().folderNames.indexOf(name);
          showDialog(context: context, builder: (context) => RenameFolderDialog(name))
              .then((value) {
            if(folderName == name && !LocalFavoritesManager().folderNames.contains(folderName)){
              _folderName = LocalFavoritesManager().folderNames[index];
            }
            setState(() {});
          });
        }),
        buildItem(const Icon(Icons.library_add_check), "检查漫画存活".tl, () async{
          App.globalBack();
          checkFolder(name).then((value) {
            if(mounted){
              setState(() {});
            }
          });
        }),
        buildItem(const Icon(Icons.outbox_rounded), "导出".tl, () async{
          App.globalBack();
          var controller = showLoadingDialog(App.globalContext!, () {}, true, true, "正在导出".tl);
          try {
            await exportStringDataAsFile(
                LocalFavoritesManager().folderToJsonString(name),
                "$name.json");
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

  Widget buildSearchBar(){
    return Container(
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          const Icon(Icons.search),
          const SizedBox(width: 4,),
          Expanded(
            child: TextField(
              onChanged: (s) => setState(() {
                keyword = s;
              }),
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(bottom: 4)
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: (){
              setState(() {
                searchMode = false;
              });
            },
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.close),
            ),
          )
        ],
      ),
    );
  }

  Widget buildTabBar() {
    Widget buildTab(String name, [bool network=false]){
      var showName = name;
      if(!network) {
        if (appdata.settings[65] == "1") {
          showName += "(${LocalFavoritesManager().count(name)})";
        }
      } else {
        name = _networkFolderFlag;
      }
      bool selected = folderName == name;
      return InkWell(
        key: Key(name),
        borderRadius: BorderRadius.circular(8),
        splashColor: App.colors(context).primary.withOpacity(0.2),
        onTap: (){
          setState(() {
            folderName = name;
          });
        },
        onLongPress: network ? null : () => showFolderManageDialog(name),
        onSecondaryTapDown: network ? null : (details) => showFolderManageDialog(name),
        child: Container(
          constraints: const BoxConstraints(minWidth: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                      color: selected ?
                        App.colors(context).primary :
                        Colors.transparent,
                      width: 2),
                    top: const BorderSide(
                        color: Colors.transparent,
                        width: 2))
            ),
            child: Center(
              child: Text(showName, style: TextStyle(
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
                  buildTab("网络".tl, true),
                  const SizedBox(width: 8,),
                  for(var name in folders)
                    buildTab(name),
                  const SizedBox(width: 8,),
                  InkWell(
                    onTap: (){
                      keyword = "";
                      setState(() {
                        shouldScrollTabBar = false;
                        searchMode = true;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 12,),
                            Text("搜索".tl, style: TextStyle(color: App.colors(context).primary),),
                            const SizedBox(width: 4,),
                            const Icon(Icons.search, size: 18,),
                            const SizedBox(width: 12,),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildComics(){
    if(searchMode){
      return buildSearchView();
    } else {
      return ComicsPageView(
        key: const Key("comics"),
        controller: controller,
        initialPage: _allFolders.indexOf(_folderName!),
      );
    }
  }

  Widget buildSearchView(){
    if(keyword.isNotEmpty) {
      final comics = LocalFavoritesManager().search(keyword);

      return GridView.builder(
        key: const Key("_pica_comic_"),
        gridDelegate: SliverGridDelegateWithComics(),
        itemCount: comics.length,
        padding: EdgeInsets.zero,
        itemBuilder: (BuildContext context, int index) {
          return LocalFavoriteTile(
            comics[index].comic,
            comics[index].folder,
                () => setState(() {}),
            true,
            showFolderInfo: true,
          );
        },
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  Object? get tag => "me page";
}

class ComicsPageViewController{
  void Function(int)? listener;

  void to(int index){
    listener?.call(index);
  }

  final void Function(int) onDragChangePage;

  ComicsPageViewController(this.onDragChangePage);
}


class ComicsPageView extends StatefulWidget {
  const ComicsPageView({required this.controller, this.initialPage = 0, super.key});

  final ComicsPageViewController controller;

  final int initialPage;

  @override
  State<ComicsPageView> createState() => _ComicsPageViewState();
}

class _ComicsPageViewState extends State<ComicsPageView> {
  late PageController controller = PageController(initialPage: currentPage);

  late int currentPage = widget.initialPage;

  Widget? temp;

  String? folder;

  FolderSync? folderSync(){
    final folderSyncArr = _allFolderSync.where((element) => element.folderName == folder).toList();
    if(folderSyncArr.isEmpty) return null;
    return folderSyncArr[0];
  }
  @override
  void initState() {
    widget.controller.listener = onPageChange;
    super.initState();
  }

  void onPageChange(int newIndex){
    if(currentPage == newIndex){
      setState(() {});
      return;
    }

    if((currentPage - newIndex).abs() == 1){
      folder = _allFolders[newIndex];
      controller.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease
      );
    } else {
      temp = buildFolderComics(_allFolders[currentPage]);
      int initialPage = currentPage - newIndex > 0 ? newIndex+1 : newIndex-1;
      folder = _allFolders[initialPage];
      controller.jumpToPage(initialPage);
      scheduleMicrotask(() {
        folder = _allFolders[newIndex];
        controller.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.ease);
      });
    }
  }

  Widget buildPreviousPage(){
    if(currentPage == 0){
      return const SizedBox();
    }
    return buildFolderComics(_allFolders[currentPage-1]);
  }

  @override
  Widget build(BuildContext context) {
    if(_allFolders.length <= currentPage){
      currentPage--;
    }
    return PageView.builder(
      controller: controller,
      onPageChanged: (i) {
        currentPage = i;
        if(folder != _allFolders[i]){
          folder = _allFolders[i];
          widget.controller.onDragChangePage(i);
        }
      },
      itemCount: _allFolders.length,
      itemBuilder: (context, index){
        if(temp != null){
          Future.microtask(() => temp = null);
          return temp;
        }
        return buildFolderComics(_allFolders[index]);
      },
    );
  }
  Future<void> onRefresh(context) async {

    if(folderSync() == null){
      showMessage(App.globalContext, "该收藏夹没有对应网络收藏夹".tl);
      return Future.value();
    }
    var controllerFrom = TextEditingController();
    var controllerTo = TextEditingController();
    var direction = "0";
    await showDialog(context: context, builder: (context){
      return AlertDialog(
        title: Text("网络收藏夹同步设置".tl),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: Row(
            children: [
              Text("从".tl+"1"),
              // TextField(
              //   keyboardType: TextInputType.number,
              //   controller: controllerFrom,
              //   inputFormatters: [
              //     FilteringTextInputFormatter.allow(RegExp("[0-9]"))
              //   ],
              //   decoration: const InputDecoration(
              //       border: OutlineInputBorder(),
              //   ),
              // ),
              Text("到".tl),
              TextField(
                keyboardType: TextInputType.number,
                controller: controllerTo,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                ],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              Text("新收藏添加至".tl),
              Select(
                values: ["最后".tl, "最前".tl],
                initialValue: 0,
                whenChange: (i) {
                  direction = i.toString();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: (){
            if(controllerTo.text == ""){
              return;
            }
            App.globalBack();
          }, child: Text("提交".tl))
        ],
      );
    });

    return startFolderSync(context, folderSync()!, FolderSyncParam(int.parse("1"), int.parse(controllerTo.text), direction));
  }
  Widget buildFolderComics(String folder){
    if(folder == _networkFolderFlag){
      return const NetworkFavoritesPages();
    }
    var comics = LocalFavoritesManager().getAllComics(folder);
    inspect(comics);
    if(comics.isEmpty){
      return buildEmptyView();
    }
    return MediaQuery.removePadding(
      key: Key(folder),
      removeTop: true,
      context: context,
      child: RefreshIndicator(
        onRefresh: ()=>onRefresh(context),
        child: Scrollbar(
            interactive: true,
            thickness: App.isMobile ? 8 : null,
            radius: const Radius.circular(8),
            child: GridView.builder(
              key: Key(folder),
              primary: true,
              gridDelegate: SliverGridDelegateWithComics(),
              itemCount: comics.length,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context, int index) {
                return LocalFavoriteTile(
                  comics[index],
                  folder,
                  () => setState(() {}),
                  true,
                  showFolderInfo: true,
                );
              },
          )),
      ),
    );
  }

  Widget buildEmptyView(){
    Widget noFolderSync = RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: [
          TextSpan(
            text: '前往'.tl,
          ),
          TextSpan(
              text: '探索页面'.tl,
              style: TextStyle(color: App.colors(context).primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  MainPage.toExplorePage?.call();
                }),
          TextSpan(
            text: '寻找漫画'.tl,
          ),
        ],
      ),
    );
    Widget hasFolderSync = Text("尝试下拉刷新, 同步网络收藏".tl);
    return RefreshIndicator(
      onRefresh: () => onRefresh(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(folderSync() == null ? "这里什么都没有".tl : "这个收藏夹同步了网络".tl),
              const SizedBox(
                height: 8,
              ),
              folderSync() == null ? noFolderSync : hasFolderSync
            ],
          ),
        ),
      ),
    );
  }
}
