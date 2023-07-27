import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../base.dart';
import 'jm_widgets.dart';
import 'package:pica_comic/tools/translations.dart';

class JWRPLogic extends GetxController{
  bool loading = true;
  Map<String, String>? rec;
  String? message;
  String currentName = "";
  String currentId = "";

  void change(){
    loading = !loading;
    update();
  }

  void get() async{
    rec = null;
    message = null;
    var res = await JmNetwork().getWeekRecommendation();
    if(res.error){
      message = res.errorMessage;
    }else{
      rec = res.data;
      currentName = rec!.values.first;
      currentId = rec!.keys.first;
    }
    loading = false;
    update();
  }

}

class JmWeekRecommendationPage extends StatelessWidget {
  JmWeekRecommendationPage({Key? key}) : super(key: key);
  final logic = Get.put(JWRPLogic());

  @override
  Widget build(BuildContext context) {
    var key = GlobalKey();
    const titleLength = 190;
    return Scaffold(
      appBar: AppBar(
        title: Text("每周必看".tl),
        actions: [
          GetBuilder<JWRPLogic>(builder: (logic)=>Container(
            key: key,
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.all(5),
            width: MediaQuery.of(context).size.width>250+titleLength?250:MediaQuery.of(context).size.width-titleLength,
            height: 40,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.all(Radius.circular(16))
            ),
            child: Row(
              children: [
                const SizedBox(width: 8,),
                Expanded(child: Text(logic.currentName, maxLines: 1, overflow: TextOverflow.ellipsis,),),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down_sharp),
                  iconSize: 16,
                  onPressed: (){
                    if(logic.rec == null) return;
                    var renderObject = key.currentContext!.findRenderObject() as RenderBox;
                    var offset = renderObject.localToGlobal(Offset.zero);
                    offset = Offset(offset.dx+246, offset.dy+53);
                    showMenu(
                        constraints: BoxConstraints(
                            maxHeight: 300,
                            minWidth: (MediaQuery.of(context).size.width > 250 ? 250 : MediaQuery.of(context).size.width)-16
                        ),
                        context: context,
                        position: RelativeRect.fromLTRB(offset.dx, offset.dy, MediaQuery.of(context).size.width-offset.dx, MediaQuery.of(context).size.height-offset.dy),
                        items: [
                          for(var item in logic.rec!.entries)
                            PopupMenuItem(
                              child: Text(item.value),
                              onTap: (){
                                logic.currentId = item.key;
                                logic.currentName = item.value;
                                logic.update();
                              },
                            )
                        ]
                    );
                  },
                ),
              ],
            ),
          ))
        ],
      ),
      body: GetBuilder<JWRPLogic>(
        builder: (logic){
          if(logic.loading){
            logic.get();
            return const Center(
              child: CircularProgressIndicator(),
            );
          }else if(logic.message != null){
            return showNetworkError(logic.message!, () {
              logic.change();
              logic.get();
            }, context);
          }else{
            return WeekRecommendationList(logic.currentId, key: Key(logic.currentId),);
          }
        },
      ),
    );
  }
}

class WRLLogic extends GetxController{
  var comics = <List<JmComicBrief>>[[],[],[]];
  var messages = <String?>[null, null, null];
  var loading = <bool>[true, true, true];
  
  void get(int index, String id) async{
    var res = await JmNetwork().getWeekRecommendationComics(id, WeekRecommendationType.values[index]);
    if(res.error){
      messages[index] = res.errorMessage;
    }else{
      comics[index] = res.data;
    }
    loading[index] = false;
    update();
  }
  
  void retry(int index, String id){
    loading[index] = true;
    messages[index] = null;
    update();
    get(index, id);
  }
}

class WeekRecommendationList extends StatelessWidget {
  const WeekRecommendationList(this.id, {Key? key}) : super(key: key);
  final String id;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 3, child: Column(
      children: [
        TabBar(tabs: [
          Tab(text: "韩漫".tl,),
          Tab(text: "日漫".tl,),
          Tab(text: "其它".tl,)
        ]),
        Expanded(child: GetBuilder<WRLLogic>(
            init: WRLLogic(),
            tag: id,
            builder: (logic){
              return TabBarView(children: [
                for(int i=0;i<=2;i++)
                  buildPage(i, logic, context)
              ]);
            }))
      ],
    ));
  }
  
  Widget buildPage(int index, WRLLogic logic, BuildContext context){
    if(logic.loading[index]){
      logic.get(index, id);
      return const Center(
        child: CircularProgressIndicator(),
      );
    }else if(logic.comics[index].isEmpty){
      return showNetworkError(logic.messages[index]??"未知错误".tl, ()=>logic.retry(index, id), context);
    }else{
      return CustomScrollView(
        slivers: [
          SliverGrid(
            delegate: SliverChildBuilderDelegate(
                    (context, i){
                  return JmComicTile(logic.comics[index][i]);
                },
                childCount: logic.comics[index].length
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: comicTileMaxWidth,
              childAspectRatio: comicTileAspectRatio,
            ),
          ),
        ],
      );
    }
  }
}
