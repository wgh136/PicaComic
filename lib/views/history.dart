import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../base.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
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
                        appdata.writeData();
                      });
                    },
                  ),
                ),
              ],
            ),
            SliverGrid(
              delegate: SliverChildBuilderDelegate(
                  childCount: appdata.history.length,
                      (context, i){
                    return ComicTile(appdata.history[appdata.history.length-1-i]);
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

