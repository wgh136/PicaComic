import 'package:flutter/material.dart';
import 'package:pica_comic/network/nhentai_network/nhentai_main_network.dart';
import 'package:get/get.dart';
import 'package:pica_comic/views/nhentai/comic_tile.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import '../../base.dart';

class NhentaiHomePageController extends GetxController {
  bool loading = true;
  NhentaiHomePageData? data;
  String? message;

  void get() async {
    var res = await NhentaiNetwork().getHomePage();
    if (res.error) {
      message = res.errorMessageWithoutNull;
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

class NhentaiHomePage extends StatelessWidget {
  const NhentaiHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NhentaiHomePageController>(
        builder: (logic) {
          if (logic.loading) {
            logic.get();
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (logic.message != null) {
            return showNetworkError(logic.message!, ()=>logic.refresh_(), context,
                showBack: false);
          } else {
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 60,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 5, 10),
                      child: Row(
                        children: [
                          Text(
                            "Popular",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return NhentaiComicTile(logic.data!.popular[index]);
                  }, childCount: logic.data!.popular.length),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(),),
                const SliverToBoxAdapter(
                  child: SizedBox(
                    height: 60,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 10, 5, 10),
                      child: Row(
                        children: [
                          Text(
                            "Latest",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if(index == logic.data!.latest.length-1){
                      NhentaiNetwork().loadMoreHomePageData(logic.data!).then((res){
                        if(res.error){
                          showMessage(Get.context, res.errorMessageWithoutNull);
                        }else{
                          logic.update();
                        }
                      });
                    }
                    return NhentaiComicTile(logic.data!.latest[index]);
                  }, childCount: logic.data!.latest.length),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: comicTileMaxWidth,
                    childAspectRatio: comicTileAspectRatio,
                  ),
                ),
                const SliverToBoxAdapter(child: ListLoadingIndicator(),)
              ],
            );
          }
        });
  }
}
