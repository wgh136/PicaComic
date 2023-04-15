import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pica_comic/base.dart';
import 'package:pica_comic/views/widgets/show_network_error.dart';
import 'package:pica_comic/views/widgets/widgets.dart';
import '../../network/models.dart';

class HomePageLogic extends GetxController{
  bool isLoading = true;
  bool isLoadingMore = false;
  var comics = <ComicItemBrief>[];
  void change(){
    isLoading = !isLoading;
    update();
  }
  void refresh_() async{
    isLoading = true;
    comics.clear();
    update();
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomePageLogic>(
        builder: (homePageLogic){
      if(homePageLogic.isLoading){
        bool flag1 = false,flag2 = false;
        network.getRandomComics().then((c){
          for(var i in c){
            homePageLogic.comics.add(i);
          }
          flag1 = true;
          if(flag1&&flag2)  homePageLogic.change();
        });
        network.getRandomComics().then((c){
          for(var i in c){
            homePageLogic.comics.add(i);
          }
          flag2 = true;
          if(flag1&&flag2)  homePageLogic.change();
        });
        return const Center(
          child: CircularProgressIndicator(),
        );
      }else if(homePageLogic.comics.isNotEmpty){
        return Material(
          child: RefreshIndicator(
              child: CustomScrollView(
                slivers: [
                  SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                        childCount: homePageLogic.comics.length,
                            (context, i){
                          if(i == homePageLogic.comics.length-1){
                            bool flag1 = false,flag2 = false;
                            network.getRandomComics().then((c){
                              for(var i in c){
                                homePageLogic.comics.add(i);
                              }
                              flag1 = true;
                              if(flag1&&flag2) {
                                homePageLogic.isLoadingMore = false;
                                homePageLogic.update();
                              }
                            });
                            network.getRandomComics().then((c){
                              for(var i in c){
                                homePageLogic.comics.add(i);
                              }
                              flag2 = true;
                              if(flag1&&flag2) {
                                homePageLogic.update();
                              }
                            });
                          }
                          return ComicTile(homePageLogic.comics[i],cached: false,);
                        }
                    ),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: comicTileMaxWidth,
                      childAspectRatio: comicTileAspectRatio,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 80,
                      child: const Center(
                        child: SizedBox(
                          width: 20,height: 20,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(padding: EdgeInsets.only(top: Get.bottomBarHeight))
                ],
              ),
              onRefresh: () async {
                homePageLogic.refresh_();
              }
          ),
        );
      }else{
        return showNetworkError(context, ()=>homePageLogic.change(),showBack: false);
      }
    });
  }
}
