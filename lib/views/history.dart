import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/eh_network/eh_models.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  var comics = <NewHistory>[];
  bool status = true;

  @override
  Widget build(BuildContext context) {
    if(status){
      status = false;
      appdata.history.readData().then((v){
        setState(() {
          for(var c in appdata.history.history){
            comics.add(c);
          }
          appdata.history.close();
        });
      });
    }
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              centerTitle: true,
              title: Text("历史记录(${comics.length})"),
              actions: [
                Tooltip(
                  message: "清除",
                  child: IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: ()=>showDialog(context: context, builder: (dialogContext)=>AlertDialog(
                      title: const Text("清除记录"),
                      content: const Text("要清除历史记录吗?"),
                      actions: [
                        TextButton(onPressed: ()=>Get.back(), child: const Text("取消")),
                        TextButton(onPressed: (){
                          appdata.history.clearHistory();
                          setState(()=>comics.clear());
                          Get.back();
                        }, child: const Text("清除")),
                      ],
                    )),
                  ),
                ),
              ],
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: comics.length,
                      (context, i){
                    final comic = ComicItemBrief(
                        comics[i].title,
                        comics[i].subtitle,
                        0,
                        comics[i].cover,
                        comics[i].target
                    );
                    return ComicTile(
                      comic,
                      time: "${comics[i].time.year}-${comics[i].time.month}-${comics[i].time.day} ${comics[i].time.hour}:${comics[i].time.minute}",
                      onTap: (){
                        if(comics[i].type == HistoryType.picacg){
                          Get.to(()=>ComicPage(comic));
                        }else{
                          Get.to(()=>EhGalleryPage(EhGalleryBrief(
                            comics[i].title,
                            "",
                            "",
                            comics[i].subtitle,
                            comics[i].cover,
                            0.0,
                            comics[i].target,
                            []
                          )));
                        }
                      },
                    );
                  }
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: comicTileMaxWidth,
                childAspectRatio: comicTileAspectRatio,
              ),
            ),
            SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
          ],
        )
    );
  }
}

