import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/eh_network/get_gallery_id.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/network/new_download_model.dart';
import 'package:pica_comic/tools/io_tools.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/downloading_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import 'package:pica_comic/views/widgets/widgets.dart';

class DownloadPageLogic extends GetxController{
  ///是否正在加载
  bool loading = true;
  ///是否处于选择状态
  bool selecting = false;
  ///已选择的数量
  int selectedNum = 0;
  ///已选择的漫画
  var selected = <List<bool>>[[],[]];
  ///已下载的漫画
  var comics = <DownloadedComic>[];

  ///已下载的画廊
  var galleries = <DownloadedGallery>[];

  void change(){
    loading = !loading;
    update();
  }

  void fresh(){
    selecting = false;
    selectedNum = 0;
    selected[0].clear();
    selected[1].clear();
    comics.clear();
    galleries.clear();
    change();
  }
}

class DownloadPage extends StatelessWidget {
  const DownloadPage({this.noNetwork = false, Key? key}) : super(key: key);
  ///无网络时直接跳过漫画详情页的加载
  final bool noNetwork;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<DownloadPageLogic>(
      init: DownloadPageLogic(),
      builder: (logic){
        if(logic.loading){
          getComics(logic.comics, logic.galleries).then((v){
            for(var i=0;i<logic.comics.length;i++) {
              logic.selected[0].add(false);
            }
            for(var i=0;i<logic.galleries.length;i++){
              logic.selected[1].add(false);
            }
            logic.change();
          });
          return showLoading(context,withScaffold: true);
        }else{
          return Scaffold(
            appBar: AppBar(
              leading: logic.selecting?IconButton(onPressed: (){
                logic.selecting = false;
                logic.selectedNum = 0;
                for(int i=0;i<logic.selected[0].length;i++){
                  logic.selected[0][i] = false;
                }
                for(int i=0;i<logic.selected[1].length;i++){
                  logic.selected[1][i] = false;
                }
                logic.update();
              }, icon: const Icon(Icons.close)):
              IconButton(onPressed: ()=>Get.back(), icon: const Icon(Icons.arrow_back)),
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
                else
                  Tooltip(
                    message: "更多",
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz),
                      onPressed: (){
                        showMenu(context: context,
                            position: RelativeRect.fromLTRB(
                                MediaQuery.of(context).size.width-60, 50,
                                MediaQuery.of(context).size.width-60, 50),
                            items: [
                              PopupMenuItem(
                                child: const Text("全选"),
                                onTap: (){
                                  for(int i=0;i<logic.selected[0].length;i++){
                                    logic.selected[0][i] = true;
                                    logic.selectedNum++;
                                  }
                                  for(int i=0;i<logic.selected[1].length;i++){
                                    logic.selected[1][i] = true;
                                    logic.selectedNum++;
                                  }
                                  logic.update();
                                },
                              ),
                              PopupMenuItem(
                                child: const Text("导出"),
                                onTap: (){
                                  if(logic.selectedNum == 0){
                                    showMessage(context, "请选择漫画");
                                  }else if(logic.selectedNum>1){
                                    showMessage(context, "一次只能导出一部漫画");
                                  }else{
                                    Future<void>.delayed(
                                      const Duration(milliseconds: 200),
                                          () => showDialog(
                                        context: context,
                                        barrierColor: Colors.black26,
                                        builder: (context) => const SimpleDialog(
                                          children: [
                                            SizedBox(
                                              width: 200,
                                              height: 200,
                                              child: Center(
                                                child: Text("打包中...", style: TextStyle(fontSize: 16),),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    );
                                    Future<void>.delayed(
                                        const Duration(milliseconds: 500),
                                            ()=>export(logic)
                                    );
                                  }
                                },
                              )
                            ]
                        );
                      },
                    ),
                  ),
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
                        TextButton(onPressed: ()=>Get.back(), child: const Text("取消")),
                        TextButton(onPressed: () async{
                          Get.back();
                          var comics = <String>[];
                          for(int i = 0;i<logic.selected[0].length;i++){
                            if(logic.selected[0][i]){
                              comics.add(logic.comics[i].comicItem.id);
                            }
                          }
                          for(int i = 0;i<logic.selected[1].length;i++){
                            if(logic.selected[1][i]){
                              comics.add(getGalleryId(logic.galleries[i].gallery.link));
                            }
                          }
                          await downloadManager.delete(comics);
                          logic.fresh();
                        }, child: const Text("确认")),
                      ],
                    );
                  });
                }
              },
              child: logic.selecting?const Icon(Icons.delete_forever_outlined):const Icon(Icons.checklist_outlined),
            ),
            body: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                      splashBorderRadius: BorderRadius.all(Radius.circular(10)),
                    tabs: [
                      Tab(text: "Picacg",),
                      Tab(text: "E-Hentai",)
                    ]),
                  Expanded(
                    child: TabBarView(
                      children: [
                        CustomScrollView(
                          slivers: [
                            SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                  childCount: logic.comics.length,
                                  (context, index){
                                    var size = logic.comics[index].size;
                                    String? s;
                                    if(size!=null) {
                                      s = size.toStringAsFixed(2);
                                    }
                                    return buildItem(
                                        context,
                                        logic.comics[index].comicItem.id,
                                        0,
                                        index,
                                        logic,
                                        logic.comics[index].comicItem.title,
                                        logic.comics[index].comicItem.author,
                                        s??"未知"
                                    );
                                  }
                              ),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: comicTileMaxWidth,
                                childAspectRatio: comicTileAspectRatio,
                              ),

                            )
                          ],
                        ),
                        CustomScrollView(
                          slivers: [
                            SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                  childCount: logic.galleries.length,
                                      (context, index){
                                    var size = logic.galleries[index].size;
                                    String? s;
                                    if(size!=null) {
                                      s = size.toStringAsFixed(2);
                                    }
                                    return buildItem(
                                        context,
                                        getGalleryId(logic.galleries[index].gallery.link),
                                        1,
                                        index,
                                        logic,
                                        logic.galleries[index].gallery.title,
                                        logic.galleries[index].gallery.uploader,
                                        s??"未知"
                                    );
                                  }
                              ),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: comicTileMaxWidth,
                                childAspectRatio: comicTileAspectRatio,
                              ),

                            )
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        }
      }
    );
  }

  Future<void> getComics(List<DownloadedComic> comics, List<DownloadedGallery> galleries) async{
    for(var comic in (downloadManager.downloaded)){
      comics.add(await downloadManager.getComicFromId(comic));
    }

    for(var gallery in (downloadManager.downloadedGalleries)){
      galleries.add(await downloadManager.getGalleryFormId(gallery));
    }
  }

  Future<void> export(DownloadPageLogic logic) async{
    for(int i0 = 0;i0 < logic.selected.length;i0++){
      for(int i1 = 0;i1 < logic.selected[i0].length;i1++){
        if(logic.selected[i0][i1]){
          if(i0 == 0){
            exportComic(logic.comics[i1].comicItem.id);
            return;
          }else if(i0 == 1){
            exportComic(getGalleryId(logic.galleries[i1].gallery.link));
            return;
          }
        }
      }
    }
  }

  Widget buildItem(
      BuildContext context,
      String id,
      int index0,
      int index1,
      DownloadPageLogic logic,
      String title,
      String subTitle,
      String size){
    bool selected = logic.selected[index0][index1];
    return GestureDetector(
        onSecondaryTapUp: (details){
          showMenu(
              context: context,
              position: RelativeRect.fromLTRB(details.globalPosition.dx,details.globalPosition.dy,details.globalPosition.dx,details.globalPosition.dy),
              items: [
                PopupMenuItem(
                  onTap: (){
                    downloadManager.delete([id]);
                    if(index0 == 0){
                      logic.comics.removeAt(index1);
                    }else if(index0 == 1){
                      logic.galleries.removeAt(index1);
                    }
                    logic.selected[index0].removeAt(index1);
                    logic.update();
                  },
                  child: const Text("删除"),
                ),
                PopupMenuItem(
                  child: const Text("导出"),
                  onTap: (){
                    Future<void>.delayed(
                      const Duration(milliseconds: 200),
                          () => showDialog(
                        context: context,
                        barrierColor: Colors.black26,
                        builder: (context) => const SimpleDialog(
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: Center(
                                child: Text("打包中...", style: TextStyle(fontSize: 16),),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                    Future<void>.delayed(
                        const Duration(milliseconds: 500),
                            (){
                          exportComic(id);
                        }
                    );
                  },
                ),
              ]
          );
        },
        child: Container(
          decoration: BoxDecoration(
              color: selected?const Color.fromARGB(100, 121, 125, 127):Colors.transparent
          ),
          child: ComicTile(ComicItemBrief(title,subTitle,0,"",id),
            downloaded: true,
            onTap: () async{
            if(logic.selecting){
              logic.selected[index0][index1] = !logic.selected[index0][index1];
              logic.selected[index0][index1]?logic.selectedNum++:logic.selectedNum--;
              if(logic.selectedNum==0){
                logic.selecting = false;
              }
              logic.update();
            }else{
              if(index0 == 0) {
                Get.to(() => ComicPage(logic.comics[index1].comicItem.toBrief(), downloaded: noNetwork,),preventDuplicates: false);
              }else if(index0 == 1){
                Get.to(() => EhGalleryPage(logic.galleries[index1].gallery.toBrief(), downloaded: noNetwork));
              }
            }
          },
            size: size,
            onLongTap: (){
              if(logic.selecting) return;
              logic.selected[index0][index1] = true;
              logic.selectedNum++;
              logic.selecting = true;
              logic.update();
            },
          ),
        )
    );
  }
}
