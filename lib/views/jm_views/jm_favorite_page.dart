import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import '../widgets/my_icons.dart';
import '../widgets/show_message.dart';

class JmFavoritePageLogic extends GetxController {
  bool loading = true;

  Map<String, String> folders = {};

  String? message;

  void get() async {
    var r = await jmNetwork.getFolders();
    if (r.error) {
      message = r.errorMessage;
      return;
    } else {
      folders = r.data;
    }
    loading = false;
    update();
  }

  void refresh_() {
    loading = true;
    message = null;
    folders.clear();
    update();
    get();
  }
}

class JmFavoritePage extends StatelessWidget {
  const JmFavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<JmFavoritePageLogic>(
      init: JmFavoritePageLogic(),
      builder: (logic) {
        if (logic.loading) {
          logic.get();
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (logic.message != null) {
          return showNetworkError(logic.message!, () => logic.refresh_, context);
        } else {
          return CustomScrollView(
            slivers: [
              SliverGrid(
                delegate:
                    SliverChildBuilderDelegate(childCount: logic.folders.length + 2, (context, i) {
                  if (i == 0) {
                    return JmFolderTile(
                        name: "全部",
                        id: "0",
                        onTap: () =>
                            Get.to(() => const JmFavoriteFolder(folderId: "0", name: "全部")));
                  } else {
                    i--;
                  }
                  if (i != logic.folders.length) {
                    return JmFolderTile(
                        name: logic.folders.values.elementAt(i),
                        id: logic.folders.keys.elementAt(i),
                        onTap: () => Get.to(() => JmFavoriteFolder(
                            folderId: logic.folders.keys.elementAt(i),
                            name: logic.folders.values.elementAt(i))));
                  } else {
                    return Material(
                      child: InkWell(
                        onTap: (){
                          showDialog(context: context, builder: (context){
                            return const CreateFolderDialog();
                          });
                        },
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Icon(
                                  Icons.add_box_outlined,
                                  size: 45,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(
                                width: 16,
                              ),
                              const Expanded(
                                flex: 4,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    "创建收藏夹",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_right),
                              const SizedBox(width: 5,)
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                }),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 550,
                  childAspectRatio: 4,
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class JmFolderTile extends StatelessWidget {
  const JmFolderTile({required this.name, required this.onTap, required this.id, super.key});

  final String name;

  final String id;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              if(id != "0")
                const SizedBox(width: 2.5,),
              Expanded(
                flex: 1,
                child: Icon(
                  MyIcons.jmFolder,
                  size: 45,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              if(id != "0")
                const SizedBox(width: 2.5,),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if(id != "0")
              IconButton(
                icon: const Icon(Icons.delete_forever_outlined),
                onPressed: (){
                  showDialog(context: context, builder: (context){
                    return AlertDialog(
                      title: Text("确认删除".tr),
                      content: Text("要删除这个收藏夹吗(删除操作存在延迟, 暂时不知道原因)".tr),
                      actions: [
                        TextButton(onPressed: () => Get.back(), child: const Text("取消")),
                        TextButton(onPressed: () async{
                          Get.back();
                          showMessage(context, "正在删除收藏夹".tr);
                          var res = await jmNetwork.deleteFolder(id);
                          showMessage(Get.context, res.error?res.errorMessage!:"删除成功".tr);
                          if(! res.error){
                            Get.find<JmFavoritePageLogic>().refresh_();
                          }else{
                            showMessage(Get.context, res.error?res.errorMessage!:"删除失败".tr);
                          }
                        }, child: Text("确认".tr)),
                      ],
                    );
                  });
                },
              )
              else
                const Icon(Icons.arrow_right),
              if(id == "0")
                const SizedBox(width: 5,)
            ],
          ),
        ),
      ),
    );
  }
}

class JmFavoriteFolder extends ComicsPage<JmComicBrief> {
  const JmFavoriteFolder({required this.folderId, required this.name, super.key});

  final String folderId;

  final String name;

  @override
  Future<Res<List<JmComicBrief>>> getComics(int i) {
    return JmNetwork().getFolderComicsPage(folderId, i);
  }

  @override
  String? get tag => "EhFavoritePageFolder $folderId";

  @override
  String get title => name;

  @override
  ComicType get type => ComicType.jm;

  @override
  bool get withScaffold => true;
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