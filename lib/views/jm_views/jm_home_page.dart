import 'package:flutter/material.dart';
import 'package:pica_comic/views/jm_views/jm_comics_page.dart';
import 'package:pica_comic/views/jm_views/jm_widgets.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import '../../foundation/app.dart';
import '../../network/jm_network/jm_network.dart';
import '../../network/jm_network/jm_models.dart';
import 'package:pica_comic/tools/translations.dart';
import '../main_page.dart';

class JmHomePageLogic extends StateController {
  bool loading = true;
  HomePageData? data;
  String? message;

  void change() {
    loading = !loading;
    update();
  }

  void getData() async {
    var res = await JmNetwork().getHomePage();
    if (!res.error) {
      data = res.data;
    } else {
      message = res.errorMessage;
    }
    change();
  }

  void refresh_() {
    data = null;
    message = null;
    loading = true;
    update();
  }
}

class JmHomePage extends StatelessWidget {
  const JmHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StateBuilder<JmHomePageLogic>(
      builder: (logic) {
        if (logic.loading) {
          logic.getData();
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (logic.data != null) {
          return CustomScrollView(
            slivers: [for (var item in logic.data!.items) ...buildItem(item)],
          );
        } else {
          return showNetworkError(logic.message!, logic.refresh_, context,
              showBack: false);
        }
      },
    );
  }

  List<Widget> buildItem(HomePageItem item) {
    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 5, 10),
            child: Row(
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton(
                    onPressed: () {
                      MainPage.to(() => JmComicsPage(item.name, item.id));
                    },
                    child: Text("查看更多".tl))
              ],
            ),
          ),
        ),
      ),
      SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          return JmComicTile(item.comics[index]);
        }, childCount: item.comics.length),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: App.comicTileMaxWidth,
          childAspectRatio: App.comicTileAspectRatio,
        ),
      ),
      const SliverToBoxAdapter(
        child: Divider(),
      )
    ];
  }
}
