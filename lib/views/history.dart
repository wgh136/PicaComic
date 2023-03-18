import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/models.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
      appdata.readHistory().then((v)=>setState((){}));
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
                        appdata.saveHistory();
                      });
                    },
                  ),
                ),
              ],
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: appdata.history.length,
                      (context, index){
                    var i = appdata.history.length-index-1;
                    return ComicTile(
                      ComicItemBrief(
                          appdata.history[i].title,
                          appdata.history[i].author,
                          0,
                          appdata.history[i].cover,
                          appdata.history[i].id
                      ),
                      time: "${appdata.history[i].time.year}-${appdata.history[i].time.month}-${appdata.history[i].time.day} ${appdata.history[i].time.hour}:${appdata.history[i].time.minute}"
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

