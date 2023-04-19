import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/jm_network/jm_models.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import '../../base.dart';
import 'jm_widgets.dart';

class JmPromoteListPageLogic extends GetxController{
  bool loading = true;
  String? message;

  PromoteList? list;

  void change(){
    loading = !loading;
    update();
  }

  void refresh_(){
    message = null;
    list = null;
    change();
  }

  void load(String id) async{
    var res = await jmNetwork.getPromoteList(id);
    if(res.error == null){
      list = res.data;
    }else{
      message = res.error;
    }
    change();
  }

  void loadMore() async{
    await jmNetwork.loadMorePromoteListComics(list!);
    update();
  }
}

class JmPromoteListPage extends StatelessWidget {
  const JmPromoteListPage(this.title, this.id, {Key? key}) : super(key: key);
  final String title;
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<JmPromoteListPageLogic>(
        init: JmPromoteListPageLogic(),
        builder: (logic){
          if(logic.loading){
            logic.load(id);
            return showLoading(context);
          }else if(logic.list!=null){
            return CustomScrollView(
              slivers: [
                SliverAppBar.large(
                  title: Text(title),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index){
                      if(index == logic.list!.loaded-1){
                        logic.loadMore();
                      }
                      return JmComicTile(logic.list!.comics[index]);
                    },
                    childCount: logic.list!.comics.length
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                if(logic.list!.total > logic.list!.loaded)
                  const SliverToBoxAdapter(
                    child: SizedBox(
                      height: 80,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
              ],
            );
          }else{
            return showNetworkError(logic.message!, logic.refresh_, context);
          }
        },
      ),
    );
  }
}
