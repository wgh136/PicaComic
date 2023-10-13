import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/widgets/appbar.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/loading.dart';
import '../../foundation/app.dart';
import 'jm_widgets.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';

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
    if(!res.error){
      list = res.data;
    }else{
      message = res.errorMessage;
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
                CustomSliverAppbar(
                  title: Text(title),
                  centerTitle: true,
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
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: App.comicTileMaxWidth,
                    childAspectRatio: App.comicTileAspectRatio,
                  ),
                ),
                if(logic.list!.total > logic.list!.loaded)
                  const SliverToBoxAdapter(
                    child: ListLoadingIndicator(),
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
