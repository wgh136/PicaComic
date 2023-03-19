import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/models/history.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  var comics = <HistoryItem>[];
  bool status = true;

  @override
  void dispose() {
    //清除数据避免历史记录过多, 减少内存占用
    appdata.history.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(status){
      status = false;
      appdata.readHistory().then((v){
        setState(() {
          for(var c in appdata.history){
            comics.add(c);
          }
          appdata.history.clear();
        });
      });
    }
    return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              centerTitle: true,
              title: const Text("历史记录"),
              actions: [
                Tooltip(
                  message: "清除",
                  child: IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: (){
                      setState(() {
                        appdata.history.clear();
                        comics.clear();
                        appdata.saveHistory();
                      });
                    },
                  ),
                ),
              ],
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: comics.length,
                      (context, index){
                    var i = comics.length-index-1;
                    return ComicTile(
                      ComicItemBrief(
                          comics[i].title,
                          comics[i].author,
                          0,
                          comics[i].cover,
                          comics[i].id
                      ),
                      time: "${comics[i].time.year}-${comics[i].time.month}-${comics[i].time.day} ${comics[i].time.hour}:${comics[i].time.minute}"
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

