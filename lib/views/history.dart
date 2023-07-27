import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/eh_network/eh_models.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_models.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/network/picacg_network/models.dart';
import 'package:pica_comic/tools/time.dart';
import 'package:pica_comic/views/hitomi_views/hitomi_comic_page.dart';
import 'package:pica_comic/views/ht_views/ht_comic_page.dart';
import 'package:pica_comic/views/jm_views/jm_comic_page.dart';
import 'package:pica_comic/views/pic_views/comic_page.dart';
import 'package:pica_comic/views/eh_views/eh_gallery_page.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:pica_comic/views/widgets/normal_comic_tile.dart';
import '../base.dart';
import '../network/jm_network/jm_image.dart';
import 'package:pica_comic/tools/translations.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  var comics = <NewHistory>[];
  bool status = true;
  
  @override
  void dispose() {
    appdata.history.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(status){
      status = false;
      appdata.history.readData().then((v){
        setState(() {
          for(var c in appdata.history.history){
            comics.add(c);
          }
        });
      });
    }
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              centerTitle: true,
              title: Text("${"历史记录".tl}(${comics.length})"),
              actions: [
                Tooltip(
                  message: "清除".tl,
                  child: IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: ()=>showDialog(context: context, builder: (dialogContext)=>AlertDialog(
                      title: Text("清除记录".tl),
                      content: Text("要清除历史记录吗?".tl),
                      actions: [
                        TextButton(onPressed: ()=>Get.back(), child: Text("取消".tl)),
                        TextButton(onPressed: (){
                          appdata.history.clearHistory();
                          setState(()=>comics.clear());
                          Get.back();
                        }, child: Text("清除".tl)),
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
                        comics[i].cover!=""?comics[i].cover:getJmCoverUrl(comics[i].target),
                        comics[i].target,
                        [],
                        ignoreExamination: true
                    );
                    return NormalComicTile(
                      key: Key(comics[i].target),
                      onLongTap: (){
                        showDialog(context: context, builder: (context){
                          return AlertDialog(
                            title: Text("删除".tl),
                            content: Text("要删除这条历史记录吗".tl),
                            actions: [
                              TextButton(onPressed: ()=>Get.back(), child: Text("取消".tl)),
                              TextButton(onPressed: (){
                                appdata.history.remove(comics[i].target);
                                setState(() {
                                  comics.removeAt(i);
                                });
                                Get.back();
                              }, child: Text("删除".tl)),
                            ],
                          );
                        });
                      },
                      description_: timeToString(comics[i].time),
                      coverPath: comic.path,
                      name: comic.title,
                      subTitle_: comic.author,
                      onTap: (){
                        if(comics[i].type == HistoryType.picacg){
                          Get.to(()=>PicacgComicPage(comic));
                        }else if(comics[i].type == HistoryType.ehentai){
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
                        }else if(comics[i].type == HistoryType.jmComic){
                          Get.to(()=>JmComicPage(comics[i].target));
                        }else if(comics[i].type == HistoryType.hitomi){
                          Get.to(()=>HitomiComicPage(HitomiComicBrief(
                            comics[i].title,
                            "",
                            "",
                            [],
                            "",
                            "",
                            comics[i].target,
                            comics[i].cover
                          )));
                        }else{
                          Get.to(() => HtComicPage(HtComicBrief(
                            comics[i].title,
                            "",
                            comics[i].cover,
                            comics[i].target,
                            0
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

