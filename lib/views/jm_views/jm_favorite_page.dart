import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import 'jm_widgets.dart';

class JmFavoritePageLogic extends GetxController{
  bool loading = true;
  String folderName = "全部".tr;
  String folderId = "0";
  FavoriteFolder? folder;
  String? message;
  Map<String, String> folders = {};

  void change(){
    loading = !loading;
    try {
      update();
    }
    catch(e){
      //已退出页面
    }
  }

  void get() async{
    var r = await jmNetwork.getFolders();
    if(r.error){
      message = r.errorMessage;
      change();
      return;
    }else{
      folders = r.data;
    }
    var res = await jmNetwork.getFolderComics(folderId);
    if(res.error){
      message = res.errorMessage;
      change();
    }else{
      folder = res.data;
      change();
    }
  }

  void loadMore() async{
    if(folder!.total <= folder!.loadedComics){
      return;
    }
    await jmNetwork.loadFavoriteFolderNextPage(folder!);
    update();
  }

  void refresh_(){
    folder = null;
    folders = {};
    message = null;
    loading = true;
    update();
  }


}

class JmFavoritePage extends StatelessWidget {
  const JmFavoritePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JmFavoritePageLogic>(builder: (logic){
      if(appdata.jmName == ""){
        return Center(
          child: Text("未登录".tr),
        );
      }
      if(logic.loading){
        logic.get();
        return Column(
          children: [
            buildFolderSelector(context, logic, true),
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          ],
        );
      }else if(logic.folder == null){
        return showNetworkError(logic.message!, logic.refresh_, context, showBack: false);
      }else{
        return RefreshIndicator(
          onRefresh: () async{
            logic.refresh_();
          },
          child: Column(
            children: [
              buildFolderSelector(context, logic, false),
              const Divider(),
              Expanded(child: CustomScrollView(
                slivers: [
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                            (context, index){
                          if(index == logic.folder!.comics.length-1){
                            logic.loadMore();
                          }
                          return JmComicTile(logic.folder!.comics[index]);
                        },
                        childCount: logic.folder!.comics.length
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: comicTileMaxWidth,
                      childAspectRatio: comicTileAspectRatio,
                    ),
                  ),
                  if(logic.folder!.total > logic.folder!.loadedComics)
                    const SliverToBoxAdapter(
                      child: ListLoadingIndicator(),
                    )
                ],
              ))
            ],
          ),
        );
      }
    });
  }

  Widget buildFolderSelector(BuildContext context, JmFavoritePageLogic logic, bool loading){
    return SizedBox(
      height: 72,
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 5),
            padding: const EdgeInsets.all(5),
            width: MediaQuery.of(context).size.width - 120 > 400 ? 400 : MediaQuery.of(context).size.width - 120,
            height: 50,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.all(Radius.circular(16))
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text("  收藏夹:  ".tr),
                Text(logic.folderName),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down_sharp),
                  onPressed: (){
                    if(loading){
                      showMessage(context, "加载中".tr);
                      return;
                    }
                    showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(280, 150, MediaQuery.of(context).size.width-280, MediaQuery.of(context).size.height-150),
                        items: [
                          PopupMenuItem(
                            child: Text("全部".tr),
                            onTap: (){
                              if(logic.folderId != "0"){
                                logic.folderId = "0";
                                logic.folderName = "全部".tr;
                                logic.refresh_();
                              }
                            },
                          ),
                          for(var folder in logic.folders.entries)
                            PopupMenuItem(
                              child: Text(folder.value),
                              onTap: (){
                                if(logic.folderId != folder.key){
                                  logic.folderId = folder.key;
                                  logic.folderName = folder.value;
                                  logic.refresh_();
                                }
                              },
                            )
                        ]
                    );
                  },
                )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: IconButton(
              icon: const Icon(Icons.add_box_outlined),
              onPressed: (){
                showDialog(context: context, builder: (context){
                  return const CreateFolderDialog();
                });
              },
            ),
          ),
          const SizedBox(width: 5,),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: (){
                if(logic.folderId == "0"){
                  showMessage(context, "不可删除全部收藏".tr);
                  return;
                }
                showDialog(context: context, builder: (context){
                  return AlertDialog(
                    title: Text("确认删除".tr),
                    content: Text("要删除这个收藏夹吗(删除操作存在延迟, 暂时不知道原因)".tr),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text("取消")),
                      TextButton(onPressed: () async{
                        Get.back();
                        showMessage(context, "正在删除收藏夹".tr);
                        var res = await jmNetwork.deleteFolder(logic.folderId);
                        showMessage(Get.context, res.error?res.errorMessage!:"删除成功".tr);
                        if(! res.error){
                          logic.folderId = "0";
                          logic.folderName = "全部".tr;
                          logic.refresh_();
                        }
                      }, child: Text("确认".tr)),
                    ],
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CreateFolderDialog extends StatefulWidget {
  const CreateFolderDialog({Key? key}) : super(key: key);

  @override
  State<CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<CreateFolderDialog> {
  var controller = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("创建收藏夹".tr),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "名称".tr,
            ),
          ),
        ),
        const SizedBox(
          width: 200,
          height: 10,
        ),
        if(loading)
          const SizedBox(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
            height: 35,
            child: Center(
              child: TextButton(onPressed: (){
                setState(() {
                  loading = true;
                });
                jmNetwork.createFolder(controller.text).then((b){
                  if(b.error){
                    showMessage(context, b.errorMessage!);
                    setState(() {
                      loading = false;
                    });
                  }else{
                    Get.back();
                    showMessage(context, "成功创建".tr);
                    Get.find<JmFavoritePageLogic>().refresh_();
                  }
                });
              }, child: Text("提交".tr)),
            )
          )
      ],
    );
  }
}
