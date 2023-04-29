import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/jm_views/jm_category_page.dart';
import 'package:pica_comic/views/jm_views/jm_widgets.dart';
import 'package:pica_comic/views/jm_views/promote_list_page.dart';
import 'package:pica_comic/views/jm_views/show_error.dart';
import 'package:pica_comic/jm_network/jm_models.dart';

class JmHomePageLogic extends GetxController {
  bool loading = true;
  HomePageData? data;
  String? message;

  void change() {
    loading = !loading;
    update();
  }

  void getData() async {
    var res = await jmNetwork.getHomePage();
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
    return GetBuilder<JmHomePageLogic>(
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
          return showNetworkError(logic.message!, logic.refresh_, context, showBack: false);
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton(
                    onPressed: (){
                      if(item.category){
                        Get.to(()=>JmCategoryPage(Category(item.name, item.id, []), fromHomePage: true,));
                      }else{
                        Get.to(() => JmPromoteListPage(item.name, item.id));
                      }
                    },
                    child: const Text("查看更多"))
              ],
            ),
          ),
        ),
      ),
      SliverGrid(
        delegate: SliverChildBuilderDelegate((context, index) {
          return JmComicTile(item.comics[index]);
        }, childCount: item.comics.length),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: comicTileMaxWidth,
          childAspectRatio: comicTileAspectRatio,
        ),
      ),
      const SliverToBoxAdapter(
        child: Divider(),
      )
    ];
  }
}
