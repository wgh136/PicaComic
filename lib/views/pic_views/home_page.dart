import 'package:flutter/material.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/pic_views/picacg_latest_page.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/pic_views/widgets.dart';
import '../../foundation/app.dart';
import '../../network/picacg_network/models.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import '../widgets/grid_view_delegate.dart';

class HomePageLogic extends StateController{
  bool isLoading = true;
  String? message;
  late List<ComicItemBrief> randomComics;
  late List<ComicItemBrief> latestComics;

  void get() async{
    var futures = await Future.wait([network.getRandomComics(), network.getLatest(1)]);
    var res1 = futures[0];
    var res2 = futures[1];
    if(res1.error || res2.error){
      message = res1.errorMessage ?? res2.errorMessage;
      randomComics = [];
      latestComics = [];
    }else{
      randomComics = res1.data;
      latestComics = res2.data;
    }
    isLoading = false;
    update();
  }

  void refresh_() async{
    isLoading = true;
    randomComics.clear();
    latestComics.clear();
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
                  buildTitle("随机".tl, TextButton(
                      onPressed: () => MainPage.to(() => _PicacgRandomPage()),
                      child: Text("查看更多".tl))),
                  buildComicsList(logic.randomComics),
                  buildTitle("最新".tl, TextButton(
                      onPressed: () => MainPage.to(() => const PicacgLatestPage()),
                      child: Text("查看更多".tl))),
                  buildComicsList(logic.latestComics),
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

  Widget buildComicsList(List<ComicItemBrief> comics){
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
          childCount: comics.length, (context, i){
            return PicComicTile(comics[i],);
          }
      ),
      gridDelegate: SliverGridDelegateWithComics(),
    );
  }

  Widget buildTitle(String title, [Widget? action]){
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 60,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if(action != null)
                action
            ],
          ),
        ),
      ),
    );
  }
}

class _PicacgRandomPage extends ComicsPage<ComicItemBrief>{
  @override
  Future<Res<List<ComicItemBrief>>> getComics(int i) {
    return PicacgNetwork().getRandomComics();
  }

  @override
  String? get tag => "Picacg Random Page";

  @override
  String get title => "随机".tl;

  @override
  ComicType get type => ComicType.picacg;

  @override
  bool get withScaffold => true;
}
