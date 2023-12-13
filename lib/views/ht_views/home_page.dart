import 'package:flutter/material.dart';
import 'package:pica_comic/network/htmanga_network/htmanga_main_network.dart';
import 'package:pica_comic/network/htmanga_network/models.dart';
import 'package:pica_comic/views/ht_views/ht_comic_list.dart';
import 'package:pica_comic/views/ht_views/ht_comic_tile.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/tools/translations.dart';
import '../../foundation/app.dart';
import '../widgets/grid_view_delegate.dart';

class HtHomePageLogic extends StateController {
  bool loading = true;
  HtHomePageData? data;
  String? message;

  void get() async {
    var res = await HtmangaNetwork().getHomePage();
    if (res.error) {
      message = res.errorMessage;
    } else {
      data = res.data;
    }
    loading = false;
    update();
  }

  void refresh_() {
    loading = true;
    data = null;
    message = null;
    update();
  }
}

class HtHomePage extends StatelessWidget {
  const HtHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return StateBuilder<HtHomePageLogic>(
      builder: (logic) {
        if (logic.loading) {
          logic.get();
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (logic.data == null) {
          return showNetworkError(logic.message, logic.refresh_, context, showBack: false);
        } else {
          var slivers = <Widget>[];
          for (int i = 0; i < logic.data!.comics.length; i++) {
            slivers.add(SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
                  child: Row(
                    children: [
                      Text(
                        logic.data!.links.keys.elementAt(i),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      TextButton(
                          onPressed: () => MainPage.to(() => HtComicList(
                              name: logic.data!.links.keys.elementAt(i),
                              url: logic.data!.links.values.elementAt(i),
                              addDomain: false,)),
                          child: Text("查看更多".tl)),
                    ],
                  ),
                ),
              ),
            ));
            slivers.add(
              SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return HtComicTile(comic: logic.data!.comics[i][index]);
                }, childCount: logic.data!.comics[i].length),
                gridDelegate: const SliverGridDelegateWithComics(),
              ),
            );
          }
          return CustomScrollView(
            slivers: slivers,
          );
        }
      },
    );
  }
}
