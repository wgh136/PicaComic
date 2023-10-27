import 'package:flutter/material.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import '../../foundation/app.dart';
import '../../network/picacg_network/models.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import '../widgets/show_message.dart';

class HomePageLogic extends StateController{
  bool isLoading = true;
  String? message;
  var comics = <ComicItemBrief>[];

  void get() async{
    var res = await network.getRandomComics();
    if(res.error){
      if(comics.isEmpty) {
        message = res.errorMessage;
      }else{
        showMessage(App.globalContext, res.errorMessageWithoutNull);
      }
    }else{
      comics.addAll(res.data);
    }
    isLoading = false;
    update();
  }

  void refresh_() async{
    isLoading = true;
    comics.clear();
    message = null;
    update();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<HomePageLogic>(
        builder: (logic){
      if(logic.isLoading){
        logic.get();
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(logic.message == null){
        return Material(
          child: RefreshIndicator(
              child: CustomScrollView(
                slivers: [
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        childCount: logic.comics.length,
                            (context, i){
                          if(i == logic.comics.length-1) {
                            logic.get();
                          }
                          return PicComicTile(logic.comics[i],);
                        }
                    ),
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: App.comicTileMaxWidth,
                      childAspectRatio: App.comicTileAspectRatio,
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: ListLoadingIndicator(),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: MediaQuery.of(App.globalContext!).padding.bottom))
                ],
              ),
              onRefresh: () async {
                logic.refresh_();
              }
          ),
        );
      }else{
        return showNetworkError(logic.message,
                logic.refresh_, context, showBack: false);
      }
    });
  }
}
