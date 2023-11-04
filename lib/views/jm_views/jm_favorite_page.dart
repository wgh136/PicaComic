import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../network/jm_network/jm_main_network.dart';
import '../../network/jm_network/jm_models.dart';
import '../main_page.dart';
import '../widgets/my_icons.dart';
import '../widgets/show_message.dart';
import 'package:pica_comic/tools/translations.dart';

class JmFavoritePageLogic extends StateController {
  bool loading = true;

  Map<String, String> folders = {};

  String? message;

  void get() async {
    var r = await jmNetwork.getFolders();
    if (r.error) {
      message = r.errorMessage;
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
    return StateBuilder<JmFavoritePageLogic>(
      builder: (logic) {
        if (logic.loading) {
          logic.get();
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (logic.message != null) {
          return showNetworkError(logic.message!, logic.refresh_, context,
              showBack: false);
        } else {
          return CustomScrollView(
            slivers: [
              SliverGridViewWithFixedItemHeight(
                delegate: SliverChildBuilderDelegate(
                    childCount: logic.folders.length + 1, (context, i) {
                  if (i == 0) {
                    return JmFolderTile(
                        name: "全部",
                        id: "0",
                        onTap: () => MainPage.to(() =>
                            const JmFavoriteFolder(folderId: "0", name: "全部")));
                  } else {
                    i--;
                  }
                  return JmFolderTile(
                      name: logic.folders.values.elementAt(i),
                      id: logic.folders.keys.elementAt(i),
                      onTap: () => MainPage.to(() => JmFavoriteFolder(
                          folderId: logic.folders.keys.elementAt(i),
                          name: logic.folders.values.elementAt(i))));
                }),
                maxCrossAxisExtent: 500,
                itemHeight: 56,
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: Center(
                    child: TextButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("创建收藏夹".tl),
                          const Icon(
                            Icons.add,
                            size: 18,
                          ),
                        ],
                      ),
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return const CreateFolderDialog();
                            });
                      },
                    ),
                  ),
                ),
              )
            ],
          );
        }
      },
    );
  }
}

class JmFolderTile extends StatelessWidget {
  const JmFolderTile(
      {required this.name, required this.onTap, required this.id, super.key});

  final String name;

  final String id;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              if (id != "0")
                const SizedBox(
                  width: 2.5,
                ),
              Expanded(
                flex: 1,
                child: Icon(
                  MyIcons.jmFolder,
                  size: 35,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(
                width: 16,
              ),
              if (id != "0")
                const SizedBox(
                  width: 2.5,
                ),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (id != "0")
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text("确认删除".tl),
                            content: Text("要删除这个收藏夹吗".tl),
                            actions: [
                              TextButton(
                                  onPressed: () => App.globalBack(),
                                  child: const Text("取消")),
                              TextButton(
                                  onPressed: () async {
                                    App.globalBack();
                                    showMessage(context, "正在删除收藏夹".tl);
                                    var res = await jmNetwork.deleteFolder(id);
                                    showMessage(
                                        App.globalContext,
                                        res.error
                                            ? res.errorMessage!
                                            : "删除成功".tl);
                                    if (!res.error) {
                                      StateController.find<
                                              JmFavoritePageLogic>()
                                          .refresh_();
                                    } else {
                                      showMessage(
                                          App.globalContext,
                                          res.error
                                              ? res.errorMessage!
                                              : "删除失败".tl);
                                    }
                                  },
                                  child: Text("确认".tl)),
                            ],
                          );
                        });
                  },
                )
              else
                const Icon(Icons.arrow_right),
              if (id == "0")
                const SizedBox(
                  width: 5,
                )
            ],
          ),
        ),
      ),
    );
  }
}

class JmFavoriteFolder extends ComicsPage<JmComicBrief> {
  const JmFavoriteFolder(
      {required this.folderId, required this.name, super.key});

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
      title: Text("创建收藏夹".tl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "名称".tl,
            ),
          ),
        ),
        const SizedBox(
          width: 200,
          height: 10,
        ),
        if (loading)
          const SizedBox(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
              height: 35,
              child: Center(
                child: TextButton(
                    onPressed: () {
                      setState(() {
                        loading = true;
                      });
                      jmNetwork.createFolder(controller.text).then((b) {
                        if (b.error) {
                          showMessage(context, b.errorMessage!);
                          setState(() {
                            loading = false;
                          });
                        } else {
                          App.globalBack();
                          showMessage(context, "成功创建".tl);
                          StateController.find<JmFavoritePageLogic>()
                              .refresh_();
                        }
                      });
                    },
                    child: Text("提交".tl)),
              ))
      ],
    );
  }
}
