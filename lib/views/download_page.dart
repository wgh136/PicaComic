import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/comic_page.dart';
import 'package:pica_comic/views/downloading_page.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

import '../network/download_models.dart';

class DownloadPageLogic extends GetxController{
  bool loading = true;
  bool selecting = false;
  int selectedNum = 0;
  var selected = <bool>[];
  var comics = <DownloadItem>[];
  void change(){
    loading = !loading;
    update();
  }
  void fresh(){
    selecting = false;
    selectedNum = 0;
    selected.clear();
    comics.clear();
    change();
  }
}

class DownloadPage extends StatelessWidget {
  DownloadPage({Key? key}) : super(key: key);
  final logic = Get.put(DownloadPageLogic());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadPageLogic>(
        builder: (logic){
          if(logic.loading){
            getComics(logic.comics).then((v){
              for(var i=0;i<logic.comics.length;i++) {
                logic.selected.add(false);
              }
              logic.change();
            });
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }else{
            return Scaffold(
              appBar: AppBar(
                leading: logic.selecting?IconButton(onPressed: (){
                  logic.selecting = false;
                  logic.selectedNum = 0;
                  for(int i=0;i<logic.selected.length;i++){
                    logic.selected[i] = false;
                  }
                  logic.update();
                }, icon: const Icon(Icons.close)):
                  IconButton(onPressed: (){Get.back();}, icon: const Icon(Icons.arrow_back)),
                backgroundColor: logic.selecting?Theme.of(context).colorScheme.secondaryContainer:null,
                title: logic.selecting?Text("已选择${logic.selectedNum}个项目"):const Text("已下载"),
                actions: [
                  if(!logic.selecting)
                  Tooltip(
                    message: "下载管理器",
                    child: IconButton(
                      icon: const Icon(Icons.download_for_offline),
                      onPressed: (){
                        Get.to(()=>const DownloadingPage());
                      },
                    ),
                  )
                ],
              ),
              floatingActionButton: FloatingActionButton(
                heroTag: UniqueKey(),
                onPressed: (){
                  if(!logic.selecting) {
                    logic.selecting = true;
                    logic.update();
                  }else{
                    if(logic.selectedNum==0)  return;
                    showDialog(context: context, builder: (dialogContext){
                      return AlertDialog(
                        title: const Text("删除"),
                        content: Text("要删除已选择的${logic.selectedNum}项吗? 此操作无法撤销"),
                        actions: [
                          TextButton(onPressed: (){Get.back();}, child: const Text("取消")),
                          TextButton(onPressed: () async{
                            Get.back();
                            var comics = <String>[];
                            for(int i = 0;i<logic.selected.length;i++){
                              if(logic.selected[i]){
                                comics.add(logic.comics[i].comicItem.id);
                              }
                            }
                            await downloadManager.delete(comics);
                            logic.comics.clear();
                            logic.selected.clear();
                            logic.selectedNum = 0;
                            logic.selecting = false;
                            logic.loading = true;
                            logic.update();
                          }, child: const Text("确认")),
                        ],
                      );
                    });
                  }
                },
                child: logic.selecting?const Icon(Icons.delete_forever_outlined):const Icon(Icons.checklist_outlined),
              ),
              body: CustomScrollView(
                slivers: [
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                          (context, index){
                        var size = logic.comics[index].size;
                        String? s;
                        if(size!=null) {
                          s = size.toStringAsFixed(2);
                        }
                        return GestureDetector(
                            onSecondaryTapUp: (details){
                              showMenu(
                                  context: context,
                                  position: RelativeRect.fromLTRB(details.globalPosition.dx,details.globalPosition.dy,details.globalPosition.dx,details.globalPosition.dy),
                                  items: [
                                    PopupMenuItem(
                                      child: const Text("删除"),
                                      onTap: (){
                                        downloadManager.delete([logic.comics[index].comicItem.id]);
                                        logic.comics.removeAt(index);
                                        logic.selected.removeAt(index);
                                        logic.update();
                                      },
                                    )
                                  ]
                              );
                            },
                            onLongPressUp: (){
                              if(logic.selecting) return;
                              logic.selected[index] = true;
                              logic.selectedNum++;
                              logic.selecting = true;
                              logic.update();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                  color: logic.selected[index]?const Color.fromARGB(100, 121, 125, 127):Colors.transparent
                              ),
                              child: ComicTile(logic.comics[index].comicItem.toBrief(),onTap: (){
                                if(logic.selecting){
                                  logic.selected[index] = !logic.selected[index];
                                  logic.selected[index]?logic.selectedNum++:logic.selectedNum--;
                                  if(logic.selectedNum==0){
                                    logic.selecting = false;
                                  }
                                  logic.update();
                                }else{
                                  Get.to(()=>ComicPage(logic.comics[index].comicItem.toBrief(),downloaded: true,));
                                }
                              },size: s,),
                            )
                        );
                      },
                      childCount: logic.comics.length,
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 600,
                      childAspectRatio: 3.5,
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
                ],
              )
            );
          }
        }
    );
  }
}

Future<void> getComics(List<DownloadItem> comics) async{
  for(var index=0;index<downloadManager.downloaded.length;index++){
    comics.add(await downloadManager.getComic(index));
  }
}
