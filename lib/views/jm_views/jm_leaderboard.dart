import 'package:flutter/material.dart';
import 'package:pica_comic/network/jm_network/jm_main_network.dart';
import 'package:pica_comic/network/jm_network/jm_models.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../foundation/app.dart';
import '../widgets/list_loading.dart';
import 'jm_widgets.dart';
import 'package:pica_comic/tools/translations.dart';

class CategoryPageLogic extends StateController{
  bool loading = true;
  CategoryComicsRes? comics;
  String? message;

  void change(){
    loading = !loading;
    update();
  }

  void get(Category category, ComicsOrder order) async{
    var res = await jmNetwork.getCategoryComics(category.slug, order);
    if(res.error){
      message = res.errorMessage;
      change();
    }else{
      comics = res.data;
      change();
    }
  }

  void refresh_(){
    comics = null;
    message = null;
    loading = true;
    update();
  }

  void loadMore() async{
    await jmNetwork.getCategoriesComicNextPage(comics!);
    update();
  }
}

void createLogic(){
  StateController.put(CategoryPageLogic(), tag: "mv");
  StateController.put(CategoryPageLogic(), tag: "mv_m");
  StateController.put(CategoryPageLogic(), tag: "mv_w");
  StateController.put(CategoryPageLogic(), tag: "mv_t");
}

void disposeLogic(){
  StateController.remove<CategoryPageLogic>();
  StateController.remove<CategoryPageLogic>();
  StateController.remove<CategoryPageLogic>();
  StateController.remove<CategoryPageLogic>();
}

class JmLeaderboardPage extends StatelessWidget {
  const JmLeaderboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 4, child: Column(
      children: [
        TabBar(
            splashBorderRadius: const BorderRadius.all(Radius.circular(10)),
            tabs: [
              Tab(text: "总排行".tl),
              Tab(text: "月排行".tl),
              Tab(text: "周排行".tl),
              Tab(text: "日排行".tl),
            ]),
        const Expanded(child: TabBarView(
            children: [
              OneJmLeaderboardPage(ComicsOrder.totalRanking),
              OneJmLeaderboardPage(ComicsOrder.monthRanking),
              OneJmLeaderboardPage(ComicsOrder.weekRanking),
              OneJmLeaderboardPage(ComicsOrder.dayRanking),
            ]
        ),)
      ],
    ));
  }
}

class OneJmLeaderboardPage extends StatelessWidget{
  const OneJmLeaderboardPage(this.order,{super.key});
  final ComicsOrder order;

  @override
  Widget build(BuildContext context) {
    final category = Category("", "0", []);
    return StateBuilder<CategoryPageLogic>(
      tag: order.toString(),
      builder: (logic){
        if(logic.loading){
          logic.get(category, order);
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.comics != null){
          return CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate(
                        (context, index){
                      if(index == logic.comics!.comics.length-1){
                        logic.loadMore();
                      }
                      return JmComicTile(logic.comics!.comics[index]);
                    },
                    childCount: logic.comics!.comics.length
                ),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: App.comicTileMaxWidth,
                  childAspectRatio: App.comicTileAspectRatio,
                ),
              ),
              if(logic.comics!.loaded < logic.comics!.total)
                const SliverToBoxAdapter(
                  child: ListLoadingIndicator(),
                )
            ],
          );
        }else{
          return showNetworkError(logic.message!, logic.refresh_, context, showBack: false);
        }
      },
    );
  }
}
