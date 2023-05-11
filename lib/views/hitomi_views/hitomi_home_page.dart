import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/network/hitomi_network/hitomi_main_network.dart';
import 'package:pica_comic/views/hitomi_views/hi_widgets.dart';
import 'package:pica_comic/views/widgets/list_loading.dart';
import 'package:pica_comic/views/widgets/show_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../base.dart';
import '../../network/hitomi_network/hitomi_models.dart';

class HitomiHomePageLogic extends GetxController{
  bool loading = true;
  String? message;
  int currentPage = 1;
  ComicList? comics;

  void get(String url) async{
    var res = await HiNetwork().getComics(url);
    if(res.error){
      message = res.errorMessage!;
    }else{
      comics = res.data;
    }
    loading = false;
    update();
  }

  void loadNextPage(String url) async{
    var res = await HiNetwork().loadNextPage(comics!);
    if(res.error){
      showMessage(Get.context, res.errorMessage!);
    }else{
      update();
    }
  }

  void refresh_(){
    loading = true;
    comics = null;
    message = null;
    currentPage = 1;
    update();
  }
}

class HitomiHomePage extends StatelessWidget {
  const HitomiHomePage(this.url, {Key? key}) : super(key: key);
  final String url;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HitomiHomePageLogic>(
      tag: url,
      builder: (logic){
        if(logic.loading){
          logic.get(url);
          return const Center(
            child: CircularProgressIndicator(),
          );
        }else if(logic.message != null){
          return showNetworkError(logic.message!, () => logic.refresh_(), context, showBack: false);
        }else{
          return CustomScrollView(
            slivers: [
              SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if(index == logic.comics!.comics.length-1){
                    logic.loadNextPage(url);
                  }
                  return HiComicTile(logic.comics!.comics[index]);
                }, childCount: logic.comics!.comics.length),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: comicTileMaxWidth,
                  childAspectRatio: comicTileAspectRatio,
                ),
              ),
              if(logic.comics!.toLoad < logic.comics!.total)
                const SliverToBoxAdapter(child: ListLoadingIndicator(),)
            ],
          );
        }
      }
    );
  }
}
